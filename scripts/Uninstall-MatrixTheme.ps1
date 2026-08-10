[CmdletBinding(SupportsShouldProcess)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fragmentRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\MatrixTheme'
$destinationPath = Join-Path $fragmentRoot 'matrix-theme.json'

if (-not (Test-Path -LiteralPath $destinationPath)) {
    Write-Host 'Matrix Phosphor is not installed.'
    exit 0
}

if ($PSCmdlet.ShouldProcess($destinationPath, 'Remove Matrix Phosphor Windows Terminal fragment')) {
    Remove-Item -LiteralPath $destinationPath -Force

    $remainingItems = @(Get-ChildItem -LiteralPath $fragmentRoot -Force -ErrorAction SilentlyContinue)
    if ($remainingItems.Count -eq 0) {
        Remove-Item -LiteralPath $fragmentRoot -Force
    }

    Write-Host 'Matrix Phosphor removed. Open a new terminal tab to restore the default appearance.'
}
