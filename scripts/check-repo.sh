#!/usr/bin/env bash
# Checks that belong to the SparkForge repository itself and are not shipped.
#
# template/scripts/check.sh is copied into every project that adopts the
# framework, so it may only hold checks that still mean something there. The
# checks below guard a structure that exists only here: a template/ directory
# whose memory files have to stay empty. Shipped inside the template, such a
# check would report a permanent pass in every consuming project.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

fail() { echo "FAIL  $1"; FAILED=1; }
pass() { echo "ok    $1"; }

echo "--- template/scripts/check.sh ---"
if ! bash "$ROOT/template/scripts/check.sh"; then
  echo
  echo "check-repo.sh: the shipped checker failed; repository checks not run"
  exit 1
fi

echo
echo "--- repository-only ---"

# --- the shipped memory files are still empty shells ----------------------
# The template's METHOD.md, STATE.md and GOTCHAS.md are the empty shells a new
# project receives. A rule written into one of them has no symptom: the copy
# still works, it just arrives carrying a rule that belongs to SparkForge's own
# development rather than to the project reading it.
bad=""
for f in METHOD.md STATE.md GOTCHAS.md; do
  hit="$(grep -nE '^### |^> (Evidence|Found|Rationale):' "$ROOT/template/$f" 2>/dev/null | head -1)"
  [ -n "$hit" ] && bad="$bad; $f:$hit"
done
if [ -n "$bad" ]; then fail "template memory files carry content${bad}"
else pass "template memory files are still empty shells"; fi

# --- repository-only scripts are executable in the index ------------------
# The shipped checker holds this rule too, but it can only see inside the
# template. Anything under this repository's own scripts/ is out of its reach
# and would otherwise be covered by nothing.
if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "executable bit: $ROOT is not inside a git work tree, so the index cannot be read"
else
  bad=""
  for f in $(cd "$ROOT" && find scripts -name '*.sh' 2>/dev/null); do
    mode="$(git -C "$ROOT" ls-files -s -- "$f" | awk '{print $1}')"
    case "$mode" in
      100755) ;;
      "")     bad="$bad; $f is not in the index" ;;
      *)      bad="$bad; $f is $mode" ;;
    esac
  done
  if [ -n "$bad" ]; then fail "repository scripts not executable in the index${bad}"
  else pass "every repository .sh is 100755 in the index"; fi
fi

echo
if [ "$FAILED" -eq 0 ]; then echo "check-repo.sh: all checks passed"; else echo "check-repo.sh: FAILED"; fi
exit "$FAILED"
