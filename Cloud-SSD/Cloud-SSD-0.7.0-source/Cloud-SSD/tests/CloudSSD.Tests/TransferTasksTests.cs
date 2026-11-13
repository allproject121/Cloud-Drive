using CloudSSD.App;
using Xunit;

namespace CloudSSD.Tests;

/// <summary>Transfers as tasks: many files in one, progress counted once, done / partial / failed at the end, Retry.</summary>
public class TransferTasksTests
{
    private sealed class Clock { public DateTimeOffset Now = DateTimeOffset.Now; }

    [Fact]
    public void A_task_counts_its_files_once_and_ends_done()
    {
        var c = new Clock();
        var tasks = new TransferTasks(() => c.Now);
        var changes = 0;
        tasks.Changed += _ => changes++;
        var t = tasks.Begin("t1", "toPc", "Redmi 12", "wifi", 2, 300, "This PC › Uploads", @"C:\Up", "folder", "MyApp");
        Assert.Equal("waiting", t.State);
        tasks.Progress("t1", "a", "a.js", 50);
        tasks.Progress("t1", "a", "a.js", 100);        // told again: the newest count, not added
        Assert.Equal("running", t.State);
        Assert.Equal(100, t.DoneBytes);
        tasks.FileDone("t1", "a", "a.js", 100);
        tasks.FileDone("t1", "a", "a.js", 100);         // once
        Assert.Equal(1, t.DoneFiles);
        c.Now += TimeSpan.FromSeconds(1);
        tasks.FileDone("t1", "b", "b.js", 200);
        Assert.Equal("done", t.State);
        Assert.Equal(300, t.DoneBytes);
        Assert.Equal("a.js", t.Name);        // the first file names the task
        Assert.False(t.CanRetry);
        Assert.False(t.CanCancel);
        Assert.NotNull(t.Ended);
        Assert.True(changes >= 4);
    }

    [Fact]
    public void Some_failed_is_partial_all_failed_is_failed_and_Retry_asks_the_handler()
    {
        var tasks = new TransferTasks();
        var t = tasks.Begin("t2", "toPhone", "Pixel", "usb", 2, 20);
        tasks.FileDone("t2", "a", "a", 10);
        tasks.FileFailed("t2", "b", "b", "SPACE");
        Assert.Equal("partial", t.State);
        Assert.Equal([new TransferFailure("b", "space")], t.Failed);
        Assert.True(t.CanRetry);
        TransferTask? asked = null;
        tasks.RetryHandler = x => { asked = x; return tasks.Begin("t3", x.Dir, x.Device, x.Link, 1, 10); };
        Assert.Equal("t3", tasks.Retry("t2")!.Id);
        Assert.Same(t, asked);

        var f = tasks.Begin("t4", "toPc", "Pixel", "wifi", 1, 5);
        tasks.FileFailed("t4", "x", "x", "weird");
        Assert.Equal("failed", f.State);
        Assert.Equal("other", f.Failed[0].Reason);
    }

    [Fact]
    public void Finish_counts_the_rest_as_failed_and_cancel_stops_it()
    {
        var tasks = new TransferTasks();
        var t = tasks.Begin("o1", "toPhone", "Pixel", "wifi", 3, 30);
        tasks.FileDone("o1", "a", "a", 10);
        tasks.Finish("o1", reasonForTheRest: "network");    // the offer ended
        Assert.Equal("partial", t.State);
        Assert.Equal(2, t.Failed.Count);
        Assert.All(t.Failed, x => Assert.Equal("network", x.Reason));

        var d = tasks.Begin("o2", "toPhone", "Pixel", "wifi", 2, 20);
        tasks.Finish("o2", stateIfNothing: "cancelled");     // declined
        Assert.Equal("cancelled", d.State);

        var r = tasks.Begin("o3", "toPc", "Pixel", "wifi", 2, 20);
        var stopped = false;
        tasks.CancelHandler = _ => stopped = true;
        Assert.True(tasks.Cancel("o3"));
        Assert.True(stopped);
        Assert.Equal("cancelled", r.State);
        Assert.False(tasks.Cancel("o3"));                     // only an open task
    }

    [Fact]
    public void Retry_and_cancel_go_to_the_part_that_made_the_task()
    {
        var tasks = new TransferTasks();
        string? who = null;
        tasks.RetryHandler = _ => { who = "default"; return null; };
        tasks.Handle("pf-", retry: _ => { who = "phone folders"; return null; }, cancel: _ => { who = "pf cancel"; return true; });
        var a = tasks.Begin("pf-1", "toPhone", "Pixel", "usb", 1, 1);
        tasks.FileFailed("pf-1", "x", "x", "network");
        tasks.Retry("pf-1");
        Assert.Equal("phone folders", who);
        var b = tasks.Begin("up-1", "toPc", "Pixel", "usb", 1, 1);
        tasks.FileFailed("up-1", "x", "x", "network");
        tasks.Retry("up-1");
        Assert.Equal("default", who);
        tasks.Begin("pf-2", "toPhone", "Pixel", "usb", 1, 1);
        Assert.True(tasks.Cancel("pf-2"));
        Assert.Equal("pf cancel", who);
    }

    [Fact]
    public void Links_map_to_the_model()
    {
        Assert.Equal("usb", TransferTasks.LinkOf(LinkKinds.UsbAdb));
        Assert.Equal("hotspot", TransferTasks.LinkOf(LinkKinds.PcHotspot));
        Assert.Equal("tailscale", TransferTasks.LinkOf(LinkKinds.Internet));
        Assert.Equal("wifi", TransferTasks.LinkOf(LinkKinds.Lan));
    }
}
