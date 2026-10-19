# Improvements to study

This file lists improvements that are decided in intent but not yet designed. Each item states the goal, what the owner asked for, what Forge already provides, and the questions the study must answer. An item leaves this list when its design is written into the manifest and its tests exist.

Status values: `to study`, `design written`, `implemented`.

---

## I-001 Mandatory verification before every commit (to study)

### Goal

During the build phase, Forge never allows a commit before a set of checks has run on the code about to be committed and every problem found has been handled. The process is systematic: it runs on every commit, not on request.

### What the owner asked for

1. **Code review**: quality of the code, consistency with the Forge Rules, respect of good practices.
2. **Tests**: the necessary tests are executed and pass.
3. **Security**: detect potential vulnerabilities and mistakes that create security problems.
4. **Other relevant checks**: identify the additional checks needed for quality, reliability and maintainability.
5. **A specialised code-review agent**: define its role, the rules it verifies, its method, and how it interacts with the other Forge components.
6. **Handling**: problems found are processed before the commit goes ahead.

These are ideas to deepen, not decisions. The study decides the mandatory checks, the tools, and the conditions that allow or block a commit.

### What Forge v3 already provides

| Building block | Where | Relevance |
|---|---|---|
| `forge slice done` with evidence `<command> : <result>` | CLI | Records test evidence per slice, not per commit |
| Hash-bound review reports and two-reviewer gate | CLI, `forge-qa`, `forge-redteam` | Reusable pattern: a report bound to what was reviewed |
| `forge rules audit` and the project's `quality-gates.md` | forge-rules | Defines the project's own gate commands (lint, types, tests, coverage, duplication, vulnerabilities, review) |
| Rules phase (`rules-report`, gate runs the audit, drift protection) | CLI, forge-rules | Guarantees that `quality-gates.md` exists and passes the audit before the build starts |
| `forge-rules` template `code-review.md` | forge-rules templates | Existing review rules a project can inherit, including "a reviewer never approves their own change" |
| `forge-builder` agent | agents | The author whose work is checked |
| Memory trigger 6 "before a commit" | forge-memory | Currently a conditional trigger, listed as J3 in `docs/ESCAPE-HATCH-AUDIT.md` |
| Claude Code hooks and OpenCode plugin | hooks | Possible enforcement points; `PostToolUse` and `PreCompact` exist today, a pre-commit event does not |

### Questions the study must answer

**1. Where is the commit blocked**
- A git `pre-commit` hook, an agent-side hook on the shell tool when it runs `git commit`, a `forge commit` command that wraps git, or a combination.
- Behavior when the commit is made outside an agent, or with `--no-verify`.
- How the hook behaves on Windows and in both OpenCode and Claude Code.

**2. What the mandatory checks are, and where the list comes from**
- Fixed Forge list, or derived from the project's `quality-gates.md` (commands per stack), or both with a fixed minimum.
- How Forge reads the project's gate commands reliably.
- Candidate checks to evaluate: lint, format, type check, build, unit and integration tests, coverage threshold or ratchet, duplication, dependency vulnerability audit, secret scan, static security analysis, license check on new dependencies, migration safety, API contract drift, banned patterns from the Forge Rules, placeholders left in code, plan task ticked and slice scope respected, layout region tokens built, commit message convention, large or generated files, accessibility and performance budgets where the stack supports them.
- Which checks block, which only warn, and why.

**3. The code-review agent**
- Role and independence from `forge-builder`; how it differs from `forge-qa` (what is missing) and `forge-redteam` (what is contradictory).
- Inputs: the staged diff, the plan of the slice, the architecture contracts, the project's rule files.
- What it verifies: compliance with each Forge Rule, conformity to the plan, scope growth, test quality (do the tests fail without the code), maintainability, readability, error handling, security-sensitive changes.
- Method: how it reads a large diff within a small context window; whether it reviews per file or per slice.
- Output: a structured report with findings, severity and evidence, bound to the hash of the staged content.
- Who fixes findings, and how a fix triggers a new review.
- Name, tools and permissions; how the orchestrator delegates to it.

**4. Security**
- Tools per stack and how Forge discovers them; what happens when a tool is absent (block, or record the gate as `absent` with the install command, as forge-rules does for quality gates).
- Handling of secrets found in a diff.
- False positives: dismissal rule, with a recorded decision as for review findings.

**5. Blocking and override**
- Severity policy that blocks a commit.
- Whether an override exists, who can use it, and what it records (the user's own words, a decision entry, the journal).
- Whether work-in-progress commits follow a lighter path.

**6. Binding the checks to the commit**
- Proving that what was checked is what gets committed (hash of the staged tree).
- Behavior on `commit --amend`, rebase and merge commits.
- Relationship between commit granularity and slices.

**7. Interaction with the rest of Forge**
- Relation to `forge slice done`: whether it requires a passing pre-commit run.
- Memory: `forge memory checkpoint` becomes part of the pre-commit step, which turns trigger 6 from conditional into mechanical.
- Journal and client-mode report: how blocked commits and handled findings appear.
- Overlap with CI so that the same checks are not defined twice.

**8. Cost and limits**
- Time budget of a commit, incremental checks on the changed files, behavior with small context windows.
- Failure modes: a flaky test, a missing tool, an offline machine.

**9. Escape-hatch review**
- Add the new shortcuts to `docs/ESCAPE-HATCH-AUDIT.md` and to `tests/adversarial.sh` before implementation is called done.

### Expected output of the study

1. A design note that fixes the enforcement point, the mandatory check list, the blocking policy and the review agent's contract.
2. An update of the manifest and of `docs/STATUS.md`.
3. Test scenarios, including adversarial ones, written before the implementation.
4. A breakdown into implementation tasks.

---

## Other improvements to study

None recorded yet. Add each new item below with the same structure: goal, request, existing building blocks, questions, expected output.
