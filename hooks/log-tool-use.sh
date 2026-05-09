#!/usr/bin/env bash
# vibelog: PostToolUse hook. Appends one JSONL line per tool call.
# tool_input/tool_response can be huge — truncate any string field at 500 chars.
# Must never block — always exit 0.
set -u

DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG="$HOME/.claude/vibelog/logs/$DATE.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  printf '%s' "$INPUT" \
    | jq -c --arg ts "$TS" '
        def trunc500: if type == "string" and (length > 500)
                      then .[0:500] + "…[truncated]"
                      else . end;
        def walk_trunc:
          if type == "object" then map_values(walk_trunc)
          elif type == "array" then map(walk_trunc)
          else trunc500 end;
        {
          ts: $ts,
          event: "tool_use",
          tool: (.tool_name // ""),
          summary: ((.tool_input // {}) | walk_trunc)
        }
      ' >> "$LOG" 2>/dev/null || true
elif command -v python3 >/dev/null 2>&1; then
  printf '%s' "$INPUT" | TS="$TS" python3 - >> "$LOG" 2>/dev/null <<'PY' || true
import json, os, sys
def walk(x):
    if isinstance(x, dict):  return {k: walk(v) for k,v in x.items()}
    if isinstance(x, list):  return [walk(v) for v in x]
    if isinstance(x, str) and len(x) > 500: return x[:500] + "…[truncated]"
    return x
try:    d = json.loads(sys.stdin.read() or "{}")
except: d = {}
out = {"ts": os.environ.get("TS",""), "event": "tool_use",
       "tool": d.get("tool_name","") or "",
       "summary": walk(d.get("tool_input", {}) or {})}
print(json.dumps(out, ensure_ascii=False))
PY
else
  printf '{"ts":"%s","event":"tool_use","tool":"","summary":{}}\n' "$TS" >> "$LOG" 2>/dev/null || true
fi

exit 0
