# METHOD

Durable rules this project has earned. Facts that stay true across tasks
belong here; anything that expires when the current task closes belongs in
STATE.md.

This is SparkForge's own memory. The files under template/ are the empty
shells that ship to projects adopting the framework; nothing here is copied
into them.

## Classification (apply in order)

1. Useful again in a future task?              -> METHOD.md
2. Meaningless once this task closes?          -> STATE.md
3. A decision?                                 -> principle to METHOD,
                                                  specific choice and its
                                                  situational reason to STATE
4. Already recorded by the repo (code layout,
   git history, config files)?                 -> record nothing
5. A rejected approach with a reason?          -> METHOD -> Anti-Patterns
6. Tied to a specific library or tool version? -> GOTCHAS.md

## Update semantics

METHOD.md   accumulates. Correct a rule in place rather than appending a
            contradicting one. Deleting requires a stated reason.
STATE.md    is replaced. Drop anything no longer true. git holds history.
GOTCHAS.md  entries may be deleted freely, no reason required.

A memory update re-reads the whole file, not only the sections the current
task touched. The stale entry is never in those sections.

---

## Conventions

### The platform that produces a file cannot report that the file is broken on another platform.  `[T0]`  `[2026-08-12]`

Anything a build writes carries properties the producing machine does not
enforce and therefore cannot check: line endings, an executable bit, a
lockfile's platform. Assert those against the repository index rather than the
working tree, since the index is what other platforms will receive.

> Evidence: Three instances in this project's first four commits. A CRLF
> script that runs on the machine that wrote it and fails elsewhere with a bad
> interpreter. A version file with no extension that came out with a trailing
> carriage return, which a string comparison would have read as a permanent
> mismatch without ever failing. An executable bit that git recorded as absent
> because the producing platform does not carry one, leaving the scripts
> unrunnable on the platforms that do.

### A sabotage is not complete until the restore is verified.  `[T0]`  `[2026-08-12]`

Restoring is part of the experiment and can fail silently. Do not hand-roll a
backup: restore from the last commit and confirm the diff is empty before
moving on. If the content under test is not yet committed, git add it first so
that the index becomes the restore point. Restoring from HEAD would delete it.
A restore that fails leaves the sabotage in place, and the next check reports a
real state as if it were the test result.

> Evidence: A backup written to a path built from an environment variable that
> was already set elsewhere. The copy back failed, and the deliberately broken
> content stayed in the file after the test was considered finished. The rule
> caught its own author one commit later: restoring an uncommitted rule from
> HEAD deleted the rule itself, and the empty diff the rule demands was what
> revealed it.

### A count of things the repository holds does not belong in a memory file.  `[T0]`  `[2026-08-13]`

The test is whether a later change can make the number wrong. If nothing that
lands afterwards can falsify it, it stays; if the next commit can, it does not
belong here.

A number that describes the contents of the repository — how many skills, how
many checks, how many components — is answered by one command and falsified by
the next change that adds or removes one. Writing it down creates an entry that
must be maintained in step with the thing it counts, and nothing reports when
the two diverge.

Three kinds of number pass the test and are out of scope. A count of incidents:
no command answers it and the next change only adds to it. A count of work
still outstanding: the same, and the number is what the entry exists to reduce.
A count recording what the repository held at a past moment, inside an incident
being described: it is a fact about that moment rather than a claim about the
present, so removing it destroys the evidence instead of preventing a stale
line.

Name the things or point at the command.

> Evidence: An invariant count in this project's own state file went stale
> twice in three commits, corrected in place both times before it was
> recognised as a line that should not exist. Two smaller counts of the same
> shape were still present after the second correction.

### An opt-out and an omission look identical to a checker.  `[T1]`  `[2026-08-20]`

Where a structure is allowed to be legitimately absent, nothing reading the
current state can report the case where it is wrongly absent. Tightening the
check removes the opt-out; leaving it silent lets the wrong absence through.
Neither is available to a reader of the state, because the two states are the
same state. The difference is in the transition, so it has to be drawn wherever
the before and the after are both in hand — whatever performs the change, not
whatever inspects the result.

Report only what the transition introduced, never every absence. A warning that
fires on every deliberate opt-out is read twice and ignored from then on, which
costs more than the silence it replaced.

> Evidence: The per-tool entry files may each be deleted, since that is how a
> project declines a tool it does not use, so the checker has to read a missing
> one as intended. Their list ships inside kit/, so an update can begin naming
> a tool the project has no entry for, and that arrival is indistinguishable
> from the deletion. The update script held the old list and the new one at
> once and was the only place the two could be separated.

### A checker scoped to a subtree reports nothing about the same structure outside it.  `[T0]`  `[2026-08-20]`

A check written against a root argues only about that root. Anything of the
same shape one level above it passes unexamined, and the output is identical to
the output of a check that looked and approved. Before trusting one, ask what
its root excludes.

> Evidence: Two checks in this repository take the template directory as their
> root. The tier tag and evidence label checks read only the skills beneath it,
> while the root METHOD.md is written in the same grammar and is never opened.
> The README check globs that same root and reports "only one README, nothing
> to compare" while three translated READMEs sit one level above it.

### A restatement is a copy, and nothing keeps an unguarded copy true.  `[T1]`  `[2026-08-20]`

Where something has to be said in a second place, there are three outcomes and
only two of them are chosen. Point at the original and state nothing. Restate
it and add something that diffs the two. Or restate it and find out later.

The test is whether the restatement can be compared mechanically against what
it describes. A layout, a numbered procedure, a recorded status: each of those
is diffable against the thing itself, so a copy of one that nothing diffs is
already waiting to go false. Copies that cannot be diffed are a different
problem and this rule does not reach them.

> Evidence: A README restated the project layout, the bootstrap procedure and
> one component's execution record. All of them were false within four commits,
> and every change that falsified one reported nothing. The same repository
> holds the other two answers: the agent tools line exists twice because the
> tool reads the stub rather than the canonical file, and a check diffs the
> copies; and memory-update.md refuses the copy outright, on the stated grounds
> that a second copy would drift from the first.

## Anti-Patterns

(empty)
