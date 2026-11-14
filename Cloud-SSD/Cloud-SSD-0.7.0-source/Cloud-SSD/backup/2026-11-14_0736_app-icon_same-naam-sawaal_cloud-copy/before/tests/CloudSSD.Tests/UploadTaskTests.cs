using System.Net;
using CloudSSD.App;
using CloudSSD.Core;
using Xunit;

namespace CloudSSD.Tests;

/// <summary>Files a device sends to this PC: one task per send; a guest's send waits for an OK ("Files to receive").</summary>
public class UploadTaskTests
{
    private static string Id(char c) => new(c, 32);

    private static Task With(Func<BridgeEnv, Task> body) => BridgeHarness.With(async env =>
    {
        env.Host.Settings.MobileBridge.UploadDirectory = Path.Combine(env.Temp, "uploads");
        await body(env);
    });

    private static async Task<string> Guest(BridgeEnv env, string name, string installId)
    {
        var invite = env.Bridge.CreateGuestInvite(TimeSpan.FromHours(1), [AccessCategories.Upload]);
        var r = await env.Http.PostAsync($"{env.Base}/api/pair?code={invite.Code}&name={name}&installId={installId}&kind=phone", null);
        return (await env.Json(r)).GetProperty("token").GetString()!;
    }

    [Fact]
    public Task My_own_phone_sends_without_a_question_and_the_send_is_one_task() => With(async env =>
    {
        var token = await env.PairNew("Pixel", "inst-upt-01", "&kind=phone");
        var q = "&task=ph-abc123&files=2&bytes=30&kind=folder&folder=MyApp";
        var a = await env.PostBytes($"/api/upload?filename=a.txt&uploadId={Id('a')}&offset=0&total=10{q}", new byte[10], token);
        Assert.Equal(HttpStatusCode.OK, a.StatusCode);
        var t = Assert.Single(env.Bridge.Tasks.All);
        Assert.StartsWith("up-", t.Id);
        Assert.EndsWith("-ph-abc123", t.Id);
        Assert.Equal(("toPc", "Pixel", "folder", "MyApp"), (t.Dir, t.Device, t.Kind, t.Folder));
        Assert.Equal((2, 1, "running"), (t.Files, t.DoneFiles, t.State));
        Assert.Equal(Path.Combine(env.Temp, "uploads", "MyApp"), t.OpenPath);

        var b = await env.PostBytes($"/api/upload?filename=b.txt&uploadId={Id('b')}&offset=0&total=20{q}", new byte[20], token);
        Assert.Equal(HttpStatusCode.OK, b.StatusCode);
        Assert.Equal(("done", 2, 30L), (t.State, t.DoneFiles, t.DoneBytes));
        Assert.Equal("a.txt", t.Name);
        Assert.True(File.Exists(Path.Combine(env.Temp, "uploads", "MyApp", "b.txt")));
        Assert.Single(env.Bridge.Tasks.All);                                     // both files, one task
    });

    [Fact]
    public Task A_guests_files_wait_for_an_OK_and_a_No_refuses_them() => With(async env =>
    {
        var guest = await Guest(env, "Friend", "inst-upt-02");
        var url = $"/api/upload?filename=party.jpg&uploadId={Id('c')}&offset=0&total=5&task=ph-g1&files=1&bytes=5";

        var first = await env.PostBytes(url, new byte[5], guest);
        Assert.Equal((HttpStatusCode)423, first.StatusCode);                     // nothing saved yet
        Assert.False(Directory.Exists(Path.Combine(env.Temp, "uploads")) && Directory.GetFiles(Path.Combine(env.Temp, "uploads")).Length > 0);
        var t = Assert.Single(env.Bridge.Tasks.All);
        Assert.Equal(("asking", "Friend", "party.jpg"), (t.State, t.Device, t.Name));
        Assert.Equal((HttpStatusCode)423, (await env.PostBytes(url, new byte[5], guest)).StatusCode);   // still asking, still one task
        Assert.Single(env.Bridge.Tasks.All);

        Assert.True(env.Bridge.Tasks.Accept(t.Id));
        Assert.Equal(HttpStatusCode.OK, (await env.PostBytes(url, new byte[5], guest)).StatusCode);
        Assert.Equal("done", t.State);
        Assert.True(File.Exists(Path.Combine(env.Temp, "uploads", "party.jpg")));

        // Another send from the same guest asks again; No refuses it.
        var url2 = $"/api/upload?filename=more.jpg&uploadId={Id('d')}&offset=0&total=5&task=ph-g2&files=1&bytes=5";
        Assert.Equal((HttpStatusCode)423, (await env.PostBytes(url2, new byte[5], guest)).StatusCode);
        var t2 = env.Bridge.Tasks.All.Single(x => x.State == "asking");
        Assert.True(env.Bridge.Tasks.Decline(t2.Id));
        Assert.Equal(HttpStatusCode.Forbidden, (await env.PostBytes(url2, new byte[5], guest)).StatusCode);
        Assert.False(File.Exists(Path.Combine(env.Temp, "uploads", "more.jpg")));
    });

    [Fact]
    public Task With_always_ask_my_own_phone_waits_too_and_replace_overwrites() => With(async env =>
    {
        var token = await env.PairNew("Pixel", "inst-upt-03", "&kind=phone");
        var dir = Directory.CreateDirectory(Path.Combine(env.Temp, "uploads")).FullName;
        await File.WriteAllTextAsync(Path.Combine(dir, "notes.txt"), "old");
        env.Host.Settings.MobileBridge.AskBeforeReceiving = "always";
        var url = $"/api/upload?filename=notes.txt&uploadId={Id('e')}&offset=0&total=3&task=ph-r1&files=1&bytes=3";
        Assert.Equal((HttpStatusCode)423, (await env.PostBytes(url, "new"u8.ToArray(), token)).StatusCode);
        var t = Assert.Single(env.Bridge.Tasks.All);
        Assert.True(env.Bridge.Tasks.Accept(t.Id, "replace"));
        Assert.Equal(HttpStatusCode.OK, (await env.PostBytes(url, "new"u8.ToArray(), token)).StatusCode);
        Assert.Equal("new", await File.ReadAllTextAsync(Path.Combine(dir, "notes.txt")));
        Assert.False(File.Exists(Path.Combine(dir, "notes (1).txt")));           // replaced, not kept beside
    });

    [Fact]
    public Task An_older_phone_that_names_no_task_still_gets_one_per_send() => With(async env =>
    {
        var token = await env.PairNew("Old", "inst-upt-04", "&kind=phone");
        await env.PostBytes($"/api/upload?filename=a.bin&uploadId={Id('f')}&offset=0&total=4", new byte[4], token);
        var t = Assert.Single(env.Bridge.Tasks.All);
        Assert.Contains("-auto", t.Id);
        Assert.Equal("done", t.State);
    });
}
