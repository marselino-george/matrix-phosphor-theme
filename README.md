# Matrix Phosphor Theme

![Matrix Phosphor preview](assets/preview.svg)

A monochrome phosphor-green theme inspired by the terminal aesthetic of *The Matrix*. The same palette is available for Windows Terminal/PowerShell, Visual Studio Code, and Visual Studio.

> This is an unofficial fan-made theme and is not affiliated with or endorsed by Warner Bros., Village Roadshow Pictures, or the creators of *The Matrix*.

## Theme characteristics

- Near-black green-tinted backgrounds
- Phosphor-green text with brightness-based syntax separation
- Soft mint highlights instead of pure white
- Heavier, readable terminal typography
- No telemetry, network requests, executable extension code, services, or background tasks

## Preview status

| Product | Status | Distribution |
| --- | --- | --- |
| Windows Terminal / PowerShell | Tested on Windows Terminal 1.24 | User-local JSON fragment |
| Visual Studio Code | Preview | Declarative color-theme VSIX |
| Visual Studio 2022 and 2026 | Preview | Theme-only VSIX |

The VS Code and Visual Studio variants are intentionally marked as previews while their language and tool-window coverage is evaluated in daily use.

## Windows Terminal and PowerShell

Run from PowerShell:

```powershell
.\scripts\Install-MatrixTheme.ps1
```

Close every Windows Terminal window and reopen it. The theme applies to the built-in **Windows PowerShell** and **PowerShell** profiles.

The installer uses the per-user Windows Terminal fragment directory and does not rewrite your personal `settings.json`:

```text
%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\MatrixTheme\matrix-theme.json
```

To remove it:

```powershell
.\scripts\Uninstall-MatrixTheme.ps1
```

## Visual Studio Code preview

Build the extension package:

```powershell
.\scripts\Build-Themes.ps1 -SkipVisualStudio
```

Install the generated package:

```powershell
code --install-extension .\artifacts\matrix-phosphor-theme-0.1.0.vsix
```

Then select **Preferences: Color Theme > Matrix Phosphor**.

The VS Code extension is declarative: it contains a manifest and color definitions, with no JavaScript or executable extension host code.

## Visual Studio preview

Build both packages on a machine with the Visual Studio extension development workload and .NET Framework 4.7.2 targeting pack:

```powershell
.\scripts\Build-Themes.ps1
```

The Visual Studio package is written to:

```text
artifacts\MatrixPhosphorTheme.vsix
```

Open it with the VSIX Installer, restart Visual Studio, and select:

```text
Tools > Theme > Matrix Phosphor
```

The committed `.pkgdef` is generated from the same source palette used by VS Code. Contributors with Microsoft's Theme Converter installed can regenerate it with:

```powershell
.\scripts\Update-VisualStudioTheme.ps1
```

## Validation and privacy

Run all source checks before publishing:

```powershell
.\scripts\Test-PublicRepository.ps1
```

The validation rejects common secret formats, private-key material, user-profile paths, local build artifacts, and known personal identifiers. See [PRIVACY.md](PRIVACY.md) for the exact runtime behavior and data boundary.

## Project layout

```text
terminal/       Windows Terminal color scheme and profile fragment
vscode/         VS Code declarative theme extension
visual-studio/  Visual Studio theme-only VSIX project
scripts/        Install, build, conversion, and public-safety checks
assets/         Repository-safe generated preview artwork
```

## License

MIT. See [LICENSE](LICENSE).
