# SparkForge

## Declarations
MODE: project        # project | sprint
TEAM: 1

## Environment facts
install:
dev:
test:
typecheck:
lint:
build:
e2e:
# Leave blank if not yet established. Write "none" if this project
# genuinely has no such command — "none" is itself a finding and must
# be reported in any verification, not silently skipped.

## Hard rules (always apply, regardless of tier)
- Stop and ask when a requirement is vague. Do not fill the gap with an assumption.
- Stop when the scope changes. Do not finish the larger thing you found.
- No completion claim without evidence: commands run, output, residual risk.
- Touch only the files in the agreed scope. Say so if anything else changed.
- Before automating a manual action, count how many items and how often.
- When proposing something larger than what was asked, first state why the
  smaller version is insufficient.

## Tiers
T0  free — do it under any time pressure
T1  moderate cost — advisory when MODE is sprint
T2  expensive — skipped when MODE is sprint

## Skill routing

(empty)

## Canonical content

kit/ holds the canonical content. Each tool-specific directory
(.claude/, and one per additional agent tool) holds thin stubs that
point into kit/. Edit kit/, never the stubs.
Do not edit anything under kit/ inside a project that consumes
this framework — send the change upstream and pull it back with
scripts/update-kit.sh. This project's own knowledge lives only in
METHOD.md, STATE.md and GOTCHAS.md, which are never overwritten.

## Memory
@METHOD.md
@STATE.md
