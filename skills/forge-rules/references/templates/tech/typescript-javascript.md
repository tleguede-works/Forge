# Overlay · TypeScript / JavaScript

<!--
GENERATOR NOTES — delete this block in the emitted file.

Status: source-audited. Synthesised from two real projects (a Next.js SPA and an
Expo React Native app) plus the generic-type rules of a third. Rows marked
`source:` were present in at least one audited project; rows marked `doc:` come
from framework documentation.

Emit this overlay together with `core/coding-standards.md`. It supplies the
mechanisms; that file supplies the rules. Where the two overlap on a mechanism,
this file wins; where they overlap on a rule, `coding-standards.md` wins.
-->

# TypeScript / JavaScript

## Configuration

- **`strict: true`, non-negotiable.**
  {{source: both audited projects}}
  Turning it off to clear an error is a defect. `noUncheckedIndexedAccess` where
  the project can absorb the friction.
- **`tsconfig` extends the framework's base config** — {{e.g. the framework's
  own `tsconfig.base`}} — rather than re-declaring the framework's compiler
  options. {{doc: Expo's `expo/tsconfig.base` exists for this reason.}}
- **The path alias is configured** — {{e.g. `@/*` → `./src/*`}} — and used for
  every internal import (`architecture.md` §Conventions).

## Types

- **`type` for component and public types, not `interface`.** With a `Props`
  suffix on component parameter types. {{source}}
- **No `any`. No `dynamic` casts as a synonym.** `unknown` plus explicit
  narrowing at the boundary. {{source}}
- **Never `as` to silence a type error.** A cast is an assertion the compiler
  cannot check; when it is wrong, the error surfaces at runtime instead of
  compile time, which is the worst place to find it.
  - **One documented exception, and it must be narrow and commented:** a literal
    the framework's own type generator fails to emit. If you take it, name the
    specific generator limitation, the version it affects, and the command that
    re-verifies it. Never a general escape hatch, and never a cast on a dynamic
    or computed path.
- **`as const` on constant collections** so their literal types survive.
- **Discriminated unions over optional-flag piles** for anything with more than
  two states (`coding-standards.md` §Type Safety).
- **Satisfies over `as` for checking against a type** without widening:
  `{{satisfies Config}}` verifies the shape and keeps the inferred type.

## Deriving Types

- **Types are derived from the runtime source of truth, never written beside
  it.** {{source}}
  ```ts
  // A validation schema is the source of truth:
  export const CreateUserSchema = z.object({ /* ... */ });
  export type CreateUserInput = z.infer<typeof CreateUserSchema>;
  ```
- **API response types come from schemas written against real responses** — a
  schema per entity, in `{{validation module}}`. Never a hand-maintained
  interface that drifts from the wire format.
- **Model/domain types are declared once.** A shape that already exists in
  `{{models module}}` is imported, not re-declared.

## Module Resolution & Interop

<!-- Rows marked `doc:` are the interop failures that reliably cost an afternoon. -->

- **`verbatimModuleSyntax` / `importsNotUsedAsValues`-style correctness:** type-
  only imports are marked as types, so the emitted JavaScript doesn't carry an
  import that only existed for checking. {{doc: `tsc` with
  `verbatimModuleSyntax` errors on a type import that isn't marked, which is the
  point.}}
- **Node built-ins are imported with the `node:` prefix** — `{{node:fs}}`, not
  `{{fs}}`. {{doc: unambiguous, and required by Node's ESM resolver for some
  built-ins.}}
- **Path extensions in emitted relative imports, when the runtime requires
  them** — {{e.g. ESM Node requires the `.js` extension in relative specifiers
  even from TypeScript source.}}. {{doc: the TypeScript handbook's ESM section;
  this is the single most common "works in dev, fails in the build" ESM failure.}}
- **A directory import is not a module.** Import the file, or a real barrel —
  not the folder.

## Dependencies

- **Use the framework's installer for its ecosystem's packages** and the
  package manager's own for the rest. Never a raw install of a
  framework-coupled package. {{source}}
- **Never hand-edit the manifest to pin a version.** Never `latest`. Never delete
  the lockfile to resolve a conflict — resolve the constraint.
- **The lockfile is the project's package manager's, and only that one's.** A
  second lockfile means two dependency trees.

## Runtime Boundaries

- **A module has exactly one reason to be a server module and one reason to be a
  client module, and the framework's own file convention or directive expresses
  it.** Don't infer it.
- **Environment access goes through the platform's mechanism**, never through a
  bare global read. {{e.g. the framework's typed env accessor, reading a
  validated config module.}}

## Test Environment

<!-- The rows that cost the most time when unknown. -->

- **A test runner configured for an ESM project may need its own config file in
  CommonJS** even when the project is ESM, depending on the runner's preset.
  {{doc: a `"type": "module"` manifest plus a framework-provided test preset can
  require the runner's own config to stay CJS, because the runner loads the
  config before the project's module type is in effect.}}
- **A DOM-based component test environment may need explicit polyfills** for
  browser APIs the framework's components touch — {{e.g. `ResizeObserver`,
  `IntersectionObserver`, `matchMedia`}} — or those components silently fail to
  render in tests. {{doc: documented in the test-environment's own setup guides;
  the symptom is an overlay that never appears and a test that passes for the
  wrong reason.}}
- **Confirm the runner, not the default.** The project may have configured a
  different one (`testing.md`).

## Banned Patterns

| Banned | Use instead | Enforced by |
|---|---|---|
| `any` | `unknown` + a type guard | `{{lint rule}}` |
| `as` to silence a type error | fix the type, or escalate | review |
| `// @ts-ignore`, `// @ts-expect-error` added to land a commit | fix the type | review |
| `enum` | a `const` object with a derived union type, or a string-literal union | `{{lint rule}}` |
| `namespace` | modules | `{{lint rule}}` |
| default exports for modules with more than one export | named exports | `{{lint rule}}` |
| a barrel that re-exports a whole feature's internals | import the specific module | review |
