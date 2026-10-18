# Template · Security

<!--
GENERATOR NOTES — delete this block in the emitted file.

Security rules, in the shape that survived consolidation across three very
different projects (a Dart/Flutter app, a TypeScript/Next SPA, and a
TypeScript/React Native app). The rules themselves were already agreed across
those projects; what differed was the mechanism, and the mechanism is the tech
overlay's job.

Ordering of this file is deliberate: scoping, then storage, then the boundary
rule, then authorization, then minimisation, then logging. The boundary rule
("client validation is UX, not the security boundary") sits in the middle
because it is the one that is most often forgotten precisely because it sounds
like it is about UX.
-->

# Security Rules

## Definition of Done

A security-relevant change is complete when **ALL** of:

1. No secret, credential, or private key is referenced anywhere that reaches
   the {{client / bundle / device image}} — only the designated public
   variables get there, and that is by construction, not by discipline.
2. All input crossing a trust boundary is validated at that boundary.
3. No sensitive value — tokens, credentials, personal data beyond what the
   screen displays — is logged, and none of it can survive into production logs.
4. {{e.g. token/session teardown leaves no cached user data behind.}}

## Secret Scoping

- **Only the designated public variable prefix is client-readable**
  ({{e.g. `NEXT_PUBLIC_*` / `EXPO_PUBLIC_*` / `--dart-define`}}). **Everything
  else is server-only by construction** — not by convention.
- If a genuinely server-only secret appears to be needed by client-side code,
  **that is a signal something is architected wrong**, not a naming problem.
- {{e.g. in a client-only project, a server-only secret has no legitimate use
  here at all. Its presence means a boundary is missing.}}
- **Mock and sample credentials must be obviously fake** and must not resemble
  real ones.

## Environment Files

- **Never commit a `.env` file with real values.** It is gitignored.
- Ship a **`.env.example` with placeholder values** so the required keys are
  discoverable without the real values.
- **Read configuration once, in one place, and fail loudly at startup if a
  required value is missing.** Do not ship a dead client that fails at first
  use.
- Never: rename a variable to a public prefix to make it "work" — that ships
  the secret to every install or browser.

## Token Handling

- **One place owns tokens.** Storage, refresh, and expiry logic live in a single
  {{auth client / interceptor / session module}}. No feature reimplements it, and
  no feature reads the secure store directly.
- **Tokens are stored in the platform's secure storage** — {{e.g. keychain /
  keystore-backed store}} — never in general-purpose async storage, never in
  memory only (the session must survive a restart), never in a cache key, never
  in a route parameter or URL.
- **Check expiry before a critical authenticated call**, and treat an expired
  token as a missing one.
- **Refresh is single-flight.** One in-flight refresh; everything else awaits
  it. Two parallel refreshes against the same credential is a correctness bug,
  not an optimisation.
- {{e.g. a public client receives no refresh token — renewal is a silent
  re-authentication, and `login_required` means route to the hosted login, never
  a workaround.}}
- {{e.g. never build a credential-entry form when the identity provider owns
  one — delegate to the hosted login.}}

## Session Teardown

- **Logout is complete or it is not logout.** In order: revoke/end the session
  at the provider, delete stored tokens, clear the user/session data from every
  cache, then let the auth guard take effect. **Logout must never leave user
  data readable in a cache.**
- {{e.g. flush a session on tab close only on a genuine close — guard the
  handler against firing on ordinary internal navigation, or it logs the user
  out on every page transition.}}
- {{e.g. offer a "clear local data" action where personal data is cached, and
  make sign-out clear it.}}

## Validation Is Not the Security Boundary

**Client-side validation is UX. It protects the user from a bad experience; it
protects nothing else.** The server validates independently, always. Assume it
re-validates every field regardless of what the client checked.

- Validate at the boundary where untrusted input enters — {{e.g. a request DTO
  validated by the framework's validation pipe before the handler runs}}. A
  boundary with no validation is an open door.
- **Never build a query, a path, or a filter by concatenating user input.** Use
  typed parameters or a parameterised query.
- **Constrain the request, not just the payload.** {{e.g. rate limiting and
  authorisation are server responsibilities; a client-side delay is a UX nicety,
  not a control.}}

## Authorization

- **Protected surfaces go through one reusable guard** — {{e.g. a
  `RequirePermission` wrapper, a route guard, a security config}} — not an
  ad-hoc role check scattered through the screens.
- **A hidden UI element is not an authorization control.** The check happens
  where the data is fetched, on the server side of the boundary.
- **Deny by default.** A surface with no guard configured is closed, not open.
- {{e.g. checkout before sign-in, address editing, and order history are each
  gated by the centralised guard — never by a per-screen `if (user)`.}}

## Data Minimization

Two directions, both required:

- **Over-fetching:** request only what the screen displays. No
  `{{SELECT *}}`-style fetch for a title thumbnail. Carry the fields actually
  used across boundaries — {{e.g. a three-field view of a user, not the whole
  entity threaded through state}}.
- **Over-persisting:** do not store personal data locally without a purpose and
  a way to erase it. Mock and sample data must not resemble real identifiable
  data.
- {{e.g. store/platform data-safety declarations must match what the app
  actually collects — update them when capabilities change, don't wait for the
  review.}}

## Logging

- **Never log** tokens, credentials, authorisation codes, session or
  nonces/verifiers, reset codes, or full personal data — not to the console, not
  to a dev-only channel, not to an analytics sink.
- **Logging normalised error codes is fine.** Keep the diagnostic value; drop the
  payload.
- Never echo a credential, code, or state parameter in debug output "just to
  check the flow".

## Response Hardening

<!-- Only where the stack owns response headers. Delete this section otherwise
     rather than emitting a rule the project cannot act on. -->

- **Content-Security-Policy** configured in {{config file}}: at minimum
  `default-src 'self'`, `connect-src` limited to the actual origins the app
  talks to, and a restricted `script-src`.
- **Never disable a security header or a transport security setting to work
  around a one-off problem.** Fix the cause.

## Banned

- Any non-public credential in client code or committed configuration.
- Secure-storage APIs used outside the single auth/session module.
- `{{Payment card data, CVV, or equivalent}}` anywhere in the codebase.
- Logging credentials or personal data; committing a populated `.env`.
- Building a query, filter, or path from user input.
- Disabling a security control to ship faster.

## When Blocked

- **If client-side code seems to require a server-side secret: stop.** This is
  the case for a new decision, not a config tweak. Do not rename the variable to
  make it work.
- **If the secure store fails on a device or platform: report the exact error.**
  Do not fall back to a less-safe mechanism "temporarily" — that is the failure
  the rule exists to prevent.
- **If a permission model is unclear: ask.** Guessing a permission boundary
  produces a hole that is expensive to find later.
- Never: ship a secret to make a feature work; skip validation because the input
  "comes from our own form"; treat a client-side check as a control.

## Canonical Example

Once `{{the single auth/session module}}` exists, treat
`{{path/to/that/file}}` as the reference for token handling and session
teardown — reference it, don't reimplement that logic in a feature.
