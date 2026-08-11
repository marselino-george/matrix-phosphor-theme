[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$textExtensions = @('.cs', '.csproj', '.json', '.md', '.pkgdef', '.ps1', '.svg', '.txt', '.vsixmanifest', '.xml', '.yml')
$forbiddenExtensions = @('.pfx', '.snk', '.key', '.pem', '.user', '.suo', '.vsix', '.nupkg')
$personalIdentifiers = @(
    [Environment]::UserName,
    (& git config --global user.name 2>$null),
    (& git config --global user.email 2>$null)
) | Where-Object { $_ -and $_.Length -ge 4 } | Sort-Object -Unique

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

    foreach ($personalIdentifier in $personalIdentifiers) {
        if ($content.IndexOf($personalIdentifier, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $failures.Add("local personal identifier found in $relativePath")
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

try {
    $theme = Get-Content -LiteralPath (Join-Path $repositoryRoot 'vscode\themes\Matrix Phosphor.json') -Raw | ConvertFrom-Json
    $workbenchColorCount = @($theme.colors.PSObject.Properties).Count
    $tokenRuleCount = @($theme.tokenColors).Count
    $semanticTokenCount = @($theme.semanticTokenColors.PSObject.Properties).Count
    if ($workbenchColorCount -lt 250) {
        $failures.Add("Insufficient workbench coverage: $workbenchColorCount colors")
    }
    if ($tokenRuleCount -lt 200) {
        $failures.Add("Insufficient syntax coverage: $tokenRuleCount token rules")
    }
    if ($semanticTokenCount -lt 20) {
        $failures.Add("Insufficient semantic-token coverage: $semanticTokenCount entries")
    }

    $expectedThemeColors = [ordered]@{
        'editor.background' = '#000000'
        'activityBar.background' = '#000000'
        'editorGroupHeader.tabsBackground' = '#000000'
        'panel.background' = '#000000'
        'terminal.background' = '#000000'
    }
    foreach ($expectedColor in $expectedThemeColors.GetEnumerator()) {
        if ($theme.colors.($expectedColor.Key) -ne $expectedColor.Value) {
            $failures.Add("Primary surface is not black: $($expectedColor.Key)")
        }
    }

    $requiredSyntaxTones = @('#3A6245', '#4DE06C', '#63FF82', '#D1E8D5', '#EFF7F0')
    $tokenForegrounds = @($theme.tokenColors | ForEach-Object {
        if ($_.settings.PSObject.Properties.Name -contains 'foreground') {
            $_.settings.foreground
        }
    } | Where-Object { $_ } | Sort-Object -Unique)
    foreach ($requiredTone in $requiredSyntaxTones) {
        if ($requiredTone -notin $tokenForegrounds) {
            $failures.Add("Required syntax tone is missing: $requiredTone")
        }
    }
}
catch {
    $failures.Add("Unable to validate theme coverage: $($_.Exception.Message)")
}

$xmlFiles = @(
    'notepadplusplus\Matrix Phosphor.xml',
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

try {
    [xml]$notepadTheme = Get-Content -LiteralPath (Join-Path $repositoryRoot 'notepadplusplus\Matrix Phosphor.xml') -Raw
    $notepadLexers = @($notepadTheme.NotepadPlus.LexerStyles.LexerType)
    $notepadStyles = @($notepadTheme.NotepadPlus.LexerStyles.LexerType.WordsStyle)
    if ($notepadLexers.Count -lt 90) {
        $failures.Add("Insufficient Notepad++ lexer coverage: $($notepadLexers.Count) lexers")
    }
    if ($notepadStyles.Count -lt 1500) {
        $failures.Add("Insufficient Notepad++ syntax coverage: $($notepadStyles.Count) styles")
    }
    $invalidNotepadColors = @($notepadTheme.SelectNodes('//*[@fgColor or @bgColor]') | ForEach-Object {
        foreach ($attributeName in @('fgColor', 'bgColor')) {
            if ($_.HasAttribute($attributeName) -and $_.GetAttribute($attributeName) -notmatch '^[0-9A-Fa-f]{6}$') {
                "$($_.Name).$attributeName"
            }
        }
    })
    if ($invalidNotepadColors.Count -gt 0) {
        $failures.Add("Invalid Notepad++ colors: $($invalidNotepadColors -join ', ')")
    }
    if ($notepadTheme.OuterXml -match '(?i)Midnight Purple') {
        $failures.Add('Reference theme branding leaked into the Notepad++ theme.')
    }
}
catch {
    $failures.Add("Unable to validate the Notepad++ theme: $($_.Exception.Message)")
}

$pkgdefPath = Join-Path $repositoryRoot 'visual-studio\Matrix Phosphor.pkgdef'
if (Test-Path -LiteralPath $pkgdefPath) {
    $pkgdefLines = Get-Content -LiteralPath $pkgdefPath
    $themeHeaders = @($pkgdefLines | Where-Object { $_.StartsWith('[$RootKey$\Themes\{') })
    $themeCategoryCount = $themeHeaders.Count
    if ($themeCategoryCount -lt 62) {
        $failures.Add("Insufficient Visual Studio theme coverage: $themeCategoryCount categories")
    }
    foreach ($requiredCategory in @('Shell', 'ShellInternal')) {
        if (-not ($themeHeaders | Where-Object { $_.EndsWith("\$requiredCategory]") })) {
            $failures.Add("Missing Visual Studio theme category: $requiredCategory")
        }
    }

    $visualStudioItemCount = 0
    foreach ($dataLine in $pkgdefLines | Where-Object { $_.StartsWith('"Data"=hex:') }) {
        $hex = $dataLine.Substring(11)
        $bytes = [byte[]]($hex.Split(',') | ForEach-Object { [Convert]::ToByte($_, 16) })
        if ($bytes.Count -ge 32) {
            $visualStudioItemCount += [BitConverter]::ToUInt32($bytes, 28)
        }
    }
    if ($visualStudioItemCount -lt 1450) {
        $failures.Add("Insufficient Visual Studio UI token coverage: $visualStudioItemCount items")
    }
    foreach ($requiredClassification in @(
        'parameter name',
        'field name',
        'extension method name',
        'XML Name',
        'XML Attribute',
        'XML Attribute Value',
        'XML Delimiter',
        'XML Text',
        'SQL Operator',
        'SQL String',
        'SQL System Function',
        'SQL System Table'
    )) {
        $classificationBytes = [Text.Encoding]::UTF8.GetBytes($requiredClassification)
        $classificationHex = ($classificationBytes | ForEach-Object { $_.ToString('x2') }) -join ','
        if (-not ($pkgdefLines | Where-Object { $_.Contains($classificationHex) })) {
            $failures.Add("Missing Visual Studio semantic classification: $requiredClassification")
        }
    }
    if ($pkgdefLines[0] -ne '[$RootKey$\Themes\{f56a5588-b9d9-4708-8737-9848a29170ce}]') {
        $failures.Add('The stable Visual Studio theme GUID changed.')
    }
}
else {
    $failures.Add('The generated Visual Studio pkgdef is missing.')
}

try {
    [xml]$vsixManifest = Get-Content -LiteralPath (Join-Path $repositoryRoot 'visual-studio\source.extension.vsixmanifest') -Raw
    $ssmsTargets = @($vsixManifest.PackageManifest.Installation.InstallationTarget | Where-Object Id -eq 'Microsoft.VisualStudio.Ssms')
    if ($ssmsTargets.Count -ne 2) {
        $failures.Add("Expected AMD64 and ARM64 SSMS targets, found $($ssmsTargets.Count).")
    }
    elseif (@($ssmsTargets | Where-Object Version -ne '[17.14,)').Count -gt 0) {
        $failures.Add('SSMS targets do not use the expected [17.14,) compatibility range.')
    }
}
catch {
    $failures.Add("Unable to validate SSMS manifest targets: $($_.Exception.Message)")
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
