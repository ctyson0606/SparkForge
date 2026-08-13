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

## Anti-Patterns

(empty)
