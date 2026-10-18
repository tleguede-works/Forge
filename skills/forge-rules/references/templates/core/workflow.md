# Template · Agent Operating Workflow

<!--
GENERATOR NOTES — delete this block in the emitted file.

How the agent operates in every session, independent of the domain being worked
on. This is the highest-density file in the set and the one with the most
duplication across the source projects: three separate files in three separate
projects carried near-identical copies of the code-hygiene rules, the
verification order, the file-size rule, the session-log protocol, and the
escalation ladder. This template is where each of those lives exactly once.

Canonical homes this file does NOT own — reference them, never restate them:

  - Escalation / stop-and-report ladder   → `AGENTS.md` §Escalation Rules
  - Git commits, branches, hooks          → `git-workflow.md`
  - File size & partitioning table        → `architecture.md`
  - Memory-file formats                   → the session journal / the decisions log
  - Style, naming, banned patterns        → `coding-standards.md`
  - Security rules                        → `security.md`
  - The gate commands themselves          → `quality-gates.md`
  - What a reviewer checks                → `code-review.md`

The §Pre-Commit Review below is the one place that *sequences* checks, so it
references the command gate it does not own (`quality-gates.md`) rather than
restating it. When a rule here needs to say "never do X", it must be X that is
not already banned in `coding-standards.md` §Banned Patterns, in
`git-workflow.md` §When Blocked, or in `AGENTS.md`. Otherwise it is a duplicate
with different wording — the exact failure this file was created to prevent.
-->

# Agent Operating Workflow

## Before Coding

1. **Read `AGENTS.md` first**, then only the rule files relevant to this task
   ({{mapping: UI work → {{file}} · data → {{file}} · forms → {{file}}}}). Do
   not read everything; the index in `AGENTS.md` is a routing table, not a
   reading list.
2. **Read the memory files** — the session journal in full at the start of every
   session; the decisions log for closed decisions touching this task.
3. **Explore the codebase before writing.** Understand the existing patterns,
   shapes, and entry points for this kind of work. **Do not invent parallel
   structures** — if a second pattern for the same concern already exists,
   matching it is correct; adding a third is not.
4. **Prefer editing existing files.** Create new files only when necessary.

## How to Code

1. **Match existing conventions exactly** — naming, folder layout, data-access
   shape, naming of tests. **Never introduce a second pattern for the same
   concern.**
2. **Keep changes focused and minimal.** No speculative refactors, no dead code,
   no drive-by changes bundled into a feature commit.
3. **Comment *why*, not *what*.** Doc-comment public APIs. Never write a comment
   that restates the line below it.
4. **When a project rule conflicts with a user request: implement the user's
   request, and flag the deviation in your reply.** Don't silently break a rule,
   and don't silently drop what was asked.

## Critical Thinking Checklist

Before non-trivial work:

1. **Is the request clear and coherent?** If not, restate the goal and the
   success criteria and ask **1–2 targeted questions** — bounded, not an open
   invitation.
2. **Is there a risk?** Triggers: a change across multiple files or layers; an
   impact on {{routes, theme, state, data model, performance, or security}}; an
   unstable public API; an unverified assumption. → List risks and mitigations,
   or options with their trade-offs.
3. **Does the request contradict a project rule?** → Prioritise project
   coherence and propose a conforming alternative. If it touches a closed ADR,
   stop and ask (`AGENTS.md` §Escalation Rules).
4. **External references guide structure and patterns only — never a runtime
   dependency, and never copy-paste from another stack or another project.**
   Re-derive names, imports, and conventions from *this* project. Check
   licences before substantial reuse. If a library name or file path occurs to
   you from a different codebase, stop and re-derive it.
5. **{{Stack}} APIs are verified against the installed version, not from
   memory** — `AGENTS.md` §{{stack verification section}}.

## Verification Order

**The gate table owns the commands. This section owns the order and the
failure behaviour** — because the same command run in a different order, or run
with a different response to a red result, is a different check.

```bash
{{1. lint}}
{{2. typecheck}}
{{3. test}}
{{4. stack health check, e.g. dependency/config doctor}}
```

Then the **full gate** — `{{gate command}}`, which adds coverage, duplication
and vulnerabilities (`{{quality gate file}}` §The Gate Table) — and the
**Definition of Done** in `AGENTS.md`, all items, checked, not assumed.

**Do not finish with a red tree.** Fix every issue you introduced. If the task
genuinely cannot be completed — an external dependency is down, a design is
missing — **stop and report instead of hacking around it.**

## Pre-Commit Review

### Start by seeing what is actually staged

```bash
git status
git diff
```

Review **all** uncommitted files, not just the ones you think you changed.

**This is your own diff, not a code review.** A review of someone else's work
is `{{code review file}}`, done by someone else, and the two are different acts
with different rules.

### Why the checks are ordered this way

**Order is by cost of skipping, not by importance.** A cheap mechanical check
that fails often goes first — it costs nothing and catches the most. A check
that requires understanding the change goes later, because those degrade with
fatigue. And a check that only sometimes applies is **conditional, not
sequential**: run on every diff, it becomes noise on the diffs it doesn't apply
to, and noise is how a check gets skipped on the diffs it does.

**An unfalsifiable item placed early is the worst possible combination** — high
attention, low yield. "Check for technical debt" is not a check; it is a
disposition, and it sits last in the judgement list for that reason. A vague
item near the top absorbs the review's attention and returns a paragraph of
prose.

### Systematic — every commit

**First the command gate:** `{{gate command}}` — the whole table
(`{{quality gate file}}`), plus the Definition of Done in `AGENTS.md` — every
item, checked, not assumed. Those commands are stated once, there; this section
does not repeat them.

**Then the judgement checks**, which no command covers:

1. **Conformance** — the change follows the project's rules, its architecture and
   its conventions. The rule-file table below is what makes this mechanical
   rather than a matter of taste.
2. **No unnecessary novelty** — no existing model, type, interface, constant,
   structure, component or module redefined when one already exists; existing
   elements reused. **A second copy of a canonical concern is a violation even
   when the canonical module "doesn't have it yet"** — add it there first.
3. **No magic values** — anything compared against or branched on more than once
   is a named constant, not a repeated literal
   (`coding-standards.md` §Magic Values).
4. **No debt made worse** — debt *noticed* and out of scope is recorded in the
   handoff; debt this change *creates or deepens* is fixed now, or the change is
   split.

### Conditional — security

Run this **only when the diff touches**: authentication or authorisation, a
secret or credential, input from an untrusted source, a permission boundary, a
dependency or its version, or a network/response surface.

- No secret or credential in the diff — including in a comment, a test fixture,
  a snapshot, or a config default.
- No trust boundary crossed without validation at that boundary.
- No newly externally reachable surface, and nothing previously internal now
  exposed.
- **Authorisation is still enforced where it was before.** A refactor that
  quietly drops a guard is the common failure here, and it is invisible in the
  diff's shape.
- Full rules in `security.md`.

### Mechanical greps

<!-- Enforcement commands, not descriptions. Run them. Adapt the patterns to the
     project's real conventions as it grows — the patterns show the shape, they
     are not literal commands to run unmodified. -->

```bash
{{# e.g. no data-layer calls outside the data layer — must return empty}}
{{grep}}

{{# e.g. no hardcoded design literals outside the token module — must return empty}}
{{grep}}

{{# e.g. no debug leftovers in the diff}}
{{grep}}

{{# e.g. no second copies of canonical modules — must return one path per concern}}
{{grep}}
```

If any returns hits → fix, or justify the hit explicitly in the commit message.

#### ⚠️ A grep whose expected result is "empty" must filter comments

A `grep -rnE` matches the **comment that explains why the rule exists**. So as
soon as the rationale is written down — which is the right thing to do, and which
you are told to do — a grep that must return empty can no longer do so.

The two requirements are **incompatible**, not one-or-the-other. You cannot
resolve it by weakening the rule or by deleting the explanation; the
explanation is the most valuable line in the file.

Pick per grep, and write the choice down:

| Situation | Form |
|---|---|
| The rule is "never do X" and X may appear in a comment explaining it | `{{grep-with-comment-filter}}` |
| The rule is "never do X", full stop, and no comment should mention it either | `{{grep}}` with a one-line note that the comment is also forbidden |
| The rule is "X appears exactly once" | `{{grep-with-count}}` — returns one path per occurrence, so a second copy is visible |

**Also check the regex dialect, not the intent.** A pattern written with `-E` and
a pattern written without it do not match the same lines; a real project
concluded "no-op" on a rule that matched 1 560 lines because it cited its own
grep without re-reading which flags it used. An exit code is not a result — see
`{{rules file}}` §Verification Discipline.

### Verify against the rule files

<!-- One row per emitted rule file. This table is what stops a review from
     silently skipping a domain. Add a row when you add a file. -->

| Rule file | Check |
|---|---|
| `{{file}}` | {{the specific thing to verify}} |
| `{{file}}` | {{...}} |

### Also confirm, when the change is new rather than a modification

These are covered in their own files, but they're the ones a modification to
existing code never trips — so they're worth naming here:

- [ ] Every **new** user-facing state handles loading, error and success — not
      just the modified ones.
- [ ] Every **new** module and screen has a test on its primary path
      (`testing.md`).
- [ ] If the project is mid-migration: this diff did not **extend** a deprecated
      pattern. Using one isn't yet a defect; adding to it is.
- [ ] `{{memory file}}` entry appended (`§Memory File Triggers`).

### When a check fails

This is where the discipline actually lives. A checklist without a stated
failure path degrades into either paralysis or quiet skipping.

- **Fixable inside this change** → fix it. Do not commit past it.
- **Needs a refactor that is out of scope** → **split the change**, or land the
  refactor first. Do not mix them.
- **Cannot be resolved without a decision** → **stop and ask.** Do not invent a
  workaround, and do not quietly drop the check.
- **Genuinely not applicable, and it is arguable** → say so in the commit
  message, with the reason. A justified skip is fine. A silent one is not, and it
  is the one that costs you the next person's trust in the whole rule set.

### Never

- Commit with a red tree, or carry a knowingly-broken state into the next
  session without recording it in the handoff.
- Disable a check, a lint rule, or a test to get a commit through.
- Skip a check "just this once" — once is how it becomes always.
- Commit a credential, on the assumption it can be revoked afterwards.

The process-level bans are in `AGENTS.md` §Escalation Rules; the git-operation
bans are in `git-workflow.md` §When Blocked.

## Side-Effects Rule

**Flag a consequence in the proposal, not as a confirmation gate.**

Flag when the change:

- deletes or replaces sections or files
- refactors something shared — *what imports break, what tests need updating*
- changes a shared type, interface, or constant — *which consumers are affected*
- modifies shared configuration — *what downstream behaviour changes*

Do **not** flag: fixing a typo, renaming a local variable, updating a comment,
reformatting. **Do not create confirmation loops for trivial changes** — most
reported "side effects" are insufficient pre-reading. Read enough context
before editing.

When you do flag, describe **what the result looks like**, not only what is being
removed.

**Batch edits on the same file.** Don't fire parallel edits that cascade on
failure.

## Code Hygiene

- **No commented-out code in a commit** — delete it, git history keeps it. A
  `TODO` explaining a real tracked follow-up is fine; a block wrapped in comments
  "just in case" is not.
- **No leftover debug output.** {{grep the diff for it before committing.}}
  {{A deliberate `{{error log}}` on a genuinely handled error path is fine.}}
- **No unused imports, variables, or branches.** Treat a lint warning about an
  unused import as something to fix, not to suppress.
- **No dead code** — unreachable branches, unused exports nothing calls.
- **No magic strings or numbers** outside a designated constants module
  (`coding-standards.md` §Magic Values).
- {{e.g. Strings and money go through their single source of truth
  (`{{constants module}}` §Strings).}}

## Memory File Triggers

**Mandatory triggers. Do not skip them.** The session-log trigger is the one that
cannot wait — see below.

| File | Append when | Format |
|---|---|---|
| `{{SESSION_LOG}}` | **At the opening of the session** — create the entry before writing the first line of code. Then a checkpoint at every moment below | Defined in the file itself |
| `{{DECISIONS}}` | A durable project-wide choice is made or closed — **as soon as you decide**, not when the decision comes back to you. Also when superseding an entry | ADR blocks, defined in the file |
| `{{LEARNINGS}}` | **The same mistake happens twice.** This is where new rules are born — from observed failure, not speculation | One line per correction, **naming the rule file it will be promoted into** |

### Why the session log cannot wait until the end

**A model with a million tokens of context survives to the end.** It still holds
the reasoning, and it writes one complete entry when it knows what it did. **A
smaller model does not survive**: compaction arrives first, and when the agent
comes back it knows *what* it did but no longer knows *why*.

What disappears first is not the result — it is in the diff. It is the
**rejection**: what was ruled out, and on what grounds. A lost rejection is a
decision re-litigated six months later, with a different argument.

So a write-at-the-end trigger is **the worst possible placement** — it only fires
if the agent survives long enough to reach it.

### The five checkpoints

One line each, at moments the agent **observes**. Never on a clock: a model does
not know what time it is, and a clock that does not fire is a silent trigger,
which is the defect being repaired.

| Moment | Why this one |
|---|---|
| **The session opens** | The entry exists from the start |
| **A phase changes** | Forge knows a phase changed — a signal, not a duration |
| **A slice starts** | The scope is fresh and known |
| **A slice ends** | Before any commit, while the file inventory is still accurate |
| **The context has just been compacted** | The summary just arrived. **This is the most important one** — it is the last checkpoint before the next |

Each checkpoint says, in order: **where I am** · **what I just decided** ·
**what I am doing next**. The third is what makes it useful after a compaction —
the agent reads "I am about to write the slice X plan" and resumes, without
re-reading the diff to find out where it stopped.

It does **not** contain a diff, a file listing, or a command output: that
regenerates from git, a synthesis does not.

**Promotion, both directions:**

- A correction in `{{LEARNINGS}}` that keeps recurring gets **promoted into the
  matching rule file**, and the rule file's provenance points back at the
  correction.
- A finding in `{{external-system-contracts}}` that has become generally
  applicable gets **promoted into the owning domain rule file**. A finding that
  never reaches a rule file has changed nothing.

> **A correction without a domain is incomplete.** The domain is the promotion
> target. Without it there is nowhere to promote to, so the entry cannot change
> behaviour, and the store degenerates into a diary that competes with the rules
> it was meant to inform — it gets read *instead of* the rule.
>
> Format: `- YYYY-MM-DD [domain: <rule file>] <rule that broke> → <correction applied>`
>
> A real project logged 43 corrections in a format without that field, and
> promoted zero. The reason was structural, not motivational: there was no
> target to promote into. The promotion rule above already existed, in this very
> section — so the gap was never the rule. It was the one field that makes the
> rule executable.

## When Blocked

Use `AGENTS.md` §Escalation Rules. Never:

- {{force-push}}
- {{delete the lockfile or dependency directory to clear an error}}
- {{skip lint or typecheck to make a commit land}}
- {{weaken a security, type, or validation rule to unblock a feature}}
- {{verify a feature on a platform it does not support and call it tested}}
- {{ship a placeholder value where a real one was required}}
- {{commit with a failing or skipped test}}
