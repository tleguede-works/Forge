# Monorepo Strategy

The single owner of **how a repository with several packages gets its rules**.
Before this file, the layout was described in three places
(`stack-detection.md`, `architecture-decision-guide.md`, `target-formats.md`)
and **none of the three mentioned a build tool**. A monorepo whose task runner is
Nx, Turborepo or pnpm workspaces has a different command for every one of the
things a rule set needs to name, and the old advice — "use the package's own
scripts" — is correct and useless, because the thing that matters is *which*
package and *which* command.

**This document owns layout and tooling. `target-formats.md` owns wiring.**
One owner per fact.

## Step 1 — Read the topology, do not infer it

Before proposing any layout, answer these four by reading files. Each is a
manifest or a config, not an impression.

| Question | Where the answer lives |
|---|---|
| Is this actually a monorepo? | More than one `package.json` / `pubspec.yaml` / `pom.xml`, or a workspaces field |
| What orchestrates it? | `nx.json` · `turbo.json` · `pnpm-workspace.yaml` · `lerna.json` · `settings.gradle` + composite builds |
| Which packages exist? | The workspace globs, or the modules declared in the root config |
| Which ones are in scope? | Not derivable. **Ask.** |

**A monorepo with no orchestrator is not a monorepo layout problem, it is a
missing-tool problem.** Say so rather than inventing a per-package convention
for a repository that has a root `Makefile` doing the job perfectly well.

## Step 2 — One probe per package, not one for the repository

Run `stack-detection.md` **in each package directory** and assemble the union. A
React service and a NestJS service in one repository need different overlays, and
a single overlay for the whole repository is wrong for one or more of them.

**Shared packages get the treatment too.** A `packages/ui` consumed by three apps
has a UI layer, an accessibility surface and a public API — the exclusions that
apply to a leaf application do not apply to it. The probe decides; do not shortcut
it because a package "is only a library".

## Step 3 — Layout

```
/AGENTS.md                          ← universal only
/packages/<shared>/AGENTS.md        ← the package's own rules
/apps/<app>/AGENTS.md               ← the app's own rules
```

**The root states only what is genuinely universal**, and the test is whether it
is true of *every* package:

- the git conventions and the chosen strategy (`git-workflow.md`);
- the **shape** of the Definition of Done, not its commands;
- the escalation ladder;
- the priority ranking;
- the memory-file protocol.

It does **not** carry a package's commands, its stack table, or its domain rules.

**A package states its deltas**, including its own commands and stack table. A
rule is **never repeated** between root and package: the root states it, the
package references it. Repetition is how the two drift, and the drift is silent
because both files still look correct.

**A package can tighten a root rule. It must not contradict one silently** — a
contradiction must be explicit and justified in the package file, or it is a
defect (`code-review.md` Pass 2).

**Tech overlays are never shared across packages with different stacks.** Two
packages on the same stack can share a core template's *content*, but each emits
its own copy: a shared file one package edits breaks the other.

## Step 4 — Commands, per package, discovered

This is the part the old layout advice missed. **The root command table is
often wrong for one or more packages**, because a monorepo's packages are built
through the orchestrator, not individually.

| Orchestrator | Root, all packages | One package | Only what changed |
|---|---|---|---|
| **Nx** | `{{nx run-many -t lint,test}}` | `{{nx test <pkg>}}` | `{{nx affected -t test --base=main}}` |
| **Turborepo** | `{{turbo run lint test}}` | `{{turbo run test --filter=<pkg>}}` | `{{turbo run test --filter=...[origin/main]}}` |
| **pnpm workspaces** | `{{pnpm -r run lint}}` | `{{pnpm --filter <pkg> test}}` | `{{pnpm -r --filter "...[origin/main]" test}}` |
| **npm workspaces** | `{{npm run lint --workspaces}}` | `{{npm test -w <pkg>}}` | `{{npm test --workspaces --since=origin/main}}` |
| **Maven reactor** | `{{mvn verify}}` | `{{mvn -pl <module> test}}` | `{{mvn -pl <module> -am test}}` |
| **Gradle** | `{{./gradlew check}}` | `{{./gradlew :<module>:test}}` | `{{./gradlew ...'}}` |

{{#if no-orchestrator}}
**This repository has no orchestrator.** Do not invent one. Use the root
`package.json` scripts with a path filter — `{{npm run lint -- src/apps/web}}` —
and say in the rules that the filtering is manual, so a stale filter is a known
failure mode rather than a surprise.
{{/if}}

**The "only what changed" command is the one that makes the gates affordable.**
A full monorepo gate on every commit is a gate nobody runs. `nx affected` and
`turbo --filter=...[origin/main]` exist so the pre-commit gate stays under its
10-second budget (`git-workflow.md` §Hooks) — **if** the rules name that command
rather than the whole-repository one.

## Step 5 — Gates across packages

From `quality-gates.md`, which owns the gates themselves. What changes here is
**which command runs them**.

- **Coverage is aggregated per package, and the threshold applies to the
  minimum**, never to the mean of means. A project at 95 % in ten packages and
  0 % in one averages to 86 % — and the one at 0 % is the one that broke
  (`quality-gates.md` §What "Coverage ≥ 80 %" means here).
- **Duplication is measured across the whole repository** with per-package
  scopes, because duplication that spans two packages is exactly the duplication
  worth finding and the one a per-package run cannot see.
- **A shared package's gate is stricter than an app's.** Its consumers cannot fix
  what it ships them, so the boundary has to hold at the source.
- **The root `AGENTS.md` names the gate command; each package names the scoped
  one.** A package that has no scoped command runs the root one, and says so.

## Step 6 — Boundaries between packages

The rules that make a monorepo a monorepo rather than a folder of projects that
happen to share a repository.

- **A package imports another package only through its public entry point.** Not its
  internals — that couples the two and makes the dependency unusable when the
  first one refactors.
  - Verify: `{{the import-boundary lint rule for this orchestrator}}`.
- **Dependencies point one way, and the graph is acyclic.** A dependency cycle
  between packages is invisible to a per-package build and only appears in CI.
- **Cross-package changes are one change.** A change to a shared package and its
  consumers is not two commits, it is one — `git-workflow.md` §Commits,
  independently revertible.
- **Version and publish discipline**: internal packages are versioned together
  or with changesets, not bumped by hand. Hand-bumped internal versions drift
  from what the workspace resolves.

## When there is no shared code

**Not every repository with two packages is a monorepo.** If the packages share
a CI, a lockfile and nothing else — no shared types, no shared components, no
cross-imports — then two independently-generated rule sets plus one root file
covering git conventions is the honest structure. Forcing a monorepo layout on
two projects that share a repository produces shared-file coupling for a
coupling that does not exist.

**Ask which it is.** The answer changes the layout, the aggregation rules and
the gate commands, and it is not derivable from the manifests.