---
description: Set today's focus / intent
argument-hint: "<your intent for today>"
---

# /vibein — declare today's focus

The user's intent text is `$ARGUMENTS`.

## Procedure

1. If `$ARGUMENTS` is empty (no text after `/vibein`), respond:
   `Usage: /vibein <what you're working on today>` and stop.

2. Append one JSONL line `{ts, event:"intent", text:<intent>}` to today's log file
   `$HOME/.claude/vibelog/logs/$(date +%Y-%m-%d).jsonl`. Use `jq -n` to ensure
   the text is JSON-escaped safely (handles quotes, backslashes, newlines).

   Concretely, run via Bash — substitute the user's intent into `<INTENT>` exactly as typed,
   passing it through shell `printf` so jq receives it through stdin (avoids any heredoc-collision
   or shell-escaping pitfalls):

   ```bash
   LOG="$HOME/.claude/vibelog/logs/$(date +%Y-%m-%d).jsonl"
   TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
   mkdir -p "$(dirname "$LOG")"
   printf '%s' '<INTENT>' | jq -cRs --arg ts "$TS" '{ts:$ts, event:"intent", text:.}' >> "$LOG"
   ```

   When substituting `<INTENT>`, single-quote the entire argument and replace any `'` in
   the user's text with `'\''` (POSIX-safe single-quote escaping). This is the only character
   you need to escape — `printf '%s'` plus `jq -Rs` handles every other byte.

3. Acknowledge with a single terse line:
   `intent logged: <intent>` — no extra commentary, no follow-up questions.
