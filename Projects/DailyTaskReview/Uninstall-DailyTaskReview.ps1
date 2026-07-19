[CmdletBinding()]
param([switch]$KeepShortcut)

$ErrorActionPreference = 'Stop'
$DashboardDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DesktopRoot = Split-Path -Parent $DashboardDir
$TaskName = '每日任务复盘-07点'
$ShortcutPath = Join-Path $DesktopRoot '每日任务复盘面板.lnk'

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}
if (-not $KeepShortcut -and (Test-Path -LiteralPath $ShortcutPath)) {
    Remove-Item -LiteralPath $ShortcutPath -Force
}
Write-Output '已移除每日07:00定时任务；历史数据文件保留。'
