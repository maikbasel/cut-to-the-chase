# cut-to-the-chase

Makes Claude answer the question and stop. No filler, no AI tells, no em dashes.

Most "write better" instructions live in a skill, which loads on demand. By the
time the model decides it needs the skill, it has already written the reply the
skill was supposed to prevent. This ships the rules as a `SessionStart` hook, so
they are in context before the first token.

## Install

```
/plugin marketplace add maikbasel/cut-to-the-chase
/plugin install cut-to-the-chase@maikb-skills
```

Nothing to configure. It is on from the next session.

## Does it work

Measured, not asserted. Ten runs of one question, five with the plugin and five
without, every other prose-guidance plugin disabled so the baseline is honest.

| | em dashes | words per reply |
|---|---|---|
| Without | 22 across 5 replies | 431 to 549 |
| With | **0** | 157 to 212 |

Same question, same model. The answers stayed complete. They stopped padding.

```
bash tests/run.sh          # reproduces the table (needs a logged-in claude CLI)
bash tests/test-hook.sh    # unit-tests the optional Stop hook
```

Ten reps on one question is not proof of a zero rate. It is evidence the rate is
low enough that ten samples missed it.

## What it enforces

**Shape.** Sentence one answers the question. Hard ceiling of 150 words. The
ceiling lifts only when you explicitly ask for a report or a walkthrough.

**No em dashes.** The rule is not "delete the character". Swapping in a comma is
the same failure wearing different punctuation. Where a dash wants to go, there
are two sentences trying to be one, so it writes them as two.

**Plain language.** No throat-clearing, no hedges, no "not X, it's Y", no
pull-quotes, no vague declaratives.

[RULES.md](RULES.md) is the exact text injected into every session. It is the
whole product. Read it in a minute.

## How it works

```
SessionStart hook  ->  cat RULES.md  ->  stdout becomes session context
```

That is the entire mechanism. No scripts, no runtime, no dependencies.

## Optional hard enforcement

`hooks/no-em-dash.sh` is a `Stop` hook that blocks any reply containing an em
dash and tells the model to rewrite rather than substitute. It is tested but
**not wired up**, because injection alone already scored zero and the hook needs
`jq`. A Stop hook that errors fires on every turn, which is a bad trade for a
violation the test could not find.

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

## Prior art

The rules overlap with [stop-slop](https://hvpandya.com) by Hardik Pandya, which
is a skill covering prose quality broadly. This borrows its shape, not its text.
Two differences: stop-slop says "Em-dash anywhere? Remove it", which is the
character-swap failure, and it loads on demand, which is too late.

## License

MIT
