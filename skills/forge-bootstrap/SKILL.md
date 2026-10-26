---
name: forge-bootstrap
description: Forge phase bootstrap. Opens an engagement - records the client's request, markets, constraints and stated technical choices in a brief, and the terms of the collaboration in a contract. Use when forge status shows phase bootstrap, or when the user starts a new project, hands over a client request, or asks to set the project language, mode or touchpoints.
---

# Forge Bootstrap

Deliverables: `brief` (`.forge/brief.md`) and `contract` (`.forge/contract.md`). Write both in the project language. Producer agent: `forge-analyst`. Reviewers: `forge-qa` and `forge-redteam`. The bootstrap phase is a client touchpoint.

## Procedure

1. Confirm the project language (`forge status`, `lang=`) and the mode. Ask the user which mode they want and set it with `forge mode <interactive|client> --evidence "<their words>"`.
2. Collect the facts the later phases depend on: the request in the client's own words, the goal, the users, the target countries, any regulated area (finance, health, minors), whether payments or subscriptions exist, the data collected, the technical choices the client has already stated, the deadline and budget signals, and who answers questions and how fast.
3. Write `brief` from `references/brief-template.md`. Every fact comes from the user. A missing fact becomes an open question with an owner and a date; it is never filled in by you.
4. Write `contract` from `references/contract-template.md`: parties, how the process runs, the touchpoints and their answer times with the default that applies when no answer comes, how a change after approval is handled (`forge phase reopen`), and what the process does not include. The contract holds no feature list; the scope comes from the PRD and the roadmap.
5. Register both, run both reviews, run `forge gate check`, then approve with the client's words. In client mode, first follow the touchpoint procedure of the `forge` skill.

## Rules

- **BS1 Stated choices are constraints.** A technology the client has named is recorded in the brief under Stated technical constraints, and the PRD takes it as a constraint `C<n>`.
- **BS2 No invented answers.** An unknown stays an open question.
- **BS3 No scope in the contract.** The contract describes the collaboration, not the product.
- **BS4 Markets and regulated areas are asked now.** They feed the compliance phase and cannot be recovered cheaply after the PRD.
- **BS5 Resuming.** When `.forge/` already holds answers from an earlier session, read them first and record them in the brief with their source. Ask only what is still missing, in one message. Never ask again what a file answers, and never keep retrying a gate that needs the user's signature or approval: ask for it.
