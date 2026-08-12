---
name: verification
description: Judging whether a test, probe, or suite actually constitutes
             evidence. Read before trusting any green run.
---

# Verification

Rules are ordered as they appear in the source they were extracted from.
Each carries the tier at which it costs to comply, and the date it was
recorded.

Each rule carries one of three labels, and each implies a different follow-up:

`Evidence:`   an incident is written down. Nothing further is needed.
`Found:`      the rule came out of a real investigation, but the individual
              incident was not recorded. It is true; the detail is not
              recoverable. Write the incident down the next time it recurs.
`Rationale:`  reasoning only, never tested by an incident. Design a control
              for it.

A tier tag is `[<tier> (| <tier> if: <condition>)*]`. The first token is the
tier that applies when the conditions cannot be evaluated, so it is always the
conservative one: a reader that does not understand the condition falls back
to it, and overestimating the cost only buys verification nobody needed.

### A suite that passes on its first run is unverified, not correct.  `[T1]` `[2026-08-12]`

Before trusting a new suite, break the code it covers on purpose. Pick the one
or two behaviours most likely to be got wrong, confirm the expected tests fail,
and read *which* ones failed. Then revert and re-run.

> Rationale: A green first run is equally consistent with tests that assert
> nothing discriminating. Breaking the code on purpose is the only evidence
> that a green suite means anything, and it is cheap.

<!-- source: METHOD.md 67-73 -->

### A green suite is evidence only for the code it actually runs.  `[T0]` `[2026-08-12]`

Run the suite that covers what you changed. If no suite covers it, that
absence is itself the finding and must be reported. A probe that was written
and never run is worse than no probe, because its presence in the tree reads
as evidence to whoever comes next.

> Evidence: Hundreds of unit tests passed over a component whose two error
> notices were wired the wrong way round, disclosing to a stranger the one fact
> the error existed to withhold. Nothing in the unit suite touched that
> component, and the browser script that did cover it had been written in the
> same session as the bug and never run.

<!-- source: METHOD.md 75-83 -->

### Some assertions cannot be sabotaged safely, and those stay unproven.  `[T0]` `[2026-08-12]`

Sabotage is cheap where the blast radius is the check itself. It is not cheap
where the only way to falsify an assertion is to destroy live data. Sabotage
what you can, name what you could not, and never let one round of it vouch for
a whole file.

> Evidence: A deletion suite's control — that a record which has not expired
> survives — could only be falsified by removing or inverting the filter that
> decides what gets deleted, which empties the table on the live database.

<!-- source: METHOD.md 85-92 -->

### A sabotage has to be aimed at the assertion under test.  `[T0]` `[2026-08-12]`

Pick a sabotage whose blast radius is the assertion you are testing. If it is
not, move it somewhere with fewer neighbours. Treat "the run died first" as a
result that has not answered the question.

> Evidence: A sabotage meant to test a layout assertion broke interaction so
> thoroughly that the run aborted at an unrelated click, several assertions
> before the one under test. That says the suite is fragile, not that the
> assertion works.

<!-- source: METHOD.md 94-100 -->

### Widening a window proves nothing if the observer is blocked until it closes.  `[T1]` `[2026-08-12]`

Before widening a window to reproduce a race, ask who is awake while it is
open. If every watcher is waiting on the operation that holds the window open,
none of them can look inside it. Reproducing it needs a third party that
observes from outside the operation under test.

> Evidence: A delay inserted between two writes inside one request left the
> failure rate roughly where it was instead of making it certain. The delay was
> real and the reasoning was right; every watcher was awaiting the very request
> holding the window open. Firing the write without awaiting it, sleeping into
> the middle and reading from a separate caller made it fail every time, and
> never once the fix was in.

<!-- source: METHOD.md 102-111 -->

### When a probe fails, capture enough state to tell the candidate explanations apart.  `[T1]` `[2026-08-12]`

A failure message carrying only the value that was asserted on is usually
consistent with every hypothesis you hold. Print the neighbouring state at the
moment of failure, chosen so that the live explanations disagree about it.

> Evidence: A probe had two live explanations — two stores disagreeing, or a
> stale response overwriting a newer one — and its message carried only the
> number it asserted on, which fits both. Printing the readout *and* the
> underlying list at the moment of failure separated them in a single run.

<!-- source: METHOD.md 113-118 -->

### Check that the harness is not the thing that failed before reading anything into a control.  `[T0]` `[2026-08-12]`

A run can die on the project's own defences — rate limits, quotas, guards —
rather than on the behaviour under test. That looks exactly like a sabotage
working. Establish where the run actually stopped before concluding anything
from it.

> Evidence: Three control runs aborted at resource creation instead of reaching
> the assertion, because repeated probing had exhausted a rate limit.

<!-- source: METHOD.md 120-125 -->

### A probe whose outcomes cannot differ proves nothing.  `[T1]` `[2026-08-12]`

Pick a target where success and failure look different. Run the known-bad
control in the same breath as the real one; if the two produce identical
output, the test has not started yet.

> Evidence: A secret was tested against an endpoint that rejects every
> credential of that class regardless of the token, so the real secret and a
> deliberately wrong one both returned an identical failure. The value looked
> broken when it was merely untested, and two rounds were lost that way.

<!-- source: METHOD.md 127-134 -->

### A credential is not verified by where it was copied from.  `[T1]` `[2026-08-12]`

Provenance is not evidence, and neither is passing a local shape check. Only
the live service can tell a working credential from a plausible-looking value.

> Evidence: A dashboard displays a key's identifier next to its value; the
> identifier passed the project's own length guard and was indistinguishable
> from the real thing until the service was called.

<!-- source: METHOD.md 136-138 -->

### An equality check is satisfied by two absences.  `[T0]` `[2026-08-12]`

Every comparison of the form `a === b` passes when the thing being measured
never appeared at all. Anchor the assertion on a value known to be non-empty,
so that finding nothing fails instead of agreeing with itself.

> Evidence: An assertion comparing a restored count against a painted count
> reported success while both were zero.

<!-- source: METHOD.md 140-144 -->

### Log the call, not only the transition.  `[T0]` `[2026-08-12]`

Instrumentation carries the same requirement as a test, and it is easier to
get wrong because nobody sabotages a debug log. A log that records only
changes cannot distinguish "the handler never ran" from "the handler ran and
computed the value it already held".

> Evidence: Chasing why an interaction left a readout blank, the first probe
> recorded every change of the state behind it. Both hypotheses produced an
> identical empty log, and the empty log was read as evidence for the wrong
> one.

<!-- source: METHOD.md 146-152 -->

### An intermittent failure has a rate, and one run does not measure it.  `[T2]` `[2026-08-12]`

Anything that does not fail every time needs a count before and after the
change — several runs each side. The comparison is between rates, not between
outcomes.

> Evidence: A probe that failed, then passed once a candidate fix was in, was
> very nearly written down as fixed. A handful more runs put it back at roughly
> one failure in two, with the "fix" still in place and irrelevant.

<!-- source: METHOD.md 154-159 -->

### A flake that surfaces next to your change is not evidence your change made it.  `[T2]` `[2026-08-12]`

Stash the edit and measure the untouched tree at the same sample size. Without
that measurement the honest options are to blame your own change or to say
nothing, and both are wrong.

> Evidence: An unrelated assertion started failing about twice in five runs
> during an edit, which is exactly the shape of something newly broken.
> Stashing the edit and running the untouched tree four times put it at one in
> four — the same rate inside the noise these sample sizes carry — so it was
> pre-existing and merely never measured. The two ratios look different and at
> that sample size cannot be told apart; that is the whole point.

<!-- source: METHOD.md 161-167 -->

### An added probe is part of the experiment.  `[T0]` `[2026-08-12]`

Compare only runs whose instrumentation is identical. Be suspicious of a bug
that survives exactly as long as nobody is looking at it.

> Evidence: A failure disappeared whenever the instrumentation for diagnosing
> it was present, because each extra round trip into the page changed the
> timing.

<!-- source: METHOD.md 169-173 -->

### The toolchain's own version is a variable, and it is invisible in the diff.  `[T1]` `[2026-08-12]`

A cross-machine comparison is not clean until the tool versions on both
machines are compared too. Either match them, or name the confound beside the
number rather than reporting the rate as though the machine were the only
difference.

> Evidence: An unmodified script failed every run on a second machine where the
> first had been failing about half the time — except that the second machine
> had just picked up a newer build of the tool the harness drives. Two
> variables changed at once and only one of them was visible in the working
> tree.

<!-- source: METHOD.md 175-183 -->

### An observation window has to outlast the event it is meant to observe.  `[T1]` `[2026-08-12]`

That is a property of the platform rather than of the plan. Before writing "go
and look" into a task, establish that the record will still exist when you get
there. If it will not, there are three ways out: be present inside the window,
trigger the event yourself, or make the event leave a durable trace.

> Evidence: A step written as "check the dashboard and confirm the scheduled
> job authenticated" was not executable: the console reported no outcome for
> past runs, and log retention was far shorter than the interval between runs.
> The evidence expires long before anyone can arrive, so the check returns an
> empty list that means nothing at all — and reads like success. Triggering the
> event yourself is usually cheapest, and it costs one named gap: a manual
> invocation exercises the same handler and the same credential but not the
> scheduler, so state which of the two you proved.

<!-- source: METHOD.md 185-199 -->

### A failure that stops after a change is not a failure the change fixed.  `[T1]` `[2026-08-12]`

Put the suspected cause back and confirm the failure returns. Sabotaging the
*code* proves a test has power; sabotaging your own *fix* proves the diagnosis
does. Skipping the step costs more than the time it saves, because what gets
written down is a diagnosis rather than a coincidence and the next reader
cannot tell which they are holding.

> Evidence: A subscription delivered nothing, a plausible race was found in a
> library's source, the fix went in, the run went green, and the cause was
> written into two files as established fact. Reverting the fix later produced
> three green runs in a row: the race was real and had nothing to do with the
> failure, which remains unexplained.

<!-- source: METHOD.md 201-213 -->

### A comment claiming a line is required is a testable prediction.  `[T1]` `[2026-08-12]`

Remove the line and see. Keep it or drop it on the result, and if the reason
in the comment turns out to be false, record both observations rather than the
one that did not survive.

> Evidence: A line copied from a framework's own documentation and explained in
> a comment as load-bearing was commented out and changed nothing — the
> framework read the value from a different place than the documentation named.
> The line was kept, because documented behaviour is the better bet across
> upgrades, but the comment now records both observations.

<!-- source: METHOD.md 215-223 -->

### A sentence describing what happens when a value is missing is verified by removing the value.  `[T1]` `[2026-08-12]`

Setup documentation is more expensive to get wrong than a code comment,
because the reader has no working system to check it against. Empty the value
the document describes as optional, exercise the path, and restore it.

> Evidence: An example environment file told anyone setting the project up that
> one variable could be left empty and a feature would degrade gracefully.
> Emptying it and calling the endpoint failed outright — the value signs a
> token issued during setup, so nothing worked without it.

<!-- source: METHOD.md 225-231 -->

### A production number is not asserted from a machine that is not production.  `[T0]` `[2026-08-12]`

Where a target describes deployed behaviour — a latency, a throughput —
measure it and print it, but do not fail a local run against it, and say in
the spec why. This holds only where the difference is structural and named:
"it is slow here" is not a reason to stop asserting something.

> Rationale: Asserting a deployed number locally tests where the laptop is,
> not what the deployed system does.

<!-- source: METHOD.md 233-238 -->

### Measure the transport floor before attributing any latency to the system under test.  `[T1]` `[2026-08-12]`

Deploying does not remove the problem, because the measuring machine is still
not production. Take one request that does no work, and whatever the platform
will say about where the request arrived. A measurement whose floor is unknown
is not a slow result; it is an unread instrument.

> Evidence: A live-update figure read like the application until the floor was
> taken: a request that does nothing cost seconds, and a platform header
> reported every request entering the provider's network a continent away from
> both the application and its database.

<!-- source: METHOD.md 240-248 -->

### Measure that floor the way the system under test uses the network.  `[T1]` `[2026-08-12]`

A single cold request pays DNS, connection setup and a TLS handshake; an
application holding a warm connection never pays the handshake twice. Send
several requests over one connection and take the later ones. A floor measured
cold does not overstate latency a little — it overstates it by however long a
handshake takes.

> Evidence: The first attempt here reported a floor several times higher than
> the warm one, and the giveaway was an observed live update arriving *faster
> than the floor* — impossible, and therefore proof that the floor was
> measuring something the application does not do.

<!-- source: METHOD.md 250-260 -->

### There is not one floor — there is one per tier the request reaches.  `[T1]` `[2026-08-12]`

Take the floor whose request travels as far as the thing being measured. A
floor taken at the nearest tier makes everything behind that tier look like
the application's own cost.

> Evidence: From one machine over one warm connection, a cached static asset
> returned several times faster than a dynamic response that runs a function in
> another continent. Both are honest floors; they answer different questions.

<!-- source: METHOD.md 267-273 -->

### UI is verified by driving it, not by reading it.  `[T2 | T1 if: browser harness exists]` `[2026-08-12]`

A component that type-checks and builds has been proven to compile, nothing
more. Drive the running application in a real browser, assert on what the DOM
actually says — computed styles, element counts, the text a user would read —
and screenshot it to look at.

> Found: six separate traps, four of which are the rules that follow.

<!-- source: METHOD.md 275-278 -->

### A probe that finds nothing has usually found a wrong selector.  `[T0]` `[2026-08-12]`

A real absence and a mistyped selector produce the same empty result. Make the
probe assert something known-present first, so that "nothing here" is a claim
about the page rather than about the query.

> Found: one of six traps in a browser-driving investigation; the
> individual incident was not recorded.

<!-- source: METHOD.md 281-282 -->

### Scope a text match to the element under test.  `[T0]` `[2026-08-12]`

An unscoped match finds whichever element happens to contain the words, which
may be an ancestor or a neighbour that carries the same phrase.

> Evidence: A readout assertion matched the heading above the readout, which
> contained the same phrase, and would have passed had the readout never
> rendered at all.

<!-- source: METHOD.md 286-289 -->

### A coordinate measured on a page that updates itself is stale by the time it is used.  `[T1]` `[2026-08-12]`

Wait for the page to settle, then ask what is actually under the point before
dispatching anything to it.

> Found: one of six traps in a browser-driving investigation; the
> individual incident was not recorded. See also the
> intermittent-assertion rule below, which is the same trap measured
> over several runs.

<!-- source: METHOD.md 289-291 -->

### Wait for something only the loaded state can produce.  `[T1]` `[2026-08-12]`

"Wait for the data, not the page" is not enough when the empty state renders
the same shell as the loaded one. Pick a signal that cannot exist before the
data arrives. Then ask, of any empty state you write: is there anything on
screen that tells it apart from the real thing?

> Evidence: A component drew its grid in both states — same role, same
> accessible name, same cell markup — and the placeholder carried no handlers
> and no readout. A probe that waited for that group was satisfied by an inert
> copy, measured a cell on it, and interacted with something that could not
> respond. Days of "the handler never runs" followed, all of it true and none
> of it a bug.

<!-- source: METHOD.md 293-304 -->

### "The handler never ran" has a boring explanation before it has an interesting one.  `[T0]` `[2026-08-12]`

The element under the pointer may belong to a different render branch of the
same component. Establish which variant is mounted before suspecting the
framework or the input layer.

> Evidence: Recorded as a corollary of the investigation above, and named as
> one of the two things that cost it time.

<!-- source: METHOD.md 306-309 -->

### A rate that differs between two machines may be caused by neither of them.  `[T1]` `[2026-08-12]`

A shared dependency both machines reach can decide the outcome on its own.
This is why a confound gets named beside the number rather than concluded
from.

> Evidence: The difference between two machines' failure rates turned out to be
> the round trip to a shared database, which decided whether a fetch had landed
> before the probe interacted with the page. The tool-version difference the
> two machines also had — the confound named earlier in the same
> investigation — turned out to be irrelevant.

<!-- source: METHOD.md 309-315 -->

### Fix the timing, do not retry the probe.  `[T1]` `[2026-08-12]`

An intermittent assertion is worse than a failing one, because it gets re-run
until it passes and then believed.

> Evidence: A page whose header and list fill in asynchronously shifts
> everything below them; a probe that measured an element's position and
> touched those coordinates a moment later passed twice and failed once, with
> the feature working perfectly throughout.

<!-- source: METHOD.md 317-322 -->

### Assert the shape of the answer, not its presence.  `[T0]` `[2026-08-12]`

Any probe that would still pass on a plausibly broken render is measuring the
wrong thing. Assert something that depends on the computation behind the
output.

> Evidence: "Some cells are coloured" is satisfied by a scale that renders one
> colour everywhere. Grouping the cells by computed colour and requiring the
> group sizes to come out at specific counts is an assertion about the
> arithmetic behind the picture.

<!-- source: METHOD.md 324-328 -->

### Where an assertion needs a threshold, prefer one the codebase can defend.  `[T0]` `[2026-08-12]`

A threshold expressed relative to what the project already does can be argued
about and held to. A number borrowed from an external guideline invites a
redesign of everything that has never bothered anyone, and is the kind of
number that gets loosened the first time it is inconvenient.

> Evidence: "No control is a smaller tap target than the primary buttons
> already are" is defensible in review; the equivalent absolute figure from a
> platform guideline is not, in the same way.

<!-- source: METHOD.md 330-335 -->

### A translation is verified on what gets copied out of it, not on how it reads.  `[T1]` `[2026-08-12]`

Diff the copy-pasteable parts mechanically: strip the fences and the comments,
compare the remaining lines against the original. Give structure the same
treatment — matching counts of headings, code blocks and table rows is what
catches a section dropped during translation.

> Evidence: Prose can be clumsy and still work; a command that got translated
> along with the sentence around it cannot, and the reader will paste it
> without suspecting the document. Both checks together took one command.

<!-- source: METHOD.md 337-344 -->
