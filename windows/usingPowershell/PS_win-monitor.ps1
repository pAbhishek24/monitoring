# Date        : 15-09-2017
# Author      : Abhishek Pandey
# Reviewed By :
# Reviewd Date:
# Description : this scipt is a base version, designed to capture the performance metrices
#               1) It will execut monitor-typeperf.ps1 for capturing the metrices (CPU,Memory,Network,Threads)
#               2) Network, Process level and Error logs of system and Application from event trace
#               For Execution of the script:
#                Command : 
#                   Ex:  D:\PerformanceMonitor\script\monitor.ps1 -cT 10 -wT 2 -bID 5 -procName chrome -wspc D:\PerformanceMonitor
#Enhancement (YET TO BE IMPLEMENTED) : Implementaion of monitoring and Debug Mode execution
#           1) Weblogic Monitoring
#           2) Thread Dump Generaiton in debug mode
#           3) memory n Heap dumps in debug mode
#           4) Report Generation - Both normal n Debug mode
########
Param (
[int]$cT,
[int]$wT,
[int]$bID,
[string]$procName,
[string]$wspc
)
# Basic Configuration
Write-Output "+++ Message : Setting-Up environemnt for running monitoring script "
$MYDT=Get-Date -UFormat "%d-%m-%Y"
$env:ct=$cT
$env:wt=$wT
$env:sDIR="$wspc\script"
$env:lDIR="$wspc\logs\$MYDT\$bID"
$env:dDIR="$wspc\data"
$env:WLMONITOR_HOME="$wspc\data"
New-Item -ItemType "directory" -Path $env:lDIR
########## System level monitoring 
Write-Output "+++ Message : Iteration to capture stats :"$env:cT
Write-Output "+++ Message : Wait between the Iterations :"$env:wT
$env:d=Get-Date -UFormat "%Y%m%d%H%M%S"
[int]$dur=$cT*$wT
# Event Logs - Clearing event logs for Applicaiton and System
#Clear-EventLog -LogName "Application", "System"
# 2. Start Collecting all the logs - START TIME
Write-Output "+++ Message : Total duraiton for gathering the statistics : "$dur
# Performance Metrices
Start-Job -ScriptBlock {typeperf -cf $env:dDIR\diskUtilization.txt -si $env:wt -sc $env:ct -f CSV -o $env:lDIR\diskUtilization-$env:d}
Start-Job -ScriptBlock {typeperf -cf $env:dDIR\cacheInfo.txt -si $env:wt -sc $env:ct -f CSV -o $env:lDIR\cache-$env:d}
Start-Job -ScriptBlock {typeperf -cf $env:dDIR\processorInfo.txt -si $env:wt -sc $env:ct -f CSV -o $env:lDIR\processorUtilization-$env:d}
Start-Job -ScriptBlock {typeperf -cf $env:dDIR\memoryInfo.txt -si $env:wt -sc $env:ct -f CSV -o $env:lDIR\memoryUtilization-$env:d}
Start-Job -ScriptBlock {typeperf -cf $env:dDIR\networkInfo.txt -si $env:wt -sc $env:ct -f CSV -o $env:lDIR\networkUtilization-$env:d}
Start-Job -ScriptBlock {typeperf -cf $env:dDIR\threadInfo.txt -si $env:wt -sc $env:ct -f CSV -o $env:lDIR\threads-$env:d}
Start-Job -ScriptBlock {typeperf -cf $env:dDIR\processInfo.txt -si $env:wt -sc $env:ct -f CSV -o $env:lDIR\process-$env:d}
# While Loop --- Or else Iterate above
Do
{
    echo "+++ Message : Duration : " $dur
    $sT=Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"
    # Top 30 Running Process, descended by CPU consumption
    $sT >> $env:lDIR\top-$env:d.log
    ps | sort -desc cpu | select -first 30 >> $env:lDIR\top-$env:d.log
    # Process Informaition 
    $sT >> $env:lDIR\proc-Info-$env:d.log
    Get-Process $procName | Format-Table * >> $env:lDIR\proc-Info-$env:d.log 
    # Network COnnection Information
    $sT >> $env:lDIR\netstat-connection-pid-$env:d.log
    netstat -no >> $env:lDIR\netstat-connection-pid-$env:d.log
    # Protocol utilizaiton
    $sT >> $env:lDIR\perProtocol-stats-$env:d.log
    netstat -s >> $env:lDIR\perProtocol-stats-$env:d.log
    $dur=$dur-$wT
    Start-Sleep -s $wT
} While( $dur -ge 0)
# Getting the event logs for Application and System
Get-EventLog -LogName Application >> $env:lDIR\allApp-EventLog-$env:d.log
Get-EventLog -LogName System  >> $env:lDIR\system-EventLog-$env:d.log
# Parse FIELS for avg, min and max during run
Write-Output "### Exectuion Status: Completed ###"