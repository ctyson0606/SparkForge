# STATE

> Last updated: 2026-10-01

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

Three projects have adopted the framework, all on Windows, all in sibling
directories of this repository: ../GameBrake, the first install, a C# tray tool
built through every acceptance criterion of its v1 and in daily use;
../LearningProject, a Markdown-only template for learning projects; and
../dsh/dsh-docker+remote-access, which merges two Docker repositories into one
public one. ../TempTime never adopted it, but source/METHOD.md is a copy of its
METHOD.md, and it kept growing afterwards. A survey of all four on 2026-10-01
is where most of the Next Steps below came from.

kit/ has two halves with different standing, and the split is by how each was
written rather than by what it covers. verification, diagnosis and
memory-update were transformed from TempTime's methodology and carry its
incidents. spec-gate, team-contract, bootstrap and evidence-reviewer were
written from a specification; bootstrap and spec-gate have now run in all three
projects, the other two in none.

## Next Steps

- Memory does not load in DeepSeek Harness; see Open Questions. Unsolved. The
  obvious patch is rejected in METHOD.md, Anti-Patterns.
- scripts/check.sh and scripts/update-kit.sh have no update path. update-kit.sh
  writes only kit/, so a fix to either script reaches projects installed after
  it and none installed before. The .ps1 path check found in GameBrake does
  not reach GameBrake, and dsh keeps check.sh as its test command. The
  Environment facts comment in AGENTS.md has the same standing, by design,
  since AGENTS.md belongs to the project.
- The count rule is not yet promotable, and should not be promoted early: its
  only incidents are this repository's. GameBrake's STATE.md and READMEs carry
  test counts nothing keeps in step, and GameBrake recorded that as a gap, but
  on 2026-10-01 every one of them still matched its tests. The day one of them
  is found wrong is the second project.
- `diff source/METHOD.md ../TempTime/METHOD.md` shows what TempTime learned
  after the copy was taken. Of its verification-shaped rules, aiming the
  scenario and fixtures sharing their author's assumptions are now in kit, each
  with a GameBrake incident beside TempTime's. Three wait for a second
  incident. A selective change needing a neighbour it must not touch:
  GameBrake built one in (AC6) but nothing ever went wrong there. Confirming a
  deploy with something only the new build does: no other project has deployed
  and checked. A probe spending someone else's budget: GameBrake's e2e script
  overwrites the real config, and dsh's test stacks share one volume, but
  neither has recorded any damage, which is the bar the count rule was held to.
- Design controls for the rules labelled `Rationale:` in
  kit/skills/verification.md — they are the ones no incident has tested.
- Settle the Kimi Code question below by opening the tool, not by reading more
  documentation about it.

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
- DeepSeek Harness loads AGENTS.md and not the memory. Read on 2026-10-01 in
  the README of @deepseek-ai/dsh-agent-instructions 0.2.0-rc.2, its instruction
  loader: it loads AGENTS.md and CLAUDE.md, plus .local overlays, in every
  directory from the project root down to the working directory; adds nested
  ones once a file beneath them is touched; caps the whole at a byte budget,
  65,536 by default, by dropping broader files first; and does not interpret
  @path imports. So it needs no entry file, and METHOD.md, STATE.md and
  GOTCHAS.md never load there. The one lever the loader offers is its
  instructionFileCandidates list, which could name the memory files, but that
  lives in the user's DSH profile rather than in the project, so the framework
  cannot ship it. Untried. All of this is read, not watched.
- Every tool entry except Claude Code's reaches AGENTS.md only by asking the
  agent to open it. Cursor's alwaysApply loads the pointer, not the file it
  points at. That is the same request the rejected memory patch made, and the
  agent ignored it there, so whether those tools ever get AGENTS.md is now
  doubtful rather than merely unobserved. None of the five has been opened.
- Bootstrap puts the spec into STATE.md, which is replaced as work moves on,
  yet a spec is a contract that stays. GameBrake's STATE.md still carries its
  whole v1 spec after v1 shipped, and its memory files together are already
  past half of DeepSeek Harness's default budget.

## Unverified

Rules no project has walked yet. GameBrake walked shape over presence (an exact
key set caught a serialised property that could not be read back), what a green
run covers (the suite ran Debug output while a published single file shipped),
and translated documentation (check.sh refused a translated fence), so those
are off the list.

- A UI that can be driven — selectors, text scoping, stale coordinates,
  waiting on a loaded-only signal, which render variant is mounted.
- A test suite — thresholds the codebase can defend.
- A deployment, a network, a second machine — production numbers,
  transport floors, a toolchain version invisible in the diff.
- Intermittent failure — measuring a rate, a flake beside your own change,
  fixing timing rather than retrying, rates differing across machines.
- A scheduled job, an external service, concurrent writes, runtime logs —
  observation windows, credential provenance, who is awake, logging the call.
- Live data, a timing-sensitive probe, subagents, TEAM > 1, MODE sprint —
  rules and modes needing a project shaped for them.

Also, none of them rules:

- The tier system has never been executed. MODE has been project and TEAM 1 in
  every install, the T1/T2 degradation path has never been taken, and the tier
  tags are annotation so far.
- These components have no recorded execution in any project: team-contract,
  evidence-reviewer.
- bootstrap has run in all three projects and does not fire by itself; it is
  asked for by name. In the first it stopped at the spec gate for want of a
  requirement, which is the hard rule about vague requirements firing rather
  than a fault.
- spec-gate has produced its four artifacts in all three projects, and
  GameBrake's run also recorded its assumptions as the second step asks. Every
  recorded run was bootstrap's step 4. The gate has never been seen firing on
  its own.
- update-kit.sh has run only against a throwaway upstream and a throwaway
  project built for the occasion. It has never pulled a real change from a real
  remote into a project that was using it, and the destructive half — removing
  kit/ before replacing it — has never run over content anyone would miss.
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
- Two of the three watch-for questions are still open. Whether anyone changes
  the title in AGENTS.md unprompted is unknown: the first reader was told to,
  and the other two installs left no record either way. Whether an agent
  reaches for spec-gate on its own when it touches auth or a migration is
  unanswered: GameBrake touched neither, and dsh's whole
  subject is auth and secrets but its gate ran inside bootstrap. Both remain
  the shape of the same candidate rule.

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
  remembers to, which is how all three went false at once. Two are false now:
  its maturity section says nothing has crossed the spec gate, and it says
  memory loads by itself, which is not so in DeepSeek Harness. The second is
  deliberately left out of the README; see Recent Decisions.
- Reading a file under template/ makes Claude Code load template/CLAUDE.md
  and its import chain into the session working on this repository. That
  brings in a second AGENTS.md titled "# SparkForge", whose rules include not
  editing kit/, which is this repository's whole job. Watched on 2026-10-01,
  which also settled that the @GOTCHAS.md import works. DeepSeek Harness
  documents the same nested loading. LearningProject hit it with its own
  template and put a guard at the top of the template's AGENTS.md. The same
  guard was tried here and measured: asked after reading a template file
  whether template/AGENTS.md's rules bound the session, Claude Code said no in
  4 of 4 runs with the guard and 4 of 4 without, including with this note
  removed. The "Two roots" section of the root AGENTS.md was what it reasoned
  from. A local qwen3.6:27b, given the same files through Ollama and asked
  whether a new skill belonged directly under template/kit/, answered
  directly in 3 of 3 runs either way. deepseek-r1:32b was started and stopped
  before it answered. No misbehaviour from the nested load has been seen, so
  the guard was not added: it would ship into every project's AGENTS.md to
  answer nothing measured.
- Claude Code drops HTML comments from a file it loads through an import, so
  the comment at the top of this file is not in the session's opening context
  and is seen only when the file is opened to edit. That is when it is needed.
- Nothing carries a finding upstream. GameBrake marked one for sending and
  never sent it; it reached this repository only because a survey went and
  read GameBrake's STATE.md. For over a month before that, this file and the
  README said nothing had crossed the spec gate while GameBrake was finished.
  The return path is a paragraph in AGENTS.md: a procedure that depends on
  someone remembering,
  which is where every hole so far has been found.

## Recent Decisions

Only decisions that still steer the work. Anything already settled into a rule
in METHOD.md, or visible in the code itself, has been dropped from here.

- Every hole found so far has been a check that could not fail, and each sat
  where a check or a procedure depended on someone remembering a convention.
  That is still where to look for the next one. Three questions have each
  produced a rule and are worth asking again: what does this checker's root
  exclude, what is this check forbidden to complain about, and what did this
  document restate.
- The first use-driven change came from one install on one machine, and three
  of its four findings were assumptions about the reader's environment. Expect
  the next batch to have that shape too, and to arrive from the first machine
  that is not this one.
- The consuming project's agent checked a claim sent downstream from here,
  found it did not hold, and said why with the command that showed it. The
  arrangement runs in that direction as well as the intended one, so a claim
  worth sending down is worth phrasing so it can be checked rather than
  believed.
- A gap that only appears when two versions meet cannot be closed by anything
  that inspects one version. That is why the entry point warning lives in
  update-kit.sh and not in check.sh, and it is worth remembering the next time
  a check looks like it ought to catch something and cannot.
- A rule earns a place in kit/ when its evidence spans more than one project
  and it describes the framework rather than a stack; otherwise it stays in
  this repository's own METHOD.md. Promoting one moves it: the kit copy holds
  the rule and the evidence, and the entry here shrinks to a pointer, so there
  is never a second copy to drift. The platform rule went first, on evidence
  from TempTime, dsh and this repository, every instance of it on Windows;
  then the restatement rule, on this repository and TempTime.
- Memory loading in tools that do not resolve @ imports stays unsolved rather
  than patched with prose. The patch was built, measured, rejected and
  reverted on 2026-10-01; the reasons are in METHOD.md. By the user's decision
  the README does not carry this finding.
- Memory is written as you go, all three files, the moment state changes —
  reversed from request-only on 2026-10-01 by the user's decision, on
  LearningProject's reason: a quota running out mid-conversation leaves no
  moment to ask, and the next agent starts from whatever was last written. It
  applies to this repository's memory as well. The trigger has to sit in
  AGENTS.md's hard rules, since the skill is read only once memory is already
  on the agent's mind. It is still prose asking for an unprompted action, the
  shape METHOD.md's anti-pattern warns about, so it was measured. In a scratch
  copy, Claude Code was asked to create a file and told what would come next
  time, with nothing said about memory: under the new rule it wrote that next
  step into STATE.md in 2 of 2 runs, under the old one in 0 of 2, one of which
  said "noted for next time" and wrote nothing. A first prompt that called its
  instruction "a decision for this project" made both versions write, so a
  probe has to avoid the words the classification keys on. Unlike opening a
  file at session start, the write comes at a moment the work itself produces.
  Only Claude Code has been watched doing it.
