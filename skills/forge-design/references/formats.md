# Exact file formats parsed by `forge design check`

## screen-map.md
A table. Each screen row starts with `| SCR-`. Columns: id, route, layout, role.
```
| id | route | layout | role |
|---|---|---|---|
| SCR-001 | /home | LAY-app | user |
```

## layouts.md
One `## LAY-<name>` heading per layout, then one `- region: <name>` line per region.
```
## LAY-app Dashboard shell
- region: sidebar
- region: topbar
- region: content
```

## screens/<id>.md
```
# SCR-001 Home
- layout: LAY-app
- route: /home
## Anatomy
| rank | zone | role | why here | attention |
|---|---|---|---|---|
| 1 | Card carousel | context | cards are the object every action applies to | primary |
```
Roles: context, summary, action, detail, navigation, feedback. Attention: primary, secondary, tertiary. Ranks run 1..n without gaps. An optional line `- region-used: <name>` names the layout regions the screen fills.

## Plans
A plan task that builds a layout region contains the token `LAY-<name>/<region>`, for example `LAY-app/sidebar`.
