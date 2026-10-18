# Variant · Next.js Pages Router

<!--
GENERATOR NOTES — delete this block in the emitted file.

**This is a delta, not a replacement.** It states which files change relative to
`tech/nextjs.md` and how. It does not restate them. Applying it means: emit
`nextjs.md`, then apply the changes below to the named files.

Status: source-audited. Synthesised from the delta in the retired Next.js
profile; re-based onto the current overlay structure.

Two variant files can apply at once — Pages Router + a different UI library, for
example. There is no combined file, and writing one is the combinatorial
explosion this structure exists to prevent.
-->

# Applying Pages Router

Apply on top of `nextjs.md` when the project uses the Pages Router rather than
the App Router. **Confirm against the project's actual router before
generating** — a project with both directories is a migration, and that is a
decision (the decisions log), not a variant.

## Files that change

| In `nextjs.md` | Pages Router instead |
|---|---|
| Routes are files under `{{app dir}}` with `page`/`layout` file names | Routes are files under `{{pages dir}}` named by path, with `{{_app}}` and `{{_document}}` at the root |
| Nested layouts compose down the tree | One `_app` component wraps the tree; there is no per-segment layout composition |
| `{{loading}}` file name | No per-route loading file. A loading state is a component or a framework the project has adopted |
| `{{error}}` file name, client component with a fixed signature | No per-route error file. Error handling is a class boundary at the app level, or a page-level `getServerSideProps` branch |
| `{{not-found}}` file name | No per-route not-found file. A 404 is the `{{404}}` page, or a route-level redirect |
| `{{route}}` file name for a handler | `{{pages/api/**}}` for handlers |
| Server Components are the default | **There are no Server Components.** Every component is client-rendered; data fetching is in `{{getServerSideProps}}` / `{{getStaticProps}}` / `{{getStaticPaths}}` |
| `{{"use client"}}` directive | Does not exist and is not needed — remove the row from `nextjs.md` rather than leaving a rule about a directive the project cannot use |
| A data-fetching decision in the decisions log about server components | The decision is about the data-fetching functions instead. Rewrite it, don't delete it — the reasoning carries over |
| `{{metadata}}` export | A `{{Head}}` component per page, or the project's metadata approach |

## Rules that change

- **`{{getServerSideProps}}` / `{{getStaticProps}}` / `{{getStaticPaths}}` are
  the only server-side data entry points.** A rule in `nextjs.md` about a
  Server Component not fetching data is vacuous here — replace it with the
  equivalent rule about these functions, or drop it.
- **Anything serialisable from these functions to the component is a
  de facto API contract.** Changing a returned shape is a breaking change for
  anything else consuming it. This is the Pages Router equivalent of the DTO
  rule, and it is the main reason a project migrates off this router.
- **A page is a component with a data-fetching function attached.** The
  thin-page rule still holds; the data function replaces the Server Component's
  role.
- **Client-side navigation between pages still goes through the router**, and
  path strings still come from the one routes module (`architecture.md`
  §Conventions).

## Rules that survive unchanged

Everything in `nextjs.md` that is not in the table above: the single HTTP client,
validation at the boundary, the recovery surfaces (expressed through this
router's own mechanisms), images/fonts/scripts, the `min-w-0` footgun, the
configuration file, and the recovery-surface *rule* — "every reachable failure
has a recovery surface" — regardless of which file name expresses it.

## What this variant must not do

**Do not carry a rule about a mechanism this project doesn't have.** A row in
`nextjs.md` about `{{"use client"}}` or a per-route `{{error}}` file is dead
weight in a Pages Router project and, worse, invites an agent to go looking for
the mechanism. Removing the row is the point of applying a variant.
