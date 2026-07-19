[CmdletBinding()]
param([switch]$TestMode)

$ErrorActionPreference = 'Stop'
$DashboardDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DesktopRoot = Split-Path -Parent $DashboardDir
$MainScript = Join-Path $DashboardDir 'DailyTaskReview.ps1'
$TaskName = '每日任务复盘-07点'
$ShortcutPath = Join-Path $DesktopRoot '每日任务复盘面板.lnk'
$ShortcutDescription = '每日任务复盘面板（WPF 深夜专注工作台）'
$ActionArgs = '-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $MainScript + '"'

function Test-InstallerSafety {
    if (-not (Test-Path -LiteralPath $MainScript)) { throw "Main script missing: $MainScript" }
    if ([string]::IsNullOrWhiteSpace($TaskName) -or $TaskName -ne '每日任务复盘-07点') { throw 'Unexpected task name' }
    if ((Split-Path -Parent $ShortcutPath) -ne $DesktopRoot) { throw 'Shortcut path is not at desktop root' }
    Write-Output 'PASS: installer safety'
    Write-Output 'SHORTCUT_ROOT_OK'
    if ($ActionArgs -notmatch '-WindowStyle Hidden') { throw 'Launcher window is not hidden' }
    Write-Output 'WINDOW_HIDDEN_OK'
    if ($ShortcutDescription -notmatch 'WPF' -or $ShortcutDescription -match 'Minecraft') { throw 'Unexpected shortcut theme description' }
    Write-Output 'THEME_DESCRIPTION_OK'
    if (-not (Test-Path -LiteralPath (Join-Path $DashboardDir 'MidnightFocusWPF.ps1'))) { throw 'WPF module missing' }
    if (-not (Test-Path -LiteralPath (Join-Path $DashboardDir 'assets\midnight-constellation-v2.png'))) { throw 'WPF background asset missing' }
    Write-Output 'WPF_ASSETS_OK'
}

function Install-DailyTaskReview {
    if (-not (Test-Path -LiteralPath (Join-Path $DashboardDir 'data'))) { New-Item -ItemType Directory -Path (Join-Path $DashboardDir 'data') -Force | Out-Null }
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $ActionArgs
    $trigger = New-ScheduledTaskTrigger -Daily -At '07:00'
    $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Description '每天07:00打开每日任务复盘面板并生成当天记录' -Force | Out-Null
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = 'powershell.exe'
    $shortcut.Arguments = $ActionArgs
    $shortcut.WorkingDirectory = $DashboardDir
    $shortcut.Description = $ShortcutDescription
    $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,1"
    $shortcut.Save()
    Write-Output ('已安装：每天07:00启动；快捷方式：' + $ShortcutPath)
}

if ($TestMode) { Test-InstallerSafety; exit 0 }
Test-InstallerSafety
Install-DailyTaskReview
