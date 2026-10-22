<!-- Hero -->
<div align="center">
  <h1>🔥 SparkForge</h1>
  <p><b>A workflow framework for AI coding agents</b>: copied into a new project, it gives the agent a memory that accumulates and a method for judging whether evidence holds, and carries no project knowledge of its own.</p>
  <p>
    <img alt="for: AI coding agents" src="https://img.shields.io/badge/for-AI%20coding%20agents-4d6bfe">
    <img alt="shell: bash" src="https://img.shields.io/badge/shell-bash-4d6bfe">
    <img alt="dependencies: git, bash, awk" src="https://img.shields.io/badge/dependencies-git%2C%20bash%2C%20awk-brightgreen">
    <img alt="license: MIT" src="https://img.shields.io/badge/license-MIT-blue">
  </p>
  <p>🌏 <a href="./README.zh-CN.md">简体中文</a> · <a href="./README.zh-TW.md">繁體中文</a> · English</p>
</div>

<p align="center"><img src="docs/progress-page.png" alt="The progress page of a project using SparkForge" width="720"></p>

## ✨ Features

- **Memory that accumulates**: `SPEC.md`, `METHOD.md`, `STATE.md` and `GOTCHAS.md` load into every session, and the agent writes them the moment something changes, not when asked.
- **One instruction, every tool**: Claude Code, Cursor, Copilot, Gemini CLI, Cline, Windsurf, Codex CLI, Amp and DeepSeek Harness all start from `AGENTS.md`.
- **A spec gate**: a feature starts as a problem, goals and acceptance criteria that a person approves, and anything touching auth, payments, secrets or migrations cannot skip it.
- **Evidence that holds**: rules taken from real incidents for judging whether a green run proves anything, and for chasing a failure to its cause.
- **A progress page**: one command builds a page from the spec, the state and git — criteria with their evidence, a roadmap, a features guide, the components, and a timeline of the work, in English and one more language.
- **Checks that can fail**: `scripts/check.sh` verifies the layout, the stubs, the executable bits, the README editions and the README's own claims about the repository.
- **Updates from upstream**: `scripts/update-kit.sh` replaces `kit/` and names anything an update needs outside it.

## 🚀 Installation

Prerequisite: git and bash. On Windows that is Git Bash, which comes with Git for Windows.

**Option 1 · Git Bash, macOS or Linux**

```bash
# Copy the whole template. "template/." and not "template/*", or .claude/,
# .cursor/, .github/ and .gitattributes are silently left behind
cp -R "/path/to/SparkForge/template/." "/path/to/my-project/"
cd "/path/to/my-project"
git init

# Replace the first line of AGENTS.md, "# SparkForge", with your project's
# name before staging anything

# Stage, then set the executable bit in the index: on Windows the working
# tree's mode is not real, so chmod cannot do it
git add -A
git add --chmod=+x -- 'scripts/*.sh' 'kit/scripts/*.sh'
git commit -m "Adopt SparkForge"
```

**Option 2 · from PowerShell**

<details>
<summary>Use this when you would rather stay in PowerShell</summary>

`bash` typed into PowerShell resolves to `C:\Windows\System32\bash.exe`, WSL's launcher, which fails with `execvpe(/bin/bash) failed` when no distribution is installed. Call the bash that ships with Git instead:

```powershell
# Where Git lives; it is not always on C:
(Get-Command git).Source

# The & is required: without it PowerShell prints the quoted path
& "C:\Program Files\Git\bin\bash.exe" scripts/check.sh
```

</details>

**Verify**

```bash
git ls-files -s -- 'scripts/*.sh' 'kit/scripts/*.sh'
bash scripts/check.sh
```

Every line of the first command begins with `100755`, and the second ends with `check.sh: all checks passed`.

## 🕹️ Usage

### The first session

Open your agent and ask it to **run bootstrap**; it does not start by itself. Bootstrap runs once and:

1. stages the scripts with their executable bit;
2. asks for `MODE` and `TEAM` and writes them into `AGENTS.md`;
3. fills in the Environment facts one by one, writing `none` where the project has no such command;
4. runs the spec gate at the depth `MODE` selects;
5. writes the result into `SPEC.md` and points `STATE.md` at what is built first;
6. **leaves `METHOD.md` empty**: rules are earned from traps the project hits, never guessed.

### Every day after

Memory loads itself: the entry file imports `AGENTS.md`, which imports the four memory files. The agent reaches for a skill by situation:

| When you are… | The skill | In one line |
| --- | --- | --- |
| 🚪 about to build a feature | `kit/skills/spec-gate.md` | Restate the requirement as a problem, ask only blocking questions, write goals, non-goals, criteria and the contract, then stop for approval. |
| 🧪 looking at a green run | `kit/skills/verification.md` | A suite that passes on its first run is unverified. Break the code on purpose and watch the right tests fail. |
| 🔍 chasing a failure | `kit/skills/diagnosis.md` | An intermittent failure has a rate, and one run does not measure it. |
| 👥 working with others | `kit/skills/team-contract.md` | Agree once on the contract and on who owns which directories. |
| 💾 writing memory | `kit/skills/memory-update.md` | Write the moment state changes; re-read the whole file first. |
| 📝 writing the README | `kit/skills/readme.md` | This page's shape, in three editions, with the layout and the commands checked. |

### The spec gate is not optional here

Whatever `MODE` says, the gate runs for any change touching 🔐 authentication, 🛡️ authorisation, 💳 payments, 🔑 secrets, 🗄️ database migrations, or 🌐 more than one service.

### How memory behaves

- **Written as you go**: a step done, a decision made, a trap hit — written at once, because a session can stop without warning.
- **`METHOD.md` accumulates**: a rule is corrected in place, never contradicted by a second one.
- **`STATE.md` is replaced**: what is no longer true is deleted; git holds the history.
- **A claim your change made false is fixed in the same step** as the change.

### The progress page

```bash
bash scripts/progress.sh
```

It reads `SPEC.md`, `STATE.md` and git, stores nothing, and so cannot go stale. Set `TRANSLATION` in `AGENTS.md` for a second language: the agent writes the translations when you ask it to open the page, and the browser can machine translate the rest.

### Updating

```bash
bash scripts/update-kit.sh
bash scripts/check.sh
```

The first replaces `kit/` and lists anything new the update needs outside it; the second confirms the result. Something that belongs to SparkForge rather than to your project goes under `Upstream` in your `STATE.md`, where `scripts/collect-upstream.sh` in a SparkForge checkout next to it reads it.

## 🚪 One instruction, every tool

Each tool that will not find `AGENTS.md` by itself has a small file at the path it does read, saying only where to go. ⚠️ Never put an instruction in one of them: two tools reading two sets of rules is the failure this prevents. Not using a tool? Delete its entry.

| Tool | Its file | How it loads |
| --- | --- | --- |
| 🤖 Claude Code | `CLAUDE.md` | `@AGENTS.md`, a real import |
| ✏️ Cursor | `.cursor/rules/sparkforge.mdc` | `alwaysApply: true` |
| 🐙 GitHub Copilot | `.github/copilot-instructions.md` | a path it always reads |
| 💠 Gemini CLI | `GEMINI.md` | a path it always reads |
| 🧵 Cline | `.clinerules` | a path it always reads |
| 🏄 Windsurf | `.windsurfrules` | a path it always reads |
| 🌊 Codex CLI, Amp, DeepSeek Harness | `AGENTS.md` itself | read natively |

## 🧰 What a project receives

| File | What it is for |
| --- | --- |
| ⚙️ `AGENTS.md` | The entry point and the only file that routes: declarations, Environment facts, hard rules, the skill table. |
| 📐 `SPEC.md` | The approved contract. Changed only through the spec gate. |
| 🧠 `METHOD.md` | Rules this project earned. Starts empty. |
| 📌 `STATE.md` | Where the work stands. Replaced, never appended to. |
| 🐛 `GOTCHAS.md` | Version-bound traps, each dated. |
| 📚 `kit/` | The framework itself. Never edited in a project; overwritten on update. |
| 🪝 `.claude/` | Stubs, each pointing into `kit/`. |
| ✅ `scripts/` | Stubs for `check.sh`, `update-kit.sh` and `progress.sh`, handing over to `kit/scripts/`. |

## 🌡️ Maturity

Stated plainly, because the framework's own method insists on it. It has been installed in five projects: four on Windows and one in a Linux container. One, a desktop tool, was built through every acceptance criterion and is in daily use.

| Component | Standing |
| --- | --- |
| 🧪 `verification.md`, 🔍 `diagnosis.md`, 💾 `memory-update.md` | ✅ Extracted from real incidents; several rules carry incidents from two or three projects. |
| ✅ `check.sh`, 🔄 `update-kit.sh` | ✅ Run in every project; `update-kit.sh` has replaced itself mid-run without a trace. |
| 🥾 `bootstrap.md`, 🚪 `spec-gate.md` | 🟡 Written from a specification and run in every project, the gate always as bootstrap's fourth step, never yet on its own. |
| 📊 The progress page | 🟡 Installed everywhere; seen in use on one project. |
| 📝 `readme.md` | 🟡 New. This page was its first use. |
| 🚪 The tool entry files | 🟡 Claude Code's is watched working; the others ask the agent to open `AGENTS.md` and have not been opened. |
| 👥 `team-contract.md`, 🕵️ `evidence-reviewer.md`, 🎚️ the T0/T1/T2 tiers | ⚠️ Never exercised. |

## 🛠️ Development and testing

This repository holds the framework; `template/` is what a project receives. After any change:

```bash
bash scripts/check-repo.sh
```

Before choosing what to work on, read what the projects next to this checkout recorded:

```bash
bash scripts/collect-upstream.sh
```

## 📦 Project layout

```text
template/
template/kit/skills/
template/kit/scripts/
template/kit/readme-skeleton.md
scripts/check-repo.sh
scripts/collect-upstream.sh
source/METHOD.md
METHOD.md
STATE.md
docs/progress-page.png
```

- `template/`: what a project copies in; its contents become the project's root;
- `template/kit/skills/`: the canonical skills, one file each;
- `template/kit/scripts/`: the checker, the updater and the progress page;
- `template/kit/readme-skeleton.md`: this page's shape, to copy;
- `scripts/check-repo.sh`: runs the shipped checker on `template/`, then the checks only this repository needs;
- `scripts/collect-upstream.sh`: lists every project beside this checkout, whether its `kit/` is current, and its `Upstream`;
- `source/METHOD.md`: the methodology the rules were transformed from;
- `METHOD.md`, `STATE.md`: SparkForge's own memory, kept apart from the empty shells in `template/`;
- `docs/progress-page.png`: the screenshot above.

## ⚠️ Compatibility and limits

- Written on Windows and walked in a Linux container; never run on macOS, though the scripts are written for its bash 3.2 and BSD awk.
- No task tracking, kanban or task cards.
- No scan of an existing codebase: SparkForge is for projects that adopt it from their first commit.
- No design for non-software work, no UI design system, no mockup gate.
- No module whose value depends on the whole team adopting it.

## ❓ FAQ

| Symptom | What to do |
| --- | --- |
| `execvpe(/bin/bash) failed` in PowerShell | That is WSL's launcher, not Git Bash; use Git Bash, or Option 2 above |
| `check.sh` says a shell script is not executable in the index | `git add --chmod=+x` the file it names; `chmod` cannot set it on Windows |
| `.claude/` or `.github/` missing after the copy | The copy used `template/*`; copy `template/.` again |
| `update-kit.sh` cannot fetch the upstream | It never waits on a login; pass the SSH URL it prints |
| `check.sh` fails right after an update | The update needs something outside `kit/`; follow the hint on each failing line |
| The progress page is English with EN tags | Ask the agent to open the page, or use the page's translate button |

## 📄 License

MIT, see [LICENSE](LICENSE).
