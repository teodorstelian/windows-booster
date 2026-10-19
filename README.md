# Windows Booster

PowerShell scripts for investigating Windows performance and performing targeted maintenance. Measure first, make one change at a time, and compare results under the same workload. Maintenance may reclaim space; it does not guarantee faster games or applications.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or PowerShell 7+
- Run from a regular PowerShell terminal unless a script explicitly requires administrator access.

## Scripts

Run these commands from the project directory:

```powershell
# Read-only snapshot: memory, CPU, storage, startup entries, and busy processes
.\scripts\Get-PerformanceReport.ps1

# Preview removal of files last modified more than 7 days ago in your temp folder
.\scripts\Clear-UserTemp.ps1 -WhatIf

# Perform cleanup, confirming each file (deletion cannot be undone)
.\scripts\Clear-UserTemp.ps1 -Confirm
```

The report's process CPU values are cumulative CPU seconds since each process started, not current CPU utilization. Startup entries are inventory only; review them in Windows Settings before deciding what to disable. Reports can contain usernames, paths, and application names; review before sharing.

Cleanup only targets the current user's temporary directory. It skips symbolic links/junctions, read-only files, and inaccessible files, and leaves directories intact. Close applications first: age alone cannot prove that a temporary file is unused. Use `-MinimumAgeDays 30` for a more conservative cutoff. Check the preview before deletion. If execution is blocked by your organization's policy, follow that policy rather than bypassing it.

## Optional bundled apps and Cortana

```powershell
# Inventory only; does not remove anything
.\scripts\Remove-OptionalApps.ps1

# Preview removing the standalone Cortana app for your account
.\scripts\Remove-OptionalApps.ps1 -App Cortana -WhatIf

# Remove selected apps, with a confirmation for each installed package
.\scripts\Remove-OptionalApps.ps1 -App Cortana,Solitaire,News
```

Supported names: `Cortana`, `Clipchamp`, `Solitaire`, `News`, `Weather`, `GetHelp`, `FeedbackHub`, and `GetStarted`. These are optional choices, not a recommendation to remove every app. No administrator access is required. Run as the user whose apps you want to remove. If Appx commands are unavailable in PowerShell 7, use Windows PowerShell 5.1.

This uninstalls selected apps for the current user; it does not change other profiles or provisioning for new users. It leaves Windows Search, Store, Edge, Defender, and system services alone. The Cortana target is the standalone app, not the legacy Search-integrated component. An absent app is reported as `NotInstalled`.

Uninstalling can delete local app data. Export anything you need first. To restore a supported app, find it in Microsoft Store and reinstall it; there is no guaranteed automatic rollback. Microsoft has [retired the standalone Cortana app](https://support.microsoft.com/en-us/cortana/end-of-support-for-cortana), so restoring Cortana may be unavailable. Removing an inactive app may free storage without improving performance. Package removal follows Microsoft's [Remove-AppxPackage documentation](https://learn.microsoft.com/en-us/powershell/module/appx/remove-appxpackage).

## Project layout

- `scripts/`: user-facing maintenance and diagnostic scripts
- `docs/`: contribution and safety guidelines
- `tests/`: lightweight validation that does not change Windows settings

## Validation

```powershell
.\tests\Test-Scripts.ps1
```

This checks PowerShell syntax and the cleanup preview against a disposable test folder; it does not run cleanup on your actual temp directory.

## Adding scripts

See [the contribution guidelines](docs/CONTRIBUTING.md). Prefer specific, measurable improvements over blanket "optimization" presets. Scripts must document their effects, privileges, risks, and rollback where applicable. Security features, Windows Update, and services should never be disabled as a generic performance tweak.
