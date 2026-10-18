# Target Formats

Where the rules go, and — the part that was missing — **the file that makes the
tool load them.**

## The defect this file fixes

The previous version of this skill treated instruction files as Markdown to be
written and stopped there. For several targets that produces a set of `.md`
files that **no tool reads**: correct, well-organised, entirely inert.

The concrete case: a project configured for OpenCode needs an `opencode.json`
whose `instructions` key points at the instruction file *and* the rules
directory. Without that file, `AGENTS.md` can still be discovered, and the entire
rules directory is silently ignored — so a full rule set that never loads. The
audited source project in this library's own history had exactly that file, and
one of the two retired profiles shipped **no wiring file at all**.

**Generating only the Markdown is an incomplete run.** The wiring file is part of
the deliverable.

## The five targets

| Target | Entry file | Rules location | Wiring file to write |
|---|---|---|---|
| **OpenCode** | `AGENTS.md` | `.opencode/rules/*.md` | **`opencode.json`** — see below |
| **AGENTS.md-native tools** — Codex, Copilot, Amp, Devin, Gemini CLI | `AGENTS.md` | — | none; discovery is automatic |
| **Cursor** | `AGENTS.md` (auto-discovered) | `.cursor/rules/*.mdc` | frontmatter per file, per `mdc-frontmatter-spec.md` |
| **Claude Code** | `CLAUDE.md` → a pointer | — | none |
| **Multiple tools** | `AGENTS.md` canonical | per target | each non-canonical file references `AGENTS.md` by section name |

### OpenCode — the required structure

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["AGENTS.md", ".opencode/rules/*.md"]
}
```

**Both entries are required.** `AGENTS.md` alone gets the entry file; the glob is
what loads every rule file in the directory.

Two properties of the glob that matter:

- **Adding a rule file needs no config edit.** The glob picks it up. This is why
  the rules directory is a directory and not a list of files in the config: a new
  rule that isn't wired in is a rule that never loads, and the failure is silent.
- **The glob loads every file in the directory.** A non-rule Markdown file placed
  there — a design document, a scratch note — becomes an instruction. Keep the
  directory to rule files.

**Optional, and derived rather than invented: the permission allowlist.**

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["AGENTS.md", ".opencode/rules/*.md"],
  "permission": {
    "bash": {
      "allow": [
        "{{the commands from the entry file's Commands table}}",
        "git status", "git diff *", "git log *",
        "git add *", "git commit *", "git branch *", "git checkout *"
      ]
    }
  }
}
```

The allowlist is **derived from the Commands table**, not composed separately —
a permission list that doesn't match the documented commands is one of the two
halves being wrong, and nobody notices which.

**What stays out of the allowlist, always:** `git push`, `git reset`, `git clean`,
`git rebase`, force-push in any form, and any dependency-directory deletion. The
allowlist covers the routine loop; the destructive operations are the ones where
a permission prompt is the right outcome. Include only commands the project
actually documents — an allowlist entry for a tool the project doesn't use is a
permission granted to nothing.

**Merge, never overwrite.** If the project already has an `opencode.json`, add
the `instructions` key and the permission block to it. Replacing the file
destroys the user's model, provider, MCP, and permission configuration.

### The hook configuration — a deliverable, not a follow-up

**The Markdown and the config are the same deliverable.** A gate that exists
only as prose in a rule file is enforced by the agent remembering it, and an
agent under time pressure does not remember it.

Write one of these, derived from what the project already uses:

```yaml
# lefthook.yml — polyglot, binary, parallel by default
pre-commit:
  parallel: true
  commands:
    lint-staged:
      glob: "*.{ts,tsx,js,jsx}"
      run: npx eslint --fix --max-warnings=0 {staged_files}
    secrets:
      run: gitleaks detect --staged --no-banner
commit-msg:
  commands:
    commitlint:
      run: npx commitlint --edit {1}
pre-push:
  commands:
    duplication:
      run: npx jscpd --threshold {{THRESHOLD}} src
```

**Three rules that decide whether it survives:**

1. **`core.hooksPath` must point at the committed directory.** `.git/hooks` is
   not versioned, so hooks written there exist on one developer's machine.
2. **`pre-commit` under ~10 seconds.** A hook that takes 30 seconds is bypassed
   with `--no-verify` within a week, and a bypassed hook is worse than no hook:
   it leaves everyone believing the property holds. That is why the commands run
   on staged files rather than the whole tree.
3. **Slow gates go to `pre-push` or CI**, not to `pre-commit`. The full test
   suite, the vulnerability scan, the build.

| Target | Hook mechanism | Note |
|---|---|---|
| Node / any git repo | `lefthook` (binary, parallel, polyglot) | The default recommendation |
| Node-only | `husky` + `lint-staged` | `npm install` already provides the runtime |
| Python-only | `pre-commit` | Isolated virtualenvs |
| **No hooks** | emit the command table anyway, and state the budget | Never silently skip this |

### AGENTS.md-native tools

`AGENTS.md` at the project root. Nothing else. These tools discover it
automatically, and a companion rules directory is not part of their convention —
splitting the rules across files for these tools means the agent has to be told
to go and read the others, which it will do less reliably than reading the one
file it was given.

**If the rule set is long enough that a single file is a problem, that is an
argument for OpenCode's or Cursor's split — not for a directory these tools
won't read.**

### Cursor

`AGENTS.md` is auto-discovered and is the portable baseline. `.cursor/rules/*.mdc`
adds what AGENTS.md can't express: **activation modes** — a rule that loads only
when matching files are open, or only when the agent judges it relevant, or only
on an explicit mention.

The full frontmatter syntax and the four activation modes are in
`mdc-frontmatter-spec.md`. Three rules for the split:

- **A `.mdc` file supplements, it does not restate.** Where a rule exists in
  `AGENTS.md`, the `.mdc` says "see `AGENTS.md` §X" — it does not restate the
  rule in its own words. Two phrasings of one rule is how they come to disagree.
- **Activation mode follows scope, not importance.** A rule is not always-apply
  because it matters. It is always-apply only if it is genuinely universal. This
  is the single biggest context-budget lever, and getting it wrong burns a large
  fraction of the window before the agent reads the task.
- **The always-apply tier is the budgeted one.** Keep it small: language
  conventions, commit format, the definition of done, a short banned list.
  Everything framework-specific or file-type-specific is glob-scoped.

### Claude Code

`CLAUDE.md` that points at `AGENTS.md`:

```markdown
# Claude Code instructions

This project keeps its agent instructions in `AGENTS.md` and its domain rules in
`.opencode/rules/`. Read `AGENTS.md` first.

Claude-Code-specific configuration (subagent definitions, hook configuration) is
described below.
```

**`CLAUDE.md` carries only what's genuinely specific to that tool.** A full
parallel copy is the exact failure the multi-target row exists to prevent: two
instruction sets that drift until they contradict.

**An existing `CLAUDE.md` is not overwritten.** It can already hold real content —
hooks, subagents, project-specific commands. Merge the pointer into it.

### Multiple tools

`AGENTS.md` is the single source of truth. Every other file either references its
sections by name or carries only what is genuinely tool-specific.

**The audit for a multi-target run is a divergence check:** grep the delivered set
for a rule that appears in two files with different wording, and for a tool file
that has stopped referencing the canonical one. Two full copies is the failure;
a mirror with cross-references is the goal.

## Choosing the target

**Ask, unless the answer is already visible.** The project often tells you:
an existing `opencode.json` means OpenCode, an existing `.cursor/` means Cursor,
and so on. When nothing exists, ask — this is a genuine question with a
different deliverable each way, and it is the one question in the interview that
cannot be inferred from the code.

**The user's own answer is the target.** Where someone has stated a preferred
structure — an entry file plus a rules directory wired through a specific
configuration key — **that decision is the specification, not a default to be
improved on.** A skill that invents a different structure than the one the user
decided on is not helping, however well the rules themselves are written.

## Monorepos

> This section owns the monorepo **wiring** — the config file each service needs.
> The **layout** — which files exist where, and what the root carries versus a
> service — is `stack-detection.md` §Monorepos. One owner per fact.

The wiring is per service, not only at the root:

```
/opencode.json                              ← root: what's universal
/services/api/opencode.json                ← that service's rules directory
/services/api/.opencode/rules/*.md
/services/web/opencode.json
/services/web/.opencode/rules/*.md
```

Each service's config points at **its own** rules directory, and at the
`AGENTS.md` in its own directory. The root's `instructions` covers the root's
`AGENTS.md`; it does not reach into service directories unless its glob says so,
and it must not — the service files carry the deltas
(`stack-detection.md` §Monorepos).

## Verification

**The delivery is not complete until the wiring is verified.** Three checks, in
order:

1. **The config file exists and is valid JSON** — or valid for whatever format
   the target uses. A malformed config silently disables the whole instruction
   set, and nothing reports it.
2. **Every file the config points at exists.** A glob that matches nothing is a
   valid configuration that loads nothing.
3. **The read-back test** — from a cold session, ask the agent for its build
   command, its definition of done, and which rule files govern a given area. If
   it can't answer, the wiring is wrong or the content is too diffuse. **Fix
   that before adding more rules, not after** — a larger rule set behind a broken
   wiring is a larger rule set that never loads.
