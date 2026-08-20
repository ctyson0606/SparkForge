# SparkForge (the framework repository)

This is SparkForge itself, not a project using it. Every tool's entry file in
this repository points here, and this file is the only place that routes.

## Two roots, and they must not be confused

`METHOD.md` and `STATE.md` at this repository root are SparkForge's own memory.
They hold real rules, earned by developing the framework.

`template/METHOD.md`, `template/STATE.md` and `template/GOTCHAS.md` are the
empty shells copied into a project that adopts the framework. They stay empty.
Writing a rule into one of them has no symptom — the copy still works, it just
arrives carrying knowledge that belongs to SparkForge's development rather than
to the project reading it. `scripts/check-repo.sh` is what catches that.

## Layout

`template/` is what a consuming project receives; its contents become that
project's root. Inside it, `kit/` holds the canonical skills and agents, and
each tool directory holds thin stubs pointing into `kit/`. Edit `kit/`, never
the stubs.

`source/METHOD.md` is the methodology these rules were transformed from.

## Checks

Run `scripts/check-repo.sh` after any change. It runs the shipped checker
against `template/` first, then the checks that belong only to this repository.

## Memory

@METHOD.md
@STATE.md
