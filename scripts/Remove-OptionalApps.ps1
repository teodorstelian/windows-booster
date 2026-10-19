#requires -Version 5.1
<#
.SYNOPSIS
Lists optional bundled apps, or uninstalls explicitly selected apps for this user.
.DESCRIPTION
With no arguments, only lists the curated app catalog and installation status.
Use -App Cortana -WhatIf to preview. Removal can delete app data; reinstall
supported apps from Microsoft Store. Retired apps may not be recoverable.
Run in Windows PowerShell 5.1 if the Appx module is unavailable in PowerShell 7.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Cortana', 'Clipchamp', 'Solitaire', 'News', 'Weather', 'GetHelp', 'FeedbackHub', 'GetStarted')]
    [string[]]$App
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This script requires Windows.' }
if (!(Get-Command Get-AppxPackage -ErrorAction SilentlyContinue) -or
    !(Get-Command Remove-AppxPackage -ErrorAction SilentlyContinue)) {
    throw 'Appx commands are unavailable. Run this script in Windows PowerShell 5.1.'
}

# Exact package identities only. Never target the legacy Microsoft.Windows.Cortana
# system package, which is tied to Search on older Windows versions.
$catalog = [ordered]@{
    Cortana = 'Microsoft.549981C3F5F10'
    Clipchamp = 'Clipchamp.Clipchamp'
    Solitaire = 'Microsoft.MicrosoftSolitaireCollection'
    News = 'Microsoft.BingNews'
    Weather = 'Microsoft.BingWeather'
    GetHelp = 'Microsoft.GetHelp'
    FeedbackHub = 'Microsoft.WindowsFeedbackHub'
    GetStarted = 'Microsoft.Getstarted'
}
$targets = if ($App) { @($App | Select-Object -Unique) } else { @($catalog.Keys) }
foreach ($name in $targets) {
    $identity = $catalog[$name]
    $packages = @(Get-AppxPackage -Name $identity -ErrorAction Stop |
        Where-Object { $_.Name -eq $identity })
    if (!$App) {
        [pscustomobject]@{ App = $name; Package = $identity; Installed = ($packages.Count -gt 0) }
        continue
    }
    if (!$packages.Count) {
        [pscustomobject]@{ App = $name; Package = $identity; Status = 'NotInstalled' }
    }
    foreach ($package in $packages) {
        $status = 'Skipped'
        if ($package.NonRemovable -or $package.IsFramework) {
            Write-Warning "Skipping protected package '$($package.PackageFullName)'."
            $status = 'Protected'
        }
        elseif ($PSCmdlet.ShouldProcess($package.PackageFullName, 'Uninstall app for current user (app data may be lost)')) {
            # Let failures terminate and propagate to the caller rather than report success.
            Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop
            $status = 'Removed'
        }
        [pscustomobject]@{ App = $name; Package = $package.PackageFullName; Status = $status }
    }
}
