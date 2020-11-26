#requires -version 2
<# 
.SYNOPSIS 
    DNS Debug Log Rotation.
     
.DESCRIPTION
    This Script collects the DNS debug logfile and writes all DNS queries to a daily log file

    !! Need to run on DNS Server
    (can be run daily or more often if log file grows too quick or large)

    - Stops the DNS Server Service
    - Moves Logfile
    - Starts DNS
    - removes unnecessary empty lines from Logfile
    - housekeeping

.NOTES
    Version  : 1.0
    Author   : Tobias Duethorn <tobias@duethorn.cc>
    Created  : 2020-11-26
    Modified : 2020-11-26
#>

$ErrorActionPreference = "SilentlyContinue"
$Now = Get-Date

# this is the source file of the DNS DEBUG log
$DebugLogfile = "C:\Windows\System32\dns\dns.log"
$TargetFolder = $PSScriptRoot

# Number of Days the log files will be kept
$Keep_Days = 14

#------------------------------------------------------------------------------
# 1. Stop DNS Server
Stop-Service DNS

# 2. Move Logfile
Move-Item -Path $DebugLogfile -Destination $TargetFolder -Force

# 3. Start DNS Server
Start-Service DNS

# 4. remove unnecessary lines from log
$LogFile = Join-Path `
    -Path $TargetFolder `
    -ChildPath (Split-Path -Path $DebugLogfile -Leaf)

$TargetFile = Join-Path `
    -Path $TargetFolder `
    -ChildPath ("DNS_{0:yyyy-MM-dd}.log" -f (Get-Date))

# .NET StreamReader + StreamWriter for efficient logfile traversal and output!
$source = [System.IO.StreamReader]::new($LogFile)
$output = [System.IO.StreamWriter]::new($TargetFile, $true)
while ($source.Peek() -gt 0) {
    $line = $source.ReadLine();
    # resolve proper URIs
    $line = $line -replace '\([0-9]{1,2}\)', '.'

    # skip header + empty lines
    if ($line.Length -lt 112) {
        continue;
    }

    $timestamp = $line.Substring(0, 20)
    $ip = $line.Substring(58, 15)
    $query = $line.Substring(104, 6)
    $target = $line.Substring(112)
    $target = $target.Substring(0, $target.Length - 1)

    $output.WriteLine($timestamp + "`t" + $ip + "`t" + $query + "`t" + $target)
}

$source.Close();
$output.Close();

# 5. Cleanup
Remove-Item -Path $LogFile

Get-ChildItem -Path $TargetFolder -Filter "*.log" | ForEach-Object {
    if ($_.LastWriteTime.AddDays($Keep_Days) -lt $Now) {
        Remove-Item $_
    }
}

exit 0