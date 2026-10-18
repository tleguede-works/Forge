## Workflow

### Step 0b — Scan, and let the scan decide

**Run this before Step 1, and before any threshold is written.** Protocol in
`references/baseline-scan.md`; run it, don't read it and describe it.

The scan answers three questions in one pass, and all three used to be answered
by guessing:

1. **What is the stack, exactly?** — resolved from the manifests, not from an
   impression of them.
2. **Is the project green today?** — every gate, run, with the output captured.
   A rule set written on a project whose lint is already red must say so, or its
   Definition of Done is red on arrival and gets ignored on day one.
3. **`greenfield` or `ratchet`?** — **derived from the scan, never asked.**
   Asking makes the mode a preference; deriving it makes it a consequence, and a
   consequence is identical on two runs of the same repository.

A mode decided by interview varies with the agent's mood and with the phrasing
of the question. That variance is what produced a 6-file rule set on one project
and a 17-file one on another from the same template library.

Write the result to `docs/quality-baseline.md` — a project artefact, not part of
the rule set — and report it in the six-line form the protocol gives.

**"The command is not installed" is a result.** Record it as `absent`, propose
the installation, and emit the gate with that status. **Never** write a baseline
number that no command produced.

### Step 1 — Probe, then interview

Take the stack the scan resolved, run the detection probe
(`stack-detection.md`), match the table, produce a proposed template set. Don't
ask what the repository already says.

**Then ask only the gaps the probe can't close.** Often one or two questions:

- **Target format** — the one question that can't be inferred. See
  `references/target-formats.md`. **If the user has already stated a preferred
  structure, that is the specification, not a default to improve on.**
- **Git strategy** — trunk-based, git-flow or release-train. Also not
  derivable: both branches cost something, and they are not reversible by the
  same amount. With no preference, choose trunk-based and record it in
  the decisions log; "no strategy" is the only option nobody can reverse.
- **Variants that are decisions rather than detections** — router, rendering
  strategy, whether a state library is wanted. A component-library axis is
  settled by what's installed; a data-access axis is a decision, so ask.
- **Monorepo or single app**, and for a monorepo, which packages are in scope
  (`references/monorepo-strategy.md`).
- **Team or solo** — affects how much day-one scaffolding is worth it.
- **Anything already decided** — closed decisions, an existing memory system, a
  design contract, a deployment story.

**If the user says "just generate something reasonable for X," don't force the
interview.** State the assumptions you're filling in and proceed. Confirm only
what would silently produce the wrong architecture — the target format is the one
that qualifies.

**Do not ask about the thresholds.** They are decided in `baseline-scan.md`
§Mode selection, and asking reintroduces exactly the variance the scan was
added to remove.

### Step 2 — Verify against real sources

**Before writing any technology-specific rule, work down the ladder in
`references/documentation-sources.md`.** The project itself first — the
manifest's exact version, the installed source, the shipped type definitions.
Then what the framework bundles for agents. Then configured MCP servers, checked
rather than assumed. Then official documentation **for the exact pinned
version**. Then the installed CLI's own help. Web search last.

**Every technology-specific claim carries a provenance marker** naming its rung,
or it's marked as a project decision with its ADR. **A claim you can't source
becomes a question, a proposed ADR, or an unconfirmed entry in
`external-system-contracts.md` — never a rule with a hedge.** "Probably X, but
verify" carries a rule's authority and a guess's reliability, and the agent acts
on it.

**Do not skip this step because the framework is familiar.** The failure it
prevents is invisible: the code compiles, looks idiomatic, and calls an API that
moved two releases ago.

### Step 3 — Choose the mode

Run the mode probe (`existing-project-protocol.md` §Mode detection). It's a
lookup:

- **No instruction files present** → Step 4.
- **Instruction files present** → **run the full existing-project protocol**,
  and in particular **Step A: detect the project's actual conventions before
  drafting a single rule.** Read the code, not the manifest. Record each
  convention with a `file:line` reference. Produce the gap report, show it to the
  user, and let them choose per dimension between preserving the project's
  conventions and staging a migration. **A rule contradicting a working
  implementation is worse than no rule** — the agent will either follow the rule
  and break the code, or follow the code and distrust the whole file.

**A project with a README and no instruction files is a bootstrap, not an
adoption.** A README is documentation, not rules.

**On a project with no code yet:** the detection probe matches the manifest and
nothing else. Every conditional-domain signal — a form, a test runner, a
localisation layer, a design contract, an external system — requires existing
code, so on day one the probe returns the core tier plus whatever the manifest
names, and the domain selection becomes a **question, not a lookup**. Say that
plainly rather than presenting a table that turned out to have nothing to match,
and do not report the day-one omissions as findings — "no test runner
configured" is true and worthless before any code exists.

### Step 3b — Measure the set before delivering it

```bash
# the target's actual instruction surface
find .opencode/rules -name '*.md' -exec cat {} + | wc -l
wc -l AGENTS.md
```

Compare against the budget for the target chosen in Step 1 (Principle 6b). If it
is over:

- **Move trigger-based content out of always-loaded files.** A section that
  applies only when a diff touches auth, or only inside one monorepo service, is
  being paid for on every session it does not apply to. This is the only lever
  that works on a glob-loaded target.
- **Compress the framing, never the rule.** A rule loses its justification clause
  before it loses its threshold, its command, or its ban.
- **Cut whole rules last**, and tutorial prose only. Budgets are ceilings, not
  targets — but a set 2× over a ceiling is a defect, not thoroughness.

### Step 4 — Draft

Fill each selected template. Three things to get right:

- **Section order is fixed and it is a priority order**: commands → definition of
  done → escalation → task-organised sections → versions and banned patterns →
  style last. An agent needs to know how to build before it needs to know how to
  format. **Style is last and is the first thing cut.**
- **Task-organised sections, not flat bullet dumps** — "when writing X", "when
  reviewing X". This is where operational-prose decision rules live, and they're
  the first thing lost in a flat list.
- **Point at one canonical example already in the codebase** rather than pasting
  a code sample. Pasted code goes stale silently; a file reference doesn't.
- **Carry the why on the rule, in one clause.** A template's `GENERATOR NOTES`
  block is deleted on emit, so anything an agent would need in order to apply a
  rule to a case the template didn't anticipate has to live on the rule itself
  (`rule-file-template.md` §The Generator Notes contract). Derivation belongs in
  the notes; application belongs on the rule.

**Three operations, and they are not interchangeable** — know which one you're
doing before merging anything:

| Operation | What happens | When |
|---|---|---|
| **Absorb** | Full content transfers to the target at comparable depth; the source is deleted because its content now lives there | The source's rules genuinely belong in the target's scope |
| **Reference** | The source stays; the target points at it by name **and section** | The source is too large or too specific to inline |
| ~~Delete and mention once~~ | Replacing substantive rules with a grep or a one-liner | **Never.** This is silent content loss wearing a structural disguise |

**After absorbing anything, verify immediately** — before moving to the next
file, while the source is still open:

1. List every discrete rule in the source: numbered items, thresholds, banned
   patterns, decision rules. Not just commands.
2. Confirm each appears in the target at comparable depth — a full sentence or
   an enforcing command, not a passing mention.
3. **If the rule count drops, something was lost — not condensed.** A 94-line
   source producing three bullets in the target is a signal, not a success.

### Step 5 — Audit

**Part A is a command. Run it before reading anything.**

```bash
forge rules audit <project> --target opencode --budget 800
```

Ten decided checks — wiring, index, placeholders, cross-references,
contradictory thresholds, coupling to the Forge tool, contamination, unenforceable prose,
gates, budget. **A failure is a defect, not a discussion.** Fix it and re-run.
`tests/rules.sh` in the Forge repository proves each check detects what it claims to, so a pass is evidence and not a formality.

**Then Part B**, the judgement half of `references/audit-checklist.md`. Do not
automate it and do not report it as verified when it was not. The sections that
catch what the others can't:

- **Content preservation** — for a consolidation. Redundancy and contradiction
  checks compare the new set against *itself*; a set can be perfectly
  non-redundant while having lost a third of its rules. Requires a reconciliation
  count: *"N rules preserved, M absorbed with cross-references, K lines of
  tutorial prose cut (listed)."* If you can't state that number, you haven't
  checked.
- **Cross-project contamination** — for an adoption or a port. Part A catches the
  mechanical form; this catches the semantic one, where a borrowed idea is
  expressed in this project's vocabulary and therefore looks native.
- **Contradiction with the code** — for an adoption. For each rule, confirm the
  code doesn't already do the opposite in a load-bearing way. **No other check
  catches this**, because it compares a rule set against a codebase, not against
  itself.
- **Provenance** — every technology-specific claim traceable to a rung of the
  ladder or to an ADR.
- **Promotion** — for a project with an `external-system-contracts.md`: no
  finding sitting unpromised next to a rule it contradicts, and no finding that
  has applied beyond its first case for several sessions without reaching a rule file.
- **Divergence** — for a consolidation or an adoption with a migration: every
  detected divergence is either a preserved rule or a migration target. An
  unaccounted one is a rule that was silently dropped.

**Also check:** every "always apply" rule genuinely applies to every session
rather than being secretly scoped; every conflicting priority pair is ranked; no
instruction fails all four checkability tests (a command, a glob match, a
banned-list lookup, or the Principle 1 "would the agent violate this?" test) —
**rewrite the ones that fail, don't cut them on sight**; per-file line counts as
ceilings; every file is referenced from the index; the emitted index lists every
emitted file and no others.

### Step 6 — Wire, deliver, and set up the loop

**Wire the target format — this is part of the deliverable, not a follow-up.**
Generating Markdown without the file that makes the tool load it produces a
complete-looking, entirely inert rule set (`target-formats.md`).

**Merge, never overwrite.** An existing config file carries the user's model,
provider, and tool configuration. Add the keys; don't replace the file.

**Verify the wiring** before declaring done: the config parses; every path it
points at exists; **a glob that matches nothing is a valid configuration that
loads nothing.**

Then tell the user three things:

1. **Where the living-learnings section lives** — one canonical spot. A correction
   is added when the agent gets something wrong *twice*, not speculatively. If the
   project already has a cross-session memory system, wire learnings into the lessons log
   rather than creating a parallel mechanism.
2. **The read-back test.** From a cold session, ask the agent for its build
   command, its definition of done, and which rule files govern a given area. If
   it can't answer, the file is too long, too vague, or not being discovered.
   **Fix that before adding more content** — more rules behind a broken wiring
   are more rules that never load. In adoption mode there's a fourth question:
   *what is this project's own pattern?* If the answer describes the template
   rather than the project, the rules are wrong.
3. **The audit result**, in the reconciliation form from Step 5.

**If the templates were wrong** — a tech overlay's mechanism didn't apply, a
domain template had a rule that didn't survive contact with the real project —
**fix the template file, not just the delivered output.** The template is what
the next project copies. A correction that isn't applied there helps nobody, and
the same defect will ship again.

