---
name: bootstrap
description: The one-time opening pass, run only while METHOD.md and STATE.md
             are both still empty shells.
---

# Bootstrap

Runs only when METHOD.md and STATE.md are both still empty shells. Runs once.

1. Ask for MODE and TEAM. Write them into AGENTS.md.
2. Ask for or infer the Environment facts and fill them in one by one. Where
   the project genuinely has no such command, write "none".
3. Run the spec gate at the depth MODE selects.
4. Write what the spec gate produced into Current Focus in STATE.md.
5. Leave METHOD.md empty.

Step 5 is a hard rule. METHOD.md grows from the traps this project actually
hits, not from guesses made before it has hit any. Do not put anything in it
because it looks empty.
