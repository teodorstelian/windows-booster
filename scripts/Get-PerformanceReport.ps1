#requires -Version 5.1
<#
.SYNOPSIS
Shows a read-only snapshot of Windows resource usage and startup entries.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This script requires Windows.' }

$os = Get-CimInstance Win32_OperatingSystem
Write-Output "Windows performance snapshot - $(Get-Date -Format s)"
Write-Output "System: $($os.Caption) ($($os.Version))"
Write-Output "Last boot: $($os.LastBootUpTime)"

Write-Output "`nMemory (GB)"
[pscustomobject]@{
    Total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    Available = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
} | Format-Table -AutoSize

Write-Output 'CPU (sampled load percentage reported by Windows)'
Get-CimInstance Win32_Processor | Select-Object Name, LoadPercentage | Format-Table -AutoSize

Write-Output 'Fixed disks (GB)'
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
    Select-Object DeviceID, @{n='SizeGB';e={[math]::Round($_.Size / 1GB, 2)}},
        @{n='FreeGB';e={[math]::Round($_.FreeSpace / 1GB, 2)}} | Format-Table -AutoSize

Write-Output 'Top 10 processes by working set (physical memory currently mapped)'
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 ProcessName, Id,
    @{n='MemoryMB';e={[math]::Round($_.WorkingSet64 / 1MB, 1)}},
    @{n='CumulativeCPUSeconds';e={$_.CPU}} | Format-Table -AutoSize

Write-Output 'Startup entries (inventory; no changes made)'
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User | Format-List
