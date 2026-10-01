# 🔥 SparkForge

**English** · [繁體中文](README.zh-TW.md) · [简体中文](README.zh-CN.md)

A workflow framework layer for AI coding agents, copied into a new project. It
carries no project knowledge of its own — only two things: 🧠 a mechanism for
accumulating project knowledge, and 🔬 a methodology for judging whether
evidence holds.

## 📦 What you get

Copy `template/` into a new project and its contents become the project root:

```text
my-project/
├── AGENTS.md
├── CLAUDE.md
├── GEMINI.md
├── SPEC.md
├── METHOD.md
├── STATE.md
├── GOTCHAS.md
├── .clinerules
├── .windsurfrules
├── .gitattributes
├── .claude/
│   ├── skills/
│   └── agents/
├── .cursor/
│   └── rules/
├── .github/
│   └── copilot-instructions.md
├── kit/
│   ├── VERSION
│   ├── entry-points.txt
│   ├── skills/
│   ├── agents/
│   └── scripts/
└── scripts/
    ├── check.sh
    └── update-kit.sh
```

| File | What it is for |
|---|---|
| ⚙️ `AGENTS.md` | The entry point, and the only file that routes. Holds `MODE`, `TEAM`, your project's environment commands, the hard rules, and the table that sends the agent to a skill. |
| 🚪 The per-tool entry files | `CLAUDE.md`, `GEMINI.md`, `.clinerules`, `.windsurfrules`, `.cursor/rules/`, `.github/`. Each says one thing: read `AGENTS.md` first. See below. |
| 🗂️ `kit/entry-points.txt` | The list of those entry files. Both checkers read it, so a tool cannot be covered in one place and missed in another. |
| 📐 `SPEC.md` | The approved contract: goals, non-goals, acceptance criteria, the data and API shapes. Changed only through the spec gate, so it outlives every state change. |
| 🧠 `METHOD.md` | Durable rules this project earned. **Starts empty and stays empty** until a real trap fills it. |
| 📌 `STATE.md` | Current working state. Replaced wholesale, never appended to. |
| 🐛 `GOTCHAS.md` | Version-bound traps, each dated. Delete freely once the dependency is gone. |
| 📚 `kit/` | The canonical framework content. **Never edit this inside a consuming project** — it is overwritten on update. |
| 🪝 `.claude/` | Thin stubs. Each is a frontmatter block plus one line pointing into `kit/`. |
| ✅ `scripts/check.sh` | Structural checks for the whole layout. A one-line stub: the checker is `kit/scripts/check.sh`, so its fixes arrive with `kit/`. |
| 🔄 `scripts/update-kit.sh` | Pulls a newer `kit/` from upstream, the scripts in `kit/scripts/` included. Also a stub, so it updates itself. |

The two-layer split is the point: 📚 `kit/` holds each rule once, and every AI
tool gets a directory of 🪝 thin stubs pointing at them. Supporting a second
tool means generating another set of stubs, not copying the rules again.

## 🚪 One instruction, every tool

You never have to tell an agent which file to read. Whichever tool opens the
project, its first instruction is the same: **read `AGENTS.md`**. Each tool
that will not find that file on its own has a small file at the path it does
read, and that file says nothing except where to go.

| Tool | Its file | How it loads |
|---|---|---|
| 🤖 Claude Code | `CLAUDE.md` | ⚙️ `@AGENTS.md`, a real import |
| ✏️ Cursor | `.cursor/rules/sparkforge.mdc` | ⚙️ `alwaysApply: true` in the frontmatter |
| 🐙 GitHub Copilot | `.github/copilot-instructions.md` | 📄 a path it always reads |
| 💠 Gemini CLI | `GEMINI.md` | 📄 a path it always reads |
| 🧵 Cline | `.clinerules` | 📄 a path it always reads |
| 🏄 Windsurf | `.windsurfrules` | 📄 a path it always reads |
| 🌊 Codex CLI, Amp, DeepSeek Harness | `AGENTS.md` itself | ✅ read natively, no entry needed |

Two of those are mechanisms the loader itself honours; the rest work by putting
the words where the tool is certain to see them. ⚠️ Never write an instruction
into one of these files. Two tools reading two different sets of rules is the
failure the whole arrangement exists to prevent.

🗑️ Not using a tool? Delete its entry. That is the supported way to opt out,
and it is why `check.sh` treats a missing entry as deliberate rather than
broken.

## 🚀 Install

```bash
# 1. Copy the whole template in. Use "template/." and not "template/*",
#    or you will silently miss .claude/, .cursor/, .github/ and .gitattributes.
#    Quote both paths: one space anywhere in them breaks the command
cp -R "/path/to/SparkForge/template/." "/path/to/my-project/"

cd "/path/to/my-project"
git init

# 2. Open AGENTS.md and replace its first line, "# SparkForge", with your
#    own project name. Do this BEFORE staging anything: stage first and the
#    commit below carries the old title while your tree shows the new one

# 3. Stage, then set the executable bit in the index. On Windows the mode
#    in the working tree is not real, so chmod cannot do this
git add -A
git add --chmod=+x -- 'scripts/*.sh' 'kit/scripts/*.sh'

#    Every line this prints must begin with 100755
git ls-files -s -- 'scripts/*.sh' 'kit/scripts/*.sh'

# 4. Verify the layout, then commit
bash scripts/check.sh
git commit -m "Adopt SparkForge"
```

⚠️ On Windows, run that in **Git Bash**, not PowerShell. `bash` typed into
PowerShell resolves to `C:\Windows\System32\bash.exe`, which is WSL's launcher
and not Git Bash at all; with no distribution installed it fails with
`execvpe(/bin/bash) failed`, a message pointing nowhere near the real cause.
To stay in PowerShell, call Git's own bash by its full path:

```powershell
# Find where Git actually lives — it is not always on the C: drive
(Get-Command git).Source

# Then call the bash that ships beside it. The & is required: without it
# PowerShell treats a quoted path as a string and prints it instead
& "C:\Program Files\Git\bin\bash.exe" scripts/check.sh
```

Then open your agent and **ask it to run bootstrap** — it does not fire by
itself. 🥾 Bootstrap runs exactly once, while `METHOD.md` and `STATE.md` are both
still empty, and it will:

1. Put the scripts into the index carrying the executable bit — the same thing
   step 3 above did, for the case where bootstrap is driving the setup itself.
2. Ask you for `MODE` and `TEAM`, and write them into `AGENTS.md`.
3. Fill in the environment commands one by one. Where the project genuinely has
   no such command it writes `none` — an absence is a finding, not a blank.
4. Run the spec gate at the depth `MODE` selects.
5. Write the result into `SPEC.md`, and point `Current Focus` in `STATE.md` at
   the part being built first.
6. **Leave `METHOD.md` empty.** This is a hard rule. Rules are earned from traps
   the project actually hits, never guessed in advance.

## 🧭 Daily use

Memory loads itself: the entry file imports `AGENTS.md`, which imports
`SPEC.md`, `METHOD.md`, `STATE.md` and `GOTCHAS.md`. Every session opens with everything
the project has learned already in context.

| When you are… | Read | The one-line version |
|---|---|---|
| 🚪 about to build a feature | `kit/skills/spec-gate.md` | Restate the requirement as a *problem*, ask only blocking questions, produce goals, non-goals, acceptance criteria and the data/API contract — then **stop and wait for approval**. |
| 🧪 looking at a green test run | `kit/skills/verification.md` | A suite that passes on its first run is unverified, not correct. Break the code on purpose and confirm the right tests fail. |
| 🔍 chasing a failure | `kit/skills/diagnosis.md` | An intermittent failure has a *rate*, and one run does not measure it. Check the harness before reading anything into a result. |
| 👥 working with other people | `kit/skills/team-contract.md` | Agree once on the data/API contract and on who owns which directories. Nothing beyond that. |
| 💾 writing memory | `kit/skills/memory-update.md` | Write the moment state changes, never at the end. Re-read the *whole* file first: the stale line is never where you were working. |

### 🚨 The spec gate is not optional here

Whatever `MODE` says, the gate must run for any change touching 🔐 authentication,
🛡️ authorisation, 💳 payments, 🔑 secrets, 🗄️ database migrations, or 🌐 more than one
service. Everywhere else it is a judgement call.

### 🧠 How memory behaves

- ✍️ **Memory is written as you go.** The moment state changes — a step done, a
  decision made, a finding, a trap hit — the agent writes it down, without being
  asked and never saving it for the end, because a session can stop without
  warning when a quota runs out or you switch tools. Asking still works: say so
  and every file is brought up to date at once. A delegated subagent writes
  before it returns, since its context is discarded with it.
- 🔁 **`METHOD.md` accumulates.** Correct a rule in place rather than appending one
  that contradicts it. Deleting requires a stated reason.
- 🧹 **`STATE.md` is replaced.** Anything no longer true is deleted, not archived.
  Git holds the history.
- ⚡ **A claim your own change falsified is fixed in the same step as the
  change**, before moving on. Until then it will be believed. Keeping the record
  true is part of the work.

### 🕵️ The evidence reviewer

`kit/agents/evidence-reviewer.md` is a read-only subagent, and its tool list is
short on purpose — `Read`, `Grep`, `Glob`. It cannot run commands, because an
agent that can execute becomes a second implementer instead of a second pair of
eyes. It answers with exactly one of: **Evidence holds.** / **Evidence
insufficient.** naming the rules that fail / **Cannot judge.** naming what is
missing.

## 🔄 Updating

```bash
# Overwrites kit/ from upstream. SPEC.md, METHOD.md, STATE.md, GOTCHAS.md
# and every section of AGENTS.md are yours, and are never touched
scripts/update-kit.sh

# A skill added or removed upstream needs its stub adding or removing,
# and this is the thing that reports that
bash scripts/check.sh
```

📣 If an update starts supporting a tool you have no entry file for,
`update-kit.sh` names it. It reports only what that update introduced, never
every absent entry — a warning that fires on each tool you deliberately do not
use is read twice and ignored afterwards.

📦 A project installed before the scripts moved into `kit/scripts/` still has
the full scripts in `scripts/`. Copy the two stubs from SparkForge's
`template/scripts/` over them once. Until then the old copies keep running and
the fixes that arrive in `kit/scripts/` are never used.

📮 Found something that belongs to SparkForge rather than to your project — a
rule that proved wrong, a check that missed, a script that broke? Don't edit
`kit/` locally. The agent writes it under `Upstream` in your `STATE.md`, as it
writes the rest of memory, and it stays there until upstream has it. A
SparkForge checkout next to your projects reads that section from all of them
with one command, `scripts/collect-upstream.sh`. 🏅 A framework rule your
project was the first to actually walk belongs there too: it is worth more
than most improvements.

## 🌡️ Maturity

Stated plainly, because this framework's own methodology insists on it. **It has
been installed on three real projects, all on Windows. One, a desktop tool, was
built through every acceptance criterion of its spec and is in daily use; the
other two passed the spec gate and have been built on since.** `STATE.md` in
this repository records the detail, and what has still never been exercised.

| Component | Standing |
|---|---|
| 🧪 `verification.md` | ✅ Rules extracted from real incidents, most carrying a recorded one. Several now carry incidents from two or three projects. |
| 🔍 `diagnosis.md` | ✅ Same — extracted from a working methodology, not written from spec. |
| 💾 `memory-update.md` | ✅ Same. Writing memory as you go was measured before it shipped: with nothing said about memory, the agent recorded what came next, and under the old rule it did not. |
| ✅ `check.sh` | ✅ Runs, and has caught real holes, in this repository and in a project using it. |
| 🔄 `update-kit.sh` | 🟡 Run end to end against a throwaway upstream, carrying the scripts with `kit/` and replacing itself mid-run on Windows. It has never pulled a real change into a real project. |
| 🚪 The tool entry files | 🟡 Claude Code's is an import its loader honours, and it has been watched carrying a real project's rules into a session. The others work by asking the agent to open `AGENTS.md`, the kind of request an experiment here found agents ignoring. None of them has been opened. |
| 📐 `SPEC.md` | ⚠️ New. No project has kept its spec there yet. |
| 🚪 `spec-gate.md` | 🟡 Written from spec. It has produced its four artifacts in all three projects, each time as bootstrap's fourth step. It has never been seen firing on its own. |
| 👥 `team-contract.md` | ⚠️ Written from spec. Zero executions. |
| 🥾 `bootstrap.md` | ✅ Written from spec, and run in all three projects. It does not start by itself: ask for it by name. |
| 🕵️ `evidence-reviewer.md` | ⚠️ Written from spec. Zero executions. |
| 🎚️ The `T0`/`T1`/`T2` tier system | ⚠️ Never exercised. The tags are annotation so far. |

The install above has been walked three times, all on Windows, and corrected by
what the first walk broke. It has not been walked on macOS or Linux. 🧗 Whoever
runs it on a new platform is on new ground — record the friction, because that
record is how this section was corrected the first time.

## 🚫 What SparkForge does not include

These describe the boundaries of the framework itself — what SparkForge does
not ship. They say nothing about what a project using SparkForge may do.

- ❌ No built-in task tracking, kanban board, or task cards.
- ❌ No cold-start scan of an existing codebase. SparkForge is designed only for
  projects that adopt it from their first commit.
- ❌ No design for non-software work.
- ❌ No UI design system and no mockup gate.
- ❌ No module whose value depends on the whole team adopting it. This is the
  admission test for any new module: if exactly one person on the team uses it,
  is it still worth having?
