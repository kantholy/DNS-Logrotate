$TaskName = "DNS-LogRotate"

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if($task) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false | Out-Null
    Write-Host "Task removed: $TaskName" -ForegroundColor Green
} else {
    Write-Host "No Task to remove." -ForegroundColor Yellow
}
