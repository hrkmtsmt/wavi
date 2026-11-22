---
name: wavi-commit
description: Writes commit messages and pull request titles for the Wavi repository in Conventional Commits form, choosing the type that makes the release automation bump the right version. Use this whenever you commit in this repo, draft or amend a commit message, split work into commits, title or retitle a pull request, or prepare a pull request for merge — including when the user just says "commit", "コミットして", "push", or "PR を作って" without mentioning the format.
---

# Commits in Wavi

Follow [Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/). The types decide releases: `scripts/next-version.sh` reads them on every push to `main`, so a wrong type ships a release nobody needed or skips one users were waiting for. These rules are specific to this repo:

- Only commits that change `app/` (the macOS app) version it. A `feat:` or `fix:` that touches only `web/` or `scripts/` releases nothing, so keep app changes and website changes in separate commits; the types still describe what changed for that part.
- `security:` is a type here and bumps patch, like `fix:`.
- `release:` is a type here and bumps major on purpose (e.g. 0.x → 1.0.0). Use it only when the user decides to; never pick it yourself.
- Breaking changes (`!` or a `BREAKING CHANGE:` footer) bump major even in 0.x. Don't use `break:`; it isn't recognised.
- Every other type ships nothing. Use `chore:` for CI and release workflows, scripts and configs; don't use `ci:` or `build:`.
- Pick the type by what someone using the app would notice. A speedup users can feel is `fix:`, not `perf:`, because `perf:` doesn't ship.
- No scopes (`feat(editor):`). If the area matters, say it in the header (`fix: show the status bar file size at 12pt`).
- Write in English. The body says why, not what the diff already shows; if the reason isn't clear from the conversation, ask.
- Don't hard-wrap the body or footers: one line per paragraph or list item.
- PRs are rebase-merged, so every commit in a PR reaches `main` and only the largest bump among them applies, once. Before opening or updating a PR, check `git log --format=%s origin/main..HEAD` and reword any commit without a correct type (force-push only after asking the user). Still title the PR with its largest change.
