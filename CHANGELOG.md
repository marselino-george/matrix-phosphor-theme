# Changelog

## 0.3.1 - 2026-08-11

- Added SQL Server Management Studio 22 as an explicit theme-only VSIX target.
- Added dedicated XML classifications for project files and other XML editors in Visual Studio.
- Added Matrix SQL operator, string, system-function, and system-table colors for SSMS.
- Disabled project-based document-tab colorization in the tested Visual Studio setup so tabs use the theme palette.
- Added a full-coverage Notepad++ 8.9.7 XML theme and user-level generator/installer.
- Added public-safe Microsoft Marketplace listing copy.
- Kept the Windows Terminal/PowerShell theme unchanged.

## 0.3.0 - 2026-08-10

- Rebalanced VS Code chrome toward neutral phosphor text so green is an accent instead of a uniform wash.
- Added explicit VS Code markup tiers for tag names, attributes, strings, punctuation, and Markdown headings.
- Removed the cyan cast from Visual Studio parameters and related modern semantic classifications.
- Added Visual Studio classifications missing from the reference package, including parameters, fields, extension methods, records, and string escapes.
- Kept the Windows Terminal/PowerShell theme unchanged.

## 0.2.2 - 2026-08-10

- Tuned the Visual Studio palette for stronger hierarchy instead of uniform neon intensity.
- Reduced chrome and tool-window border saturation while keeping focused controls bright.
- Increased syntax separation between keywords, types, methods, strings, constants, comments, and line numbers.
- Kept the Windows Terminal/PowerShell theme unchanged.

## 0.2.1 - 2026-08-10

- Rebuilt the Visual Studio package from the complete working Midnight Purple 2077 pkgdef coverage model.
- Added the missing `Shell` and `ShellInternal` categories used by the Visual Studio 2026 chrome.
- Restored all missing UI items in existing categories for parity with the working reference.
- Kept the Windows Terminal/PowerShell theme unchanged.

## 0.2.0 - 2026-08-10

- Rebuilt the shared source with complete workbench and token coverage using Midnight Purple 2077 as the coverage guide.
- Changed Visual Studio and VS Code backgrounds and IDE chrome from green-tinted surfaces to black.
- Reduced green saturation in secondary text and UI accents.
- Added dark-green, electric-green, pale-green, and mint-white syntax tiers by token role.
- Preserved the Visual Studio theme GUID during regeneration so installed upgrades replace the same theme.
- Updated the VS Code and Visual Studio preview packages to version 0.2.0.

## 0.1.0 - 2026-08-10

- Added the Matrix Phosphor Windows Terminal fragment for Windows PowerShell and PowerShell 7.
- Added a declarative Visual Studio Code color-theme preview.
- Added a theme-only Visual Studio 2022/2026 VSIX preview.
- Added deterministic build, validation, uninstall, and public-repository privacy checks.
