# cut-to-the-chase

Makes Claude answer the question and stop. No filler, no AI tells, no em dashes.

Rules like these usually live in a skill, which loads on demand. By the time the
model decides it needs the skill, it has already written the reply the skill was
meant to prevent. This ships them as a `SessionStart` hook, so they are in
context before the first token.

## Install

```
/plugin marketplace add maikbasel/cut-to-the-chase
/plugin install cut-to-the-chase@maikb-skills
```

Nothing to configure. Run `/reload-plugins` to use it in the current session, or
it loads on your next one.

## Removing it

```
/plugin uninstall cut-to-the-chase@maikb-skills
/plugin marketplace remove maikb-skills
```

To keep it installed but off: `/plugin disable cut-to-the-chase@maikb-skills`

## What it enforces

**Answer first, then stop.** Sentence one answers the question. Hard ceiling of
150 words, which lifts only when you explicitly ask for a report or a
walkthrough. In practice replies land near 200 words instead of 479.

**No em dashes.** Not by deleting the character. Swapping in a comma is the same
failure with different punctuation. Where a dash wants to go there are two
sentences trying to be one, so it writes them as two.

**Every sentence carries a fact.** Short replies can still say nothing, closing
each paragraph with a line like "the seal leaks" that sounds like a conclusion
and hands you nothing. The test: if a sentence would read fine pasted into an
answer about a different topic, it is filler.

Metaphors are allowed. "Debt you never pay interest on is not worth tracking"
tells you what to skip. "The seal leaks" does not.

[RULES.md](RULES.md) is the exact text injected into every session.

## Does it work

Ten runs of one question, five with the plugin and five without, every other
prose-guidance plugin disabled.

| | em dashes | words per reply |
|---|---|---|
| Without | 22 across 5 replies | 431 to 549 |
| With | 0 | 164 to 257 |

Reproduce with `bash tests/run.sh`, which needs a logged-in `claude` CLI.

The em dash and word counts are machine-checked. The third rule is not, since
emptiness cannot be counted.

## How it works

```
SessionStart hook  ->  cat RULES.md  ->  stdout becomes session context
```

No scripts, no runtime, no dependencies.

## Optional: block em dashes hard

`hooks/no-em-dash.sh` is a `Stop` hook that blocks any reply containing an em
dash and tells the model to rewrite rather than substitute. It ships unwired,
because the rules alone already score zero and the hook needs `jq` on your
machine.

Wire it by adding this to `hooks/hooks.json`:

```json
"Stop": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/no-em-dash.sh\"",
        "timeout": 5
      }
    ]
  }
]
```

Fenced code is exempt, so quoting a file that contains an em dash will not block
the turn.

## License

MIT
