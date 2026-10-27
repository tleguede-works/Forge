# Docs

Two kinds of document live here.

- **Live** documents are read by an agent or a human to do the work today. A command, a
  gate, an invariant or an open decision refers to them, and a change to the CLI or the
  skills updates them in the same commit.
- **Archived** documents record a one-shot analysis whose outcome has shipped. They are
  history: nothing gates on them, and they are read only to understand why a mechanism
  looks the way it does.

A live fact has one home. The phase order, the deliverables and the gates belong to
`cli/forge.py`; the prose below describes them and never replaces them.

## Live

| File | Answers | Updated when |
|---|---|---|
| `STATUS.md` | What is built, what is tested, what is not, and what is untested on a live tool | A mechanism ships, changes or loses its test |
| `ESCAPE-HATCH-AUDIT.md` | Which shortcut is closed, by what, and which ones stay judgement | A hole is closed (a row and a suite case) or reclassified |
| `MIGRATION-v2.md` | What v2 did, what v3 does instead, what v3 deliberately dropped and what it has not ported yet | A capability is ported or a parity decision is taken |
| `parity-backlog.md` | The v2 capabilities v3 still lacks, each with its fix and its test | An item ships (it moves to the closed table) or a new one is found |
| `IMPROVEMENTS.md` | The decided intent and the priority order of the work not yet designed | A study starts, is decided or is implemented |

Read `STATUS.md` before claiming something works, and `IMPROVEMENTS.md` before proposing a
feature. `parity-backlog.md` is the open v2 debt; `MIGRATION-v2.md` is the record of what
was decided about v2, not a to-do list.

## Archive

| File | What it was |
|---|---|
| `archive/AUDIT-2026-10-19.md` | First full audit: reference graph, phase walk, 11 findings, each closed with a regression test |
| `archive/LOOPS.md` | Analysis of the review loop that never ended, and the guard built against it |
| `archive/OPENCODE-HOOKS.md` | Why the first OpenCode plugin crashed, and what the rewrite changed |
| `archive/forge-rules-analysis.md` | Weaknesses of Project Rules Architect, and what `forge-rules` replaced them with |
| `archive/forge-rules-provenance.md` | Where each rule template came from, read when maintaining the rule library |
| `archive/diagnostics/` | The five-part diagnostic of v3 against v2 (`archive/diagnostics/SYNTHESIS.md` holds the adjudicated list) that drove the 2026-10 correction |

An archived document is not evidence for a gate and is never cited as a rule. When an
archive still carries a fact that binds, the fact moves to a live document before the
archive is left alone.

## Adding a document

A new file lands at the root only if a command, a gate or an open decision refers to it.
Everything else starts in `archive/`.

`scripts/validate_repo.py` compares this file with the tree: an unlisted file under
`docs/`, or a listed file that does not exist, is a validator failure. That is what keeps
the root to what matters.
