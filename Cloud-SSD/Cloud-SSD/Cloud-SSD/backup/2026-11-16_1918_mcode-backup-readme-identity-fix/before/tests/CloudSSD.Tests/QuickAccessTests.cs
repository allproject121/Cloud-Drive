using System.Net;
using CloudSSD.App;
using Xunit;

namespace CloudSSD.Tests;

/// <summary>/api/pc/home: a phone opening this PC starts with File Explorer's Quick access, only what it may read.</summary>
public class QuickAccessTests
{
    [Fact]
    public Task The_phone_gets_the_pinned_folders_it_may_read_in_Explorers_order() => BridgeHarness.With(async env =>
    {
        var uploads = Directory.CreateDirectory(Path.Combine(env.Temp, "uploads")).FullName;
        env.Host.Settings.MobileBridge.UploadDirectory = uploads;
        env.Host.Settings.MobileBridge.AllowPcDisks = false;
        var work = Directory.CreateDirectory(Path.Combine(uploads, "Work")).FullName;
        var secret = Directory.CreateDirectory(Path.Combine(env.Temp, "elsewhere")).FullName;
        env.Bridge.QuickAccessOverride = () =>
        [
            new LocalMobileBridgeService.QuickAccessFolder("Work", work),
            new LocalMobileBridgeService.QuickAccessFolder("Elsewhere", secret),
            new LocalMobileBridgeService.QuickAccessFolder("Uploads", uploads),
        ];
        var token = await env.PairNew("Pixel", "inst-qa-01", "&kind=phone");

        var r = await env.Get("/api/pc/home", token);
        Assert.Equal(HttpStatusCode.OK, r.StatusCode);
        var home = await env.Json(r);
        var names = home.GetProperty("pinned").EnumerateArray().Select(p => p.GetProperty("name").GetString()).ToList();
        Assert.Equal(["Work", "Uploads"], names);                                // in order, without the one it may not read
        Assert.Equal(1, home.GetProperty("hidden").GetInt32());
        Assert.False(home.GetProperty("pcDisks").GetBoolean());
        Assert.Equal(work, home.GetProperty("pinned")[0].GetProperty("path").GetString());
        Assert.Equal("folder", home.GetProperty("pinned")[0].GetProperty("kind").GetString());

        // With the PC's own disks shared, every pinned folder on them is there.
        env.Host.Settings.MobileBridge.AllowPcDisks = true;
        var all = await env.Json(await env.Get("/api/pc/home", token));
        Assert.Equal(3, all.GetProperty("pinned").GetArrayLength());
        Assert.Equal(0, all.GetProperty("hidden").GetInt32());
    });

    [Fact]
    public void Known_folders_get_their_own_kind()
    {
        Assert.Equal("desktop", LocalMobileBridgeService.QuickAccessKind(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory)));
        Assert.Equal("documents", LocalMobileBridgeService.QuickAccessKind(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments) + "\\"));
        Assert.Equal("folder", LocalMobileBridgeService.QuickAccessKind(@"C:\Somewhere\Else"));
    }
}
