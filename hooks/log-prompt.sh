#!/usr/bin/env bash
# vibelog: UserPromptSubmit hook. Appends one JSONL line per user prompt.
# Must never block — always exit 0.
set -u

DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG="$HOME/.claude/vibelog/logs/$DATE.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || printf '')
  printf '%s\n' "$INPUT" \
    | jq -c --arg ts "$TS" --arg text "$PROMPT" \
        '{ts:$ts, event:"user_prompt", text:$text}' \
        >> "$LOG" 2>/dev/null || true
elif command -v python3 >/dev/null 2>&1; then
  printf '%s' "$INPUT" | TS="$TS" python3 - >> "$LOG" 2>/dev/null <<'PY' || true
import json, os, sys
try:
    d = json.loads(sys.stdin.read() or "{}")
except Exception:
    d = {}
out = {"ts": os.environ.get("TS",""), "event": "user_prompt", "text": d.get("prompt","") or ""}
print(json.dumps(out, ensure_ascii=False))
PY
else
  printf '{"ts":"%s","event":"user_prompt","text":""}\n' "$TS" >> "$LOG" 2>/dev/null || true
fi

exit 0
