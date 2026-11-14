using System.Net.Sockets;
using CloudSSD.Core;
using Microsoft.Extensions.Logging;

namespace CloudSSD.App;

/// <summary>How "Files when it is off" stands between this PC and one device.</summary>
/// <param name="Pc">Someone at this PC said yes for that device.</param>
/// <param name="Device">The device said yes for this PC.</param>
/// <param name="Active">Both said yes and the device is not a guest: copies may be kept and read.</param>
public sealed record WhenOffState(bool Pc, bool Device, bool Active, DateTimeOffset? Since);

/// <summary>
/// "Files when it is off" ("Band hone par bhi files"): each device keeps a copy of its files in the cloud so the other
/// one can open them while it is switched off. It is its own yes/no, per pair, on BOTH sides, and off until both say
/// yes — on purpose not one of the access categories: "allow everything" for a new device must never switch it on.
/// A guest can never have it. This part only keeps the two answers; the copies come later (docs/WHEN_OFF_PLAN.md).
/// </summary>
public sealed partial class LocalMobileBridgeService
{
    /// <summary>The two answers changed for a device (shown on its card and its permissions).</summary>
    public event Action<PairedDevice>? WhenOffChanged;

    public static WhenOffState WhenOffOf(PairedDevice d) =>
        new(d.WhenOffPc, d.WhenOffDevice, d.WhenOffPc && d.WhenOffDevice && d.GuestUntil is null && !d.IsBlocked, d.WhenOffSince);

    /// <summary>Both sides said yes for this device (and it is no guest and not blocked).</summary>
    public static bool WhenOffActive(PairedDevice d) => WhenOffOf(d).Active;

    /// <summary>This PC's answer for a device. False for a device that is not paired, or a guest asked to be switched on.</summary>
    public bool SetWhenOffPc(string deviceId, bool on)
    {
        PairedDevice? d;
        lock (_devicesLock)
        {
            d = _host.Settings.MobileBridge.PairedDevices.FirstOrDefault(x => x.Id == deviceId);
            if (d is null || (on && d.GuestUntil != null)) return false;
            if (d.WhenOffPc == on) return true;
            d.WhenOffPc = on;
            StampWhenOff(d);
        }
        _host.SaveSettings();
        RaiseWhenOffChanged(d);
        return true;
    }

    /// <summary>When both answers are yes for the first time (or again), that moment is kept; else none.</summary>
    private void StampWhenOff(PairedDevice d) =>
        d.WhenOffSince = d.WhenOffPc && d.WhenOffDevice ? d.WhenOffSince ?? Now() : null;

    private void RaiseWhenOffChanged(PairedDevice d)
    {
        try { WhenOffChanged?.Invoke(d); } catch (Exception e) { _log.LogDebug(e, "WhenOffChanged handler failed"); }
        RaiseDevicesChanged();
    }

    private static object WhenOffDto(PairedDevice d)
    {
        var s = WhenOffOf(d);
        return new { pc = s.Pc, device = s.Device, active = s.Active, guest = d.GuestUntil != null, since = s.Since?.ToUnixTimeMilliseconds() };
    }

    /// <summary>/api/whenoff/*: the device reads how it stands and gives or takes back its own answer. True when handled.</summary>
    private async Task<bool> TryHandleWhenOffRouteAsync(string method, string path, Dictionary<string, string> q, NetworkStream stream,
        Caller caller, CancellationToken ct)
    {
        if (!path.StartsWith("/api/whenoff/", StringComparison.OrdinalIgnoreCase)) return false;
        if (caller.Device is not { } me)
        {
            await SendJsonAsync(stream, 403, "Forbidden", new { error = "Only a paired device has this." }, ct);
            return true;
        }
        switch (path.ToLowerInvariant())
        {
            case "/api/whenoff/state":
                await SendJsonAsync(stream, 200, "OK", WhenOffDto(me), ct);
                return true;
            case "/api/whenoff/consent" when method == "POST":
            {
                bool on = q.GetValueOrDefault("on") is "1" or "true";
                if (on && me.GuestUntil != null)
                {
                    await SendJsonAsync(stream, 403, "Forbidden", new { error = "A guest cannot use this.", code = "guest" }, ct);
                    return true;
                }
                bool changed;
                lock (_devicesLock)
                {
                    changed = me.WhenOffDevice != on;
                    me.WhenOffDevice = on;
                    StampWhenOff(me);
                }
                if (changed)
                {
                    _host.SaveSettings();
                    RaiseWhenOffChanged(me);
                }
                await SendJsonAsync(stream, 200, "OK", WhenOffDto(me), ct);
                return true;
            }
            default:
                await SendJsonAsync(stream, 404, "Not Found", new { error = "Not found." }, ct);
                return true;
        }
    }
}
