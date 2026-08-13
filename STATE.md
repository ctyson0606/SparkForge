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

## Known Annoyances

- The working tree's file mode is not real here, so an executable bit has to
  be set with `git update-index --chmod=+x` rather than `chmod`.
- `template/.gitattributes` cannot be verified in place, because the root
  file's attributes are inherited by everything under it. The checker copies
  it to a throwaway repository to get an answer that can differ.

## Recent Decisions

- The verification rules were split in two: verification.md judges whether a
  result is evidence, diagnosis.md pursues a failure that has already
  appeared. Each file carries one pointer to the other rather than a second
  copy of the overlap.
- Classification and update semantics live only in METHOD.md.
  kit/skills/memory-update.md points at them and deliberately does not
  restate them, because the rule belongs where the decision is made.
- The agent's tool restriction is mirrored into its stub, because the stub is
  the copy the tool actually loads. The mirror is a known duplication held in
  step by the checker rather than by anyone remembering.
- Checks are split by where they can still fail. The shipped checker holds
  only what remains meaningful after the template has been copied; anything
  guarding this repository's own shape moved to scripts/check-repo.sh, which
  runs the shipped one first and stops if it fails.
- Two holes were closed, and both had the same shape: a check that could not
  fail. The evidence-label invariant ended a rule at a trailing comment, so a
  rule written without one was never counted; it now ends at the next heading
  or at end of file. The sabotage rule named the last commit as the restore
  point, which is not a restore point for content that is not committed yet;
  it now says to stage first. Where a check or a procedure depends on someone
  remembering a convention, that is where to look for the next one.
- The rule about correcting a falsified claim went into kit/, not into this
  repository's METHOD.md: its evidence spans two projects, and it describes
  the structure of a memory file rather than any stack. The rule about a
  platform being unable to report its own output stayed here by the same
  test — all three incidents are on one platform and one toolchain, so it
  has no cross-project evidence yet. Promoting it needs a second project to
  reproduce it.
