# Format of `.forge/slices.md` (parsed by the CLI)

One row per slice, in execution order: foundations first, then the roadmap releases.
Columns: `id`, `name`, `module`, `serves` (comma-separated PRD IDs, or `-` when a
foundation serves no listed ID). Identifiers `S<n>` are never reused.

| id | name | module | serves |
|---|---|---|---|
| S01 | App shell and layouts | foundation | C1 |
| S02 | Card payment | billing | B1,B2,E1,V1 |

A removed slice keeps its line under `## Removed`, without the leading pipe, with the reason.
