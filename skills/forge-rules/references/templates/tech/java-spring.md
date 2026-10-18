# Overlay · Java / Spring Boot

<!--
GENERATOR NOTES — delete this block in the emitted file.

**Status: documentation-sourced, never applied end-to-end.** No audited project
exists for this stack. Every rule is traceable to a rung of
`documentation-sources.md` and carries its `source:` marker. When this overlay
is first applied to a real project, log what turned out to be wrong and fix the
file here.

Framework facts come from `/spring-projects/spring-boot` (3.x and 4.x
documentation and the framework's own test sources). **Verify version-specific
claims against the documentation for the installed major version** — Spring Boot
4 changed some auto-configuration internals, and the defaults below reflect what
the documentation states for the version in use.

The rules that aren't framework-specific already live in `core/` and `domain/`.
This file supplies the Spring mechanisms.
-->

# Java / Spring Boot

## Dependency Injection

- **Constructor injection, always.**
  {{source: official Spring Boot documentation, which recommends constructor injection to wire up dependencies and `@ComponentScan` to find beans. The documentation's stated benefit: it lets
  the field be `final`.}}
- **Fields injected by a framework-managed bean are `final`.** A non-final
  injected field is mutable shared state on a singleton, which is a concurrency
  bug waiting for traffic.
- **A bean with more than one constructor declares which one to use.**
  {{source: official documentation — mark it `@Autowired`.}}
- **Field injection and setter injection are not used in application code.** They
  hide dependencies from the constructor, prevent `final`, and make the bean's
  requirements invisible at the point of use.
- **No service locator, no field access through the application context.** A
  class that reaches for the context has hidden dependencies, and its tests
  require a full context to run.
- **The bean scope is the default singleton unless there's a reason.** A
  request-scoped or prototype-scoped bean is a deliberate decision with a
  lifecycle cost, and injecting a prototype into a singleton means the prototype
  is created once and held forever.

## Layering

```
{{@RestController}}  →  {{@Service}}  →  {{repository interface}}
```

- **A controller does HTTP and nothing else**: map the request, bind and validate
  the DTO, call one service, return a DTO. No business logic, no persistence,
  no orchestration of several services.
- **A service owns business logic and the transaction boundary.** It is the only
  layer that coordinates more than one repository.
- **A repository is an interface over persistence.** Spring Data generates the
  implementation from the interface; the service depends on the interface.
- **Entities are never returned from a controller.** A DTO is returned, so an
  entity change doesn't become an API change and internal fields don't leak.
  {{source: consistent with Spring's own documented practice of keeping
  persistence types out of the web contract; the framework does not prevent
  returning an entity, which is exactly why the rule has to be explicit.}}

## Validation — the boundary

- **`@Valid` on the DTO parameter, with `BindingResult` to collect the errors.**
  {{source: official Spring MVC and Boot documentation; this is the documented
  pattern for a `@Valid` DTO parameter in a controller method.}}
- **The validator is auto-configured.** {{source: Boot's
  `ValidationAutoConfiguration` provides a `jakarta.validation.Validator` with
  message interpolation when a validation provider is on the classpath. Nothing
  needs wiring — but nothing happens without the provider either, so its presence
  is worth confirming rather than assuming.}}
- **A DTO is a `record` where the language version allows it**, with Bean
  Validation annotations on the components. An immutable DTO cannot be mutated
  after validation by a later handler or an interceptor.
- **Every field that must be constrained carries its constraint.** A field with
  no annotation is not validated. If it isn't meant to be accepted, it doesn't
  belong in the DTO.
- **Field-level messages are resolved through the message source**, not
  concatenated in Java, so they are localisable.
- **A validation failure returns the field errors in the same envelope as every
  other error** (`@RestControllerAdvice`, below). A `BindingResult` rendered by
  a view resolver does not apply to a JSON API.

## Error Handling

- **One `@RestControllerAdvice` handles exceptions for the whole API** and
  produces one consistent error envelope. {{source: the documented role of a
  controller-advice bean; combined with Boot's auto-configured message
  interpolation for the validation messages.}}
- **The envelope separates the machine-readable code from the human-readable
  message**, and carries a correlation id.
- **A `5xx` caused by an unhandled exception is logged in full server-side and
  returned to the client as a generic message plus that id.** Never return a
  stack trace, an exception message that can name an internal class or a
  constraint, or a database error.
- **Validation failures, business-rule failures, and missing resources are
  distinct codes**, distinguishable by a client without parsing prose.
- **A business rule failure is not an exception type per rule.** A small set of
  typed exceptions carrying a code, handled centrally, beats a class per case.
- Never: catch-and-return inside a controller to shape an error; return a bare
  map with a `message` from a handler; let a framework exception escape to the
  container's default error page in a JSON API.

## Security

- **A user-defined `SecurityFilterChain` bean replaces the auto-configured
  default chain.** {{source: Boot's default security configuration is annotated
  `@ConditionalOnDefaultServletWebSecurity` and backs off as soon as a
  user-defined `SecurityFilterChain` bean exists. **The consequence: adding the
  bean is what turns the project's own configuration on. A chain that appears to
  be ignored is often a second chain, or a chain that was never declared
  because the default was assumed to be replaced.}}
- **Authorization is expressed in the chain and in method security, not
  scattered through controllers.** {{source: the framework's documented
  `authorizeHttpRequests` matcher DSL, plus method-level security annotations
  for finer rules.}}
- **A route with no authorization rule is closed, not open.** The chain's
  matcher set is reviewed as a whole: what matches, and what it requires.
- **Method-level authorization is explicit** where a controller-level rule is too
  coarse — `@PreAuthorize` on the service method, checked against the
  authenticated principal, not against a value passed in from the client.
- **The authenticated principal comes from the security context**, never from a
  request parameter or a header the client controls.
- **CORS is configured in the chain**, from an explicit origin list. Never a
  wildcard on a credentialed request.
- **CSRF protection stays on** for session-based authentication. Disabling it is
  a decision with a written justification, never a default.
- **Passwords are hashed with the framework's encoder**, never with a general-purpose
  hash, and never verified by comparison against an encoded value the
  application computed itself.

## Transactions

- **`@Transactional` on the service class**, so every public method runs in a
  managed transaction. {{source: Boot's own documented service pattern — a
  `@Component` service annotated `@Transactional` at class level, delegating to
  repositories.}}
- **The transaction boundary is the service method, not the repository and not
  the controller.** A repository that opens its own transaction commits before
  the service's work is done.
- **Read-only queries are marked read-only** so the persistence provider can skip
  dirty checking and, where it supports it, route to a replica.
- **A `private` method is not transactional** — the proxy-based mechanism does not
  intercept self-invocation. A `private` method called from within the same class
  runs in whatever transaction the caller has, which is often not the one the
  name suggests. {{source: the mechanism is proxy-based interception, so
  self-invocation bypasses it.}}
- **A method called from inside the same class does not get its own
  transaction** for the same reason. If a transactional operation must be
  independently transactional, it belongs in a separate bean.
- **Check-then-act across a transaction boundary is a race.** A uniqueness
  constraint is the real guard; the check is an optimisation for a better error
  message.

## Persistence

- **A Spring Data repository is an interface**, and the query is derived from the
  method name. {{source: official documentation's derived-query examples —
  `findByNameContainingAndCountryContainingAllIgnoringCase`, with `Pageable` for
  pagination.}}
- **A query that can't be derived from a name is a `@Query`** — declared, with
  its parameter binding explicit. An undeclared native query's result mapping is
  invisible.
- **Pagination is always `Pageable`-driven**, and a paginated endpoint is bounded
  — an unbounded list endpoint is a denial-of-service vector.
- **N+1 is the default risk of the derived-query model.** A list endpoint that
  iterates entities and touches a lazy association per row is N+1. Fetch the
  needed association in one query, or project the read model directly.
- **Fetch size and entity graphs are set deliberately** for anything large.
- **Schema changes are versioned migrations**, applied by a migration tool, and
  committed. Never a hand-applied change against a live database; never a
  schema sync in production.
- **Every query is parameterised.** The framework's parameter binding is used;
  a concatenated query built from input is a defect.

## Configuration

- **Configuration keys are bound to a typed properties class**
  (`@ConfigurationProperties`), not read with `@Value` one at a time.
  {{source: official documentation recommends a properties class for a group of
  keys precisely because it gives a structured, type-safe object to inject.}}
- **A properties class deals with the environment and does not inject other
  beans.** {{source: official documentation, verbatim intent — it "only deals
  with the environment and, in particular, does not inject other beans from the
  context." If bean injection is genuinely needed, the bean must additionally be
  a component and use JavaBean-style binding — and that is the exception, not
  the default.}}
- **A required value with no default fails the boot**, not the first request
  that needs it.
- **Secrets come from the environment or a secret manager.** A committed
  properties file holds non-secret defaults only, and profile-specific files
  never contain credentials.

## Testing

- **Test slices, not the whole context, by default.**
  {{source: Boot's own test annotations — a data slice for repositories, a web
  slice for controllers, a full boot test only for genuine integration.}}
- **A data-slice test is transactional and rolls back after each test**, and it
  replaces the `DataSource` with an embedded database.
  {{source: Boot's `DataJpaTest` is annotated `@Transactional` and
  `@AutoConfigureTestDatabase`, and its own documentation states both the
  rollback and the database replacement. **The consequence: a test that commits
  deliberately will not behave the same outside the slice, and a test relying on
  data another test wrote is relying on ordering.**}}
- **When a migration tool owns the schema, the embedded-database replacement is
  turned off** —
  `@AutoConfigureTestDatabase(replace = Replace.NONE)`.
  {{source: Boot's documented example, given specifically so the migration tool
  manages the schema in tests. Without it, the tests run against a schema the
  migration tool did not build, and they pass against a database shape that does
  not exist in production.}}
- **A web-slice test exercises the web layer with mocked services.** A test that
  loads the full context to assert one status code is slow and gives a failure
  message that points at the context rather than the code.
- **A full-boot test uses the smallest web environment that works** —
  {{source: `@SpringBootTest`'s documented `webEnvironment` modes: a mock
  environment, a random port, a defined port, or none.}}
- **Security is exercised in the test, not assumed.** A slice test runs with the
  security filter chain applied; a test that bypasses it can pass while the route
  is actually open.
  {{source: Boot's own security test auto-configuration wraps `MockMvc` requests
  with the security context from the test — which is why a slice test that
  appears to skip security is the exception to check for, not the norm.}}
- **An assertion is on observable output** — status, body, persisted state — not
  on whether a collaborator was called. {{source: the same principle as
  `testing.md`, expressed for a proxy-based container where mocking a
  collaborator also bypasses the transaction and the advice chain around it.}}
- **A test that needs a real database uses a container, and says so.** A test
  silently running against an embedded database when the production engine is
  different is a test that cannot fail the way production fails.
- Never: hand-inject a collaborator into a `new`-constructed service and call it
  a slice test; assert on a mock invocation; rely on test ordering; leave a
  container running for the whole suite to save a few seconds.

## Generators, Scaffolding, and Where There Is No Generator

**Being honest about the asymmetry here matters more than being consistent.**

### The project skeleton: generate it

A Spring Boot project's skeleton is exactly what a generator is good at — build
file, directory layout, a runnable application class, the test, the properties
file, `.gitignore`.

```bash
# https://start.spring.io — CLI form
spring init --dependencies=web,data-jpa,validation,postgresql my-service
# or the HTTP form, which the IDEs and VS Code plugins wrap
curl https://start.spring.io/starter.zip -d dependencies=web,data-jpa -d javaVersion=21 -o svc.zip
```

**Use it for a new service. Do not hand-write `pom.xml`.** The failure mode is
not visible in the file — it is a missing plugin version that resolves to a
different Spring Boot patch level than the one the rest of the code assumes.

**In IntelliJ or STS, the Initializr is the same service with a form.** So the
rule is the same: the generator decides the dependency set, the plugin versions
and the Java version; `pom.xml` is then edited by hand from there.

### The code: write it by hand, and that is correct

**There is no mature code generator for a Spring controller, service, repository
or JPA entity**, in the way Nest, Angular, Rails or Spring Initializr have one.
Saying otherwise in a rule set would produce an agent hunting for a tool that
does not exist.

So the rules are the ones that stand on their own:

| Artefact | Generated? | What to do instead |
|---|---|---|
| Project skeleton | **Yes** — `spring init` / Initializr | Never hand-write `pom.xml` for a new service |
| A JPA entity | **No** | Write it. A generated entity is a mutable data class with `equals` that compares identity, which is wrong for a domain model |
| A `Repository` interface | **No** | It is one line: `extends JpaRepository<T, ID>`. There is nothing to generate |
| A controller | **No** | Write it. What a generator would produce is a class with a method that returns `null` |
| A service | **No** | Write it |
| A DTO | **No** | Write it, and hand-map it at the boundary (`domain/data-and-state.md` §Normalizers) |
| Lombok annotations | **Yes**, if the project uses Lombok | Let the IDE generate accessors. **Verify `lombok.config` in the repository** — the generated code is not in git, so the config is the only source of truth for what Lombok will do |

**What a generator would have got right, and what you must therefore remember
by hand:**

- The **package** matches the directory, always. The build does not enforce it,
  so a mismatched class compiles and Spring refuses to find it at startup.
- The constructor is `public`, for proxying — the same reason every other class
  here takes constructor injection.
- A `@RestController` returning an entity leaks the schema; a DTO does not.
- A `@Transactional` boundary belongs on the **public** method of the bean.

{{#if intellij}}
**In IntelliJ:** `File → New → Spring Boot Component` generates the file, the
package and — for a controller — the `@RequestMapping` skeleton. It does not
generate tests; generate the test separately, or write it. The Java Database
tools can generate an entity from an existing schema, which is legitimate when
adopting an existing database — and produces a class you then have to review,
because it defaults to identity `equals`.
{{/if}}

## Banned Patterns

| Banned | Use instead | Enforced by |
|---|---|---|
| field or setter injection | constructor injection with `final` fields | review |
| a controller returning an entity | a DTO | review |
| `@Value` for a group of related keys | `@ConfigurationProperties` | review |
| `@Transactional` on a repository | on the service | review |
| a `private` method relied on to be transactional | a separate bean | review |
| a wildcard CORS origin on a credentialed request | an explicit origin list | review |
| CSRF protection disabled by default | left on; disabled only by decision | review |
| a hand-applied schema change | a committed migration | review |
| concatenated SQL | parameterised queries | review |
| an unbounded list endpoint | a paginated one | review |
| a test relying on data another test wrote | independent fixtures | review |
| a data-slice test with the embedded database left on while migrations own the schema | `replace = Replace.NONE` | review |
| a full-context test for a single status code | a web slice | review |
| a hand-written `pom.xml` for a new service | `spring init` / Initializr | review |
| a generated entity with identity `equals` on a domain type | a hand-written one, or Lombok | review |
