# Architecture: <product name>

## 1. Stack and justification {#stack-and-justification}
| Concern | Choice | Version verified | Satisfies | Rejected options and reason |
|---|---|---|---|---|
| <concern> | <choice> | <version and where it was verified> | C1 | <option: reason> |

## 2. Modules {#modules}
A module owns its data. No entity is written by two modules.
| Module | Responsibility | Entities it owns | Slices it contains |
|---|---|---|---|
| <module> | <responsibility> | <entities> | S01, S02 |

## 3. Foundations {#foundations}
Cross-cutting work built before business slices.
| Foundation | What it provides | Layout regions it owns (`LAY-x/region`) | Slice |
|---|---|---|---|
| <foundation> | <capability> | <tokens> | S01 |

## 4. Slices {#slices}
Summary of `.forge/slices.md` with the dependency graph.
| Slice | Depends on | Delivers (PRD IDs) | Module |
|---|---|---|---|
| S01 | none | C1 | foundation |

## 5. Data model {#data-model}
One row per field. The type is the real database type, not "string".
| Entity | Field | Type | Nullable | Default | Index | Owner module |
|---|---|---|---|---|---|---|
| <entity> | <field> | <type> | no | <default> | <index> | <module> |

Relations, with the delete behavior:
| From | To | Cardinality | On delete |
|---|---|---|---|
| <entity> | <entity> | one-to-many | <cascade / restrict> |

## 6. API contracts {#api-contracts}
One block per endpoint or public function: inputs, outputs, errors, authorization, PRD IDs served.
| Endpoint or function | Inputs | Outputs | Errors | Authorization | Serves |
|---|---|---|---|---|---|
| <endpoint> | <inputs> | <outputs> | <errors> | <role> | B1 |

## 7. External integrations {#external-integrations}
| Integration | Purpose | Protocol | Auth | Failure behavior | Data sent |
|---|---|---|---|---|---|
| <integration> | <purpose> | <protocol> | <auth> | <degraded behavior> | <data> |

## 8. Dependencies {#dependencies}
| Name | Version verified | Reason | License | Owner |
|---|---|---|---|---|
| <dependency> | <version> | <reason> | <license> | <module> |

## 9. Deployment and configuration {#deployment-and-configuration}
| Environment | Host | Config source | Secrets | Backup | Rollback |
|---|---|---|---|---|---|
| <environment> | <host> | <file or service> | <store> | <policy> | <procedure> |

## 10. Risks and open questions {#risks-and-open-questions}
| ID | Risk or question | Impact | Mitigation or owner | Deadline |
|---|---|---|---|---|
| R1 | <risk> | <impact> | <mitigation> | <YYYY-MM-DD> |
