[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$themeSource = Join-Path $repositoryRoot 'vscode\themes\Matrix Phosphor.json'
$visualStudioRoot = Join-Path $repositoryRoot 'visual-studio'
$expectedOutput = Join-Path $visualStudioRoot 'Matrix Phosphor.pkgdef'
$vswherePath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'

if (-not (Test-Path -LiteralPath $vswherePath)) {
    throw 'vswhere.exe was not found. Install Visual Studio with the extension development workload.'
}

$installationPaths = @(& $vswherePath -all -products * -property installationPath)
$converterCandidates = foreach ($installationPath in $installationPaths) {
    $extensionsPath = Join-Path $installationPath 'Common7\IDE\Extensions'
    if (Test-Path -LiteralPath $extensionsPath) {
        Get-ChildItem -LiteralPath $extensionsPath -Recurse -File -Filter 'ThemeConverter.exe' -ErrorAction SilentlyContinue |
            Where-Object { $_.DirectoryName -like '*\Tools' }
    }
}

$converter = $converterCandidates | Select-Object -First 1
if (-not $converter) {
    throw 'ThemeConverter.exe was not found. Install the Microsoft Visual Studio Color Theme Designer extension.'
}

$temporaryBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$converterRuntimeRoot = Join-Path $temporaryBase ("MatrixTheme-ThemeConverter-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $converterRuntimeRoot | Out-Null
Copy-Item -Path (Join-Path $converter.DirectoryName '*') -Destination $converterRuntimeRoot -Recurse -Force
$runtimeConverter = Join-Path $converterRuntimeRoot 'ThemeConverter.exe'

$previousRollForward = $env:DOTNET_ROLL_FORWARD
try {
    $env:DOTNET_ROLL_FORWARD = 'Major'
    Push-Location $converterRuntimeRoot
    try {
        & $runtimeConverter -i $themeSource -o $visualStudioRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Theme Converter exited with code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    $env:DOTNET_ROLL_FORWARD = $previousRollForward
    $resolvedRuntimeRoot = [System.IO.Path]::GetFullPath($converterRuntimeRoot)
    if ($resolvedRuntimeRoot.StartsWith($temporaryBase, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedRuntimeRoot).StartsWith('MatrixTheme-ThemeConverter-', [System.StringComparison]::Ordinal)) {
        Remove-Item -LiteralPath $resolvedRuntimeRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $expectedOutput)) {
    throw "The expected generated theme was not found: $expectedOutput"
}

Write-Host "Visual Studio theme regenerated: $expectedOutput" -ForegroundColor Green
