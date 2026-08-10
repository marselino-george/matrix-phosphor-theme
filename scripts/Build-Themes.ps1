[CmdletBinding()]
param(
    [switch]$SkipVisualStudio
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$artifactsRoot = Join-Path $repositoryRoot 'artifacts'
$vsCodeRoot = Join-Path $repositoryRoot 'vscode'
$vsCodePackage = Join-Path $artifactsRoot 'matrix-phosphor-theme-0.1.0.vsix'

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
    & dotnet msbuild $projectPath /restore /p:Configuration=Release /p:Platform=AnyCPU /p:DeployExtension=false
    if ($LASTEXITCODE -ne 0) {
        throw "Visual Studio build failed with exit code $LASTEXITCODE."
    }

    $builtVsix = Join-Path $repositoryRoot 'visual-studio\bin\Release\MatrixPhosphorTheme.vsix'
    if (-not (Test-Path -LiteralPath $builtVsix)) {
        throw "Visual Studio package was not found: $builtVsix"
    }

    $visualStudioPackage = Join-Path $artifactsRoot 'MatrixPhosphorTheme.vsix'
    Copy-Item -LiteralPath $builtVsix -Destination $visualStudioPackage -Force
    Write-Host "Visual Studio package: $visualStudioPackage" -ForegroundColor Green
}
