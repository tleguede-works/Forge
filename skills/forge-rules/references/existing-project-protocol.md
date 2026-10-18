# Existing Project Protocol

For a project that already has code, and possibly already has instruction files.
The risk this protocol manages: **generating rules that contradict the code they
claim to describe**, which is worse than generating no rules — an agent that reads
a rule contradicting the codebase will either follow the rule and break the code,
or follow the code and ignore the whole file.

Two steps exist here that the skill did not previously have, and they are the
reason this file exists: **detecting what the project actually does**, and
**deciding what to do about the difference**.

## Mode detection

Run first. It is a probe, not a question.

| Signal | Mode |
|---|---|
| No `AGENTS.md`, no `CLAUDE.md`, no `.opencode/`, no `.cursor/rules/`, no `.github/copilot-instructions.md`, no `CLAUDE.local.md` | **Bootstrap** — the project is empty of instructions. `SKILL.md` §Bootstrap |
| Any of the above present, or instruction files present but empty or a stub | **Adoption** — this protocol |

**An existing project with a single `README.md` and no instruction files is
Bootstrap.** A README is documentation, not rules.

**Adoption on a project with no code** (instruction files but an empty tree) is
Bootstrap with a prior — the existing instruction files are the material to
consolidate, and Step 5b's content-preservation audit applies to them.

## Choosing a depth: light or full

**The full protocol below is the right answer for "set up rules for this
codebase". It is the wrong answer for "I'm adding a feature and I want the
rules to cover it."** Those are different requests and they should not cost the
same.

| | **Light** | **Full** |
|---|---|---|
| Use when | A feature is about to be written; the user did not ask for an audit or a migration | The user asked to set up rules, consolidate rules, or migrate conventions |
| Detection | **3 dimensions**, sampled — folder structure, data access, tests | All 14 dimensions, exhaustive, each with `file:line` |
| Gap report | One paragraph: what the project's patterns are | The full three-list report |
| Human gate | **None** | Step C, before drafting |
| Can run unattended | Yes | No |
| Cost | Minutes | Hours on a large codebase |
| Output | Core tier + the domains the feature touches + the project-specific conventions, with evidence | The complete set |

**Detect the light path, don't ask for it.** Signals: the user described a task
rather than asked for rules; the request names a feature, a bug, or a file; the
project already has rules and the question is whether they cover the new work.
In every one of those cases, run light, deliver, and offer the full protocol
afterwards — "this covered what your change touches; want the other eleven
dimensions audited?" is a question that costs the user nothing to decline.

**The full protocol is never skipped because it is expensive.** It is skipped
because the user did not ask for it. If light mode reveals a problem that implies
a broader issue — a second pattern for the same concern, a convention that
contradicts itself — **say so and offer the full protocol**, rather than
silently expanding scope.

## Step A — Convention detection

**Read the code before writing a single rule.** This is the step whose absence
produces the failure this protocol prevents.

### What to detect

Read the actual code, not the manifest, for each of these. For each, record what
you found **and the file you found it in**.

| Dimension | What to look for | Recorded as |
|---|---|---|
| Folder structure | The actual top-level layout and what lives in each; a feature-per-folder convention, a layer-per-folder convention, or neither | The observed tree, annotated with what each folder holds |
| Naming | Real filenames and identifiers: components, hooks, types, constants, handlers, collections | The observed convention per kind, with two or three real examples |
| Import discipline | Relative or aliased; ordering; barrel usage; extension style | The observed rule |
| State management | Which library, how state is read, how mutations are expressed, how invalidation happens | The observed pattern, with a file reference |
| Data access | The path from a screen to the data; whether there's a single client; how errors are normalized; where models and types live | The observed shape |
| Forms | Whether forms exist at all; which library; how validation is expressed; how server errors surface | The observed pattern |
| Routing | File-based or central table; how paths are written; where auth redirects live | The observed rule |
| Error handling | What a failure looks like in the UI; whether errors are swallowed; what the normalized type is, if any | The observed pattern |
| Testing | Whether a runner exists; what it is; what the tests look like; whether anything is skipped | The observed state — including the gap |
| UI | Which component library; how theming works; where shared components live; how state components are handled | The observed pattern |
| Accessibility | Whether roles and labels are present; whether there's a convention at all | The observed state |
| Security | How secrets are handled; where they live; what reaches the client | The observed practice |
| Performance | Whether there is a measured concern, a list convention, an image policy | The observed state |
| Commit format | The actual recent history | The observed format |
| Lint and format | The real configuration and which rules are actually enabled | The observed config |

### How to record it

Each detected convention is a line with three parts:

> **{{Convention}}** — {{what it is}} — evidence: `{{path:line}}`

**The evidence is not optional.** It is what makes the convention checkable later
and what lets the user see, at a glance, whether you understood their codebase.

A detection pass that produces conventions with no file references has produced
guesses. Re-read until each has a reference, or drop it.

### What not to detect

- **Do not detect a convention from a single occurrence.** Two files with the
  same shape is a coincidence until the third appears. Say "two instances,
  unconfirmed" rather than asserting a convention.
- **Do not detect a convention from a file nothing imports.** A helper nobody
  calls is not the project's convention; it's a leftover.
- **Do not infer a convention from a framework default.** "It uses the router
  library's file convention" is not a project convention.
- **Do not detect a convention the project's own tooling contradicts.** If lint
  says one thing and the code does another, the code wins the argument and the
  lint config is a finding.

## Step B — Gap report

Compare detected against the template set that `stack-detection.md` selected, and
produce three lists.

| List | Contents |
|---|---|
| **Agreements** | Where the project already does what the template says. The rule is emitted as a normal rule, and the agreement is worth saying — it tells the user the template matched their codebase |
| **Divergences** | Where the project does something else, consistently. **This is not an error.** It becomes either a preserved rule (Option 1) or a migration target (Option 2) |
| **Gaps** | Where the template has a rule and the project has no practice at all — no error handling, no form validation, no test coverage. **Also not automatically an error**: it may be a deliberate state, or out of scope. It becomes a rule to follow going forward, or a flagged finding |

**The gap report is shown to the user before any rule is drafted.** It is the
input to the choice in Step C, and drafting first and asking later wastes the
whole detection pass.

**Size the gaps.** A rule that contradicts one file is a five-minute change. A
rule that contradicts forty is a project. Sizing is what lets the user choose
sensibly, and it is the input to the migration sequencing in Option 2.

## Step C — Two options, offered explicitly

Present both. State which one the detection pass suggests, and why. Do not pick
silently, and do not ask a question that implies one answer is correct.

### Option 1 — Preserve

**The project's existing conventions become the rules.**

- Each rule states what the project actually does, with its evidence reference.
- The template's version of that rule is **not** emitted. The project's version
  wins.
- A divergence that the user wants to stop is expressed as a *constraint* rather
  than a replacement: **"`X` is the established pattern; do not introduce a
  second approach to it."** This prevents drift without demanding a rewrite.
- The template's *rules with no counterpart in the project* are emitted as-is:
  there's no existing practice to contradict, so the template is the only source.
- A gap is emitted as a rule to follow going forward, and separately reported as
  a finding. **The user may choose not to adopt it** — and that choice is
  recorded, so the next run doesn't re-propose it.

**Use when:** the codebase is healthy, the conventions are deliberate, the
divergences are a considered choice, or the project's pattern differs from the
template for a reason the user can state. This is the right default for a
codebase that is working.

### Option 2 — Migrate

**The template's foundation becomes the target, and the gaps become a staged
plan.**

Produces a `MIGRATION.md` at the project root:

| Column | Contents |
|---|---|
| Current | The convention as detected, with its evidence |
| Target | The convention the template specifies |
| Files | How many files are affected |
| Effort | {{small: under 10 files, mechanical · medium: 10–40, or a judgement call per site · large: over 40, or it touches a shared contract}} |
| Risk | {{what breaks if it's half-done — a half-migrated shared contract is worse than either end state}} |
| Stage | Which migration stage, below |

**And it produces coexistence rules**, which is the mechanism that makes a
migration gradual rather than a flag day:

- **Both shapes are currently permitted.** A new file uses the target shape; an
  existing file isn't rewritten as a side effect of an unrelated change.
- **The deprecated shape is marked as deprecated** at its definition, with a
  pointer to the target. A rule that presents both shapes as equally acceptable
  is a rule that produces a codebase that never converges.
- **The deprecated shape is not extended.** Adding to it is a defect, even
  though using it isn't yet.
- **Every coexistence rule has a removal condition** — a specific, checkable
  statement of what finishing the migration looks like. A coexistence rule
  without one is permanent, and permanent coexistence is the outcome this option
  exists to avoid.

**Migration stages**, in order. Later stages depend on earlier ones:

1. **Stop the bleeding.** No new code uses the deprecated shape. Nothing else
   changes. This stage alone captures most of the value and is safe to do
   immediately.
2. **Move the shared contracts.** The centralised modules — the client, the error
   type, the token module, the token file. **This is the highest-risk stage and
   the one that must not be half-done**: a shared contract with two live
   implementations is worse than either.
3. **Migrate the leaves.** Feature-local code, one feature at a time, each as its
   own change.
4. **Delete the deprecated path.** The rule, the helper, the alternative shape.
   **A migration that never deletes anything has not migrated; it has doubled.**

**Use when:** the user wants the foundation, the divergences are accidents rather
than decisions, the gaps are real risks, or the project's conventions are
actively costing something. **Not** when the codebase works and the divergences
are deliberate.

### Choosing between them, and combining

The options are not exclusive per project — they are per dimension. A project can
preserve its data-access convention (a considered choice, and the template's
client rule would be an improvement they'd decline) while migrating its form
validation (a genuine gap with a real failure mode).

**Offering the choice per dimension is better than offering it once for the
whole project**, and it is usually what the user actually wants. The gap report's
three lists make the split natural.

**If the user declines both** — wants neither preservation nor migration, only
new features to follow the template — that is a third valid position: emit the
template's rules scoped to new work, leave the existing code alone, and record
that the existing code is explicitly out of scope. Say that in the rules, so a
future session doesn't try to fix it.

## Step D — The external-contracts file starts from history

In adoption mode, `domain/external-system-contracts.md` is not emitted empty.
**The existing project has already discovered things** — they are in its git
history, its issue tracker, its comments, its docs, its tests that encode a
workaround.

Look for: commit messages describing a fix for unexpected behaviour; comments
explaining a workaround; a test asserting something surprising; a doc explaining
why the obvious approach doesn't work. Each is a candidate entry, and each needs
confirming against the current external system before it ships as a rule — a
workaround that was removed two years ago is not a contract.

If nothing is found, emit it empty. That is the correct initial state and not a
failure.

## Step E — Audit

The standard audit, plus two adoption-specific checks.

**Check 1 — no rule contradicts the code.** For each emitted rule, confirm the
code doesn't already do the opposite in a way that's load-bearing. A rule
contradicting a working implementation is the specific failure this protocol
exists to prevent, and it is invisible to a redundancy or contradiction check —
those compare the rule set against itself.

**Check 2 — every divergence is accounted for.** Every item in the gap report's
divergence list is either a preserved rule or a migration target. An unaccounted
divergence is a rule that was silently dropped, and it is the same class of loss
as the silent content loss in `postmortems.md` Case 1.

Then report, **against a stated denominator**:

> *Of the **N** conventions detected in Step A: **A** preserved as rules, **B**
> migrated with a staged plan, **C** recorded as "do not introduce a second
> pattern", **D** reported as findings and not adopted. Separately: **E** template
> rules emitted where the project had no practice. **F** divergences unaccounted
> for — this must be 0.*

**The denominator is the Step A count, and it is counted before drafting.** A
reconciliation figure with no denominator is not a measurement — it is a number
the agent chose, and it will be wrong in whichever direction flatters the result.
If Step A was sampled rather than exhaustive, **say the sample size and the
dimensions sampled**; a coverage claim from a 3-dimension light pass is not a
coverage claim.

In light mode the same form applies with `N` = the 3 sampled dimensions, and the
report says so explicitly.

## Step F — Read-back

**Ask the project, not the template.** The cold-read test (`SKILL.md` §Step 6)
still applies, but in adoption mode it has an extra question:

> *Ask: what is this project's state-management pattern? What is its error
> handling convention? If the answers don't match what the code actually does,
> the rules are describing a project that doesn't exist.*

A ruleset that describes the template rather than the project is the failure this
whole protocol prevents. The read-back is how you catch it before delivery.
