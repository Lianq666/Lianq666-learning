[CmdletBinding()]
param(
    [switch]$TestMode,
    [switch]$SummaryTestMode,
    [switch]$InstallMode,
    [switch]$UiTestMode,
    [switch]$VisualTestMode,
    [switch]$MidnightFocusTestMode,
    [switch]$ProgressInteractionTestMode,
    [switch]$WpfStructureTestMode,
    [switch]$WpfProgressTestMode,
    [switch]$WpfNavigationTestMode,
    [switch]$WpfSummaryVisualTestMode,
    [switch]$WpfRenderPreviewMode,
    [switch]$RenderPreviewMode,
    [string]$PreviewPath,
    [ValidateSet('Today','Week','Month')][string]$PreviewPage='Today',
    [int]$PreviewWidth = 1440,
    [int]$PreviewHeight = 920
)

$ErrorActionPreference = 'Stop'
$script:BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:DataDir = Join-Path $script:BaseDir 'data'
$script:ConfigPath = Join-Path $script:BaseDir 'config.json'

function ConvertTo-MutableHashtable {
    param([Parameter(Mandatory=$true)]$InputObject)
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $InputObject.Keys) { $result[$key] = ConvertTo-MutableHashtable $InputObject[$key] }
        return $result
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $items = @()
        foreach ($item in $InputObject) { $items += ,(ConvertTo-MutableHashtable $item) }
        return $items
    }
    if ($InputObject.PSObject -and $InputObject.PSObject.Properties.Count -gt 0 -and $InputObject -isnot [string]) {
        $result = @{}
        foreach ($property in $InputObject.PSObject.Properties) { $result[$property.Name] = ConvertTo-MutableHashtable $property.Value }
        return $result
    }
    return $InputObject
}

function Get-RoutineTemplate {
    return @(
        @{ Id='wake'; Time='7:00—7:30'; Task='起床、洗漱、早餐'; Standard='不赖床；拉开窗帘接触自然光' }
        @{ Id='morning_move'; Time='7:30—8:00'; Task='晨间运动/拉伸/散步'; Standard='至少活动15分钟' }
        @{ Id='math'; Time='8:00—10:00'; Task='数学基础'; Standard='30分钟学习 + 90分钟做题，记录错题' }
        @{ Id='break_morning'; Time='10:00—10:30'; Task='休息、水果或咖啡'; Standard='离开书桌，放松眼睛' }
        @{ Id='major'; Time='10:30—12:00'; Task='电子信息专业基础'; Standard='电路为主，逐步加入模电、数电、C语言' }
        @{ Id='lunch'; Time='12:00—14:00'; Task='午饭、午休'; Standard='午睡20—40分钟，最长不超过30分钟更稳妥' }
        @{ Id='python_ai'; Time='14:00—16:00'; Task='Python / AI'; Standard='学一个知识点并写出可运行的小练习' }
        @{ Id='break_afternoon'; Time='16:00—16:30'; Task='休息'; Standard='不连续刷短视频' }
        @{ Id='practice'; Time='16:30—18:00'; Task='电子实践'; Standard='Arduino/STM32/电路仿真/实验记录四选一' }
        @{ Id='dinner'; Time='18:00—19:00'; Task='晚饭、散步'; Standard='适度活动，不把晚饭拖得太晚' }
        @{ Id='fitness'; Time='19:00—19:40'; Task='健身训练'; Standard='力量+体能，身体不适时改为轻度散步' }
        @{ Id='english'; Time='19:40—20:30'; Task='英语'; Standard='20个词汇 + 1个长难句，写下不会的词' }
        @{ Id='review'; Time='20:30—21:00'; Task='总结复盘'; Standard='记录完成项、产出物、明日第一任务' }
        @{ Id='driving'; Time='21:00—21:40'; Task='科目一刷题'; Standard='完成一组题，记录错题原因' }
        @{ Id='free'; Time='21:40—22:30'; Task='自由时间'; Standard='洗澡、阅读或适度娱乐' }
        @{ Id='sleep_prep'; Time='22:30—23:00'; Task='睡前准备'; Standard='关闭高刺激内容，整理书桌和明日任务' }
        @{ Id='sleep'; Time='23:00'; Task='睡觉'; Standard='保证第二天7:00起床' }
    )
}

function Get-CoreTaskTemplate {
    return @(
        @{ Id='core_math'; Group='必须完成'; Text='数学2小时：完成当天章节、例题和错题整理' }
        @{ Id='core_major'; Group='必须完成'; Text='电路/专业基础1.5小时：写出定义、公式和至少1道应用题' }
        @{ Id='core_python'; Group='必须完成'; Text='Python/AI至少1小时：代码运行成功或完成一次有效调试' }
        @{ Id='core_english'; Group='必须完成'; Text='英语1小时以内：20个词汇 + 1个长难句' }
        @{ Id='core_move'; Group='必须完成'; Text='运动或散步至少15—40分钟' }
        @{ Id='core_sleep'; Group='必须完成'; Text='23:00前准备睡觉，保证明天起床时间' }
        @{ Id='adv_practice'; Group='形成优势'; Text='电子实践1.5小时：实验、仿真、接线或STM32练习' }
        @{ Id='adv_github'; Group='形成优势'; Text='GitHub提交一次学习笔记、代码或项目进度（不必每天提交）' }
        @{ Id='adv_driving'; Group='形成优势'; Text='科目一刷题40分钟' }
        @{ Id='adv_review'; Group='形成优势'; Text='复盘写清楚“今天真正产出了什么”' }
    )
}

function New-DailyRecord {
    param([Parameter(Mandatory=$true)][string]$DateKey)
    $start = [datetime]'2026-07-15'
    $dayNumber = ([datetime]::ParseExact($DateKey,'yyyy-MM-dd',$null) - $start).Days + 1
    $routine = @()
    foreach ($row in (Get-RoutineTemplate)) {
        $routine += ,@{ Id=$row.Id; Time=$row.Time; Task=$row.Task; Standard=$row.Standard; Done=$false }
    }
    $core = @()
    foreach ($row in (Get-CoreTaskTemplate)) {
        $core += ,@{ Id=$row.Id; Group=$row.Group; Text=$row.Text; Done=$false }
    }
    return @{
        Date=$DateKey
        DayNumber=$dayNumber
        Energy=''
        Routine=$routine
        CoreTasks=$core
        Outputs=@{ Math=''; Major=''; PythonAI=''; Practice=''; English=''; GitHub='' }
        Review=@{ Main=''; Reason=''; Tomorrow=''; Improve='' }
        ExtraPlanBreak=@{ Enabled=$false; Item=''; Priority=''; Reason=''; Impact='' }
        CreatedAt=(Get-Date).ToString('s')
        UpdatedAt=(Get-Date).ToString('s')
    }
}

function Save-DailyRecord {
    param([Parameter(Mandatory=$true)][hashtable]$Record)
    if (-not (Test-Path -LiteralPath $script:DataDir)) { New-Item -ItemType Directory -Path $script:DataDir -Force | Out-Null }
    $Record.UpdatedAt = (Get-Date).ToString('s')
    $path = Join-Path $script:DataDir ($Record.Date + '.json')
    $temp = $path + '.tmp'
    $Record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $temp -Encoding UTF8
    Move-Item -LiteralPath $temp -Destination $path -Force
    return $path
}

function Load-DailyRecord {
    param([Parameter(Mandatory=$true)][string]$DateKey)
    if (-not (Test-Path -LiteralPath $script:DataDir)) { New-Item -ItemType Directory -Path $script:DataDir -Force | Out-Null }
    $path = Join-Path $script:DataDir ($DateKey + '.json')
    if (Test-Path -LiteralPath $path) {
        return ConvertTo-MutableHashtable (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    $record = New-DailyRecord -DateKey $DateKey
    Save-DailyRecord -Record $record | Out-Null
    return $record
}

function Get-ProgressStats {
    param([Parameter(Mandatory=$true)][hashtable]$Record)
    $all = @($Record.Routine) + @($Record.CoreTasks)
    $total = $all.Count
    $done = @($all | Where-Object { $_.Done -eq $true }).Count
    $percent = if ($total -gt 0) { [math]::Round(($done / $total) * 100, 0) } else { 0 }
    return [ordered]@{ Done=$done; Total=$total; Percent=$percent }
}

function Set-TaskCompletion {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Record,
        [Parameter(Mandatory=$true)][ValidateSet('Routine','Core')][string]$Type,
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][bool]$Done
    )
    $collection = if ($Type -eq 'Routine') { @($Record.Routine) } else { @($Record.CoreTasks) }
    $item = @($collection | Where-Object { [string]$_.Id -eq $Id })[0]
    if ($null -eq $item) { throw ('task not found: {0}/{1}' -f $Type,$Id) }
    $item.Done = $Done
    return Get-ProgressStats -Record $Record
}

function Get-UnfinishedItems {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Record,
        [switch]$IncludeRoutine
    )
    $items = @()
    foreach ($task in @($Record.CoreTasks)) {
        if (-not $task.Done) {
            $items += ,@{ Kind='核心任务'; Group=$task.Group; Id=$task.Id; Text=$task.Text }
        }
    }
    if ($IncludeRoutine) {
        foreach ($task in @($Record.Routine)) {
            if (-not $task.Done) {
                $items += ,@{ Kind='作息'; Group='正式作息'; Id=$task.Id; Text=($task.Time + ' ' + $task.Task) }
            }
        }
    }
    return $items
}

function Get-RecordFilesInRange {
    param([datetime]$StartDate, [datetime]$EndDate)
    if (-not (Test-Path -LiteralPath $script:DataDir)) { return @() }
    $records = @()
    foreach ($file in Get-ChildItem -LiteralPath $script:DataDir -Filter '*.json' -File) {
        try {
            $date = [datetime]::ParseExact($file.BaseName, 'yyyy-MM-dd', $null)
            if ($date.Date -ge $StartDate.Date -and $date.Date -le $EndDate.Date) {
                $records += ,(ConvertTo-MutableHashtable (Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json))
            }
        } catch { }
    }
    return $records
}

function Get-PeriodSummary {
    param(
        [Parameter(Mandatory=$true)][datetime]$StartDate,
        [Parameter(Mandatory=$true)][datetime]$EndDate
    )
    $records = @(Get-RecordFilesInRange -StartDate $StartDate -EndDate $EndDate)
    $done = 0; $total = 0; $sleepDone = 0; $outputCount = 0; $extraCount = 0
    $missed = @{}
    foreach ($record in $records) {
        $stats = Get-ProgressStats -Record $record
        $done += $stats.Done; $total += $stats.Total
        $sleep = @($record.CoreTasks | Where-Object { $_.Id -eq 'core_sleep' -and $_.Done }).Count
        if ($sleep -gt 0) { $sleepDone++ }
        foreach ($value in $record.Outputs.Values) { if (-not [string]::IsNullOrWhiteSpace([string]$value)) { $outputCount++ } }
        if ($record.ExtraPlanBreak.Enabled) { $extraCount++ }
        foreach ($task in @($record.CoreTasks | Where-Object { -not $_.Done })) {
            if (-not $missed.ContainsKey($task.Text)) { $missed[$task.Text] = 0 }
            $missed[$task.Text]++
        }
    }
    $rate = if ($total -gt 0) { [math]::Round(($done / $total) * 100, 0) } else { 0 }
    $mostMissed = ''
    if ($missed.Count -gt 0) {
        $mostMissed = ($missed.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    }
    return [ordered]@{
        StartDate=$StartDate.ToString('yyyy-MM-dd')
        EndDate=$EndDate.ToString('yyyy-MM-dd')
        Days=$records.Count
        Done=$done
        Total=$total
        CompletionRate=$rate
        SleepDays=$sleepDone
        OutputCount=$outputCount
        ExtraPlanBreaks=$extraCount
        MostMissed=$mostMissed
    }
}

function Get-StandardAdvice {
    param([Parameter(Mandatory=$true)][hashtable]$Summary)
    $rate = [int]$Summary.CompletionRate
    if ($Summary.Days -lt 2) {
        return '记录不足：先连续记录至少2天，再调整学习标准。'
    }
    if ($rate -lt 60) {
        return '降低标准：当前完成率偏低，建议减少并行任务，保留数学、英语、专业基础和Python的最低线。'
    }
    if ($rate -le 85) {
        $missed = if ([string]::IsNullOrWhiteSpace($Summary.MostMissed)) { '最常遗漏任务' } else { $Summary.MostMissed }
        return ('保持标准：当前完成率适中，先修复一项薄弱环节。最常遗漏：' + $missed)
    }
    return '提高标准：当前完成率稳定较高，只增加一个提高目标，不整体加码。'
}

function Test-SummaryModel {
    $oldDir = $script:DataDir
    $script:DataDir = Join-Path ([IO.Path]::GetTempPath()) ('DailyTaskReviewSummaryTest-' + [guid]::NewGuid().ToString('N'))
    $dateKeys = @('2099-02-01','2099-02-02','2099-02-03','2099-02-04','2099-02-05','2099-02-06')
    $targetCounts = @(11,11,20,20,25,25)
    for ($i=0; $i -lt $dateKeys.Count; $i++) {
        $record = New-DailyRecord -DateKey $dateKeys[$i]
        $items = @($record.Routine) + @($record.CoreTasks)
        for ($j=0; $j -lt $targetCounts[$i]; $j++) { $items[$j].Done = $true }
        Save-DailyRecord -Record $record | Out-Null
    }
    $low = Get-PeriodSummary -StartDate ([datetime]'2099-02-01') -EndDate ([datetime]'2099-02-02')
    $mid = Get-PeriodSummary -StartDate ([datetime]'2099-02-03') -EndDate ([datetime]'2099-02-04')
    $high = Get-PeriodSummary -StartDate ([datetime]'2099-02-05') -EndDate ([datetime]'2099-02-06')
    if ((Get-StandardAdvice -Summary $low) -notmatch '降低标准') { throw 'low threshold mismatch' }
    if ((Get-StandardAdvice -Summary $mid) -notmatch '保持标准') { throw 'mid threshold mismatch' }
    if ((Get-StandardAdvice -Summary $high) -notmatch '提高标准') { throw 'high threshold mismatch' }
    $script:DataDir = $oldDir
    Write-Output 'PASS: summary thresholds'
}

function New-UiFont {
    param([float]$Size, [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular)
    return New-Object System.Drawing.Font -ArgumentList @('Microsoft YaHei UI', $Size, $Style)
}

function Get-UiColor {
    param([string]$Hex)
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function Initialize-UiPalette {
    $script:Palette = @{
        Stone = Get-UiColor '#2B2B2B'
        DeepStone = Get-UiColor '#171717'
        StoneLight = Get-UiColor '#4A4A4A'
        Grass = Get-UiColor '#5B9F3C'
        GrassDark = Get-UiColor '#396B29'
        Dirt = Get-UiColor '#8B5A2B'
        DirtDark = Get-UiColor '#5A381C'
        Diamond = Get-UiColor '#55D6E8'
        Redstone = Get-UiColor '#F04A4A'
        Gold = Get-UiColor '#F2C94C'
        Amethyst = Get-UiColor '#B47CFF'
        Paper = Get-UiColor '#F2F0E6'
        Muted = Get-UiColor '#C4C4BA'
        Black = Get-UiColor '#111111'
    }
    $texturePath = Join-Path $script:BaseDir 'assets\grass_block_hd.png'
    $script:GrassTexture = $null
    if (Test-Path -LiteralPath $texturePath) {
        $source = [System.Drawing.Image]::FromFile($texturePath)
        $script:GrassTexture = New-Object System.Drawing.Bitmap $source
        $source.Dispose()
    }
}

function New-BlockLabel {
    param(
        [string]$Text,
        [int]$Width = 180,
        [int]$Height = 30,
        [float]$FontSize = 11,
        [System.Drawing.FontStyle]$FontStyle = [System.Drawing.FontStyle]::Regular,
        [System.Drawing.Color]$BackColor = [System.Drawing.Color]::Transparent,
        [System.Drawing.Color]$ForeColor = [System.Drawing.Color]::White
    )
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Width = $Width
    $label.Height = $Height
    $label.Font = New-UiFont -Size $FontSize -Style $FontStyle
    $label.BackColor = $BackColor
    $label.ForeColor = $ForeColor
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $label.Padding = New-Object System.Windows.Forms.Padding(6,0,6,0)
    return $label
}

function New-SectionHeader {
    param([string]$Text, [int]$Width)
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Width = $Width
    $panel.Height = 52
    $panel.BackColor = $script:Palette.DirtDark
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    if ($null -ne $script:GrassTexture) {
        $block = New-Object System.Windows.Forms.PictureBox
        $block.Location = New-Object System.Drawing.Point(4,4)
        $block.Size = New-Object System.Drawing.Size(44,42)
        $block.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
        $block.Image = $script:GrassTexture
        $panel.Controls.Add($block)
    }
    $label = New-BlockLabel -Text $Text -Width ($Width - 56) -Height 50 -FontSize 18 -FontStyle ([System.Drawing.FontStyle]::Bold) -BackColor $script:Palette.DirtDark -ForeColor $script:Palette.Gold
    $label.Location = New-Object System.Drawing.Point(52,0)
    $panel.Controls.Add($label)
    return $panel
}

function Set-RecordTextValue {
    param([string]$Section, [string]$Key, [string]$Value)
    $script:CurrentRecord[$Section][$Key] = $Value
    $script:IsDirty = $true
}

function New-TextInputRow {
    param(
        [System.Windows.Forms.Control]$Parent,
        [int]$Top,
        [string]$LabelText,
        [string]$Section,
        [string]$Key,
        [int]$Width = 1240
    )
    $label = New-BlockLabel -Text $LabelText -Width 230 -Height 60 -FontSize 11 -BackColor $script:Palette.StoneLight -ForeColor $script:Palette.Paper
    $label.Location = New-Object System.Drawing.Point(10,$Top)
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Location = New-Object System.Drawing.Point(250,($Top + 4))
    $tb.Width = ($Width - 270)
    $tb.Height = 52
    $tb.Multiline = $true
    $tb.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $tb.Font = New-UiFont -Size 11
    $tb.BackColor = $script:Palette.Paper
    $tb.ForeColor = $script:Palette.Black
    $tb.Text = [string]$script:CurrentRecord[$Section][$Key]
    $tb.Tag = @{ Section=$Section; Key=$Key }
    $tb.Add_TextChanged({ Set-RecordTextValue -Section $this.Tag.Section -Key $this.Tag.Key -Value $this.Text })
    $Parent.Controls.Add($label)
    $Parent.Controls.Add($tb)
    return $tb
}

function Refresh-Progress {
    if ($null -eq $script:ProgressBar) { return }
    $stats = Get-ProgressStats -Record $script:CurrentRecord
    $script:TargetProgress = [math]::Min(100, [math]::Max(0, [int]$stats.Percent))
    $script:ProgressLabel.Text = ('完成进度：{0}/{1}  ({2}%)' -f $stats.Done, $stats.Total, $stats.Percent)
    if ($stats.Percent -ge 85) { $script:ProgressLabel.ForeColor = $script:Palette.Grass }
    elseif ($stats.Percent -ge 60) { $script:ProgressLabel.ForeColor = $script:Palette.Gold }
    else { $script:ProgressLabel.ForeColor = $script:Palette.Redstone }
    Refresh-Reminder
}

function Refresh-Reminder {
    if ($null -eq $script:ReminderLabel) { return }
    $items = @(Get-UnfinishedItems -Record $script:CurrentRecord)
    $must = @($items | Where-Object { $_.Group -eq '必须完成' })
    if ($items.Count -eq 0) {
        $script:ReminderLabel.Text = '任务状态：全部完成，今日经验值 +1'
        $script:ReminderLabel.ForeColor = $script:Palette.Grass
        return
    }
    $preview = @($items | Select-Object -First 2 | ForEach-Object { $_.Text }) -join '；'
    if ($must.Count -gt 0) {
        $script:ReminderLabel.Text = ('未完成提醒：{0} 项核心任务。{1}' -f $must.Count, $preview)
        $script:ReminderLabel.ForeColor = $script:Palette.Redstone
    } else {
        $script:ReminderLabel.Text = ('待完成：{0} 项提高任务。{1}' -f $items.Count, $preview)
        $script:ReminderLabel.ForeColor = $script:Palette.Gold
    }
}

function Show-UnfinishedReminder {
    $items = @(Get-UnfinishedItems -Record $script:CurrentRecord -IncludeRoutine)
    if ($items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show($script:Form, '今天的作息和任务全部完成。','方块成就：全清！',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    $text = ($items | ForEach-Object { '· [' + $_.Kind + '] ' + $_.Text }) -join [Environment]::NewLine
    [System.Windows.Forms.MessageBox]::Show($script:Form, ('还有以下项目未完成：' + [Environment]::NewLine + $text),'任务未完成提醒',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
}

function Save-CurrentRecord {
    Save-DailyRecord -Record $script:CurrentRecord | Out-Null
    $script:IsDirty = $false
    $script:SaveLabel.Text = '已保存：' + (Get-Date).ToString('HH:mm:ss')
    $script:SaveLabel.ForeColor = $script:Palette.Grass
    Refresh-SummaryPage -PageType 'Week'
    Refresh-SummaryPage -PageType 'Month'
}

function New-SummaryText {
    param([string]$PageType)
    $today = [datetime]::ParseExact($script:CurrentRecord.Date,'yyyy-MM-dd',$null)
    if ($PageType -eq 'Week') {
        $start = $today.Date.AddDays(-6); $title = '本周方块经验统计'
    } else {
        $start = New-Object datetime($today.Year,$today.Month,1); $title = '本月世界进度统计'
    }
    $summary = Get-PeriodSummary -StartDate $start -EndDate $today.Date
    $advice = Get-StandardAdvice -Summary $summary
    $days = if ($summary.Days -eq 0) { '暂无记录' } else { [string]$summary.Days }
    $lines = @(
        $title
        ('统计范围：{0} 至 {1}' -f $summary.StartDate, $summary.EndDate)
        ('有效记录天数：{0}' -f $days)
        ('总任务完成率：{0}%' -f $summary.CompletionRate)
        ('睡眠按时完成：{0} 天' -f $summary.SleepDays)
        ('学习产出填写数：{0}' -f $summary.OutputCount)
        ('额外事项打破计划：{0} 次' -f $summary.ExtraPlanBreaks)
        ('最常遗漏任务：{0}' -f $(if ([string]::IsNullOrWhiteSpace($summary.MostMissed)) { '暂无' } else { $summary.MostMissed }))
        ''
        ('标准评估：' + $advice)
        '建议：每次只调整一个变量；先保证睡眠和数学/英语/专业基础的最低线，再增加项目任务。'
    )
    return ($lines -join [Environment]::NewLine)
}

function Refresh-SummaryPage {
    param([ValidateSet('Week','Month')][string]$PageType)
    if ($null -ne $script:SummaryLabels[$PageType]) {
        $script:SummaryLabels[$PageType].Text = New-SummaryText -PageType $PageType
    }
}

function Add-BoundCheckBox {
    param([System.Windows.Forms.Control]$Parent, [hashtable]$Item, [string]$Type, [int]$Width = 1230)
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = if ($Type -eq 'Routine') { $Item.Task } else { $Item.Text }
    $cb.Width = $Width
    $cb.Height = 40
    $cb.AutoSize = $false
    $cb.Font = New-UiFont -Size 11
    $cb.ForeColor = $script:Palette.Paper
    $cb.BackColor = $script:Palette.Stone
    $cb.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cb.Checked = [bool]$Item.Done
    $cb.Tag = @{ Type=$Type; Id=$Item.Id }
    $cb.Add_CheckedChanged({
        if ($this.Tag.Type -eq 'Routine') {
            $row = @($script:CurrentRecord.Routine | Where-Object { $_.Id -eq $this.Tag.Id })[0]
        } else {
            $row = @($script:CurrentRecord.CoreTasks | Where-Object { $_.Id -eq $this.Tag.Id })[0]
        }
        if ($null -ne $row) { $row.Done = $this.Checked }
        $script:IsDirty = $true
        Refresh-Progress
    })
    $Parent.Controls.Add($cb)
    $script:Controls[$Type + ':' + $Item.Id] = $cb
    return $cb
}

function New-BlockTaskRow {
    param([System.Windows.Forms.Control]$Parent, [hashtable]$Item, [int]$Width = 1290)
    $row = New-Object System.Windows.Forms.Panel
    $row.Width = $Width
    $row.Height = 42
    $row.BackColor = $script:Palette.Stone
    $time = New-BlockLabel -Text $Item.Time -Width 120 -Height 39 -FontSize 10 -BackColor $script:Palette.Dirt -ForeColor $script:Palette.Paper
    $time.Location = New-Object System.Drawing.Point(0,1)
    $task = New-BlockLabel -Text $Item.Task -Width 260 -Height 39 -FontSize 11 -BackColor $script:Palette.StoneLight -ForeColor $script:Palette.Paper
    $task.Location = New-Object System.Drawing.Point(122,1)
    $standard = New-BlockLabel -Text $Item.Standard -Width ($Width - 500) -Height 39 -FontSize 10 -BackColor $script:Palette.Stone -ForeColor $script:Palette.Muted
    $standard.Location = New-Object System.Drawing.Point(385,1)
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = '完成'
    $cb.Width = 90
    $cb.Height = 36
    $cb.Location = New-Object System.Drawing.Point(($Width - 100),2)
    $cb.Font = New-UiFont -Size 10 -Style ([System.Drawing.FontStyle]::Bold)
    $cb.ForeColor = $script:Palette.Grass
    $cb.Checked = [bool]$Item.Done
    $cb.Tag = @{ Type='Routine'; Id=$Item.Id }
    $cb.Add_CheckedChanged({
        $rowData = @($script:CurrentRecord.Routine | Where-Object { $_.Id -eq $this.Tag.Id })[0]
        if ($null -ne $rowData) { $rowData.Done = $this.Checked }
        $script:IsDirty = $true
        Refresh-Progress
    })
    $row.Controls.AddRange(@($time,$task,$standard,$cb))
    $script:Controls['Routine:' + $Item.Id] = $cb
    $Parent.Controls.Add($row)
}

function New-FormPage {
    param([string]$Text)
    $page = New-Object System.Windows.Forms.TabPage
    $page.Text = $Text
    $page.BackColor = $script:Palette.DeepStone
    $page.ForeColor = $script:Palette.Paper
    $page.Padding = New-Object System.Windows.Forms.Padding(8)
    return $page
}

function Start-Dashboard {
    param([switch]$NoShow)
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    Initialize-UiPalette
    $script:CurrentRecord = Load-DailyRecord -DateKey (Get-Date).ToString('yyyy-MM-dd')
    $script:Controls = @{}
    $script:SummaryLabels = @{}
    $script:IsDirty = $false
    $script:TargetProgress = 0
    $script:AnimationPhase = 0

    $form = New-Object System.Windows.Forms.Form
    $script:Form = $form
    $form.Text = '每日任务复盘面板 - 方块世界'
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.Width = 1480
    $form.Height = 980
    $form.MinimumSize = New-Object System.Drawing.Size(1100,760)
    $form.BackColor = $script:Palette.DeepStone
    $form.ForeColor = $script:Palette.Paper
    $form.Font = New-UiFont -Size 11
    if (-not $NoShow) { $form.Opacity = 0.02 }

    $header = New-Object System.Windows.Forms.Panel
    $header.Location = New-Object System.Drawing.Point(0,0)
    $header.Size = New-Object System.Drawing.Size(1460,132)
    $header.BackColor = $script:Palette.GrassDark
    $header.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    if ($null -ne $script:GrassTexture) {
        $heroBlock = New-Object System.Windows.Forms.PictureBox
        $heroBlock.Location = New-Object System.Drawing.Point(14,12)
        $heroBlock.Size = New-Object System.Drawing.Size(94,94)
        $heroBlock.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
        $heroBlock.Image = $script:GrassTexture
        $heroBlock.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
        $header.Controls.Add($heroBlock)
    }
    $title = New-BlockLabel -Text '每日任务复盘面板' -Width 520 -Height 52 -FontSize 29 -FontStyle ([System.Drawing.FontStyle]::Bold) -BackColor $script:Palette.GrassDark -ForeColor $script:Palette.Gold
    $title.Location = New-Object System.Drawing.Point(118,6)
    $subtitle = New-BlockLabel -Text '方块世界学习生存日志 · 每天挖一点经验值' -Width 610 -Height 34 -FontSize 13 -FontStyle ([System.Drawing.FontStyle]::Bold) -BackColor $script:Palette.GrassDark -ForeColor $script:Palette.Diamond
    $subtitle.Location = New-Object System.Drawing.Point(120,58)
    $dateLabel = New-BlockLabel -Text ('今日：{0} · 第 {1} 天' -f $script:CurrentRecord.Date, $script:CurrentRecord.DayNumber) -Width 400 -Height 30 -FontSize 11 -BackColor $script:Palette.GrassDark -ForeColor $script:Palette.Paper
    $dateLabel.Location = New-Object System.Drawing.Point(120,94)
    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point(660,26)
    $progress.Size = New-Object System.Drawing.Size(500,32)
    $progress.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    $progress.Minimum = 0; $progress.Maximum = 100
    $progress.ForeColor = $script:Palette.Diamond
    $progress.BackColor = $script:Palette.DeepStone
    $script:ProgressBar = $progress
    $progressLabel = New-BlockLabel -Text '完成进度：0/0 (0%)' -Width 500 -Height 32 -FontSize 14 -FontStyle ([System.Drawing.FontStyle]::Bold) -BackColor $script:Palette.GrassDark -ForeColor $script:Palette.Gold
    $progressLabel.Location = New-Object System.Drawing.Point(660,62)
    $script:ProgressLabel = $progressLabel
    $reminder = New-BlockLabel -Text '正在读取任务状态……' -Width 720 -Height 30 -FontSize 10 -FontStyle ([System.Drawing.FontStyle]::Bold) -BackColor $script:Palette.GrassDark -ForeColor $script:Palette.Gold
    $reminder.Location = New-Object System.Drawing.Point(660,98)
    $script:ReminderLabel = $reminder
    $header.Controls.AddRange(@($title,$subtitle,$dateLabel,$progress,$progressLabel,$reminder))
    $form.Controls.Add($header)

    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Text = '保存记录'
    $saveButton.Location = New-Object System.Drawing.Point(1180,24)
    $saveButton.Size = New-Object System.Drawing.Size(120,44)
    $saveButton.Font = New-UiFont -Size 11 -Style ([System.Drawing.FontStyle]::Bold)
    $saveButton.BackColor = $script:Palette.Diamond
    $saveButton.ForeColor = $script:Palette.Black
    $saveButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $saveButton.FlatAppearance.BorderSize = 3
    $saveButton.FlatAppearance.BorderColor = $script:Palette.Paper
    $saveButton.Add_MouseEnter({ $this.BackColor = $script:Palette.Gold; $this.ForeColor = $script:Palette.Black })
    $saveButton.Add_MouseLeave({ $this.BackColor = $script:Palette.Diamond; $this.ForeColor = $script:Palette.Black })
    $saveButton.Add_Click({ Save-CurrentRecord })
    $header.Controls.Add($saveButton)
    $checkButton = New-Object System.Windows.Forms.Button
    $checkButton.Text = '检查未完成'
    $checkButton.Location = New-Object System.Drawing.Point(1310,24)
    $checkButton.Size = New-Object System.Drawing.Size(130,44)
    $checkButton.Font = New-UiFont -Size 11 -Style ([System.Drawing.FontStyle]::Bold)
    $checkButton.BackColor = $script:Palette.Redstone
    $checkButton.ForeColor = $script:Palette.Paper
    $checkButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $checkButton.FlatAppearance.BorderSize = 3
    $checkButton.FlatAppearance.BorderColor = $script:Palette.Paper
    $checkButton.Add_MouseEnter({ $this.BackColor = $script:Palette.Gold; $this.ForeColor = $script:Palette.Black })
    $checkButton.Add_MouseLeave({ $this.BackColor = $script:Palette.Redstone; $this.ForeColor = $script:Palette.Paper })
    $checkButton.Add_Click({ Show-UnfinishedReminder })
    $header.Controls.Add($checkButton)
    $script:SaveLabel = New-BlockLabel -Text '尚未保存修改' -Width 260 -Height 28 -FontSize 10 -FontStyle ([System.Drawing.FontStyle]::Bold) -BackColor $script:Palette.GrassDark -ForeColor $script:Palette.Gold
    $script:SaveLabel.Location = New-Object System.Drawing.Point(1180,78)
    $header.Controls.Add($script:SaveLabel)

    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Location = New-Object System.Drawing.Point(10,140)
    $tabs.Size = New-Object System.Drawing.Size(1440,790)
    $tabs.Font = New-UiFont -Size 12 -Style ([System.Drawing.FontStyle]::Bold)
    $tabs.BackColor = $script:Palette.DeepStone
    $tabs.ForeColor = $script:Palette.Paper

    $todayPage = New-FormPage -Text '今日复盘 · 方块任务'
    $todayScroll = New-Object System.Windows.Forms.Panel
    $todayScroll.Dock = [System.Windows.Forms.DockStyle]::Fill
    $todayScroll.AutoScroll = $true
    $todayScroll.BackColor = $script:Palette.DeepStone
    $routineHeader = New-SectionHeader -Text '正式作息 · 生存日程' -Width 1320
    $routineHeader.Location = New-Object System.Drawing.Point(8,8)
    $todayScroll.Controls.Add($routineHeader)
    $routinePanel = New-Object System.Windows.Forms.Panel
    $routinePanel.Location = New-Object System.Drawing.Point(8,66)
    $routinePanel.Width = 1320
    $routinePanel.Height = 740
    $routinePanel.BackColor = $script:Palette.Stone
    $routinePanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $y = 6
    foreach ($item in @($script:CurrentRecord.Routine)) {
        New-BlockTaskRow -Parent $routinePanel -Item $item -Width 1290
        $routinePanel.Controls[$routinePanel.Controls.Count - 1].Location = New-Object System.Drawing.Point(10,$y)
        $y += 42
    }
    $todayScroll.Controls.Add($routinePanel)
    $coreHeader = New-SectionHeader -Text '每日核心任务卡 · 勾选获得经验' -Width 1320
    $coreHeader.Location = New-Object System.Drawing.Point(8,820)
    $todayScroll.Controls.Add($coreHeader)
    $corePanel = New-Object System.Windows.Forms.Panel
    $corePanel.Location = New-Object System.Drawing.Point(8,878)
    $corePanel.Width = 1320
    $corePanel.Height = 310
    $corePanel.BackColor = $script:Palette.Stone
    $corePanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $mustGroup = New-Object System.Windows.Forms.GroupBox
    $mustGroup.Text = '必须完成'
    $mustGroup.Location = New-Object System.Drawing.Point(10,10)
    $mustGroup.Size = New-Object System.Drawing.Size(640,280)
    $mustGroup.ForeColor = $script:Palette.Redstone
    $mustFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $mustFlow.Dock = [System.Windows.Forms.DockStyle]::Fill
    $mustFlow.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $mustFlow.WrapContents = $false
    $mustFlow.AutoScroll = $true
    $mustFlow.BackColor = $script:Palette.Stone
    foreach ($item in @($script:CurrentRecord.CoreTasks | Where-Object { $_.Group -eq '必须完成' })) { Add-BoundCheckBox -Parent $mustFlow -Item $item -Type 'Core' -Width 600 | Out-Null }
    $mustGroup.Controls.Add($mustFlow)
    $advGroup = New-Object System.Windows.Forms.GroupBox
    $advGroup.Text = '形成优势'
    $advGroup.Location = New-Object System.Drawing.Point(660,10)
    $advGroup.Size = New-Object System.Drawing.Size(640,280)
    $advGroup.ForeColor = $script:Palette.Amethyst
    $advFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $advFlow.Dock = [System.Windows.Forms.DockStyle]::Fill
    $advFlow.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $advFlow.WrapContents = $false
    $advFlow.AutoScroll = $true
    $advFlow.BackColor = $script:Palette.Stone
    foreach ($item in @($script:CurrentRecord.CoreTasks | Where-Object { $_.Group -eq '形成优势' })) { Add-BoundCheckBox -Parent $advFlow -Item $item -Type 'Core' -Width 600 | Out-Null }
    $advGroup.Controls.Add($advFlow)
    $corePanel.Controls.AddRange(@($mustGroup,$advGroup))
    $todayScroll.Controls.Add($corePanel)
    $todayPage.Controls.Add($todayScroll)

    $notesPage = New-FormPage -Text '产出 · 复盘 · 额外事项'
    $notesScroll = New-Object System.Windows.Forms.Panel
    $notesScroll.Dock = [System.Windows.Forms.DockStyle]::Fill
    $notesScroll.AutoScroll = $true
    $notesScroll.BackColor = $script:Palette.DeepStone
    $noteHeader = New-SectionHeader -Text '今日产出记录 · 把经验放进箱子里' -Width 1320
    $noteHeader.Location = New-Object System.Drawing.Point(8,8)
    $notesScroll.Controls.Add($noteHeader)
    $outputPanel = New-Object System.Windows.Forms.Panel
    $outputPanel.Location = New-Object System.Drawing.Point(8,58)
    $outputPanel.Size = New-Object System.Drawing.Size(1320,430)
    $outputPanel.BackColor = $script:Palette.Stone
    $outputPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $outputRows = @(
        @('数学题目/错题','Outputs','Math'), @('电路知识/公式','Outputs','Major'), @('Python/AI代码或结果','Outputs','PythonAI'),
        @('电子实践现象/照片/数据','Outputs','Practice'), @('英语新词和长难句','Outputs','English'), @('GitHub或文件保存位置','Outputs','GitHub')
    )
    $top = 10
    foreach ($row in $outputRows) { New-TextInputRow -Parent $outputPanel -Top $top -LabelText $row[0] -Section $row[1] -Key $row[2] -Width 1300 | Out-Null; $top += 66 }
    $notesScroll.Controls.Add($outputPanel)
    $reviewHeader = New-SectionHeader -Text '21:00复盘 · 三分钟总结' -Width 1320
    $reviewHeader.Location = New-Object System.Drawing.Point(8,470)
    $notesScroll.Controls.Add($reviewHeader)
    $reviewPanel = New-Object System.Windows.Forms.Panel
    $reviewPanel.Location = New-Object System.Drawing.Point(8,528)
    $reviewPanel.Size = New-Object System.Drawing.Size(1320,320)
    $reviewPanel.BackColor = $script:Palette.Stone
    $reviewPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $reviewRows = @(
        @('今天最重要的完成项','Main'), @('没完成的原因','Reason'), @('明天起床后的第一件学习任务','Tomorrow'), @('明天只保留一个提高目标','Improve')
    )
    $top = 10
    foreach ($row in $reviewRows) { New-TextInputRow -Parent $reviewPanel -Top $top -LabelText $row[0] -Section 'Review' -Key $row[1] -Width 1300 | Out-Null; $top += 66 }
    $notesScroll.Controls.Add($reviewPanel)
    $extraHeader = New-SectionHeader -Text '额外事项 · 是否打破今日计划？' -Width 1320
    $extraHeader.Location = New-Object System.Drawing.Point(8,820)
    $notesScroll.Controls.Add($extraHeader)
    $extraPanel = New-Object System.Windows.Forms.Panel
    $extraPanel.Location = New-Object System.Drawing.Point(8,878)
    $extraPanel.Size = New-Object System.Drawing.Size(1320,260)
    $extraPanel.BackColor = $script:Palette.Stone
    $extraPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $extraCheck = New-Object System.Windows.Forms.CheckBox
    $extraCheck.Text = '有额外事项需要打破计划'
    $extraCheck.Location = New-Object System.Drawing.Point(18,18)
    $extraCheck.Size = New-Object System.Drawing.Size(360,38)
    $extraCheck.Font = New-UiFont -Size 12 -Style ([System.Drawing.FontStyle]::Bold)
    $extraCheck.ForeColor = $script:Palette.Gold
    $extraCheck.Checked = [bool]$script:CurrentRecord.ExtraPlanBreak.Enabled
    $extraCheck.Add_CheckedChanged({ $script:CurrentRecord.ExtraPlanBreak.Enabled=$this.Checked; $script:IsDirty=$true })
    $extraPanel.Controls.Add($extraCheck)
    $extraRows = @(
        @('事项内容','Item'), @('优先级（高/中/低）','Priority'), @('打破计划的原因','Reason'), @('对今日计划的影响','Impact')
    )
    $top = 58
    foreach ($row in $extraRows) {
        $label = New-BlockLabel -Text $row[0] -Width 230 -Height 36 -FontSize 10 -BackColor $script:Palette.Dirt -ForeColor $script:Palette.Paper
        $label.Location = New-Object System.Drawing.Point(18,$top)
        $tb = New-Object System.Windows.Forms.TextBox
        $tb.Location = New-Object System.Drawing.Point(255,($top + 3))
        $tb.Width = 980
        $tb.Height = 32
        $tb.Font = New-UiFont -Size 11
        $tb.Text = [string]$script:CurrentRecord.ExtraPlanBreak[$row[1]]
        $tb.Tag = $row[1]
        $tb.Add_TextChanged({ $script:CurrentRecord.ExtraPlanBreak[$this.Tag] = $this.Text; $script:IsDirty=$true })
        $extraPanel.Controls.AddRange(@($label,$tb))
        $top += 42
    }
    $notesScroll.Controls.Add($extraPanel)
    $notesPage.Controls.Add($notesScroll)

    $weekPage = New-FormPage -Text '本周汇总'
    $weekLabel = New-BlockLabel -Text '' -Width 1320 -Height 680 -FontSize 15 -BackColor $script:Palette.Stone -ForeColor $script:Palette.Paper
    $weekLabel.Location = New-Object System.Drawing.Point(10,10)
    $weekLabel.Padding = New-Object System.Windows.Forms.Padding(20)
    $weekLabel.AutoSize = $false
    $weekLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
    $weekPage.Controls.Add($weekLabel)
    $script:SummaryLabels['Week'] = $weekLabel

    $monthPage = New-FormPage -Text '本月汇总'
    $monthLabel = New-BlockLabel -Text '' -Width 1320 -Height 680 -FontSize 15 -BackColor $script:Palette.Stone -ForeColor $script:Palette.Paper
    $monthLabel.Location = New-Object System.Drawing.Point(10,10)
    $monthLabel.Padding = New-Object System.Windows.Forms.Padding(20)
    $monthLabel.AutoSize = $false
    $monthLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
    $monthPage.Controls.Add($monthLabel)
    $script:SummaryLabels['Month'] = $monthLabel

    $tabs.TabPages.AddRange(@($todayPage,$notesPage,$weekPage,$monthPage))
    $form.Controls.Add($tabs)
    Refresh-Progress
    Refresh-SummaryPage -PageType 'Week'
    Refresh-SummaryPage -PageType 'Month'

    $reminderTimer = New-Object System.Windows.Forms.Timer
    $reminderTimer.Interval = 60000
    $reminderTimer.Add_Tick({ Refresh-Progress; if ((Get-Date).Hour -eq 21 -and (Get-Date).Minute -lt 2) { Show-UnfinishedReminder } })
    $script:ReminderTimer = $reminderTimer
    $reminderTimer.Start()
    $animationTimer = New-Object System.Windows.Forms.Timer
    $animationTimer.Interval = 60
    $animationTimer.Add_Tick({
        $script:AnimationPhase = ($script:AnimationPhase + 1) % 1000
        if ($script:Form.Opacity -lt 1) { $script:Form.Opacity = [math]::Min(1.0, $script:Form.Opacity + 0.10) }
        if ($script:ProgressBar.Value -lt $script:TargetProgress) { $script:ProgressBar.Value = [math]::Min($script:TargetProgress, $script:ProgressBar.Value + 2) }
        elseif ($script:ProgressBar.Value -gt $script:TargetProgress) { $script:ProgressBar.Value = [math]::Max($script:TargetProgress, $script:ProgressBar.Value - 2) }
        if ($script:IsDirty) {
            $pulse = [int](145 + (45 * [math]::Abs([math]::Sin($script:AnimationPhase / 9))))
            $script:SaveLabel.ForeColor = [System.Drawing.Color]::FromArgb(255,$pulse,80,60)
        } else { $script:SaveLabel.ForeColor = $script:Palette.Grass }
    })
    $script:AnimationTimer = $animationTimer
    $animationTimer.Start()
    $form.Add_FormClosing({
        param($sender,$e)
        if ($script:IsDirty) {
            $choice = [System.Windows.Forms.MessageBox]::Show($sender,'今天有未保存修改，要先保存吗？','保存方块日志',[System.Windows.Forms.MessageBoxButtons]::YesNoCancel,[System.Windows.Forms.MessageBoxIcon]::Question)
            if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) { Save-CurrentRecord }
            elseif ($choice -eq [System.Windows.Forms.DialogResult]::Cancel) { $e.Cancel = $true }
        }
        $reminderTimer.Stop()
        $animationTimer.Stop()
    })

    if ($NoShow) {
        $reminderTimer.Stop()
        $animationTimer.Stop()
        $form.Opacity = 1
        return $form
    }
    [System.Windows.Forms.Application]::Run($form)
    return $form
}

. (Join-Path $script:BaseDir 'MidnightFocusUI.ps1')
. (Join-Path $script:BaseDir 'MidnightFocusWPF.ps1')

function Test-UiStructure {
    $form = Start-Dashboard -NoShow
    $tabs = @($form.Controls.Find('MainTabs',$true))[0]
    if ($null -eq $tabs) { throw 'main tabs missing' }
    $tabNames = $tabs.TabPages | ForEach-Object { $_.Text }
    if ($tabNames.Count -lt 4) { throw 'tab count mismatch' }
    if ($script:Controls.Count -ne 27) { throw ('checkbox count mismatch: ' + $script:Controls.Count) }
    if ($null -eq $script:ProgressBar) { throw 'progress bar missing' }
    $form.Dispose()
    Write-Output 'PASS: ui structure'
}

function Test-WpfStructure {
    $window = Start-WpfDashboard -NoShow
    if ($null -eq $window) { throw 'WPF window missing' }
    if ([int]$window.Width -ne 1488 -or [int]$window.Height -ne 1055) { throw ('WPF window size mismatch: {0}x{1}' -f $window.Width,$window.Height) }
    foreach ($name in @('DailyTaskList','ProgressArc','ProgressPercent','WeekCanvas','MonthHeatmap','SaveButton')) {
        if ($null -eq (Get-WpfNamedElement -Window $window -Name $name)) { throw ('WPF element missing: ' + $name) }
    }
    $taskList = Get-WpfNamedElement -Window $window -Name 'DailyTaskList'
    if ($taskList.Children.Count -ne 27) { throw ('WPF task row count mismatch: ' + $taskList.Children.Count) }
    $window.Close()
    Write-Output 'PASS: wpf structure'
}

function Test-WpfProgressInteraction {
    $window = Start-WpfDashboard -NoShow
    $check = $script:WpfTaskControls['Core:core_math']
    if ($null -eq $check) { throw 'WPF core_math checkbox missing' }
    $check.IsChecked = $true
    $stats = Get-ProgressStats -Record $script:CurrentRecord
    if ($stats.Done -ne 1 -or $stats.Percent -ne 4) { throw ('WPF progress mismatch: {0}/{1} {2}%' -f $stats.Done,$stats.Total,$stats.Percent) }
    $arc = Get-WpfNamedElement -Window $window -Name 'ProgressArc'
    if ([double]::IsNaN($arc.Width) -or [int]$arc.Width -ne 126 -or [int]$arc.Height -ne 126) {
        throw ('WPF progress arc size mismatch: {0}x{1}' -f $arc.Width,$arc.Height)
    }
    if ($arc.HorizontalAlignment -ne [System.Windows.HorizontalAlignment]::Center -or
        $arc.VerticalAlignment -ne [System.Windows.VerticalAlignment]::Center) {
        throw 'WPF progress arc alignment mismatch'
    }
    if ($arc.Stretch -ne [System.Windows.Media.Stretch]::None) {
        throw ('WPF progress arc stretch mismatch: ' + $arc.Stretch)
    }
    if ($null -eq $arc.Data -or $arc.Data.Figures.Count -eq 0) { throw 'WPF progress arc did not update' }
    $arcBounds = $arc.Data.Bounds
    if ($arcBounds.X -lt 0 -or $arcBounds.Y -lt 0 -or $arcBounds.Right -gt 126 -or $arcBounds.Bottom -gt 126) {
        throw ('WPF progress geometry exceeds shared ring box: {0}' -f $arcBounds)
    }
    $check.IsChecked = $false
    $stats = Get-ProgressStats -Record $script:CurrentRecord
    if ($stats.Done -ne 0 -or $stats.Percent -ne 0) { throw 'WPF progress did not return to zero' }
    $window.Close()
    Write-Output 'PASS: wpf progress interaction'
}

function Test-WpfNavigation {
    $window = Start-WpfDashboard -NoShow
    $week = Get-WpfNamedElement -Window $window -Name 'WeekTabButton'; $week.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
    if ((Get-WpfNamedElement -Window $window -Name 'WeekPage').Visibility -ne 'Visible') { throw 'week page did not open' }
    $today = Get-WpfNamedElement -Window $window -Name 'TodayTabButton'; $today.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
    $energy = Get-WpfNamedElement -Window $window -Name 'EnergyFull'; $energy.IsChecked = $true; $energy.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
    if ([string]$script:CurrentRecord.Energy -ne '充沛') { throw 'energy state did not update' }
    $script:IsDirty = $true; (Get-WpfNamedElement -Window $window -Name 'SaveButton').RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
    if ($script:IsDirty) { throw 'save state did not clear' }
    $oldDate = [string]$script:CurrentRecord.Date; (Get-WpfNamedElement -Window $window -Name 'NextDayButton').RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
    if ([string]$script:CurrentRecord.Date -eq $oldDate) { throw 'next day did not load' }
    $window.Close(); Write-Output 'PASS: wpf navigation'
}

function Test-WpfSummaryVisuals {
    $oldDir = $script:DataDir; $script:DataDir = Join-Path ([IO.Path]::GetTempPath()) ('WpfSummaryTest-' + [guid]::NewGuid().ToString('N'))
    try {
        foreach($offset in 0..6){$record=New-DailyRecord -DateKey ([datetime]'2099-04-06').AddDays($offset).ToString('yyyy-MM-dd');$items=@($record.Routine)+@($record.CoreTasks);for($i=0;$i -lt [math]::Min(27,($offset+1)*3);$i++){$items[$i].Done=$true};Save-DailyRecord -Record $record|Out-Null}
        $week=Get-WeekVisualModel -AnchorDate ([datetime]'2099-04-09');if($week.Days.Count -ne 7 -or $week.CategoryTotals.Count -ne 6){throw 'week visual model mismatch'}
        $month=Get-MonthVisualModel -AnchorDate ([datetime]'2099-04-09');if($month.Cells.Count -lt 35 -or $month.Weeks -lt 5){throw 'month visual model mismatch'}
        $window=Start-WpfDashboard -NoShow;Render-WpfWeekPage -AnchorDate ([datetime]'2099-04-09');Render-WpfMonthPage -AnchorDate ([datetime]'2099-04-09');if((Get-WpfNamedElement -Window $window -Name 'WeekCanvas').Children.Count -lt 10){throw 'week canvas empty'};if((Get-WpfNamedElement -Window $window -Name 'MonthHeatmap').Children.Count -lt 30){throw 'month heatmap empty'};$window.Close();Write-Output 'PASS: wpf summary visuals'
    } finally { $script:DataDir=$oldDir }
}

function Test-VisualEnhancements {
    $form = Start-Dashboard -NoShow
    if ($script:Palette.DeepNight.Name -ne 'ff0b1220') { throw 'midnight palette missing' }
    if ($script:AnimationTimer.Interval -ne 60) { throw 'animation timer missing' }
    if ($script:ReminderTimer.Interval -ne 60000) { throw 'reminder timer missing' }
    if ($script:ProgressLabel.Font.Size -lt 14) { throw 'progress text is not large enough' }
    if (-not $script:MainTaskFlow.AutoScroll) { throw 'task scroll missing' }
    if (@($script:TaskTextLabels | Where-Object { $_.AutoEllipsis }).Count -gt 0) { throw 'task text clipping enabled' }
    $form.Dispose()
    Write-Output 'PASS: theme and animation'
}

function Test-MidnightFocusLayout {
    $form = Start-Dashboard -NoShow
    if ($form.AutoScaleMode -ne [System.Windows.Forms.AutoScaleMode]::Dpi) { throw 'DPI scaling missing' }
    if (-not $script:MainTaskFlow.AutoScroll) { throw 'main task scrolling missing' }
    if (@($script:Controls.Keys).Count -ne 27) { throw 'task count mismatch' }
    $form.Dispose()
    Write-Output 'PASS: midnight focus responsive layout'
}

function Export-DashboardPreview {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$Width = 1440,
        [int]$Height = 920
    )
    $form = Start-Dashboard -NoShow
    $form.ClientSize = New-Object System.Drawing.Size($Width,$Height)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    $form.Location = New-Object System.Drawing.Point(-2000,-2000)
    $form.ShowInTaskbar = $false
    $form.Show()
    [System.Windows.Forms.Application]::DoEvents()
    $form.PerformLayout()
    foreach ($control in @($form.Controls)) { $control.PerformLayout() }
    $bitmap = New-Object System.Drawing.Bitmap($form.Width,$form.Height)
    $bounds = New-Object System.Drawing.Rectangle(0,0,$form.Width,$form.Height)
    $form.DrawToBitmap($bitmap,$bounds)
    $fullPath = [IO.Path]::GetFullPath($Path)
    $parent = Split-Path -Parent $fullPath
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $bitmap.Save($fullPath,[System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    $form.Close()
    $form.Dispose()
    Write-Output ('PASS: preview rendered ' + $fullPath)
}

function Test-DataModel {
    $oldDir = $script:DataDir
    $script:DataDir = Join-Path ([IO.Path]::GetTempPath()) ('DailyTaskReviewTest-' + [guid]::NewGuid().ToString('N'))
    $date = '2099-01-02'
    $record = New-DailyRecord -DateKey $date
    $record.Routine[2].Done = $true
    $record.CoreTasks[0].Done = $true
    $record.Outputs.Math = '测试输出'
    Save-DailyRecord -Record $record | Out-Null
    $loaded = Load-DailyRecord -DateKey $date
    if ($loaded.Routine.Count -ne 17) { throw 'routine count mismatch' }
    if ($loaded.CoreTasks.Count -ne 10) { throw 'core task count mismatch' }
    if (-not $loaded.Routine[2].Done) { throw 'routine state mismatch' }
    if (-not $loaded.CoreTasks[0].Done) { throw 'core state mismatch' }
    if ($loaded.Outputs.Math -ne '测试输出') { throw 'output state mismatch' }
    $script:DataDir = $oldDir
    Write-Output 'PASS: data model round trip'
}

function Test-ProgressInteraction {
    $record = New-DailyRecord -DateKey '2099-03-01'
    $afterCheck = Set-TaskCompletion -Record $record -Type Core -Id 'core_math' -Done $true
    if ($afterCheck.Done -ne 1 -or $afterCheck.Total -ne 27 -or $afterCheck.Percent -ne 4) {
        throw ('progress after check mismatch: {0}/{1} {2}%' -f $afterCheck.Done,$afterCheck.Total,$afterCheck.Percent)
    }
    $afterUncheck = Set-TaskCompletion -Record $record -Type Core -Id 'core_math' -Done $false
    if ($afterUncheck.Done -ne 0 -or $afterUncheck.Total -ne 27 -or $afterUncheck.Percent -ne 0) {
        throw ('progress after uncheck mismatch: {0}/{1} {2}%' -f $afterUncheck.Done,$afterUncheck.Total,$afterUncheck.Percent)
    }
    Write-Output 'PASS: progress interaction'
}

if ($TestMode) { Test-DataModel; exit 0 }
if ($SummaryTestMode) { Test-SummaryModel; exit 0 }
if ($InstallMode) { Write-Output 'INSTALL MODE PLACEHOLDER'; exit 0 }
if ($UiTestMode) { Test-UiStructure; exit 0 }
if ($VisualTestMode) { Test-VisualEnhancements; exit 0 }
if ($MidnightFocusTestMode) { Test-MidnightFocusLayout; exit 0 }
if ($ProgressInteractionTestMode) { Test-ProgressInteraction; exit 0 }
if ($WpfStructureTestMode) { Test-WpfStructure; exit 0 }
if ($WpfProgressTestMode) { Test-WpfProgressInteraction; exit 0 }
if ($WpfNavigationTestMode) { Test-WpfNavigation; exit 0 }
if ($WpfSummaryVisualTestMode) { Test-WpfSummaryVisuals; exit 0 }
if ($WpfRenderPreviewMode) {
    if ([string]::IsNullOrWhiteSpace($PreviewPath)) { $PreviewPath = Join-Path $script:BaseDir 'tests\wpf-preview.png' }
    Export-WpfDashboardPreview -Path $PreviewPath -Width $PreviewWidth -Height $PreviewHeight -Page $PreviewPage
    exit 0
}
if ($RenderPreviewMode) {
    if ([string]::IsNullOrWhiteSpace($PreviewPath)) { $PreviewPath = Join-Path $script:BaseDir 'tests\midnight-focus-preview.png' }
    Export-DashboardPreview -Path $PreviewPath -Width $PreviewWidth -Height $PreviewHeight
    exit 0
}

Start-WpfDashboard | Out-Null
