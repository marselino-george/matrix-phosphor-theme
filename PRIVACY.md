# Privacy

Matrix Phosphor is a local, theme-only project.

## Data collection

The theme does not collect, store, or transmit personal information, usage data, diagnostics, or telemetry.

## Network access

The installed themes make no network requests. Build tools may access their normal public package registries when restoring the VS Code packaging tool or Visual Studio SDK packages.

## Local changes

- The Windows Terminal installer copies one JSON fragment into the current user's Windows Terminal fragments directory.
- The Windows Terminal uninstaller removes only that fragment.
- The VS Code package contributes color definitions only and runs no extension-host code.
- The Visual Studio package contains theme resources only and runs no extension code, commands, services, or tool windows.

No personal settings files, shell profiles, source repositories, browser data, credentials, or documents are read by the installed themes.
