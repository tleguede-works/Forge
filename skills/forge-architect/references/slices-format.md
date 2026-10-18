# Format of `.forge/slices.md` (parsed by the CLI)

One row per slice. A row starts with `| S` and a number. Columns: id, name, module, serves (comma-separated PRD IDs, or `-` for a foundation that serves no listed ID).

```
| id | name | module | serves |
|---|---|---|---|
| S01 | App shell and layouts | foundation | C1 |
| S02 | Card payment | billing | B1,B2,E1,V1 |
```

Identifiers `S<n>` are never reused. A removed slice keeps its row in a section `## Removed` below the table, without the table pipe at the start of the line.
