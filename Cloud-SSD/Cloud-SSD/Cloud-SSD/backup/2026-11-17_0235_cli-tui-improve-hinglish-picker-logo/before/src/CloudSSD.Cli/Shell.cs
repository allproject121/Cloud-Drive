using System.Diagnostics;
using System.Text;
using CloudSSD.Core;
using CloudSSD.Diagnostics;

namespace CloudSSD.Cli;

/// <summary>
/// The interactive Cloud-SSD shell, laid out like Claude Code / Codex in the terminal:
/// a welcome box, a framed input line at the bottom, a command list that opens on "/", answers shown as
/// "● Heading" with "⎿" under it, a spinner while a command works, and earlier commands on ↑ ↓.
/// </summary>
/// <remarks>
/// Drawing works the way Ink (Claude Code's renderer) does: the input area is redrawn in place. The shell remembers on
/// which row of that area the cursor stands, moves up that many rows, clears to the end of the screen and draws it again.
/// Only relative cursor moves are used, so it keeps working when the window scrolls.
/// </remarks>
internal sealed class Shell
{
    private const string Esc = "\u001b[";
    private const int MenuRows = 8;
    private const int HistoryKeep = 200;

    private static readonly string[] Frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

    private readonly AppPaths _paths;
    private readonly string _historyFile;
    private readonly List<string> _history = [];
    private readonly StringBuilder _buf = new();
    private int _pos;
    private int _histIndex = -1;
    private string _draft = "";
    private int _menuSel;
    private int _menuTop;
    private bool _menuClosed;
    private bool _drawn;
    private int _cursorRow;
    private int _cursorCol;
    private int _lastWidth;
    private DateTime _ctrlCAt = DateTime.MinValue;
    private string _note = "";
    private volatile string _vitals = "";
    private int _vitalsBusy;

    public Shell(AppPaths paths)
    {
        _paths = paths;
        _historyFile = Path.Combine(paths.DataRoot, "cli-history.txt");
    }

    // ---- the main loop ------------------------------------------------------------------------------------------

    public async Task<int> RunAsync()
    {
        Console.OutputEncoding = new UTF8Encoding(false);
        Console.TreatControlCAsInput = true;
        LoadHistory();
        try
        {
            await PrintWelcomeAsync();
            while (true)
            {
                var line = ReadLine();
                if (line is null) break;
                if (!await ExecuteAsync(line)) break;
            }
        }
        finally
        {
            Console.TreatControlCAsInput = false;
            Console.Write(Esc + "0m" + Esc + "?25h");
        }
        return 0;
    }

    /// <summary>For a pipe or a file as input ("status" | cpx), or a console without colour codes: plain lines, no frames.</summary>
    public static async Task<int> RunPlainAsync(AppPaths paths)
    {
        var interactive = !Console.IsInputRedirected;
        if (interactive)
        {
            Console.WriteLine($"Cloud-SSD {Program.Version} - type help for the commands, exit to leave.");
        }
        while (true)
        {
            if (interactive) Console.Write("cloudssd > ");
            var line = Console.ReadLine();
            if (line is null) break;
            var words = CommandCatalog.Split(line.Trim());
            if (words.Length == 0) continue;
            var cmd = CommandCatalog.Find(words[0]);
            if (cmd?.Name == "exit") break;
            if (cmd?.Name == "clear") { if (interactive) Console.Clear(); continue; }
            if (cmd?.Name == "help") { Views.Help(Console.Out, shell: true); continue; }
            if (cmd is null)
            {
                var guess = CommandCatalog.Closest(words[0]);
                Console.WriteLine($"Unknown command: {words[0]}{(guess != null ? $" (did you mean {guess}?)" : "")}. Type help for the list.");
                continue;
            }
            words[0] = cmd.Name;
            try
            {
                await Program.DispatchAsync(words, paths, Console.Out, Console.Out);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: " + Redactor.Redact(ex.Message));
            }
            Console.WriteLine();
        }
        return 0;
    }

    // ---- welcome box --------------------------------------------------------------------------------------------

    private sealed record Snapshot(bool AppOn, int? Pid, string Drives, string? Phone, string? PhoneSeen, int Accounts);

    private Snapshot ReadSnapshot()
    {
        var s = Views.Settings(_paths);
        var app = Views.FindApp();
        var drives = string.Join("  ", Views.MountedCloudDrives(s).Select(d => d.Letter));
        var phone = s.MobileBridge.PairedDevices.Where(p => !p.IsBlocked).OrderByDescending(p => p.LastSeen).FirstOrDefault();
        return new Snapshot(app != null, app?.Id, drives, phone?.Name,
            phone != null ? Views.Ago(phone.LastSeen, DateTimeOffset.Now) : null, s.AccountEmails.Count);
    }

    private async Task PrintWelcomeAsync()
    {
        // Looking at a cloud drive can hang while Google is slow; the welcome never waits more than 2.5 s for it.
        var read = Task.Run(ReadSnapshot);
        var done = await Task.WhenAny(read, Task.Delay(2500));
        Snapshot? snap = done == read && read.IsCompletedSuccessfully ? read.Result : null;
        SetVitals(snap);

        var width = Math.Min(ScreenWidth(), 78);
        var inner = width - 4;
        var lines = new List<string>
        {
            Ansi.Accent(Ansi.Bold(">_")) + " " + Ansi.Bold("Cloud-SSD") + Ansi.Gray($"  v{Program.Version}"),
            "",
            Ansi.Gray(Ansi.Fit("Your Google Drive as a real drive letter on this PC.", inner)),
            "",
        };
        if (snap is null)
        {
            lines.Add(Label("app") + Ansi.Gray("still checking" + Ansi.Ellipsis + " (try /status in a moment)"));
        }
        else
        {
            lines.Add(Label("app") + (snap.AppOn
                ? Ansi.Green(Ansi.Dot + " running") + Ansi.Gray($"{Ansi.Sep}PID {snap.Pid}")
                : Ansi.Yellow(Ansi.Ring + " stopped") + Ansi.Gray($"{Ansi.Sep}/start to run it")));
            lines.Add(Label("drives") + (snap.Drives.Length > 0 ? Ansi.Accent(snap.Drives) : Ansi.Gray("none connected")));
            lines.Add(Label("phone") + (snap.Phone != null
                ? Ansi.Fit(snap.Phone, inner - 22) + Ansi.Gray($"{Ansi.Sep}seen {snap.PhoneSeen}")
                : Ansi.Gray("none paired")));
        }
        lines.Add(Label("data") + Ansi.Gray(Ansi.Fit(_paths.DataRoot, inner - 10)));

        var sb = new StringBuilder();
        sb.Append("\r\n");
        foreach (var l in Box(lines, width)) sb.Append(l).Append("\r\n");
        sb.Append("\r\n");
        sb.Append(' ').Append(Ansi.Bold("Tips for getting started:")).Append("\r\n");
        sb.Append(Ansi.Gray(" 1. ")).Append("Type ").Append(Ansi.Accent("/")).Append(" to see every command, ")
          .Append(Ansi.G("↑ ↓", "Up/Down")).Append(" to pick, Enter to run").Append("\r\n");
        sb.Append(Ansi.Gray(" 2. ")).Append(Ansi.Accent("/status")).Append(" shows everything at once").Append(Ansi.Gray(Ansi.Sep))
          .Append(Ansi.Accent("/open")).Append(" opens your drive").Append("\r\n");
        sb.Append(Ansi.Gray(" 3. ")).Append("Plain words work too: ").Append(Ansi.Accent("status")).Append(", ")
          .Append(Ansi.Accent("open y")).Append(", ").Append(Ansi.Accent("phone")).Append("\r\n");
        sb.Append("\r\n");
        Console.Out.Write(sb.ToString());
        Console.Out.Flush();
    }

    private static string Label(string text) => Ansi.Gray(text.PadRight(8));

    /// <summary>A box with round corners around the lines (each line is cut or padded to fit).</summary>
    internal static IEnumerable<string> Box(IReadOnlyList<string> lines, int width)
    {
        var h = Ansi.G("─", "-");
        yield return Ansi.Faint(Ansi.G("╭", "+") + string.Concat(Enumerable.Repeat(h, width - 2)) + Ansi.G("╮", "+"));
        foreach (var l in lines)
        {
            // A line that does not fit loses its colours and gets "…"; the frame always stays straight.
            var fitted = Ansi.Width(l) > width - 4 ? Ansi.Fit(Ansi.Strip(l), width - 4) : l;
            yield return Ansi.Faint(Ansi.G("│", "|")) + " " + Ansi.Pad(fitted, width - 4) + " " + Ansi.Faint(Ansi.G("│", "|"));
        }
        yield return Ansi.Faint(Ansi.G("╰", "+") + string.Concat(Enumerable.Repeat(h, width - 2)) + Ansi.G("╯", "+"));
    }

    // ---- reading a line -----------------------------------------------------------------------------------------

    private string? ReadLine()
    {
        _buf.Clear();
        _pos = 0;
        _histIndex = -1;
        _menuSel = 0;
        _menuTop = 0;
        _menuClosed = false;
        _drawn = false;
        Render();
        while (true)
        {
            var key = Console.ReadKey(intercept: true);
            var action = HandleKey(key);
            if (action == KeyResult.Quit)
            {
                Erase();
                return null;
            }
            if (action == KeyResult.Submit)
            {
                var text = _buf.ToString();
                Erase();
                return text;
            }
            // A paste arrives as many keys at once: draw once when they are all in.
            if (!Console.KeyAvailable) Render();
        }
    }

    private enum KeyResult { Continue, Submit, Quit }

    private KeyResult HandleKey(ConsoleKeyInfo k)
    {
        var ctrl = (k.Modifiers & ConsoleModifiers.Control) != 0;
        var menu = Menu();
        if (!(ctrl && k.Key == ConsoleKey.C)) _note = "";

        switch (k.Key)
        {
            case ConsoleKey.Enter:
                if (menu.Count > 0)
                {
                    var c = menu[_menuSel];
                    if (c.NeedsArgs)
                    {
                        SetText("/" + c.Name + " ");
                        return KeyResult.Continue;
                    }
                    SetText("/" + c.Name);
                }
                return _buf.ToString().Trim().Length == 0 ? KeyResult.Continue : KeyResult.Submit;

            case ConsoleKey.Tab:
                if (menu.Count > 0)
                {
                    var c = menu[_menuSel];
                    SetText("/" + c.Name + (c.Args.Length > 0 ? " " : ""));
                }
                return KeyResult.Continue;

            case ConsoleKey.UpArrow:
                if (menu.Count > 0) _menuSel = (_menuSel - 1 + menu.Count) % menu.Count;
                else HistoryMove(+1);
                return KeyResult.Continue;

            case ConsoleKey.DownArrow:
                if (menu.Count > 0) _menuSel = (_menuSel + 1) % menu.Count;
                else HistoryMove(-1);
                return KeyResult.Continue;

            case ConsoleKey.LeftArrow:
                _pos = ctrl ? WordLeft() : Math.Max(0, _pos - 1);
                return KeyResult.Continue;

            case ConsoleKey.RightArrow:
                _pos = ctrl ? WordRight() : Math.Min(_buf.Length, _pos + 1);
                return KeyResult.Continue;

            case ConsoleKey.Home:
                _pos = 0;
                return KeyResult.Continue;

            case ConsoleKey.End:
                _pos = _buf.Length;
                return KeyResult.Continue;

            case ConsoleKey.Backspace:
                if (ctrl) DeleteRange(WordLeft(), _pos);
                else if (_pos > 0) DeleteRange(_pos - 1, _pos);
                return KeyResult.Continue;

            case ConsoleKey.Delete:
                if (_pos < _buf.Length) DeleteRange(_pos, _pos + 1);
                return KeyResult.Continue;

            case ConsoleKey.Escape:
                if (menu.Count > 0) _menuClosed = true;
                else if (_buf.Length > 0) SetText("");
                return KeyResult.Continue;
        }

        if (ctrl)
        {
            switch (k.Key)
            {
                case ConsoleKey.C:
                    if (_buf.Length > 0)
                    {
                        SetText("");
                        _note = "";
                        return KeyResult.Continue;
                    }
                    if ((DateTime.UtcNow - _ctrlCAt).TotalSeconds < 2) return KeyResult.Quit;
                    _ctrlCAt = DateTime.UtcNow;
                    _note = "Press Ctrl+C again to leave";
                    return KeyResult.Continue;
                case ConsoleKey.D:
                    return _buf.Length == 0 ? KeyResult.Quit : KeyResult.Continue;
                case ConsoleKey.L:
                    Console.Out.Write(Esc + "2J" + Esc + "3J" + Esc + "H");
                    _drawn = false;
                    return KeyResult.Continue;
                case ConsoleKey.A:
                    _pos = 0;
                    return KeyResult.Continue;
                case ConsoleKey.E:
                    _pos = _buf.Length;
                    return KeyResult.Continue;
                case ConsoleKey.U:
                    DeleteRange(0, _pos);
                    return KeyResult.Continue;
                case ConsoleKey.K:
                    DeleteRange(_pos, _buf.Length);
                    return KeyResult.Continue;
                case ConsoleKey.W:
                    DeleteRange(WordLeft(), _pos);
                    return KeyResult.Continue;
            }
        }

        if (k.KeyChar != '\0' && !char.IsControl(k.KeyChar) && k.KeyChar != '﻿')
        {
            _buf.Insert(_pos, k.KeyChar);
            _pos++;
            TextChanged();
        }
        return KeyResult.Continue;
    }

    private IReadOnlyList<CliCommand> Menu() => _menuClosed ? [] : CommandCatalog.Suggest(_buf.ToString());

    /// <summary>For tests: as if the person had typed this line.</summary>
    internal void TypeForTest(string text) => SetText(text);

    private void SetText(string text)
    {
        _buf.Clear().Append(text);
        _pos = _buf.Length;
        TextChanged();
    }

    private void TextChanged()
    {
        _menuSel = 0;
        _menuTop = 0;
        _menuClosed = false;
    }

    private void DeleteRange(int from, int to)
    {
        if (to <= from) return;
        _buf.Remove(from, to - from);
        _pos = from;
        TextChanged();
    }

    private int WordLeft()
    {
        var i = _pos;
        while (i > 0 && _buf[i - 1] == ' ') i--;
        while (i > 0 && _buf[i - 1] != ' ') i--;
        return i;
    }

    private int WordRight()
    {
        var i = _pos;
        while (i < _buf.Length && _buf[i] == ' ') i++;
        while (i < _buf.Length && _buf[i] != ' ') i++;
        return i;
    }

    /// <summary>↑ (+1) goes to older commands, ↓ (-1) back towards what was being typed.</summary>
    private void HistoryMove(int step)
    {
        if (_history.Count == 0) return;
        if (_histIndex == -1) _draft = _buf.ToString();
        var next = Math.Clamp(_histIndex + step, -1, _history.Count - 1);
        if (next == _histIndex) return;
        _histIndex = next;
        var text = next == -1 ? _draft : _history[_history.Count - 1 - next];
        _buf.Clear().Append(text);
        _pos = _buf.Length;
        _menuClosed = true; // a line from history should not pop the list open
    }

    // ---- drawing the input area ---------------------------------------------------------------------------------

    private static int ScreenWidth()
    {
        try
        {
            return Math.Max(30, Console.WindowWidth - 1);
        }
        catch
        {
            return 79;
        }
    }

    private void Render()
    {
        var width = ScreenWidth();
        var sb = new StringBuilder();
        sb.Append(Esc + "?25l");
        if (_drawn) sb.Append(MoveToTop(width));
        sb.Append('\r').Append(Esc + "J");
        _lastWidth = width;

        var lines = BuildArea(width, out var inputRow, out var inputCol);
        sb.Append(string.Join("\r\n", lines));
        var up = lines.Count - 1 - inputRow;
        if (up > 0) sb.Append(Esc).Append(up).Append('A');
        sb.Append('\r');
        if (inputCol > 0) sb.Append(Esc).Append(inputCol).Append('C');
        sb.Append(Esc + "?25h");
        Console.Out.Write(sb.ToString());
        Console.Out.Flush();
        _cursorRow = inputRow;
        _cursorCol = inputCol;
        _drawn = true;
    }

    /// <summary>
    /// Cursor moves that bring it back to the first row of what was drawn last time. When the window got narrower the
    /// terminal has wrapped every old row into several, so more rows are climbed.
    /// </summary>
    private string MoveToTop(int width)
    {
        var rows = _cursorRow;
        if (width < _lastWidth && width > 0)
        {
            var perRow = (int)Math.Ceiling(_lastWidth / (double)width);
            rows = _cursorRow * perRow + _cursorCol / width;
        }
        return rows > 0 ? $"{Esc}{rows}A" : "";
    }

    private void Erase()
    {
        if (!_drawn) return;
        Console.Out.Write(MoveToTop(ScreenWidth()) + "\r" + Esc + "J");
        Console.Out.Flush();
        _drawn = false;
    }

    /// <summary>The rows of the input area: the framed input line, then the command list or the hint line.</summary>
    internal List<string> BuildArea(int width, out int inputRow, out int inputCol)
    {
        var h = Ansi.G("─", "-");
        var v = Ansi.Faint(Ansi.G("│", "|"));
        var lines = new List<string>
        {
            Ansi.Faint(Ansi.G("╭", "+") + string.Concat(Enumerable.Repeat(h, width - 2)) + Ansi.G("╮", "+")),
        };

        var room = width - 6; // "│ > " ... " │"
        var text = _buf.ToString();
        var cursorCol = Ansi.Width(text[.._pos]);
        var scroll = Math.Max(0, cursorCol - (room - 1));
        string shown;
        if (text.Length == 0)
        {
            shown = Ansi.Gray(Ansi.Fit("Try \"/status\", or type / to see every command", room));
        }
        else
        {
            shown = Ansi.Slice(text, scroll, room);
        }
        lines.Add(v + " " + Ansi.Accent(Ansi.Bold(">")) + " " + Ansi.Pad(shown, room) + " " + v);
        inputRow = 1;
        inputCol = 4 + (cursorCol - scroll);
        lines.Add(Ansi.Faint(Ansi.G("╰", "+") + string.Concat(Enumerable.Repeat(h, width - 2)) + Ansi.G("╯", "+")));

        var menu = Menu();
        if (menu.Count > 0)
        {
            _menuSel = Math.Clamp(_menuSel, 0, menu.Count - 1);
            if (_menuSel < _menuTop) _menuTop = _menuSel;
            if (_menuSel >= _menuTop + MenuRows) _menuTop = _menuSel - MenuRows + 1;
            _menuTop = Math.Clamp(_menuTop, 0, Math.Max(0, menu.Count - MenuRows));
            var nameWidth = Math.Min(26, Math.Max(12, width / 3));
            for (var i = _menuTop; i < Math.Min(menu.Count, _menuTop + MenuRows); i++)
            {
                var c = menu[i];
                var usage = Ansi.Fit(c.Usage, nameWidth);
                var help = Ansi.Fit(c.Help, width - nameWidth - 5);
                lines.Add(i == _menuSel
                    ? Ansi.Accent(Ansi.G("› ", "> ") + Ansi.Pad(usage, nameWidth) + " " + help)
                    : "  " + Ansi.Pad(usage, nameWidth) + " " + Ansi.Gray(help));
            }
            var hidden = menu.Count - MenuRows;
            lines.Add(Ansi.Faint("  " + (hidden > 0 ? $"{menu.Count} commands{Ansi.Sep}" : "") +
                $"{Ansi.G("↑↓", "Up/Down")} choose{Ansi.Sep}tab fill in{Ansi.Sep}enter run{Ansi.Sep}esc close"));
        }
        else
        {
            var left = _note.Length > 0
                ? Ansi.Yellow("  " + _note)
                : Ansi.Faint($"  / commands{Ansi.Sep}{Ansi.G("↑↓", "Up/Down")} history{Ansi.Sep}esc clear{Ansi.Sep}ctrl+c leave");
            var right = _vitals;
            var gap = width - Ansi.Width(left) - Ansi.Width(right) - 1;
            lines.Add(gap >= 2 ? left + new string(' ', gap) + right : left);
        }
        return lines;
    }

    // ---- running a command --------------------------------------------------------------------------------------

    private async Task<bool> ExecuteAsync(string line)
    {
        line = CommandCatalog.Clean(line).Trim();
        if (line.Length == 0) return true;
        AddHistory(line);

        var words = CommandCatalog.Split(line);
        Console.Out.Write(Ansi.Gray("> " + line) + "\r\n\r\n");

        var cmd = CommandCatalog.Find(words[0]);
        if (cmd is null || cmd.Hidden)
        {
            var guess = CommandCatalog.Closest(words[0]);
            Answer(Ansi.Yellow, "I don't know \"" + words[0] + "\"",
                (guess != null ? $"Did you mean {Ansi.Accent("/" + guess)}? " : "") + "Type / to see every command.");
            return true;
        }
        words[0] = cmd.Name;

        switch (cmd.Name)
        {
            case "exit":
                Console.Out.Write(Ansi.Gray("  Bye!") + "\r\n");
                return false;
            case "clear":
                Console.Out.Write(Esc + "2J" + Esc + "3J" + Esc + "H");
                await PrintWelcomeAsync();
                return true;
            case "help":
                var help = new StringWriter();
                Views.Help(help, shell: true);
                Answer(Ansi.Accent, "Help", help.ToString());
                return true;
        }

        if (cmd.Live)
        {
            Console.Out.Write(Ansi.Accent(Ansi.Dot) + " " + Ansi.Bold(cmd.Title) + Ansi.Gray("  (Ctrl+C stops it)") + "\r\n");
            Console.TreatControlCAsInput = false;
            try
            {
                await Program.DispatchAsync(words, _paths, Console.Out, Console.Out);
            }
            catch (Exception ex)
            {
                Console.Out.WriteLine(Ansi.Red("Error: " + Redactor.Redact(ex.Message)));
            }
            finally
            {
                Console.TreatControlCAsInput = true;
            }
            Console.Out.Write("\r\n");
            RefreshVitals();
            return true;
        }

        // The answer is collected in its own writer while the spinner runs, then shown in one piece. If the person
        // stops waiting, a late answer goes into that writer and is simply dropped.
        var output = new StringWriter();
        var run = Task.Run(() => Program.DispatchAsync(words, _paths, output, output));
        var stopped = await SpinAsync(run, cmd.Doing);
        if (stopped)
        {
            Answer(Ansi.Yellow, cmd.Title, "Stopped waiting. It may still finish in the background.");
            RefreshVitals();
            return true;
        }

        int code;
        var body = "";
        try
        {
            code = await run;
            body = output.ToString();
        }
        catch (Exception ex)
        {
            code = 1;
            body = output.ToString() + Ansi.Red("Error: " + Redactor.Redact(ex.Message));
        }
        var title = cmd.Title + (words.Length > 1 ? " " + string.Join(" ", words[1..]) : "");
        Answer(code == 0 ? Ansi.Accent : Ansi.Red, title, body);
        RefreshVitals();
        return true;
    }

    /// <summary>Spinner with seconds while the command works. Esc or Ctrl+C stops waiting (returns true).</summary>
    private static async Task<bool> SpinAsync(Task work, string doing)
    {
        // Quick commands finish before the first frame, so nothing flickers.
        await Task.WhenAny(work, Task.Delay(150));
        if (work.IsCompleted) return false;

        var clock = Stopwatch.StartNew();
        var frame = 0;
        Console.Out.Write(Esc + "?25l");
        try
        {
            while (!work.IsCompleted)
            {
                var secs = (int)clock.Elapsed.TotalSeconds;
                Console.Out.Write("\r" + Esc + "K" + Ansi.Accent(Frames[frame++ % Frames.Length]) + " " + doing + Ansi.Ellipsis +
                                  Ansi.Gray($"  ({secs}s{Ansi.Sep}esc to stop)"));
                Console.Out.Flush();
                await Task.WhenAny(work, Task.Delay(80));
                while (Console.KeyAvailable)
                {
                    var k = Console.ReadKey(intercept: true);
                    if (k.Key == ConsoleKey.Escape || (k.Key == ConsoleKey.C && (k.Modifiers & ConsoleModifiers.Control) != 0))
                        return true;
                }
            }
            return false;
        }
        finally
        {
            Console.Out.Write("\r" + Esc + "K" + Esc + "?25h");
            Console.Out.Flush();
        }
    }

    /// <summary>Shows an answer the Claude Code way: "● Heading", then the text indented under "⎿".</summary>
    internal static void Answer(Func<string, string> colour, string title, string body)
    {
        Console.Out.Write(FormatAnswer(colour, title, body));
        Console.Out.Flush();
    }

    internal static string FormatAnswer(Func<string, string> colour, string title, string body)
    {
        var sb = new StringBuilder();
        sb.Append(colour(Ansi.Dot)).Append(' ').Append(Ansi.Bold(title)).Append("\r\n");
        var rows = body.Replace("\r\n", "\n").Split('\n').ToList();
        while (rows.Count > 0 && rows[0].Trim().Length == 0) rows.RemoveAt(0);
        while (rows.Count > 0 && rows[^1].Trim().Length == 0) rows.RemoveAt(rows.Count - 1);
        if (rows.Count == 0) rows.Add(Ansi.Gray("Done."));
        for (var i = 0; i < rows.Count; i++)
            // Claude Code draws "⎿" here; Consolas (the classic cmd.exe font) has no such letter and shows an empty box,
            // so the box-drawing "└" that every console font has is used instead.
            sb.Append(i == 0 ? Ansi.Gray(Ansi.G("  └  ", "  |  ")) : "     ").Append(rows[i]).Append("\r\n");
        sb.Append("\r\n");
        return sb.ToString();
    }

    // ---- the line under the input box: is the app on, which drives -----------------------------------------------

    private void RefreshVitals()
    {
        if (Interlocked.Exchange(ref _vitalsBusy, 1) == 1) return;
        _ = Task.Run(() =>
        {
            try
            {
                SetVitals(ReadSnapshot());
            }
            catch
            {
                // Keep the old line.
            }
            finally
            {
                Interlocked.Exchange(ref _vitalsBusy, 0);
            }
        });
    }

    private void SetVitals(Snapshot? s)
    {
        if (s is null) return;
        var app = s.AppOn ? Ansi.Green(Ansi.Dot) + Ansi.Gray(" app on") : Ansi.Faint(Ansi.Ring) + Ansi.Gray(" app off");
        _vitals = app + (s.Drives.Length > 0 ? Ansi.Gray(Ansi.Sep) + Ansi.Accent(s.Drives) : "");
    }

    // ---- history (kept between runs, like Claude Code) ------------------------------------------------------------

    private void LoadHistory()
    {
        try
        {
            if (File.Exists(_historyFile))
                _history.AddRange(File.ReadAllLines(_historyFile).Where(l => l.Trim().Length > 0).TakeLast(HistoryKeep));
        }
        catch
        {
            // No history is fine.
        }
    }

    private void AddHistory(string line)
    {
        if (_history.Count > 0 && _history[^1] == line) return;
        _history.Add(line);
        if (_history.Count > HistoryKeep) _history.RemoveRange(0, _history.Count - HistoryKeep);
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_historyFile)!);
            File.WriteAllLines(_historyFile, _history);
        }
        catch
        {
            // History is a convenience; never fail a command because of it.
        }
    }
}
