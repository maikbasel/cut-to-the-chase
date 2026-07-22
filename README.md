# Cut to the Chase!

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

**Answer first, then stop.** Sentence one answers the question. The reply leads
with the answer or correction and cuts opening validation, no "Great question",
no restating your point back. No word ceiling: a reply runs as long as the facts
it carries and no longer, then stops. Padding and summary get cut, not detail.

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

|         | em dashes           | words per reply |
|---------|---------------------|-----------------|
| Without | 28 across 5 replies | 333 to 444      |
| With    | 0                   | 265 to 323      |

These counts are from v0.2, which capped replies at 150 words. v0.3 drops the
ceiling in favor of fact-density, so word counts will run higher. Re-run `node
tests/benchmark.mjs` (needs a logged-in `claude` CLI) to refresh the numbers.
The em dash result holds: zero either way.

The em dash and word counts are machine-checked. The third rule is not, since
emptiness cannot be counted.

For a graded A/B eval, `tests/promptfoo/` runs the same baseline-vs-plugin
comparison through [promptfoo](https://promptfoo.dev): deterministic checks for
em dashes and opening validation, plus an LLM-rubric for answer-first and
fact-density. The rubric is phrased binary so the judge's own verbosity bias
does not reward the longer reply. Run it with `npx promptfoo@latest eval -c
tests/promptfoo/promptfooconfig.yaml` (needs the same logged-in `claude` CLI, no
API key).

## How it works

```
SessionStart hook  ->  cat RULES.md  ->  stdout becomes session context
```

The rules inject with no dependencies. The Stop hook that blocks em dashes needs
`jq`.

## Block em dashes hard

`hooks/no-em-dash.sh` is a `Stop` hook, wired in by default, that blocks any
reply containing an em dash and tells the model to rewrite rather than
substitute. It needs `jq` on your machine.

Fenced code is exempt, so quoting a file that contains an em dash will not block
the turn.

## License

MIT
