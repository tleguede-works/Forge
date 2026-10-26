# PRD: <product name>

## 1. Problem and audience {#problem-and-audience}
Three short paragraphs: the problem in the user's own words, who has it today, and what they do instead.
- problem:
- what it costs today:
- who has it:

## 2. Personas and permissions {#personas-and-permissions}
One row per kind of user. Permissions are part of the requirement, not of the design.
| Persona | What they need | What they can see | What they can do | What they must never do |
|---|---|---|---|---|
| Visitor | <need> | <data> | <actions> | <forbidden actions> |

## 3. Goals and success measures {#goals-and-success-measures}
A goal with no baseline and no target is an intention, not a measure.
| Measure | Baseline today | Target at launch | How it is measured | Deadline |
|---|---|---|---|---|
| <measure> | <number> | <number> | <source of the number> | <YYYY-MM-DD> |

## 4. Business rules {#business-rules}
One rule per line, one stable ID, one source, and an ID is never reused. The shape is
`- B1 <rule> (source: <landscape row or user-stated>)`.

## 5. Edge cases {#edge-cases}
One line per case: the condition, then the expected behaviour. The shape is
`- E1 <case> -> <expected behavior> (source: <user-stated>)`.

## 6. Validations {#validations}
Every input the product refuses, and what the user sees when it does.
| ID | Field or action | Rule | Error shown to the user | Source |
|---|---|---|---|---|
| V1 | <field> | <rule> | <error message> | <source> |

## 7. Constraints {#constraints}
What the product cannot change: named technologies, hosting, contracts, deadlines. The
shape is `- C1 <constraint> (source: <brief or user-stated>)`.

## 8. Non-functional requirements {#non-functional-requirements}
A requirement here has a measure and a test. "Fast" and "secure" are not requirements.
| ID | Area | Requirement | Measure | Source |
|---|---|---|---|---|
| V2 | performance | <requirement> | <p95 or limit> | <source> |

## 9. Legal requirements {#legal-requirements}
One line per applicable obligation of the compliance register. The obligation ID is the
source, in the shape `- L1 <what the product must do or avoid> (obligation: OB-<n>)`.

## 10. User stories {#user-stories}
One row per story. Acceptance criteria are numbered and observable, and each row cites the IDs it implements.
| Story | As a | I want | So that | Acceptance criteria | Implements |
|---|---|---|---|---|---|
| US-1 | <persona> | <capability> | <benefit> | 1. <check> 2. <check> | B1,E1 |

## 11. Data and retention {#data-and-retention}
Every field the product stores, its sensitivity, and when it is deleted.
| Data | Class | Why it is needed | Where it is stored | Retention | Who can read it |
|---|---|---|---|---|---|
| <data> | <public / personal / sensitive> | <need> | <store> | <duration> | <roles> |

## 12. Assumptions and risks {#assumptions-and-risks}
What is believed without proof, and what happens when the belief is wrong.
| ID | Assumption or risk | Impact if wrong | How it is checked | Owner |
|---|---|---|---|---|
| A1 | <assumption> | <impact> | <check> | <owner> |

## 13. Dependencies and integrations {#dependencies-and-integrations}
Every external system the product relies on, and what happens when it is unavailable.
| Dependency | What it provides | Owner | Contract or SLA | Failure behavior |
|---|---|---|---|---|
| <dependency> | <service> | <who runs it> | <SLA> | <degraded behavior> |

## 14. Glossary {#glossary}
Every term the PRD uses in a way a newcomer would not guess.
| Term | Definition |
|---|---|
| <term> | <definition> |

## 15. Release mapping {#release-mapping}
The first cut of the order. The roadmap owns the release names and is authoritative.
| Requirement | Release | Why this order |
|---|---|---|
| B1 | MVP | <reason> |

## 16. Open questions {#open-questions}
Each with an owner and a date. Write `None yet; <why>` when nothing is open.
| Question | Owner | Answer by |
|---|---|---|
| <question> | <owner> | <YYYY-MM-DD> |

## 17. Out of scope {#out-of-scope}
A removed requirement keeps its ID here with its reason, in the shape
`- B99 <removed requirement>: <reason>`. Write `None yet; nothing has been removed` only
before the first removal.
