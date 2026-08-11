[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ReferenceThemePath,

    [string]$OutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'vscode\themes\Matrix Phosphor.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$paletteMap = @{
    '#000000' = '#000000'
    '#130B1E' = '#000000'
    '#1D112D' = '#020302'
    '#231436' = '#040604'
    '#27163C' = '#050805'
    '#282828' = '#060806'
    '#2A2D2E' = '#070A07'
    '#2E1A47' = '#080C08'
    '#2F1A48' = '#090E09'
    '#3A2159' = '#0A120C'
    '#442768' = '#0D1A11'
    '#4E2C77' = '#102418'
    '#583286' = '#14331F'
    '#613795' = '#19452A'
    '#6272A4' = '#526158'
    '#50FA7B' = '#4FE86E'
    '#8BE9FD' = '#B8D8BE'
    '#BD93F9' = '#D1E8D5'
    '#FF79C6' = '#63F184'
    '#FFB86C' = '#AFCB83'
    '#F1FA8C' = '#D7E59B'
    '#F44747' = '#E06C75'
    '#F4F4F4' = '#AAB8AD'
    '#FCFCFC' = '#CCD8CE'
    '#FFFFFF' = '#E5ECE6'
    '#C5C5C5' = '#89958C'
    '#CCCCCC' = '#96A299'
    '#999999' = '#626C64'
    '#C200FB' = '#50E878'
    '#C2E7FF' = '#B9D7BE'
}

function ConvertTo-MatrixColor {
    param([object]$Value)

    if ($Value -isnot [string] -or $Value -notmatch '^#(?<rgb>[0-9a-fA-F]{6})(?<alpha>[0-9a-fA-F]{2})?$') {
        return $Value
    }

    $rgb = $Matches['rgb'].ToUpperInvariant()
    $baseColor = "#$rgb"
    $alpha = if ($Matches.ContainsKey('alpha')) { $Matches['alpha'].ToUpperInvariant() } else { '' }

    if ($paletteMap.ContainsKey($baseColor)) {
        return "$($paletteMap[$baseColor])$alpha"
    }

    $red = [Convert]::ToInt32($rgb.Substring(0, 2), 16)
    $green = [Convert]::ToInt32($rgb.Substring(2, 2), 16)
    $blue = [Convert]::ToInt32($rgb.Substring(4, 2), 16)
    $maximum = [Math]::Max($red, [Math]::Max($green, $blue))
    $minimum = [Math]::Min($red, [Math]::Min($green, $blue))
    $luminance = [int][Math]::Round((0.2126 * $red) + (0.7152 * $green) + (0.0722 * $blue))
    $isNeutral = ($maximum - $minimum) -lt 18

    if ($isNeutral) {
        $mapped = switch ($luminance) {
            { $_ -le 20 } { '#000000'; break }
            { $_ -le 45 } { '#040604'; break }
            { $_ -le 75 } { '#0A0F0B'; break }
            { $_ -le 110 } { '#2B342D'; break }
            { $_ -le 155 } { '#59655C'; break }
            { $_ -le 205 } { '#919E94'; break }
            default { '#CFD8D1' }
        }
    }
    else {
        $mapped = switch ($luminance) {
            { $_ -le 35 } { '#030703'; break }
            { $_ -le 65 } { '#07110A'; break }
            { $_ -le 95 } { '#0C2112'; break }
            { $_ -le 125 } { '#183B25'; break }
            { $_ -le 160 } { '#315F3F'; break }
            { $_ -le 200 } { '#63A875'; break }
            default { '#A6D7B0' }
        }
    }

    return "$mapped$alpha"
}

function Get-MatrixTokenForeground {
    param([object]$Scope)

    $scopeText = if ($Scope -is [array]) { $Scope -join ',' } else { [string]$Scope }
    $scopeText = $scopeText.ToLowerInvariant()

    if ($scopeText -match 'comment') {
        return '#3A6245'
    }
    if ($scopeText -match 'variable\.language|support\.variable\.magic|constant\.|\bnumber\b|\bboolean\b|\bnull\b|enum-member|invalid') {
        return '#EFF7F0'
    }
    if ($scopeText -match 'keyword\.control|keyword\.declaration|storage\.modifier|import\.storage|token\.package\.keyword') {
        return '#63FF82'
    }
    if ($scopeText -match 'storage\.type|entity\.name\.type|entity\.name\.class|support\.class|support\.type|entity\.name\.namespace') {
        return '#D1E8D5'
    }
    if ($scopeText -match 'entity\.name\.function|support\.function|variable\.function|meta\.function-call|meta\.method') {
        return '#4DE06C'
    }
    if ($scopeText -match '\bstring\b|regexp') {
        return '#B7D39A'
    }
    if ($scopeText -match 'keyword\.operator|punctuation\.operator|\boperator\b') {
        return '#70A97B'
    }
    if ($scopeText -match '(^|[,.])keyword($|[,.])|\bkeyword\.') {
        return '#7BE594'
    }
    if ($scopeText -match 'entity\.other\.attribute-name|support\.variable\.property|meta\.object-literal\.key|\bproperty\b') {
        return '#9FC8A8'
    }
    if ($scopeText -match 'variable\.parameter|\bparameter\b') {
        return '#C0CCC2'
    }
    if ($scopeText -match 'punctuation|\bbrace\b|\bbracket') {
        return '#657269'
    }

    return $null
}

$reference = Get-Content -LiteralPath $ReferenceThemePath -Raw | ConvertFrom-Json
if (@($reference.colors.PSObject.Properties).Count -lt 240 -or @($reference.tokenColors).Count -lt 200) {
    throw 'The reference theme does not provide the expected full workbench and token coverage.'
}

$colors = [ordered]@{}
foreach ($property in $reference.colors.PSObject.Properties) {
    $colors[$property.Name] = ConvertTo-MatrixColor $property.Value
}

$criticalOverrides = [ordered]@{
    'foreground' = '#AAB6AC'
    'descriptionForeground' = '#657168'
    'focusBorder' = '#2C7543'
    'contrastBorder' = '#0E321A'
    'activityBar.background' = '#000000'
    'activityBar.foreground' = '#8EAA94'
    'activityBar.inactiveForeground' = '#536057'
    'activityBar.border' = '#07170B'
    'activityBar.activeBorder' = '#50E878'
    'activityBarBadge.background' = '#164126'
    'activityBarBadge.foreground' = '#E1EAE3'
    'sideBar.background' = '#010201'
    'sideBar.foreground' = '#A7B4A9'
    'sideBar.border' = '#07170B'
    'sideBarSectionHeader.background' = '#030503'
    'editorGroupHeader.tabsBackground' = '#000000'
    'editorGroupHeader.noTabsBackground' = '#000000'
    'tab.activeBackground' = '#020302'
    'tab.inactiveBackground' = '#000000'
    'tab.hoverBackground' = '#050A06'
    'tab.border' = '#07170B'
    'tab.activeForeground' = '#DDE7DF'
    'tab.inactiveForeground' = '#77827A'
    'tab.unfocusedActiveForeground' = '#9EA9A1'
    'editor.background' = '#000000'
    'editor.foreground' = '#C5D0C7'
    'editorGutter.background' = '#000000'
    'editor.lineHighlightBackground' = '#020402'
    'editor.lineHighlightBorder' = '#050B06'
    'editor.selectionBackground' = '#0E321A'
    'editor.inactiveSelectionBackground' = '#081C0E'
    'editorCursor.foreground' = '#DDE9DF'
    'panel.background' = '#000000'
    'panel.border' = '#07170B'
    'statusBar.background' = '#020602'
    'statusBar.foreground' = '#A6B2A8'
    'statusBar.border' = '#07170B'
    'statusBar.debuggingBackground' = '#0A1C0E'
    'statusBar.noFolderBackground' = '#010301'
    'titleBar.activeBackground' = '#000000'
    'titleBar.inactiveBackground' = '#000000'
    'titleBar.border' = '#07170B'
    'menu.background' = '#020302'
    'notifications.background' = '#020302'
    'terminal.background' = '#000000'
    'terminal.foreground' = '#78D88C'
    'terminalCursor.background' = '#000000'
    'terminalCursor.foreground' = '#B8EFC3'
    'terminal.selectionBackground' = '#0E321A'
    'terminal.ansiBlack' = '#000000'
    'terminal.ansiBrightBlack' = '#35533D'
    'terminal.ansiRed' = '#367D4C'
    'terminal.ansiBrightRed' = '#55AE70'
    'terminal.ansiGreen' = '#43C967'
    'terminal.ansiBrightGreen' = '#78E894'
    'terminal.ansiYellow' = '#62B779'
    'terminal.ansiBrightYellow' = '#98DFAA'
    'terminal.ansiBlue' = '#2D6941'
    'terminal.ansiBrightBlue' = '#50A96B'
    'terminal.ansiMagenta' = '#39794D'
    'terminal.ansiBrightMagenta' = '#68C483'
    'terminal.ansiCyan' = '#42935B'
    'terminal.ansiBrightCyan' = '#70D68A'
    'terminal.ansiWhite' = '#76AE81'
    'terminal.ansiBrightWhite' = '#B8EFC3'
    'minimap.background' = '#000000'
}
foreach ($entry in $criticalOverrides.GetEnumerator()) {
    $colors[$entry.Key] = $entry.Value
}

$tokenRules = @()
foreach ($rule in $reference.tokenColors) {
    $newRule = [ordered]@{}
    if ($rule.PSObject.Properties.Name -contains 'name') {
        $newRule.name = $rule.name
    }
    if ($rule.PSObject.Properties.Name -contains 'scope') {
        $newRule.scope = $rule.scope
    }

    $settings = [ordered]@{}
    if ($rule.settings) {
        foreach ($setting in $rule.settings.PSObject.Properties) {
            if ($setting.Name -in @('foreground', 'background')) {
                $settings[$setting.Name] = ConvertTo-MatrixColor $setting.Value
            }
            else {
                $settings[$setting.Name] = $setting.Value
            }
        }
    }

    $classifiedForeground = Get-MatrixTokenForeground $rule.scope
    if ($classifiedForeground) {
        $settings.foreground = $classifiedForeground
    }
    $newRule.settings = $settings
    $tokenRules += $newRule
}

# Add a compact set of late, language-neutral rules so markup does not collapse
# into one neon-green tone when a grammar exposes only broad XML/HTML scopes.
$tokenRules += @(
    [ordered]@{
        name = 'Matrix - Markup tag names'
        scope = @('entity.name.tag', 'support.class.component')
        settings = [ordered]@{ foreground = '#55D975' }
    },
    [ordered]@{
        name = 'Matrix - Markup attribute names'
        scope = @('entity.other.attribute-name', 'support.type.property-name')
        settings = [ordered]@{ foreground = '#A5C9AC' }
    },
    [ordered]@{
        name = 'Matrix - Quoted strings'
        scope = @('string.quoted', 'string.unquoted')
        settings = [ordered]@{ foreground = '#B7D39A' }
    },
    [ordered]@{
        name = 'Matrix - Markup delimiters'
        scope = @('punctuation.definition.tag', 'punctuation.definition.string', 'punctuation.separator')
        settings = [ordered]@{ foreground = '#657269' }
    },
    [ordered]@{
        name = 'Matrix - Markdown headings'
        scope = @('entity.name.section.markdown', 'markup.heading.markdown')
        settings = [ordered]@{ foreground = '#D1E8D5'; fontStyle = 'bold' }
    }
)

$semanticTokens = [ordered]@{
    'namespace' = '#C5DDCA'
    'type' = '#D1E8D5'
    'class' = '#D1E8D5'
    'enum' = '#C5DDCA'
    'interface' = '#D1E8D5'
    'struct' = '#D1E8D5'
    'typeParameter' = '#A5C9AC'
    'parameter' = '#C0CCC2'
    'variable' = '#C5D0C7'
    'property' = '#9FC8A8'
    'enumMember' = '#EFF7F0'
    'function' = '#4DE06C'
    'method' = '#4DE06C'
    'macro' = '#63FF82'
    'keyword' = [ordered]@{ foreground = '#63FF82'; bold = $true }
    'comment' = [ordered]@{ foreground = '#3A6245'; italic = $true }
    'string' = '#B7D39A'
    'number' = '#EFF7F0'
    'regexp' = '#B7D39A'
    'operator' = '#70A97B'
    'decorator' = '#7BE594'
    '*.readonly' = '#EFF7F0'
    '*.deprecated' = [ordered]@{ foreground = '#657168'; strikethrough = $true }
}

$theme = [ordered]@{
    '$schema' = 'vscode://schemas/color-theme'
    'type' = 'dark'
    'semanticHighlighting' = $true
    'colors' = $colors
    'tokenColors' = $tokenRules
    'semanticTokenColors' = $semanticTokens
}

$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$theme | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $OutputPath -Encoding utf8

$writtenTheme = Get-Content -LiteralPath $OutputPath -Raw | ConvertFrom-Json
Write-Host "Matrix theme generated with $(@($writtenTheme.colors.PSObject.Properties).Count) workbench colors and $(@($writtenTheme.tokenColors).Count) token rules." -ForegroundColor Green
