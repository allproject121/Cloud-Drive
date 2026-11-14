# Closes the running Cloud-SSD PC app the way a person does: asks its window to close, then answers its
# "Close Cloud Drive" box with No (the drives are unmounted; pending uploads get up to 60 s). When the box says a game
# is still running it answers Cancel and leaves the app open. UI Automation only: no mouse, no keys.
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
$p = Get-Process Cloud-SSD -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $p) { 'not running'; exit 0 }
[void]$p.CloseMainWindow()
$main = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$isWindow = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Window)
$deadline = (Get-Date).AddSeconds(90)
$answered = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 700
    if ($p.HasExited) { 'exited'; exit 0 }
    if ($answered) { continue }
    try { $box = $main.FindFirst([System.Windows.Automation.TreeScope]::Children, $isWindow) } catch { $box = $null }
    if (-not $box) { continue }
    $all = $box.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    $text = ($all | ForEach-Object { $_.Current.Name }) -join ' '
    $want = if ($text -match 'game is still running') { 'Cancel' } else { 'No' }
    $button = $all | Where-Object { $_.Current.ControlType -eq [System.Windows.Automation.ControlType]::Button -and $_.Current.Name -eq $want } | Select-Object -First 1
    if ($button) {
        $pat = $null
        if ($button.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$pat)) { $pat.Invoke(); $answered = $true; "answered: $want" }
        if ($want -eq 'Cancel') { 'a game is running: left open'; exit 1 }
    }
}
if ($p.HasExited) { 'exited' } else { 'still running after 90 s'; exit 1 }
