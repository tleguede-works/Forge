# Loops: causes found and the guard against them

Reported symptom: a client project resumed from an older Forge `.forge` folder; Bootstrap produced the Brief and the Contract, then the QA and Red Team subagents ran again and again (more than ten times) without progress, while the agent seemed to want to ask a question but did not, because it believed the answers were already in the files. The project folder was not available for this analysis, so the causes below come from the instructions of the old Forge and of Forge v3, not from the session log.

## Causes found

| # | Cause | Where | Why it loops |
|---|---|---|---|
| 1 | A gate needs a human act that nothing tells the agent to request | Old Forge: the guard refuses every phase after Bootstrap until the contract has been approved by the client, and only the client can sign | A resumed project already holds the answers, so the agent produces the documents and waits on a gate it cannot pass. It re-runs the validators hoping the refusal clears |
| 2 | A rule that discourages asking | Old Forge and the rules library: do not ask what the repository already says | The agent treats a missing human act as a missing file to search for |
| 3 | The validators have no exit criterion | QA reports what is missing, Red Team what is wrong; neither is told that an empty report is valid | The two always find something, so "fix and re-review" never ends |
| 4 | The fix then re-review cycle has no bound | Old Forge bounded only Fast Track (a third attempt stops it); Forge v3 repeated the same gap in its own step 5 ("re-run both reviews") | Nothing counts repetitions |
| 5 | A finding that only the user can settle is treated like a defect to fix | Reports had no way to say so | The author edits the document, the reviewer finds the same gap, and so on |
| 6 | A reviewer can be launched again on a file that did not change | Nothing recorded what was already reviewed | A second review of identical text cannot produce new information |

## Mechanisms now in place

| Mechanism | Closes | Where | Test |
|---|---|---|---|
| `forge review begin` / `record`: a reviewer cannot be recorded without a launch, cannot be launched again on a version it already reviewed, and gets at most two launches per version without a usable report | 6, 3 | CLI | loops |
| Three review rounds that end with blocking findings escalate: no fourth round until the user has answered and the analysis is recorded | 4, 3 | CLI | loops |
| `needs: user` on a finding, printed as `NEEDS-USER` with the question | 5 | CLI, reviewer agents | loops |
| Refusals that need a human start with `NEEDS-USER` and say to ask now | 1, 2 | CLI | loops, adversarial |
| Attempt ledger: five identical failures of one operation stop it (`STUCK`, exit code 3); a success or a different failure resets the count | 4 | CLI | loops |
| `forge attempts` and `forge unstick`: the agent must write the likely cause (120 characters or more) and a new approach, or the user's answer; a second stop on the same operation needs the user's words; the analysis is saved as a lesson | all | CLI, memory | loops |
| Same subagent launched three times with the same request while the Forge state is unchanged: blocked | 6 | Claude Code hook (`PreToolUse` on `Task`), OpenCode plugin | hooks, opencode_plugin |
| Same file edited six times since the last checkpoint: a message tells the agent to stop and analyze | 4 | Claude Code hook | hooks |
| Rule R11 and the Loop guard sections of the orchestrator and of every agent; the reviewer rules (an empty report is valid, never reopen a resolved finding, read the previous report, ask when input is missing) | 2, 3, 5 | skills and agents | lint, templates |
| Bootstrap rule BS5: when resuming, read `.forge/` once, record its answers, ask only the gaps, never wait silently on an approval | 1, 2 | forge-bootstrap | none (judgement) |

## Limits

- Judgement: an agent can ignore R11, write a thin analysis that passes the length check, or vary its request text so a launch is not seen as identical. The second stop on one operation needs the user's words, which bounds the damage.
- The launch guard compares the first 600 characters of the request. A timestamp placed at the top of every request would defeat it.
- `PreToolUse` with the matcher `Task` in Claude Code, and the `task` tool arguments in OpenCode, are assumed from documentation and untested on a live install.
- The CLI cannot see an agent that loops without calling it; the hooks cover launches and edits, not every possible repetition.

## Resuming an old project

See item I-007 in `docs/IMPROVEMENTS.md`.
