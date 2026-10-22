# STATE

> Last updated: 2026-10-21

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

The projects that have adopted the framework, all in sibling directories of
this repository: ../GameBrake, the first install, a C# tray tool built through
every acceptance criterion of its v1 and in daily use; ../LearningProject, a
Markdown-only template for learning projects; ../dsh/dsh-docker+remote-access,
which merges two Docker repositories into one public one; ../dsh-mobile-mode,
a DeepSeek Harness Web client plugin adopted on 2026-10-18 and worked on in a
Linux container, the first install off this Windows machine; and ../test, the
backend half of the qryvox hackathon (2026-10-01), MODE sprint and TEAM > 1,
which is not a git repository and whose spec never reached the team's real
repository, ../qryvox (see Open Questions). ../TempTime never adopted it, but
source/METHOD.md is a copy of its METHOD.md. Surveys on 2026-10-01 and
2026-10-21 are where most of the Next Steps below came from.

kit/ has two halves with different standing, and the split is by how each was
written rather than by what it covers. verification, diagnosis and
memory-update were transformed from TempTime's methodology and carry its
incidents. spec-gate, team-contract, bootstrap and evidence-reviewer were
written from a specification; bootstrap and spec-gate have run in every
adopting project, the other two in none.

## Next Steps

- The progress page is the current work. On 2026-10-21 the user said it still
  falls short of what they have in mind and chose to finish it before any of
  the survey findings in the next item. What falls short is not yet recorded,
  except translation: on GameBrake's page all 62 units showed untranslated,
  because translations/zh-TW.md was never written. The rule that an agent
  fills it after every memory write asks for an unprompted action and did not
  happen. A local model (Ollama) was rejected by the user: not every machine
  has one. Decided 2026-10-21: (1) the agent fills translations when the user
  asks it to open the page, a prompted moment, and the page offers a button
  that copies that instruction for any agent; (2) code, paths and ids carry
  translate="no" so the browser's own translation can cover what is left
  without breaking them; (3) Chrome's built-in Translator API only if a test
  shows the user's browser has it. The after-every-write rule goes.
  Built the same day, kit 0.6.2: code carries translate="no", untranslated
  spans lang="en"; the banner has a button copying the agent instruction and,
  where self.Translator exists, one that machine translates what the file
  lacks, per segment between code spans, cached per viewer in localStorage,
  tagged 機器翻譯 with the original one click away, then reloads; with the
  model already present it runs on load without a click. AGENTS.md says to
  fill the file when asked to open the page, project-requirements.txt makes
  check.sh ask for that paragraph, and memory-update.md no longer asks for it
  after every write. Observed in headless Edge 155 and Chrome 155 over CDP on
  a GameBrake clone: a real mouse click downloaded the en to zh-Hant model in
  about a minute (first ~40 s with no progress event), all 62 units cached,
  inline code identical, every displayed span translated after the reload,
  no errors; a page with TRANSLATION blank shows no banner. The copied
  instruction was then walked for real: the user pasted it into Claude Code
  here, which wrote all 62 of GameBrake's units into
  ../GameBrake/translations/zh-TW.md by hand (left uncommitted there for the
  user), --untranslated then listed nothing missing or orphaned, and the page
  opened. Not observed: the copy button's clipboard, other browsers (where
  only the agent button shows), the user's judgement of the machine
  translation's quality, and whether an agent fills the file unprompted when
  merely asked to open the page.
  A page defect the translation exposed, not yet fixed: an evidence result
  has its inline-code commands cut out and shown apart, so the text left
  behind reads "passed ( : 29 passed; : 17 passed", and every translation has
  to carry the same holes. Fix it in the page, not in the translations.
  The user's next complaints, 2026-10-22, on GameBrake's page: "未歸類" was a
  mess (no criterion names a goal, so all ten sat under "not under a goal"
  while six goal sections each said nothing named them), Current Focus was
  too long to read, and the work had no timeline. Asked which timeline, the
  user wanted both the work by date and the criteria on it, simple outside and
  opening to the detailed process of each item. Built in kit 0.6.3: goals no
  criterion names are one compact list; when no criterion names any goal the
  criteria are one grid headed 驗收標準 with a note why; Problem and Current
  Focus open on their first sentence (cut from the translation in the zh
  view) with the whole text one click away, a paragraph per unit; the changes
  list became a timeline of the last 300 commits by day, newest first, five
  changes shown a day and the rest folded, commits touching only memory,
  framework or translations folded as records, each commit opening to its
  body by paragraph (trailers dropped), commits since the last view marked
  新, and each day listing the criteria its commits name and the evidence
  recorded that day as chips. Bodies and subjects are translation units, so
  GameBrake went from 0 to 99 untranslated. Observed in headless Edge on a
  GameBrake clone: no errors, the four views by screenshot. Not yet seen by
  the user. The expanded Current Focus is still a wall: GameBrake's is long
  because it was written for agents, which the page cannot fix.
- Progress page, decided with the user on 2026-10-04. Origin: at a hackathon,
  without SparkForge, the user accepted AI suggestions until they no longer
  knew what the demo did or how to run it. Built, in kit 0.6.0:
  scripts/progress.sh (progress.ps1 on Windows) generates one self-contained
  bilingual HTML page from SPEC.md, STATE.md, AGENTS.md and git, and stores
  nothing: bash and awk emit JSON, inline JS renders it. A graph of cards
  joined by lines was tried for three rounds and removed because the user found
  it unusable. The user then said the page showed one spec, not the project,
  and chose three views: a roadmap of versions, an overview of every feature,
  and the project's structure. Now four tabs, remembered in localStorage and
  in the address hash (#roadmap, #progress/M1). Progress: a scope selector
  (each milestone, all, unassigned; default the current milestone), a "what
  this is" box, a progress box counting only the scope, goal sections with
  criteria cards, and project-wide lists of changes and next steps. A card
  opens a drawer: meaning, how to try it, the criterion, evidence, related
  commits and next steps. Roadmap: milestones in listed order with a computed
  state badge, evidenced counts and their goals; the current one marked. Features:
  the usage guide, only criteria with evidence, each under its first goal and
  milestone, with a quiet count of what is left out. Structure: one card per
  component with its path, responsibility and uses and computed used-by chips
  that jump between cards; its drawer lists the last five commits touching the
  path. Everything is computed or read, nothing is written to drift: a
  milestone is planned when no goal names it, done when it has criteria and
  all are evidenced (evidence recorded, not just a status), in progress
  otherwise, and the current one is the first neither done nor planned;
  a criterion counts toward every milestone its goals name. Without a
  Milestones section the progress tab is as before and the others show an empty
  state with an example. SPEC.md accumulates across milestones (spec-gate
  adds, rewrites only what changes), at the accepted cost that it, imported
  every session, grows. Gaps are ranked high (a state that looks true and is
  not: a path not on disk, a uses or milestone reference to nothing, evidence
  claimed without evidence), medium (missing links, tags, Means or Try) and low
  (housekeeping), the rule being a comment in progress.sh. Belonging is by
  written id only. Translation covers milestone titles, component names and
  responsibilities, Means, Try, commit subjects (including a component's) and
  the result part of evidence; commands, paths and ids never; the original is
  one click away and untranslated text is marked with a pill and an EN tag.
  Observed in headless Edge on Windows over the DevTools protocol, light, dark
  and 390 wide, on a three-milestone fixture, a fully translated copy and a
  GameBrake clone: every tab, scope, drawer, hash links, tab memory, chip jumps
  and keyboard opening; a DOM scan of the fully translated page over every tab,
  scope and drawer found no Latin words outside code, ids, the project name,
  the "English" button, the EN tag and the word commit; the state computation is
  unit-tested against the page's own data, including a sabotage. Not observed:
  touch, other browsers, anything on a Mac (written for bash 3.2 and BSD awk,
  never run), opening through open, xdg-open or Git Bash's start, and whether
  the user finds this version usable. Unverified: whether an agent writes ids,
  Means and Try lines, milestones, components, status lines and translations
  unprompted. Known limits: the page cannot tell a stale translation from a
  missing one; a criterion edited after its evidence was recorded still shows
  evidenced, the date being the only hint; a run takes several seconds on
  Windows because each translated section unit spawns a git hash. What a
  project needs outside kit/ is listed in kit/project-requirements.txt (see
  below); Means and Try lines, milestones and components in SPEC.md are
  content and are not in it. Solo use first; team use waits for the paused TEAM > 1 design. Phase 2, after the
  user has used this: a LEARNING switch and bilingual notes written at
  decision time, each saying what was chosen, what was rejected, what it
  solves and what it costs.
  First real install, agreed 2026-10-04: GameBrake, chosen because the user
  knows it and its data is real, not because it tests the main unknown — it
  has no development under way, so whether an agent writes status, ids and
  translations unprompted waits for a project with work in progress. Plan:
  update-kit from the local SparkForge path (the new commits were not pushed
  until 2026-10-21),
  the hand-copied pieces, status lines backed by commands actually rerun,
  and a spec-gate draft of milestones, components, Means and Try for the
  user to approve before SPEC.md changes. Done the same day except the
  approval: GameBrake is on 0.6.0 with the page, 6 criteria evidenced by
  tests run that day and 4 claimed, because their real-process half lives in
  e2e, which kills the running tray and overwrites the real config, and in
  WindowsProcessWatcherTests, which refuse while the tray runs. The draft
  waits for the user. What the install found about SparkForge was three defects, fixed in kit
  0.6.1 on 2026-10-04. update-kit.sh stages kit/'s .sh files 100755 and says
  so. kit/project-requirements.txt (path|text|hint per line) is the one list
  of what a project needs outside kit/: check.sh reads it in place of its old
  REQUIRED array and fails each unmet line with its hint, and update-kit.sh
  prints the lines that are new against the list it replaced and unmet, so a
  project already meeting everything, or an old requirement still unmet, gets
  no repeat. spec-gate states that uses takes bare comma-separated ids; the
  page draws nothing from a uses list holding any other token and reports it
  as a high gap. Verified on scratch clones of GameBrake at 0.2.1 and 0.6.0,
  a uses fixture in headless Edge, and a sabotage of the gap check restored
  from the index. Not verified: macOS. A first update to 0.6.1 runs the OLD
  kit/scripts/update-kit.sh, which neither stages nor lists anything, so
  GameBrake meets the new code only on its second update, or by running the new
  script against it directly (SPARKFORGE_ROOT and SPARKFORGE_UPDATE_COPY set
  to the project and a copy of the new script).
- Survey of 2026-10-21, discussed with the user, to do after the progress
  page. Proposed in this order, nothing built:
  1. kit 0.6.x stayed local for seventeen days, so dsh-mobile-mode, adopted
     from the remote on 2026-10-18, received 0.2.1 and never the progress
     page built for exactly its kind of project. collect-upstream.sh compares
     projects against the local template and printed "0.6.1 here" throughout,
     which hid it. Make it also print the version origin/main holds.
  2. ../test reported two bootstrap defects 0.6.1 does not fix. The entry
     condition, METHOD.md and STATE.md both empty, is falsified on day one by
     writing memory as you go, so bootstrap can never fire once the first
     conversation has written STATE.md: key it on SPEC.md being an empty
     shell, or on MODE and TEAM not yet declared. Step 1 assumes a git
     repository: add a step before it that settles where the code lives
     (git init here, or clone the real repository in).
  3. Upstream has no return path. GameBrake's three entries were fixed in
     0.6.1 and still stand there, so every survey shows them again. Proposal:
     a kit/CHANGES that names, per version, the Upstream entries it answers;
     update-kit.sh prints it, and the project's agent deletes what it answers.
  4. STATE.md grows into a changelog in every project. dsh-mobile-mode's
     Recent Decisions logs each version and each README rewrite;
     LearningProject's are long dated narratives; GameBrake's STATE.md was
     29.6 KB with v1 long finished. Nothing pushes back on "STATE.md is
     replaced". Give Recent Decisions an exit test (already in code, git or
     SPEC and no longer steering the next step: delete), and have check.sh
     warn when STATE.md grows past a size, only on growth.
  5. Joining a repository someone else owns, which already has its own
     AGENTS.md. ../qryvox is that case: the teammate's repository carries
     git and directory rules and an ADR choosing TypeScript on Vercel, where
     ../test's spec chose FastAPI on Render. SparkForge assumes it owns the
     root AGENTS.md and has no way in. Belongs with the paused TEAM > 1 design.
  6. LearningProject's findings never reached Upstream, because Upstream is
     defined as kit/, stubs and scripts, while what it learned is how agents
     follow memory rules: compliance depends mainly on the model (DeepSeek
     V4.1 Flash followed everything, free and local models did not), the
     first evidence of writing as you go outside Claude Code; commit right
     after every memory write, which memory-update.md does not mention and
     TEAM > 1 will need; which clock a date comes from when two machines
     write (dsh-mobile-mode commits at +0000 beside this machine's local
     time); one project, one session. Widen the Upstream definition to cover
     observations of agents following the framework, and weigh each of these
     as a candidate rule.
  7. A SPEC.md line found false stays false: dsh-mobile-mode's AC8 names
     `node --test test/`, which does not run there; STATE.md records it,
     SPEC.md, changeable only through the gate, does not. Consider requiring
     a pending spec change under Next Steps when a SPEC line is found false.
- The qryvox backend (../test, 2026-10-01) is the first TEAM > 1 use found,
  and team-contract never ran there. Read on 2026-10-01, it only asks for a contract
  reference and a file-ownership list, and says neither where that list is
  written nor anything about memory: every rule in memory-update.md assumes one
  writer, and STATE.md is replaced on each write, so two people's agents
  writing as they go on separate branches meet as a merge conflict in it.
  Paused by the user on 2026-10-01 with nothing built; the project's shape is
  still unknown: how many people, one repository or several, branches, which
  agent tools. The direction discussed, not decided: no separate framework,
  one STATE file per person under TEAM > 1, METHOD.md and SPEC.md shared, the
  ownership list in SPEC.md. Agents pushing memory themselves is open too,
  since memory not pushed is invisible to the others. The user's people work at different
  times, not together, so the conflicts come from starting on a stale copy.
  Pulling before a session starts is an action at session start, the shape of
  METHOD.md's anti-pattern, so it needs a mechanism (a SessionStart hook in
  Claude Code) rather than a line in AGENTS.md. Untried.
- Memory does not load in DeepSeek Harness; see Open Questions. Unsolved. The
  obvious patch is rejected in METHOD.md, Anti-Patterns.
- GameBrake is on 0.6.0 and every other project on 0.2.1. The first three
  were brought to 0.2.0 on 2026-10-01, kit/ through each project's own
  update-kit.sh over SSH and the rest copied in once by hand, with each spec
  moved out of STATE.md into SPEC.md and checked line for line; then to 0.2.1
  the same day through the new stubs, with nothing left to do by hand.
  GameBrake's spec-gate draft of milestones, components, Means and Try has
  waited for the user's approval since 2026-10-04.
- Remind the user, at the start of the next session that touches update-kit.sh
  or the projects: decide whether update-kit.sh's default upstream stays HTTPS.
  It was chosen for readers without an SSH key, which assumes a public
  repository, and this one needs a login, so the default reaches nobody
  as things stand; the user, who has SSH, has to pass the SSH URL every time.
  On 2026-10-01 they chose to keep HTTPS for now and asked to be reminded.
  Since 0.2.1 the default at least fails in seconds and prints the SSH
  command, where it used to wait on a login prompt until killed.
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
  @path imports. So it needs no entry file, and SPEC.md, METHOD.md, STATE.md
  and GOTCHAS.md never load there. The one lever the loader offers is its
  instructionFileCandidates list, which could name the memory files, but that
  lives in the user's DSH profile rather than in the project, so the framework
  cannot ship it. Untried. All of this is read, not watched. LearningProject
  works around the same loader by keeping project instructions inside
  AGENTS.md itself, the "content placed where it is already loaded" option.
- Why the qryvox hackathon went without SparkForge is inferred, not
  confirmed: ../test holds an approved backend spec, and ../qryvox, the team's
  repository, has its own AGENTS.md and a different stack, with no trace of
  the framework. The inference is that the framework had no way into a
  repository it does not own. Ask the user.
- Every tool entry except Claude Code's reaches AGENTS.md only by asking the
  agent to open it. Cursor's alwaysApply loads the pointer, not the file it
  points at. That is the same request the rejected memory patch made, and the
  agent ignored it there, so whether those tools ever get AGENTS.md is now
  doubtful rather than merely unobserved. None of the five has been opened.

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
- spec-gate has produced its four artifacts in every adopting project, and
  GameBrake's run also recorded its assumptions as the second step asks. Every
  recorded run was bootstrap's step 4. dsh-mobile-mode later grew its SPEC.md
  (G8, AC11, AC12) inside the feature commits, so whether a gate ran with
  approval there cannot be told. The gate has never been seen firing on its
  own.
- The first install off this machine, dsh-mobile-mode in a Linux container
  on 0.2.1, passed check.sh with every script at 100755 and sent nothing
  upstream.
- update-kit.sh has pulled real changes from the real remote into all three
  projects, twice on 2026-10-01: to 0.2.0 through each project's old copy, and
  to 0.2.1 through the self-copying one, which replaced itself mid-run in all
  three and left nothing behind. The destructive half has run over kits
  nobody had edited, so it has still never run over content anyone would
  miss.
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

- An awk join that tells its two files apart by FNR==NR reads the second file as
  the first when the first is empty. progress.sh did, and every scratch fixture
  had a non-empty status section, so only the real GameBrake clone showed it;
  it now compares FILENAME. The same scratch trap: a scratch project holds a
  copy of kit/, so a fix to template/kit is not under test until it is copied
  in again.
- In Windows PowerShell 5.1, `-replace` with a lone backslash pattern is an invalid regular expression;
  use .Replace with [char]92.
- The working tree's file mode is not real here, so an executable bit has to
  be set with `git update-index --chmod=+x` rather than `chmod`.
- `grep -c $'\r'` cannot be trusted as a carriage-return count on this
  machine. On 2026-10-01 it reported every line of LF-only files as matching,
  where od, file and git's eol listing all showed none, and earlier the same
  day it had printed 0 for files of the same kind. Ask `git ls-files --eol`,
  which reads the index too, or `file`, which was shown to flag a real CRLF.
- `template/.gitattributes` cannot be verified in place, because the root
  file's attributes are inherited by everything under it. The checker copies
  it to a throwaway repository to get an answer that can differ.
- The README also restates the project layout, the bootstrap procedure and
  the execution record of several components, and nothing diffs any of them
  against the files they describe. They are checked by hand when someone
  remembers to, which is how all three went false at once. The maturity
  section was brought up to date on 2026-10-01. One claim is false and stays:
  it says memory loads by itself, which is not so in DeepSeek Harness, and
  that is left out of the README by decision; see Recent Decisions. The
  translations, at least, are now compared by check-repo.sh.
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
- A finding still only reaches this repository when someone here goes to get
  it. GameBrake marked one for sending and never sent it; it arrived only
  because a survey read GameBrake's STATE.md, and for over a month before that
  this file and the README said nothing had crossed the spec gate while
  GameBrake was finished. Since 2026-10-01 a project writes such things under
  Upstream in its STATE.md, and scripts/collect-upstream.sh lists that section
  and whether kit/ is current for every project beside this repository. That
  makes the survey one command rather than an hour of reading, and it was run
  against the real projects and a scratch set covering current, behind, empty,
  filled and missing. It does not make the survey happen: the root AGENTS.md
  asks for it before choosing work, which is the depends-on-remembering shape
  every hole so far has had. Every adopting project carries an Upstream
  section. Nothing removes an entry once upstream has acted on it; see Next
  Steps, survey item 3.

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
  the next batch to have that shape too. The first machine that is not this
  one, a Linux container, reported nothing, so the shape still holds but has
  not been confirmed from the other side.
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
- The spec lives in its own SPEC.md, decided on 2026-10-01. Bootstrap used to
  put it into STATE.md, which is replaced as work moves while a spec is a
  contract that stays, so neither rule could be followed: GameBrake's STATE.md
  still carried its whole v1 spec after v1 shipped, and its memory files
  together were past half of DeepSeek Harness's default budget. SPEC.md is
  imported every session like the memory files, because asking the agent to
  open it when needed is the anti-pattern in METHOD.md; the cost is that the
  spec still takes context, and what this buys is a STATE.md that can be
  cleared. It changes only through the spec gate, never as you go. Projects
  already installed keep their spec in STATE.md until moved by hand: SPEC.md,
  its import and the bootstrap step are all outside kit/ or ran once already.
