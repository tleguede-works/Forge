// Forge plugin for OpenCode. Installed to .opencode/plugin/forge.ts or ~/.config/opencode/plugin/forge.ts.
// UNVERIFIED against a live OpenCode: hook names come from public plugin docs; test with `forge hooks status`
// and a real compaction before publishing.
import type { Plugin } from "@opencode-ai/plugin"

const EDIT_LIMIT = 10
const FORGE = "forge"

export const ForgePlugin: Plugin = async ({ $, directory }) => {
  let edits = 0
  const resume = async () => {
    try {
      return await $`${FORGE} memory resume`.cwd(directory).text()
    } catch {
      return ""
    }
  }
  return {
    // Re-inject the present state into the compacted summary.
    "experimental.session.compacting": async (_input: any, output: any) => {
      const now = await resume()
      if (now) output.context.push("Forge memory (keep verbatim):\n" + now)
    },
    "tool.execute.after": async (input: any) => {
      if (!["write", "edit", "patch"].includes(String(input.tool).toLowerCase())) return
      edits += 1
      if (edits >= EDIT_LIMIT) {
        edits = 0
        await $`${FORGE} memory log --text ${"edit threshold reached: checkpoint due"}`.cwd(directory).quiet()
      }
    },
  }
}
