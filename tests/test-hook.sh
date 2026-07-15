#!/usr/bin/env bash
# Checks the Stop hook: blocks on a prose em dash, passes clean text, exempts
# fenced code, and honors the loop guard.
H="$(cd "$(dirname "$0")/.." && pwd)/hooks/no-em-dash.sh"
fail=0
check() { # name expected_decision json
  got=$(printf '%s' "$3" | bash "$H" | jq -r '.decision // "none"' 2>/dev/null)
  [ -z "$got" ] && got=none
  if [ "$got" = "$2" ]; then echo "  ok: $1"; else echo "  FAIL: $1 (want $2, got $got)"; fail=1; fi
}
check "blocks prose em dash" block "$(jq -nc '{last_assistant_message:"This is it — the problem.", stop_hook_active:false}')"
check "passes clean prose"   none  "$(jq -nc '{last_assistant_message:"This is it. The problem.", stop_hook_active:false}')"
check "exempts fenced code"  none  "$(jq -nc '{last_assistant_message:"See:\n```\nx = 1 — 2\n```\ndone.", stop_hook_active:false}')"
check "honors loop guard"    none  "$(jq -nc '{last_assistant_message:"Still — broken.", stop_hook_active:true}')"
check "passes empty message" none  "$(jq -nc '{stop_hook_active:false}')"
exit $fail
