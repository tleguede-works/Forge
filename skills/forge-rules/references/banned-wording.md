<!-- lint:ignore-file -->
# Banned wording in rule files

This file names the words that `forge rules audit` rejects, so that no other file has to quote them. It is excluded from the wording lint because its purpose is to list them.

| Class | Words and phrases | Why an agent cannot follow it |
|---|---|---|
| Vague adverbs | carefully, properly, gracefully, robustly, cleanly, best practices, make sure to | No command or trigger tells the agent when the rule is met |
| Deferral | as needed, where appropriate, as appropriate, when appropriate, if possible, where possible, wherever possible, whenever possible, depending on the case | The agent decides alone whether the rule applies |
| Modal softeners | should, might, may (as a statement of permission), try to, consider, ideally, preferably, generally, normally, usually, feel free | The rule reads as advice, and advice is skipped under pressure |
| Floors that hide a number | at least, at a minimum | Replace with the number or with "one or more" |
| Hedges | a guess followed by a request to verify | The rule states nothing the agent can check |

Replace each with one of: a command and its pass condition, a measurable threshold, a trigger ("when X, do Y"), or a deletion.
