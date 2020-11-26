#requires -version 2
<# 
.SYNOPSIS 
    DNS Debug Log Rotation.
     
.DESCRIPTION
    This Script collects the DNS debug logfile and writes all DNS queries to a daily log file

    !! Need to run on DNS Server as Scheduled Task
    (can be run daily or more often if log file grows to large)

    - Stops the DNS Server Service
    - Moves Logfile
    - Starts DNS
    - removes unnecessary empty lines from Logfile
    - cleanup

.NOTES
    Version  : 1.0
    Author   : Tobias Duethorn <tobias@duethorn.cc>
    Created  : 2020-11-26
    Modified : 2020-11-26
#>


$ErrorActionPreference = "SilentlyContinue"

$DebugLogfile = "C:\Windows\Temp\DNS\dns.log"

$TargetFolder = "C:\DNS-LogRotate\" # needs trailing slash!


$Keep_Days = 14

$Now = Get-Date


# 1. Stop DNS Server
Stop-Service DNS

# 2. Move Logfile

Move-Item -Path $DebugLogfile -Destination $TargetFolder -Force

# 3. Start DNS Server

Start-Service DNS


# 4. remove unnecessary lines from log

$LogFile = Join-Path -Path $TargetFolder -ChildPath (Split-Path -Path $DebugLogfile -Leaf)

$TargetFile = Join-Path -Path $TargetFolder -ChildPath ("DNS_{0:yyyy-MM-dd}.log" -f (Get-Date))


# .NET StreamReader + StreamWriter for efficient logfile traversal and output!
$input = New-Object IO.StreamReader($LogFile)
$output = New-Object IO.StreamWriter($TargetFile, $true)

while($input.Peek() -gt 0) {
    $line = $input.ReadLine()

    # resolve proper URIs
    $line = $line -replace '\([0-9]{1,2}\)', '.'

    if($line.Length -lt 112) {
        continue;
    }

    $timestamp = $line.Substring(0, 20)
    $ip = $line.Substring(58, 15)
    $query = $line.Substring(104,6)
    $target = $line.Substring(112)
    $target = $target.Substring(0, $target.Length - 1)


    $output.WriteLine($timestamp + "`t" + $ip + "`t" + $query + "`t" + $target)

}

$input.Close();
$output.Close();

# 5. Cleanup

Remove-Item -Path $LogFile

Get-ChildItem -Path $Target -Filter "*.log" | ForEach-Object {


    if($_.LastWriteTime.AddDays(0) -lt $Now) {
        
        Write-Host "Delete File:" $_.BaseName
    }

}
