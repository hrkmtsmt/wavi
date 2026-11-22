# Wavi

A light text viewer and editor for macOS — for when opening an editor is too much.

- Drop a file or paste text, see its size and line count at a glance, copy it all in one click.
- No line numbers, no syntax highlighting, no previews.
- macOS 26 or later.

## Install

1. Download `Wavi.zip` from the [latest release](https://github.com/hrkmtsmt/wavi/releases/latest).
2. Double-click it to unzip, then move `Wavi.app` to `Applications`.

### Opening it the first time

Wavi is not signed with an Apple Developer ID, so macOS blocks it the first
time and says it can't check the app for malicious software. Allow it once:

1. Double-click `Wavi.app`. When macOS says it can't be opened, click **Done**.
2. Open **System Settings → Privacy & Security** and scroll down to **Security**.
3. Next to the message about Wavi, click **Open Anyway**. The button is there
   for about an hour after step 1.
4. Enter your login password, then click **Open Anyway** again.

From then on Wavi opens normally. Right-click → Open no longer works for this
since macOS 15.

If you prefer Terminal, removing the download mark does the same:

```sh
xattr -dr com.apple.quarantine /Applications/Wavi.app
```

Each release also lists `Wavi.zip.sha256`; compare it with
`shasum -a 256 Wavi.zip` to check the download.

## Build

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project Wavi.xcodeproj -scheme Wavi build
```

Run the tests with `xcodebuild -project Wavi.xcodeproj -scheme Wavi test`.

## Checks

CI (`.github/workflows/ci.yml`) runs these on every pull request. Run them
locally before pushing:

```sh
swift format lint --strict --recursive Wavi WaviTests   # layout (.swift-format)
swiftlint lint --strict                                 # code patterns (.swiftlint.yml)
xcodebuild -project Wavi.xcodeproj -scheme Wavi test SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

`swift format format -i --recursive Wavi WaviTests` fixes layout in place.
swift-format ships with Xcode; install SwiftLint with `brew install swiftlint`.

## Release

Push a version tag. `.github/workflows/release.yml` builds the app, zips it
and publishes a GitHub release with the zip attached.

```sh
git tag v1.0.0
git push origin v1.0.0
```

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
