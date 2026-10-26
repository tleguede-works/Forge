# Synthesis Provenance

> **Not part of a run.** This is the one-time audit trail for the consolidation
> that produced `references/templates/`. It is read when **maintaining the
> library** — adding a template, deciding whether a rule is universal, or
> checking what a change to a template would drop.
>
> **No run reads it.** It was originally in `references/`, where SKILL.md told
> every run to read it "before drafting from a template". That put the largest
> file in the library — 441 lines of history — into the hot path of every
> bootstrap, for content with zero recurring value. A file in `references/` is a
> file an agent reads; this one does not belong there.
>
> It stays, complete, because deleting it without a replacement would repeat
> exactly what it documents: `postmortems.md` Case 1, content correctly
> deduplicated and correctly non-redundant, but silently gone.

The audit trail for the template library. Every rule from the three source sets is
listed here with its destination. This file exists because deleting
`references/profiles/` without it would repeat `postmortems.md` Case 1: content
that was correctly deduplicated and correctly non-redundant, but silently gone.

**Sources**

| Id | Set | Location | Size |
|---|---|---|---|
| **F** | Flutter profile | `references/profiles/flutter-riverpod-gorouter/` (deleted) | 11 rule files, 958 lines + `AGENTS.md`, `DECISIONS.md`, `LEARNINGS.md`, `SESSION_LOG.md`, `analysis_options.yaml`, `opencode.json` |
| **N** | Next.js profile | `references/profiles/nextjs-redux-axios/` (deleted) | 13 rule files, 728 lines + 3 `variants/` + `AGENTS.md`, `DECISIONS.md`, `LEARNINGS.md`, `SESSION_LOG.md` |
| **E** | Elora (real project) | `C:\Users\Thibaut LEGUEDE\Documents\Projects\Elora\` | 15 rule files, 1014 lines + `AGENTS.md`, `DECISIONS.md`, `DESIGN.md`, `PRODUCT.md`, `LEARNINGS.md`, `SESSION_LOG.md`, `opencode.json` |
| **D** | Documentation | `documentation-sources.md` rungs 1–5 | Only source for the two backend overlays |

**Status vocabulary**

- `→` moved to a template, content preserved at comparable depth
- `⇄` merged with N sibling rules from other sources into one rule
- `⇅` merged with a rule from the *same* source (intra-file duplicate removed)
- `✂` cut as tutorial prose (the only licensed cut — Principle 1, tier 1)
- `○` intentionally not templated — project-specific, stays in the generated project
- `▲` fixed — a defect in the source, corrected in the template

---

## C1 · `templates/core/entry-file.md`

| Source rule | Destination | Note |
|---|---|---|
| F `AGENTS.md` §Commands (9-row table) | §Commands | → table form kept |
| N `AGENTS.md` §Commands | §Commands | ⇄ merged: N's commands are script-based, F's are CLI-based. Template emits a table, rows supplied by the tech overlay |
| E `AGENTS.md` §Commands + "use `bunx` not `npx`" | §Commands | → package-manager rule generalised |
| F §Definition of Done (5) | §Definition of Done | ⇄ with N (7) and E (9). Template keeps the **conjunctive ALL-of** shape; the count is per-project |
| N DoD item 3 "flag this line as aspirational until then, don't silently treat it as satisfied" | §Definition of Done | → kept verbatim in spirit. This is the mechanism that stops a DoD line from quietly becoming a lie |
| E DoD item 9 (same aspirational mechanism) | §Definition of Done | ⇄ confirms the rule across two independent sources |
| F §Priority Ranking (Correctness→Completeness→Quality→Speed) | §Priorities | ⇄ with N (backend contract→parity→type/test→style) and E (backend contract→type/security→completeness→quality→speed). Template emits the **shape** (5 ranked slots) |
| N §Escalation Rules | §Escalation Rules | → the canonical form. "stop, report, show the exact response" |
| N "If blocked after 2 attempts: stop, report what you tried, and wait" | §Escalation Rules | ⇄ triplicated (N, E, F-as-3-attempts). Template standardises on **2 attempts** (N + E agree; F's 3 is the outlier) |
| N §Escalation "Never:" list | §Escalation Rules | → kept as a hard-ban surface, rows per tech overlay |
| F §When Blocked | — | ✂ **merged into §Escalation Rules.** Two homes for the same rule was a live duplication in all three sources |
| F §Git Conventions | §Git Conventions | → **promoted to universal.** Present only in F; absent from N and E |
| F `AGENTS.md` §Architecture Summary | §Architecture Summary | ⇄ with N §Architecture. Template emits a 4-bullet digest that **defers** to the architecture rule file |
| F §Tech Stack (Default) | §Tech Stack | → table form. The `(Default)` hedge is **removed**: the Next profile had to add an explicit "strip this once confirmed" step because the hedge survived into real projects |
| F §Rules Reference (11 rows) | §Rules Index | ⇄ with N (13 rows) and E (15 rows). One table, rows = emitted files only |
| F §Cross-Session Memory (3 files) | §Cross-Session Memory | ⇄ with N (2 files) and E (3 files). See the memory-file templates below |
| N §Project Learnings | §Project Learnings | ⇄ with E. F has a separate `LEARNINGS.md` instead — see `architecture-decision-guide.md` §5 for which form to pick |
| N §Variance axes | — | ⇄ **moved out of the entry file** into `tech/variants/`. In N it was a self-invalidating section requiring manual deletion after confirmation — a guaranteed-drift mechanism |
| E §"Expo has changed — do not trust your training data" | §Verifying against versioned docs *(conditional)* | ⇄ generalised from an Expo-specific warning into a stack-gated section. See `documentation-sources.md` |
| N `opencode.json` (absent) / F `opencode.json` / E `opencode.json` | **not here** | → moved to `target-formats.md`. N shipped **no wiring file at all** — the defect that made the skill generate unusable output |
| F `analysis_options.yaml` (65 lines) | — | ○ lint config is a toolchain file, not a rule. Not templated |
| F `AGENTS.md` claims "Strict 44-rule analysis_options" vs the file's actual 34 | — | ▲ Not carried forward: the template must never assert a count about a tool-generated file. Rule files cite rule *names*, not counts |

### Memory-file templates (emitted alongside the entry file)

| Source | Destination | Note |
|---|---|---|
| F `SESSION_LOG.md` (8-field format) | `SESSION_LOG.md` | ⇄ identical in N. Kept as-is: STARTED FROM / DECIDED / REJECTED / BLOCKED / FILES TOUCHED / STATUS / NEXT SESSION SHOULD / NEXT SESSION SHOULD NOT |
| F `DECISIONS.md` (6-field ADR format) | `DECISIONS.md` | ⇄ with E (Status/Context/Decision/Consequences). Template uses F's fuller 6-field form |
| F `DECISIONS.md` "A decision belongs here when it would otherwise be re-argued every session" | `DECISIONS.md` | → the scope boundary between DECISIONS and SESSION_LOG, which E states and F implies |
| F ADR-005 "priority order referenced from every rule file" | — | ✂ **cut.** Verified false: zero occurrences of "Priorit" or "ADR-" in F's own rule files. A claim in a template that isn't true is worse than no claim |
| F `LEARNINGS.md` format | `LEARNINGS.md` or entry-file §Project Learnings | → whichever `architecture-decision-guide.md` §5 selects |

---

## C2 · `templates/core/architecture.md`

| Source rule | Destination | Note |
|---|---|---|
| F `01` §Layer Rules (domain purity, `data/`→`domain/`, `core/` independent) | §Dependency Direction | ⇄ with N `architecture` §Folder Layout and E `01` §Dependency Direction. **The single most consistent pattern across all three sources**: every one has a layer rule *plus a grep to enforce it* |
| F `01` `grep -r "import 'package:flutter" lib/domain/` | §Dependency Direction (enforcement) | ⇄ with E's `rg 'storefront-api-client\|…' src \| rg -v 'lib/shopify/**'`. Template emits the **shape**; the overlay emits the actual grep |
| F `01` "no circular imports between features" | §Dependency Direction | ⇄ E `01` rule 5, N `architecture` |
| F `01` §Feature Module Pattern + §New Feature Checklist (7 steps) | §New Feature Checklist | ⇄ with N's equivalents. Kept as an ordered checklist |
| N `architecture` "components/ transversal only" | §Centralized Concerns | ⇄ triplicated (N, E `01`, E `07`). One rule |
| E `01` §Centralized Concerns (9-row locked inventory) | §Centralized Concerns | → **best form of the three.** Emitted as a *locked table* the agent fills during generation, not prose. Kept |
| E `01` "the right response to 'this doesn't exist yet' is to add it to the canonical module, not an inline literal — inline literals and parallel copies are violations **even when the module doesn't have it yet**" | §Centralized Concerns | → the sharpest single sentence in any of the three sources. Kept verbatim in spirit |
| F `05` §Reusability Threshold (rule of three) | §Reusability Threshold | ⇄ **quadruplicated**: F `05`, N `architecture`, E `01`, and (as a *reference*) E `07`. E's framing retained: "not 'is this file too big' but 'does this exact thing now exist in more than one place'" |
| F `05` "promoting before it's shared is speculative abstraction — the same anti-pattern as premature file-splitting" | §Reusability Threshold | ⇄ triplicated (F, N, E). Kept |
| N `architecture` "same-domain-only reuse stays in `features/<domain>/shared/`" | §Reusability Threshold | → the 3rd step's placement rule. Kept |
| N `workflow` §File Size (4-band table 0-150/150-200/200-300/300+) | §File Size & Partitioning | ⇄ with E `14` (identical table, copied from N). **Two sources, one table** |
| N "line count is a signal, not a rule — responsibility is the real metric" | §File Size & Partitioning | ⇄ triplicated. Kept |
| N "Split by responsibility, not by lines. Ask: if I change X, should Y also need to change?" | §File Size & Partitioning | → the decision rule. Kept |
| N 5 split signs / 4 refactoring patterns | §File Size & Partitioning | ⇄ with E's shorter list. N's fuller list kept |
| F `05` "~250 lines on a presentation file is a signal" + F `09` rule 33 ("flag over 200, refactor at 300+") | — | ✂ **cut as a third, contradictory threshold.** F alone had two incompatible file-size postures in two files. One table replaces both |
| F `05` "do NOT split artificially just to pass a threshold" | §File Size & Partitioning | ⇄ E `10` "don't mass-refactor working small lists". Kept |
| E `01` rule 3 (import order) | §Conventions | ⇄ N `architecture` rule 3, identical |
| E `01` rule 2 / N rule 2 (`@/` alias, never relative across directories) | §Conventions | ⇄ triplicated. Universal rule, tech-specific *name* → overlay |
| E `01` rule 4 (file naming) | §Conventions | ⇄ N rule 4, F `08` §Code Organization. → moved to `core/coding-standards.md` §Naming (see there) |
| E `01` rule 7 / N rule 7 (barrel exports optional) | §Conventions | ⇄ duplicated. Kept once |
| E `01` rule 6 (data-driven navigation config in layout) | §Conventions | → the universal form of "routes are not strings scattered in screens". Also feeds D-templates |
| E `01` rule 1/23 (screens stay thin) | §Conventions | ⇄ F `05` §UI vs Logic, N `workflow` §Page files. Triplicated |
| E `01` §Version Pins (24-25) | — | ⇄ **moved to the tech overlay.** Version pins are per-stack facts; a core template must not carry them |
| E `01` / N `architecture` §Canonical Example | §Canonical Example | ⇄ triplicated (also F `02`, F `05`, N `redux-toolkit`, N `data-fetching`, E `04`, E `13`). One rule, referenced from every template |
| F `01` `lib/` tree, F `05` widget placement taxonomy, N `architecture` tree, E `01` tree | §Folder Layout | → **not merged.** These are four incompatible folder contracts. The template emits the *slots* (routes / shared components / domain features / shared hooks / lib / config) and the overlay fills each stack's actual paths |

---

## C3 · `templates/core/workflow.md`

| Source rule | Destination | Note |
|---|---|---|
| F `09` §Before Coding (3) + E `14` (4) | §Before Coding | ⇄ E's is fuller (adds the memory-file read). E's form kept |
| F `09` §How to Code (4) + E (4) | §How to Code | ⇄ near-identical. Kept once |
| F `09` rule 7 / E rule 4 ("a project rule conflicts with a user request → implement the request, flag the deviation in the reply") | §How to Code | ⇄ duplicated across two sources. Kept — it is the **only** rule that resolves the agent-vs-user precedence question, and no source states it in the entry file |
| F `09` §Critical Thinking Checklist (5) + E (5) | §Critical Thinking Checklist | ⇄ E's is the adaptation of F's. Merged, E's ordering kept |
| F `09` rule 12 ("external references guide structure and patterns only — never a runtime dependency; check licenses; copy-paste as-is is forbidden") | §Critical Thinking Checklist | ⇄ E rule 4. **The most on-brief rule in any source** — it is the anti-contamination rule stated *inside* the generated ruleset. Kept |
| E rule 5 (Expo doc-access rule) | — | ⇄ moved to the entry file's conditional docs section + `documentation-sources.md` |
| F `09` §Verification (3) + E §Verification Order (4) | §Verification Order | ⇄ merged. **The ordering is the rule**: lint → typecheck → test → (stack health check) |
| F `09` "do not finish with a red tree" / "never commit past a failure" | §Verification Order | ⇄ duplicated. Kept once |
| F `09` §Pre-Commit Review §1-2 (git status/diff, verify-against-rules table) | §Pre-Commit Review | → kept. The 10-row verify-against-rules table is a strong device: it maps *each rule file to what to check*, so the review can't silently skip one |
| F `09` §Pre-Commit §3-6 (auto-fix, checklist, commit-after, session-log step) | §Pre-Commit Review | ⇄ with N `workflow` §Review Checklist (13 boxes) and E (6 steps). Merged |
| F `09` §Rules (11 condensed rules) | — | ✂ **cut entirely.** Rules 25/26/29/30/31/34 restate §Verification and §Pre-Commit Review verbatim. This was a whole redundant *layer* inside one file |
| F `09` §Quick Verification Commands | §Verification Order | ⇄ merged |
| N `workflow` §Automated Checks (grep placeholders) + E's 6 greps | §Pre-Commit Review (grep bank) | ⇄ **E's greps are real and concrete; N's are explicitly self-labelled placeholders.** E's form kept as the model; N's "these are placeholders showing the shape" disclaimer kept as an instruction to the generator |
| N `workflow` §Code Hygiene (5) + F `08` §Code Hygiene (4) + E §Code Hygiene (4) | §Code Hygiene | ⇄ **triplicated near-verbatim.** Collapsed to 6 rules. "No commented-out code" and "comments explain why not what" were word-for-word in N and F |
| N "no unused imports — treat a lint warning as something to fix, not suppress" | §Code Hygiene | → added (N only) |
| N `workflow` §Side-Effects Rule (when to flag / when NOT to flag) | §Side-Effects Rule | → **N only, no counterpart anywhere.** Highest-value unique rule in the three sources: it tells the agent *when a confirmation gate is warranted* and when it is noise. Kept whole |
| F `09` §When to Update Memory Files (9 triggers across 3 files) + E's table form | §Memory File Triggers | ⇄ merged. E's 3-column table is the better form |
| F "a recurring pattern in SESSION_LOG promotes to a LEARNINGS entry so the rule originates from observed failure, not speculation" + E's promotion line | §Memory File Triggers | ⇄ duplicated. Kept |
| F `09` §Escalation + E §When Blocked | — | ⇄ **moved to the entry file** (see C1). Was duplicated in all three sources' workflow files |
| F `09` §File Size & Code Partitioning | — | ⇄ **moved to `architecture.md`** (see C2). Was duplicated in N and E |
| E's `14` header "Adapted from the profiles' `09-agent-workflow.md` / `workflow.md`" + E `02` rule 25's `LoginController.login()` + E `03` rule 17's "per the profiles: no params in shell routes" | — | ▲ **Not carried forward.** These are dangling provenance references; the second is Flutter/Riverpod contamination surviving inside a TypeScript project — `postmortems.md` Case 2 recurring. Generator rule added: a template may never name its own source profile in emitted output |

---

## C4 · `templates/core/coding-standards.md`

| Source rule | Destination | Note |
|---|---|---|
| N `typescript` §Configuration ("tsconfig strict: true — non-negotiable") | §Type Safety | → moved here from N's typescript file |
| N rules 2, 7 + E `09` rules 2, 4 ("no `any`; `unknown` + a type guard at the boundary, never silently widen") | §Type Safety | ⇄ duplicated across N and E. F's equivalent ("no `dynamic`") is the overlay's row |
| N rule 5 / E rule 4 (`// @ts-ignore` to unblock a commit → never) | §Type Safety | ⇄ duplicated. Kept |
| N rule 6 ("`type` for props with `Props` suffix, never `interface`") | §Type Safety | → the *shape* is universal (a props type with a suffix); the *keyword* is TS-specific → overlay |
| N rule 10 / E rule 4 (`AsyncState<T>` discriminated union, "not a pile of optional/boolean flags") | §Type Safety | ⇄ duplicated, and E's is the fuller version. Kept |
| N rules 14-15 (naming table) + E §Naming (8-row table) + F `08` §Code Organization (5-step order) | §Naming | ⇄ **three naming sources merged into one table with a `Consequence` column**, so each row says why it matters. The 5-step in-file ordering moves to §File Organization |
| N rule 13 + F `08` rule 14 + E rule 7 (no magic strings/numbers; "if compared against or branched on more than once → named constant") | §Magic Values | ⇄ **triplicated.** N's formulation is the sharpest ("*compared against or branched on more than once*"). Kept |
| N rule 8 / E rule 3 (`@/` alias) | — | ⇄ **moved to `architecture.md` §Conventions** (C2). Was duplicated in 4 places across N and E |
| F `08` rule 4 ("pin to a real version resolved by the installer, never `latest`") + F rule 5 ("NEVER hand-edit `pubspec.yaml`") + E `09` §Dependencies (`npx expo install` only) + N ("manual thunks, not `createAsyncThunk`" as a closed decision) | §Dependencies | → the **shape** is universal (never hand-edit the manifest; use the ecosystem's installer; never `latest`). The installer command is the overlay's row |
| F `08` rule 7 ("don't add a package 'just for comfort' — justify it; prefer existing patterns first") | §Dependencies | → F only. Kept |
| F `08` §Banned Patterns (18 rows) + N's scattered bans + E's scattered bans | §Banned Patterns | → **shape only in the template**: a `Banned → Use instead → Enforced by` three-column table, **empty**, filled by the overlay. This is what stops every project getting an identical style file |
| F `08` rule 8 rows: `print()`, `json.decode()` by hand, `DateTime.now()` in business logic, magic numbers in layouts, `dart:io` in shared files | §Banned Patterns | → into the Flutter overlay |
| F `08` rule 8 row: "no commented-out code" | §Code Hygiene | ⇄ moved to `workflow.md` (C3) — it was duplicated there too |
| N rule 15 + F `08` §Code Organization (5 steps) + N `testing` "co-locate tests" | §File Organization | → merged. The 5-step in-file ordering (header → imports → constants → classes → functions) is a genuinely useful universal |
| F `08` rule 12 ("comments explain why, not what") + N | §Code Hygiene | ⇄ moved to `workflow.md` (C3) |
| — | §Async state ownership | → the split between a query library's `data/isPending/isError` and the app's `AsyncState` (E `09` rule 4) is a real decision rule; kept as an explicit "map at the hook boundary" instruction |

---

## C5 · `templates/core/security.md`

| Source rule | Destination | Note |
|---|---|---|
| N `security` rule 1 + E `12` §Env Var Scoping ("only publicly-prefixed env vars are client-readable — by construction") | §Secret Scoping | ⇄ triplicated (also F `11`). Kept once, prefix name from the overlay |
| N rule 2 (JWT in one place, the shared client interceptor) + E `12` §Token Storage (SecureStore, centralised in the auth client) + F `11` ("auth tokens handled by the provider's internal secure storage, do NOT persist manually") | §Token Handling | ⇄ three mechanisms, one rule: **one place, never reimplemented per feature** |
| E `05` rules 16-18 (race-guard refresh: single in-flight, others await) | §Token Handling | → E only. Kept: a real, named, non-obvious correctness rule |
| E `05` rule 19 / F `11` ("on logout, invalidate data providers and clear the session context") + N (session cleanup on tab close, `sendBeacon` on `pagehide`, guarded by `event.persisted === false`) | §Session Teardown | ⇄ merged. N's guarded-`pagehide` detail is the sharpest form of "don't false-positive on internal navigation" |
| N rule 3 + E `12` §Client Validation ("client-side validation is UX, not the security boundary") + F `11` (domain validation is the real one, UI validation secondary) | §Validation Is Not the Boundary | ⇄ **triplicated near-verbatim** — N and E are word-for-word. Collapsed to one rule with three sources' phrasing preserved as the reason |
| N rule 4 (single reusable permission guard) + E `12` §Permission Gating (centralised auth guard, not per-screen `if (customer)`) | §Authorization | ⇄ duplicated. Kept |
| N rule 6 (data minimization: `Pick<User, "id" \| "name">` not a full entity) + E `12` §Data Minimization ("query only what the screen shows — no `SELECT *`") + F `11` (no personal data persisted without consent; purge local data in settings) | §Data Minimization | ⇄ three sources, one rule, both directions (over-fetch and over-persist) |
| N DoD 3 + E `12` §Logging + F `11` ("never log tokens") | §Logging | ⇄ triplicated. Extended with E's specific list (auth codes, `state`/`code_verifier`, full PII) and E's allowance (error *codes* are fine, PII is not) |
| N "never commit a `.env`" + E (`.env` gitignored, `.env.example` with placeholders) + F `11` | §Environment Files | ⇄ triplicated. `.env.example` discipline is E's addition |
| N "blocked: a server-side secret seems needed → **stop**; don't rename the var to make it work" + E `12` §When Blocked (identical) | §When Blocked | ⇄ **near-verbatim across two independent sources.** The single best escalation rule in security. Kept |
| N "rate limiting belongs on the backend, not the client" | §Authorization | → N only. Kept |
| N rule 5 (CSP headers) | §Response Hardening | → N only. Kept, marked as applying only where the stack owns response headers |
| E `12` §Banned (5 rows) | §Banned | → the rows; the shape comes from `coding-standards.md` §Banned Patterns |
| E `04` §Tokens ("the day a private token is genuinely required is the day a backend is introduced — that requires a new ADR, **not a config tweak**") | §When Blocked | → E only, and it is the correct escalation shape: the answer to "I need a secret" is an ADR, not a workaround |
| E `05` §Banned rows (never hand-roll a login form; never log the `code`/`state`; never reuse a `state`/`code_verifier` across attempts) | §Banned | → E only. Protocol-level; the auth overlay carries them when a stack has an auth flow |

---

## D1 · `templates/domain/data-and-state.md`

| Source rule | Destination | Note |
|---|---|---|
| F `04` §Repository Pattern (interface in domain, impl in data) + E `04` §Data-Access Flow (screen→hook→client) + N `data-fetching` placement table | §Mandatory Access Shape | ⇄ **three mechanisms, one rule.** The template emits the *layer count* (UI → orchestration → data) and the overlay fills the names. Highest-value merge in the library |
| F `04` rules 3, 9-12 (`Result<T>`, "never throw from a repository", `FailureCode` enum, "UI translates `FailureCode` to user-facing messages, never raw error strings") + E `11` (`AppError` union) + N (normalise backend errors at the point of receipt) | §The Normalized Error Type | ⇄ **triplicated.** Template emits the contract (one error type, crosses the boundary once, UI never sees a raw error); the overlay supplies the type |
| F `04` rule 14 + E `04` §Normalizers + N ("test behavior at the boundary") | §Normalizers / Mappers | ⇄ F's mappers and E's normalizers are the same operation. One rule: `normalize<Model>(raw) → Model`, one function per model, colocated, pure |
| E `04` rule 21 ("keep nullability honest — **the normalizer is where a null becomes a fallback**, not in screens") | §Normalizers / Mappers | → E only, and it is the best single sentence about normalizers in any source. Kept |
| N `data-fetching` rule 4 + E `04` rule 6 ("one client instance, configured once, never a second instance with different config") + F `04` rule 15 (backend chosen by a provider, domain never knows which) | §The Single Client | ⇄ triplicated. Kept |
| E `04` rule 7 ("read config once, fail loudly at startup if unset — don't ship a dead client") | §The Single Client | → E only. Kept |
| **F `04` rule 18 + N `data-fetching` rules 8-11 + E `04` rules 24-26 + E `08` rules 14-16** | §Search: Debounce vs Submit | ⇄ **quadruplicated, and Elora duplicates it internally** (`04` §Search and `08` §Filter & Search say the same thing). Collapsed to one decision rule with all three sub-rules (debounce 300–500 ms, stale-response guard, reset pagination) kept |
| N "don't apply this reflexively — **confirm the real latency first** rather than assuming" + F's "confirm actual latency before assuming either case; don't guess" | §Search: Debounce vs Submit | ⇄ the anti-reflexivity guard, present in both sources independently. Kept — it is what stops the rule becoming cargo-cult |
| **F `04` rule 21 + N `redux-toolkit` rules 9-10 + E `02` rules 14-18** | §Mutations: Optimistic vs Wait-for-Response | ⇄ **triplicated, near-verbatim.** F and N share the same decision criteria (low-stakes/high-frequency vs real consequences) and the same tie-breaker: **"if genuinely unsure, default to wait-for-response — it's the safer failure mode"**. Kept |
| F "log the mutation choice in `DECISIONS.md` if significant enough that a future session might second-guess it" + N's identical line | §Mutations | ⇄ duplicated. Kept |
| E `02` rule 17 ("never leave the cache lying — an optimistic mutation must pair `onMutate` with `onError` rollback and `onSettled` revalidate") | §Mutations | → E only. The structural completeness requirement for an optimistic update. Kept |
| E `02` rule 18 ("mutate through the mutation hook only — never write to the cache 'to make the UI feel fast' outside a proper optimistic pattern") + rule 26 ("never `queryClient.clear()` to refresh everything as a fix") | §Mutations | → E only. Two named anti-patterns. Kept |
| E `02` rule 20 ("cart mutations are serial per line — don't fire two concurrent updates for the same line") | §Mutations | → E only, but the **shape** (concurrent mutations on the same entity must be serialised or disabled) is universal. Kept, de-Shopified |
| F `02` rules 2.7 / E `02` rule 13 / N ("explicit invalidation, named helpers for cross-cutting cases") | §Cache Invalidation | ⇄ triplicated. Kept |
| E `02` rule 9 ("never put unbounded user input in a key when a stable identifier exists") + rule 8 ("invalidate by prefix, never by full-key guesswork") | §Cache Invalidation | → E only. Kept |
| E `02` rule 10-11 (set a real global `staleTime`; "don't leave everything at default and don't set per-hook `staleTime: 0` reflexively"; "`gcTime` default is fine, don't tune until a measured problem") | §Cache Invalidation | → E only. Kept |
| F `02` §Provider Selection Guide (6 rows) + N `redux-toolkit` §Shared vs Local (3 rows) + E `02` §Shared vs Local (5 rows) | §Shared vs Local State | ⇄ **triplicated, three different tables.** Merged into a single 5-row table: *what kind of state* → *where it lives*. The library column is the overlay's |
| F `02` rule 2.4 / E `02` rule 24 ("no global store unless a concrete need is proven — then write an ADR first") | §Shared vs Local State | ⇄ duplicated. Kept |
| E `04` rules 9-10, 14-15 (mutations must request and check `userErrors`; check `data.errors` AND `userErrors` AND `extensions.code`; "a mutation is not successful until `userErrors` is empty") | §Mutation Success | → E only, but the **shape** (a 2xx response is not a successful mutation; check the payload's own error channel) is a universal contract rule. Kept, de-Shopified |
| E `04` rules 11-12 ("pagination always uses `edges { node }` + `pageInfo`"; "a connection is a collection, not a list") | §Collections | → E only. The second half is a universal modelling rule. Kept |
| E `04` rules 13, 17 (fragments for shared fields; market/locale via client options, never hardcoded in a query) | §Collections / §Query Hygiene | → E only. Kept |
| E `02` rule 27 ("auth state drives redirects, not the reverse") | — | ⇄ **moved to the auth/routing overlay.** It is a routing rule, not a data rule |
| E `02` rule 4 / E `04` rule 23 ("screens never call the client directly and never hold server data in local state; if no hook provides the data, **write the hook**") | §Mandatory Access Shape | ⇄ duplicated. Kept — it closes the "just this once" loophole |
| E `02` rule 29 ("if the query library isn't installed yet, install it — don't fall back to `useEffect`+`useState` fetching as a permanent pattern") | §When Blocked | → E only. Kept |
| F `04` rule 16 + N (never raw `fetch` when a configured client exists) | §The Single Client | ⇄ triplicated |

---

## D2 · `templates/domain/errors-and-loading-states.md`

| Source rule | Destination | Note |
|---|---|---|
| N `error-handling` rule 3 + E `11` rule 3 + F (`AppAsyncValueBody` replaces per-page `when(data:, loading:, error:)`) | §Never Swallow | ⇄ **triplicated near-verbatim** ("no empty `catch`; no error logged but the UI shows nothing; the user always sees that something failed"). Collapsed to one rule |
| N DoD 3 + E `11` rules 1-2 + F `05` §Async List States | §The Four States | ⇄ triplicated. Merged: loading / error / empty / success, "nothing that looks like loading forever on failure". F's "skeleton matching the list item shape, not a random spinner" and E's shared-component rule are both kept |
| F `05` "do not manually write `isPending ? … : isError ? …` in every screen — use the shared component" + E `07` §Async List States | §The Four States | ⇄ duplicated. Kept |
| F `05` rule 5.9 / E `07` §Mutation Buttons ("loading indicator **on the submit button**, never replace the entire screen body with a loader mid-form"; disable while in flight) | §Mutation Feedback | ⇄ duplicated. Kept |
| E `11` rule 5 ("inline error next to the form/button, not a screen-replacing error") | §Mutation Feedback | → E only. Kept |
| N `error-handling` rules 4-7 (`error.tsx` per route segment; rely on a parent's boundary rather than duplicating boilerplate; `not-found.tsx` for dynamic segments; `loading.tsx` only for genuinely slow fetches) | §Recovery Surfaces | → N only, but the **rule** (a recovery surface per failure kind, and don't duplicate an inherited one) is universal; the file names are the Next overlay's. Kept |
| N rule 8 / E `11` §User-Facing Messages ("show a user-friendly message — never a raw stack trace or backend internals"; E adds "the raw message is English, technical, and sometimes empty") | §User-Facing Messages | ⇄ duplicated. Kept |
| E `11` ("keep technical detail — code, original message — for logged diagnostics, but never log tokens/PII") | §User-Facing Messages | → E only. Kept: it resolves the "lose the detail vs leak the detail" tension |
| **N `error-handling` rule 2 + E `11` §When Blocked + E `02` rule 28 + E `04` rule 27 + E `05` rule 28 + E `08` rules 18-19 + E `10` + F's `§When Blocked` in 8 of 11 files** | §When Blocked | ⇄ **the most repeated rule across all three sources, ~15 occurrences.** Collapsed to one canonical statement: *stop, capture the exact response, report it, confirm the real shape before normalizing — do not invent a workaround and do not guess a threshold.* Every individual instance is a specialisation of it |
| E `11` rule 6 ("`THROTTLED` → surface 'try again in a moment'; never auto-retry in a tight loop") | §Retry Policy | → E only, de-Shopified to "never auto-retry a rate-limit in a tight loop". Kept |
| E `11` rule 45 ("never silence a failing fetch with `retry: 0` + a fake empty-state 'to ship faster' — that hides the failure, that's a bug wearing a UI") | §Retry Policy | → E only. Kept — a named anti-pattern with a memorable justification |
| E `11` rules 39-40 (invalid dynamic param → not-found state, not a crash; a render-time boundary is the only place a raw render error may surface) | §Recovery Surfaces | ⇄ with N. Kept |
| E `12` §When Blocked (SecureStore failure → report the exact error, do not fall back to a less secure store "temporarily") | §When Blocked | → E only, de-Securestored. Kept as a general rule: never fall back to a less-safe mechanism to unblock |

---

## D3 · `templates/domain/forms.md`

| Source rule | Destination | Note |
|---|---|---|
| N `typescript` rules 15-16 + N `forms` rule 4-5 + E `08` rules 1-2 | §The Schema Is the Source of Truth | ⇄ triplicated. All three agree: schema co-located, type **derived** from it, "no hand-written duplicate shape". Kept |
| N `forms` rule 12 (Formik not Redux Form not RHF "unless the project explicitly decided otherwise and logged it in `DECISIONS.md`") + E `08` rule 20 ("form library — none until one is adopted") | §Library Discipline | ⇄ the two sources take opposite defaults (N picks one, E defers) but the *rule* is identical: **the choice is a logged decision, not a per-form judgment call.** Template states the rule; the overlay states the default |
| N `forms` rule 5 (`validateWithZod` — "reuse the existing helper, don't hand-roll a second bridge") | §The Schema Is the Source of Truth | → N only. Kept: one bridge, never two |
| N `forms` rule 9 (`validateOnBlur: false, validateOnChange: false` at form level; opt individual fields in only where earlier feedback genuinely helps) + E `08` rule 3 (validate on submit, and on change only *after* a failed submit) | §Validation Timing | ⇄ duplicated, with E's refinement (the "after a failed attempt" clause is strictly better). E's version kept |
| N `forms` rule 10 ("filter/search schemas stay **forgiving** — optional fields with safe defaults, so `safeParse({})` still passes") | §Validation Timing | → N only. Kept |
| N `forms` rule 8 + E `08` rule 4 (disable submit while in flight; never allow a double submit) | §Double Submit | ⇄ duplicated. Kept |
| N `forms` rule 7 ("error text shown inline below the field") + E `08` rule 5 ("server errors map `userErrors` field/message back onto the matching inputs — a submit that fails must show *why*") | §Server Errors | ⇄ duplicated. E's field-mapping requirement kept |
| N `forms` rule 11 + E `08` rule 6 ("mirror backend constraints in the schema — **confirm the actual limit first, don't guess it**; the client validates for UX, the API is the security boundary") | §Mirror Real Constraints | ⇄ duplicated. Kept |
| E `08` rule 7 ("no string-built queries — never concatenate user input into a GraphQL query or `query:` filter") | §§Never Build Queries From Input | → E only. Kept |
| E `08` rule 4 ("login is NOT a form — auth is delegated to the provider's hosted login") + E `06` rule 1 ("never a custom payment UI") | §Not Forms | → E only. Kept as a universal: **never build a form for something a provider already owns** (auth, payment, address autocomplete) |
| E `08` rule 12 (inputs stack one per line on a phone-width form; `returnKeyType="next"` chain; the **last** field submits — *unless* the data is critical (payments, destructive, auth), where an explicit submit button is mandatory; the visible button always stays the primary path) | §§Field Layout & Keyboard | → E only, mobile. Kept in the accessibility template's keyboard section (see D5) — it is a keyboard-flow rule, not a form-state rule |
| E `08` rule 15 ("filters apply on explicit apply, not on every chip toggle, if the backend round-trip is slow — keep the draft in local state and commit on submit") | §Validation Timing | → E only. Kept |
| N `forms` rule 14 ("validation messages in the project's working language — **confirm which**; this is a UI-copy decision, not a technical one") | §When Blocked | → N only. Kept: it correctly identifies a class of decision as *not* the agent's to make |
| N `forms` DoD 4 (`aria-invalid` / `aria-describedby`) | — | ⇄ **moved to `accessibility.md`** (D5). Was a cross-file duplicate |
| N `forms` rules 1, 3, 6, 13 (bans on Server Actions / `app/api/`) | — | ⇄ **removed from the domain template entirely.** These are *closed project decisions* (N's ADR-001), not universal form rules. They belong in the generated project's `DECISIONS.md` and its tech overlay, never in a reusable template |

---

## D4 · `templates/domain/ui-components.md`

| Source rule | Destination | Note |
|---|---|---|
| F `05` rules 5.2-5.4 (theme tokens only; no `Color(0xFF…)`; no `TextStyle()` literals) + E `07` rules 3-5 (all colour/font/spacing/radius from the theme module; no hex literals; "a one-off numeric style is a code smell — promote to a token after the second use"; semantic tokens resolve per scheme) | §§Design Tokens | ⇄ duplicated. E's "after the second use" threshold and "fix the token, not the screen" kept |
| N `components` rule 4 ("all UI primitives from the library — **never build custom UI when the library already provides it**") + E `07` rule 9 (`@expo/ui` over RN built-ins and community libs when it covers the need) | §Primitives Over Custom | ⇄ duplicated. Kept |
| E `07` rule 10 (a specific named gotcha: the library's `List` is **not** a virtualized list) | §Primitives Over Custom | → E only, de-Shopified into the RN overlay as a named footgun. Kept as a row in the overlay's footgun table |
| F `05` rule 5.10 (widget placement taxonomy: page / controller / feature widget *only if used by >1 page in the feature* / shared widget *only if used across features*) + N rule 1 (`components/` transversal only) + E `01` rule 1 | §Component Placement | ⇄ triplicated. Merged into the taxonomy table |
| F `05` rules 5.11-5.13 (pages contain only composition + watch + action; logic lives in controllers; forbidden in pages: large callbacks, business try/catch, heavy transforms, direct data access) | §Thin Screens | ⇄ with E `01` rule 23 and N `workflow` §Page files. Triplicated |
| F `05` rule 5.19 ("prefer Material over Cupertino — pick a deliberate platform stance and keep it") + E `07` rule 19 ("don't fight the platform's native defaults; if the UI must differ per platform, **branch explicitly in the component**, not with duplicate whole screens") | §Platform Stance | ⇄ duplicated. Kept |
| E `07` rules 16-17 (never scroll the focused field out from under the keyboard; `keyboardShouldPersistTaps` so a button is tappable with the keyboard up) | — | ⇄ **moved to `accessibility.md` §Keyboard Flow.** Was a cross-file duplicate |
| E `07` rule 18 (respect safe areas; never hardcode top padding) | §Platform Stance | → E only, RN overlay |
| E `07` rules 20-22 (motion: small and purposeful; respect reduced motion; no gratuitous looping animation on content the user is reading) | §Motion | ⇄ with F `05` rules 5.23-5.26. Merged |
| F `05` rule 5.26 ("do NOT add `Hero`, skeleton screens, or `shimmer` without explicit justification — project consistency") + F rule 5.25 (prefer `AnimatedSwitcher`; reuse established durations/curves, "do not invent new values per animation") | §Motion | → F only. Kept as "reuse the established motion vocabulary; add a new pattern only with justification" |
| N `components` rule 8 (`lucide-react` only, individual imports, "no second icon library introduced ad hoc") | §Single Vocabulary | → N only, but the **rule** (one icon set, one styling system) is universal. Kept |
| E `07` rules 30-32 (user-facing strings in one module; **strings are keys, not phrases**; messages built with parameters, never sentence interpolation at the call site; money through a single formatter) | §User-Facing Values | ⇄ with F `08` rule 13 (centralize formatting) and N. Kept, and it feeds `i18n.md` |
| N `components` rules 10-11 (the `SelectValue` value-vs-label quirk **plus** the "confirm whether this project's actual primitive has this behavior before assuming it does — don't copy this pattern reflexively" guard) | §Anti-Reflexivity | → N only, and the guard is the valuable half. Kept as a named principle: **a documented quirk is not a universal truth — verify it against this project's actual primitive** |
| E `07` rule 33 ("if a desired UI piece has no library counterpart — **check the versioned docs before inventing a custom implementation**") | §Anti-Reflexivity | ⇄ with N. Kept |
| E `07` rule 34 ("if a component's visual spec contradicts a token or a11y rule — flag it in the reply rather than silently overriding the rule") | §§When Blocked | → E only. Kept — it is the rule that prevents silent rule-breaking under UI pressure |
| N `components` rule 9 (`next/dynamic` with `ssr: false`) + N `performance` rule 9 | — | ⇄ **moved to `performance.md`** (D7). Was a cross-file duplicate |

---

## D5 · `templates/domain/accessibility.md`

| Source rule | Destination | Note |
|---|---|---|
| N `accessibility` rule 1 (semantic HTML first — `<button>` not `<div onClick>`, landmarks) + F `05` rule 5.5 (`Semantics(label:)` on every interactive widget) + E `07` rule 23 (`accessibilityRole` + `accessibilityLabel` or visible text) | §Role and Label | ⇄ **triplicated.** Merged: every interactive element has a role and a label |
| N rules 2-3 (every input has a label; `aria-invalid` + `aria-describedby` wired to the error) + E `07` rule 15 (`accessibilityLabel` tying the input to its label) | §Form Fields | ⇄ triplicated (also N `forms` DoD 4, moved here). Kept once |
| N rule 4 (keyboard: Tab reachable, Enter/Space to activate, `onKeyDown` for custom interactive elements) + N rule 5 (visible focus rings, logical tab order, focus returns to the trigger after a dialog closes) | §Keyboard | → N only. Kept |
| E `08` rules 12, 16-17 (one field per line on a phone; `returnKeyType` chain field-to-field; last field submits *unless* the data is critical, where an explicit button is mandatory; the visible button is always the primary path; never scroll the focused field under the keyboard; `keyboardShouldPersistTaps`) | §Keyboard (mobile) | → E only, but it's the **mobile** half of the keyboard rule the N source covers for web. Merged as a platform-tagged subsection — the single best example of why tech overlays are section-tagged rather than separate files |
| N rule 6 (`aria-live="polite"` for dynamic updates; `role="alert"` + `aria-live="assertive"` for errors) + E `07` rule 25 (announce changes rather than silently mutating) | §Dynamic Updates | ⇄ duplicated. Kept |
| N rule 8 (WCAG AA minimum: 4.5:1 normal, 3:1 large; checked in both themes) + E `07` rule 26 (tokens chosen to clear AA in both schemes; **"don't override with a slightly-different hex to fix one screen — fix the token"**) | §Contrast | ⇄ duplicated. Kept |
| N rule 9 (alt text meaningful; `alt=""` + `role="presentation"` for decorative) + E `07` rule 27 | §Images | ⇄ duplicated. Kept |
| N rule 10 + E `07` rule 29 ("UI-library primitives already carry platform semantics — don't strip them"; "don't fight native a11y") | §Native Semantics | ⇄ duplicated. Kept |
| N rule 10's second half ("verify the specific primitive's a11y behavior against the library's own docs rather than assuming shadcn's patterns transfer prop-for-prop to a different library") | §Anti-Reflexivity | ⇄ N `components` rule 11, E `07` rule 33 — **three sources state the same guard.** Promoted to its own rule |
| N rule 7 (`prefers-reduced-motion`) + E `07` rule 21 (`AccessibilityInfo.isReduceMotionEnabled`) | §Reduced Motion | ⇄ duplicated, two platform mechanisms. Kept as one rule, two rows |
| E `07` rule 24 (`accessibilityState` for disabled/selected/checked; **never colour alone as the only signal**) + N rule 4 (DoD) | §State | ⇄ duplicated. Kept |
| E `07` rule 26 (touch targets ≈ platform minimum) + F `05` rule 5.6 (`testerSemantics` in widget tests) | §Touch Targets / §Verification | ⇄ E + F. The 44pt figure is the overlay's (platform constant), the rule is universal |
| E `07` rule 28 (group related items into one accessible element when a screen reader would otherwise read them piecemeal) | §Grouping | → E only. Kept |
| F `05` rule 5.27's last item + E's "New Widget Checklist" pattern | §New Component Checklist | ⇄ F's 5-step + E's. Merged |
| N `accessibility` §Canonical Example | §Canonical Example | ⇄ universal convention. Kept |

---

## D6 · `templates/domain/testing.md`

| Source rule | Destination | Note |
|---|---|---|
| F `06` DoD (4) + N `testing` DoD (2) + E `13` DoD (3) | §Definition of Done | ⇄ triplicated. Merged. All three share: suite green + ≥1 test on the primary path for new/changed logic + nothing skipped |
| F `06` rule 6.2 ("every new public method on a controller has ≥1 test"; "every mapper has a round-trip test (model → row → model)"; "covers the normal case **plus at least one error/edge case**") + E `13` rule 2 | §Definition of Done | ⇄ the round-trip requirement and the error-case requirement are F/E additions to N's weaker version. Merged, stronger form kept |
| N `testing` rules 1-2 + F `06` rule 6.16 + E `13` rule 1 | §Naming and Structure | ⇄ triplicated. F's naming rule (file `<thing>_test`; group = class under test; **test = a descriptive sentence starting with an action verb — "returns", "throws", "preserves"**) is the most concrete. Kept |
| N rule 1 + E rule 1 + F | §Behaviour, Not Implementation | ⇄ triplicated ("don't assert that `useState` was called"). Kept |
| N rule 3 + E rule 2 + F `06` rule 6.11-6.12 | §Mock at the Boundary | ⇄ triplicated, three different mocking philosophies (mock the module, mock the client, no mocking libs at all). Template states the *rule*; the overlay states the policy |
| N rule 4 + E rule 3 (co-locate) + F `06` rule 6.13 (`group()` + `test()`, `testWidgets` only for actual rendering) | §Naming and Structure | ⇄ duplicated. Kept |
| N rule 5 + E rule 5 (validation schemas tested directly) + F `06` rule 6.15 (mappers round-trip; value objects; controllers; domain logic; error mapping; routing) | §What to Test | ⇄ F's 6-row category table is the most complete. Kept, extended with N/E's schema and mapper rows |
| N rule 4 + F `06` rule 6.18 ("never skip a failing test with `skip: true` to make CI green" / "never delete or skip a failing test to unblock a commit") + E rule 47 | §Never Greenwash | ⇄ **triplicated, near-verbatim.** Collapsed to one rule with the strongest phrasing |
| N rule 3 + E rule 46 ("if adopting the runner itself fails: **stop and report the exact error** — don't work around it by 'tested manually and it's fine' permanently") | §When Blocked | ⇄ duplicated. Kept |
| N rule 6 + F `06` rules 6.4-6.7 | §E2E Scope | ⇄ duplicated. Merged: **critical user journeys only** (auth, primary feature flow, navigation shell); grows from observed regressions; "if a behaviour can be verified with a unit/component test, write that instead" |
| F `06` rule 6.6 ("keep the suite small enough to finish in ~30 min on CI"; "large E2E suites are slow and flaky") | §E2E Scope | → F only. Kept, with the figure as a project decision |
| N rule 7 ("backend-latency-aware E2E: generous timeouts, unique test data via `Date.now()` suffix to avoid unique-constraint collisions, confirm string-length limits before generating test data") | §E2E Scope | → N only. Kept — a real, non-obvious, named failure mode |
| N rule 8 ("pick a coverage target appropriate to this project and **confirm it in `AGENTS.md` rather than leaving it unstated**") | §Coverage | → N only. Kept |
| N `testing` §Framework/Environment Gotchas (ESM `package.json` + Next Jest preset → `jest.config.cjs`; jsdom needs `ResizeObserver` polyfill) + N's triage rule ("if a run fails for a reason that looks environmental rather than logical, check the runner's own docs before assuming the test is wrong") | §§Environment vs Logic | → N only, and it is the densest real anecdote in any source. Kept as a **named triage rule** + an overlay footgun row |
| F `06` rule 6.17 ("add print-debugging to the test, run it, identify the state, then remove the print") | §When Blocked | → F only. Kept |
| F `06` rules 6.9-6.10 (do not add Patrol/Maestro unless a flow needs native interaction; `flutter_driver` is deprecated) | §Banned | → F only, into the Flutter overlay |
| N `testing` header + E `13` header ("if this project has no test script, adding one is a **prerequisite** for the 'tests pass' DoD line to mean anything — flag the gap rather than silently treating tests as optional forever") | §Status Gating | ⇄ **near-verbatim across N and E.** The most important mechanism in this file: it stops the DoD from degrading into a fiction. Kept as the file's opening status block |
| E `13` §Interim Gate (manual smoke on a dev build until a runner exists; "manual smoke is **not** a substitute for tests — it's the best available gate today") | §Status Gating | → E only. Kept — it defines the honest interim position |

---

## D7 · `templates/domain/performance.md`

| Source rule | Destination | Note |
|---|---|---|
| F `10` §Tooling Rule ("profile frames/memory/CPU"; "run a specific perf check → **None — measure, don't guess**") + E `10` header ("**measure before optimizing**") + N `performance` (bundle size visible in build output) | §Measure, Don't Guess | ⇄ **triplicated, and it is the file's founding principle.** Promoted to the file's opening statement |
| F `10` rule 10.5 (lists <20 items → `Column` fine; ≥20 or potentially large → lazy) + E `10` §Lists (<~20 → `map` fine) + N (large list pages) | §List Thresholds | ⇄ duplicated across two sources with the same ~20 threshold. Kept, threshold stated as a project decision |
| F `10` rule 10.7 + E `10` ("don't mass-refactor working small lists into lazy lists without a measured slowdown") | §List Thresholds | ⇄ duplicated. Kept — the anti-over-optimisation counterpart |
| E `10` (stable `keyExtractor`, never the index; fixed heights where uniform; cheap rows; **no nested VirtualizedLists**) | §List Thresholds | → E only, four named rules. Kept |
| F `10` rules 10.15-10.17 + E `10` §Images (always specify dimensions; `cacheWidth`/`cacheHeight`; request the rendered size, never full-size assets into a thumbnail) + N `performance` rules 5-6 (`next/image`, `next/font`) | §Images and Fonts | ⇄ triplicated. Kept |
| E `10` ("with React Compiler enabled, hand-added memoization that fights the compiler is noise — **measure first, memo only what's measured**") + F `10` rule 10.9 (`.select()` to narrow rebuilds) + N rule 10 ("memoize expensive computations — **not reflexively on everything**") | §Memoization | ⇄ triplicated. Kept |
| F `10` rules 10.2-10.4, 10.8 (const everywhere; shallow widget tree; avoid `MediaQuery` per row; avoid `ref.read` in build) + N ("Server Components reduce client JS") | §Rebuild Cost | ⇄ platform-specific mechanisms, universal principle. Kept as principle, mechanisms to the overlays |
| F `10` rule 10.13 (autoDispose page-scoped providers) + E `10` ("keep heavy screens lazy — don't pre-load screens that aren't visible") | §Code Splitting | ⇄ duplicated. Kept |
| N rule 3 + rule 9 ("dynamically import a genuinely heavy dependency — don't add it to a page's top-level import and let it bloat every load of that route") | §Code Splitting | ⇄ with F/E. Triplicated. Kept |
| N rule 4 ("**never disable image optimization to work around a one-off sizing issue — fix the sizing**") | §Images and Fonts | → N only. Kept — a named anti-pattern |
| N rule 11 ("pick a per-page gzipped budget appropriate to this project — a few hundred KB is a reasonable starting point — and check it when a page grows noticeably heavier") | §Budgets | → N only. Kept |
| N rule 12 (the `min-w-0` flex-child overflow footgun: "a flex child without an explicit `min-w-0` can silently refuse to shrink below its content's natural width, breaking horizontal overflow/scroll; if a table overflows unexpectedly, **this is one of the first things to check**") | §Named Footguns | → N only, but it is the **standard for what a footgun entry looks like**: a named, checkable, concrete fact. It becomes the model the overlay footgun tables are held to |
| E `10` §When Blocked ("reproduce on a dev build, capture the profiler trace — **don't shotgun memoization across the app because 'lists are slow'**") + E `10` (cache policy defaults are fine; don't disable caching to fix a one-off) | §When Blocked | ⇄ with N. Kept |
| F `10` §Commands ("run a specific perf check → none") | — | ⇄ **cut as a section.** It's the Measure-Don't-Guess principle restated as a table row. Absorbed |
| N `performance` rule 8 (Server Components reduce client JS) | — | ⇄ **moved to the Next overlay.** Mechanism, not principle |
| N `components` rule 9 (`next/dynamic`) | — | ⇄ **moved here from `ui-components.md`** (D4). Was a cross-file duplicate |
| E `10` §Media & Fonts ("`expo-font` loads the app font once at startup — don't dynamically load/reload fonts per screen"; "placeholders that re-render per row can hurt more than they help") | §Images and Fonts | → E only, RN overlay |

---

## D8 · `templates/domain/i18n.md`

| Source rule | Destination | Note |
|---|---|---|
| F `07` rules 7.3, 7.5 ("every new user-facing string must be added to the template ARB **first**"; `context.l10n.x` — never hardcode a user-facing string) + E `07` rule 30 (user-facing strings live in one localizable module; **no user-facing string literals inline**) | §One Source | ⇄ duplicated. Kept |
| E `07` rule 31 ("**strings are keys, not phrases** — `strings.product.addToCart`; messages built with parameters, `strings.cart.lineCount(count)`; never string interpolation of whole sentences at the call site") | §Keys Not Phrases | → E only, and it is the rule that makes translation possible at all. Kept |
| F `07` rule 7.7 ("no string interpolation in ARB keys — use ICU in the value: `"Hello {name}"` with `name` as a parameter") | §Keys Not Phrases | ⇄ the same rule at the file-format level. Kept |
| F `07` rules 7.1, 7.4 ("run `flutter gen-l10n` after **ANY** change to `.arb`; the generated files must be committed — **this is not optional, if you forget the build will fail**") | §Regenerate | → F only, but the **shape** (generated output is committed and regeneration is a mandatory step, not a convenience) is universal. Kept, generator name to the overlay |
| F `07` rule 7.8 ("two-language minimum — every string in the template + ≥1 translation; use the template value as fallback if not yet translated") | §Coverage | → F only. Kept as a project decision |
| F `07` rule 7.2, 7.10 (ARB location, template file = source of truth, `l10n.yaml` config) | §Source and Translations | → F only, the overlay's rows |
| F `07` rule 7.9 (feature-scoped l10n extension wrapping the generated localisations) | §Source and Translations | → F only. Kept as an option, not a mandate |
| F `08` rule 13 (centralize formatting: dates/currency/numbers through one shared utility; "if two widgets format a date the same way, that's the '2nd occurrence' case — extract it") + E `07` rule 32 (money through the single currency formatter; never `` `${price}€` `` ad hoc) | §Formatting | ⇄ duplicated. Kept |
| — | §Selection | → the Next profile has **no i18n rules at all**. This template fills that gap; selection is triggered by the detection table, not by a framework |

---

## D9 · `templates/domain/design-system.md`

| Source rule | Destination | Note |
|---|---|---|
| E `DESIGN.md` (a 12 KB front-matter contract: name, description, 21 named colours, 6 type roles with font/size/line-height/weight/tracking) + `src/constants/theme.ts` + `.impeccable/design.json` | §The Design Contract | → **the mechanism, not the content.** The template says: *locate the project's design contract, reference it by path, never restate it.* No template ships a palette |
| E `07` rules 3-5 (tokens only; never redefine an existing token in a feature file; semantic tokens resolve per scheme, never a hardcoded dark-mode colour inside a component) | §Token Discipline | ⇄ with F `05` rules 5.2-5.4. Kept |
| E `07` rule 3 ("a one-off numeric style is a code smell — **promote to a token after the second use**") | §Token Discipline | → E only. The threshold. Kept |
| E `07` rule 28 / N `accessibility` rule 8 (contrast is a property of the token; fix the token, never override with a near-miss hex for one screen) | §Contrast | ⇄ moved here from `accessibility.md`. **Boundary call:** the *rule* ("fix the token") is a design-system rule; the *measurement* (4.5:1) is an a11y rule. `accessibility.md` keeps the measurement and references this file |
| E `07` rule 7 (`components/ui/` = reusable wrappers around the platform primitives) + N `components` rules 4-6 (primitives from the library; styling through the design system, not inline; `cn()` for conditional classes) | §Primitives | ⇄ duplicated. Kept |
| — | §Where New Values Go | → **new rule, no source.** E's `DESIGN.md` exists but no rule file says what happens when a screen needs a colour that isn't in it. The template requires: add it to the contract, with the contract's own naming convention, then use it — otherwise the contract silently diverges from the code |
| — | §§Approval | → **new rule, no source.** E has a rich contract and no stated process for changing it. The template requires an explicit route (who approves a new token, and whether it is a project decision needing an ADR) |
| F `05` rule 5.2 (`ThemeExtension` in `app/theme/`) + E `07` rule 1 (`@expo/ui` + `expo-symbols` themed by tokens) | §§Where the Contract Lives | → the mechanism names are the overlays' rows |

---

## D10 · `templates/domain/external-system-contracts.md`

| Source rule | Destination | Note |
|---|---|---|
| N `backend-contracts.md` (the ancestor: "**starts empty by design** — do not pre-fill it with hypothetical rules"; "populate only from confirmed findings — investigating the actual backend behavior … never from assumptions") | §§The File Starts Empty | ⇄ Elora's version is the same idea, better argued, and with 13 real entries proving the value. **E's version kept**; N's is the source |
| N "this is exactly what Principle 1 calls 'operational' even though it reads as a sentence with no command: *'is X acceptable or not'* about a specific payload shape is a decision rule an agent could easily get wrong" | §§The File Starts Empty | → N only. Kept: it defends the file against the "it's just prose, cut it" failure |
| E header ("known, documented quirks belong in the domain rule files; this file is for things a session discovered the hard way that would silently repeat") | §§Promotion Rule | → **the missing half of N's design**, and the fix for Elora's own defect. Kept as a first-class section |
| E header + N (the two entry-criteria lists, merged) | §When to Add an Entry | ⇄ N's 4 criteria + E's 4 criteria, merged into 5. Both versions independently required confirmation against a real source |
| N entry format + E entry format | §Entry Format | ⇄ E's is fuller (adds "When found" and "against what version"). Kept |
| N "keep entries at the level of specificity of 'PUT = full entity replacement, sending only changed fields nulls out the rest' — a concrete, checkable fact about **this** backend, not a generic REST platitude" | §Entry Format | → N only. The specificity bar. Kept |
| E entry 6 (`CartCost.checkoutChargeAmount` is NOT shipping — it bundles delivery and taxes; on a store with no delivery rate it returned exactly the subtotal) | — | ○ **Stays in Elora.** Correctly project-specific. This entry is the file's proof of value |
| E entry 2 (the Customer Account API accepts **only HTTPS** redirect URIs; a custom scheme is silently discarded on save+reload — and the *control* that proves it is the same save path persisting an HTTPS URI) | — | ○ Stays in Elora. But see the promotion rule: "only HTTPS redirect URIs" is a **general** Customer Account API constraint, not a quirk of this store. It should have been promoted into `05-shopify-auth.md` and was not. The template's promotion rule exists to force that |
| E entry 9 (every cart mutation answers under its own field name; typing the response as the inner shape type-checks, sends fine, then silently reads `undefined`) | — | ○ Stays. Same shape as the promotion-rule case: a general GraphQL-mutation fact that belonged in `04-data-layer.md` |
| E entry 12 (product option names are merchant copy, not a contract; and the spelling trap — `Couleur` is c-o-u-l-e-u-r, so a `/colou?r/` pattern does not match) | — | ○ Stays. Model entry for "concrete enough to act on" |
| E entry 1 (the `eas deploy` stale-export trap: the CLI said "exported 2 days ago" and published a deployment without the route) | — | ○ Stays. Model entry for a *tooling* discovery rather than an API one — the file is broader than "API quirks" |
| — | §§Promotion Rule (new) | → **New mechanism, derived from the observed defect.** Required content: *an entry that has become generally applicable must be promoted into the owning domain rule file, with the entry left in place as its provenance.* Without this the file accumulates findings that never change behaviour, and the domain rule stays wrong while a contradicting entry sits next to it — which is exactly the state Elora's `03-routing.md` and `15-shopify-contracts.md` are in |

---

## T1–T5 · Tech overlays (from existing sources)

| Overlay | Absorbed from | Note |
|---|---|---|
| `tech/typescript-javascript.md` | N `typescript` (9 TECH rows) · E `09` (all) · N `testing` §Framework Gotchas · E `AGENTS.md` §Commands | The generic JS/TS discipline. `strict: true` non-negotiable, `type` not `interface`, `no any`, `unknown`+narrow, `AsyncState` union, Zod-derived types, alias discipline, package-manager discipline, ESM/CJS + jsdom gotchas |
| `tech/react.md` | N `components` (12 TECH rows) | Server/Client boundary, props pattern, `cn()`, single icon set, `next/dynamic`, the value-vs-label quirk **with** its anti-reflexivity guard |
| `tech/react-native-expo.md` | E `03` (all) · E `07` §Theme/a11y/motion · E `10` · E `AGENTS.md` §Expo has changed / §Commands / §Building with EAS | SDK-pinned doc access + `llms.txt`, `npx expo install` only, CNG (never hand-edit `ios/`/`android/`), Expo Go vs development build, `@expo/ui` primitives, the non-virtualized-`List` footgun, keyboard avoidance (with its own built-in deprecation path), safe areas, `Platform.OS` branching, typed routes, EAS, `expo-image`, `expo-font` |
| `tech/nextjs.md` | N (all) · N `performance` (8 TECH rows) · N `error-handling` (7 TECH rows) | App Router file conventions, `error.tsx`/`loading.tsx`/`not-found.tsx` (+ the "don't duplicate an inherited boundary" rule), `next/image`/`font`/`script`/`dynamic`, the `min-w-0` footgun, Route Handlers vs Server Actions per the closed decision, `min-w-0` |
| `tech/flutter-dart.md` | F (all 11 files) | `ThemeExtension`, `Result<T>`/`AppFailure`/`FailureCode`, `AsyncNotifier` + provider-selection table, `Mappers.fromRow` trio, ARB + `gen-l10n` + `nullable-output`, `const` discipline, `dart format`/`flutter analyze`, no `dynamic`, `dispose()` discipline, no codegen (including the residual `@Riverpod(keepAlive:)` annotation bug), banned patterns table (18 rows), `flutter_driver` deprecated, no mocking frameworks |
| `tech/variants/*.md` | N `variants/pages-router.md`, `mui.md`, `ssr-hybrid.md` | The **delta mechanism is preserved and is the one thing in the Next profile worth keeping verbatim**: a variant states which files change and how, never a full restated copy. Re-based onto `tech/nextjs.md` |

---

## T6–T7 · Backend overlays (from documentation only)

**Status: no audited source project.** Built from `documentation-sources.md` rungs 3–4 against `/nestjs/docs.nestjs.com` and `/spring-projects/spring-boot`. Every rule below carries its source. Marked `Status: doc-sourced, never applied end-to-end` in the file header — the honest status the old profiles used.

| Overlay | Documented facts used |
|---|---|
| `tech/node-nestjs.md` | `@Injectable()` + constructor injection + registration in the module's `providers` array; providers are module-visible by default and must be `exports`ed then `import`ed to cross a module boundary; `Scope.DEFAULT` is singleton, `Scope.REQUEST` per-request; `app.useGlobalPipes(new ValidationPipe())` globally, and **DTOs must be concrete classes, not interfaces or generics, or runtime metadata is lost**; custom pipes use `plainToInstance` + class-validator's `validate` and throw `BadRequestException`; `app.useGlobalFilters()` for `@Catch`-based filters, which **cannot inject dependencies** and do not apply to gateways; the exact request lifecycle order — middleware → guards → interceptors → pipes → controller → service → interceptors → filters; `Test.createTestingModule().compile()` + `moduleRef.get()`; e2e with `overrideProvider().useValue()` + `moduleRef.createNestApplication()` + supertest against `app.getHttpServer()`; Prisma mocked with `{ provide: PrismaService, useValue: mock }` to avoid a real connection |
| `tech/java-spring.md` | "We generally recommend using constructor injection to wire up dependencies and `@ComponentScan`" — which lets fields be `final`; `@Autowired` needed to disambiguate when a bean has several constructors; `@ConfigurationProperties` recommended over `@Value` for grouped keys, gives a type-safe object, and **should only deal with the environment, not inject other beans**; `@Valid` on the DTO parameter + `BindingResult` is the canonical validation pattern; `ValidationAutoConfiguration` auto-configures `jakarta.validation.Validator` with message interpolation; `@Transactional` at class level on the service so all public methods run managed, service delegates to repositories; Spring Data JPA derived query methods from naming conventions, `Pageable` for pagination, repositories as interfaces over `Repository<T, ID>`; default `SecurityFilterChain` backs off **as soon as a user-defined `SecurityFilterChain` bean exists**; `@DataJpaTest` is `@Transactional` and rolls back per test and replaces the DataSource with an embedded DB — use `@AutoConfigureTestDatabase(replace = NONE)` when Flyway owns the schema; `@SpringBootTest` web-environment modes `MOCK`/`RANDOM_PORT`/`DEFINED_PORT`/`NONE`; slice tests all share the same upward `@SpringBootConfiguration` search |

---

## Cut summary

Total rules in the three sources: **~350**. Rules cut: **0 operational.** Lines cut: **~180**, all of them one of:

| What was cut | Why |
|---|---|
| Flutter `08` rule 8's duplicate rows 1 and 7 (the `print()` ban, stated a 3rd time) | intra-file duplicate — Principle 2 |
| Flutter `09` §Rules (11 condensed rules) | a redundant second restatement layer of §Verification + §Pre-Commit, inside one file |
| Flutter `09` §Escalation, Flutter `09` §File Size, N `workflow` §Escalation | duplicated in a second file; moved to their canonical home |
| Flutter's third file-size threshold (`09` rule 33's 200/300, `05` rule 5.14's 250) | mutually contradictory; one table replaces both |
| Flutter `AGENTS.md`'s "Strict 44-rule analysis_options" | factually wrong (the file has 34); templates must not assert counts about tool-generated files |
| Flutter DECISIONS ADR-005's "priority order is referenced from every rule file" | verified false by grep; a false claim in a template is worse than no claim |
| Flutter `08`'s `@Riverpod(keepAlive:)` reference | a codegen annotation inside a file whose own rule bans codegen — residual contamination, not a rule |
| N `AGENTS.md` §Variance axes | a self-invalidating section; replaced by `tech/variants/`, which cannot drift |
| F `10` §Commands "run a specific perf check → none" | the Measure-Don't-Guess principle restated as a table row |
| N `components` rule 9, N `forms` rules 1/3/6 | closed *project* decisions (N's ADR-001) inside a reusable template — they belong in the generated project's `DECISIONS.md` |
| Tutorial prose in all three sources (`PROFILE.md` rationales, `README`-style explanations, Elora's preamble paragraphs) | Principle 1, tier 1 |

## Not templated, and why

| Item | Reason |
|---|---|
| Elora's `05-shopify-auth.md`, `06-shopify-checkout.md`, `15-shopify-contracts.md` entries | Genuinely project-specific. `15`'s *mechanism* is templated (D10); its 13 entries stay in Elora |
| Flutter's `analysis_options.yaml` | A toolchain file, not a rule. The lint-rule *names* go in the Flutter overlay's banned-patterns table |
| Flutter's `01`/`05` folder trees, N's `architecture` tree, E's `01` tree | Three mutually incompatible folder contracts. The template emits *slots*; the overlay fills paths |
| `DESIGN.md`'s 21 colours and 6 type roles | A project's visual identity, not a rule. `design-system.md` *references* the contract; it never restates it |
| `PRODUCT.md`, `PRD.md`, `.impeccable/` | Human-facing product artifacts, outside the agent's operational rules |
| `SESSION_LOG.md`'s 8-field *content* | A format, templated. The content is per-project history |
