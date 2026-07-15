#!/usr/bin/env bash
# Blocks the turn when the reply contains an em dash, and tells the model to
# rewrite rather than substitute. Requires jq.
set -uo pipefail

input=$(cat)

# Loop guard. A Stop hook already blocked this turn, so let it through.
if [ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ]; then
  exit 0
fi

msg=$(jq -r '.last_assistant_message // ""' <<<"$input")

# Fenced code is exempt. Quoting a file that contains an em dash is not the
# failure this rule is about, and blocking there would be wrong.
prose=$(printf '%s\n' "$msg" | awk '/^[[:space:]]*```/{f=!f; next} !f')

if printf '%s' "$prose" | grep -q '—'; then
  jq -n '{
    decision: "block",
    reason: "Your reply contains an em dash. Rewrite the sentences it appears in so that no dash is needed, then send the corrected reply. Do not swap the dash for a comma, colon, semicolon, parenthesis, or en dash. That is the same failure wearing different punctuation. Where you felt the dash, you have two sentences trying to be one. Write them as two."
  }'
fi

exit 0
