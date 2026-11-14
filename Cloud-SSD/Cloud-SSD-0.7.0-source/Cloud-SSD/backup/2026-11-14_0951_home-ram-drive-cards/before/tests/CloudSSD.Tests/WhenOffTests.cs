using System.Net;
using CloudSSD.App;
using CloudSSD.Core;
using Xunit;

namespace CloudSSD.Tests;

/// <summary>"Files when it is off": off until this PC and the device both say yes; never for a guest; never by default.</summary>
public class WhenOffTests
{
    private static PairedDevice Dev(BridgeEnv env, string name) => env.Host.Settings.MobileBridge.PairedDevices.Single(d => d.Name == name);

    [Fact]
    public Task It_is_off_for_a_new_device_and_needs_a_yes_on_both_sides() => BridgeHarness.With(async env =>
    {
        var token = await env.PairNew("Pixel", "inst-woff-01", "&kind=phone");
        var d = Dev(env, "Pixel");
        // A new device gets every access category by default, and still not this.
        Assert.False(LocalMobileBridgeService.WhenOffActive(d));
        var st = await env.Json(await env.Get("/api/whenoff/state", token));
        Assert.False(st.GetProperty("pc").GetBoolean());
        Assert.False(st.GetProperty("device").GetBoolean());
        Assert.False(st.GetProperty("active").GetBoolean());

        PairedDevice? told = null;
        env.Bridge.WhenOffChanged += x => told = x;

        // The phone says yes: still nothing, the PC has not.
        var yes = await env.Json(await env.Post("/api/whenoff/consent?on=1", token));
        Assert.True(yes.GetProperty("device").GetBoolean());
        Assert.False(yes.GetProperty("active").GetBoolean());
        Assert.Same(d, told);
        Assert.Null(d.WhenOffSince);

        // The PC says yes too: active, and the status tells the phone.
        Assert.True(env.Bridge.SetWhenOffPc(d.Id, true));
        Assert.True(LocalMobileBridgeService.WhenOffActive(d));
        Assert.NotNull(d.WhenOffSince);
        var status = await env.Json(await env.Get("/api/status", token));
        Assert.True(status.GetProperty("whenOff").GetProperty("active").GetBoolean());

        // Either side taking it back ends it.
        await env.Post("/api/whenoff/consent?on=0", token);
        Assert.False(LocalMobileBridgeService.WhenOffActive(d));
        Assert.Null(d.WhenOffSince);
        await env.Post("/api/whenoff/consent?on=1", token);
        Assert.True(LocalMobileBridgeService.WhenOffActive(d));
        Assert.True(env.Bridge.SetWhenOffPc(d.Id, false));
        Assert.False(LocalMobileBridgeService.WhenOffActive(d));

        // A blocked device has nothing, whatever was said before.
        env.Bridge.SetWhenOffPc(d.Id, true);
        d.IsBlocked = true;
        Assert.False(LocalMobileBridgeService.WhenOffActive(d));
    });

    [Fact]
    public Task A_guest_can_never_have_it() => BridgeHarness.With(async env =>
    {
        var invite = env.Bridge.CreateGuestInvite(TimeSpan.FromHours(1), AccessCategories.All);
        var r = await env.Http.PostAsync($"{env.Base}/api/pair?code={invite.Code}&name=Friend&installId=inst-woff-02&kind=phone", null);
        var token = (await env.Json(r)).GetProperty("token").GetString()!;
        var g = Dev(env, "Friend");
        Assert.Equal(HttpStatusCode.Forbidden, (await env.Post("/api/whenoff/consent?on=1", token)).StatusCode);
        Assert.False(env.Bridge.SetWhenOffPc(g.Id, true));
        Assert.False(g.WhenOffPc || g.WhenOffDevice);
        Assert.False(env.Bridge.SetWhenOffPc("no-such-device", true));
        // Without a paired device behind the request there is nothing to ask.
        Assert.NotEqual(HttpStatusCode.OK, (await env.Get("/api/whenoff/state", token: null)).StatusCode);
    });
}
