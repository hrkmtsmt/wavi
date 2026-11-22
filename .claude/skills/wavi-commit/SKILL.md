---
name: wavi-commit
description: Writes commit messages and pull request titles for the Wavi repository in Conventional Commits form, choosing the type that makes the release automation bump the right version. Use this whenever you commit in this repo, draft or amend a commit message, split work into commits, title or retitle a pull request, or prepare a pull request for merge — including when the user just says "commit", "コミットして", "push", or "PR を作って" without mentioning the format.
---

# Commits and PR titles in Wavi

Commit messages here are not just history: `.github/workflows/release.yml` runs
`scripts/next-version.sh` on every push to `main`, and the commit *types* decide
whether a release ships and which version it gets. A wrong type either ships a
release nobody needed or silently skips one users were waiting for. So pick the
type by what a user of the app will notice, not by what the diff looks like.

## How a type maps to a release

| Header or footer | Release |
| --- | --- |
| `!` after the type (`feat!:`, `fix!:`) or a `BREAKING CHANGE:` footer | major, even in 0.x |
| `release:` | major, on purpose (e.g. 0.x → 1.0.0) |
| `feat:` | minor |
| `fix:` | patch |
| `security:` | patch |
| `chore:`, `docs:`, `refactor:`, `test:`, `style:`, `perf:`, anything else | no release |

The script only matches lowercase types followed by `: ` (colon, space). `Fix:`,
`fix:no-space`, `feature:` and `break:` are not recognised and release nothing.
For a breaking change use `!` and a `BREAKING CHANGE:` footer, not `break:`.

Pull requests are rebase-merged, so every commit in a PR lands on `main` in
one push, and the script applies only the largest bump among them, once. A PR
with three `fix:` commits and one `feat:` ships one minor release.

`release:` is this repo's own type, not part of Conventional Commits. Use it
only when the user decides to cut a major version without a breaking change
(typically 0.x → 1.0.0), e.g. `release: mark Wavi as stable`. Never pick it on
your own: a major version is a promise to users.

## Choosing the type

Ask: "Would someone using Wavi notice this?"

- **feat** — something new they can do or see: a new shortcut, setting, panel,
  file type, a new `wv` option.
- **fix** — something that behaved wrongly now behaves as intended, including
  visible tweaks to existing UI (a wrong font size, a misaligned button) and
  speedups users can feel. A user-visible performance fix is `fix`, not `perf`,
  because `perf` does not ship a release.
- **security** — closes a hole: unsafe file handling, the `wv` install path,
  permissions.
- **refactor** — same behaviour, different structure (renames, extracting a
  function, moving folders).
- **chore** — tooling, CI and release workflows, scripts, project.yml, lint
  and format configs. Use `chore:` for CI changes too; this repo doesn't use
  `ci:`.
- **docs / test / style** — README and other docs, tests, formatting only.
  Like `chore`, nothing in the shipped app changes.

When a change mixes kinds (a fix plus an unrelated refactor), prefer separate
commits so each gets the right type. If they truly can't be split, use the type
with the larger release (`feat` > `fix`/`security` > the rest).

Don't add a scope (`feat(editor):`). This repo keeps headers to the bare type;
when the area matters, say it in the header's words instead
(`fix: show the status bar file size at 12pt`).

## Message format

Everything committed to this repo is written in English.

```
<type>[!]: <what changed, imperative, lowercase start, no period>

<why: the state before and the reason for the change; wrap at ~72 chars>

[BREAKING CHANGE: <what breaks and what to do instead>]
Co-Authored-By: <the attribution line the session asks for>
```

- The header says what changed so that the header alone is useful in a release
  note (`--generate-notes` lists them). Keep it under ~72 characters.
- The body says **why**. Don't restate the header or list touched files — the
  diff shows that. If the reason isn't clear from the conversation, ask instead
  of inventing one.
- Leave the body out only when the header already explains itself
  (`docs: fix a typo in the README`).

### Examples

```
fix: show the status bar file size at 12pt like the other items

The size was the only 16pt text in the status bar, so it read as a
heading instead of one of the stats next to it.
```

```
feat: open files read-only with wv --view

Checking a large log from Terminal risked an accidental edit; a flag
makes the read-only mode the help panel already has reachable from wv.
```

```
refactor: rename the source folders to App and Tests

Folder names now describe their role; target and product names stay
Wavi, so nothing shipped changes.
```

```
feat!: store settings under the new defaults domain

Settings were split across two domains after the rename.

BREAKING CHANGE: settings saved by earlier builds are not migrated and
reset to their defaults.
```

## Pull requests

PRs are rebase-merged, so the release script reads each commit in the PR as it
is; the PR title never reaches `main`. That means:

- Every commit in a PR needs a correct type. A commit with no type, or a
  misspelled one, is ignored, and a PR made only of those ships nothing.
- Before opening or updating a PR, check the commits since the base
  (`git log --format=%s origin/main..HEAD`) and fix any that don't follow this
  format (reword them, then force-push the branch, after asking the user).
- Still give the PR a Conventional Commits title naming its largest change
  (any breaking → `!`; else any `feat` → `feat:`; else any `fix`/`security`;
  else a no-release type), so reviewers can see what release it will cause.
