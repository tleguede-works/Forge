---
name: forge-design
description: Forge phase 4. Produces the design deliverables - visual references, screen map, layouts, design system and one anatomy file per screen with ranked information hierarchy. Use when forge status shows phase design, or when the user asks for screens, wireframes, UI or UX specs, layouts, or a design system.
---

# Forge Design

Write every deliverable in the project language. All files live in `.forge/design/`. The CLI parses these files, so formats in `references/formats.md` are exact.

## Procedure

1. **References** (`design-references`, `.forge/design/references.md`): three reference products with what is taken from each, three mood words, anti-references, the archetype and the core loop. If a design skill is installed, load it first. If none is installed, apply `references/hierarchy.md` alone; the CLI checks run the same way.
2. **Screen map** (`screen-map`, `.forge/design/screen-map.md`): one row per route and per role. Every admin page is its own row. A tab, a modal and a state are not screens; they are zones or states inside a screen.
3. **Layouts** (`layouts`, `.forge/design/layouts.md`): one `LAY-` section per shell (visitor and auth, app with sidebar, app with bottom navigation, landing, wizard, full screen). List every region as `- region: <name>`, with its responsive behavior.
4. **Design system** (`design-system`, `.forge/design/design-system.md`): tokens with concrete values (colors, type scale, spacing, radius), primitive components, navigation order. A token with no value is a defect.
5. **Screens** (`screen:<id>`, `.forge/design/screens/<id>.md`): one file per screen-map row, built from `references/screen-template.md`. The anatomy is a ranked table. Choose the order with `references/hierarchy.md`; a pattern from that file is the starting order.
6. Run `forge design check`. Fix every line it prints.
7. Register every file, run `forge-qa` and `forge-redteam` on each, then `forge gate check` (see the `forge` skill). The gate runs the design check again and refuses an unregistered screen.

## Rules

- **D1 One file, one screen.** One level-1 heading per screen file, starting with the screen ID.
- **D2 Layout is a contract.** Every screen names a layout defined in `layouts.md`. Every region of every layout becomes a task in the implementation plans (phase plans), and the CLI refuses the plans gate when a region has no task.
- **D3 Ranked anatomy.** Each zone has a rank, a role, a reason for its position, and an attention level. Exactly one zone is `primary`.
- **D4 Hierarchy rules H1 to H9** in `references/hierarchy.md` apply to every screen. A deviation names the rule it breaks in its reason cell.
- **D5 Client touchpoint.** In client mode, present two or three visual directions in plain language at the end of step 1 and record the choice with `forge memory decide`.

## Agents

Producer: `forge-designer`. Reviewers: `forge-qa` and `forge-redteam`. The reviewers run the checklist in `references/review-checklist.md` in addition to the generic review.
