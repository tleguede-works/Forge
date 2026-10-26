# Roadmap: <product name>

Releases are named `MVP`, `R1`, `R2`. Never `V1` or `V2`: those look like validation IDs.
Every requirement appears in exactly one release or in the PRD out of scope section.

## MVP {#mvp}
| Item | Delivers (IDs) | Why in the MVP | What is left out |
|---|---|---|---|
| <item> | <ids> | <reason> | <feature and why it waits> |

## R1 {#r1}
| Item | Delivers (IDs) | Why after the MVP | What is left out |
|---|---|---|---|
| <item> | <ids> | <reason> | <feature and why it waits> |

## R2 {#r2}
| Item | Delivers (IDs) | Why after R1 | What is left out |
|---|---|---|---|
| <item> | <ids> | <reason> | <feature and why it waits> |

## Trade-offs {#trade-offs}
| Decision | Gain | Cost | Cost of reversal |
|---|---|---|---|
| <decision> | <gain> | <cost> | <what undoing it costs> |

## Coverage {#coverage}
| Requirement | Release | Justification |
|---|---|---|
| <B-n> | <MVP, R1 or R2> | <reason> |

Every B, E, V, C and L ID of the PRD appears above exactly once, or in the PRD out of scope section.
A row whose requirement does not exist in the PRD is refused by `forge check coverage`.
