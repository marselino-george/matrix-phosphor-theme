[CmdletBinding()]
param(
    [switch]$SkipVisualStudio,

    [string]$VisualStudioPublisher
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$artifactsRoot = Join-Path $repositoryRoot 'artifacts'
$vsCodeRoot = Join-Path $repositoryRoot 'vscode'
$vsCodeManifest = Get-Content -LiteralPath (Join-Path $vsCodeRoot 'package.json') -Raw | ConvertFrom-Json
$vsCodePackage = Join-Path $artifactsRoot ("{0}-{1}.vsix" -f $vsCodeManifest.name, $vsCodeManifest.version)
$vsCodeBaseImagesUrl = 'https://raw.githubusercontent.com/marselino-george/matrix-phosphor-theme/main/vscode'
$marketplacePublisher = $null

if ($PSBoundParameters.ContainsKey('VisualStudioPublisher')) {
    $marketplacePublisher = $VisualStudioPublisher.Trim()
    if ([string]::IsNullOrWhiteSpace($marketplacePublisher)) {
        throw 'VisualStudioPublisher cannot be empty or whitespace.'
    }
    if ($marketplacePublisher.IndexOfAny([char[]]"`r`n`t") -ge 0) {
        throw 'VisualStudioPublisher cannot contain control characters.'
    }
}

& (Join-Path $PSScriptRoot 'Test-PublicRepository.ps1')
New-Item -ItemType Directory -Path $artifactsRoot -Force | Out-Null

Push-Location $vsCodeRoot
try {
    & npx.cmd --yes '@vscode/vsce@3.9.2' package --baseImagesUrl $vsCodeBaseImagesUrl --out $vsCodePackage
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

    $visualStudioPackageName = if ($marketplacePublisher) {
        'MatrixPhosphorTheme-Marketplace.vsix'
    }
    else {
        'MatrixPhosphorTheme.vsix'
    }
    $visualStudioPackage = Join-Path $artifactsRoot $visualStudioPackageName
    Copy-Item -LiteralPath $builtVsix -Destination $visualStudioPackage -Force

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if ($marketplacePublisher) {
        $archive = [System.IO.Compression.ZipFile]::Open(
            $visualStudioPackage,
            [System.IO.Compression.ZipArchiveMode]::Update
        )
        try {
            $manifestEntry = $archive.GetEntry('extension.vsixmanifest')
            if (-not $manifestEntry) {
                throw 'The Visual Studio package does not contain extension.vsixmanifest.'
            }

            $reader = [System.IO.StreamReader]::new($manifestEntry.Open())
            try {
                [xml]$marketplaceManifest = $reader.ReadToEnd()
            }
            finally {
                $reader.Dispose()
            }

            $marketplaceManifest.PackageManifest.Metadata.Identity.SetAttribute(
                'Publisher',
                $marketplacePublisher
            )
            $manifestEntry.Delete()

            $manifestEntry = $archive.CreateEntry(
                'extension.vsixmanifest',
                [System.IO.Compression.CompressionLevel]::Optimal
            )
            $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
            $writer = [System.IO.StreamWriter]::new($manifestEntry.Open(), $utf8WithoutBom)
            try {
                $marketplaceManifest.Save($writer)
            }
            finally {
                $writer.Dispose()
            }
        }
        finally {
            $archive.Dispose()
        }

        Write-Host 'Applied the private Marketplace publisher display name to the generated VSIX.' -ForegroundColor Green
    }

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

        $expectedPublisher = if ($marketplacePublisher) {
            $marketplacePublisher
        }
        else {
            [string]$sourceManifest.PackageManifest.Metadata.Identity.Publisher
        }
        $packagedPublisher = [string]$packagedManifest.PackageManifest.Metadata.Identity.Publisher
        if ($packagedPublisher -cne $expectedPublisher) {
            throw 'Visual Studio package publisher metadata does not match the requested publisher.'
        }
    }
    finally {
        $archive.Dispose()
    }

    Write-Host "Visual Studio package: $visualStudioPackage" -ForegroundColor Green
}
