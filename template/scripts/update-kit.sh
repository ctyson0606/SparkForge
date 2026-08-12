#!/usr/bin/env bash
# Pull the latest framework content from upstream and overwrite kit/ with it.
#
# Nothing outside kit/ is written. METHOD.md, STATE.md, GOTCHAS.md and every
# section of AGENTS.md — Declarations and Environment facts included — are this
# project's own and are never touched by this script.
#
# For a project that consumes this framework the upstream is SparkForge
# itself, so that is the default. Fork it and set SPARKFORGE_UPSTREAM to point
# somewhere else. The URL is HTTPS rather than SSH: whoever runs this may not
# have an SSH key on the account the repository lives under.
#
# Usage:  scripts/update-kit.sh [<upstream-url-or-path>] [<ref>]
#         SPARKFORGE_UPSTREAM=<url> scripts/update-kit.sh

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPARKFORGE_UPSTREAM="${SPARKFORGE_UPSTREAM:-https://github.com/ctyson0606/SparkForge.git}"
UPSTREAM="${1:-$SPARKFORGE_UPSTREAM}"
REF="${2:-main}"

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

echo "Fetching $UPSTREAM ($REF)"
git clone --quiet --depth 1 --branch "$REF" "$UPSTREAM" "$tmp/upstream"

SRC="$tmp/upstream/template/kit"
if [ ! -d "$SRC" ]; then
  echo "error: $UPSTREAM ($REF) has no template/kit directory." >&2
  exit 1
fi

OLD_VERSION="$(cat "$ROOT/kit/VERSION" 2>/dev/null || echo "unknown")"
NEW_VERSION="$(cat "$SRC/VERSION" 2>/dev/null || echo "unknown")"

rm -rf "$ROOT/kit"
cp -R "$SRC" "$ROOT/kit"

echo "kit/ updated: $OLD_VERSION -> $NEW_VERSION"
echo
echo "Nothing outside kit/ was written."
echo "Run scripts/check.sh: a skill added or removed upstream needs its stub"
echo "adding or removing, and check.sh is what reports that."
