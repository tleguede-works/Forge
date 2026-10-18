# Pre-Delivery Audit Checklist

Run this against the full draft set before showing it to the user. This is the
step that actually prevents spaghetti — everything upstream (the templates, the
selection table) makes good individual files; this catches the problems that
only exist *across* files, or between the rules and the code.

Each section below catches something the others cannot. **A clean result on one
section says nothing about the others.**

## Part A — Mechanical. Run it, don't read it

```bash
forge rules audit <project> --target opencode --budget 800
```

**These ten checks are decided, not judged.** Reading them off a checklist lets
the agent report them as satisfied without running anything — which is how a
rule set ends up internally consistent, wired to nothing, and complete on paper.

| Check | What it catches |
|---|---|
| `wiring_present` | Config missing, unparseable, or a glob matching nothing |
| `index_covers_everything` | A rule file nobody will read, or a row pointing at a file that does not exist |
| `no_placeholder_residue` | A `{{PLACEHOLDER}}` that survived generation |
| `cross_references_resolve` | A `§Section` reference pointing at a section that was renamed |
| `no_contradictory_thresholds` | Two files giving two answers to "is this file too big" |
| `no_forge_coupling` | Rule text that depends on the Forge tool or its `.forge/` folder |
| `no_cross_project_contamination` | A library, file or symbol from another project |
| `no_unenforceable_prose` | "Properly", "as needed", "probably X, but verify" |
| `gates_are_commands` | A gate set with no duplication, coverage, vulnerability or review check |
| `budget_measured` | The total of a glob-loaded rules directory, and per-file overages |

**A failure here is a defect, not a discussion.** Fix it and re-run. The
test suite (`tests/rules.sh`) proves each check detects what it
claims to, so a pass is evidence rather than a formality.

## Part B — Judgement. This is what a checklist is for

Everything below is a decision no script can make. Do not automate these, and do
not report them as verified when they were not.

## Redundancy

- [ ] For every rule stated as a command or a do/don't, search the rest of the set
  for the same fact in different words. Keep it in exactly one place and replace
      the duplicate with a reference — **to a section, not just a file.** "See
      `security.md`" is weak; "see `security.md` §Token Handling" survives a
      refactor.
- [ ] Any two files mentioning the same library — do they agree on the version and
      on the banned patterns? A gap isn't a contradiction yet, but it's a gap.
- [ ] Any small file closely related to another small file — should they merge?
      **If yes, it's an absorb, and Step 4's verification runs immediately.**
- [ ] **No rule appears in both a domain file and the entry file.** The entry
      file carries the index and the summary, not the domain rules.
- [ ] For a consolidation: no rule file contains a **second, condensed
      restatement layer** of rules stated in full elsewhere in the same file. This
      is a redundancy that lives entirely within one file and is invisible to a
      cross-file check.

## Contradiction

- [ ] Any two rules that could both apply to the same situation and point in
      different directions? Rank them explicitly, in the entry file, and have the
      other file reference the ranking rather than asserting its own.
- [ ] Do any two files' definitions of done disagree about what "done" means for
      overlapping work?
- [ ] Do escalation rules conflict — one says "stop and ask", another implies
      "keep trying"? Escalation is defined **once**, in the entry file, and
      inherited.
- [ ] **Do any two files state a different threshold for the same thing?** File
      size, list length, staleness, retry count, coverage. This is the defect most
      likely to survive every other check, because both numbers are individually
      reasonable and neither is wrong on its own.
- [ ] **Did applying a variant actually remove the rules it reverses?** A
      half-applied variant leaves both the old rule and the new one, and they
      contradict by definition. Check every row the variant's table names.
- [ ] **Did applying a variant leave a rule about a mechanism this project doesn't
      have?** A rule about a directive, a file convention, or a hook that the
      chosen variant removed is dead weight that invites an agent to go looking
      for it.
- [ ] **Does every cross-reference resolve to exactly one owner?** Trace the
      chains: if file A's rule points at file B, and B's rule for the same fact
      points back at A, the rule has no home and will drift. One fact, one
      location, one direction.
- [ ] **Is any instruction unsatisfiable?** A section told to be emitted empty
      collides with "an empty section is worse than no section"; a table told to
      be filled from another file duplicates that file when it is. Read the
      instructions as a sequence and check they compose.

## Vagueness — the "gets silently ignored" check

- [ ] Any sentence using "carefully", "properly", "gracefully", "where
      appropriate", "as needed", "clean", "robust" without an attached command or
      concrete trigger? Rewrite or cut.
- [ ] Any style rule with no verification command next to it? Attach the lint
      rule, or cut it — an unverifiable style preference is a suggestion and will
      be treated as one.
- [ ] Any section that's prose explaining rationale rather than an instruction?
      Move the rationale to human-facing docs, or compress it to a trailing clause
      on the rule.
- [ ] Any rule that passes none of the four checkability tests — a command, a glob
      match, a banned-list lookup, or the Principle 1 "would the agent violate
      this?" test? **Rewrite it; don't cut it on sight.**
- [ ] Any hedge that carries a rule's authority and a guess's reliability —
      "probably X, but verify"? A hedge is not a weaker rule, it's an unusable
      one. It becomes a question, a proposed ADR, or an unconfirmed finding.

## Structure

- [ ] Every file starts with commands and a definition of done, not style.
- [ ] Every file within its line ceiling. Over? Is it doing two jobs?
- [ ] **The set is measured, not estimated, against the budget for the chosen
      target.** A target with no scoping — an `instructions` glob, or a single
      `AGENTS.md` — budgets the *total* rules directory, not the always-apply
      subset. Splitting a file on such a target saves nothing; the glob loads
      every file either way. The read-back test cannot see this, so measure it
      explicitly.
- [ ] Every file's activation mode matches its real scope — nothing labelled
      always-apply that's framework-specific, nothing labelled glob-scoped that's
      actually universal.
- [ ] Monorepo child files: deltas only, no restated parent content.
- [ ] Nothing orphaned — every file is either discovered automatically or
      referenced from a file that is.
- [ ] **The index in the entry file lists every emitted rule file and nothing
      else.** A file not listed is never read; a listed file that doesn't exist is
      a broken reference.
- [ ] Every file ends up referenced. A rule file no index row points to is dead
      weight that still costs context if the target globs the directory.

## Selection justification

*New with the template library. This is what makes "why is this rule here?"
answerable.*

- [ ] Every emitted template has a **recorded detection signal**.
- [ ] Every omitted template has a **recorded reason** — "no test runner
      configured", "single-locale project", "no UI layer".
- [ ] Every applied variant is **named**, and the axes it depends on were
      confirmed rather than inferred.
- [ ] A technology-specific claim is either traceable to a rung of
      `documentation-sources.md` or marked as a project decision with its ADR.
      **An unsourced technology claim is a defect**, not an incomplete rule: a
      reader cannot distinguish a verified fact from a plausible guess, and both
      look identical on the page.
- [ ] A framework that ships faster than the training gap has the mandatory
      verification section in the entry file, stating the installed version, the
      version-matched documentation location, and that the answer is never from
      memory.

## Content preservation

*Mandatory for any consolidation — a project whose rules are being reorganised.*

This catches what the other sections don't: rules that were correctly
non-redundant and non-contradictory because they no longer exist anywhere.
Redundancy and contradiction checks compare the new set against *itself*; they
can pass perfectly on a set that lost a third of its content.

- [ ] Every original file has a rule inventory — a count of discrete rules:
      numbered items, thresholds, banned patterns, decision-rule sentences, not
      just backtick commands.
- [ ] Every rule in that inventory is located in the new set: inline, absorbed at
      comparable depth, or explicitly referenced by section.
- [ ] For every absorbed file: does the target contain the source's rules, or a
      passing mention standing in for a section? **A single bullet replacing a
      100-line file is a red flag, not a success.**
- [ ] Rule count before vs. after: original total minus explicitly-listed
      intentional cuts (tutorial prose only) equals the new total. If it doesn't,
      and you can't explain the gap line by line, something was lost.
- [ ] **The reconciliation states its denominator.** "N preserved, M absorbed, K
      cut" is not a measurement without a stated base — for a consolidation the
      base is the source rule inventory, for an adoption it is the Step A
      convention count. A figure with no denominator is a number the drafter
      chose, and it will be wrong in whichever direction flatters the result.
      A partial audit (light mode) says so, and gives the sample size.
- [ ] **A reconciliation line exists for the user:** "N rules preserved, M absorbed
      with cross-references, K lines of tutorial prose cut (listed)." If you can't
      state that number, the audit isn't done.

## Contradiction with the code

*Mandatory for any adoption — a project with existing code.*

The failure this catches is invisible to every other section, because it compares
a rule set against a **codebase** rather than against itself. A rule that
contradicts a working implementation is the worst outcome this skill can produce:
the agent either follows the rule and breaks the code, or follows the code and
distrusts the entire file.

- [ ] For every emitted rule: does the code already do the opposite in a
      load-bearing way? If so, it is a preserve-or-migrate decision
      (`existing-project-protocol.md`), not a rule to emit.
- [ ] Every convention recorded by Step A has a `file:line` reference. A
      convention with no evidence is a guess.
- [ ] Every item in the gap report's divergence list is accounted for — a
      preserved rule or a migration target. **An unaccounted divergence is a rule
      that was silently dropped**, the same class of loss as content preservation.
- [ ] Every coexistence rule in a migration has a **removal condition**. A
      coexistence rule without one is permanent, and permanent coexistence is the
      outcome the migration exists to avoid.
- [ ] No deprecated pattern is presented as equally acceptable. It is marked
      deprecated, and extending it is a defect even while using it isn't yet.
- [ ] The migration's final stage deletes the deprecated path. A migration that
      never deletes anything has doubled the codebase, not migrated it.

## Cross-project contamination

*Mandatory whenever this run ported a pattern from another project, or adopted
one — copying a template into a project is a transplant by construction.*

The opposite of content preservation: not content lost, content injected that
doesn't belong.

- [ ] Grep the full set for library and framework names that aren't part of the
      confirmed target stack. Any unexplained hit is contamination — remove it and
      re-derive from the actual stack.
- [ ] **Grep separately for process and methodology vocabulary.** Framework
      keywords don't catch a source project's own unit of work, its artifact
      names, or its workflow nouns. This needs its own pass
      (`postmortems.md` Case 2 addendum).
- [ ] For every file named inside a rule, confirm that file exists in the
      delivered set. A reference to a non-existent file is a strong signal of
      transplanted content.
- [ ] For every tool, CLI, or MCP server referenced, confirm it's actually
      configured somewhere in this project — a dependency, a config entry, an
      allowlist. A rule file asserting a tool exists is not evidence that it
      does.
- [ ] **Grep for the source templates' own names.** A delivered rule must never
      name the template or profile it came from — "per the profiles", "as in the
      Flutter profile". A surviving reference is both contamination and a dangling
      pointer, and it is the exact form contamination takes when a rule is
      *adapted* rather than copy-pasted, which is why it needs its own check.

## Promotion

*Mandatory for every project with a corrections store — not only one with an
`external-system-contracts.md`.*

- [ ] No entry in the findings file is contradicted by a rule in a domain file.
      A discovery sitting next to a rule it invalidates has changed nothing, and
      the next session reads the rule, misses the contradiction, and repeats the
      bug.
- [ ] No entry that has been generally true for several sessions is still only an
      entry. A finding that never reaches a rule file is a diary entry.
- [ ] Entries record **behaviour, not workarounds** — so a change in the external
      system tells a future session what to re-check, rather than making the
      recorded fix silently wrong.
- [ ] Every entry has its confirmation recorded: when, and against what version or
      environment. An entry with no provenance is a guess with a confident tone.
- [ ] Known-and-documented behaviour is in the domain rule files, not here. A
      findings file accumulating things that were always true is a second
      documentation surface that will drift.
- [ ] **The corrections format carries a promotion target.** Each entry names the
      rule file it will be promoted into. A store whose entries have no
      destination cannot be promoted whatever its size — `postmortems.md` Case 5
      records 43 correctly-formatted entries producing zero promotions for
      exactly this reason.
- [ ] **The promotion path has a caller.** Stating it is not running it. If
      another skill holds this project's state, name when it re-invokes this one;
      if nothing does, the path is inert and this box is not ticked by having
      written it down.
- [ ] **Only one corrections store exists.** An entry file that points at
      `LEARNINGS.md` *and* carries its own `## Project Learnings` section produces
      a stale "(no entries yet)" in one of the two — and the stale half is the one
      an agent is most likely to read.

## Living-learnings wiring

- [ ] Is it clear, in the delivered set, exactly where a future correction is
      appended? One canonical spot, not "wherever seems right".
- [ ] If the project already has a memory system, does the rule set point to it
      rather than duplicating it?
- [ ] Is the promotion path stated — how a correction becomes a rule in a rule
      file, and how a finding becomes a rule? Both directions, explicitly.

## Target-format wiring

*Every run. This is the check for the failure that makes a complete rule set
entirely inert.*

- [ ] **The wiring file exists and parses.** A malformed config silently disables
      the whole instruction set and nothing reports it.
- [ ] **Every path the config points at exists.** A glob matching nothing is a
      valid configuration that loads nothing.
- [ ] Every rule file is inside the directory or pattern the config points at.
- [ ] If an existing config file was present, it was **merged**, not replaced.
- [ ] For a multi-target run: no tool file has stopped referencing the canonical
      entry file, and no rule appears in two tool files with different wording.
- [ ] The permission allowlist, where emitted, matches the documented commands —
      and contains no destructive operation.

## Final gate

- [ ] **Cold read:** could you, in about ten seconds of skimming the always-apply
      tier, answer "what's the build command" and "what does done mean"? If not,
      neither can the agent.
- [ ] **Adoption extra:** could you answer "what is this project's own pattern for
      X"? If the answer describes the template rather than the project, the rules
      are wrong.
- [ ] **Delivery reconciliation stated to the user**, in the counts from Content
      Preservation and Selection Justification. A run that cannot state its
      numbers has not been verified.
