#!/usr/bin/env node
// A/B benchmark: baseline vs plugin, em-dash and word counts across REPS reps.
// Prints the markdown table used in the README. Replaces the old run.sh.
//
// Portable: isolation comes from clean-settings.json ({"enabledPlugins": {}}),
// which disables every user plugin for the run without naming any. So no
// contributor's own prose plugins leak into the baseline. --plugin-dir still
// loads the plugin under test even with enabledPlugins emptied (verified).
//
// Needs a logged-in `claude` CLI. Usage:  node tests/benchmark.mjs ["question"]
// Override rep count with REPS=3 node tests/benchmark.mjs
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PLUGIN_ROOT = path.resolve(__dirname, "..");
const SETTINGS = path.join(__dirname, "promptfoo", "clean-settings.json");

const QUESTION =
  process.argv[2] ||
  "Answer this question for a colleague: Why do small teams often regret adopting microservices?";
const REPS = Number(process.env.REPS || 5);

function ask(withPlugin) {
  const args = ["-p", "--settings", SETTINGS];
  if (withPlugin) args.push("--plugin-dir", PLUGIN_ROOT);
  args.push(QUESTION);
  return execFileSync("claude", args, {
    input: "", // closes stdin, non-interactive
    encoding: "utf8",
    timeout: 200000,
    maxBuffer: 10 * 1024 * 1024,
  }).trim();
}

const emDashes = (s) => (s.match(/—/g) || []).length;
const words = (s) => s.split(/\s+/).filter(Boolean).length;

function run(label, withPlugin) {
  let dashTotal = 0;
  const wordCounts = [];
  for (let i = 1; i <= REPS; i++) {
    const out = ask(withPlugin);
    const d = emDashes(out);
    const w = words(out);
    dashTotal += d;
    wordCounts.push(w);
    console.log(`  ${label.padEnd(11)} rep ${i}  dashes=${String(d).padEnd(3)} words=${w}`);
  }
  const lo = Math.min(...wordCounts);
  const hi = Math.max(...wordCounts);
  console.log(`  ${label.padEnd(11)} TOTAL em dashes: ${dashTotal}  |  words ${lo}-${hi}\n`);
  return { dashTotal, lo, hi };
}

console.log(`Running ${REPS * 2} reps...\n`);
const base = run("baseline", false);
const withP = run("with-plugin", true);

console.log("| | em dashes | words per reply |");
console.log("|---|---|---|");
console.log(`| Without | ${base.dashTotal} across ${REPS} replies | ${base.lo} to ${base.hi} |`);
console.log(`| With | ${withP.dashTotal} | ${withP.lo} to ${withP.hi} |`);
