# Overlay · React Native / Expo

<!--
GENERATOR NOTES — delete this block in the emitted file.

Status: source-audited (one audited project, an Expo SDK 57 cross-platform
storefront). The general React rows live in `react.md`; only the native rows are
here. Where a row is specific to one SDK version, it says so and says how to
re-verify it.

**The first section is the most important one in this file.** The audited source
project opened its instruction file with it, and it exists because the failure
it prevents is silent: the model confidently writes correct-looking code against
an API that changed two releases ago, and the error appears as a runtime crash
or a silent no-op.

**Provenance.** The mechanism rows come from the audited project named above —
Expo's behaviour as it was actually exercised on the SDK version it pinned, not
as remembered. Rows marked `{{version: re-verify}}` are the ones most likely to
drift and must be re-checked against the installed SDK before being emitted.
When this overlay is applied, the emitted file carries a `source:` marker on any
rule the project re-derived (`documentation-sources.md`).
-->

# React Native / Expo

## Verify against the installed SDK — do not trust your memory

**Expo ships breaking changes every SDK release.** APIs you remember are likely
renamed, moved, or removed, and the code you write from memory will type-check
against your assumptions rather than against the installed version.

Before writing any code that touches an Expo, EAS, or React Native API:

1. **Read the installed major version** from `{{manifest}}` — currently
   `{{expo ~57.x}}`.
2. **Fetch the docs for that exact version** — `{{versioned-docs-url}}`. Not
   `/latest`, and not from memory.
3. **Use the machine-readable doc index if the project has one configured**
   ({{e.g. an MCP documentation server, or a bundled skill pack}}). It carries
   corrections to known model misconceptions that the prose docs assume you
   don't have.
4. **When a rule here or in another file names a specific API, re-verify it
   against the installed version** before relying on it. A row marked
   `{{version: re-verify}}` was true for the version audited and may not be for
   the next one.

**A note in a rule file is a hypothesis about a version, not a guarantee.** When
one is wrong, the fix is to correct the rule and record it in
`{{external-system-contracts}}` if the behaviour is specific enough — not to
work around it silently.

## Installation

- **`npx expo install <package>` for any Expo SDK package.** It resolves the
  version compatible with the installed SDK. **Never a raw
  `{{npm/bun/pnpm/yarn}} install` for an SDK package** — the version it picks
  can be a major version off, and the failure appears as a native-module error
  at runtime rather than at install time.
- **The project's own package manager for everything else** —
  `{{bun add <package>}}`.
- **`npx expo install --fix`** to repair a drifted dependency tree.
- **Never hand-edit the manifest to pin a version.**
- **`npx expo-doctor`** is the dependency and config health check, and it is part
  of the verification order.

## Native Builds

- **Continuous Native Generation is the default: no `ios/` or `android/`
  directory is committed.** Native behaviour is configured in `{{config file}}`
  and config plugins. **Never create or edit a native directory by hand** — it
  is regenerated, and the edit is lost.
- **Expo Go only contains its bundled native modules.** A library with native
  code — a secure store, a checkout sheet, a camera, a push client — will not
  load in Expo Go.
- **A feature that needs a native module requires a development build:**
  `{{npx expo run:ios|android}}` locally, or
  `{{bunx eas-cli build --profile development}}` in the cloud.
- **Testing a native-module feature in Expo Go and calling it verified is a
  false positive**, and it is on the entry file's `Never` list. It is the single
  most likely way this project reports a feature as working when it has never
  loaded.
- **Prefer an Expo-supported module over a third-party one**, and check what
  the project's available skills already cover before adding a dependency.

## Build & Distribution

- **EAS builds, signs, and submits in the cloud** — no local Xcode or Android
  Studio required. Run it as `{{bunx eas-cli <command>}}`.
- **Over-the-air updates** carry JavaScript and assets, **not** native changes. A
  change requiring a new native module cannot ship by OTA.
- **Cloud builds reuse a previous export unless you produce a fresh one.** When a
  deployed route is missing from a published deployment, check whether the
  build reused a stale export before debugging the route. {{This is a recorded
  finding; see `{{external-system-contracts}}`.}}

## Native UI

- **Prefer the platform's own native components** — {{e.g. `@expo/ui`, which
  maps to SwiftUI and Jetpack Compose}} — over base-framework components or
  community libraries, when they cover the need. They inherit the platform's
  accessibility, focus, and gesture behaviour for free.
- **Fall back to the base framework only where the native set has no
  equivalent**, and prefer an Expo-supported addition over hand-rolled native
  view code.
- **Verify a native component's behaviour against the SDK's versioned docs**
  before relying on it. {{e.g. at the audited version, `@expo/ui`'s `List`
  renders native grouped rows and is **not** a virtualized list — a large dataset
  through it does not window, and the symptom is a long flat render rather than
  an error. Use the base framework's or a community virtualized list for large
  data. `{{version: re-verify}}`}}
- **Branch explicitly on `Platform.OS` inside a component** when the UI must
  differ. Never maintain two near-identical screens per platform.

## Lists

- **A plain `map` is correct for a small fixed list** — {{~20 items}}. Do not
  reach for a virtualized list on eight rows.
- **A virtualized list for anything large or unbounded.** **Never render an
  unbounded collection with a `map`** — the list is driven by data that grows.
  {{`FlatList`, or a higher-performance community list when row cost is high.}}
- **Stable keys, never the index.** **`keyExtractor` is required** and returns a
  stable identifier.
- **Uniform rows declare their height**, which lets the list skip measurement.
- **No virtualized list nested inside another** — a list in a list header
  defeats the outer list's windowing. Restructure into sections with sticky
  headers, or one flat list.
- {{`performance.md` §Lists applies in full.}}

## Images

- **Use `{{expo-image}}` for remote images**, not the base framework's image
  component — it handles resizing, caching, and progressive loading.
- **Request the size actually rendered**, using the source's transform
  parameters. Never download a full-resolution asset for a thumbnail.
- **Always specify dimensions or a fit mode** so layout doesn't jump.
- **Don't disable caching to fix a one-off.**

## Keyboard & Input

- **Keyboard avoidance is explicit, and both platforms are configured.** The
  default of "undefined" is a no-op on at least one platform.
  - iOS: the container's avoidance behaviour, plus the platform's automatic
    inset adjustment where available.
  - Android: the container's avoidance behaviour **plus** an explicit
    scroll-into-view per field — Android's container shrinks the viewport but
    does not by itself reveal the focused field.
- **The focused field must never sit under the keyboard.** This is the defect
  that a single-platform implementation always misses.
- **A tap on a control while the keyboard is open must work** — the tap-
  through setting is explicit, not a default to rely on.
- **The return key chains through fields in visual order**; the last field
  submits. For irreversible actions, an explicit submit control remains
  mandatory (`accessibility.md` §Keyboard Operation).
- {{If the project later adds a keyboard-aware scroll container, the manual
  per-field scroll handling above is replaced by it, and this section should be
  updated in the same change. A rule that describes a workaround for a
  dependency the project no longer has is a trap.}}

## Safe Areas & Insets

- **Respect the platform's safe areas and insets.** Never hardcode a top padding
  to clear a status bar, a notch, or a home indicator — the values differ by
  device and by orientation.
- **The bottom inset matters for anything at the bottom of the screen** — a tab
  bar, a fixed button, a list's last row.

## Accessibility

The rules are in `accessibility.md`. The native mechanisms:

- **Every interactive element declares a role and a label**
  ({{e.g. `accessibilityRole`, `accessibilityLabel`}}), and a visible text label
  counts as the label.
- **State is exposed as state** ({{e.g. `accessibilityState` with disabled,
  selected, checked}}) — **never colour alone** as the only signal.
- **Dynamic changes are announced** ({{e.g. an accessibility live-region
  announcement}}) rather than mutating silently.
- **Touch targets meet the platform minimum** — {{~44pt}}.
- **Related items are grouped** into one accessible element where a screen
  reader would otherwise read a row piece by piece.
- **Meaningful images get a description; decorative images are marked as
  decorative** — a missing description is not the same as an empty one.
- **Don't strip or replace the accessibility semantics a native component
  already carries.**

## Animation & Haptics

- **Motion is small and purposeful** (`ui-components.md` §Motion).
- **Respect the reduced-motion preference** at runtime — this is a native
  preference, not a stylesheet query.
- **Haptics accompany a physical action, not a state change that already has
  visual feedback.** A haptic on every state change is noise.

## Banned Patterns

| Banned | Use instead | Enforced by |
|---|---|---|
| a raw package-manager install for an Expo SDK package | `npx expo install <package>` | review |
| a committed `ios/` or `android/` directory, or any hand-edit of one | config in `{{config file}}` + config plugins | review |
| verifying a native-module feature in Expo Go | a development build | `AGENTS.md` §Escalation Rules |
| the base framework's image component for remote images | `{{expo-image}}` | `{{lint rule}}` |
| a `map` for an unbounded collection | a virtualized list | review |
| the index as a list key | a stable identifier | `{{lint rule}}` |
| hand-rolled native view code where an Expo-supported module exists | the Expo module | review |
| `{{StyleSheet}}` with literal values in a component | the theme tokens | `{{lint rule}}` |
