[CmdletBinding()]
param(
    [string]$NotepadPlusPlusDirectory = (Join-Path $env:ProgramFiles 'Notepad++'),
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$baseThemePath = Join-Path $NotepadPlusPlusDirectory 'themes\DarkModeDefault.xml'
if (-not (Test-Path -LiteralPath $baseThemePath -PathType Leaf)) {
    throw "The Notepad++ base theme was not found at '$baseThemePath'."
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $env:APPDATA 'Notepad++\themes\Matrix Phosphor.xml'
}

$palette = @{
    Background       = '000000'
    Surface          = '020402'
    SurfaceSecondary = '07110A'
    Selection        = '0E321A'
    SelectionSoft    = '0A170D'
    Accent           = '4DE06C'
    AccentBright     = '63FF82'
    Border           = '174528'
    Foreground       = 'C5D0C7'
    ForegroundSoft   = 'D1E8D5'
    ForegroundMuted  = '7D8C80'
    Comment          = '3A6245'
    Type             = 'D1E8D5'
    Function         = '4DE06C'
    String           = 'B7D39A'
    Keyword          = '63FF82'
    Number           = 'EFF7F0'
    Property         = 'A5C9AC'
    Operator         = '70A97B'
    Error            = 'E06C75'
    Warning          = 'D6D879'
    Info             = '7BE594'
    LineNumber       = '4D6D53'
}

function Get-SyntaxForeground {
    param(
        [string]$LexerName,
        [string]$StyleName
    )

    $lexer = $LexerName.ToUpperInvariant()
    $name = $StyleName.ToUpperInvariant()

    $ansiColors = @{
        'ANSI COLOR BLACK'          = '000000'
        'ANSI COLOR BLUE'           = '315F3F'
        'ANSI COLOR BRIGHT BLUE'    = '63A875'
        'ANSI COLOR BRIGHT CYAN'    = '7BE594'
        'ANSI COLOR BRIGHT GREEN'   = '63FF82'
        'ANSI COLOR BRIGHT MAGENTA' = 'A5C9AC'
        'ANSI COLOR BRIGHT RED'     = 'E06C75'
        'ANSI COLOR BROWN'          = '8FA86B'
        'ANSI COLOR CYAN'           = '55D975'
        'ANSI COLOR DARK GRAY'      = '59655C'
        'ANSI COLOR GRAY'           = 'AAB7AC'
        'ANSI COLOR GREEN'          = '4DE06C'
        'ANSI COLOR MAGENTA'        = '70A97B'
        'ANSI COLOR RED'            = 'B95962'
        'ANSI COLOR WHITE'          = 'C5D0C7'
        'ANSI COLOR YELLOW'         = 'B7D39A'
    }
    if ($ansiColors.ContainsKey($name)) {
        return $ansiColors[$name]
    }

    if ($lexer -eq 'DIFF') {
        if ($name -match 'ADDED|ADDITION') { return $palette.Accent }
        if ($name -match 'DELETED|DELETION') { return $palette.Error }
        if ($name -match 'CHANGED|CHANGE') { return $palette.Warning }
        if ($name -match 'HEADER|MESSAGE|POSITION|COMMAND') { return $palette.Type }
    }
    if ($name -match 'ERROR|BAD|ILLEGAL|WRONG|UNDEFINED|UNKNOWN|GARBAGE|UNTERMINATED|NOT CLOSED|TOO MANY') {
        return $palette.Error
    }
    if ($lexer -eq 'JSON' -and $name -match 'PROPERTY|\bKEY\b') {
        return $palette.Property
    }
    if ($lexer -eq 'CSS' -and $name -match '\b(CLASS|ID|ATTRIBUTE|PSEUDOCLASS)\b') {
        return $palette.Property
    }
    if ($name -match 'COMMENT|REMARK') {
        return $palette.Comment
    }
    if ($name -match 'ESCAPE|REGEX|REGEXP') {
        return $palette.Number
    }
    if ($name -match 'STRING|CHARACTER|\bCHAR\b|QUOTE|HEREDOC|HERE Q|BACKTICK|VERBATIM|DATE|EMAIL|FILE|GUID|URI|URL|PATH') {
        return $palette.String
    }
    if ($name -match 'NUMBER|NUMERIC|FLOAT|HEXADECIMAL|HEX NUMBER|HEXNUMBER|BINNUMBER|BINARY|OCTAL|BYTECOUNT|CONSTANT|BOOL|BOOLEAN|NULL|ATOM|LITERAL') {
        return $palette.Number
    }
    if ($name -match 'PARAMETER|ARGUMENT') {
        return $palette.ForegroundSoft
    }
    if ($name -match 'FUNCTION|FUNC|METHOD|CALLABLE|BUILT.?IN|CMDLET|COMMAND|PROCEDURE|SUBROUTINE') {
        return $palette.Function
    }
    if ($name -match '\b(NAMESPACE|CLASS|STRUCT|INTERFACE|TRAIT|ENUM|TYPE|ANNOTATION|DECORATOR|MODULE|PACKAGE|DOMAIN)\b') {
        return $palette.Type
    }
    if ($name -match 'ATTRIBUTE|PROPERTY|FIELD') {
        return $palette.Property
    }
    if ($name -match 'TAG|ELEMENT|HEADING|HEADER|^H[1-6]$|\bKEY\b|KEY NAME|SECTION') {
        return $palette.Function
    }
    if ($name -match 'LABEL|ALIAS') {
        return $palette.Type
    }
    if ($name -match 'KEYWORD|CONTROL|INSTRUCTION|DIRECTIVE|PREPROCESSOR|IMPORT|STORAGE|DECLARATION|STATEMENT|RESERVED|WORD') {
        return $palette.Keyword
    }
    if ($name -match 'OPERATOR|DELIMITER|PUNCTUATION|BRACE|BRACKET|PAREN|SEPARATOR|ASSIGN|SYMBOL') {
        return $palette.Operator
    }
    if ($name -match 'ADDED|ADDITION|INSERTED') { return $palette.Accent }
    if ($name -match 'DELETED|DELETION|REMOVED') { return $palette.Error }
    if ($name -match 'CHANGED|CHANGE|MODIFIED') { return $palette.Warning }
    if ($name -match 'LINK') { return $palette.Info }
    if ($name -match 'CODE|RAW') { return $palette.String }
    if ($name -match 'EMPHASIS|ITALIC') { return $palette.Property }
    if ($name -match 'BOLD') { return $palette.Type }

    return $palette.Foreground
}

function Get-SyntaxFontStyle {
    param([string]$StyleName)

    $name = $StyleName.ToUpperInvariant()
    if ($name -match 'COMMENT|REMARK') { return '3' }
    if ($name -match 'BOLD|^H[1-6]$') { return '1' }
    if ($name -match 'ITALIC|EMPHASIS|^EM1|PARAMETER') { return '2' }
    if ($name -match 'UNDERLINE|LINK|URL') { return '5' }
    return '1'
}

$document = [System.Xml.XmlDocument]::new()
$document.PreserveWhitespace = $false
$document.Load($baseThemePath)

$oldComments = @($document.ChildNodes | Where-Object NodeType -eq 'Comment')
foreach ($comment in $oldComments) {
    [void]$document.RemoveChild($comment)
}
$themeComment = $document.CreateComment(@'
 Matrix Phosphor for Notepad++.
 Generated from the installed DarkModeDefault.xml so lexer coverage matches the installed Notepad++ version.
 The generated file remains subject to the licensing terms of the Notepad++ base theme.
'@)
[void]$document.InsertAfter($themeComment, $document.FirstChild)

foreach ($lexer in @($document.NotepadPlus.LexerStyles.LexerType)) {
    foreach ($style in @($lexer.WordsStyle)) {
        if ($style.name -match '(?i)^EMAIL\s*\{') {
            $style.SetAttribute('name', 'EMAIL')
        }
        $style.SetAttribute('bgColor', $palette.Background)
        if ($lexer.name -eq 'searchResult' -and $style.name -eq 'Current line background colour') {
            $style.SetAttribute('bgColor', $palette.Surface)
            continue
        }
        $style.SetAttribute('fgColor', (Get-SyntaxForeground -LexerName $lexer.name -StyleName $style.name))
        $style.SetAttribute('fontStyle', (Get-SyntaxFontStyle -StyleName $style.name))
    }
}

$globalStyles = @{
    'Default Style'                        = @{ fg = $palette.Foreground;      bg = $palette.Background;       font = 'Cascadia Mono'; style = '1'; size = '12' }
    'Indent guideline style'               = @{ fg = $palette.SelectionSoft;  bg = $palette.Background }
    'Brace highlight style'                = @{ fg = $palette.ForegroundSoft; bg = $palette.Border;           style = '1' }
    'Bad brace colour'                     = @{ fg = $palette.Error;          bg = $palette.Background }
    'Current line background colour'       = @{ bg = $palette.Surface }
    'Selected text colour'                 = @{ fg = $palette.ForegroundSoft; bg = $palette.Selection }
    'Multi-selected text color'            = @{ fg = $palette.ForegroundSoft; bg = $palette.Border }
    'Caret colour'                         = @{ fg = $palette.AccentBright }
    'Multi-edit carets color'              = @{ fg = $palette.Info }
    'Edge colour'                          = @{ fg = $palette.Border }
    'Line number margin'                   = @{ fg = $palette.LineNumber;     bg = $palette.Background }
    'Bookmark margin'                      = @{ bg = $palette.Background }
    'Change History margin'                = @{ bg = $palette.Background }
    'Change History modified'              = @{ fg = $palette.Warning;        bg = $palette.Warning }
    'Change History revert modified'       = @{ fg = $palette.Property;       bg = $palette.Property }
    'Change History revert origin'         = @{ fg = $palette.Info;           bg = $palette.Info }
    'Change History saved'                 = @{ fg = $palette.Accent;         bg = $palette.Accent }
    'Fold'                                 = @{ fg = $palette.SelectionSoft;  bg = $palette.Background }
    'Fold active'                          = @{ fg = $palette.Accent }
    'Fold margin'                          = @{ fg = $palette.Surface;        bg = $palette.Background }
    'White space symbol'                   = @{ fg = $palette.Border }
    'Smart Highlighting'                   = @{ bg = $palette.SelectionSoft }
    'Find Mark Style'                      = @{ bg = $palette.Border }
    'Find status: Not found'               = @{ fg = $palette.Error }
    'Find status: Message'                 = @{ fg = $palette.Info }
    'Find status: Search end reached'      = @{ fg = $palette.Accent }
    'Mark Style 1'                         = @{ bg = '0A170D' }
    'Mark Style 2'                         = @{ bg = '0E2A18' }
    'Mark Style 3'                         = @{ bg = '12301C' }
    'Mark Style 4'                         = @{ bg = '184329' }
    'Mark Style 5'                         = @{ bg = '1A5530' }
    'Incremental highlight all'            = @{ bg = $palette.Selection }
    'Tags match highlighting'              = @{ bg = $palette.Border }
    'Tags attribute'                       = @{ bg = $palette.SelectionSoft }
    'Active tab focused indicator'         = @{ fg = $palette.Accent }
    'Active tab unfocused indicator'       = @{ fg = $palette.Border }
    'Active tab text'                      = @{ fg = $palette.ForegroundSoft }
    'Inactive tabs'                        = @{ fg = $palette.ForegroundMuted; bg = $palette.SurfaceSecondary }
    'Tab color 1'                          = @{ bg = '0A170D' }
    'Tab color 2'                          = @{ bg = '0E2A18' }
    'Tab color 3'                          = @{ bg = '12301C' }
    'Tab color 4'                          = @{ bg = '184329' }
    'Tab color 5'                          = @{ bg = '1A5530' }
    'Tab color dark mode 1'                = @{ bg = '0A170D' }
    'Tab color dark mode 2'                = @{ bg = '0E2A18' }
    'Tab color dark mode 3'                = @{ bg = '12301C' }
    'Tab color dark mode 4'                = @{ bg = '184329' }
    'Tab color dark mode 5'                = @{ bg = '1A5530' }
    'URL hovered'                          = @{ fg = $palette.Info }
    'Document map'                         = @{ fg = $palette.Foreground;      bg = $palette.Background }
    'EOL custom color'                     = @{ fg = $palette.Border }
    'Non-printing characters custom color' = @{ fg = $palette.Border }
    'Global override'                      = @{ fg = $palette.Foreground;      bg = $palette.Background;       font = 'Cascadia Mono'; style = '1'; size = '12' }
}

foreach ($style in @($document.NotepadPlus.GlobalStyles.WidgetStyle)) {
    if ($style.HasAttribute('fgColor')) { $style.SetAttribute('fgColor', $palette.ForegroundMuted) }
    if ($style.HasAttribute('bgColor')) { $style.SetAttribute('bgColor', $palette.Background) }
    if (-not $globalStyles.ContainsKey($style.name)) {
        continue
    }

    $values = $globalStyles[$style.name]
    if ($values.ContainsKey('fg')) { $style.SetAttribute('fgColor', $values.fg) }
    if ($values.ContainsKey('bg')) { $style.SetAttribute('bgColor', $values.bg) }
    if ($values.ContainsKey('font')) { $style.SetAttribute('fontName', $values.font) }
    if ($values.ContainsKey('style')) { $style.SetAttribute('fontStyle', $values.style) }
    if ($values.ContainsKey('size')) { $style.SetAttribute('fontSize', $values.size) }
}

$lexerCount = @($document.NotepadPlus.LexerStyles.LexerType).Count
$styleCount = @($document.NotepadPlus.LexerStyles.LexerType.WordsStyle).Count
if ($lexerCount -lt 90 -or $styleCount -lt 1500) {
    throw "The Notepad++ base theme coverage is incomplete: $lexerCount lexers and $styleCount syntax styles."
}

$invalidColors = @($document.SelectNodes('//*[@fgColor or @bgColor]') | ForEach-Object {
    foreach ($attributeName in @('fgColor', 'bgColor')) {
        if ($_.HasAttribute($attributeName) -and $_.GetAttribute($attributeName) -notmatch '^[0-9A-Fa-f]{6}$') {
            "$($_.Name).$attributeName=$($_.GetAttribute($attributeName))"
        }
    }
})
if ($invalidColors.Count -gt 0) {
    throw "The generated Notepad++ theme contains invalid colors: $($invalidColors -join ', ')"
}

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $outputDirectory)
}

$settings = [System.Xml.XmlWriterSettings]::new()
$settings.Encoding = [System.Text.UTF8Encoding]::new($false)
$settings.Indent = $true
$settings.IndentChars = '    '
$settings.NewLineChars = "`r`n"
$settings.NewLineHandling = [System.Xml.NewLineHandling]::Replace

$writer = [System.Xml.XmlWriter]::Create($resolvedOutputPath, $settings)
try {
    $document.Save($writer)
}
finally {
    $writer.Dispose()
}

Write-Host "Generated Matrix Phosphor for Notepad++: $resolvedOutputPath" -ForegroundColor Green
Write-Host "Lexer coverage: $lexerCount lexers, $styleCount syntax styles" -ForegroundColor Green
