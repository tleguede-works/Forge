# Cursor `.mdc` Frontmatter Spec

**Context note**: this file has not been exercised against a real Cursor project in any session so far — every project this skill has actually run against in practice used OpenCode/AGENTS.md, not Cursor. Treat the content below as correct-per-documentation but unverified-by-use, same distinction this skill now applies to its own profiles (see `profiles/*/PROFILE.md` Status lines). It stays in the skill because Cursor is a real, common target this skill claims to support (see SKILL.md's tool list) — but the next time this skill is actually pointed at a Cursor project, this file deserves a deliberate check against what really happens, not just a reread.

## Location

`.cursor/rules/*.mdc` at the project root. Subdirectories are supported (`.cursor/rules/frontend/react.mdc`). Check the whole directory into git.

Legacy `.cursorrules` (single file, project root) is deprecated — it's ignored by Agent mode entirely. Never generate one; migrate any existing one into `.cursor/rules/*.mdc`.

## Frontmatter fields

```yaml
---
description: "Short summary — used by the agent to judge relevance in intelligent mode"
alwaysApply: true | false   # default false
globs: ["**/*.tsx", "src/app/api/**"]   # string or array of glob patterns
---
```

| Field | Type | Purpose |
|---|---|---|
| `description` | string | What this rule covers. Required for intelligent-mode matching; still worth writing even on always-apply/glob files as a one-line index for humans skimming the directory. |
| `alwaysApply` | boolean | `true` = loaded into every chat session regardless of context. Default `false`. |
| `globs` | string or array | File patterns that trigger inclusion when matching files are in the chat/agent context. |

## The four activation modes

| Mode | Frontmatter shape | Fires when |
|---|---|---|
| Always Apply | `alwaysApply: true` | Every session. Universal stuff only — see budget note below. |
| Apply Intelligently | `description` set, no `globs`, `alwaysApply: false` | Agent reads the description and decides if it's relevant to the current task. |
| Apply to Specific Files | `globs: [...]` set | Matching files are present in the current context. |
| Apply Manually | No frontmatter, or `alwaysApply: false` with no `globs`/`description` doing the matching | Only when the user types `@rule-name` in chat. |

## Precedence

Team Rules (org-level, if configured) > Project Rules (`.cursor/rules/`) > User Rules (Cursor Settings → General → Rules for AI). When multiple rules match a given moment, **all of them** are included together — precedence only matters if they explicitly conflict, which they shouldn't if you followed the "one fact, one location" principle.

## Token/length budget

- Practical ceiling: **under ~500 lines per file**. Content beyond that risks silent truncation from context.
- Combined **always-apply** tier: keep under roughly **2,000 tokens** (~500 lines of plain English, roughly 4 tokens/line as a rule of thumb). This is the tier that taxes every single session regardless of task, so it's the one to keep lean.
- **These are ceilings, not targets.** If you're over, first check for tutorial prose to cut (Principle 1, tier 1 in SKILL.md) and move anything that doesn't need to be universal into glob-scoped or intelligent mode. Never trim operational content (tier 2 — decision rules, thresholds, banned patterns) just to hit the number. A rule set that's over budget but complete is a smaller problem than one that's on-budget with silently missing rules — the former costs a few hundred tokens of context, the latter costs a repeated production mistake.

## Cursor also reads AGENTS.md

Cursor auto-discovers `AGENTS.md` at the project root and in subdirectories, in addition to `.cursor/rules/`. Two implications for this skill:

1. For a Cursor-only project with no other tool in the mix, generating `AGENTS.md` as canonical and skipping `.mdc` entirely is a legitimate, simpler choice — reserve `.mdc` for when you actually need glob-based file-type scoping or the intelligent-matching mode, since AGENTS.md has no equivalent to either (it's always loaded in full).
2. For a multi-tool project, `.mdc` files should reference `AGENTS.md` sections rather than re-deriving the same content, since Cursor will load both.

## Quick self-test after generating

Ask the agent (cold session, no other context) to state its build command and its definition of done for a given domain. If it can't reproduce them accurately, something is wrong with discovery, length, or clarity — fix that before adding more rules.
