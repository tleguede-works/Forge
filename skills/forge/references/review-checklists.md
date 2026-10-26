# Reviewer checklists, one per deliverable

Both reviewers read the section of this file that matches the deliverable named in the
delegation header. `forge-qa` asks "what is missing?"; `forge-redteam` asks "what is wrong,
contradictory or untestable?". Every item below is written as a question so a finding can
quote the item it fails.

An empty findings list is allowed only after every item of the matching section was checked.

## brief

- Does every fact come from the user's words or carry the name of who stated it?
- Is every unknown an open question with an owner and a date, rather than a guess?
- Are the target countries, the sector, the payments and the personal data all present?
- Would the compliance phase have to ask anything this brief could have answered?

## contract

- Does the contract describe the collaboration rather than the product?
- Does every touchpoint name who decides, the answer time and the default applied when no answer comes?
- Does a change after approval name the approver and its effect on time and cost?
- Are the exclusions concrete enough to be enforced?

## landscape

- Was every studied product opened, with its URL?
- Does each row end with `keep`, `drop` or `differ`, a reason and a cost of reversal?
- Is the idea challenged, or only described?
- Does the document say what research changed, or why nothing changed?

## compliance-register

- Does every market and every topic of the header appear in a row?
- Is every source a primary URL, with a retrieval date inside `max-age-days`?
- Does every `not-applicable` and every `risk-accepted` cite a decision that quotes the owner?
- Is any row marked `applies` without a trigger the brief actually meets?

## prd

- Does every `B`, `E`, `V`, `C` and `L` carry a source?
- Is every `L` tied to an applicable obligation, and every applicable obligation covered by an `L`?
- Are the success measures numbers with a baseline and a target, or intentions?
- Does every screen, role, permission and refusal path of the product appear?
- Is every requirement testable as written, or does it need a decision?

## roadmap

- Does every live requirement appear in exactly one release or in out of scope?
- Does any release cite an ID that the PRD does not define?
- Is each trade-off written with the cost of reversing it?
- Are the release names `MVP`, `R1`, `R2` rather than `V1` or `V2`?

## design-references

- Are three reference products named with what is taken from each and what is not?
- Is the core loop one sentence with a subject, a verb and an object?
- Do the anti-references say why, rather than just what?

## screen-map

- Does every route and every role have a row, including every admin page?
- Is each release a heading of `roadmap.md`?
- Is a tab, a modal or a state listed as a screen? It is a zone or a state instead.

## layouts

- Does every shell have its own `LAY-` section?
- Is every region listed, and is its responsive behavior stated?
- Does any screen name a layout that does not exist, or a layout have no screen?

## design-system

- Does every token have a value rather than a description?
- Is each text colour measured against the background it is used on, at 4.5:1 or better (3:1 for large text)?
- Does every component list its focus, disabled and error states?

## screen

- Is there exactly one level-1 heading, starting with the screen ID?
- Does the anatomy have a rank, a role, a reason and an attention level per zone, with exactly one `primary`?
- Are the empty, loading, error, offline and partial states described?
- Is the focus order stated for keyboard use?

## architecture

- Does every non-trivial stack choice carry a decision entry with the rejected options?
- Does each module own its entities, with no entity written by two modules?
- Is every type a real type rather than "string"?
- Does every endpoint state its authorization, its errors and the PRD IDs it serves?
- Does every dependency name the version that was verified?

## slices

- Is every slice vertical, and does it fit one plan of at most 15 tasks?
- Does every live requirement appear in a `serves` cell?
- Does any slice serve a withdrawn ID?
- Are foundations first, then the releases in roadmap order?

## rules-report

- Is every gate a command with a pass condition?
- Does every selected template name the signal that selected it, and every omitted one the reason?
- Is the audit output verbatim, or edited?

## plan

- Does the `serves` line equal the `serves` column of `slices.md`?
- Does every task name the files it touches and an observable result?
- Is every acceptance criterion observable without reading the code?
- Does every `TC-` line state a concrete input, a concrete expected result and the ID it verifies?
- Does any task build a layout region without the `LAY-x/region` token?

## plans-index

- Does every slice of `slices.md` have a row?
- Is the order a real execution order, with dependencies before dependants?
- Is every release a heading of `roadmap.md`?

## test-plan

- Does every `B`, `E`, `V` and `L` ID appear in a test case?
- Does every slice appear?
- Is the regression command runnable, with the output that counts as a pass?
- Is a skipped or ignored test presented as a pass anywhere?

## validation-report

- Does every `TC-` of the plans and of the test plan have a result row?
- Is every `result` one of `pass`, `fail` or `blocked`?
- Does every row carry evidence a reader can reproduce?
- Does every applicable obligation appear with its result?
- Does every deviation carry its decision entry?
