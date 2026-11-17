# Edge ke khule page ke button / link ko NAAM se dabana (mouse nahi hilta), ya page ki cheezein list karna.
# Windows ki UI Automation se; ui.ps1 ke mouse click Edge par nahi lag rahe the (17 Nov 2026).
#   page.ps1 -List                      saamne wale Edge page ke button / link / box (naam ke saath)
#   page.ps1 -List -Match "client"      sirf woh jinke naam mein yeh shabd ho
#   page.ps1 -Invoke "Create client"    us naam ka button / link dabao (poora naam; -Contains ho to hissa bhi chalega)
#   page.ps1 -SetValue "Name" -Text "Cloud-SSD Desktop 2"    us naam ke box mein likho
# Kabhi Google ka login / password / "Allow" / "Continue" (consent) is se mat dabao: woh user khud dabata hai.
param(
    [switch] $List,
    [string] $Match = '',
    [string] $Invoke = '',
    [switch] $Contains,
    [int] $Index = 0,
    [string] $Kind = '',
    [string] $SetValue = '',
    [string] $Text = '',
    [string] $WindowMatch = 'Google Cloud console'
)
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
$AE = [System.Windows.Automation.AutomationElement]
$CT = [System.Windows.Automation.ControlType]

$root = $AE::RootElement
$win = $null
foreach ($w in $root.FindAll('Children', [System.Windows.Automation.Condition]::TrueCondition)) {
    if ($w.Current.ClassName -eq 'Chrome_WidgetWin_1' -and $w.Current.Name -like "*$WindowMatch*") { $win = $w; break }
}
if (-not $win) { "Edge window with '$WindowMatch' in its title not found (is that tab in front?)"; exit 2 }
"window: " + $win.Current.Name

# Sirf web page ka hissa (Document), taaki Edge ke apne button (Back, Favorites ...) na aayein.
$doc = $win.FindFirst('Descendants', (New-Object System.Windows.Automation.PropertyCondition($AE::ControlTypeProperty, $CT::Document)))
if (-not $doc) { 'page content not found'; exit 3 }

$kinds = @($CT::Button, $CT::Hyperlink, $CT::Edit, $CT::CheckBox, $CT::RadioButton, $CT::ComboBox, $CT::MenuItem, $CT::TabItem, $CT::ListItem)
$conds = $kinds | ForEach-Object { New-Object System.Windows.Automation.PropertyCondition($AE::ControlTypeProperty, $_) }
$any = New-Object System.Windows.Automation.OrCondition($conds)
$els = $doc.FindAll('Descendants', $any)

function Kind($e) { $e.Current.ControlType.ProgrammaticName -replace 'ControlType\.', '' }

if ($List) {
    $i = 0
    foreach ($e in $els) {
        $n = $e.Current.Name
        if (-not $n) { continue }
        if ($Match -and $n -notlike "*$Match*") { continue }
        $r = $e.Current.BoundingRectangle
        $where = if ($r.IsEmpty -or $e.Current.IsOffscreen) { 'off-screen' } else { '{0},{1}' -f [int]($r.X + $r.Width / 2), [int]($r.Y + $r.Height / 2) }
        $val = ''
        if ((Kind $e) -eq 'Edit') { try { $val = '  value="' + $e.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern).Current.Value + '"' } catch { } }
        '{0,3} [{1,-11}] {2}  @{3}{4}{5}' -f $i, (Kind $e), $(if ($n.Length -gt 90) { $n.Substring(0, 90) + '…' } else { $n }), $where, $val, $(if (-not $e.Current.IsEnabled) { '  (disabled)' } else { '' })
        $i++
    }
    "($i items)"
    exit 0
}

function Find([string] $name) {
    $hits = @($els | Where-Object { $n = $_.Current.Name; if ($Contains) { $n -like "*$name*" } else { $n -eq $name } })
    if ($Kind) { $hits = @($hits | Where-Object { (Kind $_) -eq $Kind }) }   # jaise -Kind Hyperlink (ek hi naam ka checkbox bhi hota hai)
    if ($hits.Count -eq 0) { "nothing named '$name' on the page"; return $null }
    if ($hits.Count -gt 1 -and $Index -eq 0) { "$($hits.Count) items match '$name'; using the first (give -Index n for another)" }
    $hits[[math]::Min($Index, $hits.Count - 1)]
}

if ($Invoke) {
    $e = Find $Invoke
    if (-not $e) { exit 4 }
    if (-not $e.Current.IsEnabled) { "'$Invoke' is disabled"; exit 5 }
    $p = $null
    if ($e.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$p)) { $p.Invoke(); "invoked [$(Kind $e)] $($e.Current.Name)" }
    elseif ($e.TryGetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern, [ref]$p)) { $p.Select(); "selected [$(Kind $e)] $($e.Current.Name)" }
    elseif ($e.TryGetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern, [ref]$p)) { $p.Toggle(); "toggled [$(Kind $e)] $($e.Current.Name)" }
    elseif ($e.TryGetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern, [ref]$p)) { $p.Expand(); "expanded [$(Kind $e)] $($e.Current.Name)" }
    else { "'$Invoke' cannot be pressed through UI Automation"; exit 6 }
}

if ($SetValue) {
    $e = Find $SetValue
    if (-not $e) { exit 4 }
    $p = $null
    if ($e.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$p)) { $e.SetFocus(); $p.SetValue($Text); "set [$(Kind $e)] $($e.Current.Name) = $Text" }
    else { "'$SetValue' is not a text box"; exit 6 }
}
