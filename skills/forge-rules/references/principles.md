## The six principles

Everything this skill produces obeys these. If a draft violates one, fix the
draft, not the principle.

1. **Operational policy, not documentation — with three tiers, not two.** Sort
   every sentence into exactly one bucket before deciding to cut it:

   | Tier | Test | Example | Action |
   |---|---|---|---|
   | Tutorial prose | Explains something the model knows from training | A 20-line example showing what a Server Component is | Cut |
   | **Operational prose** | Answers "what should the agent DO when X?" or "is X acceptable?" — even with no backtick command | "Split by responsibility, not by lines — a 250-line single-responsibility file is fine" | **Keep.** Rewrite tighter if possible; do not delete. |
   | Verifiable command | A literal invocation with a pass/fail outcome | `npm run lint` exits 0 | Keep |

   The test for the middle tier: *can you imagine the agent violating this?* If
   yes, it's a decision rule, not documentation, regardless of whether it has a
   command. "We value clean code" fails — nothing to violate. "Split by
   responsibility, not by lines" passes — an agent could easily split a 250-line
   file wrongly just to hit a count.

2. **One fact, one location.** Never state the same rule in two files. If it's
   cross-cutting, it lives in exactly one template and everything else
   references it by name. This is the single largest source of spaghetti — not
   bad individual rules, but the same rule drifting into two phrasings over time
   until they disagree. **The audit is a grep, not a judgement call**, and the
   cross-reference must name a section, not a file. "See `security.md`" is weak;
   "see `security.md` §Token Handling" survives a refactor of the file.

3. **Ranked, not stacked, priorities.** "Ship fast" + "full coverage" + "5-minute
   CI budget" with no ranking means the agent picks silently and you find out
   later. Every set of rules that could conflict gets an explicit order, in the
   entry file, referenced by everyone else.

4. **Start from a skeleton, grow from corrections — for FRESH rule sets only,
   and there are three situations, not two.**
   - **Bootstrap** (no existing rules): ship a lean, correct skeleton plus a
     living-learnings section. Don't enumerate every hypothetical rule on day
     one — that's the randomness problem, guessing at situations that haven't
     happened.
   - **Consolidation** (existing rules being reorganised): every existing rule
     already represents a lesson learned. **Reorganise and dedupe; do not
     curate down.** Applying "start lean" pressure here produces exactly the
     silent content loss in `postmortems.md` Case 1. The only content you're
     licensed to remove without asking is tutorial prose and true duplicates.
   - **Adoption** (existing *code*, with or without existing rules): run
     `references/existing-project-protocol.md` in full. Detect the conventions
     the code actually has, then preserve or migrate. **This is the case the
     skill previously had no handling for, and it's the one that produces rules
     contradicting a working codebase.**

5. **Porting a pattern is not porting content.** The *pattern* is portable —
   what triggers a check, what gets verified, what file it's logged to. The
   concrete content is not: file names, library names, framework conventions
   belong to the source project and must be re-derived from this project's
   actual stack. **A rule file that references a file, library, or tool not
   present in this project is contamination** (`postmortems.md` Case 2 — and
   note that a grep for library names doesn't catch process vocabulary; a
   separate pass is needed for that). **Corollary, learned the hard way: a
   generated rule file may never name its own source template or profile.** A
   surviving "per the profiles" or a framework symbol from the wrong stack is
   both contamination and a dangling reference.

6. **Budgets are ceilings for prose and floors for gates.** These are two
   different rules, and conflating them is how a set ends up complete in its
   argument and empty in its enforcement.

   | Content | Budget | The test |
   |---|---|---|
   | **Prose** — rationale, framing, examples, history | a **ceiling**. Cut this first | Would the agent act differently without this sentence? |
   | **A gate** — a threshold, a command, an exit code, a banned list | a **floor**. Never cut it | Does it exit non-zero when violated? |

   **A gate that does not exit non-zero is not a gate.** It is a sentence, and
   it is subject to the same fate as every other sentence: an agent that is
   tired, or in a hurry, or told to "just get this done", will read past it. A
   threshold, a command and a banned list are the *cheapest* content in any
   rule file — a line each — and the only thing that survives that pressure.

   So: if the set is over budget, cut tutorial prose first, and if there isn't
   any, **add more scoped files rather than trimming operational content.** If
   it is under budget, that is not licence to cut further — it is a signal to
   ask **what is missing**, because the usual reason a generated set is thin is
   that a pressure valve fired (see § Step 0b).

6b. **The budget is per-target, and it must be measured — the read-back test
   cannot detect it.**

   The ~500-line figure in `research-summary.md` is *Cursor's own guidance*, and
   it **assumes activation modes**: a scoped file only loads when its files are
   open. **It does not transfer to a target with no scoping.**

   | Target | Scoping | Budget | |
   |---|---|---|---|
   | Cursor `.mdc` | 4 activation modes | ~500 lines **always-apply** | `mdc-frontmatter-spec.md` |
   | OpenCode `instructions` glob | **none — every file, every session** | **the whole rules directory**, hard total | Step 3b |
   | `AGENTS.md` alone | none | one file; if it outgrows one, change target | — |

   **On a target with no scoping, splitting a file saves nothing.** The glob
   loads it either way. The only levers are the total, and not putting
   trigger-based content in a file that loads unconditionally.

   **And the read-back test in Step 6 will not catch an oversized set.** It
   answers from the entry file, which is small and front-loaded — a 2×
   over-budget set passes it. Measure the total separately, in Step 3b, or not
   at all.

