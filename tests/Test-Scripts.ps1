#requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $project 'scripts') -Filter '*.ps1') {
    $tokens = $null
    $parseErrors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
    Write-Output "Syntax OK: $($file.Name)"
}

& (Join-Path $PSScriptRoot 'Test-OptionalApps.ps1')

$fixture = Join-Path ([IO.Path]::GetTempPath()) ('windows-booster-test-' + [guid]::NewGuid())
$originalTemp = $env:TEMP
$originalTmp = $env:TMP
try {
    $null = New-Item -ItemType Directory -Path $fixture
    $oldFile = Join-Path $fixture 'old.txt'
    $newFile = Join-Path $fixture 'new.txt'
    Set-Content -LiteralPath $oldFile -Value 'old fixture'
    Set-Content -LiteralPath $newFile -Value 'new fixture'
    (Get-Item -LiteralPath $oldFile).LastWriteTime = (Get-Date).AddDays(-10)
    $env:TEMP = $fixture
    $env:TMP = $fixture
    $result = & (Join-Path $project 'scripts\Clear-UserTemp.ps1') -WhatIf
    if ($result.EligibleFiles -ne 1 -or $result.RemovedFiles -ne 0) { throw 'Preview counts were incorrect.' }
    if (!(Test-Path -LiteralPath $oldFile) -or !(Test-Path -LiteralPath $newFile)) { throw 'Preview changed the fixture.' }
    Write-Output 'Cleanup preview OK: old file selected; both files preserved.'
}
finally {
    $env:TEMP = $originalTemp
    $env:TMP = $originalTmp
    # Only delete the two known fixture files and then the empty fixture directory.
    if (Test-Path -LiteralPath $fixture) {
        foreach ($name in @('old.txt', 'new.txt')) {
            $path = Join-Path $fixture $name
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
        }
        Remove-Item -LiteralPath $fixture
    }
}
