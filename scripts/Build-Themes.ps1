[CmdletBinding()]
param(
    [switch]$SkipVisualStudio
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$artifactsRoot = Join-Path $repositoryRoot 'artifacts'
$vsCodeRoot = Join-Path $repositoryRoot 'vscode'
$vsCodePackage = Join-Path $artifactsRoot 'matrix-phosphor-theme-0.3.0.vsix'

& (Join-Path $PSScriptRoot 'Test-PublicRepository.ps1')
New-Item -ItemType Directory -Path $artifactsRoot -Force | Out-Null

Push-Location $vsCodeRoot
try {
    & npx.cmd --yes '@vscode/vsce@3.9.2' package --out $vsCodePackage
    if ($LASTEXITCODE -ne 0) {
        throw "VS Code packaging failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

Write-Host "VS Code package: $vsCodePackage" -ForegroundColor Green

if (-not $SkipVisualStudio) {
    $projectPath = Join-Path $repositoryRoot 'visual-studio\MatrixPhosphorTheme.csproj'
    & dotnet msbuild $projectPath /restore /t:Rebuild /p:Configuration=Release /p:Platform=AnyCPU /p:DeployExtension=false
    if ($LASTEXITCODE -ne 0) {
        throw "Visual Studio build failed with exit code $LASTEXITCODE."
    }

    $builtVsix = Join-Path $repositoryRoot 'visual-studio\bin\Release\MatrixPhosphorTheme.vsix'
    if (-not (Test-Path -LiteralPath $builtVsix)) {
        throw "Visual Studio package was not found: $builtVsix"
    }

    $visualStudioPackage = Join-Path $artifactsRoot 'MatrixPhosphorTheme.vsix'
    Copy-Item -LiteralPath $builtVsix -Destination $visualStudioPackage -Force

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($visualStudioPackage)
    try {
        $manifestEntry = $archive.GetEntry('extension.vsixmanifest')
        if (-not $manifestEntry) {
            throw 'The Visual Studio package does not contain extension.vsixmanifest.'
        }
        $reader = [System.IO.StreamReader]::new($manifestEntry.Open())
        try {
            [xml]$packagedManifest = $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }

        [xml]$sourceManifest = Get-Content -LiteralPath (Join-Path $repositoryRoot 'visual-studio\source.extension.vsixmanifest') -Raw
        $packagedVersion = [string]$packagedManifest.PackageManifest.Metadata.Identity.Version
        $sourceVersion = [string]$sourceManifest.PackageManifest.Metadata.Identity.Version
        if ($packagedVersion -ne $sourceVersion) {
            throw "Visual Studio package version mismatch: source $sourceVersion, package $packagedVersion."
        }
    }
    finally {
        $archive.Dispose()
    }

    Write-Host "Visual Studio package: $visualStudioPackage" -ForegroundColor Green
}
