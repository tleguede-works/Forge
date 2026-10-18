# Template · Git & Delivery Workflow

<!--
GENERATOR NOTES — delete this block in the emitted file.

Le propriétaire unique de la discipline git : commits, branches, intégration,
hooks. Le fichier d'entrée n'en garde qu'un pointeur.

**Pourquoi il était dans `entry-file.md`, et pourquoi ce n'est plus le cas.**
Le fichier d'entrée est chargé **en entier, à chaque session**, sans condition.
La discipline git est détaillée, rarely-needed au sens de Cursor, et partage une
grande partie de son contenu avec les portes. La laisser dans l'entrée meant
payer 60 lignes à chaque session pour un contenu qui n'est consulté qu'au
moment de commiter. C'est exactement l'inversion du principe 6 : du plancher
(prose détaillée, jamais chargée conditionnellement) dans le tier budgété.

Ce qui reste dans l'entrée : **le nom de la stratégie choisie** et le format de
message en une ligne. Pas le détail — le détail est ici, référencé.

Ne met PAS ici : les portes elles-mêmes (`quality-gates.md`), les hooks comme
outil de validation (`quality-gates.md` en est le propriétaire ; ici on décrit
ce qui est **enfilé quand**), le format des commits comme texte de PR.
-->

# Git & Delivery Workflow

## Strategy

**This project uses: `{{trunk-based | git-flow | release-train | project-specific}}`.**

<!--
DÉCIDE, ne devine pas. C'est une question d'interview de l'Étape 1, parce que
c'est la seule décision git qui ne se déduit pas du dépôt — et parce que les
deux branches de la décision ont des coûts opposés :

  - **trunk-based** : `main` toujours vert, branches courtes, intégration
    fréquente. Moins de conflits, historique lisible, mais exige que la suite
    soit rapide et que le.feature-flagging soit maîtrisé.
  - **git-flow** : `develop`, branches `feature/*`, `release/*`, `hotfix/*`,
    tags. Convient à une version livrée avec support, au prix d'un historique
    plus lourd et de merges de release pénibles.
  - **release-train** : tout le monde embarque sur le même train. Pour une
    équipe qui ne peut pas livrer en continu.

Si la réponse est « je ne sais pas » ou « aucune préférence », **choisis
trunk-based** et écris pourquoi dans the decisions log. C'est le choix réversible,
et le statut par défaut « aucune stratégie » est la seule option qui n'est
réversible par personne.
-->

{{#if trunk-based}}
- `{{main}}` is always releasable. A red `main` is an incident.
- A branch lives **hours, not weeks**. If it is still open after a day, the
  change is too big or the branch is doing two things.
- Feature flags, not long-lived branches, carry unfinished work.
{{/if}}

{{#if git-flow}}
- Long-lived `{{develop}}`; short `{{feature/*}}` branches merge into it.
- `{{release/*}}` branches off `develop` and produce a tag; only
  release-branch fixes are allowed on them.
- `{{hotfix/*}}` branches from `main`, merge to `main` **and** `develop`.
- A branch merged into `develop` is never reworked: a mistake goes forward
  as a new commit, never as a rewrite of shared history.
{{/if}}

## Commits

### The unit

**One commit = one intent, independently revertible.** That is the property,
and it is the test — not the line count.

> **The test:** if reverting this commit alone would break the commits after
> it, the split is wrong.

- A large change that does one thing is correct. Twelve small commits that each
  half-finish one thing are a mess, because nothing in the history can be
  undone on its own.
- **Never mix a refactor with a behaviour change.** They revert differently,
  and reviewing them together means reviewing both at once.
- **Never bundle drive-by changes.** A typo fixed in this file, a reformatted
  block "while I was there" — these belong to their own commit, or they are
  invisible in a review of the real change.
- **Commit at the last point where the tree is coherent and verified** — not
  before, not much after. A commit that leaves the tree broken is not a safety
  net; three days of accumulated work is not a history.

### Message

```
<type>(<scope>): <description>

<optional body — why, not what>

<optional footer — refs, breaking changes>
```

| Part | Rule |
|---|---|
| `type` | `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `style`, `perf`, `build`, `ci` |
| `scope` | Lowercase, the feature or package — `{{feat(checkout): add cart screen}}` |
| `description` | Imperative mood, lowercase, **no trailing period**, under 72 chars |
| `body` | **Why**, not what. The diff already says what. If the body restates the diff, delete it |
| `footer` | Issue refs, `BREAKING CHANGE:` |

- **`fix` names the bug, not the symptom**: "fix cart total ignoring promo
  code", not "fix cart".
- **A revert gets its own commit** with `revert:` in the message, naming the
  commit reverted. Silently rewriting shared history is forbidden
  (`When Blocked`).

**This format is enforced, not requested.** {{`commitlint` on a `commit-msg`
hook — see §Hooks}}, so an agent cannot ship "fix stuff" and neither can a
tired human at 18h.

## Branches

- Naming: `{{feature/<name> | fix/<name> | chore/<name>}}`, branched from
  `{{main}}`.
- **A branch isolates a change that would not be clean on the default branch**
  — a feature, a fix, a refactor, an experiment. A typo fix does not need one.
- **One branch, one intent.** Three unrelated changes on one branch merge badly
  and review badly.
- Bring the branch up to date with the default branch **before** starting work
  that touches shared ground, not after.
- **Delete the branch after merge.** A branch that survives its merge is a
  branch someone will start new work on.

## Integration

**Before opening a pull request:**

- The worktree is green — every `quality-gates.md` gate exits 0.
- The Definition of Done is satisfied, **including the process items**, which
  `git status` cannot detect.
- The branch has no unrelated commits. If it does, rebase or split — a review
  of mixed work is a review nobody does well.
- The PR description states **what** changed, **why**, and **how it was
  verified** — with the command output, not the summary of it.

**The review itself**: `code-review.md`. Two rules that belong here because
they are about the merge, not the code:

- **A conflict resolved by reading both sides, or not resolved.** Taking the
  nearest version, or deleting one side, defers the decision to runtime, where
  it fails without anyone knowing which change caused it.
- **Re-verified after conflicts are resolved**, not before.

## Hooks

<!--
Ce qu'est un hook, et pourquoi il existe : c'est la seule chose qui rend une
porte non contournable **en local**. Un agent peut décider qu'une porte « a
l'air verte » ; il ne peut pas contourner un `pre-commit` qui sort non-zéro
sans `--no-verify` — et un `--no-verify` est **visible dans l'historique**,
donc il a un coût social.

La règle qui décide si un hook survit : **il doit être rapide**. Un pre-commit
qui dépasse ~10 s est contourné en une semaine, et un hook contourné est pire
qu'un hook absent — il donne l'illusion d'une garantie.
-->

**This project uses `{{lefthook | husky + lint-staged | none}}`**, configured in
`{{lefthook.yml | .husky/}}`.

| Hook | Runs | Budget |
|---|---|---|
| `pre-commit` | Lint + format on **staged files only**, secrets | < 10 s |
| `commit-msg` | Commit message format | < 1 s |
| `pre-push` | Typecheck, fast unit tests, duplication | < 60 s |

**What is deliberately not in `pre-commit`:** the full test suite, the
vulnerability scan, the build. Not because they do not matter — because they
are slow, and a hook that is slow gets bypassed, and a bypassed hook is a lie.
Those run in `pre-push` and in CI.

{{#if lefthook}}
```yaml
# lefthook.yml — {{delete if this project does not use lefthook}}
pre-commit:
  parallel: true
  commands:
    lint-staged:
      glob: "*.{ts,tsx,js,jsx}"
      run: npx eslint --fix --max-warnings=0 {staged_files}
    format-staged:
      glob: "*.{json,md,yaml,yml}"
      run: npx prettier --write {staged_files}
    secrets:
      run: gitleaks detect --staged --no-banner

commit-msg:
  commands:
    commitlint:
      run: npx commitlint --edit {1}

pre-push:
  commands:
    typecheck:
      run: npx tsc --noEmit
    duplication:
      run: npx jscpd --threshold {{THRESHOLD}} src
```
{{/if}}

- **Lefthook over husky** for a polyglot repository: one binary, parallel by
  default, no Node runtime for the hook runner itself. Husky is the better
  choice for a pure-Node repository, where `npm install` already provides the
  runtime.
- **`lint-staged` is not optional** for the JS/TS path. `eslint .` on a large
  repo takes 15–30 s and gets bypassed; `eslint <staged files>` takes ~1 s
  and does not.
- **`core.hooksPath`** must point at the committed directory. `.git/hooks` is
  not versioned, so hooks written there are hooks only one developer has.

## When Blocked

- A conflict cannot be resolved with both sides understood: **stop and ask.**
  Do not take the nearest version.
- A hook blocks a change you believe is correct: **do not `--no-verify` to find
  out.** Fix it, or state in the PR that the hook was bypassed and why.
- A revert is needed on shared history: **revert forward** with a `revert:`
  commit. Rewriting shared history is forbidden.
- The branch is behind and the merge looks scary: **merge the default branch
  in early and often.** A 200-line conflict is the consequence of a 3-week-old
  branch, not of the merge tool.
- Never: force-push a shared branch · amend or rebase a commit already pushed
  to one · `reset --hard`, `checkout .`, `restore .` to "get back to clean" ·
  merge with a red tree · resolve a conflict without reading both sides ·
  commit a credential, on the assumption it can be revoked afterwards ·
  disable a hook to get work moving.