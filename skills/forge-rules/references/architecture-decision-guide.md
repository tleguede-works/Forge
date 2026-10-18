# Architecture Decision Guide

The structural decisions — how many files, split how, what loads when. Format
and destination questions are in `target-formats.md`; template selection is in
`stack-detection.md`; adopting an existing project's conventions is in
`existing-project-protocol.md`.

## 1. Which files does this project get?

**Not a free choice — a lookup.** Run the detection probe in
`stack-detection.md` and use the set it returns. Every emitted file records the
signal that triggered it; every omitted one records the reason.

The reason this decision is a lookup rather than a judgement: an agent reading a
manifest forms an impression of the stack, selects from the impression, and gets
it subtly wrong. A lookup produces the same set for the same repository, every
time, and produces a justification for each inclusion.

**This guide governs what happens after the selection** — the shape of what came
back.

## 2. One file per concern, and the absorb/reference rule

The default is **one file per coherent concern** — "the data rules", "the
accessibility rules" — not one per file type, not one per individual technology.
If two technologies are always used together, they're one file.

- **Merge** when a file would be under ~100 lines and is closely related to a
  neighbour. **Merge means absorb at full depth**, not summarise into a bullet.
  Run the verification immediately: list the source's discrete rules, confirm
  each survives in the target. A 100-line file becoming five lines is not a
  merge, it's undocumented deletion (`postmortems.md` Case 1).
- **Split** when a file approaches ~400–500 lines. That's usually the point where
  it's doing two jobs.
- **Reference, don't repeat.** Where a fact is stated in the canonical file,
  every other file cites it **by section**, not by file name. A file-level
  reference breaks when the file is split; a section reference survives it.

**There is a hard ceiling on merging: don't create a second layer that restates
in condensed form what a file already says in full.** A file with a "Rules"
summary section duplicating its own body is intra-file redundancy, and it's
invisible to any cross-file check (`postmortems.md` Case 4).

## 3. One canonical location per fact, and it must be findable

Cross-cutting rules live in exactly one file. Two things make that work:

- **The canonical file states it in full.** Not a pointer to where it might be.
- **Everything else references it by section.**

**A fact stated in two places with different wording is the dominant real-world
failure mode** — not a bad individual rule, but the same rule drifting until the
two versions quietly disagree. And it's a specific risk here: several source
projects each had a section literally labelled "canonical — do not restate it",
which was then restated in three other files. A label is not a mechanism.

**Two files stating different thresholds for the same thing** — file size, list
length, staleness, coverage — is the same defect wearing plausible clothes. Both
numbers are individually reasonable, which is exactly why nothing flags them.

## 4. Activation mode follows scope, not importance

For targets that support it (Cursor's four modes, `mdc-frontmatter-spec.md`).

Ask, in order:

1. **Does this apply to literally every session regardless of the task?** →
   always-apply. Keep it small — this is the budgeted tier. Language
   conventions, commit format, the definition of done, a short banned list.
2. **Only when specific paths are open?** → glob-scoped. The workhorse tier: most
   framework- and file-type-specific content belongs here, not in always-apply.
3. **A judgement call matched by topic rather than path?** → description only,
   no glob. Architecture decisions, performance, security posture.
4. **Detailed, rarely needed, would clutter every session?** → no frontmatter,
   invoked explicitly.

**A rule isn't always-apply because it matters.** It's always-apply only if it's
genuinely universal. This is the largest context-budget lever in the whole system
and the most commonly got wrong.

**For AGENTS.md-only targets there is no activation mode** — the file loads in
full, every session. That is the real trade: a single portable file is simpler
and always complete, and it is why a rule set that outgrows one file should move
to a target with activation modes rather than be split into a directory the
target won't read.

## 5. Monorepos

**Directory-scoped, deltas only.** The closer file wins on conflict.

```
/AGENTS.md                    ← universal only: git conventions, the DoD shape,
                                the escalation ladder, the memory protocol,
                                the priority ranking
/services/api/AGENTS.md       ← this service's commands, stack, domain rules
/services/web/AGENTS.md       ← this service's deltas
```

- **The root states only what is genuinely universal.** No service's commands, no
  service's stack table.
- **A child never restates the parent's rules** — it references them.
- **Tech overlays are chosen per service, not per repository.** A React service
  and a NestJS service in one monorepo need different overlays, and the
  detection probe runs in each service directory.
- **A child may tighten a parent rule; it may not contradict one silently.**

## 6. Where living learnings live

- **The project already has a memory system** — a session log, a decisions file,
  or similar: wire learnings into it. A correction becomes an entry there, not a
  fourth mechanism.
- **No existing system, canonical file small enough to absorb it:** a
  `## Project Learnings` section at the bottom of the entry file. Append-only,
  one line per correction, triggered by a mistake made **twice**, never
  speculatively.
- **No existing system, canonical file near its budget:** its own small file,
  referenced from the canonical one, so it can grow without threatening the
  always-apply budget.

**Whichever form, the promotion path must be stated in both directions:** how a
correction becomes a rule in a rule file, and how a finding in the external-
contracts file becomes a rule. A learning log with no promotion path is a diary
(`postmortems.md` Case 3).

## 7. Final sanity pass

Before calling the architecture done:

- [ ] Every emitted file has a recorded selection signal; every omitted one, a
      recorded reason.
- [ ] No fact in two places. Every cross-reference names a section, and resolves
      to **one** owner — a reference that points at a rule which points back is
      a rule with no home.
- [ ] No two files with different thresholds for the same thing.
- [ ] No file containing a second, condensed restatement of its own content.
- [ ] **The set is measured against the budget for the chosen target.** If that
      target has no scoping — an `instructions` glob, or a single `AGENTS.md` —
      the budget is the *total* size of the rules directory, not the always-apply
      subset. A glob-loaded target has no per-file relief: splitting saves
      nothing, because the glob loads every file anyway. Measure it; the
      read-back test cannot see this.
- [ ] Activation modes match real scope.
- [ ] Monorepo children carry deltas only.
- [ ] Every emitted file is referenced from the index; every index row points at
      a file that exists.
- [ ] The target's wiring file exists, parses, and points at files that are
      there (`target-formats.md`).
- [ ] Every file traces to the ordering above. Nothing skips to style.
