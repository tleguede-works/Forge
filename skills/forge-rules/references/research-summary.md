# Research Summary — What Actually Changes Agent Behavior

Synthesized from Cursor's own `.mdc` documentation and best-practice guides, the AGENTS.md open-spec community (now under the Linux Foundation's Agentic AI Foundation, with Anthropic/Google/Microsoft/OpenAI as platinum members), and measured before/after comparisons published by practitioners running these files daily across Claude Code, Codex, Cursor, and OpenCode. Read once per session, not line-by-line every time — the point is to internalize the shape of what works, not to quote this file back.

## What gets measurably ignored

Tested by running the same task with and without a given instruction, 10+ trials each, comparing completion accuracy:

- **Prose paragraphs without a command.** "We value clean, well-tested code, please ensure changes are properly tested" — the agent represents this as a vague preference and proceeds without running tests, because there's no actionable command, no threshold, no definition of "properly tested."
- **Vague adjectives.** "Be careful with migrations," "keep it fast," "handle errors gracefully." None of these are constraints an agent can check against. Compare: "Run `alembic check` before applying migrations. Abort if there's no downgrade path." — a command with a pass/fail outcome.
- **Style guides with no verification command.** "Follow the Google Python Style Guide" gives the agent nothing to check itself against. Pair every style rule with the lint invocation that enforces it, or drop it.
- **Unranked conflicting priorities.** "Move fast" + "full coverage" + "5-min CI budget" + "run full integration suite before every commit" can't all be satisfied. Research on underspecified software-engineering tasks (Ambig-SWE, ICLR 2026) found models almost never ask a clarifying question on their own when priorities conflict — they silently pick one and skip verification steps. Explicit interactive prompting recovered up to 74% of the lost performance on underspecified tasks; explicit ranking in the rules file does the same thing without needing a live question.

## What measurably works

- **Command-first instructions.** Exact invocations with exit codes the agent can check: `pytest -v --tb=short`, not "run the tests."
- **An explicit Definition of Done.** A numbered list of checks that must all pass (lint exits 0, tests exit 0, types check, changes staged/committed with a specific message format). This is the single highest-leverage fix for agents reporting "done" on work that doesn't actually run — without it, "done" means "I think I finished," which is the most common source of agent-introduced bugs per practitioner write-ups analyzing agent failure patterns.
- **Task-organized sections** ("When Writing Code" / "When Reviewing Code" / "When Releasing") over flat bullet lists. The agent can load only the section relevant to what it's currently doing instead of parsing everything regardless of context — this is also exactly why Cursor's glob/intelligent activation modes exist.
- **Escalation rules.** What to do when blocked (stop and report vs. retry N times vs. ask), and an explicit "never" list (never force-push, never delete a lock file to make an error go away, never skip tests to unblock a commit). Without this, a stuck agent improvises increasingly destructive workarounds.
- **Version pinning + a banned-pattern list.** "Next.js 16 App Router only. Do NOT use getServerSideProps, getStaticProps, or class components" prevents the model from mixing syntax across versions or reaching for deprecated patterns it half-remembers from training data.
- **Referencing a canonical file instead of pasting code.** "Follow the pattern in `src/components/Button.tsx`" stays correct as the codebase evolves; pasted code snippets in rules go stale silently.
- **Directory-level hierarchical scoping for monorepos.** Root file → service-level file → component-level file, with the closer file taking precedence and only stating deltas from the parent, not repeating it.

## On length and redundancy

> **Read the figures below as research findings about what gets ignored, not as
> production targets to copy.** They are the basis for SKILL.md Principle 6b,
> which scopes them per target — and the scoping matters, because the ~500-line
> figure assumes activation modes. On a target that loads every rules file
> unconditionally, the same principle produces a different number. Quoting these
> figures without that qualifier is how a set ends up 2× over a ceiling that
> never applied to it.

### What these figures describe, and what they don't

**The "start small" finding describes a set that already converged. It is not a
recipe for producing the first one.**

The evidence is consistent and easy to misread. Every measurement here compares
*an instruction that exists* against *the same instruction absent*, over tasks a
developer was already doing. That design measures marginal effect, not adequacy.
It can tell you that a prose paragraph is worthless; it cannot tell you that
three prose paragraphs plus three commands are better than one prose paragraph
and no commands.

Three consequences, and the third is the one that causes defects:

1. **These figures cannot size a set.** Nothing here measured "the smallest
   rule set that produces acceptable work." Choosing a line count because the
   research says smaller sets ignore less is reading a correlation as a
   threshold.
2. **"Start small, add on the second repeated mistake" is a maintenance
   strategy for an existing project.** It presupposes a set already exists and
   a project already in production. Applied to a project's first generation,
   where no mistake has been repeated twice *because there is no history yet*,
   it emits nothing at all — which is a correct reading of the principle and a
   useless output.
3. **The advice inverts the cost.** Under maintenance, a rule is added when it
   has already cost something, so most proposed rules are worthless and lean
   wins. Under first generation, an unstated rule costs silently forever: there
   is no first failure to trigger it, because the failing behaviour is *the
   absence of the rule*. Lean wins on average there only if the absent rules
   were worthless, and nobody has measured that.

**So: use these findings to cut prose, never to decide what to omit.** The
question a line budget can answer is "does this sentence change what the agent
does", not "is this rule worth having". SKILL.md Principle 6 splits the two for
exactly this reason.

- Practical ceiling: keep individual rule files under ~500 lines (Cursor's own guidance; content beyond that risks being dropped from context). Keep the total combined "always apply" content under roughly 2,000 tokens (~500 lines of plain English) — five 50-line "always apply" files is fine (~1,000-2,000 tokens); twenty 200-line "always apply" files burns 10%+ of the context window before the model reads any actual code.
- One widely-cited convention keeps each *section* to ~50 lines and the *whole root file* to ~150-200 lines, front-loading commands and definition-of-done before any style preference — most rule files that fail were written style-first and never got to the commands.
- **The decisive test**: ask the agent, cold, to recite its build command and definition of done. If it can't reproduce them, the file is too long (truncated out of context), too vague (nothing concrete to latch onto), or simply not being discovered (check file location and the tool's own docs).

## On avoiding contradictions and duplication across files

- The dominant real-world failure mode isn't a single bad rule — it's the *same* rule restated slightly differently in two files over time until they quietly disagree. Fix: one canonical location per fact, everything else references it by name/section rather than repeating it.
- If a team uses more than one agent tool (Cursor + Claude Code + Codex, as is common), treat AGENTS.md as the single source of truth and have tool-specific files (`.cursor/rules/*.mdc`, `CLAUDE.md`) reference or mirror sections from it — never maintain fully parallel instruction sets, since they will diverge.
- "Start small, add a rule only when the agent repeats the same mistake twice" is the strongest anti-spaghetti practice on record: it guarantees every rule in the file corresponds to a real, observed failure mode rather than a hypothetical one imagined during a single big generation pass — which is exactly the randomness/inconsistent-depth problem this skill exists to solve.

## Format notes specific to Cursor `.mdc`

- Legacy `.cursorrules` (single flat file) is deprecated and ignored by Agent mode; use `.cursor/rules/*.mdc`.
- Four activation modes via YAML frontmatter: `alwaysApply: true` (every session), `description` only with no glob (agent decides relevance — "intelligent"), `globs: [...]` (activates when matching files are in context), or no frontmatter / manual (only on explicit `@rule-name` mention).
- Precedence when rules overlap: Team Rules > Project Rules (`.cursor/rules/`) > User Rules (Cursor Settings). All matching rules are included together, not just the highest-precedence one.
- Cursor also auto-discovers `AGENTS.md` at the project root and in subdirectories now, which is why the multi-tool section of this skill treats `AGENTS.md` as viable even for Cursor-only setups, with `.mdc` reserved for genuinely Cursor-specific needs (glob-based file scoping, manual `@mention` rules).
