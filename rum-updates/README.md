# RUM Updates

A Noctalia plugin that monitors and manages RakuOS updates with [`rum`](https://gitlab.com/rakuos/packages/rakuos/rakuos-rum).

## Plugin

| Field | Value |
| --- | --- |
| ID | `etrigan63/rum-updates` |
| Version | `0.1.3` |
| Noctalia plugin API | `3` |
| License | `MIT` |
| Requirements | RakuOS with `rum` 0.1.0 or later; `rakuos-software` is optional |

## Usage

The background service runs `rum check-upgrade --json` at the configured interval and reports available overlay package updates. Base-image and Flatpak updates are handled by RakuOS's full upgrade flow.

Click the widget to open **RakuOS Software Center**. Alternatively, set its click action to **Run updater**, which opens a terminal with `sudo rum system-upgrade`. Review the operation and enter your password in that terminal before upgrades are applied.

### Settings

- **Update check interval**: Polling interval in seconds, from 60 to 86400.
- **Notify**: Show a notification when the available update count increases.
- **Hide when empty**: Hide the widget while no overlay package updates are available.
- **Glyph**: Select the icon shown before the update count.
- **Click action**: Open RakuOS Software Center or run the updater in a terminal.
- **Terminal application**: Set the updater terminal's executable path or name, such as `kgx` or `/usr/bin/kitty`. Leave it blank to use Noctalia's detected terminal.

### Installation

Add the GitHub source and enable the plugin:

```bash
noctalia msg plugins source add rum-updates git https://github.com/etrigan63/rum-updates
noctalia msg plugins enable etrigan63/rum-updates
```

Then add the **RUM Updates** widget to a bar in **Settings → Bar**. For local development, add the repository root as a `path` source instead.
