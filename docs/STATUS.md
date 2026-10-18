# Build status

Language rule: repository files in English; deliverables in `.forge/` follow the project language.

## Done and tested (tests/e2e.sh, tests/design.sh, manual installer runs with a fake HOME)
- CLI: init, status, mode, phase order, register, hash-bound QA and Red Team reviews, gate (check, approve with evidence, client-mode auto rule), memory (resume, checkpoint, decide, learn, log), hooks status, lint-rules, AGENTS.md block injection, design check (one screen per file, ranked anatomy, rules H1 and H2, layout defined, layout regions covered by plans).
- Gate integration: design phase runs the design check and requires every screen to be registered; plans phase requires every layout region to have a task.
- Skills: forge, forge-memory, forge-discover, forge-design, forge-architect, forge-plan, forge-build, forge-rules (with references and templates). forge-rules replaces Project Rules Architect; analysis in docs/forge-rules-analysis.md.
- `forge rules audit`: ten checks ported from Node to Python (wiring for opencode, claude or agents; index; placeholders; cross-references; thresholds; no Forge coupling; contamination; unenforceable prose; gates are commands; budget with a hard total). One mutation test per check in tests/rules.sh.
- Agents: forge (orchestrator), forge-qa, forge-redteam, forge-analyst, forge-designer, forge-architect, forge-builder, forge-client-liaison.
- CLI also covers: check coverage, premises, plans; slice start and done with evidence; phase reopen (resets downstream reviews); client ask, list, resolve, sweep. Tested by tests/flow.sh.
- Installer: scripts/install.py (auto-detects Claude Code and OpenCode, converts agent frontmatter, merges hooks into settings.json without touching foreign hooks, idempotent, --uninstall). install.sh tested on Linux.

- forge-rules templates and references: the 120 soft-wording hits are rewritten; they are inside the lint scope now. Only `references/banned-wording.md` is exempt, by file name, because it lists the banned words.
- Integrity: state.json is sealed; a hand edit is refused (R2). Approved deliverables that change afterwards are reported as DRIFT and block the next phase. tests/adversarial.sh covers 10 shortcut scenarios.

- Escape-hatch audit done: docs/ESCAPE-HATCH-AUDIT.md (16 shortcuts closed by the CLI, 7 named as judgement). Migration notes: docs/MIGRATION-v2.md.
- Kit integrity (`forge kit verify`, manifest written by the installer) and `forge client report` are in and tested (tests/install.sh, tests/flow.sh).
- Reviewer reports are bound to a fixed path and hash; dismissed findings must cite a recorded decision.

## Known limits (judgment, not mechanical)
- A reviewer report is a JSON file written by an agent; the CLI validates its shape and binds it to the deliverable hash but cannot prove a separate agent wrote it.
- `--evidence` text for approvals is recorded in the journal; the CLI cannot prove it quotes the user.
- The seal detects accidental or careless edits to state.json, not a determined forger who reads the CLI source.

## Written, not verified on a live tool
- install.ps1 and the Windows forge.cmd shim: never run on Windows.
- OpenCode plugin hooks/opencode-forge.ts and OpenCode skill and agent directories.
- Claude Code: PostToolUse exit code 2 reaching the model; running the orchestrator as main agent (`claude --agent forge`).
- `npx skills add` layout: skills/ folders follow the standard layout, not yet tested with the tool.

## Pending
Nothing on the build list. The items under "Written, not verified on a live tool" need a real Claude Code, OpenCode and Windows run.
