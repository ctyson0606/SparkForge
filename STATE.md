# STATE

> Last updated: 2026-08-19

Current working state. Superseded content is deleted, not archived.
For durable rules see METHOD.md.

Every line here must be something no command answers. Length follows from how
much of that there is.

<!--
Do not write into this file:
  - anything the repo already answers: file lists, route lists, branch,
    commit, whether something is pushed
  - any claim that the act of committing makes false, e.g. "not yet pushed"
-->

## Current Focus

SparkForge has started using its own method: this file and METHOD.md at the
repository root are its memory, kept separate from the empty shells under
template/.

Nothing in the framework has been used on a real project yet. Every rule in
kit/skills/ was transferred from a previous project's methodology; none of it
has been tested in the shape it now has.

## Next Steps

- Run the framework on a project from its first commit and find out which
  rules earn their place and which are never reached. Record the friction of
  the install itself: that record is what the README's install section will
  be.
- Design controls for the rules labelled `Rationale:` in
  kit/skills/verification.md — they are the ones no incident has tested.

## Open Questions

- Kimi Code's project-level skill directory is unconfirmed, and reading more
  documentation will not settle it: the CLI's own repository says
  `.kimi/skills/` while the product page says `.kimi-code/skills/`, and a path
  that is correct but not loaded looks exactly like a path that is wrong.
  Resolve by loading instead: put stubs under a candidate directory, run Kimi
  Code, and see whether the skills appear in its own list. This session showed
  what that looks like — Claude Code rescanned template/.claude/skills/ and
  listed every skill it found there, with no other configuration, which is the
  observation to reproduce. Note that the brand group is documented as
  mutually exclusive, so a `.kimi/` directory would take over from `.claude/`
  rather than supplement it.

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

Also, none of them rules:

- The tier system has never been executed. MODE has been project throughout,
  the T1/T2 degradation path has never been taken, and the tier tags are
  annotation so far.
- These components have zero executions: spec-gate, team-contract, bootstrap,
  evidence-reviewer, update-kit.sh.
- The `@GOTCHAS.md` import in AGENTS.md has not been tested on its own. The
  import mechanism works here, but that line is written correctly and
  unproven. To settle it: put one recognisable line in template/GOTCHAS.md,
  open a session, and see whether it arrives in context. That is a next-time
  errand, not something to schedule.
- A candidate rule, not yet written: a rule's boundary only becomes visible
  the first time it is actually applied, and that boundary has to be written
  back or the next reader applies it too literally. Three instances so far —
  the restore point in the sabotage rule, the scope of the rule about counts,
  and that same rule again when applying it deliberately showed it would
  strike numbers out of an evidence block. All in this repository, all within
  one week. Promoting it needs an instance in a different rule system, not
  another one in this METHOD.md.
- Everything to watch for at the first install is an instance of one question,
  whether the condition was put in the right place: whether bootstrap fires by
  itself, whether anyone thinks to change the title in AGENTS.md, whether the
  agent goes and reads spec-gate on its own when it touches auth or a
  migration. All three are the shape of the same candidate rule, and what that
  rule needs is exactly a different rule system.

## Known Annoyances

- The working tree's file mode is not real here, so an executable bit has to
  be set with `git update-index --chmod=+x` rather than `chmod`.
- `template/.gitattributes` cannot be verified in place, because the root
  file's attributes are inherited by everything under it. The checker copies
  it to a throwaway repository to get an answer that can differ.
- Nothing checks the tier tags or the evidence labels in the root METHOD.md.
  Those two checks scan template/kit/skills only, while the root file uses the
  same grammar and now carries three rules. A consuming project does not have
  this file, so no number of real projects will ever run into it.

## Recent Decisions

Only decisions that still steer the work. Anything already settled into a rule
in METHOD.md, or visible in the code itself, has been dropped from here.

- Three holes so far had one shape: a check that could not fail. Every one sat
  where a check or a procedure depended on someone remembering a convention.
  That is where to look for the next one.
- The parts of kit/ with evidence behind them and the parts never executed
  divide exactly along how they were written: everything transformed from the
  source methodology has been walked, and everything written from spec has run
  zero times. The next step is a real project, not more features.
- A rule earns a place in kit/ when its evidence spans more than one project
  and it describes the framework rather than a stack; otherwise it stays in
  this repository's own METHOD.md. The platform rule is the open case — three
  incidents, all on one platform and one toolchain. Promoting it needs a
  second project to reproduce it.
