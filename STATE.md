# STATE

> Last updated: 2026-08-20

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

SparkForge uses its own method: this file and METHOD.md at the repository root
are its memory, kept separate from the empty shells under template/.

The framework is structurally finished and has never been used. What remains
before a real project is nothing; what a real project will find is everything.

kit/ has two halves with different standing, and the split is by how each was
written rather than by what it covers. verification, diagnosis and
memory-update were transformed from a previous project's methodology and carry
its incidents. spec-gate, team-contract, bootstrap and evidence-reviewer were
written from a specification and have never run. An earlier version of this
section claimed every rule in kit/skills/ came from the methodology, which was
never true.

## Next Steps

- Run the framework on a project from its first commit and find out which
  rules earn their place and which are never reached. Record the friction of
  the install itself: that record is what the README's install section will
  be.
- Design controls for the rules labelled `Rationale:` in
  kit/skills/verification.md — they are the ones no incident has tested.
- Settle the two loading questions below by opening the tools, not by reading
  more documentation about them.

## Open Questions

- Kimi Code's project-level skill directory is unconfirmed, and reading more
  documentation will not settle it: the CLI's own repository says
  `.kimi/skills/` while the product page says `.kimi-code/skills/`, and a path
  that is correct but not loaded looks exactly like a path that is wrong.
  Resolve by loading instead: put stubs under a candidate directory, run Kimi
  Code, and see whether the skills appear in its own list. Claude Code
  rescanned template/.claude/skills/ and listed every skill it found there
  with no other configuration, which is the observation to reproduce. Note
  that the brand group is documented as mutually exclusive, so a `.kimi/`
  directory would take over from `.claude/` rather than supplement it.
- DeepSeek Harness is believed to need no entry file, because its
  agent-instructions plugin is documented as loading AGENTS.md and CLAUDE.md
  by itself. That is read from its config catalogue and has not been watched
  happening. It is the same shape as the Kimi Code question and settles the
  same way: open it in a project carrying AGENTS.md and see whether the
  contents arrive.

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
  evidence-reviewer.
- update-kit.sh has now run, but only against a throwaway upstream and a
  throwaway project built for the occasion. It has never pulled a real change
  from a real remote into a project that was using it, and the destructive
  half — removing kit/ before replacing it — has never run over content
  anyone would miss.
- Four of the six tool entries work by putting a file where the tool is
  expected to look and trusting it to obey the prose inside. Only the Claude
  Code import and the Cursor alwaysApply flag are mechanisms the loader
  itself honours. None of the four has been watched loading, and a tool that
  silently ignores its entry is indistinguishable from one that has no entry.
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
  A fourth candidate was examined and rejected: the boundary in the entry
  point check, that one missing entry is allowed and all of them missing is
  not, was settled while the check was being written rather than discovered
  later by someone applying it. Keeping design-time decisions out is what
  stops the rule widening into "write down your edge cases", which would make
  it true of everything and useful for nothing.
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
  same grammar. A consuming project does not have this file, so no number of
  real projects will ever run into it.
- The README check has the same blind spot and is louder about it: it globs
  the template directory, finds no README there at all, and reports that there
  is only one and nothing to compare, while the translations that do exist sit
  at the repository root outside its reach. Their agreement is asserted by
  hand, against the contract that check would have applied.
- The README also restates the project layout, the bootstrap procedure and
  the execution record of several components, and nothing diffs any of them
  against the files they describe. They are checked by hand when someone
  remembers to, which is how all three went false at once.

## Recent Decisions

Only decisions that still steer the work. Anything already settled into a rule
in METHOD.md, or visible in the code itself, has been dropped from here.

- Every hole found so far has been a check that could not fail, and each sat
  where a check or a procedure depended on someone remembering a convention.
  That is still where to look for the next one. Three questions have each
  produced a rule and are worth asking again: what does this checker's root
  exclude, what is this check forbidden to complain about, and what did this
  document restate.
- A gap that only appears when two versions meet cannot be closed by anything
  that inspects one version. That is why the entry point warning lives in
  update-kit.sh and not in check.sh, and it is worth remembering the next time
  a check looks like it ought to catch something and cannot.
- A rule earns a place in kit/ when its evidence spans more than one project
  and it describes the framework rather than a stack; otherwise it stays in
  this repository's own METHOD.md. The platform rule is the open case — three
  incidents, all on one platform and one toolchain. Promoting it needs a
  second project to reproduce it.
