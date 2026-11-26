# Wavi

A light text viewer and editor for macOS — for when opening an editor is too much.

- Drop a file or paste text, see its size and line count at a glance, copy it all in one click.
- No line numbers, no syntax highlighting, no previews.
- macOS 26 or later.

Download it from the [latest release](https://github.com/hrkmtsmt/wavi/releases/latest); [app/README.md](app/README.md#install) explains how to open it the first time.

## Repository

| Folder | Contents |
| --- | --- |
| [`app/`](app/) | The macOS app (Swift, SwiftUI and AppKit). Build, checks and releases are in [app/README.md](app/README.md). |
| [`web/`](web/) | The website (Astro and React, static, Japanese and English) at [wavi.hrkmtsmt.dev](https://wavi.hrkmtsmt.dev), served by Cloudflare. See [web/README.md](web/README.md). |
| [`scripts/`](scripts/) | Repo tooling, such as picking the app's next version from commits. |
| [`.github/workflows/`](.github/workflows/) | `app.yml`, `web.yml` and `scripts.yml` run only when their folder changes; `web.yml` deploys the site from `main`, and `release.yml` publishes the app. |

Commits follow [Conventional Commits](https://www.conventionalcommits.org/). Only commits that change `app/` decide the app's version.
