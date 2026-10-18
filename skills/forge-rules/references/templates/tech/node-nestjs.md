# Overlay · Node.js / NestJS

<!--
GENERATOR NOTES — delete this block in the emitted file.

**Status: documentation-sourced, never applied end-to-end.** No audited project
exists for this stack. Every rule below is traceable to a rung of
`documentation-sources.md` and carries its `source:` marker. Treat it as
well-grounded but unvalidated by use: when this overlay is applied to a real
project for the first time, log what turned out to be wrong, and fix the file
here — the file is what the next project copies.

The framework facts come from `/nestjs/docs.nestjs.com` (v11/v12 documentation).
**Verify version-specific claims against the documentation for the installed
major version** before treating them as current — the same discipline
`react-native-expo.md` §Verify applies to Expo.

The rules that are *not* framework-specific — layering, normalization at the
boundary, authorization in one place, never greenwashing a test — already live
in `core/` and `domain/`. This file supplies the NestJS mechanisms.
-->

# Node.js / NestJS

> **Framework facts below are from the official documentation. Where a rule
> depends on a mechanism that could change between majors, it says so and gives
> the check.**

## Modules & Dependency Injection

- **A provider is declared with `@Injectable()` and registered in its module's
  `providers` array.** {{source: official DI documentation — a class is
  instantiated by Nest only if it is both decorated and registered.}}
- **Dependencies are injected through the constructor.** {{source: official DI
  documentation. This is what makes a provider's dependencies visible at a
  glance and what makes it testable by supplying a different instance.}}
- **A provider is visible only inside its own module unless it is exported.**
  Cross-module use requires `exports` in the host module and `imports` in the
  consuming module. {{source: official module documentation — "providers defined
  in a module are visible to other members of the module without being
  exported."}}
- **Default scope is singleton.** A per-request or transient scope is an
  explicit declaration, and it has a real cost: request-scoped providers force
  the request path to bubble up, and a request-scoped provider that depends on a
  singleton propagates that upward. {{source: official provider-scope
  documentation.}}
- **Feature modules own their feature.** A controller, its service, and its
  persistence live in one module. A "services" module holding every service in
  the application is not a module boundary.
- **A module that provides a capability others consume is a separate module**,
  imported rather than re-declared.
- **No circular module imports.** Two modules that need each other have a
  missing third concept, not a dependency cycle.

## Layering

```
{{controller}}  →  {{service}}  →  {{repository / ORM}}
      ↑                ↑                ↑
   HTTP concerns   business logic    persistence only
```

- **A controller does HTTP and nothing else**: routing, extracting and validating
  the request, calling one service, shaping the response. **No business logic, no
  persistence access, no orchestration of several services** — that is a service.
- **A service owns the business logic and the transaction boundary.** It is the
  only layer that coordinates more than one repository.
- **A repository does persistence and nothing else.** No business rules, no HTTP
  concepts.
- **Entities are not the response shape.** Return a DTO from the service layer,
  so a schema change doesn't silently become an API change and internal fields
  don't leak.

## Validation — the boundary

- **`ValidationPipe` is bound globally** in the bootstrap function, so every
  route is protected rather than remembering to add it per handler.
  {{source: official validation documentation — `app.useGlobalPipes(new
  ValidationPipe())` in `bootstrap()`.}}
- **A DTO is a concrete class, never an interface and never a generic.**
  {{source: official validation documentation, verbatim intent: "ensure DTOs use
  concrete classes rather than interfaces or generics so runtime metadata is
  preserved." **This is the single most consequential row in this file** — a
  DTO declared as an interface compiles, passes no validation, and produces a
  runtime failure with no type-level warning.}}
- **Validation transforms the plain payload into a typed class instance** before
  the handler runs, using the framework's transform facility alongside the
  validator. {{source: official pipes documentation — `plainToInstance` plus
  `validate`, throwing `BadRequestException` on failure.}}
- **The whitelist/forbid behaviour is configured, not defaulted.** An
  unrecognised property must be rejected or explicitly allowed — a payload
  carrying unexpected fields that are silently dropped is a validation gap.
  {{source: official validation options.}}
- **DTO properties are declared with validation decorators and nothing else.**
  A property with no validation decorator is not validated; if it should be,
  declare the constraint; if it shouldn't be in the DTO, remove it.

## Errors

- **`@Catch(...)` filters, registered globally via `useGlobalFilters`.**
  {{source: official exception-filter documentation.}}
- **A globally registered filter cannot inject dependencies** and does not apply
  to gateways or hybrid applications. {{source: official exception-filter
  documentation, verbatim intent. If the filter needs configuration, register it
  through a module instead — and know that it then does not cover gateways.}}
- **The filter produces one consistent error envelope for the whole API.** Every
  failure the client can observe has the same shape, so a client parses one
  thing.
- **The envelope separates the machine-readable code from the human-readable
  message.** {{source: the official filter example includes a status code and a
  timestamp; a project adds its own code field.}}
- **A `5xx` caused by an unhandled error is logged in full server-side and
  returned to the client as a generic message plus a correlation id.** Never
  return a stack trace, an internal message, or a database error to a client.
- **The framework's own HTTP exceptions are used rather than raw responses**, so
  the status code and the filter path are consistent.
- Never: return a bare object with a `message` from a handler as an error;
  catch-and-return inside a service to hide a failure; log a secret while
  normalising an error.

## Guards, Interceptors, Pipes

**The lifecycle order is fixed and it is not a style preference** — a guard runs
before a pipe, and a pipe before the handler, because that is the order in which
the framework composes them. {{source: official request-lifecycle
documentation: middleware → guards → interceptors (pre) → pipes → controller →
service → interceptors (post) → exception filters → response.}}

- **Authorization is a guard.** A guard decides whether the request may proceed;
  it is not a filter over the response.
- **Validation and transformation are pipes.** They are not guards and not
  middleware.
- **Cross-cutting request/response behaviour is an interceptor** — timing,
  logging, response mapping, a cache header. A guard cannot do it (wrong phase)
  and a filter cannot do it (only runs on error).
- **Each mechanism is bound at the right scope**: global in bootstrap, or per
  controller, or per route. Prefer the narrowest scope that works — a global
  interceptor that does one thing applies to every route in the application.
- **The framework's own guard/interceptor ordering applies**, and a custom
  implementation declares its order rather than relying on registration order.

## Configuration

- **Configuration is read through a typed config module, validated at startup.**
  A required value that is missing must fail the boot, not the first request that
  needs it (`core/security.md` §Environment Files).
- **Secrets come from the environment or a secret manager, never from a
  committed file.** A committed config file holds non-secret defaults only.
- **The public/private boundary is structural.** A value read by a
  client-facing route is public by construction; anything else is server-side.
- **No configuration value is read ad hoc at a call site.** One module owns
  configuration access.

## Persistence

- **One ORM client, provided once**, as a module provider that the application's
  persistence providers inject. {{source: official Prisma integration
  documentation shows the client exposed as an injectable service with a
  lifecycle hook for connecting and disconnecting.}}
- **The ORM client is a module boundary.** Domain and service code depends on a
  repository interface, not on the ORM's query API, so the persistence choice is
  replaceable and the service is testable without a database.
- **Migrations are generated by the ORM's migration tooling and committed.**
  Never a schema change applied by hand against a live database; never a
  `db push`-style sync in production.
- **Every query is parameterised.** Never string-concatenated SQL, and never a
  raw query with interpolated input.
- **A transaction is a service-level decision**, not a per-query one. Multiple
  writes that must succeed or fail together belong in one transaction.

## Testing

- **A unit test builds a testing module and resolves the provider from it** —
  {{source: official unit-testing documentation: `Test.createTestingModule({
  providers: [...] }).compile()`, then `moduleRef.get(Service)`.}} This
  exercises the actual DI wiring rather than a hand-constructed instance.
- **An external dependency is replaced through the module's override API**, not
  by monkey-patching the imported symbol. {{source: official unit-testing
  documentation: `.overrideProvider(Token).useValue(double)`.}}
- **A database-backed provider is replaced with a mock object in unit tests**, so
  the suite doesn't open a real connection. {{source: official Prisma
  documentation shows exactly this, with the note that it also bypasses the
  client's lifecycle hook — so the mock must stand in for the connection, not
  just the methods.}}
- **An end-to-end test builds a real application and drives it over HTTP**, with
  the overridden provider in place. {{source: official unit-testing
  documentation: `moduleRef.createNestApplication()`, `app.init()`, then a
  request against `app.getHttpServer()`. **The application must be closed in
  teardown** — an unclosed application leaves handles open and the test process
  hangs or the next suite inherits state.}}
- **A test asserts on the API's observable output** — status and body — not on
  whether a service method was called. The first is a contract; the second is an
  implementation detail that changes with every refactor.
- **An e2e suite covers the critical journeys only** (`testing.md` §E2E Scope).
- Never: hand-construct a provider with `new` in a test and call it a unit test;
  hit a real database in a unit test; leave an application unclosed; assert on an
  internal method call.

## Generated Code

<!-- The one part of this overlay that is not a style opinion: Nest's schematics
     exist because the boilerplate has a module registration, a provider scope
     and a matching spec file, and getting any of the three wrong produces a
     runtime failure rather than a compile error. -->

**Use the CLI. Do not create these by hand.**

```bash
nest g resource <name>        # controller + service + module + spec, wired
nest g controller <name>
nest g service <name>
nest g module <name>
nest g resolver <name>
nest g guard <name>
nest g pipe <name>
nest g filter <name>
nest g interceptor <name>
```

- **`nest g resource` is the default for anything with a route.** It wires the
  provider into the module, and a controller registered by hand is usually not —
  a route that 404s despite a correct handler is almost always this.
- **The generated spec is a starting point, not a test.** It asserts the default
  before each. Replace the body; do not keep it as-is, because a spec that only
  compiles proves nothing (`testing.md` §Status Gating).
- **A generated file is regenerated, never hand-edited** — except the ones you
  are supposed to edit (the service body). Re-running the generator over a
  hand-edited controller overwrites it; that is the intended behaviour.
- **The generated import path is not an alias by default.** Whatever this
  project's `tsconfig.json` configures is what the generator emits; check it
  before assuming the generated imports match `architecture.md` §Conventions.
- Verify the installed CLI's flags against `nest g --help` for this version
  before writing the command into a rule — the flags changed across majors.

## Banned Patterns

| Banned | Use instead | Enforced by |
|---|---|---|
| a DTO declared as an `interface` or a generic | a concrete class | review |
| business logic in a controller | a service | review |
| returning a persistence entity from a service | a DTO | review |
| raw `res.json()` in a handler | the framework's exceptions + filters | review |
| concatenated SQL or a raw query with input | parameterised queries | review |
| a hand-applied schema change | a committed migration | review |
| reading `process.env` at a call site | the typed config module | review |
| `new SomeService()` in a test | a testing module | review |
| an e2e test without teardown | close the application | review |
| a global filter that needs injected dependencies | register it through a module | review |
