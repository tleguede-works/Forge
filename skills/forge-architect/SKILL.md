---
name: forge-architect
description: Forge phase architecture. Chooses the stack with justification, splits the product into foundations and vertical slices, and designs data model, API contracts and dependencies. Use when forge status shows phase architecture, or when the user asks for system design, architecture, slices, modules or a data model.
---

# Forge Architect

Deliverables: `architecture` (`.forge/architecture.md`) and `slices` (`.forge/slices.md`). Write both in the project language. Producer agent: `forge-architect`. Reviewers: `forge-qa` and `forge-redteam`.

## Vocabulary

- **Slice**: one feature built end to end (interface, logic, data, integration). The unit of planning and implementation. It answers one need of the PRD.
- **Foundation**: a cross-cutting concern built before business slices (app shell and layouts, design system code, authentication, error handling, internationalization, configuration, logging, CI). A foundation is a slice row whose module is `foundation`.
- **Module**: a technical grouping of slices, used to organize the architecture. Its rank follows how often users reach it.

## Procedure

1. Read `prd.md`, `roadmap.md`, the design files, and `brief.md`.
2. Choose the stack. Each non-trivial choice gets a `forge memory decide` entry with the options rejected and the PRD constraint IDs (`C<n>`) it satisfies. Verify framework and library versions against official documentation; write the version you verified.
3. List foundations. Every layout in `layouts.md` belongs to a foundation slice, and every region of that layout is named in the architecture.
4. Cut the business features into slices. A slice is vertical, fits one plan of at most 15 tasks, and serves named PRD IDs.
5. Write `slices.md` in the exact format of `references/slices-format.md`. Order rows: foundations first, then slices by roadmap release, then by frequency of use.
6. Write `architecture.md` from `references/architecture-template.md`: modules, data model, API contracts, external integrations, dependency list, deployment, and the dependency graph between slices.
7. Run `forge check coverage`. Fix every line it prints.
8. Register with the requirement IDs each document rests on: `forge register architecture .forge/architecture.md --requires B1,C2`. A deliverable that rests on a requirement later withdrawn is reported by `forge check premises`.
9. Run the reviews, then the gate (see the `forge` skill).

## Rules

- **A1 Total coverage.** Every live PRD requirement is served by one or more slices. The CLI refuses the gate otherwise.
- **A2 No phantom IDs.** A slice cites only live PRD IDs. A withdrawn ID is refused.
- **A3 Justified choices.** A stack or pattern choice with no decision entry is a defect the reviewers report as `major`.
- **A4 Contracts are concrete.** Every API contract names its inputs, outputs, error cases and the PRD IDs it serves.
- **A5 No later-phase content.** Task lists and code belong to the plans phase.
