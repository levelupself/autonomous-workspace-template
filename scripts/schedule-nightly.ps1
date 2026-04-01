# Creates a Windows Scheduled Task to run "task agent:run" nightly at 10pm CST
# Run once as Administrator: powershell -ExecutionPolicy Bypass -File scripts\schedule-nightly.ps1

$TaskName  = "AutonomousWorkspace-NightlyRun"
$WorkDir   = "C:\Users\akim\autonomous-workspace"
$Action    = New-ScheduledTaskAction `
    -Execute  "C:\Program Files\Git\bin\bash.exe" `
    -Argument "-c 'cd /c/Users/akim/autonomous-workspace && task agent:run >> .claude/logs/nightly.log 2>&1'" `
    -WorkingDirectory $WorkDir

$Trigger   = New-ScheduledTaskTrigger -Daily -At "22:00"   # 10:00 PM local (CST)

$Settings  = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 6) `
    -StartWhenAvailable `
    -WakeToRun

$Principal = New-ScheduledTaskPrincipal `
    -UserId   $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Highest

# Remove existing task if present
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask `
    -TaskName  $TaskName `
    -Action    $Action `
    -Trigger   $Trigger `
    -Settings  $Settings `
    -Principal $Principal `
    -Description "Runs autonomous dev agents nightly at 10pm CST"

Write-Host "Scheduled task created: $TaskName"
Write-Host "Runs daily at 10:00 PM. Logs: $WorkDir\.claude\logs\nightly.log"
Write-Host ""
Write-Host "To verify:  schtasks /query /tn $TaskName /fo LIST"
Write-Host "To run now: schtasks /run /tn $TaskName"
Write-Host "To remove:  schtasks /delete /tn $TaskName /f"
