# STATE

> Last updated: 2026-08-12

Current working state. Superseded content is deleted, not archived.
For durable rules see METHOD.md.

<!--
Do not write into this file:
  - anything the repo already answers: file lists, route lists, branch,
    commit, whether something is pushed
  - any claim that the act of committing makes false, e.g. "not yet pushed"
-->

## Current Focus

The template is structurally complete: memory shells, six skills, one agent,
per-tool stubs, and a shipped checker holding thirteen invariants. Two further
checks stay in this repository, in scripts/check-repo.sh, because what they
guard does not exist in a project that consumes the framework. SparkForge has
started using its own method — this file and METHOD.md at the repository root
are its memory, kept separate from the empty shells under template/.

The stub layout is confirmed for one tool: an agent harness reading
template/.claude/skills/ picked up all six skills from their SKILL.md stubs
without any other configuration.

Nothing in the framework has been used on a real project yet. Every rule in
kit/skills/ was transferred from a previous project's methodology; none of it
has been tested in the shape it now has.

## Next Steps

- Run the framework on a project from its first commit and find out which
  rules earn their place and which are never reached.
- Design controls for the two rules labelled `Rationale:` in
  kit/skills/verification.md — they are the ones no incident has tested.

## Open Questions

- Kimi Code's project-level skill directory is unconfirmed. The CLI's own
  repository documentation says `.kimi/skills/`; the product documentation
  page says `.kimi-code/skills/`. No stub has been created for either. The
  brand group is documented as mutually exclusive, so adding `.kimi/skills/`
  would take over from `.claude/skills/` rather than supplement it, and a
  skill added only to `.claude/` would then be invisible with no error.
  Resolve by running Kimi Code once and observing whether the skills load.

## Unverified

This repository does not contain the situations these rules describe, so none
of them has ever been walked. The first real project ticks this list off.

- A UI that can be driven: 6 — selectors, text scoping, stale coordinates,
  waiting on a loaded-only signal, which render variant is mounted.
- A test suite: 3 — what a green run covers, shape over presence, thresholds
  the codebase can defend.
- A deployment, a network, a second machine: 5 — production numbers,
  transport floors, a toolchain version invisible in the diff.
- Intermittent failure: 4 — measuring a rate, a flake beside your own change,
  fixing timing rather than retrying, rates differing across machines.
- A scheduled job, an external service, concurrent writes, runtime logs: 4 —
  observation windows, credential provenance, who is awake, logging the call.
- Live data, a timing-sensitive probe, subagents, translated documentation,
  TEAM > 1, MODE sprint: 5 rules and 2 modes needing a project shaped for them.

Three more, none of them rules:

- The tier system has never been executed. MODE has been project throughout,
  the T1/T2 degradation path has never been taken, and the 38 tags are
  annotation so far.
- Five components have zero executions: spec-gate, team-contract, bootstrap,
  evidence-reviewer, update-kit.sh.
- The `@GOTCHAS.md` import in AGENTS.md has not been tested on its own. The
  import mechanism works here, but that line is written correctly and unproven.

## Known Annoyances

- The working tree's file mode is not real here, so an executable bit has to
  be set with `git update-index --chmod=+x` rather than `chmod`.
- `template/.gitattributes` cannot be verified in place, because the root
  file's attributes are inherited by everything under it. The checker copies
  it to a throwaway repository to get an answer that can differ.

## Recent Decisions

Only decisions that still steer the work. Anything already settled into a rule
in METHOD.md, or visible in the code itself, has been dropped from here.

- Three holes so far had one shape: a check that could not fail. Every one sat
  where a check or a procedure depended on someone remembering a convention.
  That is where to look for the next one.
- The parts of kit/ with evidence behind them and the parts never executed
  divide exactly along how they were written: everything transformed from the
  source methodology has been walked, and all five components written from
  spec have run zero times. The next step is a real project, not more
  features.
- A rule earns a place in kit/ when its evidence spans more than one project
  and it describes the framework rather than a stack; otherwise it stays in
  this repository's own METHOD.md. The platform rule is the open case — three
  incidents, all on one platform and one toolchain. Promoting it needs a
  second project to reproduce it.
