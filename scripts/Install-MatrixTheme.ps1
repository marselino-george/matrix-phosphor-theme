[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'terminal\matrix-theme.json'
$fragmentRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\MatrixTheme'
$destinationPath = Join-Path $fragmentRoot 'matrix-theme.json'
$backupRoot = Join-Path $env:LOCALAPPDATA 'MatrixTheme\Backups'

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Theme fragment not found: $sourcePath"
}

$fragment = Get-Content -LiteralPath $sourcePath -Raw | ConvertFrom-Json
if (-not $fragment.schemes -or $fragment.schemes[0].name -ne 'Matrix Phosphor') {
    throw 'The theme fragment is valid JSON, but the Matrix Phosphor scheme is missing.'
}

$terminalPackage = Get-AppxPackage -Name Microsoft.WindowsTerminal -ErrorAction SilentlyContinue
if (-not $terminalPackage -and -not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    throw 'Windows Terminal was not found. Install it first, then run this script again.'
}

New-Item -ItemType Directory -Path $fragmentRoot -Force | Out-Null

if (Test-Path -LiteralPath $destinationPath) {
    $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    $destinationHash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash

    if ($sourceHash -eq $destinationHash) {
        Write-Host 'Matrix Phosphor is already installed.' -ForegroundColor Green
        Write-Host "Fragment: $destinationPath"
        Write-Host 'Close all Windows Terminal windows and reopen one to guarantee that the fragment is reloaded.'
        exit 0
    }

    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = Join-Path $backupRoot "matrix-theme-$timestamp.json"
    Copy-Item -LiteralPath $destinationPath -Destination $backupPath
    Write-Host "Previous fragment backed up to: $backupPath"
}

Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force

$installed = Get-Content -LiteralPath $destinationPath -Raw | ConvertFrom-Json
if ($installed.schemes[0].name -ne 'Matrix Phosphor') {
    throw 'The installed fragment could not be verified.'
}

$installedHash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash
Write-Host 'Matrix Phosphor installed successfully.' -ForegroundColor Green
Write-Host "Fragment: $destinationPath"
Write-Host "SHA-256:  $installedHash"
Write-Host 'Close all Windows Terminal windows and reopen one to guarantee that the fragment is reloaded.'
