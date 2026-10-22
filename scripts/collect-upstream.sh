#!/usr/bin/env bash
# List, for every project that uses SparkForge, what it has recorded for
# upstream and whether its kit/ has fallen behind this repository's.
#
# A project records anything that belongs to SparkForge rather than to itself
# under "## Upstream" in its STATE.md. Nothing carries that section here on its
# own: before this script, the only way to find such a note was to read every
# project's memory by hand, and one sat unread for over a month. This does not
# remove the need to run it; it makes running it one command.
#
# A project is any directory holding kit/VERSION, searched for below the given
# directories. Whether its kit/ is current is decided by comparing contents
# with template/kit/, not by kit/VERSION, which nothing obliges anyone to bump.
#
# Usage:  scripts/collect-upstream.sh [<dir> ...]
#         With no argument, searches the directory this repository sits in.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$#" -eq 0 ]; then set -- "$(cd "$ROOT/.." && pwd)"; fi

# Same files, same contents, carriage returns aside. A project's .gitattributes
# checks .ps1 files out with CRLF while this repository's own keeps template/kit
# at LF, so a byte comparison of the two working trees calls every project with
# a .ps1 in kit/ changed, current or not.
kit_same() {
  local a="$1" b="$2" f
  [ "$(cd "$a" && find . -type f | sort)" = "$(cd "$b" && find . -type f | sort)" ] || return 1
  while IFS= read -r f; do
    cmp -s <(tr -d '\r' < "$a/$f") <(tr -d '\r' < "$b/$f") || return 1
  done < <(cd "$a" && find . -type f)
  return 0
}

found=0
while IFS= read -r version; do
  project="$(cd "$(dirname "$version")/.." && pwd)"
  [ "$project" -ef "$ROOT/template" ] && continue
  found=$((found + 1))
  echo "=== $project"

  theirs="$(cat "$project/kit/VERSION" 2>/dev/null)"
  ours="$(cat "$ROOT/template/kit/VERSION" 2>/dev/null)"
  if kit_same "$project/kit" "$ROOT/template/kit"; then
    echo "kit/      current ($ours)"
  else
    echo "kit/      behind or changed: $theirs there, $ours here, and the contents differ"
  fi

  if [ ! -f "$project/STATE.md" ]; then
    echo "Upstream  no STATE.md"
  elif ! grep -q '^## Upstream' "$project/STATE.md"; then
    echo "Upstream  no such section: installed before it existed"
  else
    body="$(awk '/^## Upstream/ {f = 1; next} /^## / {f = 0} f' "$project/STATE.md" \
            | sed '/^[[:space:]]*$/d')"
    if [ -z "$body" ]; then
      echo "Upstream  empty"
    else
      echo "Upstream:"
      printf '%s\n' "$body" | sed 's/^/    /'
    fi
  fi
  echo
done < <(find "$@" -maxdepth 4 -path '*/kit/VERSION' -not -path '*/node_modules/*' 2>/dev/null | sort)

if [ "$found" -eq 0 ]; then
  echo "No project using SparkForge found under: $*"
fi
