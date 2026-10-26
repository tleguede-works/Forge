# Phases, skills and order: ownership and transitions

## Scope and method

Subject: the phase model of the v3 kit — order, ownership, transitions, and the invariant "one phase is owned end to end by exactly one skill" (`AGENTS.md:53`, I1).

Read in full: `cli/forge.py` (phase constants, `phase_of`, `next_action`, `cmd_phase_start`, `cmd_register`, `gate_problems`, `cmd_gate`, `cmd_slice`, `cmd_reopen`, `cmd_client`, `cmd_compliance`, `cmd_lint`), all 10 `skills/*/SKILL.md`, all 9 `agents/*.md`, `docs/{STATUS,MIGRATION-v2,ESCAPE-HATCH-AUDIT,AUDIT-2026-10-19,IMPROVEMENTS}.md`, `AGENTS.md`, `tests/*.sh` (grep).

v2 baseline read for parity: `skills/forge/SKILL.md` lines 82, 228-230, 239-245, 286-321, 1052-1078 in the clone at `C:\Users\Thibaut LEGUEDE\AppData\Local\Temp\opencode\v2-baseline`.

Not done: no `forge init`, no suite execution (the 14 suites are POSIX-only, `AGENTS.md:73` I6, and this host is Windows), no write outside this file. Commands actually run and their output are cited inline, notably:

```
git show 2864ab8^:cli/forge.py | head -12
PHASES = ["bootstrap", "landscape", "prd", "roadmap", "design",
          "architecture", "plans", "build", "validation"]
git show 62324f1^:cli/forge.py | head -12
PHASES = ["bootstrap", "landscape", "prd", "roadmap", "design",
          "architecture", "rules", "plans", "build", "validation"]
git log --oneline -S "Forge phase 2" -- skills/forge-compliance/SKILL.md
62324f1 Compliance phase (register, rechecks, L requirements), roadmap touchpoint, ...
git log --oneline --follow -- skills/forge-plan/SKILL.md
62324f1 ... / c89a27b ... / 2864ab8 ... / e1f2e6d Forge v3: CLI, skills, agents, ...
```

These four outputs prove the numbering history used in F2: every numeric phase claim in the skills matches the `PHASES` list printed by `git show 2864ab8^:cli/forge.py` (the list v3 shipped with before the `rules` and `compliance` insertions), not the current one.

## Current chain

`PHASES` = 11 phases (`cli/forge.py:8-9`). Exact indices: bootstrap 0, landscape 1, compliance 2, prd 3, roadmap 4, design 5, architecture 6, rules 7, plans 8, build 9, validation 10.

| # | Phase | Owning skill (source of the claim) | Producer agent (source) | Reviewers | Deliverables (`REQUIRED`, `cli/forge.py:10-22`) + path (skill, prose only) | Phase-specific gate checks in `gate_problems` (`cli/forge.py:453-508`) | Touchpoint (`:25`) | Recheck (`:1301`) |
|---|---|---|---|---|---|---|---|---|
| 0 | bootstrap | `forge-bootstrap` (`skills/forge/SKILL.md:52`) | `forge-analyst` (`forge-bootstrap:8`) | `forge-qa`, `forge-redteam` (`forge.py:24,498`) + liaison (`:526`) | `contract`, `brief` — `.forge/contract.md`, `.forge/brief.md` | none beyond REQUIRED + hash + 2 reviews (`:455-457`, `:491-507`) | yes | no |
| 1 | landscape | `forge-discover` (`forge/SKILL.md:52`) | `forge-analyst` (`forge-discover:44-46`) | qa, redteam | `landscape` — `.forge/landscape.md` | none; the generic block only (`:455-457`, `:491-507`) | no | no |
| 2 | compliance | `forge-compliance` (`forge/SKILL.md:52`) | `forge-compliance` (`forge-compliance:10`) | qa, redteam + liaison | `compliance-register` — `.forge/compliance-register.md` | `compliance_problems` (`:460-461`, body `:1329-1372`) | yes | source |
| 3 | prd | `forge-discover` (`forge/SKILL.md:52`) | `forge-analyst` (`forge-discover:44-46`) | qa, redteam + liaison | `prd` — `.forge/prd.md` | `prd_problems` + `compliance_prd_problems` (`:462-463`, bodies `:738-751`, `:1374-1391`) + recheck (`:464-469`) | yes | yes |
| 4 | roadmap | `forge-discover` (`forge/SKILL.md:52`) | `forge-analyst` (`forge-discover:44-46`) | qa, redteam + liaison | `roadmap` — `.forge/roadmap.md` | `premises_problems` (`:458-459`, body `:798-810`) + `roadmap_problems` (`:470-471`, body `:754-763`) | yes | no |
| 5 | design | `forge-design` (`forge/SKILL.md:52`) | `forge-designer` (`forge-design:30`) | qa, redteam + liaison; checklist required (`forge-design:30`) | `design-references`, `screen-map`, `layouts`, `design-system` + `screen:SCR-<n>` (`:23`) — `.forge/design/*` | `design_problems` + every screen-map row registered (`:484-488`, body `:629-701`) | yes | no |
| 6 | architecture | `forge-architect` (`forge/SKILL.md:52`) | `forge-architect` (`forge-architect:8`) | qa, redteam | `architecture`, `slices` — `.forge/architecture.md`, `.forge/slices.md` | `premises_problems` + `coverage_problems` (`:458-459`, `:472-473`, body `:778-795`) + recheck (`:464-469`) | no | yes |
| 7 | rules | `forge-rules` (`forge/SKILL.md:52`) | `forge-architect` (`forge-rules:29`) | qa, redteam | `rules-report` — `.forge/rules-report.md` | `rules_gate_problems` → `rules_checks` (`:474-475`, body `:1205-1210`) | no | no |
| 8 | plans | `forge-plan` (`forge/SKILL.md:52`) | `forge-architect` (`forge-plan:8`) | qa, redteam | `plans-index`, `test-plan` + `plan:S<n>` (`:23`) — `.forge/plans/*`, `.forge/test-plan.md` | `plans_problems` (`:476-477`, body `:813-845`) + `layout_plan_problems` (`:489-490`, body `:704-712`) + premises | no | no |
| 9 | build | `forge-build` (`forge/SKILL.md:52`) | `forge-builder` (`forge-build:8`) | qa, redteam (no deliverable to review) | none — `"build": []` (`:20`) | every slice of `slices.md` is `done` (`:478-483`); plan presence enforced earlier at `slice start` (`:873-874`) | no | no |
| 10 | validation | `forge-build` (`forge/SKILL.md:52`) | `forge-builder` (`forge-build:8`) | qa, redteam + liaison | `validation-report` — `.forge/validation-report.md` | premises + recheck only (`:458-459`, `:464-469`); no content check | yes | yes |

Reviewers are uniform: `REVIEWERS = ("qa", "redteam")` (`cli/forge.py:24`) and the gate refuses a phase deliverable without both on the current hash (`:498-507`). Client mode adds `forge-client-liaison` at the six touchpoints (`:25`, `:526-537`).

Phase order is enforced in one place: `cmd_phase_start` refuses `PHASES[i-1] != approved` (`cli/forge.py:307-309`), and a deliverable can only be registered in the current phase (`:327-328`, via `phase_of` `:159-166`). No phase can be started out of order. That part of the model holds.

## Findings

### F1 — No phase is bound to a skill or an agent by anything the CLI checks
- **Ref** `AGENTS.md:53` (I1), `skills/forge/SKILL.md:52`
- **Status** verified
- **Severity** critical
- **What** The phase→skill mapping exists once, as one sentence in the router skill (`skills/forge/SKILL.md:52`: "bootstrap uses `forge-bootstrap`; compliance uses `forge-compliance`; landscape, prd and roadmap use `forge-discover`; …"). `PHASES`, `REQUIRED`, `PREFIX_PHASE`, `TOUCHPOINTS` and `RECHECK_PHASES` (`cli/forge.py:8-25`, `:1301`) carry no skill name and no agent name. Consequently I1 is a request, not a gate — the exact defect `AGENTS.md:84` I10 names ("A deliverable the CLI cannot check is not a deliverable").
- **Evidence** `grep -rn "forge-discover\|forge-architect\|forge-plan\|forge-build" cli/ scripts/ hooks/` returns no match outside test template paths: `tests/templates.sh:8-13` is the only machine-readable deliverable→skill mapping in the repository, and it maps templates, not phases. `forge status` prints phase statuses and a `next:` line (`cli/forge.py:242-249`); no line names a skill. `forge phase start` prints `started <phase>` (`:318`). The state entry written at registration has `path`, `phase`, `hash`, `requires`, `reviews` — no producer, no skill (`:340-342`).
- **Impact** An agent may run any phase with any skill, or none, and every gate still passes. The mapping already drifted without a detector (F2). v2 had this check and v3 lost it: `v2-baseline/skills/forge/SKILL.md:288-290` calls the phase→agent table normative ("Sans elle, il faut deviner le nom"), and `:319-321` states `validate-repo refuse un fichier d'agent présent sur le disque et jamais nommé ici, comme il refuse un agent nommé ici et absent du disque`. `docs/MIGRATION-v2.md` does not record that validator as removed, so by `AGENTS.md:39-41` this is a regression, not a choice.
- **Recommendation** Add `PHASE_SKILL` and `PHASE_PRODUCER` to `cli/forge.py`; emit them in `status`, `phase start` and `write_now`; add a `forge phase owners` check and a suite asserting every `PHASES` entry has exactly one skill and one producer, and that each `skills/<x>/SKILL.md` frontmatter `name` equals its directory. See F5 for the transition half.

### F2 — Three generations of phase numbers coexist; two phases are both "phase 2"
- **Ref** `skills/forge-bootstrap/SKILL.md:3,8`, `skills/forge-compliance/SKILL.md:3`, `skills/forge-discover/SKILL.md:3,12,26,36`, `skills/forge-design/SKILL.md:3`, `skills/forge-architect/SKILL.md:3`, `skills/forge-plan/SKILL.md:3`, `skills/forge-build/SKILL.md:3,10,21`
- **Status** verified
- **Severity** major
- **What** Seven files claim a numeric phase. Not one matches the current `PHASES` list, and they do not use a single abandoned convention either: six match the pre-rules index list (`git show 2864ab8^:cli/forge.py`), one matches today's index.
- **Evidence**

| File:line | Claim | Current index | Pre-rules index (`2864ab8^`) | Verdict |
|---|---|---|---|---|
| `forge-bootstrap/SKILL.md:3,8` | "phase 0" | 0 | 0 | correct by coincidence |
| `forge-discover/SKILL.md:12` | "Phase 1: landscape" | 1 | 1 | stale-world-correct |
| `forge-discover/SKILL.md:26` | "Phase 2: prd" | 3 | 2 | **collides with compliance** |
| `forge-discover/SKILL.md:36` | "Phase 3: roadmap" | 4 | 3 | stale-world-correct |
| `forge-discover/SKILL.md:3` | "phases 1 to 3" | 1,3,4 | 1,2,3 | stale |
| `forge-compliance/SKILL.md:3` | "phase 2" | 2 | (did not exist) | **collides with prd** |
| `forge-design/SKILL.md:3` | "phase 4" | 5 | 4 | stale |
| `forge-architect/SKILL.md:3` | "phase 5" | 6 | 5 | stale |
| `forge-plan/SKILL.md:3` | "phase 6" | 8 | 6 | stale |
| `forge-build/SKILL.md:3,10,21` | "phases 7 and 8" | 9,10 | 7,8 | stale |

`git show 2864ab8:skills/forge-plan/SKILL.md | head -4` still reads "Forge phase 6" immediately after the commit that inserted `rules` before `plans`; `git show 2864ab8 --stat` lists `2864ab8 Wire forge-rules into the workflow as phase 'rules' (between architecture and plans)`. So the drift predates compliance and was widened by it — which contradicts `AGENTS.md:31-32`, where the whole drift is attributed to "the `compliance` insertion".
- **Impact** The pair (`forge-compliance:3` "phase 2", `forge-discover:26` "Phase 2: prd") states two different orders in the same repository. An agent that reads "phase 2" as a position cannot tell whether compliance precedes prd (it does, `cli/forge.py:8`) — the CLI blocks the wrong execution (`:307-309`), so nothing is skipped, but the wrong skill is loaded and the wrong deliverable prepared before the refusal. A reader told "phases 1 to 3" by `forge-discover:3` also expects to own three consecutive phases, which are 1, 3 and 4 around compliance.
- **Recommendation** Delete every numeric phase claim from `skills/` and `agents/`; name phases. Then add a lint rule to `cmd_lint` (`cli/forge.py:1528-1544`) rejecting `[Pp]hase [0-9]` under `skills/` and `agents/`, and a suite case for it.

### F3 — `forge-discover` owns three phases but its text cannot satisfy two of its three gates
- **Ref** `skills/forge-discover/SKILL.md:26-42`
- **Status** verified
- **Severity** major
- **What** Ownership of landscape, prd and roadmap by one skill is defensible (see Rejected candidates), but the skill states neither the cross-phase obligations its own gates enforce nor the touchpoint its roadmap gate requires. An agent that follows only `forge-discover` is refused at the prd gate and at the roadmap gate.
- **Evidence**
  1. prd gate refuses without `L<n>` for every applicable obligation and requires that each `L` cites an `OB` (`cli/forge.py:462-463` → `:1374-1391`). `forge-discover:26-34` never mentions compliance, `L<n>` or `OB-<n>`; the obligation lives in `skills/forge-compliance/SKILL.md:23`.
  2. prd, architecture and validation gates refuse without a compliance recheck (`cli/forge.py:464-469`, `RECHECK_PHASES` `:1301`). `forge-discover:26-34` does not mention `forge compliance recheck`; `forge-compliance:24` does.
  3. `roadmap` is a touchpoint (`cli/forge.py:25`) and the approve path refuses without a liaison review (`:526-537`). `forge-discover:36-42` never mentions it.
  4. `forge-discover:34` sends the PRD summary to the wrong touchpoint: "Client mode: produce a one-page plain-language summary for the validation touchpoint." The prd is itself a touchpoint, and the document it must produce is `.forge/client/prd-summary.md` (`skills/forge/SKILL.md:43`). The same sentence is listed as a live trap in `AGENTS.md:182-183`.
  5. The landscape gate has no content check at all: `gate_problems` has no `ph == "landscape"` branch (`:453-508`), so its only content verification is the section list at registration (`HEADINGS["landscape"]`, `:98-99`, `structure_problems` `:135-148`).
- **Impact** The refusal message names the missing artefact but not the owning skill, so the agent must search or guess which skill to load mid-phase (F5). At the prd gate it can loop: the obligation is described in a skill the phase procedure never tells it to load.
- **Recommendation** Either give `forge-discover` a "gate prerequisites" block naming `L<n>`/`OB-<n>` and the recheck, or — cleaner, per I3 — have the CLI print the prerequisite commands for the current phase in `status`; fix `:34` to `prd-summary.md`; add a `landscape` gate branch that verifies the decision table verdicts (`keep`/`drop`/`differ`, `forge-discover:21`).

### F4 — `forge-build` produces both the code and its own validation report; the validation gate is content-blind
- **Ref** `skills/forge-build/SKILL.md:8,10,21-25`, `cli/forge.py:453-508`
- **Status** verified
- **Severity** major
- **What** One skill and one producer agent (`forge-builder`, `forge-build:8`) implement the slices and then write `validation-report`. The grouping itself does not let a phase be skipped — the gates are separate and ordered — but it makes the validation gate unable to fail on the thing validation exists to check.
- **Evidence** `gate_problems("build")` verifies that every `S<n>` row of `slices.md` is `done` (`:478-483`). `gate_problems("validation")` verifies only that `validation-report` is registered, current, and twice reviewed, plus premises and the compliance recheck (`:455-457`, `:458-459`, `:464-469`, `:491-507`). Nothing ties the report to the test plan: `plans_problems` — which checks one `TC-<S>-<n>` per plan (`:832-833`) and test-plan coverage of every `B/E/V/L` id (`:838-844`) — is not called for validation. The compliance skill demands that the validation recheck verify "each applicable obligation, its requirement and its test result" (`skills/forge-compliance/SKILL.md:24`), yet `forge compliance recheck` records only a 20-character evidence string and a register hash (`cli/forge.py:1400-1403`); no check reads the report's rows. `docs/AUDIT-2026-10-19.md:45` already records the gap under another name: "Independent code review before build completes — Absent; the build gate relies on slice evidence only".
- **Impact** A validation report may be an empty-but-well-formed table (the headings check at registration, `HEADINGS["validation-report"]`, `:113-114`, accepts empty cells in a non-empty section, `:145-147`), reviewed by two agents that have no TC list to compare against. The phase fails independently only on a missing file or a blocking review finding — both produced by the same pipeline that wrote the code.
- **Recommendation** Split validation into its own skill (`forge-validate`) with its own producer (`forge-validator`), and add `validation_problems(root)`: every `TC-<S>-<n>` of every plan appears in the report with a result, every applicable `OB` has its result row, every deviation names a decision id. Add a suite case that a report missing one TC id is refused.

### F5 — The gate→skill transition is written nowhere an agent actually reads
- **Ref** `cli/forge.py:252-294`, `:547`, `:906`
- **Status** verified
- **Severity** major
- **What** "Explicit transition" today means a phase name, never an owner. Every runtime surface that announces the next step names the phase command only.
- **Evidence** `next_action` returns `forge phase start <next>` after approval (`cli/forge.py:256-258`), `forge gate check` when checks are pending (`:294`), and the slice commands during build (`:288-293`). `cmd_status` prints exactly that string as `next:` (`:249`). `cmd_gate` writes the same string into `NOW.md` on approval (`:547` → `write_now` `:552-559`), so `forge memory resume` — the documented recovery after compaction (`skills/forge-memory/SKILL.md:19-26`) — yields a phase command with no skill. `forge phase reopen` writes "edit, re-register, re-review, then gate; later phases restart" (`cli/forge.py:906`) with no skill name either. The only statement of which skill runs which phase is `skills/forge/SKILL.md:52`, a file the phase procedure tells the agent to read *after* `forge status` as a separate step.
- **Impact** A resumed session has the exact action but not the owner, and the mapping is not derivable from the phase list: `architecture`, `rules` and `plans` are three phases, two skills and one agent. The agent must either remember the router table or guess; a wrong guess is not refused by any gate (F1).
- **Recommendation** Make `next_action` return `forge phase start <phase>` and a second line `load skill <skill> (producer: <agent>)`; persist both in `NOW.md`; print both from `cmd_phase_start`. Cover the reopen transition too.

### F6 — `plans` is produced by the agent that owns `architecture`, reversing a documented v2 decision
- **Ref** `skills/forge-plan/SKILL.md:8`, `agents/forge-architect.md:2,6`
- **Status** verified
- **Severity** major
- **What** `forge-plan` names `forge-architect` as producer, and `forge-architect.md:6` lists `architecture`, `slices`, `rules-report`, `plan:<Sxx>`, `plans-index` and `test-plan` as its deliverables. One agent therefore produces three consecutive phases' artefacts (architecture, rules, plans) and can restate its own architecture as the plans' contract.
- **Evidence** v2 deliberately refused a plan writer: `v2-baseline/skills/forge/SKILL.md:306` lists Phase 5 (plans) with "**tu les écris toi-même**", and `:309-313` gives the reason — "Un plan d'implémentation est la chose la plus facile à écrire dans le vide … Il n'y a donc personne à qui déléguer la rédaction — seulement `agents/plan-validator.md`, qui **relit** un plan déjà écrit". `docs/MIGRATION-v2.md` records no such change; the only plan-related line is `:25` (adapting formats). On the gate side, `plans_problems` checks section names, 1-15 tasks, `serves` equality, at least one `TC-` line, index and test-plan mentions (`cli/forge.py:813-845`) — nothing checks P5, "a plan quotes the API contracts and data model of `architecture.md`" (`skills/forge-plan/SKILL.md:27`). The architecture author can therefore satisfy every mechanical check by paraphrasing the document it just wrote.
- **Impact** The one phase whose purpose is to be executable by a weaker model (`forge-plan:3`) is written from the same context that produced the abstractions it must make concrete — the failure mode v2 named. The `plans` gate cannot see it, and the producer is not recorded in state (F1), so a later auditor cannot tell who wrote a plan.
- **Recommendation** Give `plans` a distinct producer (`forge-planner`, one delegation per plan, reading `architecture.md` as a contract), or restore v2's rule that the orchestrator writes plans and no author agent does. Either way record the producer in the deliverable entry and add a `plans` check that each plan quotes at least one API contract identifier present in `architecture.md`.

### F7 — The touchpoint set is copied in eight places and the liaison gate does not require the summary it names
- **Ref** `cli/forge.py:25`, `:526-537`, `:939-953`; `skills/forge/SKILL.md:37,43`
- **Status** verified
- **Severity** major
- **What** `TOUCHPOINTS` is duplicated in prose in at least six places, one of them wrong (F3 item 4), and `forge client review` accepts any file inside `.forge/` as the document to review, so the touchpoint check can be satisfied against the technical deliverable instead of the plain-language summary.
- **Evidence** The set appears at `cli/forge.py:25`, `skills/forge/SKILL.md:37` (modes table), `:43` (touchpoint procedure, which also states the path `.forge/client/<phase>-summary.md`), `forge-bootstrap:8`, `forge-compliance:10`, `forge-design:26`, `forge-build:25`, and wrongly at `forge-discover:34`. `cmd_client` accepts `--document` if it resolves inside `.forge/` and exists (`:946-947`) and does not compare it to `.forge/client/<phase>-summary.md`; `cmd_gate` then only checks that the recorded document still hashes the same (`:532-533`) and that no question is unresolved (`:536-537`). `agents/forge-client-liaison.md:6` likewise accepts "the contract, a progress report, a PRD summary or an acceptance summary" with no binding to the current phase.
- **Impact** At the prd touchpoint, registering `.forge/prd.md` itself as the reviewed document passes every check while the client-facing obligation (a plain-language summary a non-technical client can answer) is not exercised. It also means a phase can consume another phase's summary: nothing checks that `prd.client.json` was produced from the prd summary.
- **Recommendation** Derive the path in the CLI: `cmd_client review` requires `--document .forge/client/<phase>-summary.md` for the `--phase` it is given. Keep the touchpoint list in `TOUCHPOINTS` only; have the six skills say "this phase is a touchpoint, see `forge status`" without repeating the set.

### F8 — `AGENTS.md` has two owners, and the documented recovery is a command the CLI always refuses
- **Ref** `cli/forge.py:181-182`, `:198-215`, `:1001-1002`, `:1188-1194`; `skills/forge-rules/SKILL.md:31`; `skills/forge-memory/SKILL.md:24`
- **Status** verified
- **Severity** major
- **What** `forge init` writes the Forge block into `AGENTS.md` (`inject_agents_md`, `:198-215`), and phase `rules` produces the rule set in the project root, where `AGENTS.md` is the first entry file (`ENTRY_FILES`, `:968`). Nothing verifies the block survived the rules phase, and the recovery instruction in `forge-memory` cannot run.
- **Evidence** The rules hash deliberately excludes the block (`_noblock` `:1001-1002` used at `:1192`), so deleting the block during the rules phase is not even reported as `DRIFT` (`drift`, `:219-230`). `forge-memory:24` says: "If it is missing or outdated, run `forge init` for a new project or restore the block from the installed template" — `cmd_init` refuses with `already initialised` whenever `.forge/state.json` exists (`:181-182`), which is exactly the case in which the block can be missing. `AGENTS.md:76-78` (I7) states the block must be preserved but names no check.
- **Impact** A rules-phase rewrite of `AGENTS.md` can sever the project's only pointer to its CLI, and the agent's documented repair sends it into a refusal it must then work around, which R9 (`skills/forge/SKILL.md:26`) and R11 (`:28`) forbid.
- **Recommendation** Add a `block_problems()` check on every `gate check` and on `status`: the `BEGIN`/`END` markers exist exactly once and enclose the four required lines. Change `forge-memory:24` to a real command (`forge init --repair-block` or the installer), and add a rules-phase check that the entry file still holds the block after wiring.

### F9 — The design review checklist has no carrier: the mandated delegation header has no inputs field
- **Ref** `skills/forge-design/SKILL.md:30`, `agents/forge-qa.md:10`, `agents/forge-redteam.md:10`, `agents/forge.md:17-23`, `skills/forge/SKILL.md:17-23`
- **Status** verified
- **Severity** major
- **What** `forge-design` requires the reviewers to run `references/review-checklist.md` "in addition to the generic review", while both reviewer contracts say "Read nothing else" beyond the delegation header, the deliverable and earlier deliverables. The delegation header has five fields and none of them can carry the checklist, so the only written workaround (`AGENTS.md:177-179`: "pass the checklist in the delegation header") has no syntax.
- **Evidence** Header fields are `CALLER`, `PHASE`, `DELIVERABLE`, `ROLE`, `RIGHTS` (`agents/forge.md:17-23`, duplicated at `skills/forge/SKILL.md:17-23`). `forge-qa.md:10` and `forge-redteam.md:10` both say "Read nothing else". `forge-design:30` names a file inside the skill directory. The CLI records no delegation content (`cmd_review_begin`, `:362-398`), so nothing proves the checklist was passed or read.
- **Impact** Design is the phase where the reviewer's own contract forbids the extra input, so the checklist is either skipped silently or the reviewer reads outside its stated inputs — both unrecorded. The same structural gap applies to any future per-phase review checklist.
- **Recommendation** Add an `INPUTS:` field to the header template and make the producing skill fill it (the checklist path for design, nothing otherwise); state in the reviewer contract that `INPUTS` overrides "read nothing else". This is prose, so no gate is possible — record it in `docs/ESCAPE-HATCH-AUDIT.md:30-33` as judgement rather than leaving it implicit.

### F10 — Deliverable paths are prose; the gate's content checks read fixed paths the phase may not have registered
- **Ref** `cli/forge.py:10-22`, `:329-331`, `:739`, `:755`, `:767`, `:706`, `:1314`; `AGENTS.md:61-63`
- **Status** verified
- **Severity** minor
- **What** `REQUIRED` holds deliverable names, not paths, although I3 states "Deliverable paths live in `REQUIRED`". `cmd_register` accepts any existing file inside `.forge/` (`:329-331`), while the content checks read one hardcoded path per deliverable (`prd.md` `:739`, `roadmap.md` `:755`, `compliance-register.md` `:1314`, `slices.md` `:767`, `.forge/plans/*.md` `:706`).
- **Evidence** `AGENTS.md:61-63` says paths live in `REQUIRED`; `cli/forge.py:10-22` shows they do not. Registering `prd` at `.forge/draft.md` passes registration and then makes `prd_problems` report "prd.md is missing" (`:739-741`), a message that names a file the phase never claimed.
- **Impact** The gate can validate a file the phase did not register (when `.forge/prd.md` exists beside a differently registered `prd`), or refuse with a misleading message. No phase can be skipped, but the audited artefact is ambiguous.
- **Recommendation** Add the canonical path to `REQUIRED` (name → relative path) and have `cmd_register` refuse a path that differs, or derive the path from the name and drop `--path` for the fixed-name deliverables. Correct I3 in the same change.

### F11 — Residual doc and constant drift around the phase model
- **Ref** `docs/MIGRATION-v2.md:7,12`, `docs/STATUS.md:11,14`, `cli/forge.py:20`, `:476-477`, `:489-490`, `:264`, `:280`, `:288`
- **Status** verified
- **Severity** minor
- **What** Counts and constants that describe the model disagree with the model, and one branch is written twice.
- **Evidence** `MIGRATION-v2:7` says "seven phase skills"; `skills/forge/SKILL.md:52` names eight (`forge-bootstrap`, `forge-compliance`, `forge-discover`, `forge-design`, `forge-architect`, `forge-rules`, `forge-plan`, `forge-build`), and `skills/` holds 10 directories including `forge` and `forge-memory`. `MIGRATION-v2:12` says "8" agents and `STATUS.md:14` lists 8, while `agents/` holds 9 (`forge-compliance` missing from the STATUS list, as `AGENTS.md:188-191` already notes); `STATUS.md:11` lists 9 skills and omits `forge-compliance`. `REQUIRED["build"] = []` (`:20`) makes build look like an unconfigured phase; `next_action` special-cases build three times (`:264`, `:280`, `:288`). `gate_problems` writes `if ph == "plans"` twice (`:476-477`, `:489-490`).
- **Impact** None on execution; it costs a reader the trust I3 is meant to protect, and the build special case makes the "every phase has a deliverable" reading false without explanation.
- **Recommendation** Fold the two `plans` branches into one; state explicitly in `REQUIRED`'s comment that build is a slice-state phase, not a deliverable phase; fix the three counts in one pass; make the STATUS skill and agent lists generated or asserted by `tests/templates.sh`.

## Target model

Invariant to adopt, stated so it can be checked: **every phase maps to exactly one owning skill and one producer agent; a skill may own several phases, but only if each of those phases has its own `REQUIRED` entry, its own gate branch and its own producer declaration.** Three properties, one source: `cli/forge.py`.

### Recommended: a phase registry in the CLI, nine skills, explicit transitions

Add to `cli/forge.py` (single source, replacing the prose copies):

```
PHASE_SKILL = {"bootstrap": "forge-bootstrap", "landscape": "forge-discover",
               "compliance": "forge-compliance", "prd": "forge-discover",
               "roadmap": "forge-discover", "design": "forge-design",
               "architecture": "forge-architect", "rules": "forge-rules",
               "plans": "forge-plan", "build": "forge-build", "validation": "forge-validate"}
PHASE_PRODUCER = {"bootstrap": "forge-analyst", "landscape": "forge-analyst",
                  "compliance": "forge-compliance", "prd": "forge-analyst",
                  "roadmap": "forge-analyst", "design": "forge-designer",
                  "architecture": "forge-architect", "rules": "forge-architect",
                  "plans": "forge-planner", "build": "forge-builder",
                  "validation": "forge-validator"}
```

Changes: `validation` leaves `forge-build` (F4); `plans` leaves `forge-architect` (F6); skills stop carrying phase numbers (F2); `forge phase owners` asserts the registry against `PHASES`, `REQUIRED` and the skill/agent directories (F1); `next_action`, `status`, `phase start` and `NOW.md` emit the skill and producer (F5).

Transitions, each one line, each produced by the CLI:

| From | Condition | Transition | Source |
|---|---|---|---|
| project created | `.forge/state.json` written | `forge phase start bootstrap` → load skill `forge-bootstrap` (producer `forge-analyst`) | `forge.py:192`, `:254-255` |
| gate bootstrap approved | `next_action` | `forge phase start landscape` → load skill `forge-discover` | `:258` |
| gate landscape approved | `next_action` | `forge phase start compliance` → load skill `forge-compliance` | `:258` |
| gate compliance approved | `next_action` | `forge phase start prd` → load skill `forge-discover` | `:258` |
| gate prd approved | `next_action` | `forge phase start roadmap` → load skill `forge-discover` | `:258` |
| gate roadmap approved | `next_action` | `forge phase start design` → load skill `forge-design` | `:258` |
| gate design approved | `next_action` | `forge phase start architecture` → load skill `forge-architect` | `:258` |
| gate architecture approved | `next_action` | `forge phase start rules` → load skill `forge-rules` | `:258` |
| gate rules approved | `next_action` | `forge phase start plans` → load skill `forge-plan` | `:258` |
| gate plans approved | `next_action` | `forge phase start build` → load skill `forge-build` | `:258` |
| gate build approved | `next_action` | `forge phase start validation` → load skill `forge-validate` | `:258` |
| gate validation approved | `next_action` | `done` — no skill | `:256-258` |
| gate `<phase>` reopened | `forge phase reopen` | reload skill of `<phase>` | `:901-907` (today: no skill named) |
| gate prd / architecture / validation pending | `gate check` refusal | load the recheck section of `forge-compliance` before retrying | `:464-469` (today: refusal only) |

Trade-off: `forge-discover` still owns three phases (justified below), so ownership is "registered", not 1:1 by file name; the registry plus the suite is what makes I1 checkable. Cost is one constant, one subcommand, one suite, and four prose deletions.

### Alternative (only if strict 1:1 is wanted): eleven skills, one per phase

`forge-landscape`, `forge-prd`, `forge-roadmap` replace `forge-discover`; `forge-validate` as above. Each skill reads a shared `skills/_discovery/references/` for templates. Trade-off: any phase name answers "which skill" without a registry, and no skill can hide a stub phase among its siblings — but the discovery material (templates, benchmark procedure, ID rules) must be shared by reference, adding a cross-skill dependency the CLI cannot check (`tests/templates.sh:8-13` would keep pointing into `forge-discover/references/`), and the count of prose files to keep in step goes from 8 to 11. Recommend the registry first; this alternative only if a phase-per-skill reading is a hard requirement.

## Ripple list

Every item below must move in one change. `cli/forge.py` line numbers are the current ones.

| Area | Exact items |
|---|---|
| CLI constants | `PHASES` `:8-9` (unchanged), `REQUIRED` `:10-22`, `PREFIX_PHASE` `:23`, `REVIEWERS` `:24`, `TOUCHPOINTS` `:25`, `RECHECK_PHASES` `:1301`, new `PHASE_SKILL` / `PHASE_PRODUCER` |
| CLI functions | `phase_of` `:159-166`, `next_action` `:252-294`, `cmd_status` `:233-249`, `cmd_phase_start` `:305-318`, `cmd_gate` `:511-548` (validation check, `block_problems`), `gate_problems` `:453-508` (merge the duplicate `plans` branches `:476-477`/`:489-490`, add `validation_problems`, add `landscape` branch), `cmd_client` `:939-953` (document path), `cmd_reopen` `:901-907`, `cmd_lint` `:1528-1544` (no numeric phase), `HEADINGS` `:92-115` |
| `REQUIRED` / paths | name→path table replacing the prose paths in `forge-bootstrap:8`, `forge-discover:12,26,36`, `forge-compliance:10`, `forge-design:8`, `forge-architect:8`, `forge-rules:29`, `forge-plan:8`, `forge-build:10,21`; hardcoded readers `:739`, `:755`, `:767`, `:706`, `:1314` |
| `PREFIX_PHASE` | `:23` — unchanged unless `plans` gains a prefix |
| `TOUCHPOINTS` | `:25`; delete the copies at `forge/SKILL.md:37,43`, `forge-bootstrap:8`, `forge-compliance:10`, `forge-design:26`, `forge-build:25`; fix `forge-discover:34` |
| `RECHECK_PHASES` | `:1301`; `forge-compliance:24`; `forge-discover:26-34` must gain the recheck step |
| Skill directories | `skills/forge-bootstrap/`, `forge-discover/`, `forge-compliance/`, `forge-design/`, `forge-architect/`, `forge-rules/`, `forge-plan/`, `forge-build/` (loses validation), new `skills/forge-validate/`; `skills/forge/SKILL.md:3,20,37,43,52`; `skills/forge-memory/SKILL.md:24` |
| Agent files | `agents/forge.md:17-23` (header + `INPUTS`), `:29` (rights table), `agents/forge-architect.md:2,6,8,12` (loses `plan:<Sxx>`, `plans-index`, `test-plan`), `agents/forge-analyst.md:2,6,8`, `agents/forge-builder.md:2` (loses validation), new `agents/forge-planner.md`, new `agents/forge-validator.md`, `agents/forge-qa.md:10`, `agents/forge-redteam.md:10` (`INPUTS` override) |
| Templates | `skills/forge-build/references/validation-report-template.md` (moves with the deliverable), `skills/forge-plan/references/{plan,plans-index,test-plan}-template.md`, any entry-file template used by `forge-rules` for `AGENTS.md` |
| Tests | `tests/templates.sh:8-13` (MAP is the second copy of deliverable→skill), `tests/e2e.sh:30,42-48,63`, `tests/compliance.sh:31,51,57-59`, `tests/rulesphase.sh:50-51,71-75`, `tests/flow.sh:62,69-71`, `tests/audit.sh:32,40,55`, `tests/adversarial.sh:28,53,63,67`, `tests/design.sh`, `tests/i18n.sh:9`, `tests/loops.sh:21`, `tests/install.sh:17,31,48`; new `tests/phases.sh` for the registry, the numbering lint and the validation-report coverage |
| Docs | `docs/STATUS.md:5,8,10,11,12,14`; `docs/MIGRATION-v2.md:7,10,12,17` (+ a row recording the plans-producer decision); `docs/ESCAPE-HATCH-AUDIT.md` (rows for the registry, the validation binding, the liaison path, the block check; J-list for the `INPUTS` field); `docs/AUDIT-2026-10-19.md:45` (close or restate); `README.md:47-48,52` |
| `AGENTS.md` | I1 `:53-57` (add "and one producer", drop the number-based wording), I3 `:61-64` (paths are not in `REQUIRED` today), Known traps `:31-32` (drift started at `2864ab8`, not at compliance) and `:186-187` (fix or remove), Definition of done items 3 and 5 `:204-207` |

Third copies that must be deleted rather than updated, per I3: `tests/templates.sh:8-13` should read from the CLI registry instead of a local `MAP`; the per-skill touchpoint sentences should point at `TOUCHPOINTS`; the per-skill producer/reviewer sentences should point at `PHASE_PRODUCER`/`REVIEWERS`.

## Rejected candidates

| Candidate | Verdict | Why (evidence) |
|---|---|---|
| `forge-discover` owning landscape + prd + roadmap is a defect | **Rejected, justified grouping** | The three phases share one input (`brief.md`, `forge-bootstrap:14`) and one producer (`forge-discover:44-46`); each has its own `REQUIRED` entry (`cli/forge.py:12-15`), its own gate branch or generic gate (`:455-457`, `:462-471`), and its own reviews bound to its own hash (`:491-507`). Order is enforced once, centrally (`:307-309`), not per phase. No deliverable can be registered in the wrong phase (`phase_of` `:159-166`, `:327-328`). Splitting the skill would not add a check — the defect is the missing prerequisites text (F3), not the grouping. |
| `forge-analyst` producing four phases (bootstrap, landscape, prd, roadmap) is a defect | **Rejected, justified** | `agents/forge-analyst.md:6` states "one deliverable per delegation", so no context or authority accumulates across phases; the rights are "only its own deliverable" (`agents/forge.md:29`). The v2 baseline did the same (`v2-baseline/skills/forge/SKILL.md:1058`: `product-analyst` on phases 1 and 2). Unlike F6, nothing here asks the agent to make its own output concrete in a second artefact. |
| `forge-builder` owning build and validation is a defect *because the gates are not independent* | **Rejected as stated, kept as F4** | The gates are independent in code: `build` and `validation` are separate `PHASES` entries with separate `REQUIRED`, and `cmd_phase_start` forces build approved before validation (`:307-309`); `gate_problems` branches on the phase name, so the validation gate cannot be satisfied by build state (`:478-483` versus `:455-457`, `:464-469`). The defect is the producer identity and the content blindness of the report check, which F4 states in those terms. |
| `forge-rules` overlaps `forge-memory` | **Rejected, boundary is explicit** | `skills/forge-rules/SKILL.md:10` states the boundary ("Memory (journal, decisions, lessons) belongs to `forge-memory`. This skill never writes those files") and `skills/forge-memory/SKILL.md:17` states the rule ("One fact has one home"). The residual overlap is the `AGENTS.md` block, which is a CLI/init versus rules-phase conflict, filed as F8. |
| `forge-client-liaison` duplicates the touchpoint gate | **Rejected, the roles differ** | The liaison produces no verdict and writes no gate state (`agents/forge-client-liaison.md:2,12`), while the gate consumes its report (`cli/forge.py:526-537`). They are complementary. The real defect is that the gate does not pin the reviewed document (F7). |
| `forge-qa`/`forge-redteam` vs the design checklist is a contradiction between skills | **Rejected as a contradiction, confirmed as a carrier gap** | Both reviewers are generic by design (`REVIEWERS` is phase-independent, `cli/forge.py:24`), and `forge-design:30` adds a checklist on top. That is a deliberate layering, not a conflict; the defect is that the delegation header cannot carry the checklist (F9). |

## Open questions

1. **Who approves in client mode without the user?** `gate approve --evidence auto` is accepted for `landscape`, `architecture`, `rules`, `plans`, `build` in client mode (`cli/forge.py:538-540`), i.e. five of eleven gates have no human approval, while I1 treats the phase as owned by a skill. Should the target model mark those five as "agent-decided" in `status`, and does that weaken "one phase, one owner"?
2. **Should the producer be recorded in state?** Adding `producer` to the deliverable entry (`:340-342`) would make F1/F6 auditable after the fact, but it is agent-reported, like `--evidence` (`docs/STATUS.md:26-28`). Is an unprovable record worth the field, or does it create false assurance?
3. **Can `plans` legitimately stay with the architect?** The v2 reason (`v2-baseline/skills/forge/SKILL.md:309-313`) assumes plans are easy to write in a vacuum. If `plans_problems` gained a real contract-quotation check, would a separate producer still be needed? That is the cheapest way to avoid a ninth skill and a ninth agent.
4. **Does the validation split need a tenth phase?** F4 adds a check inside `validation`. Once the report must map every `TC-` and every applicable `OB`, is a separate skill still useful, or is the phase's ownership clear enough with `forge-validate` owning only the report template and procedure?
5. **Which suite owns the registry test?** `tests/templates.sh` already holds a private copy of the deliverable→skill map (`:8-13`). Should the registry check live there (it needs the CLI import anyway, `:7`) or in a new `tests/phases.sh`, given the repository counts suites in three places (`AGENTS.md:97`, `README.md:52`, `STATUS.md:5`)?
