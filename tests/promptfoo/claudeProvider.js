// promptfoo custom provider: runs the `claude` CLI so the SessionStart hook that
// injects RULES.md actually fires. The raw Anthropic API would not load the plugin.
// config.plugin=true adds --plugin-dir (rules active); false is the baseline.
const { execFileSync } = require("node:child_process");
const path = require("node:path");

const PLUGIN_ROOT = path.resolve(__dirname, "..", "..");
const SETTINGS = path.join(__dirname, "clean-settings.json");

module.exports = class ClaudeCliProvider {
  constructor(options) {
    this.providerId = options.id || "claude-cli";
    this.config = options.config || {};
  }

  id() {
    return this.providerId;
  }

  async callApi(prompt) {
    const args = ["-p", "--settings", SETTINGS];
    if (this.config.plugin) args.push("--plugin-dir", PLUGIN_ROOT);
    args.push(prompt);
    try {
      const output = execFileSync("claude", args, {
        input: "", // closes stdin, non-interactive
        encoding: "utf8",
        timeout: 200000,
        maxBuffer: 10 * 1024 * 1024,
      });
      return { output: output.trim() };
    } catch (e) {
      return { error: `claude CLI failed: ${e.message}` };
    }
  }
};
