#!/usr/bin/env bash
# A/B test: same question, 5 reps with the plugin and 5 without, other plugins
# disabled so the baseline is not contaminated by someone else's style rules.
# Prints em-dash and word counts per rep. Requires a logged-in `claude` CLI.
set -uo pipefail

PLUGIN=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

Q=${1:-"Answer this question for a colleague: Why do small teams often regret adopting microservices?"}
REPS=${REPS:-5}

# Disable every plugin that injects prose guidance, or the baseline measures
# their rules instead of the absence of ours.
cat >"$WORK/clean.json" <<'EOF'
{
  "enabledPlugins": {
    "ponytail@ponytail": false,
    "superpowers@claude-plugins-official": false,
    "claude-obsidian@agricidaniel-claude-obsidian": false,
    "andrej-karpathy-skills@karpathy-skills": false
  }
}
EOF

echo "Running $((REPS * 2)) reps..."
for i in $(seq 1 "$REPS"); do
  timeout 200 claude -p --settings "$WORK/clean.json" \
    "$Q" </dev/null >"$WORK/base-$i.txt" 2>/dev/null &
  timeout 200 claude -p --settings "$WORK/clean.json" --plugin-dir "$PLUGIN" \
    "$Q" </dev/null >"$WORK/with-$i.txt" 2>/dev/null &
done
wait

report() { # label
  local total=0
  for i in $(seq 1 "$REPS"); do
    local f="$WORK/$1-$i.txt"
    local d w
    d=$(grep -o '—' "$f" 2>/dev/null | wc -l)
    w=$(wc -w <"$f" 2>/dev/null)
    total=$((total + d))
    printf "  %-8s rep %s  dashes=%-3s words=%s\n" "$1" "$i" "$d" "$w"
  done
  printf "  %-8s TOTAL em dashes: %s\n\n" "$1" "$total"
}

echo
report base
report with
echo "Expect: base emits em dashes and runs long. with emits zero and stays near 150 words."
