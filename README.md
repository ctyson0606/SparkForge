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
├── METHOD.md
├── STATE.md
├── GOTCHAS.md
├── .gitattributes
├── .claude/
│   ├── skills/
│   └── agents/
├── kit/
│   ├── VERSION
│   ├── skills/
│   └── agents/
└── scripts/
    ├── check.sh
    └── update-kit.sh
```

| File | What it is for |
|---|---|
| ⚙️ `AGENTS.md` | The entry point. Holds `MODE`, `TEAM`, your project's environment commands, the hard rules, and the routing table that sends the agent to a skill. |
| 🔗 `CLAUDE.md` | One line: `@AGENTS.md`. The tool-specific door into everything else. |
| 🧠 `METHOD.md` | Durable rules this project earned. **Starts empty and stays empty** until a real trap fills it. |
| 📌 `STATE.md` | Current working state. Replaced wholesale, never appended to. |
| 🐛 `GOTCHAS.md` | Version-bound traps, each dated. Delete freely once the dependency is gone. |
| 📚 `kit/` | The canonical framework content. **Never edit this inside a consuming project** — it is overwritten on update. |
| 🪝 `.claude/` | Thin stubs. Each is a frontmatter block plus one line pointing into `kit/`. |
| ✅ `scripts/check.sh` | Structural checks for the whole layout. |
| 🔄 `scripts/update-kit.sh` | Pulls a newer `kit/` from upstream. |

The two-layer split is the point: 📚 `kit/` holds each rule once, and every AI
tool gets a directory of 🪝 thin stubs pointing at them. Supporting a second
tool means generating another set of stubs, not copying the rules again.

## 🚀 Install

```bash
# 1. Copy the whole template in. Use "template/." and not "template/*",
#    or you will silently miss .claude/ and .gitattributes
cp -R /path/to/SparkForge/template/. /path/to/my-project/

cd /path/to/my-project
git init
git add -A

# 2. Mark the scripts executable in the git index.
#    On Windows the working-tree mode is not real, so chmod is not enough
git update-index --chmod=+x scripts/check.sh scripts/update-kit.sh

# 3. Open AGENTS.md and replace the first line, "# SparkForge",
#    with your own project name

# 4. Verify the layout before committing
bash scripts/check.sh

git commit -m "Adopt SparkForge"
```

Then open your agent and **ask it to run bootstrap** — it does not fire by
itself. 🥾 Bootstrap runs exactly once, while `METHOD.md` and `STATE.md` are both
still empty, and it will:

1. Ask you for `MODE` and `TEAM`, and write them into `AGENTS.md`.
2. Fill in the environment commands one by one. Where the project genuinely has
   no such command it writes `none` — an absence is a finding, not a blank.
3. Run the spec gate at the depth `MODE` selects.
4. Write the result into `Current Focus` in `STATE.md`.
5. **Leave `METHOD.md` empty.** This is a hard rule. Rules are earned from traps
   the project actually hits, never guessed in advance.

## 🧭 Daily use

Memory loads itself: `CLAUDE.md` imports `AGENTS.md`, which imports `METHOD.md`,
`STATE.md` and `GOTCHAS.md`. Every session opens with everything the project has
learned already in context.

| When you are… | Read | The one-line version |
|---|---|---|
| 🚪 about to build a feature | `kit/skills/spec-gate.md` | Restate the requirement as a *problem*, ask only blocking questions, produce goals, non-goals, acceptance criteria and the data/API contract — then **stop and wait for approval**. |
| 🧪 looking at a green test run | `kit/skills/verification.md` | A suite that passes on its first run is unverified, not correct. Break the code on purpose and confirm the right tests fail. |
| 🔍 chasing a failure | `kit/skills/diagnosis.md` | An intermittent failure has a *rate*, and one run does not measure it. Check the harness before reading anything into a result. |
| 👥 working with other people | `kit/skills/team-contract.md` | Agree once on the data/API contract and on who owns which directories. Nothing beyond that. |
| 💾 asked to save memory | `kit/skills/memory-update.md` | Re-read the *whole* file, not the sections you touched. The stale line is never where you were working. |

### 🚨 The spec gate is not optional here

Whatever `MODE` says, the gate must run for any change touching 🔐 authentication,
🛡️ authorisation, 💳 payments, 🔑 secrets, 🗄️ database migrations, or 🌐 more than one
service. Everywhere else it is a judgement call.

### 🧠 How memory behaves

- ✍️ **Memory is written on request only.** The main conversation never writes on
  its own — you have to ask. The one exception is a delegated subagent, which
  writes when it finishes, because it holds context the main thread never sees.
- 🔁 **`METHOD.md` accumulates.** Correct a rule in place rather than appending one
  that contradicts it. Deleting requires a stated reason.
- 🧹 **`STATE.md` is replaced.** Anything no longer true is deleted, not archived.
  Git holds the history.
- ⚡ **A claim your own change falsified gets fixed immediately**, without waiting
  to be asked. Adding to the record is a request; keeping the record true is
  part of the work.

### 🕵️ The evidence reviewer

`kit/agents/evidence-reviewer.md` is a read-only subagent, and its tool list is
short on purpose — `Read`, `Grep`, `Glob`. It cannot run commands, because an
agent that can execute becomes a second implementer instead of a second pair of
eyes. It answers with exactly one of: **Evidence holds.** / **Evidence
insufficient.** naming the rules that fail / **Cannot judge.** naming what is
missing.

## 🔄 Updating

```bash
# Overwrites kit/ from upstream. METHOD.md, STATE.md, GOTCHAS.md
# and every section of AGENTS.md are yours, and are never touched
scripts/update-kit.sh

# A skill added or removed upstream needs its stub adding or removing,
# and this is the thing that reports that
bash scripts/check.sh
```

Found an improvement while using it? Send it upstream instead of editing `kit/`
locally. And when you do, read the `Unverified` block in the upstream
`STATE.md` — 🏅 a rule your project has now actually walked is worth more than
the improvement itself.

## 🌡️ Maturity

Stated plainly, because this framework's own methodology insists on it. **No
part of this has been used on a real project yet.**

| Component | Standing |
|---|---|
| 🧪 `verification.md` | ✅ Rules extracted from real incidents, most carrying a recorded one. |
| 🔍 `diagnosis.md` | ✅ Same — extracted from a working methodology, not written from spec. |
| 💾 `memory-update.md` | ✅ Same. |
| ✅ `check.sh` | ✅ Runs, and has caught real holes in this repository. |
| 🚪 `spec-gate.md` | ⚠️ Written from spec. Zero executions. |
| 👥 `team-contract.md` | ⚠️ Written from spec. Zero executions. |
| 🥾 `bootstrap.md` | ⚠️ Written from spec. Zero executions. |
| 🕵️ `evidence-reviewer.md` | ⚠️ Written from spec. Zero executions. |
| 🔄 `update-kit.sh` | ⚠️ Written from spec. Zero executions. |
| 🎚️ The `T0`/`T1`/`T2` tier system | ⚠️ Never exercised. The tags are annotation so far. |

The install above is derived from the layout, not from an install anyone has
walked. 🧗 Whoever runs it first is on new ground — record the friction, because
that record is what this section should have been.

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
