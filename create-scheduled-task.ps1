#This script is intended to be deployed using PDQ or other for the purposes of creating a scheduled task for LogOff-IdleSessions.ps1 to run

#copy script to correct location
robocopy . C:\Windows\System32\WindowsPowerShell\v1.0\Scripts\ LogOff-IdleSessions.ps1

#creates a scheduled task that will run at logon and repeat every hour
$Script = "C:\Windows\System32\WindowsPowerShell\v1.0\Scripts\LogOff-IdleSessions.ps1"
Unregister-ScheduledTask -TaskName 'log-off-idle-sessions' -Confirm:$false
$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"-Argument "-File $($Script)"
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfIdle
$Principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId SYSTEM
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal
$CompleteTask = Register-ScheduledTask -TaskName 'log-off-idle-sessions' -InputObject $Task -User 'SYSTEM'
$CompleteTask.Triggers.Repetition.Duration = "P1D"
$CompleteTask.Triggers.Repetition.Interval = "PT1H"
$CompleteTask | Set-ScheduledTask