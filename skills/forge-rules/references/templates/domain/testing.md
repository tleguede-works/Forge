# Template · Testing

<!--
GENERATOR NOTES — delete this block in the emitted file.

The opening status block is not optional and not decoration. Every audited
project independently arrived at the same finding: a Definition of Done line
saying "tests pass" is meaningless — and actively harmful — while no runner
exists, because the agent learns to report "done" on a line nobody verifies.
Two of the three sources state it almost word for word. Emit the status block
whenever the gap exists, and make the DoD line say "aspirational" in the same
breath.

The project-specific half of the harness (runner, library, layer table) comes
from the tech overlay or from the project's actual configuration. The rules
below hold regardless.
-->

# Testing Rules

## Status

<!-- Emit one of these two blocks. Never leave both, never leave neither. -->

<!-- Emit when NO runner is configured: -->
> **No test runner is configured yet.** The "tests pass" line in the Definition
> of Done is **aspirational** until a runner exists. Do not silently treat it as
> satisfied, and do not skip it silently forever — flag the gap, and treat adding
> a runner as a prerequisite for that line meaning anything.
>
> **Interim gate, until a runner exists:** {{the strongest manual verification
> this project can actually do — e.g. a smoke test of each changed flow on a real
> build against a real environment}}. Manual verification is **not** a substitute
> for tests; it is the best available gate today, and it should be recorded as
> provisional.

<!-- Emit when a runner IS configured: -->
> Runner: `{{name and version}}`, configured in `{{config file}}`. The commands
> below are the ones this project actually uses — confirm them against
> `{{manifest}}` rather than assuming a default runner.

## Commands

```bash
{{test command}}                 {{unit + component}}
{{test command}} --watch         {{if supported}}
{{test command}} --coverage      {{if supported}}
{{e2e command}}                  {{critical journeys only}}
```

**Confirm the actual runner and its real CLI. Do not assume the ecosystem
default** — a project that configured a different runner will silently get wrong
commands.

## Definition of Done

A tested change is complete when **ALL** of:

1. The suite passes.
2. **New or changed business logic has at least one test covering the primary
   path**, plus at least one error or edge case.
3. **Every normalizer/mapper has a round-trip test** — raw → model → raw.
4. **Every validation schema is tested directly** — valid input passes, each
   invalid case produces the expected field error.
5. No test was skipped, commented out, or deleted to make the suite pass.

<!-- Item 3 and 4 are the two most commonly missed and the two that catch the
     most. A mapper tested one way proves nothing about the inverse. -->

## Status Gating

- **Never skip, comment out, or delete a failing test to unblock a commit.**
  Fix the code, fix the test, or escalate. A skipped test is a silent deletion
  of a requirement.
- **`{{it.skip}}` / `{{@Ignore}}` is for a documented, tracked reason only**,
  with the reason in the test and a reference to the issue. "Flaky on CI" is
  not a reason; a race that needs fixing is.
- **A test that asserts nothing is worse than no test** — it passes forever and
  reports nothing. If you can't assert an outcome, don't add the test yet.
- **A new test must be able to fail.** Before committing a test, confirm it
  fails against the broken behaviour — otherwise it isn't testing the thing.

## Behaviour, Not Implementation

- **Assert on what the user sees and what happened**, not on which internal
  function was called. A test coupled to an implementation detail fails on every
  refactor and protects nothing.
- **Prefer the most realistic interaction available** over the lowest-level
  simulation. {{e.g. the higher-fidelity user-event helper over the raw fire
  helper.}}
- **Assert on the contract, not the wording** of a message. Assert that an error
  is shown, not that it says a specific sentence — unless the exact string is
  itself a requirement.

## Mock at the Boundary

- **Mock the boundary you don't own** — the network client, the external API,
  the platform module. Do not mock the framework's internals or your own logic.
- **One mocking approach, decided with the runner.** Three coexisting mocking
  libraries in one project is a defect.
- **A mock that drifts from the real contract is worse than no mock** — it
  passes tests against a shape the server never returns. Prefer a fake
  implementation with the real interface over a loose stub.
- **Don't mock what you're trying to test.** If the logic under test is the
  transformation, mock its input, not its output.

## What to Test

| Kind | Test it for |
|---|---|
| Pure functions, formatters, helpers | the boundary cases, including the empty and the extreme |
| Validation schemas | valid passes; each invalid case produces the right field error |
| Normalizers / mappers | **round trip** — raw → model → raw, and the null-handling case |
| {{Domain model}} value objects | construction, equality, validation in the constructor |
| Orchestration / controllers / hooks | state transitions, the error path, the double-call guard |
| Error mapping | each failure kind maps to the right normalized kind and message |
| Components | rendering, the states, the interactions, the accessible wiring |
| Routing / navigation | route resolution, redirect logic, the auth guard |
| Integration | the real wiring between two units that actually talk to each other |
| E2E | **critical user journeys only** — see below |

**A new public method on an orchestration unit has at least one test.** If a
method is never called, it should not be public.

## Structure & Naming

- **Co-locate tests with the code**: `{{name.spec}}` next to `{{name}}`.
- **File name matches the unit under test.**
- **Group name is the class or the concept** under test.
- **Test name is a sentence starting with an action verb** — *returns*,
  *throws*, *preserves*, *emits*, *rejects*. `{{should work}}` and
  `{{test 1}}` are not names.
- {{e2e file}} — one file per journey, named for the journey
  (`{{checkout-completes.spec}}`), not for the page.

## E2E Scope

**Critical user journeys only.** {{Define them explicitly: e.g. sign-in/out,
the primary create-or-purchase flow, the navigation shell.}}

- **If a behaviour can be verified by a unit or component test, write that
  instead.** E2E is the most expensive and most flaky layer; spending it on
  logic is spending it badly.
- **One file per journey. Grow the suite from observed regressions**, not from a
  coverage target. A new critical journey gets one test; nobody attempts
  exhaustive end-to-end coverage.
- **Keep the suite fast enough to be run before every commit** —
  {{project decision on the acceptable duration}}. Large E2E suites are slow and
  flaky, and a suite nobody runs is a suite that isn't testing anything.
- **Against the real application entry point, not a test-only wiring.** Fakes in
  an E2E test defeat its purpose — it is testing a different app.
- {{e2e-specific}}: **use generous timeouts and unique test data.** A fixed
  generated name collides with the previous run's data; append a timestamp or a
  random suffix. **Confirm any string-length limits the backend imposes before
  generating test data**, or the generation itself fails validation.
- {{e2e-specific}}: **an external device or browser is required for the real
  flow.** A host-only CI runner cannot run these — say so, rather than letting
  the suite silently not run.

## Coverage

- **Pick a target appropriate to this project and state it in `AGENTS.md`.** An
  unstated target is not a target. {{e.g. 80% on utilities, schemas, and
  orchestration; no target on view code.}}
- **Coverage measures what was executed, not what was verified.** A high number
  with weak assertions is worse than a lower number with real ones. Do not
  raise the number by writing assertion-free tests.
- **Coverage is a floor for the layers where a regression is expensive**, not a
  goal for the whole codebase.

## Environment vs Logic

> **When a test run fails for a reason that looks environmental rather than
> logical — a config resolution failure, a missing global, a runner/framework
> version mismatch — check the runner's documentation for this specific
> combination before assuming the test is wrong.** Rewriting a correct test to
> work around a configuration problem destroys the test and hides the problem.

{{Platform-specific environment gotchas belong in the tech overlay's footgun
table, not here.}}

## When Blocked

- **If a test fails: fix the code or the test.** Do not delete it, do not skip
  it, and do not weaken the assertion until it passes.
- **If a test needs temporary debugging: add it, run it, read the state, then
  remove it** before committing.
- **If setting up the runner itself fails: stop and report the exact error.** Do
  not work around it by verifying manually and calling it done — permanently.
- **If the behaviour under test is genuinely untestable without a refactor:**
  say so, and treat the refactor as a decision rather than a workaround. Don't
  contort the design to make a test writable.
- Never: raise a timeout until a test passes; assert on a value you just
  computed in the test; mock the unit under test.

## Canonical Example

Once `{{the first test over a normalizer or the first orchestration unit}}`
exists, treat `{{path/to/that/file}}` as the reference for test structure and
naming.
