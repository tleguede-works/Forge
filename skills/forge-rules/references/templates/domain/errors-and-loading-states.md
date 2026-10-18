# Template · Error Handling & Async States

<!--
GENERATOR NOTES — delete this block in the emitted file.

Owns: the normalized error type, the four states every data flow must have, the
recovery surfaces, and the stop-and-report rule.

The "stop and report" rule appeared roughly fifteen times across the three
source projects — in eight of eleven files in one of them. Every instance was a
specialisation of the same rule, stated locally because no file owned it. It is
owned here, once, in its fullest form, in §When Blocked.

This file also owns the promise that an error is never swallowed, which is the
single rule that most reliably separates a codebase that reports agent bugs from
one that hides them.
-->

# Error Handling & Async States

## Definition of Done

An error-handling change is complete when **ALL** of:

1. Every data flow has visible **loading**, **error**, and **empty** states, and
   none of them is an indefinite spinner.
2. Errors are normalized **before** they reach UI code.
3. Every reachable failure has a recovery surface — a message the user can act
   on, and a retry where retrying can help.
4. No error is swallowed: no empty `catch`, no "logged but the UI shows nothing".
5. {{e.g. the error's log line carries a code, not a payload.}}

## The Normalized Error Type

- **One error type crosses into UI code.** It is produced in one place, at the
  boundary where the raw response or third-party error is received.
- **A raw `Error` from a client, framework, or driver never reaches a
  component.** Normalize at the boundary; the outer layers only ever see the
  project's own type.
- The type is **discriminated by kind**, so the UI can branch without string
  matching:

  ```{{lang}}
  type {{AppError}} =
    | { kind: "network" }                                  // no response — retryable
    | { kind: "{{domain}}"; code: string; message: string; field?: string }
    | { kind: "validation"; fields: Record<string, string> }
    | { kind: "unauthorized" }
    | { kind: "notFound" }
    | { kind: "unknown"; cause: unknown }
  ```

  {{Adjust the variants to the failure kinds this project actually has. Do not
  keep a variant you never produce; do not omit one you do.}}

- **The normalization function is the only place that reads a raw error's
  shape.** If two call sites branch on the raw error differently, the
  normalization is incomplete.
- {{e.g. every failure kind maps to a machine-readable code, so the UI can pick
  a message without inspecting the message text.}}

## The Four States

**Every data flow has all of these. "Success" is not the only one implemented.**

1. **Loading** — a skeleton or indicator that **matches the shape of the content
   it replaces**. A random spinner where a list of rows will appear is a layout
   jump, not a loading state.
2. **Error** — a message the user can read, plus a retry action wired to the
   actual refetch. Not a raw error string.
3. **Empty** — a distinct state from both loading and error, with an icon, a
   message, and an action where one applies. **An empty result is not a success
   screen showing nothing**, and it is never the previous results left on screen.
4. **Success** — the data, which may itself be an empty collection (see 3).

- **Use shared state components.** Do not hand-write the three-way branch in
  every screen — one `{{LoadingState}}` / `{{ErrorState}}` / `{{EmptyState}}`
  set, wired once.
- **Pull-to-refresh on every scrollable list that reads server data.**
- **No state that looks identical to loading when the request failed.** A failed
  request must be visibly different from a pending one, always.

## Never Swallow

- **No empty `catch` block.** Not ever, not as a placeholder, not "the error is
  handled elsewhere" when it isn't.
- **No "logged but the UI shows nothing."** If a failure is invisible to the
  user, it did not happen as far as they are concerned and will be reported as
  "it just doesn't work".
- **No swallowing to make a flow pass.** `{{retry: 0}}` plus a fake empty state
  to ship faster is a bug wearing a UI.
- **No `catch` that logs and rethrows nothing** — either handle it, or let it
  propagate to a boundary that does.
- If a failure genuinely cannot be surfaced, it needs a comment saying why, and
  it still needs to reach a log.

## Mutation Feedback

- **The pending indicator goes on the control that triggered the action** — the
  submit button, the row's action — **never replacing the whole screen or the
  form body with a loader.** A form that becomes a spinner mid-save destroys the
  user's input context.
- **Disable the control while the mutation is in flight** — this is the
  double-submit guard.
- **The failure appears inline, next to the form or the control**, not as a
  screen-replacing error.
- **Field-level failures map back onto their field**
  (`forms.md` §Server Errors). A submit that fails must say which field and why.

## Retry Policy

- **Retry only what retrying can fix.** A network failure or a rate limit is
  retryable; a validation failure is not, and retrying it is noise.
- **A rate limit surfaces as "try again shortly".** Never auto-retry in a tight
  loop — it deepens the rate limit and burns the user's battery.
- **Exponential backoff with a cap** for anything automatic.
- **Don't disable caching or retries to fix a one-off.** That is a correctness
  change made for a cosmetic reason.
- {{e.g. an external system's own retry semantics — read them before assuming
  a retry is safe. A non-idempotent operation retried on timeout is a duplicate
  write.}}

## Recovery Surfaces

- **A recovery surface per failure kind**, at the level where the failure
  happens: {{route/screen/component-level error boundary, not-found state,
  loading state}}.
- **Rely on an inherited boundary when the handling genuinely applies.** Don't
  duplicate identical boilerplate at every level — duplication is how they drift.
- **A not-found state for any dynamic identifier that might not resolve.** An
  invalid or unknown id renders the empty state, not a crash and not a blank
  screen.
- **A render-time boundary is the only place a raw render error may surface.**
  Recoverable UI beats a blank screen.
- **A loading boundary only where the wait is genuinely long enough to warrant
  one** — not for content that arrives immediately.

## User-Facing Messages

- **Messages are looked up by error kind**, from the project's string module —
  never the raw `error.message` from the backend or the third party. That string
  is in another language, is addressed to a developer, and is sometimes empty.
- **Never show a stack trace, an internal error code the user can't act on, or
  backend internals.**
- **Keep the technical detail for diagnostics** — the code, the original
  message — but keep it out of the UI and out of anything that could carry
  personal data (`security.md` §Logging).
- Messages live in the string module so they are translatable — see
  `{{i18n}}` when that template is emitted.

## When Blocked

> **If the failure is not one you recognise — an unexpected shape, a code that
> isn't in the known list, a status where you expected another: stop. Capture
> the exact response (body and status), report it against the shape you
> expected, and confirm the real behaviour before extending the normalizer.
> Do not invent a workaround, and do not add a guess-based handler.**

- Once confirmed, the behaviour belongs in `{{external-system-contracts}}` if it
  is specific to an external system, or in this file if it is general.
- **If a validation rule, limit, or constraint is undocumented: stop.** Confirm
  it against the real source, then encode it. Never invent a threshold to get
  unblocked.
- **If the secure or persistent store fails: report the exact error.** Do not
  fall back to a less-safe mechanism "temporarily".
- Never: add a catch-all that returns a generic message and hides the shape;
  guess a field mapping; disable an error path to make a test pass; retry a
  non-idempotent operation automatically.

## Canonical Example

Once `{{the first feature with complete loading/error/empty/success}}` exists,
treat `{{path/to/that/file}}` and the shared state components as the reference
for this pattern.
