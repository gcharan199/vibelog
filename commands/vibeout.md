---
description: Generate today's summary of AI-assisted activity from the vibelog
argument-hint: "[YYYY-MM-DD]"
---

# /vibeout — generate the daily summary report

Argument `$ARGUMENTS` is an optional `YYYY-MM-DD` date. Empty means today.

## Procedure

Follow these steps exactly. Do **not** invent data — only report what's in the log file.

### 1. Resolve target date
- If `$ARGUMENTS` (after trimming whitespace) is empty: run `date +%Y-%m-%d` via Bash and use that as `<date>`.
- Otherwise: it must match the regex `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`. If it does not, respond **`Bad date. Use YYYY-MM-DD.`** and stop. Do not run any further commands. (This regex check defeats shell injection; still quote the variable in every command below.)

### 2. Locate log file
Compute `LOG="$HOME/.vibelog/logs/<date>.jsonl"` and `REPORT="$HOME/.vibelog/reports/<date>.md"`.

If `[ ! -s "$LOG" ]` (missing or empty), respond **`No vibelog data for <date> at <LOG>.`** and stop.

### 3. Extract structured stats with one Bash call

```bash
LOG="$HOME/.vibelog/logs/<date>.jsonl"
jq -s '{
  total: length,
  prompts: [.[] | select(.event=="user_prompt")] | length,
  prompt_texts: [.[] | select(.event=="user_prompt") | .text],
  intents:      [.[] | select(.event=="intent") | .text],
  tool_counts: ([.[] | select(.event=="tool_use") | .tool]
                | group_by(.) | map({tool: .[0], count: length})
                | sort_by(-.count)),
  files: ([.[] | select(.event=="tool_use" and (.tool=="Edit" or .tool=="Write" or .tool=="MultiEdit" or .tool=="NotebookEdit"))
              | (.summary.file_path // .summary.notebook_path // empty)]
          | map(select(. != null and . != ""))
          | unique),
  first_ts: ([.[].ts] | min),
  last_ts:  ([.[].ts] | max),
  by_hour: ([.[] | {hour: (.ts[11:13]), event, tool: (.tool // ""),
                    text: ((.text // "")[0:120])}])
}' "$LOG"
```

### 4. Compute session duration
From `first_ts` and `last_ts` compute minutes (rounded). If only one event exists, duration is `< 1 min`.

### 5. Render Mermaid pie (tool usage)

If `tool_counts` is non-empty:

```
pie showData
    title Tool usage
    "Edit" : 12
    "Bash" : 8
```

If empty (no tool calls all day): use a placeholder with one slice:

```
pie title No tool calls today
    "idle" : 1
```

(Mermaid requires at least one slice — placeholder prevents render errors.)

### 6. Render Mermaid timeline (major activities)

Group `by_hour` events into hourly buckets `00`–`23`. For each non-empty bucket, pick up to **2 representative entries** (prefer `user_prompt` text > non-Read tool use > Read).

**Format each row as `<hour-am-pm> : <short description>`** — e.g. `9am`, `10am`, `2pm`. **Do not use `HH:00` format** — Mermaid's timeline parser uses `:` as the period/event separator, so `09:00` produces "Parse error... got 'INVALID'". Use bare hours with `am`/`pm` suffix instead. The description must contain **no colons** — replace any `:` with `-` (≤60 chars).

```
timeline
    title <date> activity
    9am  : Started auth refactor
    10am : Tests passing
```

If zero hours have events: replace this block with a one-line italic placeholder `_(no activity logged)_` and skip the mermaid fence.

### 7. Synthesize prose sections

- **Today's intent.** From `intents`, render as a bullet list. If empty: `(no /vibein run today)`.
- **Summary.** One paragraph, 3–5 sentences, present tense, factual and concise. Synthesize from `prompt_texts`, `tool_counts`, and any intents. Reference the intent if it's there. Mention session length and total prompts. Don't pad — if the day was light, say so.
- **Decision log.** Walk `by_hour` chronologically. Group consecutive related events into 1–6 entries total. For each entry, write **1–2 sentences**: what Claude did + the *inferred* reason (drawn from the surrounding prompt). Skip noise like solo Read calls.

### 8. Write the report

Use the Write tool to create `$HOME/.vibelog/reports/<date>.md` with this exact section ordering:

```markdown
# vibelog — <date>

## Today's intent
<bullet list or "(no /vibein run today)">

## Summary
<one paragraph>

## Tool usage
```mermaid
<pie block>
```

## Timeline
```mermaid
<timeline block>
```
(or italic placeholder if no activity)

## Files touched
<bullet list, or "(none)">

> _Includes Edit/Write/MultiEdit/NotebookEdit attempts. Failed tool calls are not filtered out — vibelog logs `tool_input` only._

## Decision log
<1–6 entries, chronological>
```

**Idempotency:** if the report file already exists, overwrite it. The Write tool does this by default.

### 9. Confirm

After writing, respond with one line:

```
vibelog report written to <absolute path to report>
```

No other output. Don't summarize the summary back at the user — they can read the file.

## Edge cases checklist

- Empty / nonexistent log → step 2 stops cleanly.
- Single event log → all sections still render; pie/timeline use placeholders if needed.
- Bad date arg → step 1 stops cleanly with a one-liner.
- Rerun on same date → overwrites prior report.
- Log with only `session_start`/`session_end` events → `tool_counts` empty, `prompts` 0, summary acknowledges quiet day.
- File paths with spaces or unicode → `jq` and Write handle natively.
