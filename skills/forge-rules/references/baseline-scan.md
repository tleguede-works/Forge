# Baseline Scan

Runs **before** any rule is drafted. Not an intake questionnaire — a set of
commands whose output decides three things: which templates apply, which of the
two quality modes the project is in, and what the Definition of Done can
honestly say.

## Why this is a scan and not an interview

An interview produces **claims**; a scan produces **measurements**. A claim can
be wrong and nothing downstream notices — the rules are written against it, and
the first session that contradicts it is a session spent finding out why the
rules do not match the project.

The failure this prevents is specific and was measured: a project whose rule
set asserted a lint command that did not exist in any `package.json` script. The
rules were internally consistent, the audit was clean, and the agent discovered
the gate was fictional on its first commit.

**A rule set written without a scan is a rule set written from a guess.**

## The four questions, and the command that answers each

Run what exists; record what does not. **"The command is not available" is a
result, not a failure to report** — it changes what the rule set can say.

| Question | Where the answer lives | If unavailable |
|---|---|---|
| What is the stack, exactly? | The manifests, resolved | Cannot proceed — ask |
| Do the tests pass today? | The test runner, in CI configuration if present | Record `absent` |
| What is the coverage? | The coverage report | Record `absent`; DoD line becomes aspirational |
| What is the duplication? | The duplication detector | Record `absent`; gate emitted with status |
| What vulnerabilities exist? | The ecosystem audit | Record `absent` |
| Do lint and typecheck pass **now**, before any change? | Their own commands | Record `absent` — **and say so in the report** |

That last row is the one that changes behaviour most often. A project whose
lint is red before anyone touches it cannot receive a rule saying "lint must be
green" without also receiving the fact that it is not, today. Writing the rule
alone produces a Definition of Done that is red on arrival and therefore
ignored.

## Procedure

1. **Read the manifests.** Resolve the exact installed version of every
   dependency. Not the range — the resolved version.
2. **Run each gate that can run**, from the project's own scripts, at the
   project root, and **capture the output verbatim**. The exit code alone is not
   the measurement; the output is what gets quoted in the report.
3. **Record the timestamp and the tool version.** A baseline without a date is
   an anecdote.
4. **Write `docs/quality-baseline.md`** — the file, the gate, the value, the
   date, the tool version. This is a project artefact, not part of the rule set.
5. **Decide the mode** below.
6. **Report the scan result to the user before drafting anything**, including
   every `absent`.

### What to do when a tool is missing

Three options, in order of preference:

1. **The project already has an equivalent** — use it. A project with
   `sonar-project.properties` does not need `jscpd` installed to know its
   duplication.
2. **The ecosystem ships one** — use it. `npm audit` needs no installation;
   that is a feature.
3. **Neither** — propose the installation as part of the deliverable, and
   **mark the gate `absent` until it is actually installed**. Do not emit a
   gate that cannot run as though it could.

**Never** write "coverage: 80 %" because 80 % is the threshold. A baseline is
what the project *is*, not what it is *required to become*. The gap between
those two numbers is the whole content of `quality-gates.md` §Status.

## Mode selection

Determined from the scan, **not asked**. Asking makes it a preference; deriving
it makes it a consequence, and a consequence is consistent between two runs of
the same project.

| Condition | Mode | What the rules say |
|---|---|---|
| No source files | `greenfield` | All gates apply from the first line. No exemptions |
| Source files, **every** measured gate green | `greenfield` | Same. The project is already at the threshold |
| Source files, **at least one** gate red | `ratchet` | The existing value is recorded, and **regression** is what fails |
| `greenfield`, and a gate's tool is missing | `greenfield-dette` | The gate is emitted with status `absent` and the install command |

### Why the ratchet mode is not a concession

A project at 22 % duplication cannot be told to be at 3 % today. A gate that
says otherwise is red from the first commit, and **a gate that is always red is
not a gate** — it trains the agent to bypass it, and a bypassed gate is worse
than no gate because it leaves everyone believing the property holds.

So the ratchet mode keeps the *property* and drops the *immediacy*:

- The measured value is **recorded with a target and an owner** — it is a debt
  with a name, not an accepted fact.
- The gate fails on **regression**, using the baseline mechanism the tools
  provide (`--baseline-from-ref`, `--fail-on-new-clones`).
- The debt has a **route**: which file, what effort, what removal condition.

This is the difference between "the project may be at 22 %" and "the project is
at 22 %, and here is what lowers it". Only the second one changes behaviour.

## The report

State it before drafting. Six lines, and every one of them is a fact rather
than a judgement:

```
Stack        : {{framework version}} + {{language version}}
Gates        : {{n}} green, {{n}} red, {{n}} absent
Mode         : {{greenfield | ratchet | greenfield-dette}}
Worst gate   : {{name}} — {{value}} against a threshold of {{threshold}}
Not installed: {{tools}}
No code yet  : {{yes/no}}
```

**"No code yet" gets its own line** because it is the single fact that changes
the selection the most, and the one most often left implicit. On a project
without code, the domain selection is a **proposal**, and the report must say so
rather than presenting a table that turned out to have nothing to match.

## What this scan is not

- **It is not an audit.** It does not judge the code, and it produces no
  findings about quality beyond the gate values.
- **It is not the adoption protocol.** An existing project's *conventions* are
  detected in Step A (`existing-project-protocol.md`). This scan measures
  *numbers*; that step reads *patterns*. They run together, and neither
  substitutes for the other.
- **It is not a one-off.** Re-run it when a tool, a threshold, a major
  dependency or the CI configuration changes. A baseline older than the tool it
  was measured with describes a configuration that no longer exists.