# Wavi

A light text viewer and editor for macOS — for when opening an editor is too much.

- Drop a file or paste text, see its size and line count at a glance, copy it all in one click.
- No line numbers, no syntax highlighting, no previews.
- macOS 26 or later.

## Build

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project Wavi.xcodeproj -scheme Wavi build
```

Run the tests with `xcodebuild -project Wavi.xcodeproj -scheme Wavi test`.

## The `wv` command

Open the help panel (`?`) and press "Install the wv command". It links
`/usr/local/bin/wv` to the script inside the app. Then:

```sh
wv ./file.txt
```

## Layout

| Folder | Contents |
| --- | --- |
| `Wavi/Tokens` | Design tokens (spacing, radii, colors, glass levels, type) |
| `Wavi/Components` | Generic components: GlassSurface, RoundButton, PillButton, Chip, PillGroup, Tab, Switch, KeyRow, InfoItem, Panel, Overlay |
| `Wavi/Features` | TabBar, StatusBar, HelpPanel, SettingsPanel, DropOverlay, Editor |
| `Wavi/Window` | DocumentWindow, the only window |
| `Wavi/Model` | Documents, encoding detection, settings, UI strings |
| `Wavi/Services` | `wv` installation and default-app settings |

## Fonts

JetBrains Mono and Gen Jyuu Gothic Monospace are bundled under the SIL Open Font
License 1.1. The license texts ship in `Wavi/Resources/Licenses`.
