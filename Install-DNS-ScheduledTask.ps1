$TaskName = "DNS-LogRotate"

$TaskAction = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy ByPass -File `"Start-DNS-LogRotate.ps1`"" `
    -WorkingDirectory $PSScriptRoot


$TaskTrigger = New-ScheduledTaskTrigger -Daily -At "23:59"


$task = Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $TaskAction `
    -Trigger $TaskTrigger `
    -User "SYSTEM" `
    -Force



if($task) {
    Write-Host "Task successfully created: $TaskName" -ForegroundColor Green
    Start-Sleep -Seconds 3
    Exit 0
} else {
    Write-Error "Error while creating Scheduled Task: $TaskName"
    Start-Sleep -Seconds 5
    Exit 1
}

