# Template · Quality Gates

<!--
GENERATOR NOTES — delete this block in the emitted file.

Le propriétaire unique de tout ce qui **se mesure**. Avant ce fichier, la
question « à quoi correspond un seuil dans ce projet » avait autant de réponses
que de fichiers, et la réponse par défaut était « l'agent juge ». C'est la
raison pour laquelle un projet peut afficher un Definition of Done parfait et
une duplication à 31 %.

Trois règles qui gouvernent ce gabarit, et qui expliquent sa forme :

  1. **Chaque porte est une commande qui sort non-zéro.** Pas une intention,
     pas une phrase, pas « vérifie que ». Une porte dont on ne peut pas citer
     l'invocation n'est pas une porte, et l'audit le refuse.
  2. **La baseline précède les seuils.** On ne peut pas dire « ≤ 3 % » à un
     projet à 22 % sans avoir décidé ce que ça veut dire. D'où les deux modes
     (`greenfield` / `ratchet`) : ce ne sont pas deux generations de règles,
     c'est deux réponses au même seuil appliquées à des Measurements
     différents.
  3. **Les seuils sont posés, pas négociés par fichier.** Les valeurs sont
     decidées une fois ici ; aucun autre fichier ne les réénonce, il les
     référence. C'est ce qui rend `forge rules audit`
     §no_contradictory_thresholds capable de dire quelque chose.

Ne met PAS ici : le format des commits (`git-workflow.md`), le contenu des
revues (`code-review.md`), la remédiation des vulnérabilités en détail
(`dependency-security.md` §Remédiation — ici on ne fait que la *gate*).

Le §Baseline est à remplir **avant** le reste du fichier. Un jeu de règles
qui déclare ses seuils sans avoir mesuré le projet est un jeu de règles qui
invente un point de départ.
-->

# Quality Gates

## Status

<!--
Choisi AUTOMATIQUIQUEMENT au scan initial — ce n'est pas une question
d'interview. Voir `baseline-scan.md` §Choix du mode.

  - `greenfield`        aucun fichier source, ou tous les seuils respectés
  - `ratchet`           sources présentes, au moins un seuil violé
  - `greenfield-dette`  aucun source ET un outil de gate manquant

Emit ONE of the three blocks. Jamais les deux. Jamais aucun.

{{#if greenfield}}
> **Projet neuf — seuils stricts.** Aucun code existant n'est exempté. Les
> sept portes s'appliquent dès la première ligne écrite.
{{/if}}

{{#if ratchet}}
> **Projet existant — mode ratchet.** La baseline du {{SCAN_DATE}} est le
> point de départ, pas zéro. La dette existante est **enregistrée, pas
> tolérée** : elle est nommée dans `docs/quality-baseline.md` et un
> emplacement lui est réservé dans le backlog.
>
> Ce qui est interdit, c'est **la régression** : une porte échoue si la
> mesure se dégrade, même si la mesure reste « mauvaise ». C'est
> mesurable sans être atteignable immédiatement — et c'est la seule exigence
> qui tient dans un projet qui a 22 % de duplication.
>
> {{#each debt}}
> - {{METRIC}} : {{CURRENT_VALUE}} au {{SCAN_DATE}} → cible {{TARGET}}, échéance {{DATE}}, porteur {{OWNER}}
> {{/each}}
{{/if}}

{{#if greenfield-dette}}
> **Outil de porte manquant.** La porte « {{GATE}} » est émise mais **n'est
> pas satisfaite** : `{{COMMAND}}` n'est pas installé. Le statut est
> `absent`, pas `passé`.
>
> Installez-le : `{{INSTALL_COMMAND}}`. Tant qu'il est absent, cette porte
> **ne se coche pas** et ne doit pas être déclarée satisfaite dans une
> Definition of Done.
{{/if}}

## The Gate Table

<!--
Le cœur du fichier. Une ligne = une porte. Chaque ligne DOIT avoir une
commande avec un code de sortie — sinon `forge rules audit` la refuse.

Ne coupez pas une ligne de ce tableau pour gagner de la place. Une porte
retirée est une vérification qui ne se fait plus, et elle ne se fait plus
sans signal : le rapport reste vert parce que personne ne regarde.

{{#each gate}}
| {{NAME}} | `{{COMMAND}}` | {{THRESHOLD}} | {{IF_MATCHES_THIS_WHAT}} |
{{/each}}
-->

| Gate | Command | Threshold | What a failure means |
|---|---|---|---|
| Lint | `{{npm run lint}}` | 0 errors | A rule in this set is broken in code |
| Typecheck | `{{npm run typecheck}}` | 0 errors | A type was widened or suppressed to make an error go away |
| Tests | `{{npm test}}` | 0 failures, 0 skipped | A regression, or a test deleted to hide one |
| Coverage | `{{npm run test:coverage}}` | ≥ **80 %** | New code arrived untested |
| Duplication | `{{npx jscpd --threshold 3 src}}` | ≤ **3 %** | A second copy exists where a shared module is needed |
| Vulnerabilities | `{{npm audit --audit-level=high}}` | **0** | A known CVE is reachable in the dependency tree |
| Doctor | `{{npx depcheck}}` or `{{mvn dependency:analyze}}` | 0 unused, 0 missing | A dependency was added for comfort, or removed and still imported |

**Why these seven, in this order.** Order is by cost of skipping, not by
importance — a cheap check that fails often goes first, because it costs
nothing and catches the most. The doctor goes last because it is the only
one that sometimes does not apply, and a check that only sometimes applies is
**conditional, not sequential**: run on every diff it becomes noise on the
diffs it does not apply to.

**An unfalsifiable item placed early is the worst combination**: high
attention, low yield. If you cannot describe the failure state, the gate is
not a gate.

## What "Coverage ≥ 80 %" means here, exactly

The threshold is meaningless without a statement of **how it is measured**,
because four different numbers all answer "what is your coverage".

| Question | Answer for this project | Why it matters |
|---|---|---|
| Which layers are counted? | {{e.g. domain + orchestration only; view code excluded}} | 80 % on 40 000 lines of view code is not the same gate as 80 % on 3 000 lines of logic |
| Which metric? | `{{statements / branches / lines / functions}}` | Branch coverage is the strictest; lines is the loosest |
| How are multiple reports aggregated? | `{{one merged report, not a per-package average}}` | An average of averages hides the package that is at 0 % |
| What is excluded? | `{{generated code, migrations, type-only files}}` | Exclusions must be named, or they silently grow |

**Averaging per-package coverage is a defect, not a measurement.** A project
at 95 % in ten packages and 0 % in one averages to 86 %, and the package at
0 % is the one that broke. Aggregate over the merged report, or take the
**minimum per package**, never the mean of means.

- **Coverage measures what executed, not what was verified.** A high number
  with assertions-free tests is worse than a lower number with real ones. Do
  not raise the number by writing tests that assert nothing.
- **Coverage is a floor for the layers where a regression is expensive**, not
  a target for the whole codebase. If this project has no opinion on view
  code, say so explicitly rather than letting the number drift.

## What "Duplication ≤ 3 %" means here, exactly

Same discipline. The percentage is only comparable if the detector and its
settings are stated, because a different minimum token count produces a
different number on identical code.

| Question | Answer for this project |
|---|---|
| Which detector? | `{{jscpd 5.x}}` — one binary, 220+ languages, no SonarQube needed |
| Minimum token count / line count? | `{{min-tokens 50, min-lines 5}}` — the defaults; state any change |
| What is excluded from the measurement? | `{{tests, snapshots, generated code}}` — duplication in a test that mirrors a DTO is intentional |
| How is the ratio computed? | `{{duplicated lines / total scanned lines}}` |

**Do not mix detectors between runs.** A number produced by `jscpd` and one
produced by PMD CPD are not comparable, and the threshold applies to the one
this project uses. If the project has a mix of JVM and JS, run each tool in
its own scope and give each its own gate row.

{{#if ratchet}}
**In ratchet mode, the gate is on new duplication, not on the total.** The
total cannot be brought under 3 % without a refactoring project, so gating on
it means the gate is always red and therefore always ignored:

```bash
npx jscpd --baseline-from-ref origin/main --fail-on-new-clones 0 src
```

This scans the base ref's tree with the same settings and fails only for
clones absent from it. **A gate that is always red is not a gate**: it trains
the agent to pass with `--no-verify`, which is worse than no gate at all.
{{/if}}

## What "0 vulnerabilities" means here

Zero is the target, and it is reachable in a way "no new vulnerabilities" is
not — but only if the remediation path is written down. Detection without a
remediation procedure produces a finding nobody acts on
(`dependency-security.md` owns that procedure).

| Question | Answer for this project |
|---|---|
| Which scanner, and on what artifact? | `{{npm audit}}` on the lockfile, `{{osv-scanner scan source -r .}}` for the broader OSV set |
| Is `--omit=dev` used? | {{yes / no — and if no, state why dev dependencies are in scope}} |
| What happens on a major-version fix? | A dedicated PR, never bundled into a feature commit |
| What if a fix is impossible right now? | Recorded with an owner and an expiry — **never silently tolerated** |

The last row is the one that matters. A rule that says "zero vulnerabilities"
and has no answer for "what if zero is unreachable" produces a gate that gets
disabled the first week.

## Baseline

The measurement this file was built against. **Filled in from the scan, never
from an estimate** — a baseline written by hand is a guess wearing a
measurement's authority.

| Gate | {{SCAN_DATE}} | Target | How the gap is closed |
|---|---|---|---|
| {{GATE}} | {{VALUE}} | {{THRESHOLD}} | {{route}} |

Full scan output: `docs/quality-baseline.md`. **Re-run the scan when a tool,
a threshold or a major dependency changes** — a baseline that is older than
the tool it was measured with describes a configuration that no longer exists.

## When a Gate Fails

The failure path is where a gate is really defined. A table of commands with
no stated response degrades into either paralysis or quiet skipping.

- **Fixable inside this change** → fix it. Do not commit past it.
- **Needs a refactor that is out of scope** → **split the change**, or land
  the refactor first. Do not mix them.
- **Cannot be resolved without a decision** → **stop and ask.** Do not
  invent a threshold, and do not weaken the gate to make it pass.
- **The tool is missing or the project is not configured for it** → record it
  as `absent` in `docs/quality-baseline.md`, and do not tick the gate.
- **Genuinely not applicable** → say so explicitly in the commit message,
  with the reason. A justified skip is fine. A silent one is the thing that
  costs the next person trust in the entire rule set.

Never: raise a threshold to make a gate pass · add `--no-verify` · delete a
failing test · exclude a file from the scanner to clear its finding ·
regenerate a baseline to make a red gate green.

**A threshold that has been raised is a decision, not a correction.** Record
it in the decisions log with the reason and the date. A threshold edited twice in
a quarter without a decision behind it is not a quality gate any more.

## When Blocked

- A gate cannot run because its tool is missing: **report it as `absent`**.
  Never as `passé`.
- A gate cannot run because the project has no code yet: the gate is emitted
  with its status, and the Definition of Done says so in the same breath.
- A gate fails for a reason that looks environmental (config resolution,
  missing global, version mismatch): **check the tool's documentation for this
  exact combination before changing anything**. Rewriting a correct gate to
  work around a configuration problem destroys the gate and hides the problem.
- Never: declare a gate satisfied without running its command · pass a gate by
  weakening the rule it enforces · regenerate a baseline without saying so.