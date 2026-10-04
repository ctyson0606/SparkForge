#!/usr/bin/env bash
# Generates one self-contained HTML page showing where the project stands, and
# opens it. The page stores nothing: every run rebuilds it from SPEC.md,
# STATE.md, AGENTS.md and git, so it cannot drift from them.
#
# The page is a canvas of cards joined by lines. A line exists only where an id
# written in a file says so: a criterion naming its goal "(G1)", a commit
# subject or a Next Steps entry naming an AC id. Nothing is guessed from
# wording or position, and a card with no id reference stays unlinked.
#
# The work is split in two. This script reads the files and git and writes the
# result as JSON inside the page; JavaScript inside the page does the layout
# and drawing. Both stay in this one file so the output is one self-contained
# page that needs no network.
#
# This file lives at kit/scripts/progress.sh and is run through the stub at
# scripts/progress.sh (Windows: scripts/progress.ps1, which finds Git Bash and
# opens the page). ROOT is two levels above it, as in check.sh.
#
# Usage: scripts/progress.sh [--no-open] [--out <file>] [--no-mark]
#        scripts/progress.sh --untranslated
#
#   --no-open       write the page, do not open a browser
#   --out <file>    where to write it. Default: inside the git directory, so it
#                   belongs to this clone and is never committed
#   --no-mark       do not move the "last viewed" marker
#   --untranslated  print every displayed unit that has no current translation,
#                   and every orphaned translation, then stop. No page is made.
#
# stdout carries the output path (or, for --untranslated, the report) and
# nothing else; notices go to stderr, so a launcher can read the last line.
#
# Portable on purpose: bash 3.2 and BSD userland (macOS) as well as Git Bash and
# Linux. No associative arrays, mapfile, ${var,,}, sed -i, grep -P, GNU date
# flags, or awk beyond POSIX (no interval expressions either: {n} is missing
# from the awk macOS ships).

set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NO_OPEN=0
OUT=""
UNTRANS=0
MARK=1
FIRST_N=15     # commits shown on a first view
MAX_N=50       # commits shown at most

while [ $# -gt 0 ]; do
  case "$1" in
    --no-open)      NO_OPEN=1 ;;
    --no-mark)      MARK=0 ;;
    --untranslated) UNTRANS=1 ;;
    --out)
      shift
      [ $# -gt 0 ] || { echo "progress.sh: --out needs a file" >&2; exit 2; }
      OUT="$1" ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "progress.sh: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if ! GITDIR="$(git -C "$ROOT" rev-parse --absolute-git-dir 2>/dev/null)"; then
  echo "progress.sh: $ROOT is not inside a git repository. The page reads git for what changed, and keeps its marker in the git directory." >&2
  exit 1
fi

SPEC="$ROOT/SPEC.md"
STATE="$ROOT/STATE.md"
AGENTS="$ROOT/AGENTS.md"
MARKER="$GITDIR/sparkforge-progress-last"
[ -n "$OUT" ] || OUT="$GITDIR/sparkforge-progress.html"
case "$OUT" in /*|?:*) ;; *) OUT="$PWD/$OUT" ;; esac

T="$(mktemp -d "${TMPDIR:-/tmp}/sparkforge-progress.XXXXXX")" || exit 1
trap 'rm -rf "$T"' EXIT
mkdir "$T/tr" "$T/used"

# --- declarations -----------------------------------------------------------
# TRANSLATION is blank when unset. The value names a file, so it is held to a
# language tag rather than trusted as a path.
LANG2=""
if [ -f "$AGENTS" ]; then
  LANG2="$(sed -n 's/^TRANSLATION:[[:space:]]*//p' "$AGENTS" | head -n 1 \
           | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//' | tr -d '\r')"
fi
case "$LANG2" in
  *[!A-Za-z0-9-]*) echo "progress.sh: TRANSLATION '$LANG2' is not a language tag; ignoring it" >&2; LANG2="" ;;
esac
TRANS_ON=0
[ -n "$LANG2" ] && TRANS_ON=1

if [ "$UNTRANS" -eq 1 ] && [ "$TRANS_ON" -eq 0 ]; then
  echo "TRANSLATION is blank in AGENTS.md, so there is nothing to translate."
  exit 0
fi

# --- awk: units --------------------------------------------------------------
# A unit is one paragraph or one list item of a section, whitespace collapsed
# and trimmed: the thing that gets a translation, and the thing that is hashed.
# Output: "<kind> <text>" with kind p, li or h. Comments and fenced blocks are
# skipped.
UNITS_AWK='
function norm(s) { gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return s }
function flush() { if (cur != "") print kind " " cur; cur = ""; kind = "" }
{ sub(/\r$/, "") }
/^## / { flush(); on = (norm($0) == "## " sec); fence = 0; incom = 0; next }
!on { next }
{ line = $0 }
incom { if (line ~ /-->/) incom = 0; next }
line ~ /^[ \t]*<!--/ { if (line !~ /-->/) incom = 1; next }
line ~ /^[ \t]*```/ { flush(); fence = !fence; next }
fence { next }
line ~ /^[ \t]*$/ { flush(); next }
line ~ /^###+ / { flush(); sub(/^#+ +/, "", line); kind = "h"; cur = norm(line); flush(); next }
line ~ /^[ \t]*([-*]|[0-9]+[.)])[ \t]+/ {
  flush(); sub(/^[ \t]*([-*]|[0-9]+[.)])[ \t]+/, "", line); kind = "li"; cur = norm(line); next }
{ if (cur == "") { kind = "p"; cur = norm(line) } else cur = cur " " norm(line) }
END { flush() }
'

# --- awk: translation file -> one file per hash --------------------------------
# An entry is a "## <hash>" heading and the translated text under it, up to the
# next heading. Several lines are joined into one.
TRFILE_AWK='
function norm(s) { gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return s }
function done_entry() {
  if (active && txt != "") { print txt > (dir "/" h); close(dir "/" h) }
  active = 0; txt = ""
}
{ sub(/\r$/, "") }
/^## / { done_entry(); h = $2; if (h ~ /^[0-9a-f]+$/) active = 1; next }
active && NF { txt = (txt == "") ? norm($0) : txt " " norm($0) }
END { done_entry() }
'

TRFILE=""
if [ "$TRANS_ON" -eq 1 ]; then
  TRFILE="$ROOT/translations/$LANG2.md"
  if [ -f "$TRFILE" ]; then
    awk -v dir="$T/tr" "$TRFILE_AWK" "$TRFILE"
  else
    echo "progress.sh: translations/$LANG2.md does not exist; every unit shows in English as untranslated" >&2
  fi
fi

# resolve_section <file> <heading> [li]
# One line per displayed unit: kind, status, hash, English, translation, joined
# by the unit separator (octal 037). status is ok when an entry's hash equals the
# hash of the current English unit, otherwise stale: a translation written for
# an older wording is never shown as current. With a third argument li, only
# list items are kept, the ones the acceptance block displays.
resolve_section() {
  [ -f "$1" ] || return 0
  awk -v sec="$2" "$UNITS_AWK" "$1" | while read -r kind text; do
    [ "$kind" = "li" ] || [ "${3:-}" != "li" ] || continue
    h=""; tr=""; st="ok"
    if [ "$TRANS_ON" -eq 1 ]; then
      h="$(printf '%s' "$text" | git hash-object --stdin)"
      if [ -f "$T/tr/$h" ]; then
        tr="$(cat "$T/tr/$h")"
        : > "$T/used/$h"
      else
        st="stale"
      fi
    fi
    printf '%s\037%s\037%s\037%s\037%s\n' "$kind" "$st" "$h" "$text" "$tr"
  done
}

resolve_section "$SPEC"  "Problem"             > "$T/res.problem"
resolve_section "$SPEC"  "Goals"               li > "$T/res.goals"
resolve_section "$SPEC"  "Acceptance criteria" li > "$T/res.ac"
resolve_section "$STATE" "Current Focus"       > "$T/res.focus"
resolve_section "$STATE" "Next Steps"          li > "$T/res.next"
resolve_section "$STATE" "Open Questions"      > "$T/res.open"

# --- --untranslated: report and stop ------------------------------------------------
if [ "$UNTRANS" -eq 1 ]; then
  echo "# Language: $LANG2 (translations/$LANG2.md)"
  echo "# Units below have no current translation. Each block is a translation-file"
  echo "# entry: keep the '## <hash>' line, replace the English with the translation."
  echo
  cat "$T/res.problem" "$T/res.focus" "$T/res.goals" "$T/res.ac" "$T/res.next" "$T/res.open" \
    | awk 'BEGIN { FS = "\037" } $2 == "stale" && !($3 in seen) { seen[$3] = 1; print "## " $3; print $4; print "" }'
  echo "# Orphaned entries: their hash matches no displayed unit, so prune them."
  orph=0
  for f in "$T"/tr/*; do
    [ -e "$f" ] || continue
    n="$(basename "$f")"
    [ -e "$T/used/$n" ] && continue
    orph=$((orph + 1))
    printf '%s  %s\n' "$n" "$(head -c 60 "$f")"
  done
  [ "$orph" -gt 0 ] || echo "(none)"
  exit 0
fi

# STATE.md's Acceptance status lines, as units: read by acs_json.
: > "$T/status.units"
[ -f "$STATE" ] && awk -v sec="Acceptance status" "$UNITS_AWK" "$STATE" > "$T/status.units"

# --- awk: JSON ---------------------------------------------------------------------------------
# The page is drawn by JavaScript from one JSON block. Everything read from a
# file is escaped here, and only here: backslash, quote, every control
# character, and "<" as a unicode escape, so "</script>" in a file can never end the
# block it is embedded in. The page itself sets text only through textContent,
# so nothing read from a file is ever parsed as markup.
JLIB='
function jesc(s,   o, i, c, n, k) {
  o = ""
  n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (c == "<") o = o "\\u003c"
    else if ((k = index(CTL, c)) > 0) o = o sprintf("\\u%04x", k)
    else o = o c
  }
  return "\"" o "\""
}
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
BEGIN { for (ci = 1; ci < 32; ci++) CTL = CTL sprintf("%c", ci) }
'

json_str() { printf '%s' "$1" | awk "$JLIB"'{ printf "%s", jesc($0) } END { if (NR == 0) printf "\"\"" }'; }

# units_json <res-file>: [{"k":kind,"st":ok|stale,"en":..,"tr":..}, ...]
units_json() {
  awk "$JLIB"'
    BEGIN { FS = "\037"; printf "[" }
    NF >= 4 { printf "%s{\"k\":%s,\"st\":%s,\"en\":%s,\"tr\":%s}", (n++ ? "," : ""), jesc($1), jesc($2), jesc($4), jesc($5) }
    END { printf "]" }' "$1"
}

# A list item that starts with an id: "G1: text", "AC3 (G1, G2): text". Sets
# pid (empty when the item has no id), prefs (comma list of goal ids, empty
# when none are written) and prest (the text without them). The pattern says
# what an id looks like, so goals and criteria can differ.
HEAD_AWK='
function parse_head(s, pat,   w, rest, p, inner, n, parts, i, ok) {
  pid = ""; prefs = ""; prest = s
  w = s; sub(/ .*$/, "", w)
  if (w == s || w !~ pat) return
  pid = w; sub(/[.:)]$/, "", pid)
  rest = substr(s, length(w) + 2)
  if (substr(rest, 1, 1) == "(") {
    p = index(rest, ")")
    if (p > 0) {
      inner = substr(rest, 2, p - 2)
      gsub(/[,;\/]/, " ", inner)
      n = split(inner, parts, " ")
      ok = (n > 0)
      for (i = 1; i <= n; i++) if (parts[i] !~ /^G[0-9][0-9]*$/) ok = 0
      if (ok) {
        prefs = parts[1]
        for (i = 2; i <= n; i++) prefs = prefs "," parts[i]
        rest = trim(substr(rest, p + 1))
        if (substr(rest, 1, 1) == ":") rest = trim(substr(rest, 2))
        else if (substr(rest, 1, length("：")) == "：") rest = trim(substr(rest, length("：") + 1))
      }
    }
  }
  prest = rest
}
# The same head on a translation: dropped only when it names the same id.
function strip_tr(t, id, pat,   r) {
  if (t == "") return t
  parse_head(t, pat)
  if (pid == id) return prest
  if (substr(t, 1, length(id)) == id) {
    r = substr(t, length(id) + 1)
    if (substr(r, 1, 1) == ":") return trim(substr(r, 2))
    if (substr(r, 1, length("：")) == "：") return trim(substr(r, length("：") + 1))
  }
  return t
}
function jarr_ids(csv,   n, parts, i, o) {
  if (csv == "") return "[]"
  n = split(csv, parts, ",")
  o = "["
  for (i = 1; i <= n; i++) o = o (i > 1 ? "," : "") jesc(parts[i])
  return o "]"
}
'
ID_PAT='^[A-Za-z][A-Za-z]*[0-9][0-9]*[.:)]?$'
GOAL_PAT='^G[0-9][0-9]*[.:)]?$'

# goals_json: an item "G1: text" is goal G1; an item without an id is G<n> by
# position, flagged so the page can say that the id was never written.
goals_json() {
  awk -v idpat="$GOAL_PAT" "$JLIB $HEAD_AWK"'
    BEGIN { FS = "\037"; printf "[" }
    NF >= 4 {
      pos++
      en = $4; tr = $5
      parse_head(en, idpat)
      if (pid == "") { id = "G" pos; impl = 1 }
      else { id = pid; impl = 0; en = prest; tr = strip_tr(tr, id, idpat) }
      dup = (id in U) ? 1 : 0
      U[id] = 1
      printf "%s{\"id\":%s,\"impl\":%s,\"dup\":%s,\"st\":%s,\"en\":%s,\"tr\":%s}", (n++ ? "," : ""), jesc(id), (impl ? "true" : "false"), (dup ? "true" : "false"), jesc($2), jesc(en), jesc(tr)
    }
    END { printf "]" }' "$1"
}

# acs_json: criteria joined with STATE.md's Acceptance status lines. The id is
# the first word of a criterion when it looks like AC1; a criterion without one
# is numbered by position as AC<n>. Goals it serves are the ids in parentheses
# after the id. The status of a criterion comes only from a status line naming
# that id, and nothing is checked here: the page shows the evidence so a person
# can rerun it. Output: {"acs":[...],"unknown":[ids],"bad":[lines]}
acs_json() {
  awk -v EM="—" -v sf="$T/status.units" -v idpat="$ID_PAT" "$JLIB $HEAD_AWK"'
FILENAME == sf {
  t = $0
  if (t !~ /^li /) next
  t = substr(t, 4)
  i = index(t, ":")
  if (i == 0) { bad[++nb] = t; next }
  id = trim(substr(t, 1, i - 1)); rest = trim(substr(t, i + 1))
  if (id == "" || id ~ / /) { bad[++nb] = t; next }
  if (substr(rest, 1, 9) == "evidenced") { st = "evidenced"; rest = substr(rest, 10) }
  else if (substr(rest, 1, 7) == "claimed") { st = "claimed"; rest = substr(rest, 8) }
  else if (substr(rest, 1, 11) == "not started") { st = "none"; rest = substr(rest, 12) }
  else { bad[++nb] = t; next }
  rest = trim(rest)
  if (substr(rest, 1, length(EM)) == EM) rest = trim(substr(rest, length(EM) + 1))
  else if (substr(rest, 1, 2) == "--") rest = trim(substr(rest, 3))
  else if (substr(rest, 1, 1) == "-" || substr(rest, 1, 1) == ":") rest = trim(substr(rest, 2))
  date = ""
  if (match(rest, /[(][0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][)]$/)) {
    date = substr(rest, RSTART + 1, 10); rest = trim(substr(rest, 1, RSTART - 1))
  }
  S[id] = st; E[id] = rest; D[id] = date
  next
}
BEGIN { FS = "\037"; printf "{\"acs\":[" }
FILENAME != sf && NF >= 4 {
  pos++
  en = $4; tr = $5
  parse_head(en, idpat)
  if (pid == "") { id = "AC" pos; impl = 1; refs = "" }
  else { id = pid; impl = 0; refs = prefs; en = prest; tr = strip_tr(tr, id, idpat) }
  dup = (id in U) ? 1 : 0
  U[id] = 1
  decl = (id in S) ? S[id] : "missing"
  printf "%s{\"id\":%s,\"impl\":%s,\"dup\":%s,\"goals\":%s,\"decl\":%s,\"ev\":%s,\"date\":%s,\"st\":%s,\"en\":%s,\"tr\":%s}", (n++ ? "," : ""), jesc(id), (impl ? "true" : "false"), (dup ? "true" : "false"), jarr_ids(refs), jesc(decl), jesc(E[id]), jesc(D[id]), jesc($2), jesc(en), jesc(tr)
}
END {
  printf "],\"unknown\":["
  for (id in S) if (!(id in U)) printf "%s%s", (nu++ ? "," : ""), jesc(id)
  printf "],\"bad\":["
  for (i = 1; i <= nb; i++) printf "%s%s", (i > 1 ? "," : ""), jesc(bad[i])
  printf "]}"
}' "$T/status.units" "$T/res.ac"
}

# env_json: dev always, install and build when AGENTS.md has the key. A blank
# value is a finding, so it is passed on as blank (p true, v empty).
env_json() {
  [ -f "$AGENTS" ] || { printf '{"install":{"p":false,"v":""},"dev":{"p":false,"v":""},"build":{"p":false,"v":""}}'; return; }
  awk "$JLIB"'
    { sub(/\r$/, "") }
    /^## / { on = ($0 == "## Environment facts"); next }
    !on { next }
    /^(install|dev|build):/ {
      k = $0; sub(/:.*$/, "", k)
      v = $0; sub(/^[a-z]+:/, "", v); sub(/[ \t]+#.*$/, "", v); v = trim(v)
      V[k] = v; P[k] = 1
    }
    function one(k) { return "{\"p\":" ((k in P) ? "true" : "false") ",\"v\":" jesc(V[k]) "}" }
    END { printf "{\"install\":%s,\"dev\":%s,\"build\":%s}", one("install"), one("dev"), one("build") }' "$AGENTS"
}

# --- what changed since this machine last looked ------------------------------------------
# changes.log holds the commits to show; hist.log holds every commit (newest
# first, up to HIST_N) whose subject has anything id-shaped in it, so that "last
# touched by" can look back past the last view for any criterion.
HIST_N=5000
FMT='%h%x1f%ad%x1f%s'
CH_KIND="nocommits"; CH_N=""; CH_TOTAL=0
: > "$T/changes.log"; : > "$T/hist.log"
HEADC="$(git -C "$ROOT" rev-parse --verify -q HEAD 2>/dev/null)" || HEADC=""
if [ -n "$HEADC" ]; then
  last=""
  [ -f "$MARKER" ] && last="$(head -n 1 "$MARKER" | tr -d '[:space:]')"
  if [ -z "$last" ]; then
    CH_KIND="first"
    git -C "$ROOT" log -n "$FIRST_N" --date=short --format="$FMT" HEAD > "$T/changes.log"
  elif ! git -C "$ROOT" cat-file -e "$last^{commit}" 2>/dev/null; then
    CH_KIND="lost"
    git -C "$ROOT" log -n "$FIRST_N" --date=short --format="$FMT" HEAD > "$T/changes.log"
  else
    CH_TOTAL="$(git -C "$ROOT" rev-list --count "$last..HEAD")"
    CH_N="$(git -C "$ROOT" rev-parse --short "$last")"
    if [ "$CH_TOTAL" -eq 0 ]; then CH_KIND="none"; else CH_KIND="some"
      git -C "$ROOT" log -n "$MAX_N" --date=short --format="$FMT" "$last..HEAD" > "$T/changes.log"
    fi
  fi
  git -C "$ROOT" log -n "$HIST_N" --date=short --format="$FMT" HEAD 2>/dev/null \
    | awk -F '\037' '$3 ~ /[A-Za-z][0-9]/' > "$T/hist.log"
fi

# log_json <file>: [{"h":hash,"d":date,"s":subject}, ...]
log_json() {
  awk "$JLIB"'
    BEGIN { FS = "\037"; printf "[" }
    NF >= 3 { printf "%s{\"h\":%s,\"d\":%s,\"s\":%s}", (n++ ? "," : ""), jesc($1), jesc($2), jesc($3) }
    END { printf "]" }' "$1"
}

# --- the page ------------------------------------------------------------------------------
esc_sh() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
NAME=""
[ -f "$AGENTS" ] && NAME="$(sed -n 's/^# //p' "$AGENTS" | head -n 1 | tr -d '\r')"
[ -n "$NAME" ] || NAME="$(basename "$ROOT")"
NAME_H="$(printf '%s' "$NAME" | esc_sh)"
if [ "$TRANS_ON" -eq 1 ]; then DEF_LANG="zh"; TLANG="$LANG2"; else DEF_LANG="en"; TLANG="zh-TW"; fi
UPDATED=""
[ -f "$STATE" ] && UPDATED="$(sed -n 's/^> Last updated:[[:space:]]*//p' "$STATE" | head -n 1 | tr -d '\r')"
NOW="$(date '+%Y-%m-%d %H:%M')"
HEAD_SHORT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo none)"
TRFILE_OK=true
[ "$TRANS_ON" -eq 1 ] && [ ! -f "$TRFILE" ] && TRFILE_OK=false
TRANS_JS=false; [ "$TRANS_ON" -eq 1 ] && TRANS_JS=true
# Translations whose hash matches no displayed unit (the same ones --untranslated
# lists for pruning).
ORPHANS=0
for f in "$T"/tr/*; do
  [ -e "$f" ] || continue
  [ -e "$T/used/$(basename "$f")" ] || ORPHANS=$((ORPHANS + 1))
done

{
printf '<!doctype html>\n<html lang="%s" data-lang="%s" data-tlang="%s">\n' "$DEF_LANG" "$DEF_LANG" "$TLANG"
cat <<'EOF'
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
EOF
printf '<title>%s progress</title>\n' "$NAME_H"
cat <<'EOF'
<style>
:root { --bg:#f5f4ef; --fg:#1d1d1b; --muted:#66655f; --line:#d6d4ca; --card:#fff; --panel:#fbfaf7;
  --ok:#14663a; --okbg:#e0f3e7; --mid:#8a5a00; --midbg:#fbefd0; --none:#55554f; --nonebg:#ececea;
  --warn:#9c2a1a; --warnbg:#fbe7e2; --code:#efeee8; --dot:#dedcd2; --acc:#1b5fa8;
  --e-pg:#8d8b80; --e-ga:#23806f; --e-ca:#1b5fa8; --e-na:#8a3fb0;
  --n0:#8a3fb0; --n1:#d1530f; --n2:#c0267e; --n3:#8b5a2b; --n4:#5f7d12; --n5:#5b4bd6; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --bg:#141417; --fg:#e8e6df; --muted:#9d9b93; --line:#37373a; --card:#1f1f24; --panel:#1a1a1e;
  --ok:#6fd49a; --okbg:#173325; --mid:#f0c460; --midbg:#3a2e12; --none:#b0b0aa; --nonebg:#2b2b2e;
  --warn:#ff9d8a; --warnbg:#3b1d19; --code:#2a2a2e; --dot:#26262a; --acc:#7db6f0;
  --e-pg:#8d8b82; --e-ga:#4fc2ab; --e-ca:#6fb0f0; --e-na:#c78ae6;
  --n0:#c78ae6; --n1:#ff9a5c; --n2:#ff7ab8; --n3:#d6a574; --n4:#a9d05a; --n5:#9c93ff; } }
* { box-sizing:border-box; }
[hidden] { display:none !important; }
html, body { height:100%; }
body { margin:0; background:var(--bg); color:var(--fg); display:flex; flex-direction:column; height:100vh; overflow:hidden;
  font:15px/1.45 system-ui, -apple-system, "Segoe UI", "Noto Sans TC", "PingFang TC", "Microsoft JhengHei", sans-serif; }
code { background:var(--code); border-radius:4px; padding:.05em .3em; font:.88em ui-monospace, Consolas, Menlo, monospace; overflow-wrap:anywhere; }
button { font:inherit; font-size:.88rem; padding:.25rem .7rem; border:1px solid var(--line); border-radius:6px; background:var(--card); color:var(--fg); cursor:pointer; }
button:hover { border-color:var(--acc); }
html[data-lang="en"] .zh { display:none; }
html[data-lang="zh"] .en { display:none; }
em.stale { color:var(--warn); font-style:normal; font-size:.85em; }

/* header: fixed above the canvas */
#top { flex:none; background:var(--panel); border-bottom:1px solid var(--line); padding:.5rem 16px .6rem; }
.bar { display:flex; flex-wrap:wrap; gap:.3rem 1rem; align-items:center; justify-content:space-between; }
.bar h1 { font-size:1.25rem; margin:0; }
.tools { display:flex; gap:.5rem; }
.hgrid { display:grid; grid-template-columns:repeat(auto-fit, minmax(250px, 1fr)); gap:.6rem; margin-top:.5rem; }
.hb { background:var(--card); border:1px solid var(--line); border-radius:8px; padding:.45rem .7rem; min-width:0; }
.hb h2 { margin:0 0 .15rem; font-size:.72rem; letter-spacing:.06em; text-transform:uppercase; color:var(--muted); }
.hb .u { margin:0; }
.hb .u + .u { margin-top:.3rem; }
.cmd { display:flex; gap:.4rem; align-items:center; margin:.12rem 0; min-width:0; }
.cmd b { font:600 .8rem ui-monospace, Consolas, monospace; width:3.4rem; flex:none; }
.cmd code { flex:1; min-width:0; }
.cmd button { flex:none; padding:.05rem .45rem; font-size:.78rem; }
.gapname { color:var(--warn); font-style:italic; flex:1; }
.sum { font-weight:600; margin:.1rem 0 .35rem; }
.bar3 { display:flex; height:12px; border-radius:6px; overflow:hidden; background:var(--nonebg); border:1px solid var(--line); }
.bar3 i { display:block; height:100%; }
.bar3 .k1 { background:var(--ok); } .bar3 .k2 { background:#d9a21b; } .bar3 .k3 { background:transparent; }
.leg { display:flex; flex-wrap:wrap; gap:.2rem .8rem; margin-top:.3rem; font-size:.85rem; }
.leg .t1 { color:var(--ok); } .leg .t2 { color:var(--mid); } .leg .t3 { color:var(--none); }

/* main: canvas and gaps panel */
#main { flex:1; min-height:0; display:flex; }
#canvas { flex:1; position:relative; overflow:hidden; touch-action:none; cursor:grab; user-select:none; -webkit-user-select:none;
  background-image:radial-gradient(var(--dot) 1px, transparent 1px); background-size:22px 22px; }
#canvas.drag { cursor:grabbing; }
#view { position:absolute; left:0; top:0; transform-origin:0 0; }
#edges { position:absolute; left:0; top:0; overflow:visible; pointer-events:none; }
#cards { position:absolute; left:0; top:0; }
.ctl { position:absolute; right:10px; top:10px; display:flex; gap:.35rem; }
.ctl button { box-shadow:0 1px 3px rgba(0,0,0,.18); min-width:2rem; }
.legend { position:absolute; left:10px; top:10px; background:var(--panel); border:1px solid var(--line); border-radius:8px; padding:.35rem .6rem; font-size:.78rem; display:flex; flex-wrap:wrap; gap:.15rem .9rem; max-width:calc(100% - 200px); pointer-events:none; }
.legend span { display:inline-flex; align-items:center; gap:.35rem; }
.legend svg { width:26px; height:8px; overflow:visible; }
#gaps { flex:none; width:340px; overflow:auto; background:var(--panel); border-left:1px solid var(--line); padding:.7rem .8rem 1rem; }
#gaps h2 { font-size:1rem; margin:0 0 .4rem; }
#gaps ul { list-style:none; margin:0; padding:0; }
#gaps li.g { display:flex; gap:.5rem; padding:.4rem .5rem; margin:.3rem 0; background:var(--card); border:1px solid var(--line); border-radius:6px; font-size:.9rem; }
#gaps li.g.high { border-color:var(--warn); background:var(--warnbg); }
#gaps li.g.medium { border-color:#d9a21b; background:var(--midbg); }
#gaps li.g.low { color:var(--muted); }
#gaps li.g.high .ic { color:var(--warn); } #gaps li.g.medium .ic { color:var(--mid); } #gaps li.g.low .ic { color:var(--muted); }
#gaps h3.sev { font-size:.78rem; letter-spacing:.05em; text-transform:uppercase; margin:.9rem 0 .2rem; }
#gaps h3.sev-high { color:var(--warn); } #gaps h3.sev-medium { color:var(--mid); } #gaps h3.sev-low { color:var(--muted); }
#gaps li.g.ref { cursor:pointer; }
#gaps li.g.ref:hover { border-color:var(--acc); }
#gaps li.g .ic { flex:none; font-weight:700; width:1rem; text-align:center; }
#gaps .none { color:var(--ok); font-weight:600; }
#gaps details { margin-top:1rem; }
#gaps summary { cursor:pointer; font-weight:600; }
#gaps details li { margin:.3rem 0; font-size:.88rem; }
#gaps .gen { color:var(--muted); font-size:.78rem; margin-top:1.2rem; }

/* cards */
.card { position:absolute; background:var(--card); border:1px solid var(--line); border-left-width:5px; border-radius:8px; padding:.4rem .6rem .45rem; font-size:14px; line-height:1.4; box-shadow:0 1px 2px rgba(0,0,0,.08); transition:opacity .12s; overflow-wrap:anywhere; cursor:pointer; }
.card.nolink { border-style:dashed; border-left-style:solid; }
.card .ch { display:flex; flex-wrap:wrap; align-items:center; gap:.3rem .5rem; margin-bottom:.2rem; }
.card .kind { font-size:.68rem; letter-spacing:.06em; text-transform:uppercase; color:var(--muted); }
.card .id { font:700 .85rem ui-monospace, Consolas, Menlo, monospace; }
.card .date, .card .meta { color:var(--muted); font-size:.82em; }
.card .foot { margin-top:.3rem; font-size:.82em; color:var(--muted); }
.card .foot.w { color:var(--warn); font-weight:600; }
.warnmini { margin-left:auto; color:var(--warn); font-weight:600; font-size:.74rem; }
.card .u { margin:0; }
.card .u + .u { margin-top:.25rem; }
.fb { color:var(--muted); }
.enTag { font-size:.66em; font-weight:700; border:1px solid var(--line); border-radius:4px; padding:0 .3em; margin-right:.35em; color:var(--muted); font-style:normal; vertical-align:.1em; }
.untr { font-size:.72rem; font-weight:700; color:var(--warn); background:var(--warnbg); border:1px solid var(--warn); border-radius:99px; padding:0 .45rem; white-space:nowrap; }
.hb h2 .untr { margin-left:.5rem; text-transform:none; letter-spacing:0; }
.orig { font-size:.68rem; font-weight:600; color:var(--muted); border:1px solid var(--line); border-radius:4px; padding:0 .3em; margin-left:.3rem; }
#trline { margin-top:.4rem; padding:.3rem .6rem; border:1px solid var(--warn); background:var(--warnbg); border-radius:6px; font-size:.88rem; }
.badge { font-size:.76rem; font-weight:700; padding:.02rem .5rem; border-radius:99px; white-space:nowrap; }
.b-evidenced { color:var(--ok); background:var(--okbg); }
.b-claimed { color:var(--mid); background:var(--midbg); }
.b-none { color:var(--none); background:var(--nonebg); }
.s-evidenced { border-left-color:var(--ok); } .s-claimed { border-left-color:#d9a21b; } .s-none { border-left-color:#9a9a92; }
.t-goal { border-left-color:var(--e-ga); }
.t-commit { border-left-color:var(--e-ca); } .t-next { border-left-color:var(--e-na); }
.card.ac { border-width:1.5px; border-left-width:6px; font-size:14.5px; }
.ev { margin-top:.35rem; padding:.3rem .45rem; background:var(--code); border-radius:6px; font-size:.92em; }
.ev .lbl { font-weight:700; margin-right:.3rem; }
.warnline { margin-top:.35rem; color:var(--warn); font-weight:600; font-size:.92em; }
.cl { overflow:hidden; display:-webkit-box; -webkit-box-orient:vertical; -webkit-line-clamp:5; }
.cl.l3 { -webkit-line-clamp:3; } .cl.l4 { -webkit-line-clamp:4; } .cl.l7 { -webkit-line-clamp:7; }
.cw.open .cl { display:block; }
.more { margin-top:.15rem; padding:0 .4rem; font-size:.75rem; }
.cw.open .lm, .cw:not(.open) .ll { display:none; }
.colhead { position:absolute; font-weight:700; font-size:.95rem; letter-spacing:.01em; }
.colhead small { display:block; font-weight:400; color:var(--muted); font-size:.78rem; }
.sep { position:absolute; font-size:.72rem; letter-spacing:.06em; text-transform:uppercase; color:var(--muted); border-top:1.5px dashed var(--line); padding-top:.2rem; }
.edge { fill:none; stroke-width:1.8; stroke-linecap:round; transition:opacity .12s; }
.edge.ga { stroke:var(--e-ga); } .edge.ca { stroke:var(--e-ca); } .edge.na { stroke:var(--e-na); stroke-dasharray:6 3; }
.mk-n0 { fill:var(--n0); } .mk-n1 { fill:var(--n1); } .mk-n2 { fill:var(--n2); } .mk-n3 { fill:var(--n3); } .mk-n4 { fill:var(--n4); } .mk-n5 { fill:var(--n5); } .mk-ga { fill:var(--e-ga); } .mk-ca { fill:var(--e-ca); } .mk-na { fill:var(--e-na); }
.lg-ga { stroke:var(--e-ga); } .lg-ca { stroke:var(--e-ca); } .lg-na { stroke:var(--e-na); stroke-dasharray:6 3; }
.legend path { fill:none; stroke-width:2; }
#view.has-sel .card:not(.hl) { opacity:.22; }
#view.has-sel .edge:not(.hl) { opacity:.08; }
#view.has-sel .sep, #view.has-sel .colhead { opacity:.5; }
.card.sel { box-shadow:0 0 0 3px var(--acc), 0 2px 8px rgba(0,0,0,.25); }
.edge.hl { stroke-width:3.2; }
noscript { display:block; padding:1rem; }

@media (max-width: 800px) {
  body { display:block; height:auto; overflow:auto; }
  #main { display:flex; flex-direction:column; }
  #gaps { order:-1; width:auto; border-left:none; border-bottom:1px solid var(--line); max-height:60vh; }
  #canvas { flex:none; height:calc(100vh - 12px); min-height:480px; }
  .legend { font-size:.7rem; }
  .legend .sentence { display:none; }
}
</style>
</head>
<body>
<header id="top">
<div class="bar">
<h1 id="title"></h1>
<div class="tools"><button id="gapsbtn" type="button" hidden></button><button id="lang" type="button" hidden></button></div>
</div>
<div id="trline" class="zh" hidden></div>
<div class="hgrid">
<section class="hb" id="hproblem"></section>
<section class="hb" id="hfocus"></section>
<section class="hb" id="hstart"></section>
<section class="hb" id="hsum"></section>
</div>
</header>
<div id="main">
<div id="canvas">
<div id="view"><svg id="edges" xmlns="http://www.w3.org/2000/svg"></svg><div id="cards"></div></div>
<div class="ctl" id="ctl"></div>
<div class="legend" id="legend"></div>
</div>
<aside id="gaps"></aside>
</div>
<noscript><p>This page draws itself with JavaScript, which is off here. The data it shows is in the page source, in the block with id "data".</p></noscript>
EOF
printf '<script type="application/json" id="data">\n'
printf '{"name":%s,"updated":%s,"now":%s,"head":%s,"trans":%s,"tlang":%s,"trfileOk":%s,' \
  "$(json_str "$NAME")" "$(json_str "$UPDATED")" "$(json_str "$NOW")" "$(json_str "$HEAD_SHORT")" \
  "$TRANS_JS" "$(json_str "$LANG2")" "$TRFILE_OK"
printf '"orphans":%s,"trfile":%s,' "$ORPHANS" "$(json_str "translations/$LANG2.md")"
printf '"problem":%s,' "$(units_json "$T/res.problem")"
printf '"focus":%s,' "$(units_json "$T/res.focus")"
printf '"goals":%s,' "$(goals_json "$T/res.goals")"
printf '"ac":%s,' "$(acs_json)"
printf '"next":%s,' "$(units_json "$T/res.next")"
printf '"open":%s,' "$(units_json "$T/res.open")"
printf '"env":%s,' "$(env_json)"
printf '"changes":{"kind":%s,"n":%s,"total":%s,"items":%s},' "$(json_str "$CH_KIND")" "$(json_str "$CH_N")" "$CH_TOTAL" "$(log_json "$T/changes.log")"
printf '"hist":%s}\n' "$(log_json "$T/hist.log")"
printf '</script>\n<script>\n'
cat <<'EOF'
(function () {
  "use strict";
  var D = JSON.parse(document.getElementById("data").textContent);
  var root = document.documentElement;
  var KEY = "sparkforge-progress-lang";
  var SVGNS = "http://www.w3.org/2000/svg";

  /* ---------- small helpers: every file-derived string goes in through textContent ---------- */
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }
  function sv(tag, attrs) {
    var e = document.createElementNS(SVGNS, tag);
    for (var k in attrs) e.setAttribute(k, attrs[k]);
    return e;
  }
  // Inline code is the one piece of markdown shown: `like this`.
  function rich(parent, s) {
    var parts = s.split("`");
    if (parts.length === 1 || parts.length % 2 === 0) { parent.appendChild(document.createTextNode(s)); return parent; }
    for (var i = 0; i < parts.length; i++) {
      if (i % 2 === 1) parent.appendChild(el("code", null, parts[i]));
      else if (parts[i]) parent.appendChild(document.createTextNode(parts[i]));
    }
    return parent;
  }
  function bi(en, zh) {
    var f = document.createDocumentFragment();
    f.appendChild(rich(el("span", "en"), en));
    f.appendChild(rich(el("span", "zh"), zh));
    return f;
  }
  // A translation that is missing or out of date. The English then shows as a
  // fallback in the zh view. What says so must never sit where line clamping
  // can cut it off, so it is a leading tag on each unit and a tag in the header
  // of the card or box, never text at the end.
  function isFb(u) { return D.trans && !u.tr; }
  function untrTag() { var t = el("span", "untr zh", "未翻譯"); t.title = "No current translation: showing the English"; return t; }
  function origTag() { return el("span", "orig zh", "原文"); }
  function unitFrag(u) {
    var f = document.createDocumentFragment();
    f.appendChild(rich(el("span", "en"), u.en));
    var z = el("span", isFb(u) ? "zh fb" : "zh");
    if (isFb(u)) z.appendChild(el("span", "enTag", "EN"));
    rich(z, u.tr || u.en);
    f.appendChild(z);
    return f;
  }
  function unitDiv(u) {
    var d = el("div", "u");
    if (u.k === "h") d.style.fontWeight = "700";
    d.appendChild(unitFrag(u));
    return d;
  }
  function clamp(n, a, b) { return Math.max(a, Math.min(b, n)); }

  /* ---------- ids: a relation exists only where an id is written ---------- */
  function isW(c) { return c !== "" && /[A-Za-z0-9_]/.test(c); }
  // Whole-token match: AC1 is not found inside AC10, AC1x or xAC1.
  function hasTok(s, id) {
    var i = 0;
    while ((i = s.indexOf(id, i)) >= 0) {
      var b = i === 0 ? "" : s.charAt(i - 1), a = s.charAt(i + id.length);
      if (!isW(b) && !isW(a)) return true;
      i += 1;
    }
    return false;
  }

  /* ---------- model ---------- */
  var gaps = [];
  // How a gap is ranked, so the panel can be read top down:
  //   high    an incomplete or false state shown as if it were complete or true:
  //           evidenced with no evidence, a status line for an id that is not in
  //           SPEC.md, a criterion naming a goal SPEC.md does not list, a status
  //           line that cannot be read, an id used twice (one card silently lost)
  //   medium  something needed to link or finish the picture is missing: a
  //           criterion with no goal, a goal with no criterion, no status line,
  //           claimed without evidence, an empty dev command, no problem, goals
  //           or criteria at all, a missing translation file
  //   low     housekeeping: empty install or build, empty focus or next steps,
  //           untranslated units, orphaned translations, a lost marker commit
  // Within a rank the order is the order the checks run in.
  var SEV = ["high", "medium", "low"];
  function gap(sev, en, zh, ref) { gaps.push({ sev: sev, en: en, zh: zh, ref: ref || null }); }

  var goals = [], acs = [], goalBy = {}, acBy = {};
  D.goals.forEach(function (g) {
    if (g.dup) { gap("high", "`" + g.id + "` appears more than once under Goals in SPEC.md; only the first is drawn.", "`" + g.id + "` 在 SPEC.md 的 Goals 裡重複出現，只畫第一個。"); return; }
    goalBy[g.id] = g; goals.push(g); g.acs = [];
    if (g.impl) gap("medium", "A goal in SPEC.md has no id written; it is numbered `" + g.id + "` by position.", "SPEC.md 裡有一個目標沒有寫 id，依位置編為 `" + g.id + "`。", "g:" + g.id);
  });
  D.ac.acs.forEach(function (a) {
    if (a.dup) { gap("high", "`" + a.id + "` appears more than once under Acceptance criteria in SPEC.md; only the first is drawn.", "`" + a.id + "` 在 SPEC.md 的驗收條件裡重複出現，只畫第一個。"); return; }
    acBy[a.id] = a; acs.push(a);
    a.eff = a.decl === "evidenced" ? (a.ev ? "evidenced" : "claimed") : (a.decl === "claimed" ? "claimed" : "none");
    a.nodes = { c: [], n: [] };
    a.touch = null;
    for (var i = 0; i < D.hist.length; i++) { if (hasTok(D.hist[i].s, a.id)) { a.touch = D.hist[i]; break; } }
  });

  var counts = { evidenced: 0, claimed: 0, none: 0 };
  acs.forEach(function (a) { counts[a.eff]++; });

  var edges = [];
  function edge(kind, from, to) { edges.push({ kind: kind, from: from, to: to }); }

  // goal -> criterion: the criterion names its goal.
  acs.forEach(function (a) {
    a.gids = [];
    a.goals.forEach(function (gid) {
      if (goalBy[gid]) { if (a.gids.indexOf(gid) < 0) { a.gids.push(gid); goalBy[gid].acs.push(a); edge("ga", "g:" + gid, "a:" + a.id); } }
      else gap("high", "`" + a.id + "` names goal `" + gid + "`, which SPEC.md does not list.", "`" + a.id + "` 指名的目標 `" + gid + "` 不在 SPEC.md 裡。", "a:" + a.id);
    });
  });

  // commit -> criterion: an id in the subject. Next step -> criterion: an id in the entry.
  var commits = D.changes.items.map(function (c) {
    var k = { key: "c:" + c.h, c: c, ids: [] };
    acs.forEach(function (a) { if (hasTok(c.s, a.id)) { k.ids.push(a.id); a.nodes.c.push(k); edge("ca", k.key, "a:" + a.id); } });
    return k;
  });
  var nexts = D.next.filter(function (u) { return u.k === "li"; }).map(function (u, i) {
    var k = { key: "n:" + i, u: u, ids: [] };
    acs.forEach(function (a) { if (hasTok(u.en, a.id)) { k.ids.push(a.id); a.nodes.n.push(k); edge("na", k.key, "a:" + a.id); } });
    return k;
  });
  var hasProblem = D.problem.length > 0;

  /* ---------- gaps: what is missing, named ---------- */
  if (!hasProblem) gap("medium", "SPEC.md has nothing under Problem: the spec gate has not run.", "SPEC.md 的 Problem 是空的：規格門還沒跑過。");
  if (!goals.length) gap("medium", "SPEC.md lists no goals (list items under Goals).", "SPEC.md 沒有列出任何目標（Goals 底下的清單項目）。");
  if (!acs.length) gap("medium", "SPEC.md lists no acceptance criteria (list items under Acceptance criteria).", "SPEC.md 沒有列出任何驗收條件（Acceptance criteria 底下的清單項目）。");
  // Up to two of the same kind are named one by one; more become one line that
  // lists them, so the panel reads as a short list of problems, not a wall.
  function fmt(s, a, n) { return s.replace("%", function () { return a; }).replace("#", function () { return n; }); }
  function group(sev, ids, ref, one, many) {
    if (!ids.length) return;
    if (ids.length <= 2) { ids.forEach(function (id) { gap(sev, fmt(one[0], "`" + id + "`", 1), fmt(one[1], "`" + id + "`", 1), ref + id); }); return; }
    gap(sev, fmt(many[0], ids.join(", "), ids.length), fmt(many[1], ids.join(", "), ids.length), ref + ids[0]);
  }
  group("medium", goals.filter(function (g) { return !g.acs.length; }).map(function (g) { return g.id; }), "g:",
    ["% has no acceptance criteria: no criterion names it.", "% 沒有驗收條件：沒有任何條件指名它。"],
    ["# goals have no acceptance criteria, because no criterion names them: %.", "# 個目標沒有驗收條件，因為沒有任何條件指名它們：%。"]);
  acs.forEach(function (a) {
    var r = "a:" + a.id;
    if (a.impl) gap("medium", "A criterion in SPEC.md has no id written; it is numbered `" + a.id + "` by position.", "SPEC.md 裡有一項驗收條件沒有寫 id，依位置編為 `" + a.id + "`。", r);
    if (a.decl === "evidenced" && !a.ev) gap("high", "`" + a.id + "` is marked evidenced but records no evidence, so it counts as claimed.", "`" + a.id + "` 標為有證據，但沒有記錄證據，因此算作僅宣稱。", r);
    else if (a.decl === "claimed" && !a.ev) gap("medium", "`" + a.id + "` is claimed but records no evidence.", "`" + a.id + "` 是僅宣稱，而且沒有記錄證據。", r);
  });
  if (goals.length) group("medium", acs.filter(function (a) { return !a.goals.length; }).map(function (a) { return a.id; }), "a:",
    ["% names no goal.", "% 沒有指名任何目標。"],
    ["# criteria name no goal: %.", "# 項驗收條件沒有指名任何目標：%。"]);
  group("medium", acs.filter(function (a) { return a.decl === "missing"; }).map(function (a) { return a.id; }), "a:",
    ["% has no status line in STATE.md.", "% 在 STATE.md 沒有狀態行。"],
    ["# criteria have no status line in STATE.md, so they show as not started: %.", "# 項驗收條件在 STATE.md 沒有狀態行，因此顯示為未開始：%。"]);
  D.ac.unknown.slice().sort().forEach(function (id) { gap("high", "STATE.md has a status line for `" + id + "`, which SPEC.md does not list.", "STATE.md 有 `" + id + "` 的狀態行，但 SPEC.md 沒有這一項。"); });
  D.ac.bad.forEach(function (t) { gap("high", "Unreadable status line: `" + t.replace(/`/g, "'") + "` (expected `id: evidenced|claimed|not started - evidence (date)`).", "無法解讀的狀態行：`" + t.replace(/`/g, "'") + "`（格式：`id: evidenced|claimed|not started - 證據 (日期)`）。"); });
  [["dev", true], ["install", false], ["build", false]].forEach(function (p) {
    var e = D.env[p[0]];
    if (!e.p) { if (p[1]) gap("medium", "`dev` is not listed in AGENTS.md, so nothing says how to start the project.", "AGENTS.md 裡沒有 `dev`，沒有任何地方說明怎麼啟動專案。"); }
    else if (e.v === "") gap(p[1] ? "medium" : "low", "`" + p[0] + "` command is empty in AGENTS.md: not established yet.", "AGENTS.md 的 `" + p[0] + "` 指令是空的：尚未確立。");
  });
  if (!D.focus.length) gap("low", "STATE.md has nothing under Current Focus.", "STATE.md 的 Current Focus 是空的。");
  if (!nexts.length) gap("low", "STATE.md has no Next Steps (list items).", "STATE.md 沒有 Next Steps（清單項目）。");
  if (D.changes.kind === "lost") gap("low", "The marker commit is no longer in this repository (history was rewritten?), so the changes column shows the last commits instead.", "標記的 commit 已不在這個 repository（歷史被改寫過？），因此變更欄改為顯示最近的 commit。");
  if (D.trans && !D.trfileOk) gap("medium", "`" + D.trfile + "` does not exist, so every unit shows in English as untranslated.", "`" + D.trfile + "` 不存在，所有單位都以英文顯示為未翻譯。");
  // Every distinct displayed unit, and how many of them have no current translation.
  var trTotal = 0, trMiss = 0;
  (function () {
    var seen = {};
    [D.problem, D.focus, D.goals, D.ac.acs, D.next, D.open].forEach(function (list) { list.forEach(function (u) { if (seen[u.en]) return; seen[u.en] = 1; trTotal++; if (isFb(u)) trMiss++; }); });
  })();
  if (D.trans && trMiss) gap("low", trMiss + " of " + trTotal + " displayed units have no current translation; `scripts/progress.sh --untranslated` lists them.", trTotal + " 段中 " + trMiss + " 段沒有最新的翻譯；`scripts/progress.sh --untranslated` 會列出它們。");
  if (D.trans && D.orphans) gap("low", D.orphans + " translation(s) in `" + D.trfile + "` match no displayed unit; `scripts/progress.sh --untranslated` lists them to prune.", "`" + D.trfile + "` 裡有 " + D.orphans + " 筆翻譯對不到任何顯示的單位；`scripts/progress.sh --untranslated` 會列出，請清掉。");

  /* ---------- the header ---------- */
  document.getElementById("title").textContent = D.name;
  (function trline() {
    var t = document.getElementById("trline");
    if (!D.trans || !trMiss) return;
    t.appendChild(document.createTextNode(trTotal + " 段中 " + trMiss + " 段尚未翻譯，以淡色 EN 顯示英文原文。列出：")); t.appendChild(el("code", null, "scripts/progress.sh --untranslated"));
    t.appendChild(document.createTextNode("。Commit 標題與證據不翻譯，標為「原文」。"));
    t.hidden = false;
  })();

  function clampBox(content, lines) {
    var wrap = el("div", "cw"), box = el("div", "cl" + (lines ? " l" + lines : ""));
    box.appendChild(content);
    var btn = el("button", "more"); btn.type = "button"; btn.hidden = true;
    var m = el("span", "lm"); m.appendChild(bi("more", "展開"));
    var l = el("span", "ll"); l.appendChild(bi("less", "收合"));
    btn.appendChild(m); btn.appendChild(l);
    btn.addEventListener("click", function () { wrap.classList.toggle("open"); layout(); });
    wrap.appendChild(box); wrap.appendChild(btn);
    clamps.push({ wrap: wrap, box: box, btn: btn });
    return wrap;
  }
  var clamps = [];

  function section(id, en, zh, units) {
    var s = document.getElementById(id);
    var h = el("h2"); h.appendChild(bi(en, zh)); s.appendChild(h);
    if (units && units.some(isFb)) h.appendChild(untrTag());
    return s;
  }
  (function header() {
    var s = section("hproblem", "Problem", "問題", D.problem);
    if (!D.problem.length) { var e = el("p", "u"); e.style.color = "var(--warn)"; e.appendChild(bi("Not written: the spec gate has not run.", "還沒寫：規格門還沒跑過。")); s.appendChild(e); }
    else { var c = el("div"); D.problem.forEach(function (u) { c.appendChild(unitDiv(u)); }); s.appendChild(clampBox(c, 3)); }

    s = section("hfocus", "Current focus", "目前焦點", D.focus);
    if (!D.focus.length) { var e2 = el("p", "u"); e2.style.color = "var(--warn)"; e2.appendChild(bi("Nothing written under Current Focus in STATE.md.", "STATE.md 的 Current Focus 沒有內容。")); s.appendChild(e2); }
    else { var c2 = el("div"); D.focus.forEach(function (u) { c2.appendChild(unitDiv(u)); }); s.appendChild(clampBox(c2, 3)); }

    s = section("hstart", "How to start", "怎麼啟動");
    [["dev", true], ["install", false], ["build", false]].forEach(function (p) {
      var e = D.env[p[0]];
      if (!e.p && !p[1]) return;
      var row = el("div", "cmd");
      row.appendChild(el("b", null, p[0]));
      if (!e.p) { var g = el("span", "gapname"); g.appendChild(bi("not listed in AGENTS.md", "AGENTS.md 裡沒有這一項")); row.appendChild(g); }
      else if (e.v === "") { var g2 = el("span", "gapname"); g2.appendChild(bi("empty: not established yet", "空白：尚未確立")); row.appendChild(g2); }
      else {
        row.appendChild(el("code", null, e.v));
        var b = el("button", null); b.type = "button"; b.appendChild(bi("copy", "複製"));
        b.addEventListener("click", function () {
          function done() { b.textContent = "✓"; setTimeout(function () { b.textContent = ""; b.appendChild(bi("copy", "複製")); }, 1200); }
          try { navigator.clipboard.writeText(e.v).then(done, fallback); } catch (x) { fallback(); }
          function fallback() {
            try { var t = el("textarea"); t.value = e.v; t.style.position = "fixed"; t.style.opacity = "0"; document.body.appendChild(t); t.select(); document.execCommand("copy"); document.body.removeChild(t); done(); } catch (y) {}
          }
        });
        row.appendChild(b);
      }
      s.appendChild(row);
    });

    s = section("hsum", "Acceptance criteria", "驗收條件");
    var total = acs.length;
    if (!total) { var e3 = el("p", "u"); e3.style.color = "var(--warn)"; e3.appendChild(bi("None listed in SPEC.md yet.", "SPEC.md 還沒有列出。")); s.appendChild(e3); }
    else {
      var line = el("div", "sum");
      line.appendChild(bi(counts.evidenced + " of " + total + " evidenced", total + " 項中 " + counts.evidenced + " 項有證據"));
      s.appendChild(line);
      var bar = el("div", "bar3");
      [["k1", counts.evidenced], ["k2", counts.claimed], ["k3", counts.none]].forEach(function (p) { var i = el("i", p[0]); i.style.width = (100 * p[1] / total) + "%"; bar.appendChild(i); });
      s.appendChild(bar);
      var lg = el("div", "leg");
      var t1 = el("span", "t1"); t1.appendChild(bi("✓ " + counts.evidenced + " evidenced", "✓ " + counts.evidenced + " 項有證據"));
      var t2 = el("span", "t2"); t2.appendChild(bi("◐ " + counts.claimed + " claimed", "◐ " + counts.claimed + " 項僅宣稱"));
      var t3 = el("span", "t3"); t3.appendChild(bi("○ " + counts.none + " not started", "○ " + counts.none + " 項未開始"));
      lg.appendChild(t1); lg.appendChild(t2); lg.appendChild(t3);
      s.appendChild(lg);
    }
  })();

  /* ---------- the gaps panel ---------- */
  var aside = document.getElementById("gaps"), gapsbtn = document.getElementById("gapsbtn");
  (function panel() {
    var h = el("h2"); h.appendChild(bi("Gaps (" + gaps.length + ")", "缺口（" + gaps.length + "）")); aside.appendChild(h);
    if (!gaps.length) { var p = el("p", "none"); p.appendChild(bi("No gaps found.", "沒有發現缺口。")); aside.appendChild(p); }
    else {
      var HEAD = { high: ["High: shown as complete or true, but is not", "高：看起來完整或正確，其實不是"], medium: ["Medium: something needed is missing", "中：缺少必要的東西"], low: ["Low: housekeeping", "低：整理類"] };
      var MARK = { high: "▲", medium: "◆", low: "·" };
      SEV.forEach(function (sv) {
        var list = gaps.filter(function (g) { return g.sev === sv; });
        if (!list.length) return;
        var hh = el("h3", "sev sev-" + sv); hh.appendChild(bi(HEAD[sv][0] + " (" + list.length + ")", HEAD[sv][1] + "（" + list.length + "）")); aside.appendChild(hh);
        var ul = el("ul");
        list.forEach(function (g) {
          var li = el("li", "g " + sv + (g.ref ? " ref" : ""));
          li.appendChild(el("span", "ic", MARK[sv]));
          var t = el("span"); t.appendChild(bi(g.en, g.zh)); li.appendChild(t);
          if (g.ref) li.addEventListener("click", function () { focusNode(g.ref); });
          ul.appendChild(li);
        });
        aside.appendChild(ul);
      });
    }
    var det = el("details"), sm = el("summary"); sm.appendChild(bi("Open questions (" + D.open.length + ")", "未解問題（" + D.open.length + "）")); det.appendChild(sm);
    if (!D.open.length) { var e = el("p", "u"); e.style.color = "var(--muted)"; e.appendChild(bi("STATE.md has no Open Questions.", "STATE.md 沒有 Open Questions。")); det.appendChild(e); }
    else { var ul2 = el("ul"); D.open.forEach(function (u) { var li = el("li"); li.appendChild(unitFrag(u)); ul2.appendChild(li); }); det.appendChild(ul2); }
    aside.appendChild(det);
    var gen = el("p", "gen");
    gen.appendChild(bi("Generated " + D.now + " at commit `" + D.head + "` from SPEC.md, STATE.md (last updated: " + (D.updated || "unknown") + "), AGENTS.md and git. The page stores nothing and verifies nothing; run the generator again to refresh it, and rerun the evidence to check it.",
      "產生於 " + D.now + "，commit `" + D.head + "`，來源為 SPEC.md、STATE.md（最後更新：" + (D.updated || "不明") + "）、AGENTS.md 與 git。本頁不儲存也不驗證任何事；要更新請重新執行產生器，要確認請自行重跑證據裡的指令。"));
    aside.appendChild(gen);
    function sync() {
      var open = !aside.hidden;
      gapsbtn.textContent = "";
      gapsbtn.appendChild(bi((open ? "Hide gaps" : "Show gaps") + " (" + gaps.length + ")", (open ? "收起缺口" : "顯示缺口") + "（" + gaps.length + "）"));
    }
    aside.hidden = window.matchMedia("(max-width: 800px)").matches;
    gapsbtn.hidden = false;
    gapsbtn.addEventListener("click", function () { aside.hidden = !aside.hidden; sync(); layoutSoon(); });
    sync();
  })();

  /* ---------- cards ---------- */
  var nodes = {}, order = [];
  var cardsEl = document.getElementById("cards");
  function addNode(key, type, div, extra) {
    var n = { key: key, type: type, el: div, x: 0, y: 0, w: 0, h: 0, deg: 0 };
    for (var k in extra) n[k] = extra[k];
    div.setAttribute("data-key", key);
    div.classList.add("card", "t-" + type);
    cardsEl.appendChild(div);
    nodes[key] = n; order.push(n);
    return n;
  }
  function kindLabel(div, en, zh) { var k = el("span", "kind"); k.appendChild(bi(en, zh)); return k; }
  // A card no id reaches is drawn dashed and says so in its header row.
  function noLink(div, h, en, zh) { var w = el("span", "warnmini"); w.appendChild(bi(en, zh)); h.appendChild(w); div.classList.add("nolink"); }
  function arrows(h, ids) { var m = el("span", "meta"); m.appendChild(document.createTextNode("→ " + ids.join(", "))); h.appendChild(m); }

  var ICON = { evidenced: "✓", claimed: "◐", none: "○" };
  var LABEL = { evidenced: ["evidenced", "有證據"], claimed: ["claimed", "僅宣稱"], none: ["not started", "未開始"] };

  goals.forEach(function (g) {
    var d = el("div");
    var h = el("div", "ch"); h.appendChild(el("span", "id", g.id)); h.appendChild(kindLabel(d, "Goal", "目標"));
    if (!g.acs.length) { var w = el("span", "warnmini"); w.appendChild(bi("no criteria", "沒有條件")); h.appendChild(w); d.classList.add("nolink"); }
    if (isFb(g)) h.appendChild(untrTag());
    d.appendChild(h);
    d.appendChild(clampBox(unitDiv(g), 5));
    var f = el("div", "foot");
    if (!g.acs.length) { f.className = "foot w"; f.appendChild(bi("No acceptance criterion names " + g.id, "沒有任何驗收條件指名 " + g.id)); }
    else {
      var ev = g.acs.filter(function (a) { return a.eff === "evidenced"; }).length;
      var ids = g.acs.map(function (a) { return a.id; }).join(" ");
      f.appendChild(bi(ids + " — " + ev + " of " + g.acs.length + " evidenced", ids + " —— " + g.acs.length + " 項中 " + ev + " 項有證據"));
    }
    d.appendChild(f);
    addNode("g:" + g.id, "goal", d, { goal: g });
  });

  acs.forEach(function (a) {
    var d = el("div", "ac s-" + a.eff);
    var h = el("div", "ch");
    h.appendChild(el("span", "id", a.id));
    var b = el("span", "badge b-" + a.eff); b.appendChild(document.createTextNode(ICON[a.eff] + " ")); b.appendChild(bi(LABEL[a.eff][0], LABEL[a.eff][1])); h.appendChild(b);
    if (a.gids.length) { var sv2 = el("span", "meta"); sv2.appendChild(bi("serves " + a.gids.join(", "), "對應 " + a.gids.join(", "))); h.appendChild(sv2); }
    else noLink(d, h, "no goal", "沒有目標");
    if (isFb(a)) h.insertBefore(untrTag(), h.querySelector(".warnmini"));
    d.appendChild(h);
    d.appendChild(clampBox(unitDiv(a), 4));
    if (a.ev) {
      var e = el("div", "ev"); var l = el("span", "lbl"); l.appendChild(bi("Evidence", "證據")); e.appendChild(l); if (D.trans) e.appendChild(origTag());
      var body = el("span"); rich(body, a.ev); e.appendChild(body);
      if (a.date) e.appendChild(el("span", "date", " (" + a.date + ")"));
      var w = el("div"); w.appendChild(e); d.appendChild(clampBox(w, 3));
    }
    if (a.decl === "evidenced" && !a.ev) { var w1 = el("div", "warnline"); w1.appendChild(bi("Marked evidenced, but no evidence is recorded: counted as claimed.", "標為有證據，但沒有記錄證據：算作僅宣稱。")); d.appendChild(w1); }
    else if (a.decl === "claimed" && !a.ev) { var w2 = el("div", "warnline"); w2.appendChild(bi("No evidence recorded.", "沒有記錄證據。")); d.appendChild(w2); }
    else if (a.decl === "missing") { var w3 = el("div", "warnline"); w3.appendChild(bi("No status line in STATE.md.", "STATE.md 沒有狀態行。")); d.appendChild(w3); }
    var t = el("div", "foot");
    if (a.touch) { t.appendChild(bi("Last touched by `" + a.touch.h + "` " + a.touch.d, "最近一次相關 commit：`" + a.touch.h + "` " + a.touch.d)); }
    else t.appendChild(bi("No commit names " + a.id, "沒有任何 commit 提到 " + a.id));
    d.appendChild(t);
    addNode("a:" + a.id, "ac", d, { ac: a });
  });

  commits.forEach(function (k) {
    var d = el("div");
    var h = el("div", "ch"); h.appendChild(el("code", null, k.c.h)); h.appendChild(el("span", "date", k.c.d)); if (D.trans) h.appendChild(origTag());
    if (k.ids.length) arrows(h, k.ids); else noLink(d, h, "no id link", "沒有 id 連結");
    d.appendChild(h);
    d.appendChild(el("div", null, k.c.s));
    addNode(k.key, "commit", d, { ids: k.ids });
  });

  var colN = 0;
  nexts.forEach(function (k) {
    k.col = k.ids.length ? (colN++ % 6) : -1;
    var d = el("div");
    var h = el("div", "ch"); h.appendChild(kindLabel(d, "Next step", "下一步"));
    if (isFb(k.u)) h.appendChild(untrTag());
    if (k.ids.length) arrows(h, k.ids); else noLink(d, h, "no id link", "沒有 id 連結");
    d.appendChild(h);
    d.appendChild(clampBox(unitDiv(k.u), 5));
    addNode(k.key, "next", d, { ids: k.ids, col: k.col });
    if (k.col >= 0) { d.style.borderLeftColor = "var(--n" + k.col + ")"; var ar = h.querySelector(".meta"); if (ar) ar.style.color = "var(--n" + k.col + ")"; ar && (ar.style.fontWeight = "700"); }
  });

  /* ---------- layout ---------- */
  var COLW = { g: 220, a: 340, c: 240, n: 270 }, GAPX = 104, PADL = 24, ROW = 12, HEADH = 58, LANE = 14;
  var view = document.getElementById("view"), svg = document.getElementById("edges"), cv = document.getElementById("canvas");
  var W = 0, H = 0, decor = [], LX = { a: 0 };

  function nodeOf(k) { return nodes[k]; }
  function cyOf(n) { return n.y + n.h / 2; }

  // Ports: where each line meets a card, spread along its edge and ordered by
  // where the other end is, so lines leave and arrive without piling up.
  function ports(list, side, otherKey) {
    var byNode = {};
    list.forEach(function (e) { var n = side(e); (byNode[n] = byNode[n] || []).push(e); });
    for (var k in byNode) {
      var n = nodes[k], es = byNode[k];
      es.sort(function (p, q) { return cyOf(nodes[otherKey(p)]) - cyOf(nodes[otherKey(q)]); });
      es.forEach(function (e, i) {
        var y = es.length === 1 ? n.y + Math.min(n.h / 2, 40) : n.y + 20 + (n.h - 40) * i / (es.length - 1);
        if (n.h < 60 && es.length > 1) y = n.y + 8 + (n.h - 16) * i / (es.length - 1);
        e["y_" + k] = y;
      });
    }
  }

  function rpath(pts, r) {
    var d = "M" + pts[0][0] + " " + pts[0][1];
    for (var i = 1; i < pts.length - 1; i++) {
      var p0 = pts[i - 1], p1 = pts[i], p2 = pts[i + 1];
      var l1 = Math.hypot(p1[0] - p0[0], p1[1] - p0[1]), l2 = Math.hypot(p2[0] - p1[0], p2[1] - p1[1]);
      if (!l1 || !l2) continue;
      var rr = Math.min(r, l1 / 2, l2 / 2);
      d += " L" + (p1[0] + (p0[0] - p1[0]) * rr / l1) + " " + (p1[1] + (p0[1] - p1[1]) * rr / l1) +
           " Q" + p1[0] + " " + p1[1] + " " + (p1[0] + (p2[0] - p1[0]) * rr / l2) + " " + (p1[1] + (p2[1] - p1[1]) * rr / l2);
    }
    var z = pts[pts.length - 1];
    return d + " L" + z[0] + " " + z[1];
  }
  function bez(x1, y1, x2, y2) {
    var dx = (x2 - x1) * 0.5;
    return "M" + x1 + " " + y1 + " C" + (x1 + dx) + " " + y1 + " " + (x2 - dx) + " " + y2 + " " + x2 + " " + y2;
  }

  function layout() {
    // 1. measure
    clamps.forEach(function (c) { if (c.wrap.classList.contains("open")) c.btn.hidden = false; });
    order.forEach(function (n) {
      var cw = n.type === "problem" || n.type === "goal" ? COLW.g : n.type === "ac" ? COLW.a : n.type === "commit" ? COLW.c : COLW.n;
      n.el.style.width = cw + "px"; n.w = cw;
    });
    clamps.forEach(function (c) { if (!c.wrap.classList.contains("open")) c.btn.hidden = !(c.box.scrollHeight > c.box.clientHeight + 1); });
    order.forEach(function (n) { n.h = n.el.offsetHeight; });

    // 2. columns
    var skip = edges.filter(function (e) { return e.kind === "na"; });
    var H0 = skip.length ? 20 + skip.length * LANE : 12;
    var top = H0 + HEADH;
    var xg = PADL, xa = xg + COLW.g + GAPX, xc = xa + COLW.a + GAPX, xn = xc + COLW.c + GAPX;
    LX.a = xa;
    decor.forEach(function (d) { if (d.parentNode) d.parentNode.removeChild(d); });
    decor = [];
    function deco(cls, x, y, w) { var d = el("div", cls); d.style.left = x + "px"; d.style.top = y + "px"; if (w) d.style.width = w + "px"; cardsEl.appendChild(d); decor.push(d); return d; }
    function n_w2(x) { return x === xg ? COLW.g : x === xa ? COLW.a : x === xc ? COLW.c : COLW.n; }
    function head(x, en, zh, sub) {
      var d = deco("colhead", x, H0 - 2, n_w2(x));
      d.appendChild(bi(en, zh));
      if (sub) { var s = el("small"); s.appendChild(bi(sub[0], sub[1])); d.appendChild(s); }
    }

    // criteria: those that name a goal, in goal order; then those that name none
    var gIndex = {}; goals.forEach(function (g, i) { gIndex[g.id] = i; });
    var withGoal = acs.filter(function (a) { return a.gids.length; });
    var noGoal = acs.filter(function (a) { return !a.gids.length; });
    withGoal.sort(function (p, q) {
      var bp = p.gids.reduce(function (s, id) { return s + gIndex[id]; }, 0) / p.gids.length;
      var bq = q.gids.reduce(function (s, id) { return s + gIndex[id]; }, 0) / q.gids.length;
      return bp - bq || acs.indexOf(p) - acs.indexOf(q);
    });
    var y = top;
    withGoal.forEach(function (a) { var n = nodes["a:" + a.id]; n.x = xa; n.y = y; y += n.h + ROW; });
    if (noGoal.length) {
      if (withGoal.length) y += 10;
      var sp = deco("sep", xa, y, COLW.a); sp.appendChild(bi("No goal linked", "沒有連到目標")); y += 26;
      noGoal.forEach(function (a) { var n = nodes["a:" + a.id]; n.x = xa; n.y = y; y += n.h + ROW; });
    }
    var bottom = y;
    head(xa, "Acceptance criteria", "驗收條件", [counts.evidenced + " evidenced · " + counts.claimed + " claimed · " + counts.none + " not started", counts.evidenced + " 有證據 · " + counts.claimed + " 僅宣稱 · " + counts.none + " 未開始"]);

    // a column that follows the criteria: each card sits level with the
    // criteria it names, pushed down only as far as the cards above it need
    function follow(list, x, linkedOf, sepEn, sepZh) {
      var linked = [], free = [];
      list.forEach(function (n) { (linkedOf(n).length ? linked : free).push(n); });
      linked.forEach(function (n) { n.want = linkedOf(n).reduce(function (s, id) { return s + cyOf(nodes["a:" + id]); }, 0) / linkedOf(n).length; });
      linked.sort(function (p, q) { return p.want - q.want; });
      var prev = top - ROW;
      linked.forEach(function (n) { n.x = x; n.y = Math.max(n.want - n.h / 2, prev + ROW); prev = n.y + n.h; });
      if (free.length) {
        var yy = (linked.length ? prev + ROW + 10 : top);
        var s = deco("sep", x, yy, null); s.style.width = n_w(x) + "px"; s.appendChild(bi(sepEn, sepZh)); yy += 26;
        free.forEach(function (n) { n.x = x; n.y = yy; yy += n.h + ROW; prev = n.y + n.h; });
      }
      return prev;
    }
    function n_w(x) { return x === xc ? COLW.c : COLW.n; }

    // goals, level with their criteria
    var gy = top;
    var gl = goals.map(function (g) { return nodes["g:" + g.id]; });
    var gLinked = gl.filter(function (n) { return n.goal.acs.length; }), gFree = gl.filter(function (n) { return !n.goal.acs.length; });
    gLinked.forEach(function (n) { n.want = n.goal.acs.reduce(function (s, a) { return s + cyOf(nodes["a:" + a.id]); }, 0) / n.goal.acs.length; });
    var prev = gy - ROW;
    gLinked.forEach(function (n) { n.x = xg; n.y = Math.max(n.want - n.h / 2, prev + ROW); prev = n.y + n.h; });
    if (gFree.length) {
      var yy = prev + ROW + (gLinked.length ? 10 : 0);
      var s = deco("sep", xg, yy, COLW.g); s.appendChild(bi("No criterion names these", "沒有條件指名這些目標")); yy += 26;
      gFree.forEach(function (n) { n.x = xg; n.y = yy; yy += n.h + ROW; prev = n.y + n.h; });
    }
    bottom = Math.max(bottom, prev);
    head(xg, "Goals", "目標", goals.length ? [goals.length + " in SPEC.md", "SPEC.md 裡共 " + goals.length + " 個"] : null);

    bottom = Math.max(bottom, follow(commits.map(function (k) { return nodes[k.key]; }), xc, function (n) { return n.ids; }, "No id link", "沒有 id 連結"));
    var chk = D.changes, sub;
    if (chk.kind === "first") sub = ["First view here: the last " + chk.items.length + " commits", "這台機器第一次檢視：最近 " + chk.items.length + " 個 commit"];
    else if (chk.kind === "lost") sub = ["Marker gone: the last " + chk.items.length + " commits", "標記已不存在：最近 " + chk.items.length + " 個 commit"];
    else if (chk.kind === "none") sub = ["Nothing new since the last view (at " + chk.n + ")", "自上次檢視（" + chk.n + "）以來沒有新的 commit"];
    else if (chk.kind === "some") sub = [chk.total + " commit(s) since the last view (at " + chk.n + ")", "自上次檢視（" + chk.n + "）以來共 " + chk.total + " 個 commit"];
    else sub = ["No commits yet", "還沒有任何 commit"];
    head(xc, "Changes since last view", "上次檢視後的變更", sub);

    bottom = Math.max(bottom, follow(nexts.map(function (k) { return nodes[k.key]; }), xn, function (n) { return n.ids; }, "No id link", "沒有 id 連結"));
    head(xn, "Next steps", "下一步", [nexts.length + " in STATE.md", "STATE.md 裡共 " + nexts.length + " 項"]);

    order.forEach(function (n) { n.el.style.left = n.x + "px"; n.el.style.top = n.y + "px"; });
    W = xn + COLW.n + 50; H = bottom + 40;

    // 3. lines
    var ge = edges.filter(function (e) { return e.kind === "ga"; });
    var ce = edges.filter(function (e) { return e.kind === "ca"; });
    ports(ge, function (e) { return e.from; }, function (e) { return e.to; });
    ports(ge, function (e) { return e.to; }, function (e) { return e.from; });
    ports(ce.concat(skip), function (e) { return e.to; }, function (e) { return e.from; });
    ports(ce.concat(skip), function (e) { return e.from; }, function (e) { return e.to; });
    while (svg.firstChild) svg.removeChild(svg.firstChild);
    svg.setAttribute("width", W); svg.setAttribute("height", H);
    var defs = sv("defs", {});
    ["ga", "ca", "na", "n0", "n1", "n2", "n3", "n4", "n5"].forEach(function (k) {
      var m = sv("marker", { id: "mk-" + k, viewBox: "0 0 10 10", refX: "9", refY: "5", markerWidth: "8", markerHeight: "8", orient: "auto", markerUnits: "userSpaceOnUse" });
      m.appendChild(sv("path", { d: "M0 0 L10 5 L0 10 z", "class": "mk-" + k })); defs.appendChild(m);
    });
    svg.appendChild(defs);
    function draw(e, d) {
      var c = e.kind === "na" ? "n" + nodes[e.from].col : e.kind;
      var p = sv("path", { d: d, "class": "edge " + e.kind, "marker-end": "url(#mk-" + c + ")" });
      if (e.kind === "na") p.style.stroke = "var(--" + c + ")";
      svg.appendChild(p); e.path = p;
    }
    ge.forEach(function (e) { var a = nodes[e.from], b = nodes[e.to]; draw(e, bez(a.x + a.w, e["y_" + e.from], b.x, e["y_" + e.to])); });
    ce.forEach(function (e) { var a = nodes[e.from], b = nodes[e.to]; draw(e, bez(a.x, e["y_" + e.from], b.x + b.w, e["y_" + e.to])); });
    // next step -> criterion crosses the commits column, so it goes round the
    // top of it instead of behind the cards. Each line has its own lane, its own
    // vertical on each side, and the colour of its next step. Ordered by the
    // criterion's height: the higher the criterion, the higher the lane and the
    // nearer its vertical to the criteria, which keeps lines from crossing on
    // that side; the verticals on the next-step side run the other way.
    var span = Math.max(0, GAPX - 40), step = skip.length > 1 ? Math.min(14, span / (skip.length - 1)) : 0;
    skip.slice().sort(function (p, q) { return cyOf(nodes[p.to]) - cyOf(nodes[q.to]) || cyOf(nodes[p.from]) - cyOf(nodes[q.from]); }).forEach(function (e, i) {
      var a = nodes[e.from], b = nodes[e.to];
      var xA = xc - GAPX + 20 + i * step, xB = xn - 20 - i * step, ly = 10 + i * LANE;
      draw(e, rpath([[a.x, e["y_" + e.from]], [xB, e["y_" + e.from]], [xB, ly], [xA, ly], [xA, e["y_" + e.to]], [b.x + b.w, e["y_" + e.to]]], 8));
    });
    view.style.width = W + "px"; view.style.height = H + "px";
    applySel();
  }
  var pending = false;
  function layoutSoon() { if (pending) return; pending = true; setTimeout(function () { pending = false; layout(); if (!moved) fit(); }, 0); }

  /* ---------- selection ---------- */
  var sel = null;
  function applySel() {
    var near = {};
    if (sel) { near[sel] = 1; edges.forEach(function (e) { if (e.from === sel || e.to === sel) { near[e.from] = 1; near[e.to] = 1; } }); }
    view.classList.toggle("has-sel", !!sel);
    order.forEach(function (n) { n.el.classList.toggle("hl", !!near[n.key]); n.el.classList.toggle("sel", n.key === sel); });
    edges.forEach(function (e) { if (e.path) e.path.setAttribute("class", "edge " + e.kind + (sel && (e.from === sel || e.to === sel) ? " hl" : "")); });
  }
  function select(k) { sel = (sel === k) ? null : k; applySel(); }
  function focusNode(k) {
    var n = nodes[k]; if (!n) return;
    sel = k; applySel();
    var r = cv.getBoundingClientRect();
    S.tx = r.width / 2 - (n.x + n.w / 2) * S.k; S.ty = r.height / 2 - (n.y + n.h / 2) * S.k; moved = true; applyT();
    if (window.matchMedia("(max-width: 800px)").matches) { aside.hidden = true; gapsbtn.textContent = ""; gapsbtn.appendChild(bi("Show gaps (" + gaps.length + ")", "顯示缺口（" + gaps.length + "）")); cv.scrollIntoView({ block: "center" }); }
  }

  /* ---------- pan and zoom ---------- */
  var S = { tx: 0, ty: 0, k: 1 }, moved = false;
  function applyT() { view.style.transform = "translate(" + S.tx + "px," + S.ty + "px) scale(" + S.k + ")"; }
  // Readable first: the whole picture when it fits at a size text can be read
  // at, otherwise that size, with the criteria column in view, and the rest is
  // a pan away. The Fit button always shows everything.
  function fit(all) {
    var r = cv.getBoundingClientRect(), lg = document.getElementById("legend");
    var top = lg.offsetHeight + 20, availH = r.height - top - 14;
    var kw = (r.width - 30) / W, kh = availH / H;
    var k = Math.min(kw, kh, 1.15);
    if (!all && k < 0.8) k = 0.8;
    k = clamp(k, 0.1, 1.15);
    S.k = k;
    S.tx = W * k <= r.width ? (r.width - W * k) / 2 : (all ? 15 : Math.min(15, 14 - LX.a * k));
    S.ty = H * k <= availH ? top + (availH - H * k) / 2 : top;
    moved = false; applyT();
  }
  function zoomAt(cx, cy, f) {
    var k2 = clamp(S.k * f, 0.1, 2.5); f = k2 / S.k;
    S.tx = cx - (cx - S.tx) * f; S.ty = cy - (cy - S.ty) * f; S.k = k2; moved = true; applyT();
  }
  (function controls() {
    var c = document.getElementById("ctl");
    function btn(txt, fn, en, zh) { var b = el("button"); b.type = "button"; if (txt) b.textContent = txt; else b.appendChild(bi(en, zh)); b.addEventListener("click", fn); c.appendChild(b); return b; }
    btn("+", function () { var r = cv.getBoundingClientRect(); zoomAt(r.width / 2, r.height / 2, 1.25); });
    btn("−", function () { var r = cv.getBoundingClientRect(); zoomAt(r.width / 2, r.height / 2, 0.8); });
    btn(null, function () { fit(true); }, "Fit", "全覽");
    var lg = document.getElementById("legend");
    [["ga", "goal → criterion", "目標 → 條件"], ["ca", "commit → criterion", "commit → 條件"], ["na", "next step → criterion (a colour each)", "下一步 → 條件（各一種顏色）"]].forEach(function (p) {
      var s = el("span"), g = sv("svg", { viewBox: "0 0 26 8" });
      g.appendChild(sv("path", { d: "M0 4 L26 4", "class": "lg-" + p[0] })); s.appendChild(g); s.appendChild(bi(p[1], p[2])); lg.appendChild(s);
    });
    var s2 = el("span", "sentence"); s2.appendChild(bi("A line exists only where an id is written in a file.", "只有檔案裡寫了 id 的地方才有線。")); lg.appendChild(s2);
  })();

  var ptrs = {}, down = null, pinch = 0;
  function count() { return Object.keys(ptrs).length; }
  cv.addEventListener("pointerdown", function (e) {
    if (e.target.closest("button, .ctl")) return;
    ptrs[e.pointerId] = { x: e.clientX, y: e.clientY };
    if (count() === 1) { var c = e.target.closest(".card"); down = { x: e.clientX, y: e.clientY, moved: false, key: c ? c.getAttribute("data-key") : null }; }
    else { if (down) down.moved = true; var ks = Object.keys(ptrs); pinch = Math.hypot(ptrs[ks[0]].x - ptrs[ks[1]].x, ptrs[ks[0]].y - ptrs[ks[1]].y); }
  });
  cv.addEventListener("pointermove", function (e) {
    var p = ptrs[e.pointerId]; if (!p) return;
    var dx = e.clientX - p.x, dy = e.clientY - p.y;
    if (count() === 1 && down) {
      if (!down.moved && Math.hypot(e.clientX - down.x, e.clientY - down.y) > 4) { down.moved = true; cv.classList.add("drag"); try { cv.setPointerCapture(e.pointerId); } catch (x) {} }
      if (down.moved) { S.tx += dx; S.ty += dy; moved = true; applyT(); }
      p.x = e.clientX; p.y = e.clientY;
    } else if (count() === 2) {
      p.x = e.clientX; p.y = e.clientY;
      var ks = Object.keys(ptrs), a = ptrs[ks[0]], b = ptrs[ks[1]];
      var d = Math.hypot(a.x - b.x, a.y - b.y), r = cv.getBoundingClientRect();
      if (pinch) zoomAt((a.x + b.x) / 2 - r.left, (a.y + b.y) / 2 - r.top, d / pinch);
      pinch = d;
    }
  });
  function up(e) {
    if (!ptrs[e.pointerId]) return;
    var wasOne = count() === 1;
    delete ptrs[e.pointerId];
    if (wasOne && down) {
      if (!down.moved && e.type === "pointerup") { if (down.key) select(down.key); else { sel = null; applySel(); } }
      down = null; cv.classList.remove("drag");
    }
    if (count() < 2) pinch = 0;
  }
  cv.addEventListener("pointerup", up);
  cv.addEventListener("pointercancel", up);
  cv.addEventListener("wheel", function (e) {
    e.preventDefault();
    var r = cv.getBoundingClientRect();
    zoomAt(e.clientX - r.left, e.clientY - r.top, Math.exp(-e.deltaY * (e.deltaMode === 1 ? 0.05 : 0.0015)));
  }, { passive: false });
  window.addEventListener("resize", function () { if (!moved) fit(); });

  /* ---------- language ---------- */
  var lb = document.getElementById("lang"), tl = root.getAttribute("data-tlang") || "zh-TW";
  try { var s0 = localStorage.getItem(KEY); if (s0 === "en" || s0 === "zh") root.setAttribute("data-lang", s0); } catch (e) {}
  function applyLang() {
    var l = root.getAttribute("data-lang");
    root.setAttribute("lang", l === "zh" ? tl : "en");
    lb.textContent = l === "zh" ? "English" : "繁體中文";
  }
  lb.hidden = false;
  lb.addEventListener("click", function () {
    var n = root.getAttribute("data-lang") === "zh" ? "en" : "zh";
    root.setAttribute("data-lang", n);
    try { localStorage.setItem(KEY, n); } catch (e) {}
    applyLang(); layout();
  });
  applyLang();

  layout();
  fit();
})();
EOF
printf '</script>\n</body>\n</html>\n'
} > "$OUT" || { echo "progress.sh: could not write $OUT" >&2; exit 1; }

# Move the marker only after the page was written, so a failed run does not
# swallow the changes it never showed.
if [ "$MARK" -eq 1 ]; then
  git -C "$ROOT" rev-parse --verify -q HEAD > "$MARKER" 2>/dev/null || true
fi

# Git Bash hands native Windows programs a drive-letter path, which the launcher
# and the browser both read; elsewhere the path is already native.
SHOWN="$OUT"
command -v cygpath >/dev/null 2>&1 && SHOWN="$(cygpath -m "$OUT")"
echo "$SHOWN"

if [ "$NO_OPEN" -eq 0 ]; then
  case "$(uname -s 2>/dev/null)" in
    Darwin) open "$OUT" >/dev/null 2>&1 || echo "progress.sh: could not open the page; open $OUT yourself" >&2 ;;
    MINGW*|MSYS*|CYGWIN*) cmd //c start "" "$(cygpath -w "$OUT")" >/dev/null 2>&1 || echo "progress.sh: could not open the page; open $OUT yourself" >&2 ;;
    *) if command -v xdg-open >/dev/null 2>&1; then xdg-open "$OUT" >/dev/null 2>&1 &
       else echo "progress.sh: xdg-open not found; open $OUT yourself" >&2; fi ;;
  esac
fi
exit 0
