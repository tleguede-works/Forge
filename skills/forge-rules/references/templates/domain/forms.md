# Template · Forms & Validation

<!--
GENERATOR NOTES — delete this block in the emitted file.

Owns: the form-state / validation split, the validation timing rule, the
double-submit guard, and the mapping of server failures back onto fields.

The load-bearing rule is the first one: the schema is the source of truth and
the type is derived from it. Every audited project that had this right also had
the "no hand-written duplicate shape" rule attached to it — the two travel
together, because the duplicate shape is what the derivation prevents.

The accessibility attributes on fields are NOT here — they are in
`accessibility.md` §Form Fields, and this file references them.
-->

# Forms & Validation Rules

## Commands

- Install (once, when the first real form lands): `{{...}}`
- Typecheck: `{{...}}`

## Definition of Done

A form change is complete when **ALL** of:

1. The validation schema lives in the designated module, and the form's value
   type is **derived** from it — not written alongside it.
2. Validation is not triggered while the user is still typing a field for the
   first time.
3. The submit control is disabled while the submission is in flight.
4. Every field has an associated label, and validation errors are wired to
   their field programmatically (`accessibility.md` §Form Fields).
5. A failed submit says **why** and **which field** — never a generic banner.

## The Schema Is the Source of Truth

- **One schema per form**, co-located in `{{validation module}}` or beside the
  feature when it is domain-specific.
- **The value type is derived from the schema**:
  ```{{lang}}
  {{const Input = z.infer<typeof schema>}}
  ```
  **No hand-written duplicate shape. No `{{any}}` typed out of the form's raw
  values.** A duplicate shape is a second source of truth that will drift.
- **Export both the schema and the inferred type.** A consumer that needs the
  type shouldn't have to re-derive it.
- **One bridge, never two.** If the form library and the validation library need
  an adapter, that adapter is a single shared helper — reuse it, don't hand-roll
  a second one inline.
- **Never build a query, filter, or path by concatenating user input.** Validate,
  then pass typed arguments.

## Validation Timing

**Validate on submit. And on change, only after a submit has already failed.**

- Do not mark a field invalid while the user is still typing it for the first
  time. That is a hostile experience and it trains people to ignore the errors.
- Once a submit has failed, live validation on the fields that were wrong is
  helpful — the user can see the error clear as they fix it.
- **Opt individual fields into earlier validation only where earlier feedback
  genuinely helps** — a field with an async uniqueness check, for example.
- **Filter and search schemas are forgiving**: optional fields with safe
  defaults, so an empty filter still validates. A search form that errors on an
  empty query has failed at its job.

## Double Submit

- **The submit control is disabled while the submission is in flight**, and
  shows its pending state on the control itself
  (`errors-and-loading-states.md` §Mutation Feedback).
- **Never allow a double submit.** Two of the most expensive bugs in this class
  are duplicate orders and duplicate payments, and both are one missing `if
  (isSubmitting) return`.
- This is a correctness control, not a UX nicety. It does not get relaxed for
  "just this once".

## Server Errors

- **A field-level failure from the server maps back onto its field.** Read the
  field identifier out of the error payload and attach the message to that
  input. A banner saying "validation failed" forces the user to hunt.
- **A failure with no field is shown at the form level**, near the control that
  triggered it, still explaining what happened.
- **Show the field errors and clear them as the user fixes them** — a stale
  error on a field the user has since corrected is its own bug.
- **A server failure is never silently swallowed into a generic "something went
  wrong."** If the server didn't say which field, that is a contract gap — see
  §When Blocked.

## Mirror Real Constraints

- **Encode the server's actual constraints in the schema** — max lengths,
  required combinations, formats — so the user gets immediate feedback instead
  of a round-trip rejection.
- **Confirm the real limit first. Do not guess a threshold.** A guessed max
  length that is wrong in the permissive direction is a server error the user
  sees; wrong in the strict direction, it blocks a legitimate value. Read the
  constraint from the source that owns it.
- **The client validates for UX. The server is the security boundary** and
  re-validates regardless (`security.md` §Validation Is Not the Security
  Boundary). Encoding a constraint client-side is not a control.
- **Validation messages are the project's working language.** Which language
  that is, is a copy decision for the user — not one to assume. Ask if it isn't
  established.

## Not Forms

**Some things are not forms and must not be built as forms**, because the
provider already owns them and a hand-rolled version is strictly worse:

- **Authentication.** Delegate to the provider's hosted flow. Never build a
  username/password form against an identity provider that offers one.
- **Payment.** Delegate to the provider's hosted component. Card data must never
  enter this codebase.
- **Address autocomplete / lookup.** Delegate to the provider's widget.

Building your own version of one of these is a defect, not an implementation
detail.

## Filter & Search Forms

- **A filter form is a form**: same schema discipline, same submit guard.
- **Keep the draft selection in local state; commit on an explicit apply** when
  the backend round-trip is slow (`data-and-state.md` §Search).
- **Text inputs debounce** on the same rule as any other search.
- **Reset pagination and scroll on every filter change** — results belong to
  the current filter.

## When Blocked

- **If a validation rule, limit, or format is not documented anywhere: stop.**
  Confirm it against what the server actually validates, or ask. Do not invent a
  threshold to get the form working.
- **If the form needs a value the backend doesn't accept** — an unsupported
  region, an unavailable option: validate the allowed values against the real
  data rather than hardcoding a guess.
- **If the server returns a failure with no field identifier: report the exact
  payload.** The mapping rule above cannot be implemented without it, and
  guessing produces errors on the wrong inputs.
- Never: relax a schema to let a submission through; disable validation on a
  field "temporarily"; hand-roll a second bridge to the validation library;
  duplicate a shape instead of deriving the type.

## Canonical Example

Once `{{the first form wired end-to-end: schema, derived type, submit guard,
server error mapping}}` exists, treat `{{path/to/that/file}}` as the reference
for every later form.
