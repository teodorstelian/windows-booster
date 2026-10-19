#requires -Version 5.1
# Mock Appx commands; never modify installed applications.
& {
    $ErrorActionPreference = 'Stop'
    $removals = New-Object 'System.Collections.Generic.List[string]'
    function Get-AppxPackage {
        param($Name)
        if ($Name -eq 'Microsoft.BingNews') { return }
        [pscustomobject]@{ Name = $Name; PackageFullName = "$($Name)_test"; NonRemovable = ($Name -eq 'Microsoft.GetHelp'); IsFramework = $false }
    }
    function Remove-AppxPackage {
        param($Package)
        $removals.Add($Package)
    }
    $target = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\Remove-OptionalApps.ps1'
    $inventory = @(& $target)
    if ($inventory.Count -ne 8 -or $removals.Count) { throw 'Inventory must be read-only.' }
    $null = & $target -App Cortana -WhatIf
    if ($removals.Count) { throw 'WhatIf called removal.' }
    $absent = & $target -App News -Confirm:$false
    if ($absent.Status -ne 'NotInstalled') { throw 'Missing app status incorrect.' }
    $protected = & $target -App GetHelp -Confirm:$false -WarningAction SilentlyContinue
    if ($protected.Status -ne 'Protected' -or $removals.Count) { throw 'Protected app was not skipped.' }
    $null = & $target -App Cortana,Cortana -Confirm:$false
    if ($removals.Count -ne 1 -or $removals[0] -ne 'Microsoft.549981C3F5F10_test') { throw 'Incorrect removal target or duplicate removal.' }
    $rejected = $false
    try { $null = & $target -App 'Microsoft.WindowsStore' -Confirm:$false }
    catch { $rejected = $true }
    if (!$rejected) { throw 'Unknown app was accepted.' }
    Write-Output 'Optional app tests OK: inventory, preview, exact selection, missing/protected apps, and validation.'
}

