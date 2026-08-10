[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$textExtensions = @('.cs', '.csproj', '.json', '.md', '.pkgdef', '.ps1', '.svg', '.txt', '.vsixmanifest', '.yml')
$forbiddenExtensions = @('.pfx', '.snk', '.key', '.pem', '.user', '.suo', '.vsix', '.nupkg')
$localAlias = -join @([char]109, [char]106, [char]111, [char]114, [char]103)
$fullNamePattern = ('Marcelino', 'Jorge', 'Romero' -join '\s+')
$alternateNamePattern = ('Marselino', 'Georgios', 'Romero' -join '[-\s]+')

$isGitRepository = (& git -C $repositoryRoot rev-parse --is-inside-work-tree 2>$null) -eq 'true'
if ($isGitRepository) {
    $relativeFiles = @(& git -C $repositoryRoot ls-files --cached --others --exclude-standard)
}
else {
    $relativeFiles = @(Get-ChildItem -LiteralPath $repositoryRoot -Recurse -File |
        Where-Object { $_.FullName -notmatch '[\\/](artifacts|bin|obj|node_modules|\.git)[\\/]' } |
        ForEach-Object { $_.FullName.Substring($repositoryRoot.Length + 1) })
}

$relativeFiles = @($relativeFiles | Sort-Object -Unique)
foreach ($relativePath in $relativeFiles) {
    $fullPath = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath)) {
        continue
    }

    $file = Get-Item -LiteralPath $fullPath
    if ($forbiddenExtensions -contains $file.Extension.ToLowerInvariant()) {
        $failures.Add("Forbidden public artifact: $relativePath")
        continue
    }

    if ($file.Length -gt 2MB) {
        $failures.Add("File exceeds the 2 MB public-source limit: $relativePath")
    }

    if ($textExtensions -notcontains $file.Extension.ToLowerInvariant() -and $file.Name -notin @('.gitignore', '.vscodeignore', 'LICENSE')) {
        continue
    }

    $content = Get-Content -LiteralPath $fullPath -Raw
    $checks = [ordered]@{
        'absolute user-profile path' = '(?i)[A-Z]:[\\/]+Users[\\/]+[^\\/\s]+[\\/]'
        'known local alias' = "(?i)\b$([regex]::Escape($localAlias))\b"
        'full personal name' = "(?i)$fullNamePattern|$alternateNamePattern"
        'email address' = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
        'GitHub token' = '(?i)(gho_|ghp_|github_pat_)[A-Z0-9_]{16,}'
        'AWS access key' = 'AKIA[0-9A-Z]{16}'
        'private key material' = 'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY'
        'password assignment' = '(?i)(password|passwd|pwd)\s*[:=]\s*["''][^"'']+'
        'cloud account key' = '(?i)(AccountKey|SharedAccessSignature)\s*='
    }

    foreach ($check in $checks.GetEnumerator()) {
        if ($content -match $check.Value) {
            $failures.Add("$($check.Key) found in $relativePath")
        }
    }
}

$jsonFiles = @(
    'terminal\matrix-theme.json',
    'vscode\package.json',
    'vscode\themes\Matrix Phosphor.json'
)
foreach ($relativePath in $jsonFiles) {
    $fullPath = Join-Path $repositoryRoot $relativePath
    try {
        Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json | Out-Null
    }
    catch {
        $failures.Add("Invalid JSON in ${relativePath}: $($_.Exception.Message)")
    }
}

$xmlFiles = @(
    'visual-studio\MatrixPhosphorTheme.csproj',
    'visual-studio\source.extension.vsixmanifest'
)
foreach ($relativePath in $xmlFiles) {
    $fullPath = Join-Path $repositoryRoot $relativePath
    try {
        [xml](Get-Content -LiteralPath $fullPath -Raw) | Out-Null
    }
    catch {
        $failures.Add("Invalid XML in ${relativePath}: $($_.Exception.Message)")
    }
}

$parseErrors = @()
Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'scripts') -Filter '*.ps1' | ForEach-Object {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    $parseErrors += $errors
}
foreach ($parseError in $parseErrors) {
    $failures.Add("PowerShell parse error: $($parseError.Message)")
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    throw "Public repository validation failed with $($failures.Count) issue(s)."
}

Write-Host "Public repository validation passed for $($relativeFiles.Count) files." -ForegroundColor Green
