#!/usr/bin/env bash
# Prints the next version (without "v") of the macOS app from the Conventional Commits since the latest vX.Y.Z tag, or nothing when no commit calls for a release. Only commits that change app/ count; the website and repo tooling don't version the app.
#
#   BREAKING CHANGE footer or "type!:"  -> major
#   release:                            -> major, on purpose (e.g. 0.x -> 1.0.0)
#   feat:                               -> minor
#   fix: / security:                    -> patch
#   anything else                       -> no release
#
# Only the largest bump applies, once. PRs are rebase-merged, so one PR reaches main in one push and gets at most one version. With no tag yet, counting starts from 0.0.0. "release:" is not a Conventional Commits type; it exists so a major version can be cut without a breaking change.
# https://semver.org/  https://www.conventionalcommits.org/ja/v1.0.0/
set -euo pipefail

# The highest plain vX.Y.Z tag reachable from HEAD; pre-release tags are skipped.
last_tag=$(git tag --merged HEAD --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1 || true)
if [[ -n "$last_tag" ]]; then
    range="$last_tag..HEAD"
    version="${last_tag#v}"
else
    range="HEAD"
    version="0.0.0"
fi
IFS=. read -r major minor patch <<<"$version"

# Kept in variables: bash only reads parentheses in =~ patterns that way.
scope='(\([^)]*\))?'
breaking="^[a-z]+$scope!: "
release="^release$scope: "
feature="^feat$scope: "
fix="^(fix|security)$scope: "

level=0 # 0 none, 1 patch, 2 minor, 3 major
while IFS= read -r -d '' message; do
    subject=${message%%$'\n'*}
    if [[ "$subject" =~ $breaking ]] || [[ "$subject" =~ $release ]] || grep -Eq '^BREAKING[ -]CHANGE: ' <<<"$message"; then
        level=3
    elif [[ "$subject" =~ $feature ]]; then
        if ((level < 2)); then level=2; fi
    elif [[ "$subject" =~ $fix ]]; then
        if ((level < 1)); then level=1; fi
    fi
done < <(git log -z --format=%B "$range" -- ':/app') # -z: NUL between messages, no extra newline; ':/app' is app/ from the repo root, wherever this runs

case $level in
    3) echo "$((major + 1)).0.0" ;;
    2) echo "$major.$((minor + 1)).0" ;;
    1) echo "$major.$minor.$((patch + 1))" ;;
    *) ;;
esac
