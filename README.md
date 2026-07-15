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

Nothing to configure. Run `/reload-plugins` to use it in the current session, or
it loads on your next one.

## Turning it off

Try it off for one session before removing it:

```
/plugin disable cut-to-the-chase@maikb-skills
/reload-plugins
```

That leaves it installed. Re-enable with `/plugin enable cut-to-the-chase@maikb-skills`.

To remove the plugin but keep the marketplace:

```
/plugin uninstall cut-to-the-chase@maikb-skills
```

To remove both:

```
/plugin marketplace remove maikb-skills
```

Removing the marketplace uninstalls every plugin you got from it. Since this
marketplace only ships one plugin, that's the same thing here.

Nothing to clean up by hand. The plugin writes no files, sets no config, and
leaves nothing behind outside `~/.claude/plugins/`.

## Does it work

Measured, not asserted. Ten runs of one question, five with the plugin and five
without, every other prose-guidance plugin disabled so the baseline is honest.

| | em dashes | words per reply |
|---|---|---|
| Without | 22 across 5 replies | 431 to 549 |
| With | **0** | 164 to 257 |

Same question, same model. The answers stayed complete. They stopped padding.

```
bash tests/run.sh          # reproduces the table (needs a logged-in claude CLI)
bash tests/test-hook.sh    # unit-tests the optional Stop hook
```

Ten reps on one question is not proof of a zero rate. It is evidence the rate is
low enough that ten samples missed it.

The third rule below is not in that table. Emptiness cannot be counted, so it was
judged by a human reading blind samples. Treat it as weaker evidence than the two
numbers above.

## What it enforces

**Shape.** Sentence one answers the question, then a hard ceiling of 150 words.
The ceiling is an anchor, not a limit. Replies land near 200 rather than at 150,
but without a number they land at 479. An earlier version said "only what changes
the reader's next action", with no number, and produced 310 words scattered from
250 to 370. The number does the work. The ceiling lifts only when you explicitly
ask for a report or a walkthrough.

**No em dashes.** The rule is not "delete the character". Swapping in a comma is
the same failure wearing different punctuation. Where a dash wants to go, there
are two sentences trying to be one, so it writes them as two.

**Every sentence carries a fact.** The one that took longest to find. Replies
were already short and still said nothing, closing each paragraph with a line
like "the seal leaks" that sounds like a conclusion and hands you nothing. The
test: if a sentence would read fine pasted into an answer about a different
topic, it is filler.

Metaphors are allowed. "Debt you never pay interest on is not worth tracking"
tells you what to skip. "The seal leaks" does not. The test is the fact, not the
figure of speech.

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

## License

MIT
