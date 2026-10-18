# Overlay · Next.js

<!--
GENERATOR NOTES — delete this block in the emitted file.

Status: source-audited (one audited project, App Router + Redux Toolkit + axios,
client-side data fetching). The rendering-strategy rows assume that project's
closed decision and are marked accordingly — for a project that chose
SSR/RSC-first data fetching, apply `variants/ssr-hybrid.md` and reconcile
§Data Fetching before emitting.

Emit alongside `react.md` (the general React rows) and, when the project has
chosen a router other than App Router, `variants/pages-router.md`.

**Provenance.** The rendering and file-convention rows come from the audited
project named above. The Named Footguns are the highest-drift content in this
overlay — each is a real behaviour of a specific framework version, and each has
bitten a session that assumed otherwise. Re-verify every one against the
installed version before emitting. When this overlay is applied, the emitted file
carries a `source:` marker on any rule the project re-derived
(`documentation-sources.md`).
-->

# Next.js

## Routing

- **App Router** unless `variants/pages-router.md` is applied. Routes are files
  under `{{routes dir}}`; layouts compose and nest; a route is not a string
  assembled at a call site (`architecture.md` §Conventions).
- **The file name is the behaviour** — `{{page}}`, `{{layout}}`,
  `{{loading}}`, `{{error}}`, `{{not-found}}`, `{{route}}`, `{{default}}`. Adding
  one changes what the router does; that is the point, and it is why an
  unfamiliar convention must be checked against the versioned docs rather than
  assumed.
- **All route paths come from one module** and are consumed from there. Dynamic
  paths are functions in that module, not concatenation at a call site.
- **Breadcrumbs, redirects, and navigation consume the same constants** as
  everything else. No `href="#"`, no ad-hoc redirect string.
- **Choosing dynamic segment vs query parameter for the same kind of view is a
  project decision — and then it is consistent.** Don't use one pattern for a
  detail page and the other for a filter.
- **A server-only file cannot be imported by a client component**, and the error
  is a module-resolution failure that names a secret-adjacent file. If a client
  component needs a value, that value has to be a prop or a public config value.

## Server / Client Boundary

- **A component is a Server Component by default.** Add
  `{{"use client"}}` only when it genuinely needs one of: browser APIs, React
  hooks, event handlers, or a client-only library.
- **Push the boundary down.** Every component above a client boundary becomes a
  client component. A boundary at the layout level makes the whole subtree ship
  JavaScript.
- **Serialisable props only across the boundary** — no functions, no class
  instances, no `Date`/`Map`/`Set` passed as-is where the framework's serialiser
  doesn't handle them.
- **A Server Component is not a data-fetching component** in the default
  variant. If the project's closed decision is client-side fetching, a server
  component that fetches is the decision being reversed silently. Check
  the decisions log.

## Data Fetching

> **{{Default variant: client-side data fetching through one configured HTTP
> client; the backend is not called from Server Components. This is a closed
> decision in this project — see the decisions log. Applying
> `variants/ssr-hybrid.md` reverses it and requires a new decision.}}**

- **One configured HTTP client instance**, in one module, with the auth
  interceptor and error normalisation attached (`data-and-state.md`
  §The Single Client).
- **Never a raw `fetch` where the configured client applies, and never a second
  client instance.** A second instance silently loses the interceptors.
- **The project's data-fetching constraints are in the decisions log**, not
  re-derived per feature. {{e.g. whether a route handler or a server action is
  permitted at all, and why.}}
- **Cross-route data belongs to the data layer**, not to a component's effect
  (`data-and-state.md` §The Mandatory Access Shape).
- **Page-local, non-shared data** can be fetched in a client component's effect
  — still through the configured client, still typed, still with its states.
- **A build catches boundary errors that lint and typecheck miss.** It is part of
  the verification order for that reason.

## Recovery Surfaces

- **An `{{error}}` boundary per route segment** where a distinct recovery
  message is genuinely useful. It is a client component and receives the
  framework's error and reset callback shape — don't change that signature.
- **Rely on an inherited boundary when the handling genuinely applies.** Three
  identical boilerplate boundary files is duplication that will drift.
- **A `{{not-found}}` surface for any route that resolves a dynamic identifier
  against data that can be absent.** A missing id is a not-found state, not a
  crash and not a blank screen.
- **A `{{loading}}` surface where the wait is long enough to warrant one** — not
  for content that arrives immediately. A loading boundary on a fast route adds
  a flash, which is worse than nothing.

## Images, Fonts, Scripts

- **The framework's image component for every image**, never a raw `{{img}}`.
  It handles sizing, lazy loading, and format negotiation.
- **The framework's font loader**, never a manually linked web-font link. It
  self-hosts, subsets, and preloads.
- **The framework's script component for third-party scripts**, with an
  appropriate loading strategy — not a raw script tag in the body.
- **A heavy, client-only dependency is dynamically imported** with server
  rendering disabled, when it genuinely cannot render without a browser
  (`performance.md` §Code Splitting).
- **Never disable image optimisation to work around a one-off sizing problem.**
  Fix the sizing.
- **Always specify image dimensions or a fill container with an aspect ratio**,
  so the layout doesn't shift when the image loads.

## Configuration

- **Response headers, including the CSP, are configured in
  `{{config file}}`** (`security.md` §Response Hardening) — not in middleware
  scattered through the app, and not at a CDN only.
- **The router's own configuration is the only place** for base path, rewrites,
  redirects, and image domains. A rewrite duplicated in three places resolves
  once and diverges twice.

## Named Footguns

- **A flex child without an explicit `min-w-0` can refuse to shrink below its
  content's natural width.** The symptom is content overflowing its container —
  a wide table breaking horizontal scroll, a long unbroken string pushing a
  sidebar open — with no error and no obvious cause. **If content overflows its
  container unexpectedly, check this first.**
- **`"type": "module"` plus a framework-provided test preset can require the test
  runner's own config file to stay CommonJS**, even when the rest of the project
  is ESM. See `typescript-javascript.md` §Test Environment.
- **A component that reads a request-scoped value cannot be statically
  generated.** It silently opts the route out of static rendering, and the
  symptom is a build that succeeds and a page that is slower than expected.
- **A `{{metadata}}` export only applies to the segment that declares it**, and
  a nested segment's metadata replaces rather than merges in some fields. A
  title that looks right on one route and wrong on a child is often this.
- **`useSearchParams` opts a component out of static rendering.** Wrapping a
  component that only reads search params in a client boundary is the fix, not
  removing the read.

## Banned Patterns

| Banned | Use instead | Enforced by |
|---|---|---|
| a raw `{{img}}` | the framework's image component | `{{lint rule}}` / review |
| a manually linked web font | the framework's font loader | review |
| a raw `{{fetch}}` where the configured client applies | the shared client | `{{lint rule}}` |
| a second configured HTTP client instance | the single client | review |
| `{{"use client"}}` at a layout or page root when only a subtree needs it | push the boundary down | review |
| a data-fetching mechanism this project has closed off | the one in the decisions log | `AGENTS.md` §Escalation Rules |
| an unoptimised-image escape hatch | fixed sizing | review |
