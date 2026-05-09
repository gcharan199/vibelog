#!/usr/bin/env bash
# vibelog: UserPromptSubmit hook (Claude Code, Codex), beforeSubmitPrompt (Cursor).
# Appends one JSONL line per user prompt. Must never block — always exit 0.
# Arg $1 = platform identifier ("claude-code", "codex", "cursor"). Defaults to "claude-code".
set -u

PLATFORM="${1:-claude-code}"
DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG="$HOME/.vibelog/logs/$DATE.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || printf '')
  printf '%s\n' "$INPUT" \
    | jq -c --arg ts "$TS" --arg text "$PROMPT" --arg platform "$PLATFORM" \
        '{ts:$ts, platform:$platform, event:"user_prompt", text:$text}' \
        >> "$LOG" 2>/dev/null || true
elif command -v python3 >/dev/null 2>&1; then
  printf '%s' "$INPUT" | TS="$TS" PLATFORM="$PLATFORM" python3 - >> "$LOG" 2>/dev/null <<'PY' || true
import json, os, sys
try:
    d = json.loads(sys.stdin.read() or "{}")
except Exception:
    d = {}
out = {
    "ts": os.environ.get("TS",""),
    "platform": os.environ.get("PLATFORM","claude-code"),
    "event": "user_prompt",
    "text": d.get("prompt","") or "",
}
print(json.dumps(out, ensure_ascii=False))
PY
else
  printf '{"ts":"%s","platform":"%s","event":"user_prompt","text":""}\n' "$TS" "$PLATFORM" >> "$LOG" 2>/dev/null || true
fi

exit 0
