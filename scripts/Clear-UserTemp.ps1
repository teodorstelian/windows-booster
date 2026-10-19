#requires -Version 5.1
<#
.SYNOPSIS
Removes old files from the current user's temporary directory.
.DESCRIPTION
Supports -WhatIf and -Confirm. Deletions are permanent. Links and read-only
files are skipped; directories are retained. Close applications before use.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [ValidateRange(1, 3650)]
    [int]$MinimumAgeDays = 7
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This script requires Windows.' }
$root = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$rootItem = Get-Item -LiteralPath $root -Force
if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw 'The temporary directory is a link. Cleanup has been refused.'
}
if ($root.TrimEnd('\', '/') -eq [IO.Path]::GetPathRoot($root).TrimEnd('\', '/')) {
    throw 'Refusing to clean a drive root.'
}

$cutoff = (Get-Date).AddDays(-$MinimumAgeDays)
$pending = New-Object 'System.Collections.Generic.Stack[string]'
$pending.Push($root)
$removed = 0
$bytes = 0L
$candidates = 0
while ($pending.Count -gt 0) {
    $directory = $pending.Pop()
    try { $items = @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop) }
    catch { Write-Warning "Cannot inspect '$directory': $($_.Exception.Message)"; continue }
    foreach ($item in $items) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
        if ($item.PSIsContainer) { $pending.Push($item.FullName); continue }
        if ($item.LastWriteTime -ge $cutoff -or $item.IsReadOnly) { continue }
        $candidates++
        if ($PSCmdlet.ShouldProcess($item.FullName, 'Permanently delete old temporary file')) {
            try {
                Remove-Item -LiteralPath $item.FullName -ErrorAction Stop
                $removed++
                $bytes += $item.Length
            }
            catch { Write-Warning "Skipped '$($item.FullName)': $($_.Exception.Message)" }
        }
    }
}
[pscustomobject]@{
    TempDirectory = $root
    EligibleFiles = $candidates
    RemovedFiles = $removed
    RemovedMB = [math]::Round($bytes / 1MB, 2)
}
