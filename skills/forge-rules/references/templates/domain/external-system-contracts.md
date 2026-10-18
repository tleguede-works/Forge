# Template · External System Contracts

<!--
GENERATOR NOTES — delete this block in the emitted file.

**This file is emitted with its entries section empty. That is the design, not an
oversight.** It ships as a structured empty file. A template that arrived
pre-filled would be pre-filled with the source project's quirks, which is
precisely the cross-project contamination this skill exists to prevent.

Two rules in here are not in any source file and exist because of a defect found
in one of them:

  §Promotion Rule — an entry that applies beyond its first case must be
  promoted into the owning domain rule file. The source project's discoveries
  file accumulated thirteen entries over several days while the domain rule it
  contradicted stayed uncorrected. A findings file that never changes behaviour
  is a diary, not a rule.

  §The entry is a fact, not a fix — record what the system does, not what this
  project decided to do about it. A fact survives; a workaround is wrong the
  moment the system changes.

Emit this file when the project depends on an external system whose behaviour
is not fully specified by its documentation: a third-party API, a legacy
backend, a payment or auth provider, a vendor platform. For a project whose
dependencies are entirely first-party, it is not needed — say so and skip it.
-->

# External System Contracts — Real Discovered Behaviour

**This file starts empty by design. Do not pre-fill it with hypothetical
rules.** Its entire value is capturing the behaviour of `{{the external system}}`
that was discovered the hard way and would otherwise repeat — silently — in
every future session.

## What Belongs Here, and What Doesn't

| Belongs here | Belongs in a domain rule file |
|---|---|
| A behaviour of `{{the external system}}` that contradicts its documentation, or that the documentation doesn't state | The rule that follows from a *documented* behaviour — stated plainly, with no archaeology |
| A constraint that had to be measured against the real endpoint | Anything the project's own team decided |
| A field or endpoint that behaves differently than the schema suggests | A general engineering practice |
| A tooling trap in the integration toolchain | Anything guessable from the type signature |

**Known, documented behaviour belongs in the domain rule file** — write it
there as a plain rule. This file is only for what a session had to go and
find out.

> Why this is a rules file and not documentation: a statement of the form *"is
> this payload acceptable or not"* about a specific external contract is a
> decision rule. An agent can get it confidently wrong, and the cost is silent
> data corruption. That makes it operational, even though it reads as a
> sentence with no command attached.

## When to Add an Entry

- A write operation behaves unexpectedly given its payload — a field silently
  nulls, an option is ignored, a field turns out to be required and isn't
  marked as such.
- An endpoint that is expected to exist is absent, or returns a status or shape nobody
  expected for a case that looks handled.
- The system enforces a constraint the client has to mirror: a rate limit beyond
  the documented one, a maximum, a market or region behaviour, a field only
  populated after configuration.
- **Two enum sets that look interchangeable aren't** — a query fails as a whole
  because a variable declared for one is reused in the other.
- **A field that fails the entire query when missing**, rather than returning
  null as the schema suggests.
- **Anything discovered about this specific deployment** that would silently
  repeat: this store's metafield keys, this environment's behaviour, this
  account's configuration.
- **A trap in the integration tooling itself** — a deployment command that
  silently reused a stale build, a generator that doesn't regenerate.

**Every entry must be confirmed**, not inferred. Confirmed means one of:

- hitting the real endpoint and reading the real response
- reading the official documentation **for the exact version this project pins**
- reading the system's own source, if accessible
- an explicit statement from the provider

**Never** from an assumption about how a system of this kind is supposed to behave.
Assumptions are how wrong entries get written, and a wrong entry is worse than
no entry: it is believed, cited, and built on.

## Entry Format

```
- **<one-line statement of the behaviour>.** <Why it matters — the concrete
  behaviour that makes this necessary, and what goes wrong if you don't know it.>
  (Confirmed: <date>; against: <environment / API version>.)
```

**The bar for specificity:** an entry is concrete enough that another session can
act on it without re-investigating. Compare:

- Too general — *"always validate your inputs"*. Useless; it is a platitude.
- Too vague — *"the API is inconsistent"*. Useless; it can't be acted on.
- Right — *"`{{field}}` is not the shipping cost. It bundles delivery charges and
  taxes before cart-level discounts, so on a store with no configured delivery
  rate it returns exactly the subtotal, and a shipping row fed from it can never
  reconcile. Read the delivery groups instead; an empty connection means the shop
  has no delivery option and the UI must say 'calculated at checkout' rather than
  quote a number."*

**Record the behaviour, not the workaround.** The fact is that the field means
something else; that the project reads a different field is a decision, and
decisions belong in the decisions log. When the external system changes, a recorded
fact tells you what to re-check; a recorded workaround just becomes wrong.

Keep each entry to a few lines — enough to act on, not a debugging narrative.

## Promotion Rule

**An entry that applies beyond its first case must be promoted into the
owning domain rule file, and the entry stays here as its provenance.**

This is the rule that makes the file a rules file rather than a diary. Without
it, findings accumulate next to the rules they had to change, and a
session reads the rule, misses the contradiction, and repeats the bug.

Promotion looks like this:

1. The entry states a behaviour that isn't specific to one deployment — it's
   true of the system, or of a whole class of usage.
2. The owning domain rule file gets the rule, stated as a plain rule with no
   archaeology: *"Mutations answer under their own field name; unwrap the named
   field."* Not *"we once found that…"*.
3. The rule file cites the entry for provenance where useful.
4. The entry stays. It's the evidence, and it's what tells a future session the
   rule isn't arbitrary.

**Conversely:** an entry that stays project-specific — this store's
configuration, this environment's quirk — is *correct* where it is and is
never promoted. The test is whether the statement is true beyond this
deployment.

**At review time, check both directions:** a domain rule contradicted by an entry
here is a defect, and an entry that has been true for several sessions
without being promoted is a defect.

## Entries

<!-- Newest at top. Add entries above this line.
     Format per §Entry Format. Empty is the correct initial state. -->

- (no entries yet — this file grows only from confirmed findings, never from
  assumptions)
