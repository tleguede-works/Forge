# Overlay · Flutter / Dart

<!--
GENERATOR NOTES — delete this block in the emitted file.

Status: source-audited (one audited project, Riverpod 3.x handwritten + GoRouter
+ feature-first, backend-agnostic). The source project's state-management choice
was Riverpod without code generation; where a project chooses a different state
library, replace §State Management and keep everything else.

**One correction applied to the source material:** the audited profile stated an
`autoDispose` exception in terms of a code-generation annotation, in a file whose
own rules banned code generation. The rule has been restated in terms of the
actual runtime API.

**Provenance.** The mechanism rows come from the audited project named above —
the framework's behaviour as it was actually exercised, not as documented. Rows
marked `{{version: re-verify}}` were true for the version audited and must be
re-checked against the installed one. When this overlay is applied, the emitted
file carries a `source:` marker on any rule the project re-derived
(`documentation-sources.md`): a template cannot supply provenance for a claim
only that project can verify.
-->

# Flutter / Dart

## Commands

```bash
flutter pub get                    # dependencies
flutter analyze                    # static analysis — must be zero issues
dart format .                      # format
dart format . --output=none --set-exit-if-changed .   # format check, no writes
flutter test                       # unit + widget tests
flutter test --coverage            # with coverage
flutter test integration_test      # on-device integration tests
flutter gen-l10n                   # regenerate localizations
```

## Dart Style & Analysis

- **`analysis_options.yaml` is the single source of lint truth**, and the linter
  is part of the verification order. `flutter analyze` must report **zero**
  issues — not "no errors".
- **The lint set this project enforces** — the enforced subset of the SDK
  defaults, plus:
  - single quotes for strings
  - trailing commas
  - `const` constructors and declarations on every model and widget that can be const
  - **no `print`** — `avoid_print`; use the project's logger
  - **no `dynamic` calls** — `avoid_dynamic_calls`; type the value
  - explicit return types
  - super parameters
  - package imports, never relative, for cross-directory
  - unawaited futures are deliberate
- **Never suppress an analyzer hint or error to make analysis pass.** Fix it, or
  disable the specific rule in `analysis_options.yaml` with a written reason —
  never an inline ignore on one line.
- **Never add `--no-sound-null-safety` or any legacy flag.** It is a
  whole-program downgrade for one error.

## Dependencies

- **Never hand-edit `pubspec.yaml`** to add, remove, or pin — use
  `flutter pub add <package>`, `flutter pub add dev:<package>`,
  `flutter pub remove <package>`, `flutter pub upgrade`. The tool keeps the
  manifest and the lockfile consistent; a hand edit does not.
  The narrow exception is non-dependency metadata — assets, fonts — kept minimal
  and justified.
- **Pin to a real version resolved by the tool.** Never `any`, never unpinned.
- **Never delete `pubspec.lock` to resolve a conflict.** Resolve the constraint.
- **Never run `flutter clean` unless the build cache is genuinely corrupted** —
  it is a long rebuild, not a fix.
- **No code generation** unless a decision in the decisions log says otherwise.
  That means no `freezed`, no `json_serializable`, no `riverpod_generator`, no
  `build_runner`. Models are handwritten.

## Models (no code generation)

- **`const` constructor on every model that can be const** — such a model is
  const, and const models are compared by identity for free.
- **Override `==` and `hashCode`** — using the framework's helper, not a
  hand-rolled chain. A model in a set or a map key without this silently
  misbehaves.
- **`copyWith` on every model.**
- **Validation in the constructor** for a value object. A `UserId` that cannot
  hold an invalid value is better than a `User` that can.

## State Management

> **{{Default: Riverpod with handwritten providers — no code generation.}}**

- **One controller per screen**, named for the screen. Its `build` declares what
  it depends on; its public methods are the actions.
- **Dependencies are declared in `build`, not injected through the
  constructor.** That is the mechanism the library uses to rebuild on
  dependency change; constructor injection bypasses it.
- **Mutations are public methods on the controller** — `{{controller.login()}}` —
  not callback properties passed in, and not free functions.
- **Use the async notifier for anything that fetches**, so the loading and error
  states are part of the type rather than a separate boolean.
- **Invalidate explicitly** — the provider itself for same-provider
  invalidation, the named provider for cross-provider. **Name the invalidation
  helper** when a change affects several providers.
- **Disposal is the default** for a provider scoped to a page. Keep-alive is an
  explicit choice, made with the framework's own API — not an annotation from a
  code-generation package this project doesn't use.
- **`ChangeNotifier` is banned.** If you reach for it, the project uses a
  different notifier type; the two models don't mix.
- **Select the narrowest state a widget depends on**, so a change to one field
  doesn't rebuild a widget that reads another.
- **Watch as close to the consuming widget as possible.** A provider watched at a
  root rebuilds the whole subtree.

## Errors

- **A repository method never throws.** It returns `{{Result<T>}}` — a sealed
  type with success and failure variants — so a failure is part of the signature
  and cannot be forgotten.
- **Every failure carries a machine-readable code**, so the UI maps a code to a
  message and never renders a raw error string.
- **The one error type that crosses into the presentation layer is that
  failure type.** A raw exception from a plugin or an HTTP client does not reach
  a widget.
- **Callers exhaustively match** on the result — a `switch` over the sealed
  variants, which the compiler makes incomplete if a variant is added.

## Data Access

- **Repository interfaces are abstract and declared in the domain layer.** The
  domain layer imports **no** plugin, no HTTP package, no platform library —
  verify with a grep. The implementation lives in the data layer.
- **The data layer depends on the domain; the presentation layer depends on the
  domain; the domain depends on nothing.** No cycles.
- **Mappers convert raw data to domain models, as pure functions** with a
  consistent suffix, in one file per model, colocated. No I/O, no side effects.
  - `{{Mappers.fromRow}}`, `{{Mappers.toInsertPayload}}`,
    `{{Mappers.toUpdatePayload}}` — the trio a model crossing a storage boundary
    needs.
- **The active backend is a wiring decision**, made once. Domain and
  presentation code does not know which implementation is active.
- **Nullability is resolved in the mapper**, not in a widget. A field that can be
  null at the source is a field the model admits, and the mapper decides what it
  becomes.
- **Errors are wrapped at the call site** so a failure is always inside the
  result type rather than escaping as an exception.

## Routing

- **One router, configured once**, at the application root. Not a second
  navigator in a feature.
- **Every path is a constant or a function in the routes module.** Never a path
  string in a feature file. Dynamic segments are functions, not concatenation.
- **Auth redirects are handled by the router's redirect callback**, not in
  individual pages. A page that decides whether the user is signed in is a second
  source of truth about auth.
- **Route parameters do not belong on shell routes** — a shell that has to carry
  a parameter is a shell that will conflict with the shell's own state. Use a
  query parameter or a nested route.
- **Transitions are declared in the router**, not per page, so navigation feels
  uniform.
- **The router rebuilds on a listenable** tied to auth state, so a sign-out
  redirects without a manual navigation call.

## Widgets & UI

- **All colours and text styles come from the theme extension**, never a literal
  in a widget file (`ui-components.md` §Design Tokens).
- **A page contains composition and wiring only.** Validation, orchestration,
  side effects, navigation, and data access live in the controller. Forbidden in
  a page: a large inline callback, a business `try`/`catch`, a heavy
  transformation, direct data access.
- **A feature widget moves to the feature's shared folder once used by more than
  one page in that feature**; it moves to the shared location once used by more
  than one feature. Not before.
- **`const` constructors wherever the widget's parameters allow it** — this is
  the framework's primary rebuild optimisation.
- **A widget with a controller does not also hold local state** for the same
  concern. Two sources of truth for one thing is a bug with a delay.
- **Every animation controller is created with a `vsync`, and disposed.** An
  undisposed controller is a leak that shows up as a crash on route pop.
- **Every focus node you create is disposed.** Same failure mode.
- **Semantics on every interactive widget** (`accessibility.md`).

## Localization

The rules are in `i18n.md`. The mechanism: **ARB files in `{{dir}}`, with
`{{native language}}` as the template file**, generated by `flutter gen-l10n`
into `{{output dir}}`, configured by `l10n.yaml`.

- **The generated files are committed.** A commit that changes an ARB file
  without the regenerated output is incomplete.
- **`flutter gen-l10n` after ANY ARB change.** Not optional — the build fails
  without it.
- **A new key goes into the template ARB first**, then the translations, then
  the generator runs, then the key is used.
- **French and other French-language locales use U+202F, not U+0020.** French
  typographic convention puts a narrow no-break space before `: ; ! ?` and inside
  number groups (`25 000 €`, not `25 000 €` with an ordinary space). This is
  invisible in a source file and survives a review by eye, so a literal written
  with an ordinary space compiles, runs, and fails a `textContaining` assertion
  with no visible cause. Two ways out, both required:
  - Assert through a helper that normalises separators — never write the literal
    inline in an assertion.
  - Add a test on the formatters that asserts the exact codepoint, not the
    rendered glyph.

## Named Footguns

<!-- Language-and-framework traps that produce real defects. Each one names the
     check that catches it — a footgun with no command is a preference. -->

- **`List.sort` is not stable in Dart.** Two elements comparing equal can come
  back in either order, so a screen's row order can change between two identical
  runs, and a list of same-day entries has no defined order. **Every sort that
  feeds a user-visible list needs a total order: a tiebreaker on a unique key
  (id, sequence, insertion order) after the primary key.** Verified by a
  mechanical grep — every `.sort(` on a collection reaching a widget is followed
  by a comparison whose last clause is a unique key.

- **A `sealed` type is a machine for showing omissions.** The compiler rejects an
  incomplete `switch` over a sealed hierarchy, so use one on every domain
  enumeration. It is not a stylistic choice: it is what turns a forgotten branch
  from a runtime surprise into a compile error.

- **Never call the wall clock from business logic.** `DateTime.now()` in a domain
  file makes deadlines untestable and lets two reads inside one screen straddle a
  boundary. Inject the clock. **And test that the injected clock is wired**, not
  merely that it exists — a clock harness used by nothing but its own test is dead
  code that looks like coverage.

- **A dependency version table is a hypothesis until the first install.** A
  version written from memory can be unresolvable, and the failure looks like a
  version conflict rather than a wrong file. Resolve from the manifest, and
  resolve it in every file that states a version.

## Testing

The rules are in `testing.md`. The Flutter-specific constraints:

- **`flutter test` runs unit and widget tests. `flutter test integration_test`
  requires a booted device or emulator** and never runs on a host-only CI
  runner. Say so in the test file, so nobody waits for a suite that can't run.
- **No mocking framework.** Use the real implementation with sample data, or a
  hand-written in-memory fake. A mocking library's generated mocks drift from
  the interface and nobody notices until the test passes against a method that
  no longer exists.
- **Fakes live in a fakes folder or beside the test**, not in a shared setup
  that makes each test's dependencies invisible.
- **A controller test injects fakes through the framework's testing container**
  with the provider's override API, rather than constructing the controller by
  hand — otherwise the test doesn't exercise the wiring it claims to.
- **`group()` and `test()` throughout; a widget test only where something actually
  renders.**
- **Every mapper has a round-trip test** (`testing.md`).
- **Never add an older first-party driver package** — deprecated, and the
  replacement covers it.
- **A UI-automation tool is added only when a flow genuinely needs native
  interaction** — a system permission dialog, biometrics, a notification. Not for
  general E2E, where the integration test package is sufficient.

## Banned Patterns

| Banned | Use instead | Enforced by |
|---|---|---|
| `print()` | the project logger | `avoid_print` |
| a colour literal in a widget | the theme extension | `{{lint rule}}` |
| `ChangeNotifier` | the project's notifier type | review |
| a `dynamic` call | an explicit type | `avoid_dynamic_calls` |
| a hand-edited `pubspec.yaml` | `flutter pub add` / `remove` / `upgrade` | review |
| a path string in a feature file | the routes module | review |
| an imperatively pushed route | the router | review |
| a wall-clock call in business logic | an injected clock | review |
| hand-rolled platform channels where a package exists | the package | review |
| the deprecated first-party driver package | the integration test package | review |
| a mocking framework | hand-written fakes | review |
| `--no-sound-null-safety` | fix the error | `AGENTS.md` §Escalation Rules |
