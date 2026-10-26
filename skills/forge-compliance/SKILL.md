---
name: forge-compliance
description: Forge phase compliance. Finds the laws and regulations that apply to a project in each target market, records them in a sourced register, and turns the applicable ones into requirements. Use when forge status shows phase compliance, or when the user asks about laws, regulations, legal obligations, data protection, payment or subscription rules, or which markets a product can launch in.
---

# Forge Compliance

Forge does not give legal advice. This phase produces a register for a qualified person to review, and it makes the owner's decisions about legal risk explicit and recorded.

Deliverable: `compliance-register` (`.forge/compliance-register.md`), from `references/register-template.md`, written in the project language. Producer agent: `forge-compliance`. Reviewers: `forge-qa` and `forge-redteam`. Phase `compliance` is a client touchpoint.

## Procedure

1. Read `.forge/brief.md`: markets, regulated areas, payments, subscriptions, data, minors. Write the header lines `- markets:` (country or region codes), `- topics:` (payments, subscriptions, personal-data, minors, and every area the brief names) and `- max-age-days:` (default 180).
2. For each market and topic, search the web and open the primary source: the statute text or the regulator's page. A blog, a summary or a recollection is not a source.
3. Write one row per obligation: `OB-<n>`, jurisdiction, trigger (the condition that makes it apply), obligation in plain words, source URL, retrieval date, applicability, legal review, decision.
4. Set applicability: `applies` when the project as described in the brief meets the trigger; `not-applicable` when it does not; `unknown` when you cannot tell. `unknown` blocks the gate.
5. Set legal review: `required` for any obligation with fines, licensing or criminal liability, or whose text is ambiguous for this project; `not-needed` for plain obligations. Only the owner moves a row to `done` (a qualified person reviewed it) or `risk-accepted` (the owner proceeds without review). Either needs `forge memory decide --text "..." --user-evidence "<the owner's words>"`, and the decision ID `D-<n>` goes in the `decision` column.
6. Register, run both reviews, then `forge gate check`. In client mode, follow the touchpoint procedure of the `forge` skill: the summary names the laws that matter, what is uncertain, and what the client must decide.

## After this phase

- **PRD.** Every applicable obligation becomes a requirement `L<n>` that cites its `OB-<n>`. The CLI refuses the PRD gate when an applicable obligation has no `L`, or an `L` cites an obligation that is not applicable.
- **Rechecks.** Run `forge compliance recheck --phase <prd|architecture|validation> --evidence "<what was re-checked and found>"` before the gate of each of those phases. At the PRD: new features against the topics of the register. At architecture: where data is stored and processed, retention, processors, encryption, cross-border transfer. At validation: each applicable obligation, its requirement and its test result.
- **New obligation found.** `forge phase reopen compliance --reason ...`, then update the register.

## Rules

- **C1 Sources.** Every row has a primary source URL and a retrieval date. A claim from memory is `unknown`.
- **C2 Nothing applies everywhere.** Every row names its jurisdiction and its trigger.
- **C3 Not applicable is a decision.** It needs the owner's words recorded.
- **C4 Freshness.** A source older than `max-age-days` is verified again before the gate.
- **C5 Proportion.** A small project has few rows, and every market and topic of the brief still appears in one or more rows.
- **C6 Review roles.** `forge-qa` checks that the brief is covered. `forge-redteam` challenges every `not-applicable` row and every market or topic that has no row.
