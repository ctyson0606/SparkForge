#!/usr/bin/env bash
# Structural checks for a SparkForge tree. Every failure is reported; the
# script exits 1 if any check failed.
#
# ROOT is the directory this script's parent lives in: the SparkForge template
# inside this repo, or the project root inside a project that consumes it.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

# Directories that hold per-tool stubs pointing into kit/. One entry per tool
# whose skill directory has been established. Adding a tool means adding its
# directory here and generating its stubs.
STUB_ROOTS=(".claude")

fail() { echo "FAIL  $1"; FAILED=1; }
pass() { echo "ok    $1"; }

# --- required files -------------------------------------------------------
REQUIRED=(
  AGENTS.md CLAUDE.md METHOD.md STATE.md GOTCHAS.md
  .gitattributes kit/VERSION
  scripts/check.sh scripts/update-kit.sh
)
missing=""
for f in "${REQUIRED[@]}"; do
  [ -f "$ROOT/$f" ] || missing="$missing $f"
done
if [ -n "$missing" ]; then fail "required files missing:$missing"
else pass "required files present"; fi

# --- every canonical skill has a stub under every stub root ---------------
for sr in "${STUB_ROOTS[@]}"; do
  missing=""
  for f in "$ROOT"/kit/skills/*.md; do
    [ -e "$f" ] || continue
    n="$(basename "$f" .md)"
    [ -f "$ROOT/$sr/skills/$n/SKILL.md" ] || missing="$missing $n"
  done
  if [ -n "$missing" ]; then fail "$sr/skills: stubs missing for:$missing"
  else pass "$sr/skills: a stub for every skill"; fi

  missing=""
  for f in "$ROOT"/kit/agents/*.md; do
    [ -e "$f" ] || continue
    n="$(basename "$f" .md)"
    [ -f "$ROOT/$sr/agents/$n.md" ] || missing="$missing $n"
  done
  if [ -n "$missing" ]; then fail "$sr/agents: stubs missing for:$missing"
  else pass "$sr/agents: a stub for every agent"; fi
done

# --- no stub pointing at a canonical file that does not exist -------------
dangling=""
for sr in "${STUB_ROOTS[@]}"; do
  for s in "$ROOT/$sr"/skills/*/SKILL.md; do
    [ -e "$s" ] || continue
    n="$(basename "$(dirname "$s")")"
    [ -f "$ROOT/kit/skills/$n.md" ] || dangling="$dangling $sr/skills/$n"
  done
  for s in "$ROOT/$sr"/agents/*.md; do
    [ -e "$s" ] || continue
    n="$(basename "$s" .md)"
    [ -f "$ROOT/kit/agents/$n.md" ] || dangling="$dangling $sr/agents/$n"
  done
done
if [ -n "$dangling" ]; then fail "dangling stubs (no canonical file):$dangling"
else pass "no dangling stubs"; fi

# --- agent stubs mirror the canonical tools: line -------------------------
# A tool restriction has to live where the tool reads it, so it exists twice.
# This is the check that keeps the second copy from becoming a comment.
drift=""
for sr in "${STUB_ROOTS[@]}"; do
  for f in "$ROOT"/kit/agents/*.md; do
    [ -e "$f" ] || continue
    n="$(basename "$f" .md)"
    stub="$ROOT/$sr/agents/$n.md"
    [ -f "$stub" ] || continue
    a="$(grep '^tools:' "$f" || true)"
    b="$(grep '^tools:' "$stub" || true)"
    [ "$a" = "$b" ] || drift="$drift; $sr/agents/$n.md has [$b], kit has [$a]"
  done
done
if [ -n "$drift" ]; then fail "agent tools drifted${drift}"
else pass "agent stubs mirror the canonical tools line"; fi

# --- every skill named in the AGENTS.md routing block exists --------------
routed="$(awk '/^## Skill routing/{p=1;next} /^## /{p=0} p' "$ROOT/AGENTS.md" \
          | sed -n 's/^\([a-z0-9-]*\) — .*/\1/p')"
missing=""
for n in $routed; do
  [ -f "$ROOT/kit/skills/$n.md" ] || missing="$missing $n"
done
if [ -n "$missing" ]; then fail "AGENTS.md routes skills that do not exist:$missing"
else pass "AGENTS.md routing resolves ($(echo $routed | wc -w) entries)"; fi

# --- every file path mentioned anywhere in AGENTS.md exists ---------------
# Forward references such as scripts/update-kit.sh are caught here rather than
# relying on anyone remembering to keep a renamed file in step.
paths="$(grep -oE '[A-Za-z0-9_./-]+\.(md|sh|json|ya?ml|txt)' "$ROOT/AGENTS.md" | sort -u)"
missing=""
for p in $paths; do
  [ -e "$ROOT/$p" ] || missing="$missing $p"
done
if [ -n "$missing" ]; then fail "AGENTS.md names paths that do not exist:$missing"
else pass "AGENTS.md path references resolve ($(echo $paths | wc -w) paths)"; fi

# --- no .sh carries CRLF --------------------------------------------------
crlf="$(find "$ROOT" -name '*.sh' -exec grep -lU "$(printf '\r')" {} + 2>/dev/null)"
if [ -n "$crlf" ]; then fail "CRLF in shell scripts: $crlf"
else pass "no CRLF in any .sh"; fi

# --- tier tag grammar -----------------------------------------------------
bad="$(grep -rhoE '`\[T[^]]*\]`' "$ROOT/kit/skills" 2>/dev/null \
       | grep -vE '^`\[T[0-2]( \| T[0-2] if: [^]]+)*\]`$')"
if [ -n "$bad" ]; then fail "tier tags outside the grammar: $bad"
else pass "tier tags conform ($(grep -rhoE '`\[T[^]]*\]`' "$ROOT/kit/skills" 2>/dev/null | wc -l) tags)"; fi

# --- exactly one evidence label per rule ----------------------------------
# Anchored on the ### heading: a block with no heading is not a rule and is
# not subject to this check.
viol="$(for f in "$ROOT"/kit/skills/*.md; do
  [ -e "$f" ] || continue
  awk -v F="$(basename "$f")" '
    /^### / { inb=1; h=$0; n=0; next }
    inb && /^> (Evidence|Found|Rationale):/ { n++ }
    inb && /^<!-- source:/ { if (n != 1) printf "%s: %d labels: %s\n", F, n, h; inb=0 }
  ' "$f"
done)"
if [ -n "$viol" ]; then fail "evidence labels: $viol"
else pass "exactly one evidence label per rule"; fi

# --- .gitattributes verified outside this repo ----------------------------
# It cannot be verified in place: a .gitattributes further up the tree
# contributes attributes to everything below it, so a check run here passes
# whatever this file says. The probe has to run where nothing else applies.
tmp="$(mktemp -d)"
cp "$ROOT/.gitattributes" "$tmp/.gitattributes"
(cd "$tmp" && git init -q .)
expect_eol() {
  got="$(cd "$tmp" && git check-attr eol -- "$1" | sed 's/.*: //')"
  [ "$got" = "$2" ] || echo "$1 -> $got (expected $2)"
}
attr_bad="$( { expect_eol sample.sh lf
               expect_eol sample.md lf
               expect_eol VERSION   lf
               expect_eol sample.bat crlf
               expect_eol sample.ps1 crlf; } )"
rm -rf "$tmp"
if [ -n "$attr_bad" ]; then fail "gitattributes in a clean repo: $attr_bad"
else pass "gitattributes behaves correctly in a clean repo"; fi

# --- README translations agree ---------------------------------------------
readmes=()
for r in "$ROOT"/README.md "$ROOT"/README.*.md; do
  [ -e "$r" ] && readmes+=("$r")
done
if [ "${#readmes[@]}" -le 1 ]; then
  pass "README consistency (only one README, nothing to compare)"
else
  base="$ROOT/README.md"
  count_structure() {
    printf '%s %s %s' \
      "$(grep -c '^#\{1,6\} ' "$1")" \
      "$(grep -c '^```' "$1")" \
      "$(grep -c '^|' "$1")"
  }
  # Everything inside a fence, minus comment lines: this is what a reader
  # copies out, and it is the part a translation must not have touched.
  copyable() {
    awk '/^```/{f=!f; next} f' "$1" | grep -vE '^[[:space:]]*#' | sed 's/[[:space:]]*$//'
  }
  bad=""
  for r in "${readmes[@]}"; do
    [ "$r" = "$base" ] && continue
    n="$(basename "$r")"
    [ "$(count_structure "$base")" = "$(count_structure "$r")" ] || \
      bad="$bad; $n structure $(count_structure "$r") != $(count_structure "$base")"
    diff <(copyable "$base") <(copyable "$r") >/dev/null 2>&1 || \
      bad="$bad; $n copyable lines differ"
  done
  if [ -n "$bad" ]; then fail "README translations${bad}"
  else pass "README translations agree (${#readmes[@]} files)"; fi
fi

echo
if [ "$FAILED" -eq 0 ]; then echo "check.sh: all checks passed"; else echo "check.sh: FAILED"; fi
exit "$FAILED"
