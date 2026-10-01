# METHOD

Durable rules this project has earned. Facts that stay true across tasks
belong here; anything that expires when the current task closes belongs in
STATE.md.

## Classification (apply in order)

1. Part of the approved contract (goals,
   criteria, a data or API shape)?             -> SPEC.md, and only through
                                                  the spec gate
2. About SparkForge itself rather than this
   project (kit/, the stubs, the scripts)?     -> STATE.md -> Upstream
3. Useful again in a future task?              -> METHOD.md
4. Meaningless once this task closes?          -> STATE.md
5. A decision?                                 -> principle to METHOD,
                                                  specific choice and its
                                                  situational reason to STATE
6. Already recorded by the repo (code layout,
   git history, config files)?                 -> record nothing
7. A rejected approach with a reason?          -> METHOD -> Anti-Patterns
8. Tied to a specific library or tool version? -> GOTCHAS.md

## Update semantics

SPEC.md     changes only through the spec gate, with approval. Rewrite what
            no longer holds in place; never append a second spec.
METHOD.md   accumulates. Correct a rule in place rather than appending a
            contradicting one. Deleting requires a stated reason.
STATE.md    is replaced. Drop anything no longer true. git holds history.
GOTCHAS.md  entries may be deleted freely, no reason required.

A memory update re-reads the whole file, not only the sections the current
task touched. The stale entry is never in those sections.

---

## Conventions

(empty)

## Anti-Patterns

(empty)
