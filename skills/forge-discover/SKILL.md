---
name: forge-discover
description: Forge phases 1 to 3. Researches what already exists (landscape benchmark), writes the PRD with stable requirement IDs, then the roadmap. Use when the forge status shows phase landscape, prd or roadmap, or when the user asks to research competitors, write a PRD, a BRD, a roadmap or an MVP scope.
---

# Forge Discover

Three phases, in this order. The benchmark comes first so that research changes what gets specified.

Write every deliverable in the project language (`forge status`, `lang=`). Load the template file named in each step before writing.

## Phase 1: landscape (deliverable `landscape`, `.forge/landscape.md`)

Template: `references/landscape-template.md`.

1. Run the premise challenge. Launch the `forge-redteam` agent in challenge mode on the raw idea: is the problem real, already solved, or too large? Record its questions and the user's answers in the document.
2. Name the application archetype and write the core loop in one sentence.
3. Find three or more existing products or open-source projects that solve the same problem. Use web search. Open each product page or documentation; a name alone does not count.
4. For each product, record what it does, who it serves, its price model, what users praise, and what users complain about.
5. Extract invariants: properties that no solution of this problem can violate. Record properties, not code.
6. Fill the decision table. Every row ends with one verdict: `keep`, `drop` or `differ`, plus a reason. A row with no verdict is incomplete.
7. If the research changed no decision, write that sentence in the document. Do not pad.

Then register, review, gate (see the `forge` skill).

## Phase 2: prd (deliverable `prd`, `.forge/prd.md`)

Template: `references/prd-template.md`.

1. Interview the user. Interactive mode: ask. Client mode: ask in business terms and batch the questions.
2. Give every business rule an ID `B<n>`, every edge case `E<n>`, every validation `V<n>`, every constraint `C<n>`. An ID is never reused. A removed requirement keeps its ID in the Out of scope section with its reason. New requirements take numbers after the highest number ever used.
3. Every requirement cites the landscape row that justifies it, or says `user-stated`.
4. Launch `forge-redteam` in challenge mode on the finished PRD.
5. Client mode: produce a one-page plain-language summary for the validation touchpoint.

## Phase 3: roadmap (deliverable `roadmap`, `.forge/roadmap.md`)

Template: `references/roadmap-template.md`.

1. Split the PRD into releases named MVP, R1, R2 (never V1 or V2: those look like validation IDs). Each item lists the requirement IDs it delivers.
2. Every PRD requirement appears in exactly one release or in Out of scope. A requirement in no release is a gap.
3. Record each scope trade-off with its cost of reversal.

## Agents

Producer: `forge-analyst`. Reviewers: `forge-qa` and `forge-redteam`, per the `forge` skill rule R4.
