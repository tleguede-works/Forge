# Template · Entry File (`AGENTS.md`)

<!--
GENERATOR NOTES — delete this block in the emitted file.

This is the canonical entry file. It is loaded on every session, in full, before
anything else. It carries only what an agent needs before it can do anything
useful: commands, the definition of done, how to break a tie, what to do when
blocked, and where everything else lives. It does NOT restate domain rules — it
points at them.

Fill order is fixed and is the priority order from SKILL.md: commands → done →
tie-break → blocked → git → stack → index → memory. Style never appears here.

This file carries only what is needed **before** the agent can act, and a
pointer to everything else. Two consequences worth stating, because they are
what makes it stay small:

- **Thresholds and commands are a floor here.** This is the always-loaded tier:
  if the build command, the gate command or the Definition of Done were
  "compressed", the file would still cost the same context and would have lost
  the two things an agent cannot recover on its own.
- **Paraphrase is a ceiling.** Architecture, conventions, review detail, git
  discipline — all referenced, none restated. A paragraph in this file is paid
  for on every session, including the 95 % where it is irrelevant.

Placeholders: {{PROJECT_NAME}}, {{ONE_LINE_PURPOSE}}, {{COMMANDS_TABLE}},
{{GATE_COMMAND}}, {{DOD_ITEMS}}, {{PRIORITIES}}, {{NEVER_LIST}}, {{STRATEGY}},
{{STACK_TABLE}}, {{ARCH_DIGEST}}, {{RULES_INDEX_TABLE}}, {{MEMORY_SECTION}}.

Delete any section that genuinely does not apply. Never leave a section with
placeholder text or a vague heading — an empty section is worse than no section.
-->

# {{PROJECT_NAME}} — Agent Instructions

{{ONE_LINE_PURPOSE — one sentence: what this project is and what it does.}}

## Commands

<!-- The single fastest-lookup surface. Rows come from the project's real scripts
     and CLI, resolved from the manifest — never from memory. If the project uses
     a package manager other than the platform default, say so here once. -->

| Action | Command |
|---|---|
| **All gates** | `{{gate command}}` — see `{{quality gate file}}` |
| Install dependencies | `{{...}}` |
| Lint | `{{...}}` |
| Typecheck | `{{...}}` |
| Test | `{{...}}` |
| Build | `{{...}}` |
| Format | `{{...}}` |
| {{stack-specific, e.g. regenerate localizations / dev build / migrations}} | `{{...}}` |

## Definition of Done

A task is complete when **ALL** of:

1. **`{{gate command}}` exits 0** — every gate in `{{quality gate file}}`
   §The Gate Table: lint, typecheck, tests, coverage, duplication,
   vulnerabilities, doctor. One command, because the table exists so this line
   does not have to enumerate.
2. {{stack-specific gate, e.g. `{{health-check command}}` reports no issues}}
3. `{{COMMAND that checks the thing}}` exits 0 — e.g. for "a session log entry
   is appended", this is a script that asserts it, not the sentence asserting it
4. {{a real, non-command gate this project has — e.g. "new/changed auth flows
   smoke-tested on a development build"}}

<!-- Rules for this list:
     - Conjunctive. "ALL of" is load-bearing — it is what stops the agent
       reporting done on work that doesn't run.
     - Every item is checkable: a command with an exit code, a named check, or a
       process step. No item may be a quality judgement.
     - **The gate table is item 1, and it is item 1 deliberately.** It is the
       only item that can be checked mechanically, and the only one whose
       failure is invisible afterwards. A DoD where the gate is item 6 is a
       DoD where the gate is item 6.
     - If a gate's tool is not installed, its line says **absent**, never
       satisfied (`{{quality gate file}}` §Status).
     - Each item names the rule file that owns the detail, if there is one:
       "(see `{{rules file}}` §X)".

     ⚠️ A prose item is the one that gets ignored, and it gets ignored silently.
     A real project carried "the session journal entry appended" as DoD item 8 of 8;
     the other seven had a command behind them, and this one was skipped on 13 of
     26 working commits. The reason is structural, not carelessness: the
     pre-commit review delegates to this list rather than restating it, so the
     item lived at the end of a list — and `git status` structurally cannot
     detect it, because it shows what CHANGED, and an unmodified log file is
     indistinguishable from an up-to-date one.

     So: if a rule or gate can be checked mechanically, it ships with the command
     that checks it. A rule delivered only as prose is a preference, and a
     preference is a decoration. A 20-line script that exits non-zero removes an
     item that prose never will. -->

## Priorities

When rules or goals conflict, resolve in this order:

1. **{{Correctness of the primary contract}}** — {{the external dependency, the
   data model, the thing that corrupts state if wrong}}. Rules in the decisions log
   and `{{contracts rule file}}` are non-negotiable.
2. **Type safety + security** — never skip types or ship a secret to go faster.
3. **Completeness** — the Definition of Done above is fully met.
4. **Quality** — lint clean, patterns followed, formatting consistent.
5. **Speed** — ship fast only after 1–4 are satisfied.

<!-- Ranking is not optional. An unranked set means the agent picks silently and
     you find out later which one it picked. If the project is a rewrite or a
     migration, slot 2 becomes design parity with the source: "if the existing
     code does X, the new code does X unless a decision says otherwise." -->

## Escalation Rules

- If {{the external system}} returns something unexpected: **stop and report**.
  Show the exact response and the shape you expected. Do not invent a workaround.
- If a constraint is undocumented — a validation limit, a rate limit, a field
  contract: **stop and confirm it against the real source**, then encode it. Do
  not invent a threshold.
- If a closed decision in the decisions log conflicts with the task: **stop and
  ask.** Name the decision. Do not silently reverse it.
- If blocked after 2 attempts: **stop, report what you tried, and wait.**
- **Never:** {{force-push · delete the lockfile or `node_modules` to clear an
  error · skip lint or typecheck · weaken a security rule to unblock a feature ·
  test on a platform the feature does not support and call it verified · silently
  pick between two ambiguous interpretations · commit with a failing test}}

<!-- This is the file's escalation ladder and its hard-ban surface for CODE and
     PROCESS. Every other rule file references this section rather than restating
     it. Two attempts, not three: the third attempt is where an agent starts
     inventing workarounds.

     Git-operation bans are deliberately NOT here — they are in
     `git-workflow.md` §When Blocked, which is their domain. Two Never lists in
     one file is fine as long as they don't overlap: this one is about what you
     may do to the codebase, that one about what you may do to the repository. -->

## Git Conventions

**Strategy: `{{trunk-based | git-flow | release-train}}`** — decided at
generation, never inferred from the repository. The full discipline — commit
atomicity, message format, branch rules, integration, hooks — lives in
`{{git workflow rule file}}`.

| Rule | Value |
|---|---|
| Commit format | `<type>(<scope>): <description>`, imperative, no trailing period |
| Branch naming | `{{feature/<name>}}` from `{{main}}` |
| Default branch | `{{main}}` |
| Hooks | `{{lefthook | husky | none}}`, `pre-commit` under 10 s |

The three rules that matter, without their detail:

- **One commit = one intent, independently revertible.** If reverting it alone
  would break the commits after it, the split is wrong.
- **Never mix a refactor with a behaviour change** — they revert differently.
- **The pre-commit review passes before every commit**
  (`{{workflow rule file}}` §Pre-Commit Review).

<!-- This is a POINTER, and it is one for a reason. The full discipline used to
     live here, which meant ~60 lines of detail paid for on every single
     session to be read only at the moment of committing — the opposite of what
     Principle 6 says. The entry file is the always-loaded tier: a threshold
     there is a floor, a paragraph there is a ceiling. It keeps the strategy
     name and the message format (both read constantly) and references the
     rest. -->

## Tech Stack

| Concern | Choice |
|---|---|
| Framework | `{{name + exact version}}` |
| Language | `{{name + exact version, strict mode}}` |
| Package manager | `{{...}}` |
| State | `{{...}}` |
| Data / backend | `{{...}}` |
| Validation | `{{...}}` |
| UI | `{{...}}` |
| Testing | `{{...}}` |
| Build / deploy | `{{...}}` |

<!-- Exact versions, resolved from the manifest. "Next.js" is not a version; a
     version-vague rule is how the model mixes syntax across releases.
     Do NOT write a hedge like "(Default — confirm before treating as final)".
     If a choice is genuinely still open, that is an open question for the user,
     not a hedge to leave in the file.

     ⚠️ This table is a COPY, and a copy of a fact is a second home for it.
     A real project carried one package's version in six places — the manifest,
     this table, a rules file, a planning doc, and two plans — and a finding that
     checked the two files it happened to read was closed as `resolved` while
     three copies still carried a version that made the build fail.

     So: mark it generated, and regenerate it rather than editing it.

     <!-- forge:version-block:generated from {{manifest file}} — regenerate, do not edit -->

     And prefer resolving it at read time over copying it at write time. The
     rule that matters is "never answer a {{Stack}} API question from memory"
     below — that one is a command, and commands do not go stale. -->

<!-- tech:react-native-expo — emit this section only for fast-moving SDKs -->
## {{Stack}} changes faster than your training data — verify before you write

{{Stack}} ships breaking changes every release. An API you remember is likely
renamed, moved, or removed. Before writing code that touches any {{Stack}} API:

1. Read the installed major version from `{{manifest file}}`.
2. Fetch the docs for **that exact version** — `{{versioned-docs-url}}`.
3. {{If the project ships a machine-readable doc index — e.g. an `llms.txt`,
   a bundled skill pack, an MCP server — use it. It carries corrections to known
   LLM misconceptions that the prose docs assume you don't have.}}
4. Never answer a {{Stack}} API question from memory.

## Architecture

{{Four bullets maximum. A digest, not a reference — the detail is in
`{{architecture rule file}}`, and repeating it here is how the two drift apart.}}

- **{{Structure, e.g. feature-first}}** — {{one clause}}
- **{{Dependency direction}}** — {{one clause, plus the grep that enforces it}}
- **{{Shared vs domain boundary}}** — {{one clause}}
- **{{Cross-cutting location}}** — {{one clause}}

Full structure: `{{rules file}}` §Folder Layout.

## Rules Reference

Domain rules are in `{{rules dir}}`. Each file governs one concern — read the
relevant one before working in that area, not all of them.

| File | Governs |
|---|---|
| `{{file}}` | {{one line}} |

<!-- This table is the agent's routing mechanism. It must list every emitted rule
     file and nothing else. A file not listed here will never be read. A listed
     file that does not exist is a broken reference — check before delivering.

     ⚠️ Emit ONE corrections store, not two. `architecture-decision-guide.md` §5
     selects between a separate the lessons log and an in-entry `## Project
     Learnings` section. Emitting both — as this template used to — produces an
     entry file that says "no entries yet" in one place while the other holds
     dozens, and the stale half is the one an agent is most likely to read. -->

## Cross-Session Memory

{{This project compensates for {{zero / limited}} cross-session memory with
{{N}} files at the root, governed by `{{workflow rule file}}` §Memory File
Triggers.}}

- **the session journal** — running record, session by session. Read in full at the
  start of every session. Append an entry before ending any session or commit.
  It opens with a {{project-specific runbook — which tool drives the admin, where
  the credentials live and how to re-issue them}}; read that before any
  {{external-system}} task.
- **the decisions log** — project-wide ADRs. Closed entries are not to be
  re-proposed or silently reversed. Check before any project-wide choice.
{{#if separate-learnings-file}}
- **the lessons log** — append-only corrections log. New rules are born here, from
  a mistake made twice — not from speculation.

  <!-- the lessons log entries name the rule file they will be promoted INTO.
       A correction without a target has no promotion path, and a corrections
       log with no promotion path is a diary that competes with the rules it was
       meant to inform. Format, newest at top:

       - YYYY-MM-DD [domain: <rule file>] <rule that broke> → <correction applied>
  -->
{{else}}
- **Project Learnings** (this section) — corrections log. New rules are born here,
  from a mistake made twice — not from speculation. Each entry names the rule
  file it will be promoted into.

  <!-- Newest at top. Format:
       - YYYY-MM-DD [domain: <rule file>] <rule that broke> → <correction applied>
  -->
{{/if}}
- (no entries yet — grows from real mistakes)
