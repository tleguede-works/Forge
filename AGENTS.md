# Forge — instructions for agents

This repository is the Forge kit: a gated, CLI-enforced workflow that turns an idea
into a code-ready plan. It is not a Forge-managed project, so it holds no `.forge/`.
Run `forge init` inside `labs/<name>`, never at this root: at the root it mixes the
kit's state with the product it builds and injects a project block into this file.

Repository files are English. A delivered project's files under `.forge/` follow that
project's language.

## Read first

| File | Answers |
|---|---|
| `cli/forge.py` | The phase order, the required deliverables, the gates and the checks |
| `skills/forge/SKILL.md` | Which skill owns which phase, and the golden rules R1–R11 |
| `docs/STATUS.md` | What is built, what is tested, what is not. Trust its prose, not its counts (Known traps) |
| `docs/ESCAPE-HATCH-AUDIT.md` | Which shortcuts are closed, by what, and which stay judgement |

Read `docs/IMPROVEMENTS.md` before proposing a feature: it holds the decided intent
and the priority order.

## The executable truth

`cli/forge.py` is the source of truth for `PHASES`, `REQUIRED`, `PREFIX_PHASE`,
`TOUCHPOINTS`, `RECHECK_PHASES` and every gate check. A skill, an agent or a doc that
disagrees with it is wrong. Settle a disagreement in all three places in one change:
the code when the code is wrong, the prose, and a test. Editing prose to match a bug
freezes the bug.

Phase numbers in skill frontmatter are stale: the `compliance` insertion shifted every
number after `landscape`. Name phases, never numbers.

## v2 parity

`https://github.com/tleguede-works/ship-clean-skills` is the v2 baseline. Before
declaring a capability new, look for its predecessor there.

- A capability v2 had and v3 lacks is a regression until `docs/MIGRATION-v2.md`
  records it as removed on purpose with the reason. Silence is a regression.
- Porting is not rediscovery: the v2 implementation and its tests encode the failure
  they were built to prevent. Read them before writing a replacement.
- A v3 test weaker than its v2 counterpart is a regression the suite cannot see.
  Compare the mutations, not the names.
- v3 ships no CI and no repository-wide validator. Nothing catches a broken reference
  except the suites and `tests/templates.sh`, so a change with no suite case is a
  change with no check.

## Invariants

Cite the ID when you refuse a request or stop.

- **I1 One owner per phase.** `bootstrap` → `forge-bootstrap`; `landscape`, `prd`,
  `roadmap` → `forge-discover`; `compliance` → `forge-compliance`; `design` →
  `forge-design`; `architecture` → `forge-architect`; `rules` → `forge-rules`;
  `plans` → `forge-plan`; `build`, `validation` → `forge-build`. `forge` routes,
  `forge-memory` is cross-cutting and owns no phase.
- **I2 Transitions come from the CLI.** `forge status` prints the `next:` line. Act on
  it. A phase inferred from a conversation, a skill section or a number is a guess,
  and the gate refuses guesses.
- **I3 One fact, one home.** The phase order lives in `cli/forge.py` and reaches the
  agent through `forge status`. Deliverable paths live in `REQUIRED`. A skill states
  its own phase and points at the CLI for the order. A second copy is a defect: the
  copies drift, and a weak model follows the stale one.
- **I4 Every closed shortcut has a test.** A hole closed in the CLI gets a case in
  `tests/` and a row in `docs/ESCAPE-HATCH-AUDIT.md`. A hole closed without a test
  reopens on the next refactor.
- **I5 Normative files carry no soft wording.** Run
  `python3 cli/forge.py lint-rules <paths>` after editing a skill, an agent or
  `AGENTS.md`. Zero hits is the pass condition. Generated rule sets face
  `forge rules audit`: a command in backticks and a pass condition per gate, no vague
  prose.
- **I6 The suites run on POSIX only.** All 16 need a POSIX shell and `python3`; six
  call `sed -i` and `compliance.sh` calls `date -d`. Run them in the devcontainer or a
  Codespace, or let `.github/workflows/ci.yml` run them. A suite reported as passing from
  native Windows was not run.
- **I7 Preserve the injected block.** `forge init` writes `<!-- forge:start v3 -->` …
  `<!-- forge:end -->` into a project's `AGENTS.md`. Edit outside the markers. Moving,
  duplicating or deleting them breaks the project's link to its CLI.
- **I8 One slice at a time.** `forge slice start` refuses a second concurrent slice,
  and the build gate reads `state.json`, not the plans.
- **I9 The user's words are the only evidence for a decision.** `--evidence` and
  `--user-evidence` take an actual statement from the user. A paraphrase and an
  invention are the same defect.
- **I10 A deliverable the CLI cannot check is not a deliverable.** A new skill, phase
  or deliverable names the subcommand and the refusal that enforce it. When the check
  does not exist, add the subcommand and a suite case proving the refusal, in the same
  change. A deliverable only a reviewer reads is a request, not a gate.

## Repo map

| Path | Holds |
|---|---|
| `cli/forge.py` | The whole CLI. One file, Python 3.9+, stdlib only |
| `skills/<name>/SKILL.md` | A skill under 100 lines, plus its `references/` |
| `agents/*.md` | Subagent definitions and their write rights |
| `hooks/forge_hook.py`, `hooks/opencode-forge.js` | The Claude Code and OpenCode loop guards, which mirror each other |
| `tests/*.sh` | 16 POSIX suites, one per mechanism |
| `scripts/install.py` | Global and local install, hooks, manifest, Windows shim |
| `scripts/validate_repo.py` | The repository validator: skill names, references, phase registry, templates, documented commands, suite listing |
| `.github/workflows/ci.yml` | Lint, validator, then every suite on push |
| `docs/` | Status, improvements, audits, migration, loop analysis |

## Commands

```bash
python3 cli/forge.py lint-rules AGENTS.md skills agents            # expect 0 hits
bash tests/<suite>.sh                                             # one suite
for t in tests/*.sh; do bash "$t" || exit 1; done                 # all suites, POSIX
python3 scripts/install.py --scope local --project labs/<name>     # install into a lab
```

Every command here is POSIX. On Windows, `python3` resolves to the Microsoft Store
stub and no POSIX shell exists: there, `python` runs the CLI and the suites do not run
at all.

`tests/templates.sh` is the canary: it asserts that every template holds the sections
the CLI parses. Run it after touching a template or a `REQUIRED` entry.

## Change-impact pass

Run every item for a change to a phase, a skill, the order or a deliverable. Skipping
this list is how the count and phase-number drift appeared.

1. `PHASES`, `REQUIRED`, `PREFIX_PHASE`, `TOUCHPOINTS`, `RECHECK_PHASES` in
   `cli/forge.py`.
2. The phase-to-skill mapping in `skills/forge/SKILL.md` and the changed skill's
   frontmatter.
3. The agent rights table in `agents/forge.md` and the producer named in the skill.
4. The template under `skills/<name>/references/`, and `tests/templates.sh`.
5. A suite in `tests/` that fails before the change and passes after.
6. `docs/ESCAPE-HATCH-AUDIT.md`, `docs/MIGRATION-v2.md`, and the counts and suite lists
   in `docs/STATUS.md`.
7. A walkthrough on a fresh `forge init` in a temp directory, then in a `labs/` project.

## Quality bar

**Skills.** Frontmatter `name` equals the directory name. `description` states the
trigger and names the phase. The body stays under 100 lines; rules and formats live in
`references/`. Every format the CLI parses lives in one `references/*-format*.md` that
says so in its first line.

**Templates.** Every template holds the headings the CLI parses, carries `{#anchor}` on
a heading that a translated deliverable needs, and contains no section the CLI does not
check and no check the template cannot satisfy. A section that only says "describe X"
is a defect: it produces placeholder prose that passes review by looking filled.

**PRD.** Stable IDs `B<n>`, `E<n>`, `V<n>`, `C<n>`, `L<n>`, one per line, each with its
source. Every `L<n>` cites an `OB-<n>` of the compliance register and every applicable
`OB` appears as an `L<n>`, in both directions. Section 9 lists open questions with an
owner and a date. Section 10 is `## 10. Out of scope {#out-of-scope}`, and a dropped
requirement keeps its ID with its reason. No empty section survives the gate.

## Integration labs

`labs/` holds throwaway products built with Forge to exercise the whole system: a
mobile banking app, a non-English project, an imported brownfield repository. A lab is
a real project driven through every phase by a real model, not a unit test.

- Nothing inside `labs/` is committed. `.gitignore` keeps only `labs/.gitkeep`. A lab
  that must survive becomes a `tests/` suite, because a lab deleted tomorrow proves
  nothing.
- Build one with `python3 scripts/install.py --scope local --project labs/<name>`, then
  `forge init --name <name>` inside it, then drive `forge status` as a client would. A
  lab that calls the kit's `cli/forge.py` tests the kit, not an installation.
- A lab reaches `validation` before it counts. Stopping at the PRD tests the PRD, not
  Forge.
- A defect a lab exposes becomes a `tests/` case before the fix counts as done. The lab
  is the story, the suite is the regression.

## Known traps

These are live today. Closing one is a code change, not an edit to this file.

- `.forge/progress.md` is a derived view, never evidence and never hand-edited:
  `forge progress` regenerates it from `state.json`, `plans/index.md` and the plans, and
  the build and validation gates regenerate it instead of refusing a stale copy.
  `forge progress --check` is the refusal, and CI runs it.
- `prd_problems` measures a requirement after removing its source clause, so
  `- B1 x (source: user-stated)` is refused. A new `B`, `E`, `V`, `C` or `L` needs 10
  characters of statement plus a source.
- `validation_problems` reads the five-column table
  `test case | verifies | command | result | evidence` and the `TC-` cases of the plans.
  An ID written after the out-of-scope heading of the PRD is treated as withdrawn and
  does not count as live.
- `doc()` in every `tests/*.sh` runs `sed -E 's/<[^>]*>/sample text/g'`, so a fixture
  replaces each template token wholesale. A case that proves a token is refused writes
  the token itself instead of going through `doc()`.
- `forge.TEMPLATES` is the only registry of template paths. A new structure needs its
  key in `HEADINGS` or `ROW_RULES`, a template under `skills/`, and an anchor `{#slug}`
  on every heading, or `tests/templates.sh` and `scripts/validate_repo.py` both fail.
- `hooks/forge_hook.py` and `hooks/opencode-forge.js` mirror each other. A change to one
  needs the same change and a test in the other.
- `docs/STATUS.md` and `docs/MIGRATION-v2.md` print skill and agent counts by hand.
  `scripts/validate_repo.py` checks the suite list and the phase registry, not those
  counts: recount by hand when a skill or an agent is added.
- The bash suites need a POSIX shell. On this Windows host `python3` is the Microsoft
  Store stub and `bash.exe` is a WSL stub, so a suite reported as passing from here was
  not run. `tests/templates.sh`, `tests/validation.sh` and `tests/progress.sh` hold a
  Python block that runs on its own; CI is the first full run of all of them.
- The v2 `forge` and `project-rules-architect` skills are quarantined in
  `~/.agents/skills-quarantined-v2/`. They describe a different phase model. Do not
  reinstall them: `docs/MIGRATION-v2.md` records the same instruction.

## Definition of done

Report each item with its command and its result.

1. `python3 cli/forge.py lint-rules AGENTS.md skills agents` prints `0 soft-wording
   hit(s)`.
2. Every suite in `tests/` passes on POSIX, or you name the suite you could not run and
   why.
3. The change-impact pass is complete, or you list the items that do not apply.
4. A defect found in a lab has a `tests/` case that fails without the fix.
5. The CLI, the skills, the templates and the prose agree, and the diff touches every
   copy of the changed fact.
