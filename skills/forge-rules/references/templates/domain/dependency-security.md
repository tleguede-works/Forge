# Template · Dependency Security

<!--
GENERATOR NOTES — delete this block in the emitted file.

Le propriétaire du **processus** de vulnérabilité : détecter, corriger,
prouver que c'est corrigé.

Ce qui existait avant, et ce qui manquait : `security.md` parle de secrets,
de jetons et d'autorisation — c'est le code de l'application. Les
**dépendances** n'avaient aucun propriétaire, et une règle sans propriétaire
n'est appliquée par personne. Le mot « dépendance » apparaissait dans
`coding-standards.md` §Dependencies, qui parle d'épinglage et de verbe
d'installateur — pas de risque.

La distinction avec `quality-gates.md`, à tenir strictement — c'est le genre
de frontière qui disparaît et qui produit deux fichiers qui se contredisent :

  - `quality-gates.md` §The Gate Table → **une ligne du tableau**, la
    commande qui échoue si le scan trouve quelque chose. Le quoi et le seuil.
  - ici → **la marche à suivre quand la ligne échoue.** Le comment, et
    surtout ce qui empêche un correctif automatique de casser l'application.

Ne met PAS ici : la gestion des secrets (`security.md`), les seuils et le
baseline (`quality-gates.md`).
-->

# Dependency Security

## Scanners

**Use what the ecosystem already ships before adding anything.** A tool added
for this one job is a tool to maintain, to version, and to explain in six
months.

| Ecosystem | Baseline command | Broader set | Notes |
|---|---|---|---|
| Node (npm / pnpm / yarn) | `{{npm audit --audit-level=high}}` | `{{osv-scanner scan source -r .}}` | `npm audit` queries only the npm advisory DB; OSV federates GHSA + npm + PyPI + … |
| Node (bun) | `{{bun audit}}` | `{{osv-scanner scan source -r .}}` | Same advisories, different resolver — check the lockfile is the committed one |
| Java (Maven) | `{{mvn dependency-check:check}}` | `{{osv-scanner scan source -r .}}` | OSV matches Maven coordinates exactly; OWASP Dependency-Check matches CPE and is noisy — prefer OSV unless NVD-specific reporting is required |
| Java (Gradle) | `{{gradle dependencyCheckAnalyze}}` | same | Same plugin as Maven |
| Dart / Flutter | `{{flutter pub outdated}}` + the Dart advisory feed | `{{osv-scanner scan source -r .}}` | Dart is an OSV ecosystem |
| Any, in CI, container images | — | `{{osv-scanner scan source -r .}}`, `{{trivy fs .}}` | OSV is the precise one; Trivy is the broad one |

**Scan the lockfile, not the manifest.** A manifest range (`^1.2.0`) does not
tell you what is installed; a lockfile does. Every scanner below resolves the
real tree, which is why a stale `node_modules` produces a clean report on a
vulnerable tree.

**Pin the scanner version** in the tool config. A gate whose behaviour changes
on its own is a gate that gets disabled the first time it surprises someone.

## Severity and Scope — decide these before the first finding

Two decisions, made once, written here. Left undecided, they get re-argued on
every finding, and the argument always ends in "let's just ignore it".

| Decision | This project | Why |
|---|---|---|
| Which severities block? | `{{high and critical block; moderate and low are tracked, not gating}}` | A gate on every severity is a gate that fires constantly and is therefore ignored |
| Are dev dependencies in scope? | `{{yes / no — and if no, state which class is excluded and why}}` | A build-time-only CVE is real but not the same risk as a runtime one; say which you mean |
| How often beyond the diff? | `{{on every PR + weekly schedule}}` | **A dependency can be flagged after it was accepted** — a PR-only gate misses that entirely |

The weekly re-scan is not optional. The most common way a project ships a
known-vulnerable dependency is not a bad merge; it is an advisory published
three weeks later.

## Remediation

Detection without this section produces a finding nobody acts on
(`postmortems.md` Case 3). **This is the part that changes behaviour.**

1. **Identify.** Read the finding as *package@version, advisory ID, fixed
   version*. A finding without those three is not actionable.
2. **Determine the fixed version**, and whether it is within the current
   range. `{{npm outdated <pkg>}}`, `{{mvn dependency:tree}}`.
3. **Assess the blast radius** — this is the step everyone skips:

   | Fix kind | What it means | How it lands |
   |---|---|---|
   | **Patch / minor** | No API change | In the current change, with the tests re-run |
   | **Major** | API or behaviour change | **Its own PR**, with its own review. Never bundled into a feature |
   | **Transitive only** | The direct dependency's range blocks the fix | Ask the upstream to widen; do **not** add an override to force it, unless the override is itself reviewed and recorded |

4. **Apply, then re-run the full gate** — not just the scanner. A version bump
   is a change to code the team did not write and has not read.
   `{{quality-gates.md}}` §The Gate Table, all seven.
5. **Re-scan and prove it.** The finding must be **gone from the output**, not
   merely downgraded. A finding that moved from `high` to `moderate` is still
   a finding.
6. **Record it** if the fix was non-trivial: what the advisory actually was,
   and what this project now does differently. If it was a project-specific
   behaviour, it belongs in `external-system-contracts.md`.

**`npm audit fix --force` and the equivalents are not remediation.** They
upgrade across majors with no review, and the "fix" is usually a broken
build discovered three days later, after the change was merged.

## When a Fix Is Not Available

Zero vulnerabilities is the target. It is **not always reachable today**, and a
rule with no answer for "what if zero is impossible" produces a gate that gets
disabled in the first week.

So there is a fourth disposition, and it is not "ignore it":

| Disposition | Meaning | Required |
|---|---|---|
| **Fixed** | Upgraded and re-scanned clean | The command output showing the finding gone |
| **Not reachable** | The vulnerable code path is not called | **A sentence naming the path and why it is unreachable.** Not "seems unused" |
| **Accepted, with expiry** | No fix exists yet | Owner + date + a linked advisory. Reviewed at the weekly scan, not left |
| **Blocked upstream** | The fix exists, a transitive blocks it | The upstream issue link, and a re-check date |

**Anything not fixed is recorded in `docs/quality-baseline.md` with its
disposition.** An unrecorded finding is indistinguishable from one that was
forgotten — and a gate that cannot represent "we know" cannot be honest.

## Lockfile Discipline

The lockfile is **the** input to every scanner above. A committed lockfile that
does not match the installed tree produces a report about software that is not
running.

- **Commit the lockfile.** An uncommitted lockfile makes the vulnerability
  scan describe a tree nobody has.
- **Never regenerate the lockfile to clear a finding.** Re-resolving silently
  moves every transitive dependency — a fix disguised as a repair.
- **CI installs with `{{npm ci}}` / `{{mvn dependency:go-offline}}`, never
  `{{npm install}}`.** `install` re-resolves and can produce a different tree
  than the one that was scanned.
- **A major-version bump that is not the subject of the change** is a signal
  that something re-resolved. Check `git diff` on the lockfile before merging.

## Updating Dependencies

Updating is not auditing, and it has its own failure mode: a change that
"just bumps everything" is a change nobody reviewed and that breaks something
three weeks later.

- **Group by risk**: patch bumps together, minors together, majors one per PR.
- **One ecosystem per PR.** A PR that bumps npm *and* Maven is unreviewable.
- **Automated update PRs are welcome; auto-merge is not**, unless the project's
  CI already runs the full gate set. `{{dependabot}}` / `{{renovate}}` open
  the PR; the gate decides.
- **A scheduled bump PR is a maintenance task, not an emergency.** It follows
  the same review rules, with the difference that the reviewer's baseline is
  "does this bump anything behaviourally relevant", not "is this correct".

## When Blocked

- A fix requires an architecture change: **stop and ask**. A vulnerability that
  requires restructuring is a the decisions log entry, not a clever workaround.
- A scan is red and the finding is unreachable: **prove it**, in a sentence
  naming the path. Then use the disposition table above — do not pass the gate
  by asserting it.
- A scanner and the package manager disagree about the tree: **believe the
  lockfile**, and investigate why the scan saw a different tree before drawing
  a conclusion about the finding.
- **A dependency was flagged with no advisory for its reachability**: that is
  a **Required** review item, not a dismissed one. The scanner cannot know
  whether your code calls it.
- Never: `--force` an audit fix · add a dependency override to silence a
  finding without recording why · drop a dev dependency from the scan to
  reduce its output · mark a finding resolved without re-scanning.