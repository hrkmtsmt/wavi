#!/usr/bin/env bash
# Runs next-version.sh against throwaway git histories. Each block of commits between tags stands for one rebase-merged pull request.
set -u
NV="$(cd "$(dirname "$0")" && pwd)/next-version.sh"
cd "$(mktemp -d)"
git init -q && git config user.email t@t && git config user.name t
fails=0
# c MESSAGE [DIR]: commits a change under DIR (default app, the macOS app).
c() {
    mkdir -p "${2:-app}" && echo "$RANDOM$RANDOM" >>"${2:-app}/file"
    git add -A && git commit -q -m "$1"
}
check() {
    got=$("$NV")
    if [[ "$got" == "$2" ]]; then echo "ok   $1 -> '$got'"; else echo "FAIL $1 -> got '$got' want '$2'"; fails=1; fi
}
release() { git tag "v$("$NV")"; }

# No tag yet: counting starts from 0.0.0.
c "Add things";                       check "non-conventional only" ""
c "chore: tidy"; c "docs: readme"; c "refactor: x"; c "ci: y"; c "perf: z"
                                      check "no-release types" ""
c "security: patch tls";              check "security" "0.0.1"
c "fix(editor): caret";               check "fix" "0.0.1"
c "feat: drop";                       check "feat outranks fix" "0.1.0"
release                               # v0.1.0
                                      check "nothing since the tag" ""

# One PR with many commits still bumps once, by its largest change.
c "fix: a"; c "fix: b"; c "security: c"
                                      check "PR of fixes -> one patch" "0.1.1"
c "docs: after the fixes";            check "largest change is not the newest commit" "0.1.1"
c "feat: d"; c "feat(ui): e"
                                      check "PR with feats -> one minor" "0.2.0"
release                               # v0.2.0

# Breaking changes are major even before 1.0.0.
c "feat!: f"; c "chore: after"; c $'docs: with body\n\nmore text'
                                      check "type! in 0.x, buried under later commits" "1.0.0"
c "fix: g"; c $'refactor: h\n\nBREAKING CHANGE: drops x'
                                      check "two breaking commits in one PR -> one major" "1.0.0"
release                               # v1.0.0

# release: cuts a major on purpose, without a breaking change.
c "release: mark Wavi as stable";     check "release:" "2.0.0"
release                               # v2.0.0
c "fix: i";                           check "2.0.0 + fix" "2.0.1"
c $'docs: j\n\nBREAKING-CHANGE: hyphen form'
                                      check "BREAKING-CHANGE footer" "3.0.0"
release                               # v3.0.0

c "feature: not a type"; c "Fix: capitalized"; c "fix:no space"; c "break: other prefix"; c "releases: typo"
                                      check "near misses do not count" ""
git tag v3.0.1-beta; c "fix: k";      check "pre-release tag is not the base" "3.0.1"
release                               # v3.0.1

# Only commits that change app/ version the app.
c "feat: a website page" web; c "fix: a website bug" web; c "feat: a release script" scripts
                                      check "web/ and scripts/ only" ""
c "fix: the app" app;                 check "app/ among others" "3.0.2"
echo "$RANDOM" >>web/file; c "feat: one commit changing app/ and web/" app
                                      check "a commit touching app/ and web/ counts" "3.1.0"
cd app && check "runs from a subfolder" "3.1.0" && cd ..
exit $fails
