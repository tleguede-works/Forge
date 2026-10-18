# Postmortems

Real failures from prior runs of this skill, kept verbatim-in-spirit so the same mistake doesn't repeat. Read this before any **consolidation** task (existing rules being reorganized) — this is where the failure mode below actually bites; it's much less of a risk on a fresh, no-prior-file bootstrap.

## Case 1 — Silent content loss during consolidation (ace3i-bankingsms-ui, OpenCode, 18 files / ~2,500 lines)

### What happened

Asked to consolidate an existing 18-file `.opencode/rules/` set. The agent running this skill applied "ship a lean skeleton" (Principle 4) to an *existing* set instead of a fresh one, and treated the line-count budget as something to minimize. Result: six files were "merged" into neighbors, but the merge collapsed full rule sections into one or two bullet points or a single grep command.

| Original file | Lines | Absorbed into | Lines surviving | Lines lost |
|---|---|---|---|---|
| `file-size.md` | 94 | `workflow.md` | ~5 | ~89 |
| `routes.md` | 114 | `architecture.md` | ~2 | ~112 |
| `side-effects.md` | 44 | `workflow.md` | ~6 | ~38 |
| `error-handling.md` | 205 | `performance.md` | ~4 | ~201 |
| `security.md` | 141 | `performance.md` | ~10 | ~131 |
| `accessibility.md` | 199 | `accessibility.md` | ~6 | ~193 |

~764 lines of operational rules absorbed, ~73 survived the first pass. The user caught it on review; it was not caught by the skill's own audit checklist, because that checklist (at the time) only checked redundancy/contradiction/vagueness/structure — all of which can pass perfectly on a set that lost a third of its content, since those checks only compare what's present against itself.

### Root causes (each one is now a fix in this skill — see SKILL.md)

1. **Only two content tiers existed ("cut prose" / "keep commands").** A sentence like *"Split by responsibility, not by lines — a 250-line single-responsibility file is fine"* is a real decision rule with no backtick command, so it got misclassified as prose and cut. → Fixed with the three-tier test in Principle 1 (tutorial / operational prose / verifiable command) and the "would the agent violate this?" test.
2. **"Merge small files into neighbors" had no depth requirement.** Structurally the merges were correct (right neighbor, right domain) — the failure was invisible at the structural level and only showed up in content. → Fixed with the absorb/reference/delete distinction (Step 4) and mandatory Step 4b verification immediately after each merge.
3. **The budget felt like a target.** Seeing 18 files / ~2,500 lines created pressure to compress toward the ~500-line-per-file ceiling, and that pressure landed on content, not on the tutorial-prose fat that should have absorbed it. → Fixed with Principle 5 ("ceilings, not targets") stated explicitly, in more than one place, so it survives skimming.
4. **No comparison step existed between "before" and "after."** Nothing in the original workflow ever re-opened the source files after drafting the target and checked whether their rules had a home. → Fixed with Step 5b (content preservation audit) and the matching checklist section in `audit-checklist.md`, which requires a reconciliation count before delivery.
5. **"Start from a skeleton" was applied to the wrong situation.** That principle is sound for a project with zero existing rules — it's actively harmful applied to consolidating a set where every existing rule already represents a lesson learned. → Fixed with the explicit fresh-vs-consolidation branch at the start of Step 4.

### The one-line takeaway

**Redundancy checks and content-preservation checks are different checks.** A set can be perfectly non-redundant and non-contradictory while having silently lost a third of its rules — dedup only ever compares the new set against itself, never against what used to exist. Any consolidation run needs both.

## Case 2 — Cross-project contamination (Flutter + OpenCode, "port ace3i's review discipline")

### What happened

Different project, opposite failure direction. The user asked to port a *pattern* from another of their projects (an existing Next.js/ace3i codebase's mandatory pre-commit review + session-log discipline) into a fresh Flutter project. The agent running this skill copy-pasted the ace3i project's actual rule content — file names (`redux-toolkit.md`, `forms-validation.md`, `select.md`), conventions (`createAsyncThunk` bans, shadcn/Tailwind checks, `@/lib/routes`), and even a stray reference to a CodeGraph MCP tool and a `MIGRATION_ROADMAP.md` file — into the Flutter project's `09-agent-workflow.md`. None of those files, tools, or conventions existed anywhere else in the Flutter repo. A future session reading this file would go looking for `.opencode/rules/redux-toolkit.md` in a Flutter codebase and find nothing.

This is invisible to every check this skill already had at the time:
- Not a redundancy issue (the content wasn't duplicated elsewhere in the Flutter set).
- Not a contradiction between two rules in the same domain (nothing else in the set mentioned Redux, so there was nothing to conflict with).
- Not vagueness (the copied content was, in ace3i's own context, perfectly concrete and operational).
- Not a content-preservation miss (Case 1's fix) — nothing was lost, something extra and wrong was added.

Caught only because the user (who knows both projects) recognized the file names and conventions didn't belong.

### Root cause

**"Port the pattern from project X" was executed as "port the content from project X."** A pattern (mandatory pre-commit review, structured handoff notes, closed-decision protocol) is stack-agnostic and portable. Its *content* — which files to check, which framework conventions to verify — is not, and needs to be re-derived for the target project's actual stack and actual file names, not transplanted.

### Fix — added to SKILL.md and the audit checklist

1. **When explicitly asked to port a pattern from another project**: extract the *shape* of the pattern (what triggers it, what it checks, what file it writes to) and rebuild the content from the current project's own stack/files. Never copy a concrete file name, library name, or convention from the source project into the target — if you catch yourself typing a library or file name that came from the other project's context rather than this session's interview/codebase, stop and re-derive it.
2. **Audit checklist gained a "Cross-Project Contamination" section** (see `audit-checklist.md`): grep the final set for any stack/library/file names that don't belong to the confirmed target stack, and confirm every referenced file name in every rule file actually exists in the delivered set.

### The one-line takeaway

**Porting a pattern and porting content are different operations.** The pattern is portable; the concrete file names, libraries, and conventions inside it are not — they must be re-derived from the target project, never transplanted from the source.

### Addendum (2026-09-09) — contamination isn't only stack/library keywords

A first audit pass on this same output caught the obvious contamination (Redux/shadcn/Next.js file names) but missed a second, quieter layer: the cross-session-memory scaffolding (`SESSION_LOG.md`'s entry format, `DECISIONS.md`'s own usage rules, the "When to Update Memory Files" section) had inherited **process vocabulary** from the source project's methodology — "slice," `.plan.md`, `MIGRATION_ROADMAP.md` — terms specific to ace3i's phased-migration workflow, not tech-stack terms. A grep for library/framework names doesn't catch this; it needs a separate pass for methodology-specific process nouns (the unit of work: slice/feature/task/ticket; the artifact: roadmap/plan/backlog) whenever scaffolding is reused from a project that had its own distinctive workflow vocabulary. Added to the Cross-Project Contamination checklist as its own line — see `audit-checklist.md`.

### Addendum (2026-09-25) — contamination survives *adaptation*, and a source reference is itself contamination

Consolidating the source material for the template library surfaced the same
failure in a new form, and it is worth stating separately because the obvious
grep does not catch it.

**Case 2's original failure was copy-paste.** A rule referenced
`redux-toolkit.md`, a file that didn't exist in the target. That is loud: a
future session greps for the file, finds nothing, and reports it.

**The quieter form is adaptation.** In a TypeScript React Native project's
state-management file, a rule read:

> Mutations as hook methods — `useAddToCart().mutate(…)` — same shape as
> `LoginController.login()` **in the source profiles**.

Every token in that sentence is legitimate for the project. The rule is
operational, specific, and actionable. But `LoginController` is a Riverpod
controller from a Flutter project that has nothing to do with this codebase, and
a reader looking for `LoginController` will never find it. A second rule in the
same project's routing file said **"per the profiles: no params in shell
routes"** — a bare pointer to a document the reader doesn't have.

**Why the obvious check misses it:** grepping for library names finds nothing
wrong. There is no `riverpod` token. `LoginController` is not a library — it's a
symbol from another codebase, and the sentence around it is correct.

**The fix, now in the templates and the checklist:**

1. **A generated rule file may never name its own source template or profile.**
   Not "per the profiles", not "as in the Flutter profile", not a symbol that only
   exists in the template the rule came from. The rule must stand alone or cite
   something the reader has.
2. **Every symbol named in a rule must be greppable in the delivered set or the
   project itself.** `useAddToCart` passes; `LoginController` fails. This is a
   different check from "every *file* named exists" — it's about *symbols*.
3. **When adapting a rule from another stack, the example has to be re-derived
   too, not just the rule around it.** Porting the sentence but keeping the
   illustrative symbol is the same transplant, one level down.

### The one-line takeaway for the adapted form

**A reference to something the reader cannot reach is contamination even when
every other word in the rule is correct** — and the contaminating word is
usually an example, not the rule.

## Case 3 — A findings file that never changed any behaviour

### What happened

A real project (Expo + Shopify storefront) carried a rule file for the external
API's discovered quirks, alongside domain rule files for data access, auth, and
checkout. Over roughly a week the findings file accumulated **thirteen confirmed
entries** — real, hard-won, correctly formatted facts about the API's actual
behaviour.

Three of those entries **directly contradicted a rule in a domain file that
shipped in the same set**:

- The auth file instructed registering a custom-scheme redirect URI in the app
  config. The findings file, three entries down, recorded that the API accepts
  **only HTTPS** redirect URIs — a custom scheme is accepted by the input,
  marked as modified, and **silently discarded on save and reload**, proven by
  the control that the same save path *does* persist an HTTPS URI.
- The data-layer file taught a GraphQL mutation pattern that type-checks, sends
  successfully, and then silently reads `undefined` — because the response nests
  under the mutation's own field name.
- A cost field the data file implicitly treated as authoritative was recorded in
  the findings file as bundling delivery *and* taxes, so a UI row fed from it can
  never reconcile.

**Nothing was wrong with either file.** The findings were correct. The domain
rules were also correct-as-written and had been correct-as-written for a week.
They were simply describing a system whose real behaviour had since been
discovered and recorded three files away.

### Why every existing check passed

- **Not redundancy** — the facts appear once each.
- **Not contradiction in the usual sense** — no two rules point opposite ways
  *within a domain*. The contradiction is between a rule and a **finding about
  the system the rule describes**, and nothing compared those two.
- **Not vagueness** — both are concrete and specific.
- **Not content preservation** — nothing was lost.
- **Not contamination** — the findings are about the right system.

The only reason it was caught is that a person read the findings file and
recognised the contradiction.

### Root cause

**A findings file with no promotion path is a diary.** Its whole value is
changing behaviour, and behaviour changes only when a finding reaches a rule
file. Thirteen findings that never reach a rule file are thirteen facts that the
agent reads *instead of* the rule rather than *in addition to* correcting it — so
the file actively competes with the rules it was meant to inform.

The mechanism that would have caught it: findings are findings *about* a
domain, so a finding without a domain is incomplete, and a rule contradicted by
a finding is a defect. Neither existed.

### Fix

- **`domain/external-system-contracts.md` gained a mandatory —Promotion Rule.** An
  entry that has become generally applicable must be promoted into the owning
  domain rule file — restated as a plain rule with no archaeology — and the entry
  stays as its provenance. An entry that stays project-specific is *correct* where
  it is and is never promoted; the test is whether the statement is true beyond
  one deployment.
- **Entries record behaviour, not workarounds.** A fact survives a system change
  and tells a future session what to re-check; a recorded workaround just becomes
  wrong.
- **`audit-checklist.md` gained a —Promotion section**, checked in both
  directions: no rule contradicted by a finding, and no finding that has been
  generally true for several sessions without reaching a rule file.

### The one-line takeaway

**A findings file needs a promotion path or it is a diary that competes with the
rules it was meant to inform.**

## Case 5 — A promotion path that exists, is correct, and was never triggered

### What happened

A Flutter rental-management app, 12 working sessions, 43 logged corrections. The
promotion path was already in place and already correct: `workflow.md`
§Memory File Triggers mandated that a recurring correction be promoted into the
matching rule file, and the audit checklist checked it in both directions.

**Zero of the 43 were promoted.**

This is the shape that makes the case worth recording. The mechanism was not
missing, not wrong, and not ignored in principle — every part of it was in place
and had been for the whole project. Two things were missing, and neither was the
rule:

1. **No trigger.** The promotion is checked when this skill runs. It ran once,
   at project setup, and never again. A path with no caller is not a path.
2. **No domain on the entries.** The log format was
   `- YYYY-MM-DD: <rule that broke> → <correction applied>`. There was no field
   naming the rule file the correction would be promoted *into*. So even a
   determined promoter had no target — not "no time to do it", **nowhere to put
   it**.

The consequence was not an inert file. It was an actively harmful one: the
corrections were read *instead of* the rules, because they were newer and
session-local. And the log had grown to 31 KB against a rule file that still
said nothing about any of the 43.

### Why every existing check passed

- **The promotion rule was never violated.** It said "promote recurring
  corrections" and the agent was never asked to promote one.
- **The log format was followed exactly.** Every entry had the mandated fields.
  The mandated fields just did not include the one that mattered.
- **The audit checklist had a promotion section, and the section was satisfied
  vacuously** — there was nothing to promote because nothing was ever marked
  pending.
- **The rules were not missing either.** Two of the 43 were rules the skill
  already carried in prose elsewhere, and the agent broke them again anyway —
  not out of ignorance, but because nothing enforced them and nothing referred
  to them at the moment of the mistake.

### Root cause

Case 3 diagnosed a findings file with no promotion path. This case is the
follow-on: **a promotion path that is complete, correct, documented, and never
invoked, on entries that carry no target.**

A documented process is not a running process. What made this survive is that
every component was individually correct, so no component looked wrong. The
defect was in the *wiring*, and wiring defects are invisible to audits that
inspect components.

### Fix

- **The corrections format carries a domain**, and the domain is the promotion
  target:
  `- YYYY-MM-DD [domain: <rule file>] <rule that broke> → <correction applied>`
  A correction without one is refused, not accepted-with-a-gap.
- **A second skill, when present, triggers the re-run.** A planning skill that
  holds the project's state is the natural caller: on a threshold of unpromoted
  corrections, or at a phase boundary, it re-invokes this skill with the routed
  entries. The trigger belongs to whichever agent actually observes the
  accumulation — not to this skill, which is not running at the time.
- **The audit checks the wiring, not just the file.** A promotion section that
  only inspects the store cannot detect that nothing ever entered it. It must
  also assert that the format carries a target field, because a store whose
  entries have no target is a store that cannot be promoted, whatever its size.

### The one-line takeaway

**A promotion path needs a caller and a target, not just a rule. Documented is
not running, and an entry with no destination is a wish, not a correction.**

## Case 4 — An audit that reported clean on a set with live contradictions

### What happened

One of the two source profiles shipped a header claiming its material was
audited with **zero contamination and zero redundancy**. Auditing it found all
three of the following in the same set.

**Intra-file redundancy.** A coding-standards file stated the same banned
pattern in three separate places: once in a lint-rule table, once as a row in a
banned-patterns table, and once more as a second banned-patterns row. A separate
workflow file then carried an eleven-item "Rules" section that restated, word for
word, content already given in full in the two sections above it.

**Three mutually contradictory thresholds for the same thing.** File size was
"flag over 200 lines, refactor at 300+" in one file, "~250 lines is a signal to
split" in another, and a four-band table (0-150 / 150-200 / 200-300 / 300+) in a
third. All three are individually defensible advice. Together they mean an agent
has no answer to "is this file too big", which is the only question the rule
exists to answer.

**A false claim in the project documentation.** An ADR asserted that a priority
ordering was "referenced from every rule file". A grep found **zero**
occurrences of either the ordering or the ADR identifier anywhere in the rule
directory.

### Why the audit missed all three

- **Cross-file redundancy checks** don't see redundancy *within* one file.
- **Contradiction checks** compare rules to rules; a file that says "250" and
  another that says "300" isn't a contradiction — they're thresholds, and
  nothing flags two different answers to one question.
- **The clean claim was never mechanically checked.** It was an assertion in a
  document, and documents aren't audited.

### Fix

- **`audit-checklist.md` gained three lines:** redundancy *within* a file,
  including "a second condensed restatement layer of rules stated in full
  elsewhere in the same file"; **two files stating different thresholds for the
  same thing**, called out explicitly as the defect most likely to survive every
  other check; and a check that assertions in the project's own documentation
  are verified rather than inherited.
- **A template may not assert a countable fact about a tool-generated file.** The
  same source documented its lint configuration as "strict 44-rule" when the file
  listed 34 — a number that drifts on the next dependency bump and is false the
  moment it's written. Rule files cite rule *names*, never counts.
- **A template may not carry a claim that isn't true of the template.** A false
  statement in a reusable template is worse than no statement: it's copied into
  every future project, and it fails in all of them.

### The one-line takeaway

**Redundancy within a file, and two different answers to one question, are both
invisible to a check that compares files against each other** — and a claim of
"audited clean" is only worth what a mechanical check behind it verified.