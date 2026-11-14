// Phase 3 (files when it is off), PC side: the phone may fetch the Google key (never a sign-in) and learns the name of
// this PC's folder in the cloud. Run: node .work\p3-pc.js <repo>
const fs = require('fs');
const repo = process.argv[2];
function patch(rel, swaps) {
  const p = repo + '/' + rel;
  let s = fs.readFileSync(p, 'utf8');
  const crlf = s.includes('\r\n');
  if (crlf) s = s.replace(/\r\n/g, '\n');
  for (const [a, b] of swaps) {
    if (s.split(a).length !== 2) { console.log(rel + ' NOT ONCE: ' + a.slice(0, 90)); process.exit(1); }
    s = s.replace(a, () => b);
  }
  fs.writeFileSync(p, crlf ? s.replace(/\n/g, '\r\n') : s);
  console.log('ok', rel);
}

patch('src/CloudSSD.Mount/RcloneConfigService.cs', [[
`    /// <summary>Google Drive accounts that may be written to`,
`    /// <summary>
    /// The user's own Google key (OAuth client) that a Google Drive account is signed in with: the preferred account's
    /// when it has one, else any account's. Null while every account still uses rclone's shared login.
    /// </summary>
    public static (string ClientId, string ClientSecret)? OwnDriveClient(JsonObject dump, string? preferRemote = null)
    {
        (string, string)? Of(string name) =>
            dump[name] is JsonObject o && Str(o, "type") == "drive" && Str(o, "client_id") is { Length: > 0 } id ? (id, Str(o, "client_secret")) : null;
        if (preferRemote is { Length: > 0 } && Of(preferRemote) is { } preferred) return preferred;
        foreach (var kv in dump)
            if (Of(kv.Key) is { } any) return any;
        return null;
    }

    /// <summary>Google Drive accounts that may be written to`]]);

patch('src/CloudSSD.App/LocalMobileBridgeService.WhenOff.cs', [
  [`using CloudSSD.Core;
using Microsoft.Extensions.Logging;`,
`using CloudSSD.Core;
using CloudSSD.Mount;
using Microsoft.Extensions.Logging;`],
  [`/// A guest can never have it. This part only keeps the two answers; the copies come later (docs/WHEN_OFF_PLAN.md).
/// </summary>`,
`/// A guest can never have it. This part keeps the two answers and tells the device where this PC's copy is and which
/// Google key to sign in with; the copying itself is Mirror/DeviceMirrorService (docs/WHEN_OFF_PLAN.md).
/// </summary>`],
  [`    private static object WhenOffDto(PairedDevice d)
    {
        var s = WhenOffOf(d);
        return new { pc = s.Pc, device = s.Device, active = s.Active, guest = d.GuestUntil != null, since = s.Since?.ToUnixTimeMilliseconds() };
    }`,
`    /// <summary>Stands in for reading the Google key out of rclone's config (tests).</summary>
    internal Func<CancellationToken, Task<(string ClientId, string ClientSecret)?>>? WhenOffKeyOverride;

    /// <summary>A Google account of this PC is signed in with the user's own Google key (not rclone's shared one).</summary>
    private bool HasOwnGoogleKey =>
        WhenOffKeyOverride != null || _host.Remotes.Any(r => r.Type == "drive" && !_host.SharedClientRemotes.Contains(r.Name));

    /// <summary>The user's own Google key, for the device's own sign-in. Null while this PC still uses the shared one.</summary>
    private async Task<(string ClientId, string ClientSecret)?> WhenOffKeyAsync(CancellationToken ct)
    {
        if (WhenOffKeyOverride != null) return await WhenOffKeyOverride(ct);
        if (_host.Rclone is not { } rclone) return null;
        try
        {
            return RcloneConfigService.OwnDriveClient(await _host.RcloneConfig.DumpAsync(rclone, ct), _host.Settings.Mirror.Account);
        }
        catch (Exception e) when (e is not OperationCanceledException)
        {
            _log.LogDebug("The Google key could not be read: {Why}", e.GetType().Name);
            return null;
        }
    }

    private object WhenOffDto(PairedDevice d)
    {
        var s = WhenOffOf(d);
        return new
        {
            pc = s.Pc, device = s.Device, active = s.Active, guest = d.GuestUntil != null, since = s.Since?.ToUnixTimeMilliseconds(),
            // Only once both said yes: this PC's folder inside "Cloud-SSD Devices", and whether a Google key can be fetched.
            folder = s.Active ? _host.Mirror.DeviceFolder : null,
            key = s.Active && HasOwnGoogleKey
        };
    }`],
  [`            default:
                await SendJsonAsync(stream, 404, "Not Found", new { error = "Not found." }, ct);
                return true;
        }
    }
}`,
`            case "/api/whenoff/key":
            {
                // The Google key only (what a sign-in is asked with), never a sign-in itself: the device signs in to Google on
                // its own, so no account access ever travels over the home network. Only for a pair where both said yes.
                if (!WhenOffActive(me))
                {
                    await SendJsonAsync(stream, 403, "Forbidden", new { error = "Both sides must say yes first.", code = "not-active" }, ct);
                    return true;
                }
                if (await WhenOffKeyAsync(ct) is not { } k)
                {
                    await SendJsonAsync(stream, 409, "Conflict", new
                    {
                        error = "This PC still signs in to Google with the shared key. Switch it to your own Google key first (Cloud Drives).",
                        code = "shared-key"
                    }, ct);
                    return true;
                }
                await SendJsonAsync(stream, 200, "OK", new { clientId = k.ClientId, clientSecret = k.ClientSecret }, ct);
                return true;
            }
            default:
                await SendJsonAsync(stream, 404, "Not Found", new { error = "Not found." }, ct);
                return true;
        }
    }
}`]
]);

patch('src/CloudSSD.App/LocalMobileBridgeService.Security.cs', [[`"wol", "whenoff", "upload-clash"`, `"wol", "whenoff", "whenoff-key", "upload-clash"`]]);

patch('tests/CloudSSD.Tests/WhenOffTests.cs', [[
`    [Fact]
    public Task A_guest_can_never_have_it() => BridgeHarness.With(async env =>`,
`    [Fact]
    public Task The_google_key_goes_only_to_a_device_with_both_yeses_and_only_an_own_key() => BridgeHarness.With(async env =>
    {
        var token = await env.PairNew("Pixel", "inst-woff-03", "&kind=phone");
        var d = Dev(env, "Pixel");
        env.Bridge.WhenOffKeyOverride = _ => Task.FromResult<(string, string)?>(("id-123.apps.googleusercontent.com", "s3cret"));

        // One yes is not enough: no key, and the status names no folder.
        await env.Post("/api/whenoff/consent?on=1", token);
        Assert.Equal(HttpStatusCode.Forbidden, (await env.Get("/api/whenoff/key", token)).StatusCode);
        var waiting = (await env.Json(await env.Get("/api/status", token))).GetProperty("whenOff");
        Assert.Equal(System.Text.Json.JsonValueKind.Null, waiting.GetProperty("folder").ValueKind);
        Assert.False(waiting.GetProperty("key").GetBoolean());

        // Both said yes: the key (not a sign-in) and the name of this PC's folder in the cloud.
        env.Bridge.SetWhenOffPc(d.Id, true);
        var key = await env.Json(await env.Get("/api/whenoff/key", token));
        Assert.Equal("id-123.apps.googleusercontent.com", key.GetProperty("clientId").GetString());
        Assert.Equal("s3cret", key.GetProperty("clientSecret").GetString());
        var on = (await env.Json(await env.Get("/api/status", token))).GetProperty("whenOff");
        Assert.StartsWith(env.Host.Settings.MobileBridge.PcId, on.GetProperty("folder").GetString());
        Assert.True(on.GetProperty("key").GetBoolean());

        // This PC still on the shared key: there is nothing to hand over.
        env.Bridge.WhenOffKeyOverride = _ => Task.FromResult<(string, string)?>(null);
        var none = await env.Get("/api/whenoff/key", token);
        Assert.Equal(HttpStatusCode.Conflict, none.StatusCode);
        Assert.Equal("shared-key", (await env.Json(none)).GetProperty("code").GetString());

        // Taking the yes back closes it again.
        env.Bridge.WhenOffKeyOverride = _ => Task.FromResult<(string, string)?>(("id", "s"));
        await env.Post("/api/whenoff/consent?on=0", token);
        Assert.Equal(HttpStatusCode.Forbidden, (await env.Get("/api/whenoff/key", token)).StatusCode);
    });

    [Fact]
    public void The_own_google_key_is_read_from_the_accounts()
    {
        var dump = (System.Text.Json.Nodes.JsonObject)System.Text.Json.Nodes.JsonNode.Parse("""
            {
              "gdrive":  { "type": "drive", "token": "t" },
              "gdrive2": { "type": "drive", "client_id": "own-2", "client_secret": "sec-2" },
              "gdrive3": { "type": "drive", "client_id": "own-3", "client_secret": "sec-3" },
              "box":     { "type": "onedrive", "client_id": "not-google" },
              "CloudSSD": { "type": "union", "upstreams": "gdrive: gdrive2:" }
            }
            """)!;
        Assert.Equal(("own-3", "sec-3"), CloudSSD.Mount.RcloneConfigService.OwnDriveClient(dump, "gdrive3"));
        // The preferred account still on the shared key (or unknown): any account's own key.
        Assert.Equal(("own-2", "sec-2"), CloudSSD.Mount.RcloneConfigService.OwnDriveClient(dump, "gdrive"));
        Assert.Equal(("own-2", "sec-2"), CloudSSD.Mount.RcloneConfigService.OwnDriveClient(dump));
        dump.Remove("gdrive2");
        dump.Remove("gdrive3");
        Assert.Null(CloudSSD.Mount.RcloneConfigService.OwnDriveClient(dump, "gdrive"));
    }

    [Fact]
    public Task A_guest_can_never_have_it() => BridgeHarness.With(async env =>`]]);
