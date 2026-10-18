# Template · Code Style & Type Discipline

<!--
GENERATOR NOTES — delete this block in the emitted file.

Code style, and nothing else. Three rules govern what goes in this file:

  1. **Style goes last in every file's ordering and is the first thing cut.**
     An agent needs commands and a definition of done before formatting matters.
  2. **Every style rule is paired with the command that verifies it.** An
     unverifiable style preference is a suggestion, and will be treated as one.
  3. **The banned-patterns list is NOT in this file — the technology overlay owns
     it.** An earlier version of this template carried an empty table here,
     marked "emit this empty, rows come from the overlay", which contradicted the
     rule that an empty section is worse than no section, and duplicated the
     overlay's real list when filled. The overlay knows the framework's
     deprecated APIs; this file knows the discipline those lists must follow.

This file is the canonical home for naming, typing, magic values, in-file
organisation, and the dependency discipline. The file-size rule is NOT here —
it is in `architecture.md`. The banned-patterns list is NOT here — it is in
`tech/<stack>.md`.
-->

# Code Style & Type Discipline

## Commands

- Typecheck: `{{...}}`
- Lint / format: `{{...}}`
- Format check (must not modify): `{{...}}`

## Type Safety

- **Strict mode is on and non-negotiable** — `{{tsconfig / compiler flag}}`.
  Turning it off to make an error go away is a defect, not a fix.
- **No `{{any}}` / `{{dynamic}}`** anywhere — not in library code, not in
  screens, not in a test. When a value's type is genuinely unclear, use
  `{{unknown}}` and **narrow explicitly at the boundary** (a type guard, or a
  validation schema). Never silently widen.
- **Never suppress a type error to unblock a commit** —
  `{{@ts-ignore}}` / `{{@ts-expect-error}}` / `{{suppress}}` must not be added to
  make a build pass. Fix the type or escalate.
- **Components and public functions take a typed parameter object**, named with
  a `{{Props}}` suffix, declared as a `{{type}}` alias. No inline anonymous
  parameter types.
- **Async state is one discriminated union, not a pile of flags.** No
  `{{isLoading && !isError && data}}` boolean soup in the outer layers.

  ```{{lang}}
  type {{AsyncState}}<T> =
    | { status: "idle" }
    | { status: "loading" }
    | { status: "success"; data: T }
    | { status: "error"; error: {{AppError}} }
  ```

  {{If a query/cache library exposes its own status flags: those are fine inside
  the hook that owns the query. Map to {{AsyncState}} at the hook boundary when
  the outer layer wants one shape everywhere.}}

- **The one error type that crosses into UI code is the normalized one**
  (`errors-and-loading-states.md` §Normalized Error Type). A raw error from a
  third-party client never reaches a component.

## Naming

Every row says what it is *for*, because "be consistent" is not a rule — the
reason is what makes an agent apply it to a new case correctly.

| Thing | Convention | Example | Why |
|---|---|---|---|
| Component / file | `{{kebab-case}}` | `{{product-card.tsx}}` | one file, one component |
| Component type | `{{PascalCase}}` + `{{Props}}` | `{{ProductCardProps}}` | greppable, unambiguous at the call site |
| Hook | `use` + `{{camelCase}}` | `{{useProduct}}` | the framework finds hooks by prefix |
| Event handler | `handle` + `{{PascalCase}}` | `{{handleSubmit}}` | separates handlers from values at a glance |
| Constant / option array | `{{UPPER_SNAKE_CASE}}` | `{{STATUS_OPTIONS}}` | a constant is distinguishable from a variable |
| Constant object | `{{camelCase}}` | `{{tableColumns}}` | objects are values, not collections |
| Model / domain type | `{{PascalCase}}` | `{{Product}}` | — |
| {{Normalizer}} | `{{normalize}}` + Model | `{{normalizeProduct}}` | one function per model, greppable from the model name |
| {{String key}} | dot-namespaced | `{{cart.lineCount}}` | greppable, translatable, no collision |
| {{Route/URL}} | {{in the central routes module}} | `{{PATHS.cart.detail(id)}}` | see `architecture.md` §Conventions |

## Magic Values

**If a value is compared against or branched on more than once, it is a named
constant, not a repeated literal.**

- No bare `{{'cart'}}` in a cache key, no bare `{{'€'}}` in a component, no bare
  URL, no repeated status code, no magic threshold or retry count.
- Name it near its point of use, or in the designated constants module when more
  than one feature needs it.
- **Routes are the one case with a dedicated rule** (`architecture.md`
  §Conventions — one central definition). Everything else follows this general
  rule and does not need a special case of its own.
- **Additions to a centralized module are made there first.** An inline literal
  is a violation even when the module doesn't have the value yet.
- {{e.g. user-facing strings are keys, not phrases; money goes through the one
  formatter.}}

## Dependencies

- **Pin to a real version resolved by the ecosystem's installer.** Never
  `{{latest}}`, never unpinned, never a range wider than the project uses
  elsewhere.
- **Never hand-edit `{{manifest}}` to add, remove, or pin a dependency.** Use
  the framework's own installer — {{e.g. `{{npx expo install <pkg>}}` for SDK
  packages, `{{flutter pub add <pkg>}}` for Dart, `{{mvn add-dependency}}`}} —
  so the manifest and the lockfile stay consistent. The narrow exception is
  non-dependency metadata (assets, scripts, metadata) and it must stay minimal
  and justified.
- **Never delete the lockfile to resolve a dependency conflict.** Resolve the
  constraint.
- **Don't add a package "for comfort".** Justify it, or use what the project
  already has.
- **One library per concern.** A second icon set, date library, HTTP client, or
  state library introduced ad hoc is a defect — pick the one the project
  standardised on.
- {{e.g. run the ecosystem's dependency doctor before declaring a dependency
  problem solved.}}

## Banned Patterns

**The banned-patterns list lives in `tech/<stack>.md`, not here.** The overlay
knows the framework's deprecated and discouraged APIs; a generic list would be
wrong in every project it landed in, and a list maintained in two places is a
list that is wrong in one of them.

What this file owns is the **discipline** every such list must follow:

- **Every ban names its replacement.** "Never `X`" without "use `Y`" is a
  prohibition the agent can only obey by not doing the task.
- **Every ban names what enforces it** — a lint rule, a grep, or "review". A ban
  with no enforcement column is a preference, and will be treated as one.
- **A ban is a decision, and a closed one.** Deviating is
  `AGENTS.md` §Escalation Rules, not a per-file judgement call. If the project
  genuinely needs to deviate, that is a the decisions log entry and the ban is
  amended there.
- **A ban that is not enforced is not a ban.** If nothing checks it, it is
  documentation — and documentation in a rules file is the thing this whole
  system exists to avoid.

## File Organisation

Within a file, in this order:

1. File-level doc comment
2. Imports, sorted by the project's configured order
3. Top-level constants
4. Types and classes, {{alphabetical within the section}}
5. Top-level functions, {{alphabetical}}

- **Co-locate tests** with the code they test — `{{name.spec}}` next to
  `{{name}}`.
- **One concern per file**, judged by the responsibility test in
  `architecture.md`, not by line count.

## Style

<!-- Only rules with a verification command. If you cannot attach a command to a
     style rule, either find the lint rule that enforces it or cut the rule. -->

- `{{rule}}` — verified by `{{lint rule id or command}}`
- `{{rule}}` — verified by `{{...}}`
- {{e.g. no `{{debug print}}` in source — verified by `{{grep}}`; see also
  `workflow.md` §Code Hygiene.}}

## When Blocked

- If a type error is real but the fix touches a closed decision (a shared model
  shape, a public API): **stop** — check the decisions log before changing shared
  shapes.
- If a required value's type is unclear at an import boundary: type it
  `{{unknown}}` and narrow explicitly. Do not reach for `{{any}}` to make the
  error disappear.
- Never: suppress a type error to land a commit; widen a type to silence the
  compiler; disable a lint rule project-wide to accommodate one file.
