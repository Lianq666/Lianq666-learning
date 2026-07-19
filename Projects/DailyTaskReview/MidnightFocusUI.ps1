function Initialize-UiPalette {
    $script:Palette = @{
        DeepNight = Get-UiColor '#0B1220'
        Surface = Get-UiColor '#111B2E'
        SurfaceRaised = Get-UiColor '#16233A'
        Line = Get-UiColor '#263650'
        Text = Get-UiColor '#F4F7FB'
        Muted = Get-UiColor '#9AA8C0'
        Primary = Get-UiColor '#4E86FF'
        PrimarySoft = Get-UiColor '#1A3268'
        Warning = Get-UiColor '#F4B347'
        Danger = Get-UiColor '#FF7272'
        Success = Get-UiColor '#64D2A1'
        Purple = Get-UiColor '#A78BFA'
        Black = Get-UiColor '#07101F'
    }
}

function Get-UiFallbackPalette {
    return @{
        DeepNight     = [System.Drawing.Color]::FromArgb(255,11,18,32)
        Surface       = [System.Drawing.Color]::FromArgb(255,17,27,46)
        SurfaceRaised = [System.Drawing.Color]::FromArgb(255,22,35,58)
        Line          = [System.Drawing.Color]::FromArgb(255,38,54,80)
        Text          = [System.Drawing.Color]::FromArgb(255,244,247,251)
        Muted         = [System.Drawing.Color]::FromArgb(255,154,168,192)
        Primary       = [System.Drawing.Color]::FromArgb(255,78,134,255)
        PrimarySoft   = [System.Drawing.Color]::FromArgb(255,26,50,104)
        Warning       = [System.Drawing.Color]::FromArgb(255,244,179,71)
        Danger        = [System.Drawing.Color]::FromArgb(255,255,114,114)
        Success       = [System.Drawing.Color]::FromArgb(255,100,210,161)
        Purple        = [System.Drawing.Color]::FromArgb(255,167,139,250)
        Black         = [System.Drawing.Color]::FromArgb(255,7,16,31)
    }
}

function Test-UiColorValue {
    param([object]$Value)
    return ($Value -is [System.Drawing.Color] -and -not $Value.IsEmpty)
}

function Ensure-UiPalette {
    $fallback = Get-UiFallbackPalette
    $keys = @($fallback.Keys)
    $needsInit = $null -eq $script:Palette
    if (-not $needsInit) {
        foreach ($key in $keys) {
            if (-not (Test-UiColorValue -Value $script:Palette[$key])) { $needsInit = $true; break }
        }
    }
    if ($needsInit) {
        $initializer = Get-Command Initialize-UiPalette -CommandType Function -ErrorAction SilentlyContinue
        if ($null -ne $initializer) {
            try { Initialize-UiPalette } catch { }
        }
    }
    if ($null -eq $script:Palette) { $script:Palette = @{} }
    foreach ($key in $keys) {
        if (-not (Test-UiColorValue -Value $script:Palette[$key])) { $script:Palette[$key] = $fallback[$key] }
    }
}

function Resolve-UiColor {
    param([object]$Value, [System.Drawing.Color]$Fallback)
    if (Test-UiColorValue -Value $Value) { return [System.Drawing.Color]$Value }
    if ($null -ne $Value -and -not [string]::IsNullOrWhiteSpace([string]$Value)) {
        try { return [System.Drawing.ColorTranslator]::FromHtml([string]$Value) } catch { }
    }
    return $Fallback
}

function New-UiLabel {
    param(
        [string]$Text,
        [float]$FontSize = 11,
        [System.Drawing.FontStyle]$FontStyle = [System.Drawing.FontStyle]::Regular,
        [object]$BackColor = $null,
        [object]$ForeColor = $null,
        [System.Drawing.ContentAlignment]$TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    )
    Ensure-UiPalette
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Font = New-UiFont -Size $FontSize -Style $FontStyle
    $label.BackColor = Resolve-UiColor -Value $BackColor -Fallback ([System.Drawing.Color]::Transparent)
    $label.ForeColor = Resolve-UiColor -Value $ForeColor -Fallback $script:Palette.Text
    $label.TextAlign = $TextAlign
    $label.AutoEllipsis = $false
    $label.UseCompatibleTextRendering = $true
    return $label
}

function New-UiButton {
    param(
        [string]$Text,
        [int]$Width = 82,
        [object]$BackColor = $null,
        [object]$ForeColor = $null
    )
    Ensure-UiPalette
    $resolvedBackColor = Resolve-UiColor -Value $BackColor -Fallback $script:Palette.SurfaceRaised
    $resolvedForeColor = Resolve-UiColor -Value $ForeColor -Fallback $script:Palette.Text
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Font = New-UiFont -Size 10.5 -Style ([System.Drawing.FontStyle]::Bold)
    $button.Size = New-Object System.Drawing.Size($Width,38)
    $button.MinimumSize = New-Object System.Drawing.Size(62,38)
    $button.Padding = New-Object System.Windows.Forms.Padding(7,2,7,2)
    $button.Margin = New-Object System.Windows.Forms.Padding(2)
    $button.BackColor = $resolvedBackColor
    $button.ForeColor = $resolvedForeColor
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 1
    $button.FlatAppearance.BorderColor = $script:Palette.Line
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Tag = @{ RestBack=$resolvedBackColor; RestFore=$resolvedForeColor }
    $hoverBackColor = $script:Palette.Primary
    $hoverForeColor = $script:Palette.Text
    $button.Add_MouseEnter({ $this.BackColor = $hoverBackColor; $this.ForeColor = $hoverForeColor }.GetNewClosure())
    $button.Add_MouseLeave({ $this.BackColor = $this.Tag.RestBack; $this.ForeColor = $this.Tag.RestFore })
    return $button
}

function New-SectionHeading {
    param([string]$Text, [object]$Color = $null)
    Ensure-UiPalette
    if ($null -eq $Color) { $Color = $script:Palette.Primary }
    $label = New-UiLabel -Text $Text -FontSize 14 -FontStyle ([System.Drawing.FontStyle]::Bold) -ForeColor $Color
    $label.AutoSize = $true
    $label.Margin = New-Object System.Windows.Forms.Padding(2,10,2,8)
    return $label
}

function New-CardPanel {
    param([int]$Height = 150)
    $card = New-Object System.Windows.Forms.Panel
    $card.Height = $Height
    $card.MinimumSize = New-Object System.Drawing.Size(220,$Height)
    $card.BackColor = $script:Palette.Surface
    $card.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $card.Padding = New-Object System.Windows.Forms.Padding(14)
    $card.Margin = New-Object System.Windows.Forms.Padding(0,0,0,12)
    return $card
}

function Set-FlowRowWidths {
    param([System.Windows.Forms.FlowLayoutPanel]$Flow)
    if ($null -eq $Flow -or $Flow.IsDisposed) { return }
    $width = [math]::Max(280, $Flow.ClientSize.Width - $Flow.Padding.Horizontal - 22)
    foreach ($child in @($Flow.Controls)) {
        if ($child -is [System.Windows.Forms.Control] -and -not $child.AutoSize) { $child.Width = $width }
        elseif ($child -is [System.Windows.Forms.Panel]) { $child.Width = $width }
    }
}

function Set-RecordTextValue {
    param([string]$Section, [string]$Key, [string]$Value)
    $script:CurrentRecord[$Section][$Key] = $Value
    $script:IsDirty = $true
}

function New-TextInputRow {
    param(
        [System.Windows.Forms.FlowLayoutPanel]$Parent,
        [string]$LabelText,
        [string]$Section,
        [string]$Key
    )
    $row = New-Object System.Windows.Forms.Panel
    $row.Height = 86
    $row.MinimumSize = New-Object System.Drawing.Size(360,86)
    $row.BackColor = $script:Palette.Surface
    $row.Padding = New-Object System.Windows.Forms.Padding(10,8,10,8)
    $row.Margin = New-Object System.Windows.Forms.Padding(0,0,0,8)
    $table = New-Object System.Windows.Forms.TableLayoutPanel
    $table.Dock = [System.Windows.Forms.DockStyle]::Fill
    $table.ColumnCount = 2
    $table.RowCount = 1
    $table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,28)))
    $table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,72)))
    $label = New-UiLabel -Text $LabelText -FontSize 10.5 -ForeColor $script:Palette.Muted
    $label.Dock = [System.Windows.Forms.DockStyle]::Fill
    $label.AutoEllipsis = $false
    $label.Padding = New-Object System.Windows.Forms.Padding(4,6,14,6)
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Dock = [System.Windows.Forms.DockStyle]::Fill
    $tb.Multiline = $true
    $tb.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $tb.Font = New-UiFont -Size 10.5
    $tb.BackColor = $script:Palette.SurfaceRaised
    $tb.ForeColor = $script:Palette.Text
    $tb.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tb.Text = [string]$script:CurrentRecord[$Section][$Key]
    $tb.Tag = @{ Section=$Section; Key=$Key }
    $tb.Add_TextChanged({ Set-RecordTextValue -Section $this.Tag.Section -Key $this.Tag.Key -Value $this.Text })
    $table.Controls.Add($label,0,0)
    $table.Controls.Add($tb,1,0)
    $row.Controls.Add($table)
    $Parent.Controls.Add($row)
    return $tb
}

function Refresh-Progress {
    if ($null -eq $script:ProgressBar) { return }
    $stats = Get-ProgressStats -Record $script:CurrentRecord
    $script:TargetProgress = [math]::Min(100,[math]::Max(0,[int]$stats.Percent))
    $script:ProgressLabel.Text = ('{0}% · 已完成 {1}/{2}' -f $stats.Percent,$stats.Done,$stats.Total)
    if ($stats.Percent -ge 85) { $script:ProgressLabel.ForeColor = $script:Palette.Success }
    elseif ($stats.Percent -ge 60) { $script:ProgressLabel.ForeColor = $script:Palette.Primary }
    else { $script:ProgressLabel.ForeColor = $script:Palette.Warning }
    Refresh-Reminder
}

function Refresh-Reminder {
    if ($null -eq $script:ReminderLabel) { return }
    $items = @(Get-UnfinishedItems -Record $script:CurrentRecord)
    $must = @($items | Where-Object { $_.Group -eq '必须完成' })
    if ($items.Count -eq 0) {
        $script:ReminderLabel.Text = '今天的任务已全部完成，可以安心收尾。'
        $script:ReminderLabel.ForeColor = $script:Palette.Success
        return
    }
    $preview = @($items | Select-Object -First 2 | ForEach-Object { $_.Text }) -join '；'
    if ($must.Count -gt 0) {
        $script:ReminderLabel.Text = ('还有 {0} 项必须完成。{1}' -f $must.Count,$preview)
        $script:ReminderLabel.ForeColor = $script:Palette.Danger
    } else {
        $script:ReminderLabel.Text = ('还有 {0} 项加分任务。{1}' -f $items.Count,$preview)
        $script:ReminderLabel.ForeColor = $script:Palette.Warning
    }
}

function Show-UnfinishedReminder {
    $items = @(Get-UnfinishedItems -Record $script:CurrentRecord -IncludeRoutine)
    if ($items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show($script:Form,'今天的作息和任务全部完成。','今日复盘',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    $text = ($items | ForEach-Object { '· [' + $_.Kind + '] ' + $_.Text }) -join [Environment]::NewLine
    [System.Windows.Forms.MessageBox]::Show($script:Form,('还有以下项目未完成：' + [Environment]::NewLine + $text),'任务未完成提醒',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
}

function Save-CurrentRecord {
    Save-DailyRecord -Record $script:CurrentRecord | Out-Null
    $script:IsDirty = $false
    $script:SaveLabel.Text = '已保存：' + (Get-Date).ToString('HH:mm:ss')
    $script:SaveLabel.ForeColor = $script:Palette.Success
    Refresh-SummaryPage -PageType 'Week'
    Refresh-SummaryPage -PageType 'Month'
}

function New-SummaryText {
    param([string]$PageType)
    $today = [datetime]::ParseExact($script:CurrentRecord.Date,'yyyy-MM-dd',$null)
    if ($PageType -eq 'Week') { $start = $today.Date.AddDays(-6); $title = '本周学习状态总结' }
    else { $start = New-Object datetime($today.Year,$today.Month,1); $title = '本月学习状态总结' }
    $summary = Get-PeriodSummary -StartDate $start -EndDate $today.Date
    $advice = Get-StandardAdvice -Summary $summary
    $days = if ($summary.Days -eq 0) { '暂无记录' } else { [string]$summary.Days }
    return @(
        $title
        ''
        ('统计范围：{0} 至 {1}' -f $summary.StartDate,$summary.EndDate)
        ('有效记录天数：{0}' -f $days)
        ('总任务完成率：{0}%' -f $summary.CompletionRate)
        ('睡眠按时完成：{0} 天' -f $summary.SleepDays)
        ('学习产出填写数：{0}' -f $summary.OutputCount)
        ('额外事项打破计划：{0} 次' -f $summary.ExtraPlanBreaks)
        ('最常遗漏任务：{0}' -f $(if ([string]::IsNullOrWhiteSpace($summary.MostMissed)) { '暂无' } else { $summary.MostMissed }))
        ''
        ('标准评估：' + $advice)
        '建议：每次只调整一个变量；先保证睡眠和数学、英语、专业基础的最低线，再增加项目任务。'
    ) -join [Environment]::NewLine
}

function Refresh-SummaryPage {
    param([ValidateSet('Week','Month')][string]$PageType)
    if ($null -ne $script:SummaryLabels[$PageType]) { $script:SummaryLabels[$PageType].Text = New-SummaryText -PageType $PageType }
}

function New-FocusTaskRow {
    param([System.Windows.Forms.FlowLayoutPanel]$Parent,[hashtable]$Item,[string]$Type)
    $row = New-Object System.Windows.Forms.Panel
    $row.Height = 82
    $row.MinimumSize = New-Object System.Drawing.Size(520,82)
    $row.BackColor = if ($Item.Done) { $script:Palette.SurfaceRaised } else { $script:Palette.Surface }
    $row.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $row.Padding = New-Object System.Windows.Forms.Padding(10,8,10,8)
    $row.Margin = New-Object System.Windows.Forms.Padding(0,0,0,8)
    $grid = New-Object System.Windows.Forms.TableLayoutPanel
    $grid.Dock = [System.Windows.Forms.DockStyle]::Fill
    $grid.ColumnCount = 5
    $grid.RowCount = 1
    $grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,44)))
    $grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,116)))
    $grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,34)))
    $grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,46)))
    $grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,92)))
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.AutoSize = $true
    $cb.MinimumSize = New-Object System.Drawing.Size(30,30)
    $cb.Margin = New-Object System.Windows.Forms.Padding(2,9,2,2)
    $cb.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cb.ForeColor = $script:Palette.Primary
    $cb.BackColor = $row.BackColor
    $cb.Checked = [bool]$Item.Done
    $timeText = if ($Type -eq 'Routine') { [string]$Item.Time } else { '核心任务' }
    $time = New-UiLabel -Text $timeText -FontSize 10.5 -ForeColor $script:Palette.Muted
    $time.Dock = [System.Windows.Forms.DockStyle]::Fill
    $time.AutoEllipsis = $false
    $time.Padding = New-Object System.Windows.Forms.Padding(0,5,8,5)
    $taskText = if ($Type -eq 'Routine') { [string]$Item.Task } else { [string]$Item.Text }
    $task = New-UiLabel -Text $taskText -FontSize 11.5 -FontStyle ([System.Drawing.FontStyle]::Bold) -ForeColor $script:Palette.Text
    $task.Dock = [System.Windows.Forms.DockStyle]::Fill
    $task.AutoEllipsis = $false
    $task.Padding = New-Object System.Windows.Forms.Padding(0,4,8,4)
    $standardText = if ($Type -eq 'Routine') { [string]$Item.Standard } else { [string]$Item.Group }
    $standard = New-UiLabel -Text $standardText -FontSize 10.5 -ForeColor $script:Palette.Muted
    $standard.Dock = [System.Windows.Forms.DockStyle]::Fill
    $standard.AutoEllipsis = $false
    $standard.Padding = New-Object System.Windows.Forms.Padding(0,4,8,4)
    $statusText = if ($Item.Done) { '已完成' } elseif ($Type -eq 'Routine') { '待开始' } else { '待完成' }
    $statusColor = if ($Item.Done) { $script:Palette.Success } elseif ($Type -eq 'Routine') { $script:Palette.Muted } else { $script:Palette.Warning }
    $status = New-UiLabel -Text $statusText -FontSize 10 -FontStyle ([System.Drawing.FontStyle]::Bold) -ForeColor $statusColor -TextAlign ([System.Drawing.ContentAlignment]::MiddleCenter)
    $status.Dock = [System.Windows.Forms.DockStyle]::Fill
    $status.AutoEllipsis = $false
    $successColor = $script:Palette.Success
    $mutedColor = $script:Palette.Muted
    $warningColor = $script:Palette.Warning
    $surfaceRaisedColor = $script:Palette.SurfaceRaised
    $surfaceColor = $script:Palette.Surface
    $cb.Tag = @{ Type=$Type; Id=$Item.Id; Row=$row; Status=$status }
    $cb.Add_CheckedChanged({
        if ($this.Tag.Type -eq 'Routine') { $rowData = @($script:CurrentRecord.Routine | Where-Object { $_.Id -eq $this.Tag.Id })[0] }
        else { $rowData = @($script:CurrentRecord.CoreTasks | Where-Object { $_.Id -eq $this.Tag.Id })[0] }
        if ($null -ne $rowData) { $rowData.Done = $this.Checked }
        $this.Tag.Status.Text = if ($this.Checked) { '已完成' } elseif ($this.Tag.Type -eq 'Routine') { '待开始' } else { '待完成' }
        $this.Tag.Status.ForeColor = if ($this.Checked) { $successColor } elseif ($this.Tag.Type -eq 'Routine') { $mutedColor } else { $warningColor }
        $this.Tag.Row.BackColor = if ($this.Checked) { $surfaceRaisedColor } else { $surfaceColor }
        $this.BackColor = $this.Tag.Row.BackColor
        $script:IsDirty = $true
        Refresh-Progress
    }.GetNewClosure())
    $enter = { $this.BackColor = $surfaceRaisedColor }.GetNewClosure()
    $leave = { $this.BackColor = if ($cb.Checked) { $surfaceRaisedColor } else { $surfaceColor } }.GetNewClosure()
    $row.Add_MouseEnter($enter)
    $row.Add_MouseLeave($leave)
    $grid.Controls.Add($cb,0,0)
    $grid.Controls.Add($time,1,0)
    $grid.Controls.Add($task,2,0)
    $grid.Controls.Add($standard,3,0)
    $grid.Controls.Add($status,4,0)
    $row.Controls.Add($grid)
    $script:Controls[$Type + ':' + $Item.Id] = $cb
    $script:TaskTextLabels += $task
    $Parent.Controls.Add($row)
    return $row
}

function New-FormPage {
    param([string]$Text)
    $page = New-Object System.Windows.Forms.TabPage
    $page.Text = $Text
    $page.BackColor = $script:Palette.DeepNight
    $page.ForeColor = $script:Palette.Text
    $page.Padding = New-Object System.Windows.Forms.Padding(0)
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
    $script:TaskTextLabels = @()
    $script:SummaryLabels = @{}
    $script:IsDirty = $false
    $script:TargetProgress = 0
    $script:AnimationPhase = 0

    $form = New-Object System.Windows.Forms.Form
    $script:Form = $form
    $form.Text = '每日复盘 · 深色专注工作台'
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.ClientSize = New-Object System.Drawing.Size(1440,920)
    $form.MinimumSize = New-Object System.Drawing.Size(1040,700)
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $form.AutoScroll = $true
    $form.BackColor = $script:Palette.DeepNight
    $form.ForeColor = $script:Palette.Text
    $form.Font = New-UiFont -Size 10.5
    if (-not $NoShow) { $form.Opacity = 0.02 }

    $root = New-Object System.Windows.Forms.TableLayoutPanel
    $root.Dock = [System.Windows.Forms.DockStyle]::Fill
    $root.RowCount = 2
    $root.ColumnCount = 1
    [void]$root.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute,96)))
    [void]$root.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent,100)))

    $header = New-Object System.Windows.Forms.TableLayoutPanel
    $header.Dock = [System.Windows.Forms.DockStyle]::Fill
    $header.BackColor = $script:Palette.DeepNight
    $header.ColumnCount = 3
    $header.RowCount = 1
    $header.Padding = New-Object System.Windows.Forms.Padding(24,14,24,10)
    [void]$header.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,36)))
    [void]$header.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20)))
    [void]$header.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,44)))

    $leftHead = New-Object System.Windows.Forms.Panel
    $leftHead.Dock = [System.Windows.Forms.DockStyle]::Fill
    $title = New-UiLabel -Text '每日复盘' -FontSize 25 -FontStyle ([System.Drawing.FontStyle]::Bold) -ForeColor $script:Palette.Text
    $title.AutoSize = $true; $title.Location = New-Object System.Drawing.Point(0,0)
    $subtitle = New-UiLabel -Text '专注当下，积累每一次进步' -FontSize 10.5 -ForeColor $script:Palette.Muted
    $subtitle.AutoSize = $true; $subtitle.Location = New-Object System.Drawing.Point(2,42)
    [void]$leftHead.Controls.AddRange(@($title,$subtitle))

    $middleHead = New-Object System.Windows.Forms.Panel
    $middleHead.Dock = [System.Windows.Forms.DockStyle]::Fill
    $dateLabel = New-UiLabel -Text ('{0}  ·  第 {1} 天' -f $script:CurrentRecord.Date,$script:CurrentRecord.DayNumber) -FontSize 11 -ForeColor $script:Palette.Muted
    $dateLabel.AutoSize = $true; $dateLabel.Location = New-Object System.Drawing.Point(8,16)
    $script:SaveLabel = New-UiLabel -Text '尚未保存修改' -FontSize 9.5 -ForeColor $script:Palette.Warning
    $script:SaveLabel.AutoSize = $true; $script:SaveLabel.Location = New-Object System.Drawing.Point(8,48)
    [void]$middleHead.Controls.AddRange(@($dateLabel,$script:SaveLabel))

    $actions = New-Object System.Windows.Forms.FlowLayoutPanel
    $actions.Dock = [System.Windows.Forms.DockStyle]::Fill
    $actions.FlowDirection = [System.Windows.Forms.FlowDirection]::RightToLeft
    $actions.WrapContents = $true
    $actions.Padding = New-Object System.Windows.Forms.Padding(0,6,0,0)
    $saveButton = New-UiButton -Text '保存' -Width 72 -BackColor $script:Palette.Primary
    $saveButton.Add_Click({ Save-CurrentRecord })
    $checkButton = New-UiButton -Text '检查' -Width 70
    $checkButton.Add_Click({ Show-UnfinishedReminder })
    $navMonth = New-UiButton -Text '本月' -Width 58
    $navWeek = New-UiButton -Text '本周' -Width 58
    $navNotes = New-UiButton -Text '记录' -Width 58
    $navToday = New-UiButton -Text '今日' -Width 58 -BackColor $script:Palette.PrimarySoft
    [void]$actions.Controls.AddRange(@($saveButton,$checkButton,$navMonth,$navWeek,$navNotes,$navToday))
    [void]$header.Controls.Add($leftHead,0,0)
    [void]$header.Controls.Add($middleHead,1,0)
    [void]$header.Controls.Add($actions,2,0)
    [void]$root.Controls.Add($header,0,0)

    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Name = 'MainTabs'
    $tabs.Dock = [System.Windows.Forms.DockStyle]::Fill
    $tabs.Appearance = [System.Windows.Forms.TabAppearance]::FlatButtons
    $tabs.ItemSize = New-Object System.Drawing.Size(0,1)
    $tabs.SizeMode = [System.Windows.Forms.TabSizeMode]::Fixed
    $tabs.Padding = New-Object System.Drawing.Point(0,0)
    $tabs.BackColor = $script:Palette.DeepNight
    $tabs.ForeColor = $script:Palette.Text

    $todayPage = New-FormPage -Text '今日'
    $todayGrid = New-Object System.Windows.Forms.TableLayoutPanel
    $todayGrid.Dock = [System.Windows.Forms.DockStyle]::Fill
    $todayGrid.Padding = New-Object System.Windows.Forms.Padding(18,8,18,18)
    $todayGrid.ColumnCount = 2; $todayGrid.RowCount = 1
    [void]$todayGrid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,68)))
    [void]$todayGrid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,32)))

    $mainColumn = New-Object System.Windows.Forms.FlowLayoutPanel
    $mainColumn.Dock = [System.Windows.Forms.DockStyle]::Fill
    $mainColumn.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $mainColumn.WrapContents = $false
    $mainColumn.AutoScroll = $true
    $mainColumn.BackColor = $script:Palette.DeepNight
    $mainColumn.Padding = New-Object System.Windows.Forms.Padding(0,0,12,0)
    $script:MainTaskFlow = $mainColumn
    $script:MainTaskFlow.AutoScroll = $true
    $mainColumn.Add_Resize({ Set-FlowRowWidths -Flow $this })
    [void]$mainColumn.Controls.Add((New-SectionHeading -Text '学习任务清单'))
    foreach ($item in @($script:CurrentRecord.Routine)) { New-FocusTaskRow -Parent $mainColumn -Item $item -Type 'Routine' | Out-Null }
    [void]$mainColumn.Controls.Add((New-SectionHeading -Text '必须完成' -Color $script:Palette.Danger))
    foreach ($item in @($script:CurrentRecord.CoreTasks | Where-Object { $_.Group -eq '必须完成' })) { New-FocusTaskRow -Parent $mainColumn -Item $item -Type 'Core' | Out-Null }
    [void]$mainColumn.Controls.Add((New-SectionHeading -Text '形成优势' -Color $script:Palette.Purple))
    foreach ($item in @($script:CurrentRecord.CoreTasks | Where-Object { $_.Group -eq '形成优势' })) { New-FocusTaskRow -Parent $mainColumn -Item $item -Type 'Core' | Out-Null }

    $sideColumn = New-Object System.Windows.Forms.FlowLayoutPanel
    $sideColumn.Dock = [System.Windows.Forms.DockStyle]::Fill
    $sideColumn.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $sideColumn.WrapContents = $false
    $sideColumn.AutoScroll = $true
    $sideColumn.BackColor = $script:Palette.DeepNight
    $sideColumn.Padding = New-Object System.Windows.Forms.Padding(12,0,0,0)
    $sideColumn.Add_Resize({ Set-FlowRowWidths -Flow $this })

    $progressCard = New-CardPanel -Height 166
    $progressTitle = New-UiLabel -Text '今日进度' -FontSize 13 -FontStyle ([System.Drawing.FontStyle]::Bold)
    $progressTitle.AutoSize = $true; $progressTitle.Location = New-Object System.Drawing.Point(14,12)
    $progressLabel = New-UiLabel -Text '0% · 已完成 0/0' -FontSize 15 -FontStyle ([System.Drawing.FontStyle]::Bold) -ForeColor $script:Palette.Primary
    $progressLabel.AutoSize = $true; $progressLabel.Location = New-Object System.Drawing.Point(14,48)
    $script:ProgressLabel = $progressLabel
    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Minimum = 0; $progress.Maximum = 100; $progress.Value = 0
    $progress.Visible = $false
    $progress.Size = New-Object System.Drawing.Size(1,1)
    $progress.Location = New-Object System.Drawing.Point(14,92)
    $script:ProgressBar = $progress
    $progressTrack = New-Object System.Windows.Forms.Panel
    $progressTrack.Name = 'ProgressTrack'
    $progressTrack.Location = New-Object System.Drawing.Point(14,92)
    $progressTrack.Size = New-Object System.Drawing.Size(320,16)
    $progressTrack.BackColor = $script:Palette.SurfaceRaised
    $progressTrack.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $progressTrack.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top
    $progressFill = New-Object System.Windows.Forms.Panel
    $progressFill.Name = 'ProgressFill'
    $progressFill.Location = New-Object System.Drawing.Point(0,0)
    $progressFill.Size = New-Object System.Drawing.Size(0,14)
    $progressFill.BackColor = $script:Palette.Primary
    [void]$progressTrack.Controls.Add($progressFill)
    $script:ProgressTrack = $progressTrack
    $script:ProgressFill = $progressFill
    [void]$progressCard.Controls.AddRange(@($progressTitle,$progressLabel,$progressTrack,$progress))
    $progressBarRef = $progress
    $progressCard.Add_Resize({
        $progressTrack.Width = [math]::Max(180,$this.ClientSize.Width - 28)
        $progressFill.Height = [math]::Max(1,$progressTrack.ClientSize.Height)
        $progressFill.Width = [int]($progressTrack.ClientSize.Width * ($progressBarRef.Value / 100.0))
    }.GetNewClosure())
    [void]$sideColumn.Controls.Add($progressCard)

    $energyCard = New-CardPanel -Height 142
    $energyTitle = New-UiLabel -Text '今日能量' -FontSize 13 -FontStyle ([System.Drawing.FontStyle]::Bold)
    $energyTitle.AutoSize = $true; $energyTitle.Location = New-Object System.Drawing.Point(14,12)
    $energyHint = New-UiLabel -Text '选择此刻状态，方便复盘时看见自己' -FontSize 9.5 -ForeColor $script:Palette.Muted
    $energyHint.AutoSize = $true; $energyHint.Location = New-Object System.Drawing.Point(14,38)
    $energyFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $energyFlow.Location = New-Object System.Drawing.Point(10,66); $energyFlow.Size = New-Object System.Drawing.Size(420,54)
    $energyFlow.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight; $energyFlow.WrapContents = $false
    $energyFlow.BackColor = $script:Palette.Surface
    $script:EnergyFlow = $energyFlow
    foreach ($energy in @(@('好',$script:Palette.Success),@('一般',$script:Palette.Primary),@('较差',$script:Palette.Warning))) {
        $radio = New-Object System.Windows.Forms.RadioButton
        $radio.Text = $energy[0]; $radio.Tag = $energy[0]; $radio.AutoSize = $true
        $radio.Font = New-UiFont -Size 9.5; $radio.ForeColor = $energy[1]; $radio.BackColor = $script:Palette.Surface
        $radio.Margin = New-Object System.Windows.Forms.Padding(4,8,8,4)
        $radio.Checked = ([string]$script:CurrentRecord.Energy -eq [string]$energy[0])
        $radio.Add_CheckedChanged({ if ($this.Checked) { $script:CurrentRecord.Energy = $this.Tag; $script:IsDirty = $true } })
        [void]$energyFlow.Controls.Add($radio)
    }
    [void]$energyCard.Controls.AddRange(@($energyTitle,$energyHint,$energyFlow))
    $energyCard.Add_Resize({ $energyFlow.Width = [math]::Max(180,$this.ClientSize.Width - 28) }.GetNewClosure())
    [void]$sideColumn.Controls.Add($energyCard)

    $reminderCard = New-CardPanel -Height 150
    $reminderTitle = New-UiLabel -Text '今日提醒' -FontSize 13 -FontStyle ([System.Drawing.FontStyle]::Bold)
    $reminderTitle.AutoSize = $true; $reminderTitle.Location = New-Object System.Drawing.Point(14,12)
    $reminder = New-UiLabel -Text '正在读取任务状态……' -FontSize 10.5 -ForeColor $script:Palette.Warning
    $reminder.AutoSize = $false; $reminder.AutoEllipsis = $false; $reminder.Size = New-Object System.Drawing.Size(380,82); $reminder.Location = New-Object System.Drawing.Point(14,48)
    $script:ReminderLabel = $reminder
    [void]$reminderCard.Controls.AddRange(@($reminderTitle,$reminder))
    $reminderCard.Add_Resize({ $reminder.Width = [math]::Max(170,$this.ClientSize.Width - 28); $reminder.Height = [math]::Max(70,$this.ClientSize.Height - 64) }.GetNewClosure())
    [void]$sideColumn.Controls.Add($reminderCard)

    $quickCard = New-CardPanel -Height 218
    $quickTitle = New-UiLabel -Text '今日关键产出' -FontSize 13 -FontStyle ([System.Drawing.FontStyle]::Bold)
    $quickTitle.AutoSize = $true; $quickTitle.Location = New-Object System.Drawing.Point(14,12)
    $quick = New-Object System.Windows.Forms.TextBox
    $quick.Multiline = $true; $quick.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $quick.Font = New-UiFont -Size 10.5; $quick.BackColor = $script:Palette.SurfaceRaised; $quick.ForeColor = $script:Palette.Text
    $quick.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $quick.Location = New-Object System.Drawing.Point(14,48); $quick.Size = New-Object System.Drawing.Size(420,146)
    $quick.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $quick.Text = [string]$script:CurrentRecord.Outputs.Math
    $quick.Tag = @{ Section='Outputs'; Key='Math' }
    $quick.Add_TextChanged({ Set-RecordTextValue -Section $this.Tag.Section -Key $this.Tag.Key -Value $this.Text })
    [void]$quickCard.Controls.AddRange(@($quickTitle,$quick))
    $quickCard.Add_Resize({ $quick.Width = [math]::Max(180,$this.ClientSize.Width - 28); $quick.Height = [math]::Max(88,$this.ClientSize.Height - 72) }.GetNewClosure())
    [void]$sideColumn.Controls.Add($quickCard)
    [void]$todayGrid.Controls.Add($mainColumn,0,0); [void]$todayGrid.Controls.Add($sideColumn,1,0)
    [void]$todayPage.Controls.Add($todayGrid)

    $notesPage = New-FormPage -Text '记录'
    $notesFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $notesFlow.Dock = [System.Windows.Forms.DockStyle]::Fill
    $notesFlow.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $notesFlow.WrapContents = $false; $notesFlow.AutoScroll = $true
    $notesFlow.BackColor = $script:Palette.DeepNight
    $notesFlow.Padding = New-Object System.Windows.Forms.Padding(18,8,18,18)
    $notesFlow.Add_Resize({ Set-FlowRowWidths -Flow $this })
    [void]$notesFlow.Controls.Add((New-SectionHeading -Text '今日产出记录'))
    foreach ($entry in @(@('数学题目/错题','Outputs','Math'),@('电路知识/公式','Outputs','Major'),@('Python/AI代码或结果','Outputs','PythonAI'),@('电子实践现象/照片/数据','Outputs','Practice'),@('英语新词和长难句','Outputs','English'),@('GitHub或文件保存位置','Outputs','GitHub'))) {
        New-TextInputRow -Parent $notesFlow -LabelText $entry[0] -Section $entry[1] -Key $entry[2] | Out-Null
    }
    [void]$notesFlow.Controls.Add((New-SectionHeading -Text '21:00 复盘'))
    foreach ($entry in @(@('今天最重要的完成项','Main'),@('没完成的原因','Reason'),@('明天起床后的第一件学习任务','Tomorrow'),@('明天只保留一个提高目标','Improve'))) {
        New-TextInputRow -Parent $notesFlow -LabelText $entry[0] -Section 'Review' -Key $entry[1] | Out-Null
    }
    [void]$notesFlow.Controls.Add((New-SectionHeading -Text '额外事项优先级' -Color $script:Palette.Warning))
    $extraPanel = New-CardPanel -Height 300
    $extraCheck = New-Object System.Windows.Forms.CheckBox
    $extraCheck.Text = '有额外事项需要打破今日计划'; $extraCheck.AutoSize = $true
    $extraCheck.Font = New-UiFont -Size 11 -Style ([System.Drawing.FontStyle]::Bold); $extraCheck.ForeColor = $script:Palette.Warning
    $extraCheck.BackColor = $script:Palette.Surface; $extraCheck.Location = New-Object System.Drawing.Point(14,14)
    $extraCheck.Checked = [bool]$script:CurrentRecord.ExtraPlanBreak.Enabled
    $extraCheck.Add_CheckedChanged({ $script:CurrentRecord.ExtraPlanBreak.Enabled=$this.Checked; $script:IsDirty=$true })
    [void]$extraPanel.Controls.Add($extraCheck)
    $extraFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $extraFlow.Location = New-Object System.Drawing.Point(12,52); $extraFlow.Size = New-Object System.Drawing.Size(680,226)
    $extraFlow.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown; $extraFlow.WrapContents = $false; $extraFlow.AutoScroll = $true
    $extraFlow.BackColor = $script:Palette.Surface
    foreach ($entry in @(@('事项内容','Item'),@('优先级（高/中/低）','Priority'),@('打破计划的原因','Reason'),@('对今日计划的影响','Impact'))) {
        $row = New-Object System.Windows.Forms.Panel; $row.Height=46; $row.Width=640
        $label = New-UiLabel -Text $entry[0] -FontSize 10 -ForeColor $script:Palette.Muted; $label.AutoSize=$true; $label.Location=New-Object System.Drawing.Point(0,10)
        $tb = New-Object System.Windows.Forms.TextBox; $tb.Font=New-UiFont -Size 10.5; $tb.BackColor=$script:Palette.SurfaceRaised; $tb.ForeColor=$script:Palette.Text
        $tb.Location=New-Object System.Drawing.Point(178,5); $tb.Size=New-Object System.Drawing.Size(440,32); $tb.Text=[string]$script:CurrentRecord.ExtraPlanBreak[$entry[1]]; $tb.Tag=$entry[1]
        $tb.Add_TextChanged({ $script:CurrentRecord.ExtraPlanBreak[$this.Tag] = $this.Text; $script:IsDirty=$true })
        [void]$row.Controls.AddRange(@($label,$tb)); [void]$extraFlow.Controls.Add($row)
    }
    [void]$extraPanel.Controls.Add($extraFlow); [void]$notesFlow.Controls.Add($extraPanel); [void]$notesPage.Controls.Add($notesFlow)

    $weekPage = New-FormPage -Text '本周'
    $weekLabel = New-Object System.Windows.Forms.RichTextBox
    $weekLabel.Dock=[System.Windows.Forms.DockStyle]::Fill; $weekLabel.ReadOnly=$true; $weekLabel.BorderStyle=[System.Windows.Forms.BorderStyle]::None
    $weekLabel.BackColor=$script:Palette.Surface; $weekLabel.ForeColor=$script:Palette.Text; $weekLabel.Font=New-UiFont -Size 12; $weekLabel.Padding=New-Object System.Windows.Forms.Padding(24); $weekLabel.ScrollBars=[System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $weekPage.Padding=New-Object System.Windows.Forms.Padding(18); [void]$weekPage.Controls.Add($weekLabel); $script:SummaryLabels['Week']=$weekLabel
    $monthPage = New-FormPage -Text '本月'
    $monthLabel = New-Object System.Windows.Forms.RichTextBox
    $monthLabel.Dock=[System.Windows.Forms.DockStyle]::Fill; $monthLabel.ReadOnly=$true; $monthLabel.BorderStyle=[System.Windows.Forms.BorderStyle]::None
    $monthLabel.BackColor=$script:Palette.Surface; $monthLabel.ForeColor=$script:Palette.Text; $monthLabel.Font=New-UiFont -Size 12; $monthLabel.Padding=New-Object System.Windows.Forms.Padding(24); $monthLabel.ScrollBars=[System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $monthPage.Padding=New-Object System.Windows.Forms.Padding(18); [void]$monthPage.Controls.Add($monthLabel); $script:SummaryLabels['Month']=$monthLabel

    [void]$tabs.TabPages.AddRange(@($todayPage,$notesPage,$weekPage,$monthPage))
    [void]$root.Controls.Add($tabs,0,1)
    [void]$form.Controls.Add($root)
    $navToday.Add_Click({ $tabs.SelectedIndex=0 }); $navNotes.Add_Click({ $tabs.SelectedIndex=1 }); $navWeek.Add_Click({ $tabs.SelectedIndex=2 }); $navMonth.Add_Click({ $tabs.SelectedIndex=3 })
    $form.Add_Resize({ Set-FlowRowWidths -Flow $script:MainTaskFlow; Set-FlowRowWidths -Flow $sideColumn; Set-FlowRowWidths -Flow $notesFlow })
    Refresh-Progress
    Refresh-SummaryPage -PageType 'Week'; Refresh-SummaryPage -PageType 'Month'

    $reminderTimer = New-Object System.Windows.Forms.Timer
    $reminderTimer.Interval = 60000
    $reminderTimer.Add_Tick({ Refresh-Progress; if ((Get-Date).Hour -eq 21 -and (Get-Date).Minute -lt 2) { Show-UnfinishedReminder } })
    $script:ReminderTimer = $reminderTimer
    $animationTimer = New-Object System.Windows.Forms.Timer
    $animationTimer.Interval = 60
    $animationTimer.Add_Tick({
        $script:AnimationPhase = ($script:AnimationPhase + 1) % 1000
        if ($script:Form.Opacity -lt 1) { $script:Form.Opacity = [math]::Min(1.0,$script:Form.Opacity + 0.10) }
        if ($script:ProgressBar.Value -lt $script:TargetProgress) { $script:ProgressBar.Value = [math]::Min($script:TargetProgress,$script:ProgressBar.Value + 2) }
        elseif ($script:ProgressBar.Value -gt $script:TargetProgress) { $script:ProgressBar.Value = [math]::Max($script:TargetProgress,$script:ProgressBar.Value - 2) }
        $script:ProgressFill.Width = [int]($script:ProgressTrack.ClientSize.Width * ($script:ProgressBar.Value / 100.0))
        if ($script:IsDirty) { $pulse=[int](120 + (45 * [math]::Abs([math]::Sin($script:AnimationPhase / 12)))); $script:SaveLabel.ForeColor=[System.Drawing.Color]::FromArgb(255,$pulse,150,90) }
        else { $script:SaveLabel.ForeColor=$script:Palette.Success }
    })
    $script:AnimationTimer = $animationTimer
    if (-not $NoShow) { $reminderTimer.Start(); $animationTimer.Start() }
    $form.Add_FormClosing({
        param($sender,$e)
        if ($script:IsDirty) {
            $choice=[System.Windows.Forms.MessageBox]::Show($sender,'今天有未保存修改，要先保存吗？','保存每日复盘',[System.Windows.Forms.MessageBoxButtons]::YesNoCancel,[System.Windows.Forms.MessageBoxIcon]::Question)
            if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) { Save-CurrentRecord }
            elseif ($choice -eq [System.Windows.Forms.DialogResult]::Cancel) { $e.Cancel=$true }
        }
        $reminderTimer.Stop(); $animationTimer.Stop()
    })
    if ($NoShow) { $form.Opacity=1; return $form }
    [System.Windows.Forms.Application]::Run($form)
    return $form
}

