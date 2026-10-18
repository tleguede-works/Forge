# Template · Code Review

<!--
GENERATOR NOTES — delete this block in the emitted file.

Le fichier qui manquait le plus, et le plus confusionné avec un autre.

**Ce n'est pas le pre-commit review.** Celui-là vit dans `workflow.md` et
porte sur **le diff de l'agent qui le produit**, exécuté par cet agent, avant
son propre commit. Celui-ci porte sur **le travail de quelqu'un d'autre**, par
quelqu'un d'autre, avant intégration. Confondre les deux produit deux défauts
opposés : soit une équipe sans aucun artefact de revue, soit un agent qui se
revue lui-même en appelant ça une revue.

**La frontière centrale de ce fichier est mécanique / jugement.** C'est la
demande explicite, et c'est ce qui distingue une revue d'une liste de
commandes. Une revue qui ne se réduit pas à un script n'est pas « la revue
plus un peu d'humain » — c'est un **deuxième jeu de portes** dont la moitié
ne peut pas être automatisée, et dont la partie automatisée doit donc être
exécutée en premier, pour que l'attention humaine arrive sur ce qu'aucun
script ne peut voir.

Ne met PAS ici : les portes elles-mêmes (`quality-gates.md`), le format des
commits (`git-workflow.md`), les règles par domaine.
-->

# Code Review

## What Is Reviewed

A review covers **one change on one branch against one intent** — the unit
that is independently revertible (`git-workflow.md` §Commits). Two unrelated
changes in one diff is not two reviews, it is one unusable one: the reviewer
either checks both shallowly or stops.

- A reviewer **must not approve their own change.** This is the single rule
  that makes the rest of this file meaningful, and it has no exception for
  "it was small".
- A review that finds nothing states **what was checked**, not "LGTM".
  "LGTM" is indistinguishable from "not looked".

## Stage 1 — Mechanical, before reading a single line

**These run first, and their output is the review's first paragraph.** A human
who opens a diff whose gates are already green is reviewing judgement, not
re-running linters — which is the only thing a human is better at.

| # | Check | Command | Fails when |
|---|---|---|---|
| 1 | Gates | `{{npm run gate}}` | any `quality-gates.md` gate is red |
| 2 | Secrets | `{{gitleaks detect --staged}}` | a credential is in the diff, **including in a comment, a fixture or a snapshot** |
| 3 | Scope | `{{git diff --stat origin/main...HEAD}}` | the change touches more than its stated intent |
| 4 | Generated code | — | a generated file was hand-edited instead of regenerated |
| 5 | Dependency changes | `{{npm audit}}` | a version moved without a reason in the body |
| 6 | Migrations | `{{migrate status}}` | a schema change has no rollback path |

Stage 1 is not "the review". It is the part a script can settle, and running
it first is what buys the reviewer attention for Stage 2.

## Stage 2 — Judgement, and the order it happens in

**Read the diff three times, in this order.** Each pass answers one question,
and a pass that tries to answer all three produces a review that is three
shallow ones.

### Pass 1 — Is it correct?

Read for what the code **does**, not for what it was asked to do.

- Does it do what the ticket says, **and only that**? Extra correct work is
  still extra, and it is extra that nobody reviewed.
- Trace the **primary happy path** end to end. Then, for each branch: what
  happens on the empty case, the boundary, the concurrent case?
- **What is the failure path?** Find the error branch and ask whether it is
  reachable, and what the user sees when it is.
- What happens on **retry**? Is an operation safe to run twice? A
  double-submit bug and a double-charge bug are the same defect.
- What happens when the **external dependency is slow, down, or returns
  something undeclared**? `domain/external-system-contracts.md` §What Belongs
  Here records what is known; anything beyond it is an assumption.
- **Is the behaviour that was asked for actually the behaviour that was
  wanted?** These differ more often than teams expect, and the diff is where
  it shows.

### Pass 2 — Does it belong to this project?

- Does it follow the **architecture** — the layer rules, the dependency
  direction (`architecture.md` §Dependency Direction)? A change that is
  locally clean and architecturally wrong is the most expensive kind.
- Does it introduce a **second pattern** for something that already has one?
  (`architecture.md` §Centralized Concerns.) The second copy is always the
  one nobody maintains.
- Is a **magic value** a named constant (`coding-standards.md` §Magic Values)?
- Is a **new abstraction** earning itself? An abstraction used once is not
  reuse, it is indirection with a name.
- Is this file now doing **two jobs** (`architecture.md` §File Size)?

### Pass 3 — Can someone else maintain it?

- Would a reader understand **why**, from the code, or only from the author's
  head? A comment that states the what is noise; a missing "why" is a cost
  paid by everyone else.
- Is the **naming** carrying its meaning, or is it a restatement of the type?
- Is there a **comment explaining a non-obvious constraint**? If a rule had
  to be discovered the hard way, it is now written on someone else's code, and
  the next person will rediscover it.
- Is the **error handling** at the right altitude — handled where it can be
  handled, propagated where it cannot?

## Severity, and what each level obliges

Without a vocabulary, "this looks wrong" and "this is wrong" arrive in the
same tone, and the second is dismissed with the first.

| Severity | Meaning | What the reviewer does |
|---|---|---|
| **Blocking** | Wrong behaviour, a broken gate, a security hole, a rule contradiction | Not merged. Stated as **what** breaks, **why**, and a failing case |
| **Required** | Not wrong today, but the thing that makes it wrong tomorrow — a missing test, an unexplained choice | Not merged until addressed or explicitly deferred |
| **Suggestion** | A preference the author can decline | Non-blocking, clearly marked as optional |
| **Question** | The reviewer does not understand something | **A question, not a comment.** The author answers; if the answer is "I don't know either", that is itself a **Required** |

A **Blocking** comment without a **failing scenario** is a guess wearing a
verdict's clothes. "This breaks on empty input" is reviewable; "this feels
fragile" is a veto the author cannot act on.

## Tests: reviewed as code

**A test is reviewed as production code** — it is read by the next person, it
fails in the worst moment, and it is often the least reviewed file in a diff.

- Does a test **fail against the broken behaviour**? A test that cannot fail
  is not a test; confirm it by breaking the code and watching it go red.
- Does it assert on the **contract** (`domain/external-system-contracts.md`),
  or on an incidental string?
- Does the test **survive a refactor**, or does it reach into internals and
  break on every change?
- Is a **skip** present? A skip needs a tracked reason and an owner. "Flaky on
  CI" is not a reason; a race that needs fixing is.
- Is the coverage of the **new** path real, or is the number met by tests
  that execute a line without asserting anything about it?

## Definition of Review Complete

A review is done when **ALL** of:

1. Stage 1 ran and its output is in the review.
2. The three passes were made, in order.
3. Every comment carries a severity from the table above.
4. Every **Blocking** comment has a failing scenario.
5. The author answered every **Question**, or the question became **Required**.
6. **Coverage, duplication and vulnerability gates are green** — a review that
   approves a red gate has approved a defect, whatever it said about the code.

**And one more, which is the one people skip:** the reviewer says what they
did **not** check. An unreviewed surface that nobody named is a surface that
nobody owns.

## When Blocked

- A **Blocking** finding is ignored without discussion: escalate
  (`AGENTS.md` §Escalation Rules). Do not merge and mention it later.
- A change is too large to review: **say so and ask for a split.** A review
  of 1 200 lines that finds three things is a review that found the three
  easiest things.
- A gate is red and the author says it is unrelated: **verify that claim
  against the command's own output**, not against the author's summary. The
  author is describing, you are measuring.
- The author is unavailable and the change is urgent: say what you did not
  verify, in the review, in writing.
- Never: approve a change you wrote · approve to unblock someone's deadline ·
  leave a **Blocking** comment as a **Suggestion** to be agreeable · mark
  "LGTM" without stating what was checked.