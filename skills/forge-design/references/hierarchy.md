# Information hierarchy rules

Rules H1 to H9 apply to every screen. The CLI checks H1 and H2 mechanically. The reviewers check the others.

## Rules
- **H1 Context before action.** The object an action applies to ranks above the action. Example: on a banking home, the card carousel ranks above send money.
- **H2 Summary before detail.** Indicators rank above charts, charts above tables. Example: a dashboard starts with its KPI strip and ends with the detail table.
- **H3 One focal point.** One zone is `primary`. One primary action per screen.
- **H4 Frequency decides rank.** What the user reads or does most often ranks higher. Estimate frequency from the PRD core loop.
- **H5 Proximity.** Zones that belong together are adjacent. Unrelated zones are separated.
- **H6 Progressive disclosure.** Rare or heavy detail sits behind an expand, a tab or a detail screen.
- **H7 Reading pattern.** Dense screens follow an F pattern: key content top-left in left-to-right languages, top-right in right-to-left ones. Sparse screens follow a Z pattern.
- **H8 Reach on mobile.** Frequent actions sit in the lower third of the screen. Navigation sits at the bottom.
- **H9 Deviation is written.** A zone that breaks a rule says which rule in its reason cell.

## Starting orders by pattern
| Pattern | Order |
|---|---|
| Mobile banking home | balance and card carousel (context), quick actions, recent transactions, promotions |
| Dashboard | filters and period, KPI strip, charts, detail table |
| List and detail | search and filters, list, selected item detail, bulk actions |
| Form | title and purpose, fields ordered by need to fill, primary action, secondary action |
| Authentication | brand, form, primary action, secondary links, legal |
| Settings | groups ordered by frequency of use, destructive actions last |
| Landing page | hero with value proposition and call to action, proof, features, pricing, questions, final call to action |
| Admin list page | page title and primary action, filters, table, pagination |
| Admin detail page | entity summary, status and key facts, tabs or sections of detail, history, destructive actions |
