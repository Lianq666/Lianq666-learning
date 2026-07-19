function Initialize-WpfAssemblies {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
}

function New-WpfBrush {
    param([Parameter(Mandatory=$true)][string]$Hex)
    return [System.Windows.Media.BrushConverter]::new().ConvertFromString($Hex)
}

function Get-WpfDashboardXaml {
    return @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="MainWindow"
        Title="每日复盘 · WPF 深夜专注工作台"
        Width="1488" Height="1055" MinWidth="1100" MinHeight="760"
        WindowStartupLocation="CenterScreen" Background="#08111F"
        FontFamily="Microsoft YaHei UI" Foreground="#F4F7FB"
        UseLayoutRounding="True" SnapsToDevicePixels="True" Opacity="1">
  <Window.Resources>
    <SolidColorBrush x:Key="PageBrush" Color="#08111F"/>
    <SolidColorBrush x:Key="CardBrush" Color="#0D1829"/>
    <SolidColorBrush x:Key="CardHoverBrush" Color="#12213A"/>
    <SolidColorBrush x:Key="LineBrush" Color="#24344E"/>
    <SolidColorBrush x:Key="TextBrush" Color="#F4F7FB"/>
    <SolidColorBrush x:Key="MutedBrush" Color="#91A0B8"/>
    <SolidColorBrush x:Key="PrimaryBrush" Color="#4E86FF"/>
    <SolidColorBrush x:Key="PrimarySoftBrush" Color="#16366F"/>
    <SolidColorBrush x:Key="SuccessBrush" Color="#58D6AF"/>
    <SolidColorBrush x:Key="WarningBrush" Color="#FFB84D"/>
    <SolidColorBrush x:Key="DangerBrush" Color="#FF6F76"/>

    <Style x:Key="CardStyle" TargetType="Border">
      <Setter Property="Background" Value="{StaticResource CardBrush}"/>
      <Setter Property="BorderBrush" Value="{StaticResource LineBrush}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="11"/>
      <Setter Property="Padding" Value="22"/>
    </Style>

    <Style x:Key="TaskRowStyle" TargetType="Border">
      <Setter Property="Background" Value="#0D1829"/>
      <Setter Property="BorderBrush" Value="#213149"/>
      <Setter Property="BorderThickness" Value="0,0,0,1"/>
      <Setter Property="Padding" Value="18,15"/>
      <Setter Property="MinHeight" Value="92"/>
    </Style>

    <Style x:Key="NavButtonStyle" TargetType="Button">
      <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
      <Setter Property="Background" Value="#101C2F"/>
      <Setter Property="BorderBrush" Value="{StaticResource LineBrush}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="16,9"/>
      <Setter Property="MinHeight" Value="42"/>
      <Setter Property="FontSize" Value="15"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="ButtonBorder" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="7" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="ButtonBorder" Property="Background" Value="#17315F"/>
                <Setter TargetName="ButtonBorder" Property="BorderBrush" Value="#4E86FF"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="ButtonBorder" Property="Opacity" Value="0.82"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PrimaryButtonStyle" TargetType="Button" BasedOn="{StaticResource NavButtonStyle}">
      <Setter Property="Background" Value="#3F79F3"/>
      <Setter Property="BorderBrush" Value="#6A9AFF"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Padding" Value="22,10"/>
    </Style>

    <Style x:Key="EnergyButtonStyle" TargetType="ToggleButton">
      <Setter Property="Foreground" Value="{StaticResource MutedBrush}"/>
      <Setter Property="Background" Value="#0B1525"/>
      <Setter Property="BorderBrush" Value="{StaticResource LineBrush}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Margin" Value="0,0,8,0"/>
      <Setter Property="Padding" Value="7,11"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ToggleButton">
            <Border x:Name="EnergyBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="7" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="EnergyBorder" Property="Background" Value="#16366F"/>
                <Setter TargetName="EnergyBorder" Property="BorderBrush" Value="#4E86FF"/>
                <Setter Property="Foreground" Value="#75A4FF"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="EnergyBorder" Property="BorderBrush" Value="#4E86FF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="TaskCheckStyle" TargetType="CheckBox">
      <Setter Property="Width" Value="28"/>
      <Setter Property="Height" Value="28"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="CheckBorder" Width="25" Height="25" CornerRadius="4" Background="#0B1525" BorderBrush="#DCE6F5" BorderThickness="1.6">
              <Path x:Name="CheckMark" Data="M 4,12 L 10,18 L 21,6" Stroke="#66A0FF" StrokeThickness="2.4" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Visibility="Collapsed"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="CheckBorder" Property="Background" Value="#17366F"/>
                <Setter TargetName="CheckBorder" Property="BorderBrush" Value="#66A0FF"/>
                <Setter TargetName="CheckMark" Property="Visibility" Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="CheckBorder" Property="BorderBrush" Value="#66A0FF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="8"/>
      <Setter Property="Background" Value="Transparent"/>
    </Style>
  </Window.Resources>

  <Grid Background="#08111F">
    <Image x:Name="ConstellationBackground" Stretch="UniformToFill" Opacity="0.26" IsHitTestVisible="False"/>
    <Grid Margin="38,26,38,28">
      <Grid.RowDefinitions>
        <RowDefinition Height="82"/>
        <RowDefinition Height="*"/>
      </Grid.RowDefinitions>

      <Grid x:Name="TopHeader" Grid.Row="0" Panel.ZIndex="10">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="300"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <StackPanel Grid.Column="0" VerticalAlignment="Center">
          <TextBlock Text="今日计划" FontSize="31" FontWeight="SemiBold" Foreground="#F7F9FC"/>
          <TextBlock Text="专注当下，积累每一次进步" FontSize="14" Foreground="#8D9BB1" Margin="0,6,0,0"/>
        </StackPanel>

        <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
          <Button x:Name="PrevDayButton" Content="‹" Style="{StaticResource NavButtonStyle}" Width="48" Margin="0,0,14,0" FontSize="28" Padding="0"/>
          <Border Background="#0F1B2E" BorderBrush="#24344E" BorderThickness="1" CornerRadius="8" Padding="20,10" MinWidth="292">
            <TextBlock x:Name="DateLabel" Text="2026-07-16  星期四" FontSize="16" TextAlignment="Center"/>
          </Border>
          <Button x:Name="NextDayButton" Content="›" Style="{StaticResource NavButtonStyle}" Width="48" Margin="14,0,28,0" FontSize="28" Padding="0"/>
          <Border Background="#0B1525" BorderBrush="#24344E" BorderThickness="1" CornerRadius="8" Padding="3">
            <StackPanel Orientation="Horizontal">
              <Button x:Name="TodayTabButton" Content="今天" Style="{StaticResource NavButtonStyle}" Background="#356FE8" BorderThickness="0" MinWidth="76"/>
              <Button x:Name="WeekTabButton" Content="本周" Style="{StaticResource NavButtonStyle}" Background="Transparent" BorderThickness="0" MinWidth="76"/>
              <Button x:Name="MonthTabButton" Content="本月" Style="{StaticResource NavButtonStyle}" Background="Transparent" BorderThickness="0" MinWidth="76"/>
            </StackPanel>
          </Border>
        </StackPanel>

        <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
          <TextBlock x:Name="SaveStateLabel" Text="尚未保存" Foreground="#FFB84D" VerticalAlignment="Center" Margin="0,0,16,0"/>
          <Button x:Name="SaveButton" Content="✓  保存" Style="{StaticResource PrimaryButtonStyle}" MinWidth="112"/>
        </StackPanel>
      </Grid>

      <Grid Grid.Row="1" Margin="0,14,0,0">
        <Grid x:Name="TodayPage">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="7*"/>
            <ColumnDefinition Width="24"/>
            <ColumnDefinition Width="3*"/>
          </Grid.ColumnDefinitions>

          <Border Grid.Column="0" Style="{StaticResource CardStyle}" Padding="0">
            <Grid>
              <Grid.RowDefinitions><RowDefinition Height="70"/><RowDefinition Height="*"/></Grid.RowDefinitions>
              <Grid Grid.Row="0" Margin="24,0" VerticalAlignment="Center">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="115"/></Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                  <TextBlock Text="&#xE8FD;" FontFamily="Segoe MDL2 Assets" Foreground="#4E86FF" FontSize="18" Margin="0,0,10,0"/>
                  <TextBlock Text="学习任务清单" FontSize="19" FontWeight="SemiBold"/>
                  <Border Background="#162237" CornerRadius="10" Padding="10,3" Margin="12,0,0,0">
                    <TextBlock x:Name="TaskCountLabel" Text="27 项任务" Foreground="#91A0B8" FontSize="12"/>
                  </Border>
                </StackPanel>
                <TextBlock Grid.Column="1" Text="预计时长" Foreground="#7F8DA3" FontSize="12" VerticalAlignment="Center" Margin="0,0,44,0"/>
                <TextBlock Grid.Column="2" Text="状态" Foreground="#7F8DA3" FontSize="12" VerticalAlignment="Center"/>
              </Grid>
              <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <StackPanel x:Name="DailyTaskList"/>
              </ScrollViewer>
            </Grid>
          </Border>

          <ScrollViewer Grid.Column="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
            <StackPanel>
              <Border x:Name="ProgressCard" Style="{StaticResource CardStyle}" Margin="0,0,0,16" MinHeight="300">
                <StackPanel>
                  <StackPanel Orientation="Horizontal">
                    <TextBlock Text="&#xE9D2;" FontFamily="Segoe MDL2 Assets" Foreground="#4E86FF" FontSize="18" Margin="0,0,10,0"/>
                    <TextBlock Text="今日进度" FontSize="19" FontWeight="SemiBold"/>
                  </StackPanel>
                  <Grid Margin="0,18,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="165"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Grid Width="152" Height="152">
                      <Ellipse Stroke="#223047" StrokeThickness="13" Width="126" Height="126"/>
                      <Path x:Name="ProgressArc" Width="126" Height="126"
                            HorizontalAlignment="Center" VerticalAlignment="Center" Stretch="None"
                            Stroke="#4E86FF" StrokeThickness="13"
                            StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
                      <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                        <TextBlock x:Name="ProgressPercent" Text="0%" FontSize="30" FontWeight="SemiBold" HorizontalAlignment="Center"/>
                        <TextBlock Text="完成度" Foreground="#91A0B8" FontSize="12" HorizontalAlignment="Center"/>
                      </StackPanel>
                    </Grid>
                    <Grid Grid.Column="1" Margin="16,2,0,0">
                      <Grid.RowDefinitions><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/></Grid.RowDefinitions>
                      <TextBlock Grid.Row="0" Text="已完成" Foreground="#91A0B8"/>
                      <TextBlock x:Name="CompletedCount" Grid.Row="0" Text="0 项" HorizontalAlignment="Right"/>
                      <TextBlock Grid.Row="1" Text="未完成" Foreground="#91A0B8"/>
                      <TextBlock x:Name="RemainingCount" Grid.Row="1" Text="27 项" HorizontalAlignment="Right"/>
                      <Separator Grid.Row="2" Background="#24344E" Margin="0,8"/>
                      <TextBlock Grid.Row="3" Text="总时长" Foreground="#91A0B8"/>
                      <TextBlock x:Name="PlannedDuration" Grid.Row="3" Text="14 小时 30 分" HorizontalAlignment="Right"/>
                      <TextBlock Grid.Row="4" Text="已完成时长" Foreground="#91A0B8"/>
                      <TextBlock x:Name="CompletedDuration" Grid.Row="4" Text="0 分钟" HorizontalAlignment="Right"/>
                    </Grid>
                  </Grid>
                  <TextBlock x:Name="ProgressEncouragement" Text="保持专注，今天从第一项开始。" Foreground="#91A0B8" Margin="0,17,0,0" TextWrapping="Wrap"/>
                </StackPanel>
              </Border>

              <Border x:Name="EnergyCard" Style="{StaticResource CardStyle}" Margin="0,0,0,16" MinHeight="178">
                <StackPanel>
                  <StackPanel Orientation="Horizontal">
                    <TextBlock Text="&#xEB51;" FontFamily="Segoe MDL2 Assets" Foreground="#4E86FF" FontSize="19" Margin="0,0,10,0"/>
                    <TextBlock Text="今日能量" FontSize="19" FontWeight="SemiBold"/>
                  </StackPanel>
                  <TextBlock Text="选择你当前的状态，帮助复盘时看见真实节奏" Foreground="#91A0B8" Margin="0,8,0,14"/>
                  <UniformGrid Columns="5">
                    <ToggleButton x:Name="EnergyFull" Content="充沛" Style="{StaticResource EnergyButtonStyle}"/>
                    <ToggleButton x:Name="EnergyGood" Content="良好" Style="{StaticResource EnergyButtonStyle}"/>
                    <ToggleButton x:Name="EnergyNormal" Content="一般" Style="{StaticResource EnergyButtonStyle}"/>
                    <ToggleButton x:Name="EnergyTired" Content="疲惫" Style="{StaticResource EnergyButtonStyle}"/>
                    <ToggleButton x:Name="EnergyLow" Content="低落" Style="{StaticResource EnergyButtonStyle}" Margin="0"/>
                  </UniformGrid>
                </StackPanel>
              </Border>

              <Border x:Name="ReminderCard" Style="{StaticResource CardStyle}" MinHeight="220">
                <StackPanel>
                  <StackPanel Orientation="Horizontal">
                    <TextBlock Text="&#xE7F4;" FontFamily="Segoe MDL2 Assets" Foreground="#4E86FF" FontSize="18" Margin="0,0,10,0"/>
                    <TextBlock Text="今日提醒" FontSize="19" FontWeight="SemiBold"/>
                  </StackPanel>
                  <Border Background="#101E34" BorderBrush="#253956" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,16,0,0">
                    <StackPanel>
                      <TextBlock x:Name="ReminderTime" Text="07:00" Foreground="#5F92FF" FontSize="18" FontWeight="SemiBold"/>
                      <TextBlock x:Name="ReminderTitle" Text="从第一项任务开始" FontSize="15" FontWeight="SemiBold" Margin="0,5,0,0"/>
                      <TextBlock x:Name="ReminderText" Text="完成后勾选，今日进度会实时更新。" Foreground="#91A0B8" Margin="0,6,0,0" TextWrapping="Wrap"/>
                    </StackPanel>
                  </Border>
                </StackPanel>
              </Border>
            </StackPanel>
          </ScrollViewer>
        </Grid>

        <Grid x:Name="WeekPage" Panel.ZIndex="0" Visibility="Collapsed">
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
          <TextBlock Text="本周复盘" FontSize="28" FontWeight="SemiBold" Margin="0,0,0,18"/>
          <Border Grid.Row="1" Style="{StaticResource CardStyle}">
            <Canvas x:Name="WeekCanvas" MinHeight="620"/>
          </Border>
        </Grid>

        <Grid x:Name="MonthPage" Panel.ZIndex="0" Visibility="Collapsed">
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
          <TextBlock Text="本月复盘" FontSize="28" FontWeight="SemiBold" Margin="0,0,0,18"/>
          <Border Grid.Row="1" Style="{StaticResource CardStyle}">
            <Grid x:Name="MonthHeatmap" MinHeight="620"/>
          </Border>
        </Grid>
      </Grid>
    </Grid>
  </Grid>
</Window>
'@
}

function Get-WpfNamedElement {
    param([Parameter(Mandatory=$true)][System.Windows.Window]$Window,[Parameter(Mandatory=$true)][string]$Name)
    return $Window.FindName($Name)
}

function Get-WpfTaskPresentation {
    param([hashtable]$Item,[string]$Type)
    $id = [string]$Item.Id
    $category = '计划'
    $color = '#4E86FF'
    $minutes = 30
    if ($id -match 'math') { $category='数学'; $color='#5B8EFF'; $minutes=120 }
    elseif ($id -match 'english') { $category='英语'; $color='#A67AF4'; $minutes=50 }
    elseif ($id -match 'major|circuit') { $category='专业'; $color='#50D0B0'; $minutes=90 }
    elseif ($id -match 'python|practice') { $category='编程'; $color='#4E86FF'; $minutes=90 }
    elseif ($id -match 'fitness|move') { $category='运动'; $color='#FFB84D'; $minutes=40 }
    elseif ($id -match 'sleep|lunch|dinner|free|break') { $category='生活'; $color='#91A0B8'; $minutes=30 }
    elseif ($id -match 'review|driving') { $category='复盘'; $color='#6C9DFF'; $minutes=40 }
    if ($Type -eq 'Routine' -and [string]$Item.Time -match '^(\d{1,2}):(\d{2})—(\d{1,2}):(\d{2})$') {
        $start = ([int]$Matches[1] * 60) + [int]$Matches[2]
        $end = ([int]$Matches[3] * 60) + [int]$Matches[4]
        if ($end -gt $start) { $minutes = $end - $start }
    }
    return @{ Category=$category; Color=$color; Minutes=$minutes }
}

function New-WpfTaskRow {
    param([Parameter(Mandatory=$true)][hashtable]$Item,[Parameter(Mandatory=$true)][ValidateSet('Routine','Core')][string]$Type)
    $meta = Get-WpfTaskPresentation -Item $Item -Type $Type
    $row = [System.Windows.Controls.Border]::new()
    $row.Style = $script:WpfWindow.FindResource('TaskRowStyle')
    $row.Tag = @{ Type=$Type; Id=[string]$Item.Id; BaseBrush=(New-WpfBrush '#0D1829'); HoverBrush=(New-WpfBrush '#12213A') }

    $grid = [System.Windows.Controls.Grid]::new()
    foreach ($width in @('44','98','*','116','104')) {
        $column = [System.Windows.Controls.ColumnDefinition]::new()
        $column.Width = [System.Windows.GridLengthConverter]::new().ConvertFromString($width)
        [void]$grid.ColumnDefinitions.Add($column)
    }

    $check = [System.Windows.Controls.CheckBox]::new()
    $check.Style = $script:WpfWindow.FindResource('TaskCheckStyle')
    $check.Width = 25; $check.Height = 25; $check.VerticalAlignment = 'Center'; $check.HorizontalAlignment = 'Left'
    $check.IsChecked = [bool]$Item.Done
    $check.Tag = @{ Type=$Type; Id=[string]$Item.Id; Row=$row }
    [System.Windows.Controls.Grid]::SetColumn($check,0)

    $categoryPanel = [System.Windows.Controls.StackPanel]::new()
    $categoryPanel.Orientation = 'Horizontal'; $categoryPanel.VerticalAlignment = 'Center'
    $dot = [System.Windows.Shapes.Ellipse]::new(); $dot.Width=9; $dot.Height=9; $dot.Fill=New-WpfBrush $meta.Color; $dot.Margin='0,0,8,0'
    $category = [System.Windows.Controls.TextBlock]::new(); $category.Text=$meta.Category; $category.Foreground=New-WpfBrush $meta.Color; $category.FontSize=13
    [void]$categoryPanel.Children.Add($dot); [void]$categoryPanel.Children.Add($category)
    [System.Windows.Controls.Grid]::SetColumn($categoryPanel,1)

    $content = [System.Windows.Controls.StackPanel]::new(); $content.VerticalAlignment='Center'; $content.Margin='4,0,18,0'
    $title = [System.Windows.Controls.TextBlock]::new(); $title.Text=if($Type -eq 'Routine'){[string]$Item.Task}else{[string]$Item.Text}; $title.FontSize=15; $title.FontWeight='SemiBold'; $title.Foreground=New-WpfBrush '#F4F7FB'; $title.TextWrapping='Wrap'
    $detail = [System.Windows.Controls.TextBlock]::new(); $detail.Text=if($Type -eq 'Routine'){[string]$Item.Standard}else{[string]$Item.Group}; $detail.FontSize=12.5; $detail.Foreground=New-WpfBrush '#91A0B8'; $detail.TextWrapping='Wrap'; $detail.Margin='0,6,0,0'
    [void]$content.Children.Add($title); [void]$content.Children.Add($detail)
    [System.Windows.Controls.Grid]::SetColumn($content,2)

    $duration = [System.Windows.Controls.TextBlock]::new(); $duration.Text=('{0} 分钟' -f $meta.Minutes); $duration.Foreground=New-WpfBrush '#5F92FF'; $duration.FontSize=13.5; $duration.VerticalAlignment='Center'; $duration.HorizontalAlignment='Left'
    [System.Windows.Controls.Grid]::SetColumn($duration,3)

    $statusBorder = [System.Windows.Controls.Border]::new(); $statusBorder.CornerRadius='12'; $statusBorder.Padding='11,5'; $statusBorder.HorizontalAlignment='Left'; $statusBorder.VerticalAlignment='Center'
    $status = [System.Windows.Controls.TextBlock]::new(); $status.FontSize=12.5; $status.Text=if($Item.Done){'已完成'}else{'未开始'}; $status.Foreground=if($Item.Done){New-WpfBrush '#58D6AF'}else{New-WpfBrush '#91A0B8'}
    $statusBorder.Background=if($Item.Done){New-WpfBrush '#12362E'}else{New-WpfBrush '#172338'}; $statusBorder.Child=$status
    $check.Tag.Status = $status; $check.Tag.StatusBorder=$statusBorder
    [System.Windows.Controls.Grid]::SetColumn($statusBorder,4)

    [void]$grid.Children.Add($check); [void]$grid.Children.Add($categoryPanel); [void]$grid.Children.Add($content); [void]$grid.Children.Add($duration); [void]$grid.Children.Add($statusBorder)
    $row.Child = $grid
    $script:WpfTaskControls[($Type + ':' + [string]$Item.Id)] = $check
    return $row
}

function Initialize-WpfTaskRows {
    param([System.Windows.Window]$Window)
    $list = Get-WpfNamedElement -Window $Window -Name 'DailyTaskList'
    $list.Children.Clear()
    foreach ($item in @($script:CurrentRecord.Routine)) { [void]$list.Children.Add((New-WpfTaskRow -Item $item -Type Routine)) }
    foreach ($item in @($script:CurrentRecord.CoreTasks)) { [void]$list.Children.Add((New-WpfTaskRow -Item $item -Type Core)) }
}

function Initialize-WpfStaticValues {
    param([System.Windows.Window]$Window)
    $stats = Get-ProgressStats -Record $script:CurrentRecord
    (Get-WpfNamedElement -Window $Window -Name 'DateLabel').Text = ('{0}  {1}' -f $script:CurrentRecord.Date,([datetime]$script:CurrentRecord.Date).ToString('dddd'))
    (Get-WpfNamedElement -Window $Window -Name 'ProgressPercent').Text = ('{0}%' -f $stats.Percent)
    (Get-WpfNamedElement -Window $Window -Name 'CompletedCount').Text = ('{0} 项' -f $stats.Done)
    (Get-WpfNamedElement -Window $Window -Name 'RemainingCount').Text = ('{0} 项' -f ($stats.Total-$stats.Done))
}

function Set-WpfBackground {
    param([System.Windows.Window]$Window)
    $path = Join-Path $script:BaseDir 'assets\midnight-constellation-v2.png'
    if (-not (Test-Path -LiteralPath $path)) { return }
    try {
        $bitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $bitmap.BeginInit(); $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.UriSource = [Uri]::new([IO.Path]::GetFullPath($path)); $bitmap.EndInit()
        (Get-WpfNamedElement -Window $Window -Name 'ConstellationBackground').Source = $bitmap
    } catch { }
}

function Get-WpfProgressGeometry {
    param([double]$Percent,[double]$Radius=56,[double]$Center=63)
    $safe = [math]::Min(100,[math]::Max(0,$Percent))
    if ($safe -le 0) { return [System.Windows.Media.PathGeometry]::new() }
    $startAngle = -90.0; $endAngle = $startAngle + (360.0 * $safe / 100.0)
    $start = [math]::PI * $startAngle / 180.0; $end = [math]::PI * $endAngle / 180.0
    $p1 = [System.Windows.Point]::new($Center + ($Radius * [math]::Cos($start)), $Center + ($Radius * [math]::Sin($start)))
    $p2 = [System.Windows.Point]::new($Center + ($Radius * [math]::Cos($end)), $Center + ($Radius * [math]::Sin($end)))
    $figure = [System.Windows.Media.PathFigure]::new(); $figure.StartPoint = $p1
    if ($safe -ge 99.99) {
        $mid = [System.Windows.Point]::new($Center + $Radius, $Center)
        $first = [System.Windows.Media.ArcSegment]::new(); $first.Point=$mid; $first.Size=[System.Windows.Size]::new($Radius,$Radius); $first.IsLargeArc=$false; $first.SweepDirection=[System.Windows.Media.SweepDirection]::Clockwise
        $second = [System.Windows.Media.ArcSegment]::new(); $second.Point=$p1; $second.Size=[System.Windows.Size]::new($Radius,$Radius); $second.IsLargeArc=$false; $second.SweepDirection=[System.Windows.Media.SweepDirection]::Clockwise
        [void]$figure.Segments.Add($first); [void]$figure.Segments.Add($second)
    } else {
        $arc = [System.Windows.Media.ArcSegment]::new(); $arc.Point=$p2; $arc.Size=[System.Windows.Size]::new($Radius,$Radius); $arc.IsLargeArc=($safe -gt 50); $arc.SweepDirection=[System.Windows.Media.SweepDirection]::Clockwise
        [void]$figure.Segments.Add($arc)
    }
    $geometry = [System.Windows.Media.PathGeometry]::new(); [void]$geometry.Figures.Add($figure); return $geometry
}

function Step-WpfProgressAnimation {
    if ($null -eq $script:WpfWindow) { return }
    $current = [double]$script:WpfDisplayedProgress; $target = [double]$script:WpfTargetProgress
    if ([math]::Abs($target - $current) -lt 0.05) { $current = $target }
    elseif ($target -gt $current) { $current = [math]::Min($target,$current + [math]::Max(0.8,(($target-$current)/5.0))) }
    else { $current = [math]::Max($target,$current - [math]::Max(0.8,(($current-$target)/5.0))) }
    $script:WpfDisplayedProgress = $current
    $arc = Get-WpfNamedElement -Window $script:WpfWindow -Name 'ProgressArc'
    $percent = Get-WpfNamedElement -Window $script:WpfWindow -Name 'ProgressPercent'
    if ($null -ne $arc) { $arc.Data = Get-WpfProgressGeometry -Percent $current }
    if ($null -ne $percent) { $percent.Text = ('{0}%' -f [int][math]::Round($current,0)) }
}

function Start-WpfProgressAnimation {
    param([double]$Target)
    $script:WpfTargetProgress = [math]::Min(100,[math]::Max(0,$Target))
    if ($null -eq $script:WpfProgressTimer) { Step-WpfProgressAnimation }
}

function Refresh-WpfProgress {
    if ($null -eq $script:WpfWindow) { return }
    $stats = Get-ProgressStats -Record $script:CurrentRecord
    $script:WpfTargetProgress = [double]$stats.Percent
    $count = Get-WpfNamedElement -Window $script:WpfWindow -Name 'TaskCountLabel'; $done = Get-WpfNamedElement -Window $script:WpfWindow -Name 'CompletedCount'; $remaining = Get-WpfNamedElement -Window $script:WpfWindow -Name 'RemainingCount'
    $planned = Get-WpfNamedElement -Window $script:WpfWindow -Name 'PlannedDuration'; $completedDuration = Get-WpfNamedElement -Window $script:WpfWindow -Name 'CompletedDuration'; $percent = Get-WpfNamedElement -Window $script:WpfWindow -Name 'ProgressPercent'
    if ($null -ne $count) { $count.Text = ('{0} 项任务' -f $stats.Total) }; if ($null -ne $done) { $done.Text = ('{0} 项' -f $stats.Done) }; if ($null -ne $remaining) { $remaining.Text = ('{0} 项' -f ($stats.Total-$stats.Done)) }
    $allMinutes = 0; $doneMinutes = 0
    foreach ($item in @($script:CurrentRecord.Routine)) { $m=(Get-WpfTaskPresentation -Item $item -Type Routine).Minutes; $allMinutes += $m; if($item.Done){$doneMinutes += $m} }
    foreach ($item in @($script:CurrentRecord.CoreTasks)) { $m=(Get-WpfTaskPresentation -Item $item -Type Core).Minutes; $allMinutes += $m; if($item.Done){$doneMinutes += $m} }
    if ($null -ne $planned) { $planned.Text = ('{0} 小时 {1} 分' -f [math]::Floor($allMinutes/60),($allMinutes%60)) }; if ($null -ne $completedDuration) { $completedDuration.Text = ('{0} 分钟' -f $doneMinutes) }; if ($null -ne $percent -and $null -eq $script:WpfProgressTimer) { $percent.Text = ('{0}%' -f $stats.Percent) }
    Start-WpfProgressAnimation -Target $stats.Percent
}

function Set-WpfTaskDone {
    param([Parameter(Mandatory=$true)][System.Windows.Controls.CheckBox]$CheckBox,[Parameter(Mandatory=$true)][bool]$Done)
    $tag = $CheckBox.Tag; $stats = Set-TaskCompletion -Record $script:CurrentRecord -Type $tag.Type -Id $tag.Id -Done $Done
    if ($Done) { $tag.Status.Text='已完成'; $tag.Status.Foreground=New-WpfBrush '#58D6AF'; $tag.StatusBorder.Background=New-WpfBrush '#12362E'; $tag.Row.Background=New-WpfBrush '#12213A' }
    else { $tag.Status.Text='未开始'; $tag.Status.Foreground=New-WpfBrush '#91A0B8'; $tag.StatusBorder.Background=New-WpfBrush '#172338'; $tag.Row.Background=New-WpfBrush '#0D1829' }
    $script:IsDirty = $true; Refresh-WpfProgress; return $stats
}

function Wire-WpfTaskInteractions {
    foreach ($check in @($script:WpfTaskControls.Values)) {
        $check.Add_Checked({ Set-WpfTaskDone -CheckBox $this -Done ([bool]$this.IsChecked) | Out-Null })
        $check.Add_Unchecked({ Set-WpfTaskDone -CheckBox $this -Done $false | Out-Null })
    }
}

function Get-WpfRecordIfExists {
    param([datetime]$Date)
    $path = Join-Path $script:DataDir ($Date.ToString('yyyy-MM-dd') + '.json')
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try { return ConvertTo-MutableHashtable (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

function Get-WeekVisualModel {
    param([datetime]$AnchorDate)
    $monday = $AnchorDate.Date.AddDays(-(([int]$AnchorDate.DayOfWeek + 6) % 7))
    $days = @(); $categoryTotals = [ordered]@{ 数学=0; 专业基础=0; Python与AI=0; 英语=0; 实践与运动=0; 其他=0 }
    for ($i=0; $i -lt 7; $i++) {
        $date = $monday.AddDays($i); $record = Get-WpfRecordIfExists -Date $date; $rate=0; $done=0; $total=0; $has=($null -ne $record)
        if ($has) { $stats=Get-ProgressStats -Record $record; $rate=[int]$stats.Percent; $done=[int]$stats.Done; $total=[int]$stats.Total; foreach($task in @($record.CoreTasks | Where-Object {$_.Done})){ $id=[string]$task.Id; if($id -match 'math'){$categoryTotals['数学']++} elseif($id -match 'major'){$categoryTotals['专业基础']++} elseif($id -match 'python'){$categoryTotals['Python与AI']++} elseif($id -match 'english'){$categoryTotals['英语']++} elseif($id -match 'move|practice|fitness'){$categoryTotals['实践与运动']++} else {$categoryTotals['其他']++} } }
        $days += ,@{ Date=$date; Label=$date.ToString('MM/dd'); Rate=$rate; Done=$done; Total=$total; HasRecord=$has }
    }
    $summary = Get-PeriodSummary -StartDate $monday -EndDate $monday.AddDays(6)
    return [ordered]@{ StartDate=$monday; Days=$days; CategoryTotals=$categoryTotals; Summary=$summary; Advice=(Get-StandardAdvice -Summary $summary) }
}

function Get-MonthVisualModel {
    param([datetime]$AnchorDate)
    $first = [datetime]::new($AnchorDate.Year,$AnchorDate.Month,1); $count=[datetime]::DaysInMonth($first.Year,$first.Month); $cells=@()
    $leading = ([int]$first.DayOfWeek + 6) % 7
    for($i=0;$i -lt ($leading+$count);$i++) { if($i -lt $leading){$cells+=,@{Date=$null;HasRecord=$false;Rate=0}} else {$date=$first.AddDays($i-$leading);$record=Get-WpfRecordIfExists -Date $date;$rate=0;if($null -ne $record){$rate=(Get-ProgressStats -Record $record).Percent};$cells+=,@{Date=$date;HasRecord=($null -ne $record);Rate=[int]$rate}} }
    while($cells.Count % 7 -ne 0){$cells+=,@{Date=$null;HasRecord=$false;Rate=0}}
    $summary=Get-PeriodSummary -StartDate $first -EndDate $first.AddMonths(1).AddDays(-1)
    return [ordered]@{ Month=$first; Cells=$cells; Weeks=($cells.Count/7); Summary=$summary; Advice=(Get-StandardAdvice -Summary $summary) }
}

function New-WpfTextBlock {
    param([string]$Text,[double]$FontSize=13,[string]$Foreground='#F4F7FB',[string]$Weight='Normal')
    $tb=[System.Windows.Controls.TextBlock]::new();$tb.Text=$Text;$tb.FontSize=$FontSize;$tb.Foreground=New-WpfBrush $Foreground;$tb.FontWeight=$Weight;$tb.TextWrapping='Wrap';return $tb
}

function New-WpfMetricCard {
    param([string]$Label,[string]$Value,[string]$Accent='#4E86FF',[int]$Width=190)
    $card=[System.Windows.Controls.Border]::new();$card.Width=$Width;$card.Height=78;$card.Background=New-WpfBrush '#101E34';$card.BorderBrush=New-WpfBrush '#243956';$card.BorderThickness='1';$card.CornerRadius='8';$card.Padding='14,10';$stack=[System.Windows.Controls.StackPanel]::new();[void]$stack.Children.Add((New-WpfTextBlock -Text $Label -FontSize 11 -Foreground '#91A0B8'));[void]$stack.Children.Add((New-WpfTextBlock -Text $Value -FontSize 22 -Foreground $Accent -Weight 'SemiBold'));$card.Child=$stack;return $card
}

function Render-WpfWeekPage {
    param([datetime]$AnchorDate)
    $canvas=Get-WpfNamedElement -Window $script:WpfWindow -Name 'WeekCanvas';$canvas.Children.Clear();$canvas.Width=900;$canvas.Height=620
    $model=Get-WeekVisualModel -AnchorDate $AnchorDate
    [void]$canvas.Children.Add((New-WpfTextBlock -Text ('{0} — {1}  ·  完成率 {2}%' -f $model.StartDate.ToString('yyyy-MM-dd'),$model.Days[-1].Date.ToString('yyyy-MM-dd'),$model.Summary.CompletionRate) -FontSize 19 -Weight 'SemiBold'))
    $metrics=@(
        (New-WpfMetricCard -Label '有效记录' -Value ($model.Summary.Days.ToString()+' 天') -Accent '#5F92FF'),
        (New-WpfMetricCard -Label '完成任务' -Value ($model.Summary.Done.ToString()+'/'+$model.Summary.Total) -Accent '#58D6AF'),
        (New-WpfMetricCard -Label '睡眠按时' -Value ($model.Summary.SleepDays.ToString()+' 天') -Accent '#A67AF4'),
        (New-WpfMetricCard -Label '额外事项' -Value ($model.Summary.ExtraPlanBreaks.ToString()+' 次') -Accent '#FFB84D')
    );for($m=0;$m -lt $metrics.Count;$m++){[System.Windows.Controls.Canvas]::SetLeft($metrics[$m],30+$m*205);[System.Windows.Controls.Canvas]::SetTop($metrics[$m],55);[void]$canvas.Children.Add($metrics[$m])}
    $categoryIndex=0;foreach($entry in $model.CategoryTotals.GetEnumerator()){ $cat=New-WpfTextBlock -Text ($entry.Key+'  '+$entry.Value+' 项') -FontSize 11 -Foreground '#B9C6DA';[System.Windows.Controls.Canvas]::SetLeft($cat,30+($categoryIndex%3)*250);[System.Windows.Controls.Canvas]::SetTop($cat,158+[math]::Floor($categoryIndex/3)*28);[void]$canvas.Children.Add($cat);$categoryIndex++ }
    $maxHeight=270;$barWidth=64;$gap=30;$baseY=350
    for($i=0;$i -lt 7;$i++){ $day=$model.Days[$i];$height=[math]::Max(8,[int]($maxHeight*$day.Rate/100.0));$barColor=if($day.HasRecord){if($day.Rate -ge 85){'#58D6AF'}elseif($day.Rate -ge 60){'#4E86FF'}else{'#2A4F82'}}else{'#172338'};$bar=[System.Windows.Shapes.Rectangle]::new();$bar.Width=$barWidth;$bar.Height=$height;$bar.RadiusX=8;$bar.RadiusY=8;$bar.Fill=New-WpfBrush $barColor;[System.Windows.Controls.Canvas]::SetLeft($bar,30+$i*($barWidth+$gap));[System.Windows.Controls.Canvas]::SetTop($bar,$baseY-$height);[void]$canvas.Children.Add($bar);$label=New-WpfTextBlock -Text $day.Label -FontSize 11 -Foreground '#91A0B8';[System.Windows.Controls.Canvas]::SetLeft($label,36+$i*($barWidth+$gap));[System.Windows.Controls.Canvas]::SetTop($label,$baseY+14);[void]$canvas.Children.Add($label);$rate=New-WpfTextBlock -Text ($day.Rate.ToString()+'%') -FontSize 12 -Foreground '#F4F7FB';[System.Windows.Controls.Canvas]::SetLeft($rate,42+$i*($barWidth+$gap));[System.Windows.Controls.Canvas]::SetTop($rate,$baseY-$height-26);[void]$canvas.Children.Add($rate) }
    $summaryText=('有效记录 {0} 天   已完成 {1}/{2}   睡眠按时 {3} 天   产出填写 {4} 项' -f $model.Summary.Days,$model.Summary.Done,$model.Summary.Total,$model.Summary.SleepDays,$model.Summary.OutputCount);$summary=New-WpfTextBlock -Text $summaryText -FontSize 14 -Foreground '#C0CBE0';[System.Windows.Controls.Canvas]::SetLeft($summary,30);[System.Windows.Controls.Canvas]::SetTop($summary,430);[void]$canvas.Children.Add($summary);$advice=New-WpfTextBlock -Text ('标准评估：'+$model.Advice) -FontSize 14 -Foreground '#FFB84D';[System.Windows.Controls.Canvas]::SetLeft($advice,30);[System.Windows.Controls.Canvas]::SetTop($advice,480);$advice.Width=820;[void]$canvas.Children.Add($advice)
}

function Get-WpfHeatBrush {
    param([bool]$HasRecord,[int]$Rate)
    if(-not $HasRecord){return New-WpfBrush '#101B2C'};if($Rate -ge 85){return New-WpfBrush '#3D8C77'};if($Rate -ge 60){return New-WpfBrush '#2C6A87'};if($Rate -gt 0){return New-WpfBrush '#1E466C'};return New-WpfBrush '#172338'
}

function Render-WpfMonthPage {
    param([datetime]$AnchorDate)
    $grid=Get-WpfNamedElement -Window $script:WpfWindow -Name 'MonthHeatmap';$grid.Children.Clear();$grid.RowDefinitions.Clear();$grid.ColumnDefinitions.Clear();$model=Get-MonthVisualModel -AnchorDate $AnchorDate
    for($c=0;$c -lt 7;$c++){[void]$grid.ColumnDefinitions.Add([System.Windows.Controls.ColumnDefinition]::new())};for($r=0;$r -lt ($model.Weeks+2);$r++){[void]$grid.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())}
    foreach($name in @('一','二','三','四','五','六','日')){$tb=New-WpfTextBlock -Text $name -FontSize 12 -Foreground '#91A0B8';$tb.HorizontalAlignment='Center';$tb.Margin='0,0,0,10';[void]$grid.Children.Add($tb);[System.Windows.Controls.Grid]::SetRow($tb,0);[System.Windows.Controls.Grid]::SetColumn($tb,$grid.Children.Count-1)}
    for($i=0;$i -lt $model.Cells.Count;$i++){ $cell=$model.Cells[$i];$border=[System.Windows.Controls.Border]::new();$border.Margin='3';$border.CornerRadius='6';$border.Background=Get-WpfHeatBrush -HasRecord $cell.HasRecord -Rate $cell.Rate;$border.ToolTip=if($null -eq $cell.Date){'无日期'}else{('{0}  完成率 {1}%' -f $cell.Date.ToString('yyyy-MM-dd'),$cell.Rate)};$cellLabel=if($null -eq $cell.Date){''}else{$cell.Date.Day.ToString()};$tb=New-WpfTextBlock -Text $cellLabel -FontSize 12 -Foreground '#D9E2F2';$tb.HorizontalAlignment='Center';$tb.VerticalAlignment='Center';$border.Child=$tb;[void]$grid.Children.Add($border);[System.Windows.Controls.Grid]::SetRow($border,1+[math]::Floor($i/7));[System.Windows.Controls.Grid]::SetColumn($border,$i%7) }
    $advice=New-WpfTextBlock -Text ('本月评估：'+$model.Advice) -FontSize 14 -Foreground '#FFB84D';$advice.Margin='4,18,4,0';$advice.Width=860;[void]$grid.Children.Add($advice);[System.Windows.Controls.Grid]::SetRow($advice,$model.Weeks+1);[System.Windows.Controls.Grid]::SetColumnSpan($advice,7)
}

function Set-WpfPage {
    param([ValidateSet('Today','Week','Month')][string]$Page)
    if ($null -eq $script:WpfWindow) { return }
    $today = Get-WpfNamedElement -Window $script:WpfWindow -Name 'TodayPage'
    $week = Get-WpfNamedElement -Window $script:WpfWindow -Name 'WeekPage'
    $month = Get-WpfNamedElement -Window $script:WpfWindow -Name 'MonthPage'
    $today.Visibility = if ($Page -eq 'Today') { 'Visible' } else { 'Collapsed' }
    $week.Visibility = if ($Page -eq 'Week') { 'Visible' } else { 'Collapsed' }
    $month.Visibility = if ($Page -eq 'Month') { 'Visible' } else { 'Collapsed' }
    if ($Page -eq 'Week') { Render-WpfWeekPage -AnchorDate ([datetime]$script:CurrentRecord.Date) }
    if ($Page -eq 'Month') { Render-WpfMonthPage -AnchorDate ([datetime]$script:CurrentRecord.Date) }
    foreach ($name in @('TodayTabButton','WeekTabButton','MonthTabButton')) {
        $button = Get-WpfNamedElement -Window $script:WpfWindow -Name $name
        $button.Background = if ($name -eq ($Page + 'TabButton')) { New-WpfBrush '#356FE8' } else { New-WpfBrush '#0B1525' }
    }
}

function Save-WpfRecord {
    if ($null -eq $script:CurrentRecord) { return }
    Save-DailyRecord -Record $script:CurrentRecord | Out-Null
    $script:IsDirty = $false
    $label = Get-WpfNamedElement -Window $script:WpfWindow -Name 'SaveStateLabel'
    if ($null -ne $label) { $label.Text = ('已保存 {0}' -f (Get-Date).ToString('HH:mm')); $label.Foreground = New-WpfBrush '#58D6AF' }
}

function Set-WpfDate {
    param([datetime]$Date)
    if ($script:IsDirty) { Save-WpfRecord }
    $script:CurrentRecord = Load-DailyRecord -DateKey $Date.ToString('yyyy-MM-dd')
    $script:WpfTaskControls = @{}
    Initialize-WpfTaskRows -Window $script:WpfWindow
    Wire-WpfTaskInteractions
    Initialize-WpfStaticValues -Window $script:WpfWindow
    Refresh-WpfProgress
}

function Wire-WpfNavigation {
    $window = $script:WpfWindow
    (Get-WpfNamedElement -Window $window -Name 'PrevDayButton').Add_Click({ Set-WpfDate -Date ([datetime]$script:CurrentRecord.Date).AddDays(-1) })
    (Get-WpfNamedElement -Window $window -Name 'NextDayButton').Add_Click({ Set-WpfDate -Date ([datetime]$script:CurrentRecord.Date).AddDays(1) })
    (Get-WpfNamedElement -Window $window -Name 'TodayTabButton').Add_Click({ Set-WpfPage -Page Today })
    (Get-WpfNamedElement -Window $window -Name 'WeekTabButton').Add_Click({ Set-WpfPage -Page Week })
    (Get-WpfNamedElement -Window $window -Name 'MonthTabButton').Add_Click({ Set-WpfPage -Page Month })
    (Get-WpfNamedElement -Window $window -Name 'SaveButton').Add_Click({ Save-WpfRecord })
    $energyMap = @{
        EnergyFull='充沛'; EnergyGood='良好'; EnergyNormal='一般'; EnergyTired='疲惫'; EnergyLow='低落'
    }
    foreach ($name in $energyMap.Keys) {
        $button = Get-WpfNamedElement -Window $window -Name $name; $button.Tag = $energyMap[$name]
        $storedEnergy = [string]$script:CurrentRecord.Energy
        if ($storedEnergy -eq '好') { $storedEnergy = '良好' } elseif ($storedEnergy -eq '较差') { $storedEnergy = '疲惫' }
        $button.IsChecked = ($storedEnergy -eq [string]$button.Tag)
        $button.Add_Click({ $script:CurrentRecord.Energy = [string]$this.Tag; $script:IsDirty=$true })
    }
}

function Start-WpfDashboard {
    param([switch]$NoShow)
    Initialize-WpfAssemblies
    $script:CurrentRecord = Load-DailyRecord -DateKey (Get-Date).ToString('yyyy-MM-dd')
    $script:WpfTaskControls = @{}
    $script:WpfDisplayedProgress = 0.0
    $script:WpfTargetProgress = 0.0
    $script:WpfProgressTimer = $null
    $reader = [System.Xml.XmlNodeReader]::new([xml](Get-WpfDashboardXaml))
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    $script:WpfWindow = $window
    Set-WpfBackground -Window $window
    Initialize-WpfTaskRows -Window $window
    Wire-WpfTaskInteractions
    Wire-WpfNavigation
    Initialize-WpfStaticValues -Window $window
    Refresh-WpfProgress
    Render-WpfWeekPage -AnchorDate ([datetime]$script:CurrentRecord.Date)
    Render-WpfMonthPage -AnchorDate ([datetime]$script:CurrentRecord.Date)
    $script:WpfProgressTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $script:WpfProgressTimer.Interval = [TimeSpan]::FromMilliseconds(28)
    $script:WpfProgressTimer.Add_Tick({ Step-WpfProgressAnimation })
    if ($NoShow) { $script:WpfProgressTimer.Stop(); $script:WpfProgressTimer=$null; return $window }
    $script:WpfProgressTimer.Start()
    $window.Add_Closing({ if ($script:IsDirty) { Save-WpfRecord }; if ($null -ne $script:WpfProgressTimer) { $script:WpfProgressTimer.Stop() } })
    [void]$window.ShowDialog()
    return $window
}

function Export-WpfDashboardPreview {
    param([Parameter(Mandatory=$true)][string]$Path,[int]$Width=1488,[int]$Height=1055,[ValidateSet('Today','Week','Month')][string]$Page='Today')
    $window = Start-WpfDashboard -NoShow
    if ($Page -ne 'Today') { Set-WpfPage -Page $Page }
    $window.Width=$Width; $window.Height=$Height; $window.WindowState='Normal'; $window.Left=-10000; $window.Top=-10000; $window.Show(); $window.UpdateLayout(); [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{},[System.Windows.Threading.DispatcherPriority]::Render)
    $bitmap=[System.Windows.Media.Imaging.RenderTargetBitmap]::new($Width,$Height,96,96,[System.Windows.Media.PixelFormats]::Pbgra32);$bitmap.Render($window)
    $encoder=[System.Windows.Media.Imaging.PngBitmapEncoder]::new();[void]$encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap));$full=[IO.Path]::GetFullPath($Path);$parent=Split-Path -Parent $full;if(-not(Test-Path $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null};$stream=[IO.File]::Open($full,[IO.FileMode]::Create);try{$encoder.Save($stream)}finally{$stream.Dispose()};$window.Close();Write-Output ('PASS: wpf preview rendered ' + $full)
}

















