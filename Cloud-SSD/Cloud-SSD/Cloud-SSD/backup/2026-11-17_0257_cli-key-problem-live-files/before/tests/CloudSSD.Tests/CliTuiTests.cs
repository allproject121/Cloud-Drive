using CloudSSD.Cli;
using CloudSSD.Core;

namespace CloudSSD.Tests;

/// <summary>The terminal shell (cloudssd / cpx): command list, "/" menu, drawing widths and plain output for pipes.</summary>
public sealed class CliTuiTests : IDisposable
{
    private readonly string _home = Path.Combine(Path.GetTempPath(), "cloudssd-cli-" + Guid.NewGuid().ToString("N")[..8]);
    private readonly bool _wasEnabled = Ansi.Enabled;
    private readonly bool _wasUnicode = Ansi.Unicode;

    public CliTuiTests() => Directory.CreateDirectory(_home);

    public void Dispose()
    {
        Ansi.Enabled = _wasEnabled;
        Ansi.Unicode = _wasUnicode;
        try { Directory.Delete(_home, true); } catch { /* temp folder */ }
    }

    private static void Fancy(bool on)
    {
        Ansi.Enabled = on;
        Ansi.Unicode = on;
    }

    [Fact]
    public void No_color_keeps_the_frame_but_drops_the_colours()
    {
        Ansi.Enabled = false;
        Ansi.Unicode = true;
        var row = Shell.Box(["hi"], 10).First();
        Assert.Equal("╭────────╮", row);
        // Char search: a culture string search treats the ESC control character as ignorable and "finds" it anywhere.
        Assert.False(Shell.FormatAnswer(Ansi.Accent, "Status", "ok").Contains('\u001b'));
    }

    [Theory]
    [InlineData("/status", "status")]
    [InlineData("status", "status")]
    [InlineData("STATUS", "status")]
    [InlineData("s", "status")]
    [InlineData("mounts", "drives")]
    [InlineData("remotes", "accounts")]
    [InlineData("devices", "phone")]
    [InlineData("\uFEFFhelp", "help")]
    [InlineData("/q", "exit")]
    public void Old_and_new_words_find_the_same_command(string typed, string expected) =>
        Assert.Equal(expected, CommandCatalog.Find(typed)?.Name);

    [Fact]
    public void A_slash_opens_the_whole_list_but_never_the_hidden_secret_command()
    {
        var all = CommandCatalog.Suggest("/");
        Assert.Contains(all, c => c.Name == "status");
        Assert.DoesNotContain(all, c => c.Name == "secret");
        Assert.Equal(CommandCatalog.All.Count(c => !c.Hidden), all.Count);
    }

    [Fact]
    public void Typing_after_the_slash_filters_best_matches_first()
    {
        var st = CommandCatalog.Suggest("/st").Select(c => c.Name).ToList();
        Assert.Equal(["status", "start", "stop"], st.Take(3));

        Assert.Contains(CommandCatalog.Suggest("/mou"), c => c.Name == "drives"); // by its old name "mounts"
        Assert.Contains(CommandCatalog.Suggest("/google"), c => c.Name == "accounts"); // help text
        Assert.Empty(CommandCatalog.Suggest("status"));     // no slash: no list
        Assert.Empty(CommandCatalog.Suggest("/open z"));    // a second word closes the list
    }

    [Theory]
    [InlineData("stauts", "status")]
    [InlineData("/phnoe", "phone")]
    [InlineData("drievs", "drives")]
    public void A_mistyped_word_gets_a_did_you_mean(string typed, string expected) =>
        Assert.Equal(expected, CommandCatalog.Closest(typed));

    [Fact]
    public void Nonsense_gets_no_guess() => Assert.Null(CommandCatalog.Closest("xyzzyq"));

    [Fact]
    public void Quotes_keep_a_folder_with_spaces_together_and_the_bom_is_dropped()
    {
        Assert.Equal(["scan", @"D:\My Games\Game One", "--mbps", "50"],
            CommandCatalog.Split("\uFEFFscan \"D:\\My Games\\Game One\" --mbps 50"));
    }

    [Fact]
    public void Widths_ignore_colour_codes_and_count_wide_letters_twice()
    {
        Fancy(true);
        var coloured = Ansi.Accent("Z:") + " " + Ansi.Bold("drive");
        Assert.Equal(8, Ansi.Width(coloured));
        Assert.Equal("Z: drive", Ansi.Strip(coloured));
        Assert.Equal(4, Ansi.Width("中文"));
        Assert.Equal(10, Ansi.Width(Ansi.Pad(coloured, 10)));
    }

    [Fact]
    public void Long_text_is_cut_with_dots_and_sliced_for_the_input_box()
    {
        Fancy(true);
        Assert.Equal("abcd…", Ansi.Fit("abcdefgh", 5));
        Assert.Equal("abc", Ansi.Fit("abc", 5));
        Assert.Equal("cdef", Ansi.Slice("abcdefgh", 2, 4));

        Fancy(false);
        Assert.Equal("ab...", Ansi.Fit("abcdefgh", 5));
    }

    [Fact]
    public void Without_colour_nothing_but_plain_ascii_is_written()
    {
        Fancy(false);
        var text = Ansi.Accent("a") + Ansi.Dot + Ansi.Tick + Ansi.Sep + Views.Bar(0.5, 4);
        Assert.Equal("a*OK | [##..]", text);
        Assert.All(text, ch => Assert.True(ch < 128));
    }

    [Fact]
    public void Answers_are_shown_under_a_heading_with_the_hook_line()
    {
        Fancy(true);
        var s = Ansi.Strip(Shell.FormatAnswer(Ansi.Accent, "Status", "\nPC app  running\nDrives  Z:\n\n"));
        Assert.Equal("● Status\r\n  └  PC app  running\r\n     Drives  Z:\r\n\r\n", s);

        Assert.Contains("Done.", Ansi.Strip(Shell.FormatAnswer(Ansi.Accent, "Clean", "")));
    }

    [Fact]
    public void Every_row_of_a_box_is_exactly_as_wide_as_asked()
    {
        Fancy(true);
        var rows = Shell.Box([Ansi.Bold("Cloud-SSD"), "", "a very long line that does not fit in the box at all"], 30).ToList();
        Assert.Equal(5, rows.Count);
        Assert.All(rows, r => Assert.Equal(30, Ansi.Width(r)));
        Assert.EndsWith("… │", Ansi.Strip(rows[3]));
    }

    [Fact]
    public void The_input_area_is_a_frame_with_a_hint_line_and_the_menu_opens_on_a_slash()
    {
        Fancy(true);
        var shell = new Shell(new AppPaths(_home));

        var empty = shell.BuildArea(60, out var row, out var col);
        Assert.Equal(4, empty.Count);                       // top, "> ", bottom, hint line
        Assert.Equal(1, row);
        Assert.Equal(4, col);                               // just after "│ > "
        Assert.All(empty.Take(3), l => Assert.Equal(60, Ansi.Width(l)));
        Assert.Contains("z drive kholo", Ansi.Strip(empty[1])); // the placeholder

        shell.TypeForTest("/st");
        var menu = shell.BuildArea(60, out _, out col);
        Assert.Equal(7, col);
        var items = menu.Skip(3).Select(Ansi.Strip).ToList();
        Assert.StartsWith("› /status", items[0]);           // first match chosen
        Assert.Contains(items, l => l.Contains("/start"));
        Assert.Contains("esc close", items[^1]);

        shell.TypeForTest("/");
        var full = shell.BuildArea(60, out _, out _);
        Assert.Equal(3 + 8 + 1, full.Count);                // never more than 8 commands at once
    }

    [Fact]
    public void A_line_longer_than_the_box_scrolls_so_the_cursor_stays_visible()
    {
        Fancy(true);
        var shell = new Shell(new AppPaths(_home));
        shell.TypeForTest("/scan " + new string('x', 100));
        var area = shell.BuildArea(40, out _, out var col);
        Assert.Equal(40, Ansi.Width(area[1]));
        Assert.True(col < 40);
    }

    [Fact]
    public async Task One_shot_commands_write_plain_text_and_say_when_something_is_missing()
    {
        Fancy(false);
        var paths = new AppPaths(_home);

        var o = new StringWriter();
        var err = new StringWriter();
        Assert.Equal(0, await Program.DispatchAsync(["mounts"], paths, o, err));
        Assert.Contains("No drives set up yet", o.ToString());

        o = new StringWriter();
        Assert.Equal(64, await Program.DispatchAsync(["scan"], paths, o, err));
        Assert.Contains("scan needs <folder>", err.ToString());

        err = new StringWriter();
        Assert.Equal(64, await Program.DispatchAsync(["stauts"], paths, o, err));
        Assert.Contains("did you mean \"status\"", err.ToString());
    }

    [Theory]
    [InlineData("status")]
    [InlineData("drives")]
    [InlineData("phone")]
    [InlineData("mirror")]
    [InlineData("help")]
    public async Task Output_into_a_pipe_is_plain_ascii(string command)
    {
        Fancy(false);
        var o = new StringWriter();
        await Program.DispatchAsync([command], new AppPaths(_home), o, o);
        Assert.NotEmpty(o.ToString());
        Assert.All(o.ToString(), ch => Assert.True(ch < 128, $"'{ch}' (U+{(int)ch:X4}) in: {o}"));
    }

    [Fact]
    public async Task Deps_always_exits_0_because_the_release_build_uses_it_as_a_smoke_test()
    {
        Fancy(false);
        var o = new StringWriter();
        Assert.Equal(0, await Program.DispatchAsync(["deps"], new AppPaths(_home), o, o));
        Assert.Contains("WinFsp", o.ToString(), StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task The_secret_for_rclone_prints_nothing_but_the_key()
    {
        var paths = new AppPaths(_home);
        var o = new StringWriter();
        var err = new StringWriter();
        Assert.Equal(1, await Program.DispatchAsync(["secret", "emit-config-pass"], paths, o, err));
        Assert.Equal("", o.ToString());
        Assert.Contains("No configuration key", err.ToString());
    }

    [Fact]
    public void Home_option_is_taken_out_before_the_command_runs()
    {
        Assert.Equal(["secret", "emit-config-pass"],
            Program.WithoutOption(["secret", "emit-config-pass", "--home", @"C:\data"], "--home"));
        Assert.Equal(["status"], Program.WithoutOption(["--home", @"C:\data", "status"], "--home"));
    }

    [Fact]
    public void Help_lists_every_visible_command()
    {
        Fancy(false);
        var o = new StringWriter();
        Views.Help(o, shell: true);
        foreach (var c in CommandCatalog.All.Where(c => !c.Hidden)) Assert.Contains("/" + c.Name, o.ToString());
        Assert.DoesNotContain("secret", o.ToString());
    }

    [Theory]
    [InlineData("z drive kholo", "/open Z:")]
    [InlineData("Z: kholo", "/open Z:")]
    [InlineData("y drive open karo", "/open Y:")]
    [InlineData("drive kholo", "/open")]
    [InlineData("phone dikhao", "/phone")]
    [InlineData("फोन दिखाओ", "/phone")]
    [InlineData("kitni jagah bachi hai?", "/cache")]
    [InlineData("google account dikhao", "/accounts")]
    [InlineData("app band karo", "/stop")]
    [InlineData("app chalu karo", "/start")]
    [InlineData("safai karo", "/clean")]
    [InlineData("kya haal hai", "/status")]
    [InlineData("drive band karo", "/drives")]   // not "close the app": the sentence is about a drive
    [InlineData("phone kaisa hai", "/phone")]    // the thing named wins over "kaisa"
    public void Hinglish_sentences_become_commands(string said, string expected) =>
        Assert.Equal(expected, CommandCatalog.Understand(said)?.Shown);

    [Theory]
    [InlineData("hello")]
    [InlineData("i am a user")]
    [InlineData("")]
    public void Sentences_about_nothing_known_are_not_guessed(string said) => Assert.Null(CommandCatalog.Understand(said));

    [Fact]
    public void After_open_the_list_shows_the_drives_and_runs_the_chosen_one()
    {
        Fancy(true);
        var shell = new Shell(new AppPaths(_home));
        shell.SetDrivesForTest([new("Y:", "Each Account", true), new("Z:", "All Accounts", false)]);

        shell.TypeForTest("/op");
        var open = Assert.Single(shell.Menu());
        Assert.Equal("/open ", open.Fill);
        Assert.False(open.RunsNow);                         // Enter fills "/open " and shows the drives

        shell.TypeForTest("/open ");
        var drives = shell.Menu();
        Assert.Equal(["/open Y:", "/open Z:"], drives.Select(d => d.Fill));
        Assert.All(drives, d => Assert.True(d.RunsNow));
        Assert.Contains("not connected", Ansi.Strip(drives[1].Help));

        shell.TypeForTest("/open z");
        Assert.Equal("/open Z:", Assert.Single(shell.Menu()).Fill);

        shell.TypeForTest("/st");
        Assert.True(shell.Menu().First().RunsNow);          // /status runs straight away
    }

    [Fact]
    public void Drive_choices_list_set_up_drives_and_say_which_are_connected()
    {
        var s = new AppSettings();
        s.Mounts.Add(new MountDefinition { DisplayName = "All Accounts", DriveLetter = "Z" });
        s.Mounts.Add(new MountDefinition { DisplayName = "Each Account", DriveLetter = "Y:" });
        var choices = Shell.Choices(s, [new Views.CloudDrive("Z:", "All Accounts", 1, 2)]);
        Assert.Equal(["Y:", "Z:"], choices.Select(c => c.Letter));
        Assert.False(choices[0].On);
        Assert.True(choices[1].On);
    }

    [Fact]
    public void A_yes_no_question_is_a_box_with_numbered_answers()
    {
        Fancy(true);
        var rows = Shell.BuildChoice("Close the Cloud-SSD app?", "The drives keep working.", ["Yes, close it", "No"], 1, 100);
        var plain = rows.Select(Ansi.Strip).ToList();
        Assert.Contains(plain, r => r.Contains("Close the Cloud-SSD app?"));
        Assert.Contains(plain, r => r.Contains("  1. Yes, close it"));
        Assert.Contains(plain, r => r.Contains("› 2. No"));
        Assert.All(rows.Take(rows.Count - 1), r => Assert.Equal(78, Ansi.Width(r)));
        Assert.Contains("esc cancel", plain[^1]);
    }

    [Fact]
    public void Only_closing_a_running_app_and_cleaning_are_asked_first()
    {
        Assert.NotNull(Shell.ConfirmFor("stop", appRunning: true));
        Assert.Null(Shell.ConfirmFor("stop", appRunning: false));   // nothing to close
        Assert.NotNull(Shell.ConfirmFor("clean", appRunning: false));
        Assert.Null(Shell.ConfirmFor("status", appRunning: true));
        Assert.Equal(["clean", "stop"], CommandCatalog.All.Where(c => c.Confirm).Select(c => c.Name).Order());
    }

    [Fact]
    public void The_logo_is_five_even_rows_and_only_where_it_fits()
    {
        Fancy(true);
        var rows = Logo.Lines(80);
        Assert.Equal(5, rows.Count);
        Assert.All(rows, r => Assert.Equal(Logo.Width, Ansi.Width(r)));
        Assert.Empty(Logo.Lines(Logo.Width - 1));                // too narrow
        Fancy(false);
        Assert.Empty(Logo.Lines(80));                            // no block letters in a plain console
    }

    [Fact]
    public void Slow_answers_say_how_long_they_took()
    {
        Fancy(true);
        Assert.Contains("2.5s", Ansi.Strip(Shell.FormatAnswer(Ansi.Accent, "Google accounts", "x", TimeSpan.FromSeconds(2.5))));
        Assert.DoesNotContain("0.3s", Ansi.Strip(Shell.FormatAnswer(Ansi.Accent, "Status", "x", TimeSpan.FromSeconds(0.3))));
    }

    [Theory]
    [InlineData(30 * 86400.0, "30 days")]
    [InlineData(86400.0, "1 day")]
    [InlineData(7200.0, "2 h")]
    [InlineData(90.0, "1.5 min")]
    [InlineData(5.0, "5 s")]
    [InlineData(0.0, "0 s")]
    public void Time_spans_read_like_words(double seconds, string expected) =>
        Assert.Equal(expected, Views.Span(TimeSpan.FromSeconds(seconds)));

    [Theory]
    [InlineData(0, "just now")]
    [InlineData(5 * 60, "5 min ago")]
    [InlineData(3 * 3600, "3 h ago")]
    [InlineData(30 * 3600, "yesterday")]
    [InlineData(3 * 86400, "3 days ago")]
    public void Last_seen_reads_like_a_person_would_say_it(int secondsAgo, string expected)
    {
        var now = new DateTimeOffset(2026, 11, 17, 12, 0, 0, TimeSpan.FromHours(5.5));
        Assert.Equal(expected, Views.Ago(now.AddSeconds(-secondsAgo), now));
    }
}
