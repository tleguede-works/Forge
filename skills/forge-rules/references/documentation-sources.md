# Documentation Sources

The mechanism that keeps the skill from inventing rules. A rule about how a
framework behaves, asserted from memory, is the most dangerous thing this skill
can emit: it reads as authoritative, it is almost right, and the failure
it causes is a silent runtime bug rather than a compile error.

**The rule this file enforces: every technology-specific claim is traceable to a
rung below, or it does not ship as a rule.**

## The ladder

Work down. **Stop at the first rung that answers the question.** Each rung is
more expensive and less authoritative than the one above it.

### Rung 1 — The project itself

The most authoritative source, and the one most often skipped in favour of
searching.

- **The manifest** — the exact installed version of every dependency. The version
  in the manifest overrides any general knowledge about the framework.
- **The installed source** — `node_modules`, the package cache, the resolved
  dependency tree. The code that will actually run is the ground truth about
  what the library does.
- **Type definitions** — the shipped declaration files state the real API
  surface, including the deprecated parts that are still present.
- **The framework's own configuration file** in the project — what is enabled,
  which options are set, which experiments are on.
- **The lockfile** — the resolved tree, which can differ from the manifest's
  ranges.
- **The project's own tooling output** — a linter's rule list, a type-checker's
  config resolution, a framework's own diagnostic command. These state what is
  actually enabled, which is not always what the config file appears to say.

**Why first:** the project is the only source that cannot be wrong about this
project. A documentation page describes the framework; the installed package
describes *this* version of it in *this* configuration.

### Rung 2 — What the framework ships with the project

Many ecosystems bundle their own documentation or agent-facing material in the
project.

- **A bundled documentation index or agent skill pack.** Some frameworks ship a
  machine-readable index of their documentation, often at a well-known path,
  which exists precisely because prose documentation assumes knowledge the reader
  lacks. It also commonly carries **corrections to known model
  misconceptions** — which makes it higher-value than the prose docs, not lower.
- **A local documentation directory**, a vendored copy, an offline package.
- **The framework's own example directory** in the repository.

Check for these **before** searching the web. A framework that ships guidance for
agents has written it to answer exactly the questions this run has.

### Rung 3 — Configured MCP servers

**Check what is actually connected before assuming anything is or isn't
available.** The available set differs per session and per project, and a
documentation server that is connected will be faster and more current than a web
fetch.

- A general documentation server resolves a library identifier and returns
  version-matched content.
- **Framework-specific servers** often expose version-pinned documentation, API
  references, and — valuably — example code for the installed major version.
- A project can have its own server exposing internal APIs, which no public
  documentation describes at all.

**This rung is also where project-specific knowledge lives** that no public
source has: an internal service's real contract, a private package's behaviour.
For a project depending on an internal system, this rung is more authoritative
than rungs 4 and 5 combined.

### Rung 4 — Official versioned documentation

Only when rungs 1–3 don't answer it. Two constraints, both load-bearing:

- **The exact pinned version.** A documentation site serves one version by
  default, often the newest, and the newest is not this project. Fetch the
  versioned path.
- **The official source** — the framework's own documentation, not a tutorial, a
  blog post, a course, or an answer on a forum. A tutorial is someone's
  particular use of the framework; a versioned reference is what the framework
  does.

**For a fast-moving framework, the version is not a detail.** A framework that
ships breaking changes per release is exactly the case where a model trained on
an older version will confidently write plausible code against an API that moved.

### Rung 5 — The locally installed tooling

- **The CLI's own `--help`** for the installed version. For anything invoked from
  a command line, this is authoritative about the flags that version accepts, and
  it is right there.
- **A generator's output** — scaffolding a small throwaway example to see what
  the tool produces. Slower than reading, faster than guessing, and it shows what
  the tool *actually does* rather than what it documents.
- **The build's own diagnostics** — a configuration warning states a real
  misconfiguration, in the project's actual state.

### Rung 6 — Web search

Last resort, and only for what the ladder genuinely can't reach.

Scoped narrowly, per the discipline already in this skill: a specific question
about a specific version, not "best practices for X." Search for a **version
release note or a migration guide** when the question is "did this change between
these two versions" — that question has a precise, authoritative answer, and
release notes are it.

**A search result is a lead, not a source.** Anything load-bearing goes back
through the ladder to a rung 1–5 source before it ships.

## The citation requirement

**Every technology-specific rule carries a provenance line**, in one of these
forms:

```
<!-- source: package.json — installed version, verified against rung 1 -->
<!-- source: official docs, <framework> v<major>.<minor> — <section> -->
<!-- source: <CLI> --help, installed version -->
<!-- source: project convention, <path:line> -->
<!-- source: project decision — ADR-<NNN> -->
```

**The five forms, and what each means:**

| Form | Means | Confidence |
|---|---|---|
| Rung 1 — the project | Verified against what's installed | Highest. If this disagrees with a documentation page, the project wins |
| Rung 2 — framework-shipped | From material the framework ships for exactly this purpose | High |
| Rung 3 — MCP server | From a documentation source, version-matched | High |
| Rung 4 — official versioned docs | From the framework's own documentation for this version | Good. Note it is documentation, not the installed artifact |
| Rung 5 — installed tooling | From the tool itself | Good |
| **ADR** | **Not a framework fact — a decision this project made.** The most authoritative kind, because it's a choice rather than an observation |

**A rule with no provenance line is a defect.** Not "an incomplete rule" — a
defect, because it means the claim's basis is unrecorded, and a reader cannot
tell a verified fact from a plausible guess. Both look identical on the page.

## When a claim can't be sourced

**It does not become a rule.** It becomes one of three things:

1. **A question to the user.** "Does this project's backend accept a partial
   update, or is it a full replacement?" is a real question with a real cost
   either way, and the project can know the answer.
2. **A project decision, proposed as an ADR.** "This project uses partial
   updates" — if it turns out to be wrong, the wrongness is discoverable and
   correctable, which a confidently-stated framework fact is not.
3. **An entry in `external-system-contracts.md`, marked unconfirmed.** If the
   claim is about an external system and a session can confirm it, the entry is
   the right home — with the confirmation requirement stated.

**Never the third option: shipping it as a rule with a hedge.** "Probably X, but
verify" is the worst of both — it carries the authority of a rule and the
reliability of a guess, and the agent will act on it.

## The fast-moving-SDK rule

**Some frameworks change faster than the gap between a model's training data and
the installed version.** For those, the project's entry file gets a mandatory
verification section (`core/entry-file.md`, the conditional section), stating:

- how to read the installed version,
- where the version-matched documentation is,
- that the answer is never from memory.

This is not a stylistic preference. It exists because the failure mode it
prevents is invisible: the generated code compiles, looks idiomatic, and calls an
API that moved. The project's first real session discovers it, and by then the
wrong pattern is in the codebase and in the rules that describe it.

**Which frameworks get this section is a judgement, and it is made
explicitly** in the emitted file rather than assumed. The signal is a release
cadence that ships breaking changes, and a major version numbering that tracks
the platform underneath it.

## The tool-selection rule

**Before a tool becomes a rule, it clears four checks. A tool that fails any of
them is described in the output as a proposal, not emitted as a gate.**

| Check | The failure it prevents |
|---|---|
| **Is it installed, or does one command install it?** | A gate the project cannot run is a gate nobody runs |
| **Is it maintained?** — a release inside ~12 months, an issue tracker that responds | A rule depending on an abandoned tool outlives the tool |
| **Does it exit non-zero on a violation?** | A tool that warns produces a gate that is always green |
| **Does the project already have something equivalent?** | A second linter is a second opinion, not a better one — and a second thing to maintain |

The third check is the one that gets skipped, and skipping it is the most
expensive: **a tool that cannot fail cannot gate.** Confirm it on the project's
own code, where a violation already exists. A detector configured against a
clean codebase proves nothing — it is equally consistent with "no duplicates"
and with "the tool is not looking at this directory".

### Cost, before adoption

One tool per concern, and a concern already covered costs nothing to keep.
Adding a tool adds a version to pin, a config to maintain, a CI minute, and a
failure mode on the day it changes behaviour. **Prefer the tool the ecosystem
already ships** — it needs no installation, no config, and no upgrade.

The honest ordering, when a project's own tooling does not cover a gate:

1. **The ecosystem's own command** — `npm audit`, `mvn verify`, `go vet`.
2. **A single tool that covers several gates** — `jscpd` reports duplication,
   dead code and complexity from one binary, so it costs one install rather than
   three.
3. **Nothing, and say so** — record the gate as `absent` in the baseline. A
   missing gate is visible; an unmaintained dependency on a scanner is not.

### And record which version

A tool's flags and its output format change. **Pin the version and write it in
the rule**, because a threshold check that starts reporting a different field
after an upgrade fails silently — the gate keeps running, the numbers change,
and nobody knows they mean something else now.

## Applying this to the backend overlays

The two backend overlays in this library (`node-nestjs.md`, `java-spring.md`)
were built from this ladder — rungs 3 and 4 — because no audited project existed
for either stack. Every rule in them carries a `source:` marker, and both files
declare their status as documentation-sourced and never applied end-to-end.

**That declaration is not optional and not pessimistic.** It is the honest
statement of what a reader needs to know: the mechanism is documented, the
delivery path is unproven. The first project to use an overlay finds out what was
wrong, and the fix goes in the overlay file — which is what the next project
copies. Leaving the status off would let an unvalidated overlay accumulate
confidence it hasn't earned.
