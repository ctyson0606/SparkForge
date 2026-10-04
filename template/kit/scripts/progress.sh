#!/usr/bin/env bash
# Generates one self-contained HTML page showing where the project stands, and
# opens it. The page stores nothing: every run rebuilds it from SPEC.md,
# STATE.md, AGENTS.md and git, so it cannot drift from them.
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
resolve_section "$SPEC"  "Goals"               > "$T/res.goals"
resolve_section "$SPEC"  "Acceptance criteria" li > "$T/res.ac"
resolve_section "$STATE" "Next Steps"          > "$T/res.next"
resolve_section "$STATE" "Open Questions"      > "$T/res.open"

# --- --untranslated: report and stop ------------------------------------------------
if [ "$UNTRANS" -eq 1 ]; then
  echo "# Language: $LANG2 (translations/$LANG2.md)"
  echo "# Units below have no current translation. Each block is a translation-file"
  echo "# entry: keep the '## <hash>' line, replace the English with the translation."
  echo
  cat "$T/res.problem" "$T/res.goals" "$T/res.ac" "$T/res.next" "$T/res.open" \
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

# --- awk: rendering --------------------------------------------------------------------
# Content from files is escaped here, and only here. Inline code is the one
# piece of markdown rendered.
RENDER_LIB='
function esc(s,   o, i, c) {
  o = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "&") o = o "&amp;"
    else if (c == "<") o = o "&lt;"
    else if (c == ">") o = o "&gt;"
    else if (c == "\"") o = o "&quot;"
    else o = o c
  }
  return o
}
function rend(s,   n, p, i, o) {
  n = split(s, p, "`")
  if (n == 1 || n % 2 == 0) return esc(s)
  o = ""
  for (i = 1; i <= n; i++) o = o ((i % 2 == 0) ? "<code>" esc(p[i]) "</code>" : esc(p[i]))
  return o
}
function unit(en, tr, st,   z) {
  z = (tr != "") ? rend(tr) : rend(en)
  if (tr == "" && trans && st == "stale") z = z " <em class=\"stale\">" mark "</em>"
  return "<span class=\"en\">" rend(en) "</span><span class=\"zh\">" z "</span>"
}
function bi(en, zh) { return "<span class=\"en\">" en "</span><span class=\"zh\">" zh "</span>" }
'

MARK_TEXT="[translation missing or out of date / 翻譯缺漏或過期]"
SECTION_AWK='
BEGIN { FS = "\037" }
{
  if ($1 == "li") {
    if (!inl) { print "<ul>"; inl = 1 }
    print "<li>" unit($4, $5, $2) "</li>"
    next
  }
  if (inl) { print "</ul>"; inl = 0 }
  if ($1 == "h") print "<h4>" unit($4, $5, $2) "</h4>"
  else print "<p>" unit($4, $5, $2) "</p>"
}
END { if (inl) print "</ul>" }
'

# render_section <res-file> <empty-en> <empty-zh>
render_section() {
  if [ -s "$1" ]; then
    awk -v trans="$TRANS_ON" -v mark="$MARK_TEXT" "$RENDER_LIB $SECTION_AWK" "$1"
  else
    printf '<p class="empty">%s</p>\n' "<span class=\"en\">$2</span><span class=\"zh\">$3</span>"
  fi
}

# Acceptance criteria joined with STATE.md's Acceptance status lines. The id is
# the first word of a criterion when it looks like AC1 or G2; spec-gate fixes no
# scheme, so a criterion without one is numbered by position as AC<n>. The
# status of a criterion comes only from a status line naming that id. Anything
# not evidenced with evidence text is shown as less than evidenced, and nothing
# is checked here: the page shows the evidence so a person can rerun it.
AC_AWK='
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function badge(st) {
  if (st == "evidenced") return "<span class=\"badge b-evidenced\">" bi("evidenced", "有證據") "</span>"
  if (st == "claimed") return "<span class=\"badge b-claimed\">" bi("claimed", "僅宣稱") "</span>"
  return "<span class=\"badge b-none\">" bi("not started", "未開始") "</span>"
}
FILENAME == sf {
  t = $0
  if (t !~ /^li /) next
  t = substr(t, 4)
  i = index(t, ":")
  if (i == 0) { bad[++nb] = t; next }
  id = trim(substr(t, 1, i - 1)); rest = trim(substr(t, i + 1))
  if (id == "" || id ~ / /) { bad[++nb] = t; next }
  if (substr(rest, 1, 9) == "evidenced" ) { st = "evidenced"; rest = substr(rest, 10) }
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
BEGIN { FS = "\037" }
FILENAME != sf && NF >= 4 {
  pos++
  en = $4; tr = $5
  w = en; sub(/ .*$/, "", w)
  if (w ~ /^[A-Za-z][A-Za-z]*[0-9][0-9]*[.:)]?$/ && w != en) {
    id = w; sub(/[.:)]$/, "", id)
    en = substr(en, length(w) + 2)
    if (tr != "") { w2 = tr; sub(/ .*$/, "", w2); if (w2 == w) tr = substr(tr, length(w) + 2) }
  } else id = "AC" pos
  U[id] = 1
  st = (id in S) ? S[id] : "none"
  warn = ""
  if (st == "evidenced" && E[id] == "") { st = "claimed"; warn = bi("Marked evidenced, but no evidence is recorded, so it is shown as claimed.", "標為已有證據，但沒有記錄證據，因此顯示為僅宣稱。") }
  cnt[st]++
  total++
  row = "<li class=\"ac s-" st "\"><div class=\"ach\"><span class=\"id\">" esc(id) "</span>" badge(st) "</div>"
  row = row "<div class=\"actext\">" unit(en, tr, $2) "</div>"
  if (warn != "") row = row "<div class=\"warn\">" warn "</div>"
  if (st == "claimed" && warn == "" && E[id] == "") row = row "<div class=\"warn\">" bi("No evidence recorded.", "沒有記錄證據。") "</div>"
  if (E[id] != "") {
    row = row "<div class=\"ev\"><span class=\"lbl\">" bi("Evidence", "證據") "</span> " rend(E[id])
    if (D[id] != "") row = row " <span class=\"date\">(" esc(D[id]) ")</span>"
    row = row "</div>"
  }
  rows = rows row "</li>\n"
}
END {
  if (total == 0) {
    print "<p class=\"empty\">" bi("SPEC.md lists no acceptance criteria yet.", "SPEC.md 還沒有列出驗收條件。") "</p>"
  } else {
    print "<p class=\"summary\">" bi(cnt["evidenced"] + 0 " of " total " evidenced, " cnt["claimed"] + 0 " claimed, " cnt["none"] + 0 " not started", total " 項中 " cnt["evidenced"] + 0 " 項有證據、" cnt["claimed"] + 0 " 項僅宣稱、" cnt["none"] + 0 " 項未開始") "</p>"
    print "<ul class=\"acs\">"; printf "%s", rows; print "</ul>"
  }
  for (id in S) if (!(id in U)) { if (!ow++) print "<p class=\"warn\">" bi("Status lines naming no criterion in SPEC.md:", "狀態行對應不到 SPEC.md 的任何驗收條件：") "</p><ul>"; print "<li><code>" esc(id) "</code></li>" }
  if (ow) print "</ul>"
  if (nb) {
    print "<p class=\"warn\">" bi("Status lines that could not be read (expected id: evidenced|claimed|not started - evidence (date)):", "無法解讀的狀態行（格式：id: evidenced|claimed|not started - 證據 (日期)）：") "</p><ul>"
    for (i = 1; i <= nb; i++) print "<li>" esc(bad[i]) "</li>"
    print "</ul>"
  }
}
'

render_ac() {
  : > "$T/status.units"
  [ -f "$STATE" ] && awk -v sec="Acceptance status" "$UNITS_AWK" "$STATE" > "$T/status.units"
  awk -v trans="$TRANS_ON" -v mark="$MARK_TEXT" -v EM="—" -v sf="$T/status.units" "$RENDER_LIB $AC_AWK" "$T/status.units" "$T/res.ac"
}

# Environment facts: dev always, install and build when AGENTS.md has the key.
# A blank value is shown as blank. It is a finding, not something to hide.
ENV_AWK='
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
{ sub(/\r$/, "") }
/^## / { on = ($0 == "## Environment facts"); next }
!on { next }
/^(install|dev|build):/ {
  k = $0; sub(/:.*$/, "", k)
  v = $0; sub(/^[a-z]+:/, "", v); sub(/[ \t]+#.*$/, "", v); v = trim(v)
  V[k] = v; P[k] = 1
}
function show(k,   v) {
  if (!(k in P)) { if (k == "dev") print "<tr><th><code>dev</code></th><td class=\"empty\">" bi("not listed in AGENTS.md", "AGENTS.md 裡沒有這一項") "</td></tr>"; return }
  v = V[k]
  if (v == "") print "<tr><th><code>" k "</code></th><td class=\"empty\">" bi("empty: not established yet", "空白：尚未確立") "</td></tr>"
  else print "<tr><th><code>" k "</code></th><td><code>" esc(v) "</code></td></tr>"
}
END { print "<table class=\"env\">"; show("install"); show("dev"); show("build"); print "</table>" }
'

# --- what changed since this machine last looked ------------------------------------------
render_changes() {
  local head last range total n fmt
  head="$(git -C "$ROOT" rev-parse --verify -q HEAD 2>/dev/null)" || head=""
  if [ -z "$head" ]; then
    printf '<p class="empty">%s</p>\n' "$(printf '<span class="en">No commits yet.</span><span class="zh">還沒有任何 commit。</span>')"
    return
  fi
  last=""
  [ -f "$MARKER" ] && last="$(head -n 1 "$MARKER" | tr -d '[:space:]')"
  fmt='%h%x1f%ad%x1f%s'
  if [ -z "$last" ]; then
    printf '<p>%s</p>\n' '<span class="en">First view on this machine, so this shows the last '"$FIRST_N"' commits.</span><span class="zh">這台機器第一次檢視，因此顯示最近 '"$FIRST_N"' 個 commit。</span>'
    git -C "$ROOT" log -n "$FIRST_N" --date=short --format="$fmt" HEAD
  elif ! git -C "$ROOT" cat-file -e "$last^{commit}" 2>/dev/null; then
    printf '<p class="warn">%s</p>\n' '<span class="en">The marker commit is no longer in this repository (history was rewritten?), so this shows the last '"$FIRST_N"' commits.</span><span class="zh">標記的 commit 已不在這個 repository（歷史被改寫過？），因此顯示最近 '"$FIRST_N"' 個 commit。</span>'
    git -C "$ROOT" log -n "$FIRST_N" --date=short --format="$fmt" HEAD
  else
    total="$(git -C "$ROOT" rev-list --count "$last..HEAD")"
    n="$(git -C "$ROOT" rev-parse --short "$last")"
    if [ "$total" -eq 0 ]; then
      printf '<p>%s</p>\n' '<span class="en">Nothing new since the last view (at <code>'"$n"'</code>).</span><span class="zh">自上次檢視（<code>'"$n"'</code>）以來沒有新的 commit。</span>'
      return
    fi
    printf '<p>%s</p>\n' '<span class="en">'"$total"' commit(s) since the last view (at <code>'"$n"'</code>).</span><span class="zh">自上次檢視（<code>'"$n"'</code>）以來共 '"$total"' 個 commit。</span>'
    git -C "$ROOT" log -n "$MAX_N" --date=short --format="$fmt" "$last..HEAD"
  fi | awk "$RENDER_LIB"'
    BEGIN { FS = "\037" }
    NF < 3 { print; next }
    { if (!o) { print "<ul class=\"log\">"; o = 1 } print "<li><code>" esc($1) "</code> <span class=\"date\">" esc($2) "</span> " esc($3) "</li>" }
    END { if (o) print "</ul>" }'
}

# --- the page ------------------------------------------------------------------------------
esc_sh() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
NAME=""
[ -f "$AGENTS" ] && NAME="$(sed -n 's/^# //p' "$AGENTS" | head -n 1 | tr -d '\r')"
[ -n "$NAME" ] || NAME="$(basename "$ROOT")"
NAME_H="$(printf '%s' "$NAME" | esc_sh)"
if [ "$TRANS_ON" -eq 1 ]; then DEF_LANG="zh"; TLANG="$LANG2"; else DEF_LANG="en"; TLANG="zh-TW"; fi
UPDATED=""
[ -f "$STATE" ] && UPDATED="$(sed -n 's/^> Last updated:[[:space:]]*//p' "$STATE" | head -n 1 | tr -d '\r' | esc_sh)"
NOW="$(date '+%Y-%m-%d %H:%M')"
HEAD_SHORT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo none)"

{
cat <<EOF
<!doctype html>
<html lang="$DEF_LANG" data-lang="$DEF_LANG" data-tlang="$TLANG">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$NAME_H progress</title>
<style>
:root { --bg:#fafaf8; --fg:#1d1d1b; --muted:#66655f; --line:#dcdad2; --card:#fff;
  --ok:#14663a; --okbg:#e0f3e7; --mid:#8a5a00; --midbg:#fbefd0; --none:#555; --nonebg:#ececea;
  --warn:#9c2a1a; --link:#1b5fa8; --code:#efeee8; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --bg:#17171a; --fg:#e8e6df; --muted:#9d9b93; --line:#33332f; --card:#202024;
  --ok:#6fd49a; --okbg:#173325; --mid:#f0c460; --midbg:#3a2e12; --none:#aaa; --nonebg:#2b2b2e;
  --warn:#ff9d8a; --link:#7db6f0; --code:#2a2a2e; } }
* { box-sizing:border-box; }
body { margin:0; background:var(--bg); color:var(--fg); font:16px/1.55 system-ui, -apple-system, "Segoe UI", "Noto Sans TC", "PingFang TC", "Microsoft JhengHei", sans-serif; }
main { max-width:52rem; margin:0 auto; padding:1rem 16px 3rem; }
header { display:flex; flex-wrap:wrap; gap:.5rem 1rem; align-items:baseline; justify-content:space-between; }
h1 { font-size:1.5rem; margin:.6rem 0; }
h2 { font-size:1.15rem; margin:0 0 .6rem; }
h3 { font-size:1rem; margin:1rem 0 .3rem; color:var(--muted); text-transform:none; }
h4 { font-size:1rem; margin:.8rem 0 .2rem; }
section { background:var(--card); border:1px solid var(--line); border-radius:8px; padding:1rem; margin:1rem 0; }
p, ul { margin:.4rem 0; } ul { padding-left:1.3rem; }
code { background:var(--code); border-radius:4px; padding:.05em .3em; font:.9em ui-monospace, Consolas, Menlo, monospace; overflow-wrap:anywhere; }
button { font:inherit; padding:.3rem .8rem; border:1px solid var(--line); border-radius:6px; background:var(--card); color:var(--fg); cursor:pointer; }
.meta, .date, .lbl { color:var(--muted); font-size:.88rem; }
.empty { color:var(--muted); font-style:italic; }
.warn { color:var(--warn); font-size:.92rem; }
.stale { color:var(--warn); font-style:normal; font-size:.85rem; }
html[data-lang="en"] .zh { display:none; }
html[data-lang="zh"] .en { display:none; }
.acs { list-style:none; padding:0; }
.ac { border:1px solid var(--line); border-radius:6px; padding:.6rem .7rem; margin:.5rem 0; }
.ach { display:flex; flex-wrap:wrap; gap:.5rem; align-items:center; margin-bottom:.2rem; }
.id { font:600 .9rem ui-monospace, Consolas, Menlo, monospace; }
.badge { font-size:.8rem; font-weight:600; padding:.05rem .5rem; border-radius:99px; }
.b-evidenced { color:var(--ok); background:var(--okbg); }
.b-claimed { color:var(--mid); background:var(--midbg); }
.b-none { color:var(--none); background:var(--nonebg); }
.ev { margin-top:.3rem; font-size:.92rem; overflow-wrap:anywhere; }
.summary { font-weight:600; }
.env { border-collapse:collapse; width:100%; } .env th { text-align:left; width:5.5rem; vertical-align:top; padding:.2rem .5rem .2rem 0; }
.env td { padding:.2rem 0; overflow-wrap:anywhere; }
.log { list-style:none; padding:0; } .log li { padding:.15rem 0; overflow-wrap:anywhere; }
footer { color:var(--muted); font-size:.85rem; }
</style>
</head>
<body>
<main>
<header>
<h1>$NAME_H</h1>
<button id="lang" type="button" hidden></button>
</header>

<section id="what">
<h2><span class="en">What this is and how to start it</span><span class="zh">這是什麼、怎麼啟動</span></h2>
<h3><span class="en">Problem</span><span class="zh">問題</span></h3>
EOF
render_section "$T/res.problem" "SPEC.md has nothing under Problem: the spec gate has not run." "SPEC.md 的 Problem 是空的：規格門還沒跑過。"
echo '<h3><span class="en">Goals</span><span class="zh">目標</span></h3>'
render_section "$T/res.goals" "SPEC.md has nothing under Goals." "SPEC.md 的 Goals 是空的。"
echo '<h3><span class="en">Commands (from AGENTS.md)</span><span class="zh">指令（來自 AGENTS.md）</span></h3>'
if [ -f "$AGENTS" ]; then
  awk "$RENDER_LIB $ENV_AWK" "$AGENTS"
else
  echo '<p class="empty"><span class="en">AGENTS.md is missing.</span><span class="zh">找不到 AGENTS.md。</span></p>'
fi
cat <<'EOF'
</section>

<section id="acceptance">
<h2><span class="en">Acceptance status</span><span class="zh">驗收狀態</span></h2>
<p class="meta"><span class="en">Nothing is shown as done without recorded evidence. This page verifies nothing: rerun the evidence to check it.</span><span class="zh">沒有記錄證據的項目一律不會顯示為完成。本頁不驗證任何事：要確認請自行重跑證據裡的指令。</span></p>
EOF
render_ac
cat <<'EOF'
</section>

<section id="changes">
<h2><span class="en">What changed since this machine last looked</span><span class="zh">這台機器上次檢視之後的變更</span></h2>
EOF
render_changes
cat <<'EOF'
</section>

<section id="next">
<h2><span class="en">Next steps and open questions</span><span class="zh">下一步與未解問題</span></h2>
<h3><span class="en">Next steps</span><span class="zh">下一步</span></h3>
EOF
render_section "$T/res.next" "STATE.md has no Next Steps." "STATE.md 沒有 Next Steps。"
echo '<h3><span class="en">Open questions</span><span class="zh">未解問題</span></h3>'
render_section "$T/res.open" "STATE.md has no Open Questions." "STATE.md 沒有 Open Questions。"
cat <<EOF
</section>

<footer>
<p><span class="en">Generated $NOW at commit <code>$HEAD_SHORT</code> from SPEC.md, STATE.md (last updated: ${UPDATED:-unknown}), AGENTS.md and git. The page stores nothing; run the generator again to refresh it.</span><span class="zh">產生於 $NOW，commit <code>$HEAD_SHORT</code>，來源為 SPEC.md、STATE.md（最後更新：${UPDATED:-不明}）、AGENTS.md 與 git。本頁不儲存任何東西，要更新請重新執行產生器。</span></p>
</footer>
</main>
<script>
(function () {
  var h = document.documentElement, key = "sparkforge-progress-lang", b = document.getElementById("lang");
  var tl = h.getAttribute("data-tlang") || "zh-TW";
  try { var s = localStorage.getItem(key); if (s === "en" || s === "zh") h.setAttribute("data-lang", s); } catch (e) {}
  function apply() {
    var l = h.getAttribute("data-lang");
    h.setAttribute("lang", l === "zh" ? tl : "en");
    b.textContent = l === "zh" ? "English" : "繁體中文";
  }
  b.hidden = false;
  b.addEventListener("click", function () {
    var n = h.getAttribute("data-lang") === "zh" ? "en" : "zh";
    h.setAttribute("data-lang", n);
    try { localStorage.setItem(key, n); } catch (e) {}
    apply();
  });
  apply();
})();
</script>
</body>
</html>
EOF
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
