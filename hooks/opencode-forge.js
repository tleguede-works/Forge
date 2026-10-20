// Forge plugin for OpenCode. Installed as plugins/forge.js (project: .opencode/plugins, global: ~/.config/opencode/plugins).
// Design rules, from the OpenCode plugin docs and the Bun shell docs:
//  - a hook that throws aborts the operation it wraps, so every hook here catches its own errors;
//    the single deliberate throw is the loop guard, which blocks a repeated subagent launch on purpose;
//  - Bun's `$` throws on a non-zero exit code, so commands run through node:child_process with a timeout instead;
//  - the plugin acts only in a Forge project (a `.forge/state.json` exists) and is silent everywhere else.
import { existsSync, readFileSync, writeFileSync } from "node:fs"
import { execFileSync } from "node:child_process"
import { createHash } from "node:crypto"
import { join, isAbsolute } from "node:path"

const PYTHON = "python3" // replaced by the installer
const CLI = ".forge/kit/cli/forge.py" // replaced by the installer
const TIMEOUT_MS = 10000
const MAX_SAME_LAUNCHES = 3

const isForgeProject = (dir) => existsSync(join(dir, ".forge", "state.json"))

function runCli(dir, args) {
  try {
    const cli = isAbsolute(CLI) ? CLI : join(dir, CLI)
    return execFileSync(PYTHON, [cli, ...args], {
      cwd: dir, encoding: "utf8", timeout: TIMEOUT_MS, stdio: ["ignore", "pipe", "ignore"],
    })
  } catch {
    return ""
  }
}

const stateSeal = (dir) => {
  try { return JSON.parse(readFileSync(join(dir, ".forge", "state.json"), "utf8")).seal || "" } catch { return "" }
}

const launchKey = (args) => {
  const agent = String((args && args.subagent_type) || "")
  const prompt = String((args && args.prompt) || "").replace(/\s+/g, " ").slice(0, 600)
  return createHash("sha256").update(agent + "\0" + prompt).digest("hex").slice(0, 16)
}

// Counts identical subagent launches while the Forge state has not changed. Returns a message to block with, or "".
function loopGuard(dir, args) {
  const file = join(dir, ".forge", "memory", ".launches.json")
  const seal = stateSeal(dir)
  let book = { seal, counts: {} }
  try { const old = JSON.parse(readFileSync(file, "utf8")); if (old.seal === seal) book = old } catch {}
  const key = launchKey(args)
  book.counts[key] = (book.counts[key] || 0) + 1
  try { writeFileSync(file, JSON.stringify(book)) } catch {}
  if (book.counts[key] < MAX_SAME_LAUNCHES) return ""
  return (
    `Forge loop guard: this subagent was launched ${book.counts[key]} times with the same request and the Forge state did not change. ` +
    "Stop launching it. Read `forge attempts`, write down what blocks and what you already tried, and if information is missing ask the user. " +
    "Launch again only after something changed (a file, a decision, an answer)."
  )
}

export const ForgePlugin = async ({ directory }) => {
  const dir = directory || process.cwd()
  return {
    // Put the present state of the project into the compacted summary.
    "experimental.session.compacting": async (_input, output) => {
      try {
        if (!isForgeProject(dir) || !output || !Array.isArray(output.context)) return
        const now = runCli(dir, ["memory", "resume"])
        if (now) output.context.push("Forge memory (keep verbatim):\n" + now)
      } catch {}
    },
    // Block the same subagent launch repeated without any progress in the Forge state.
    "tool.execute.before": async (input, output) => {
      let message = ""
      try {
        if (String(input && input.tool).toLowerCase() !== "task" || !isForgeProject(dir)) return
        message = loopGuard(dir, output && output.args)
      } catch {
        return
      }
      if (message) throw new Error(message)
    },
  }
}
