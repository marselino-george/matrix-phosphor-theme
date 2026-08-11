[CmdletBinding()]
param(
    [string]$ReferencePkgdefPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$visualStudioRoot = Join-Path $repositoryRoot 'visual-studio'
$outputPath = Join-Path $visualStudioRoot 'Matrix Phosphor.pkgdef'

if (-not $ReferencePkgdefPath) {
    $ReferencePkgdefPath = Join-Path (Split-Path -Parent $repositoryRoot) 'MidnightPurple2077Theme\Midnight Purple 2077.pkgdef'
}
if (-not (Test-Path -LiteralPath $ReferencePkgdefPath -PathType Leaf)) {
    throw "The full-coverage Visual Studio reference pkgdef was not found: $ReferencePkgdefPath"
}

$stableThemeGuid = 'f56a5588-b9d9-4708-8737-9848a29170ce'
if (Test-Path -LiteralPath $outputPath) {
    $existingHeader = Get-Content -LiteralPath $outputPath -TotalCount 1
    if ($existingHeader -match '\\Themes\\\{(?<guid>[0-9a-fA-F-]{36})\}') {
        $stableThemeGuid = $Matches.guid
    }
}

$paletteMap = @{
    '#000000' = '#000000'
    '#0E0816' = '#000000'
    '#130B1E' = '#000000'
    '#160D24' = '#010201'
    '#1A0F2A' = '#010201'
    '#1D112D' = '#020302'
    '#211335' = '#030503'
    '#24153A' = '#040604'
    '#27153D' = '#050805'
    '#27163C' = '#050805'
    '#2A1841' = '#070A07'
    '#2B1944' = '#070A07'
    '#2E1A47' = '#080C08'
    '#321D50' = '#0A0F0B'
    '#33204F' = '#0A0F0B'
    '#3A2159' = '#0A170D'
    '#4C2C75' = '#0E2A18'
    '#4E2C77' = '#10351D'
    '#5D2F9A' = '#1C5B31'
    '#613795' = '#143A23'
    '#7C41C4' = '#205C34'
    '#8D51D7' = '#45C966'
    '#9F69E8' = '#69ED88'
    '#6272A4' = '#3A5D43'
    '#50FA7B' = '#4DE06C'
    '#8BE9FD' = '#B8D8BE'
    '#BD93F9' = '#D1E8D5'
    '#FF79C6' = '#63FF82'
    '#FFB86C' = '#A5C9AC'
    '#F1FA8C' = '#B7D39A'
    '#999999' = '#626F65'
    '#C5C5C5' = '#AAB7AC'
    '#CCCCCC' = '#B9C5BB'
    '#F4F4F4' = '#D1DAD3'
    '#FCFCFC' = '#EFF7F0'
    '#FFFFFF' = '#EFF7F0'
    '#E8D7FF' = '#DCE9DE'
    '#C2E7FF' = '#B9D7BE'
    '#9B8AB8' = '#819286'
    '#6EE7B7' = '#79CE8B'
    '#C42B1C' = '#C42B1C'
    '#F44747' = '#E06C75'
    '#FF6B8A' = '#E06C75'
    '#FFD166' = '#D6D879'
    '#7A2101' = '#4B3309'
    '#16362C' = '#07170B'
    '#3A1722' = '#180708'
    '#3A2A17' = '#161507'
}

function ConvertTo-MatrixRgb {
    param(
        [byte]$Red,
        [byte]$Green,
        [byte]$Blue,
        [string]$ItemName,
        [string]$Category
    )

    $source = '#{0:X2}{1:X2}{2:X2}' -f $Red, $Green, $Blue
    if ($paletteMap.ContainsKey($source)) {
        $target = $paletteMap[$source]
    }
    else {
        $maximum = [Math]::Max($Red, [Math]::Max($Green, $Blue))
        $minimum = [Math]::Min($Red, [Math]::Min($Green, $Blue))
        $luminance = [int][Math]::Round((0.2126 * $Red) + (0.7152 * $Green) + (0.0722 * $Blue))
        $isNeutral = ($maximum - $minimum) -lt 18
        $isSemanticRed = $Red -gt ($Green * 1.3) -and $Red -gt ($Blue * 1.2) -and $ItemName -match '(?i)close|error|critical|invalid|breakpoint'
        $isSemanticYellow = $Red -gt $Blue -and $Green -gt $Blue -and $ItemName -match '(?i)warning|building|debugging'

        if ($isSemanticRed) {
            $target = '#D65C66'
        }
        elseif ($isSemanticYellow) {
            $target = '#D6D879'
        }
        elseif ($isNeutral) {
            $target = switch ($luminance) {
                { $_ -le 20 } { '#000000'; break }
                { $_ -le 45 } { '#030503'; break }
                { $_ -le 75 } { '#0A0F0B'; break }
                { $_ -le 110 } { '#2B342D'; break }
                { $_ -le 155 } { '#59655C'; break }
                { $_ -le 205 } { '#9CA9A0'; break }
                default { '#EFF7F0' }
            }
        }
        else {
            $target = switch ($luminance) {
                { $_ -le 35 } { '#020402'; break }
                { $_ -le 65 } { '#07110A'; break }
                { $_ -le 95 } { '#0C2112'; break }
                { $_ -le 125 } { '#183B25'; break }
                { $_ -le 160 } { '#315F3F'; break }
                { $_ -le 200 } { '#63A875'; break }
                default { '#A6D7B0' }
            }
        }
    }

    if ($Category -match '^Text Editor') {
        $target = switch -Regex ($ItemName) {
            '(?i)^xml (name|keyword)$' { '#55D975'; break }
            '(?i)^xml attribute$' { '#A5C9AC'; break }
            '(?i)^xml (attribute quotes|delimiter)$' { '#657269'; break }
            '(?i)^xml (attribute value|text|cdata section|entity reference|processing instruction)$' { '#B7D39A'; break }
            '(?i)^xml comment$' { '#3A6245'; break }
            '(?i)^sql system function$' { '#4DE06C'; break }
            '(?i)^sql system table$' { '#D1E8D5'; break }
            '(?i)^sql string$' { '#B7D39A'; break }
            '(?i)^sql operator$' { '#70A97B'; break }
            '(?i)xml doc comment - (name|attribute|delimiter)' { '#5D8F68'; break }
            '(?i)comment' { '#3A6245'; break }
            '(?i)keyword|preprocessor' { '#63FF82'; break }
            '(?i)class name|interface name|struct name|enum name|delegate name|namespace name|type parameter name|type name|record (class|struct) name' { '#D1E8D5'; break }
            '(?i)method name|extension method name|function' { '#4DE06C'; break }
            '(?i)string|character' { '#B7D39A'; break }
            '(?i)line number' { '#4D6D53'; break }
            '(?i)number|literal|constant|enum member name|property name|field name|event name' { '#EFF7F0'; break }
            '(?i)operator|punctuation' { '#6B9975'; break }
            '(?i)parameter|local name|label name' { '#B9C8BB'; break }
            default { $target }
        }
    }
    elseif ($Category -in @('Shell', 'ShellInternal', 'Environment', 'CommonControls')) {
        if ($ItemName -match '(?i)border|stroke|separator|divider' -and $ItemName -notmatch '(?i)focus|selected|active|accent') {
            $target = '#174528'
        }
        elseif ($ItemName -match '(?i)focusvisual|focusborder|selectedborder|activeborder|environmentindicator') {
            $target = '#3BC866'
        }
        elseif ($ItemName -match '(?i)^AccentFill(Default|Alt)$|^EnvironmentLogo$') {
            $target = '#4BD06D'
        }
    }

    return [byte[]]@(
        [Convert]::ToByte($target.Substring(1, 2), 16),
        [Convert]::ToByte($target.Substring(3, 2), 16),
        [Convert]::ToByte($target.Substring(5, 2), 16)
    )
}

function Convert-ThemeData {
    param(
        [string]$HexData,
        [string]$Category
    )

    $bytes = [byte[]]($HexData.Split(',') | ForEach-Object { [Convert]::ToByte($_, 16) })
    if ($bytes.Count -lt 32) {
        throw "Invalid Visual Studio theme data in category: $Category"
    }

    $declaredLength = [BitConverter]::ToUInt32($bytes, 0)
    if ($declaredLength -ne $bytes.Count) {
        throw "Theme data length mismatch in category: $Category"
    }

    $offset = 28
    $itemCount = [BitConverter]::ToUInt32($bytes, $offset)
    $offset += 4
    $itemNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    for ($itemIndex = 0; $itemIndex -lt $itemCount; $itemIndex++) {
        $nameLength = [BitConverter]::ToUInt32($bytes, $offset)
        $offset += 4
        $itemName = [Text.Encoding]::UTF8.GetString($bytes, $offset, $nameLength)
        $offset += $nameLength
        [void]$itemNames.Add($itemName)

        foreach ($colorKind in @('Background', 'Foreground')) {
            $hasColor = $bytes[$offset]
            $offset++
            if ($hasColor -notin @(0, 1)) {
                throw "Invalid $colorKind marker for '$itemName' in category '$Category'."
            }
            if ($hasColor -eq 1) {
                $mapped = ConvertTo-MatrixRgb -Red $bytes[$offset] -Green $bytes[$offset + 1] -Blue $bytes[$offset + 2] -ItemName $itemName -Category $Category
                $bytes[$offset] = $mapped[0]
                $bytes[$offset + 1] = $mapped[1]
                $bytes[$offset + 2] = $mapped[2]
                $offset += 4
            }
        }
    }

    if ($offset -ne $bytes.Count) {
        throw "Theme data parsing did not consume the full category: $Category"
    }

    $additionalClassifications = $null
    if ($Category -eq 'Text Editor MEF Items') {
        $additionalClassifications = [ordered]@{
            'parameter name' = '#B9C8BB'
            'field name' = '#EFF7F0'
            'event name' = '#EFF7F0'
            'extension method name' = '#4DE06C'
            'record class name' = '#D1E8D5'
            'record struct name' = '#D1E8D5'
            'control keyword' = '#63FF82'
            'string escape character' = '#EFF7F0'
        }
    }
    elseif ($Category -eq 'Text Editor Language Service Items') {
        $additionalClassifications = [ordered]@{
            'XML Name' = '#55D975'
            'XML Attribute' = '#A5C9AC'
            'XML Attribute Quotes' = '#657269'
            'XML Attribute Value' = '#B7D39A'
            'XML CData Section' = '#B7D39A'
            'XML Comment' = '#3A6245'
            'XML Delimiter' = '#657269'
            'XML Entity Reference' = '#EFF7F0'
            'XML Keyword' = '#63FF82'
            'XML Processing Instruction' = '#7BE594'
            'XML Text' = '#C5D0C7'
            'SQL Operator' = '#70A97B'
            'SQL String' = '#B7D39A'
            'SQL System Function' = '#4DE06C'
            'SQL System Table' = '#D1E8D5'
        }
    }

    if ($additionalClassifications) {
        $expandedBytes = [System.Collections.Generic.List[byte]]::new()
        $expandedBytes.AddRange($bytes)
        $addedItemCount = 0
        foreach ($classification in $additionalClassifications.GetEnumerator()) {
            if ($itemNames.Contains($classification.Key)) {
                continue
            }

            $nameBytes = [Text.Encoding]::UTF8.GetBytes($classification.Key)
            $expandedBytes.AddRange([BitConverter]::GetBytes([uint32]$nameBytes.Count))
            $expandedBytes.AddRange($nameBytes)
            $expandedBytes.Add(0) # No background override.
            $expandedBytes.Add(1) # Explicit foreground override.
            $expandedBytes.Add([Convert]::ToByte($classification.Value.Substring(1, 2), 16))
            $expandedBytes.Add([Convert]::ToByte($classification.Value.Substring(3, 2), 16))
            $expandedBytes.Add([Convert]::ToByte($classification.Value.Substring(5, 2), 16))
            $expandedBytes.Add(0)
            $addedItemCount++
        }

        if ($addedItemCount -gt 0) {
            $bytes = $expandedBytes.ToArray()
            [BitConverter]::GetBytes([uint32]($itemCount + $addedItemCount)).CopyTo($bytes, 28)
            [BitConverter]::GetBytes([uint32]$bytes.Count).CopyTo($bytes, 0)
        }
    }

    return ($bytes | ForEach-Object { $_.ToString('x2') }) -join ','
}

$referenceLines = Get-Content -LiteralPath $ReferencePkgdefPath
if ($referenceLines.Count -lt 3 -or $referenceLines[0] -notmatch '\\Themes\\\{(?<guid>[0-9a-fA-F-]{36})\}') {
    throw 'The reference pkgdef does not contain a valid Visual Studio theme header.'
}
$referenceThemeGuid = $Matches.guid

$outputLines = [System.Collections.Generic.List[string]]::new()
$currentCategory = $null
$dataCategoryCount = 0
$itemTotal = 0

foreach ($line in $referenceLines) {
    $headerMatch = [regex]::Match($line, '^\[\$RootKey\$\\Themes\\\{[^}]+\}(?:\\(?<category>[^]]+))?\]$')
    if ($headerMatch.Success) {
        $currentCategory = if ($headerMatch.Groups['category'].Success) { $headerMatch.Groups['category'].Value } else { $null }
        $outputLines.Add(($line -replace [regex]::Escape($referenceThemeGuid), $stableThemeGuid))
        continue
    }

    if (-not $currentCategory -and $line -match '^@=') {
        $outputLines.Add('@="Matrix Phosphor"')
        continue
    }
    if (-not $currentCategory -and $line -match '^"Name"=') {
        $outputLines.Add('"Name"="Matrix Phosphor"')
        continue
    }

    $dataMatch = [regex]::Match($line, '^"Data"=hex:(?<hex>.+)$')
    if ($dataMatch.Success) {
        if (-not $currentCategory) {
            throw 'Visual Studio theme data was found without a category header.'
        }
        $convertedHex = Convert-ThemeData -HexData $dataMatch.Groups['hex'].Value -Category $currentCategory
        $convertedBytes = [byte[]]($convertedHex.Split(',') | ForEach-Object { [Convert]::ToByte($_, 16) })
        $itemTotal += [BitConverter]::ToUInt32($convertedBytes, 28)
        $dataCategoryCount++
        $outputLines.Add("`"Data`"=hex:$convertedHex")
        continue
    }

    $outputLines.Add(($line -replace 'Midnight Purple 2077', 'Matrix Phosphor'))
}

if ($dataCategoryCount -lt 61 -or $itemTotal -lt 1450) {
    throw "The reference coverage is incomplete: $dataCategoryCount categories and $itemTotal items."
}

$normalizedContent = ($outputLines -join [Environment]::NewLine).TrimEnd("`r", "`n") + [Environment]::NewLine
Set-Content -LiteralPath $outputPath -Value $normalizedContent -Encoding utf8 -NoNewline

$writtenContent = Get-Content -LiteralPath $outputPath -Raw
if ($writtenContent -match '(?i)Midnight Purple' -or $writtenContent -match [regex]::Escape($referenceThemeGuid)) {
    throw 'Reference identity data leaked into the generated Matrix pkgdef.'
}

Write-Host "Visual Studio theme regenerated with $dataCategoryCount categories and $itemTotal UI items: $outputPath" -ForegroundColor Green
