#!/usr/bin/env bash
# vibelog: SessionEnd (Claude Code) / sessionEnd (Cursor) hook.
# Note: Codex CLI does NOT emit SessionEnd — it uses Stop instead.
# Logs session_end. If today's log has events but no report file exists,
# emit a reminder to stdout. Must never block — always exit 0.
# Arg $1 = platform identifier. Defaults to "claude-code".
set -u

PLATFORM="${1:-claude-code}"
DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG_DIR="$HOME/.vibelog/logs"
REPORT_DIR="$HOME/.vibelog/reports"
LOG="$LOG_DIR/$DATE.jsonl"
REPORT="$REPORT_DIR/$DATE.md"
mkdir -p "$LOG_DIR" "$REPORT_DIR" 2>/dev/null || true

cat > /dev/null 2>&1 || true

printf '{"ts":"%s","platform":"%s","event":"session_end"}\n' "$TS" "$PLATFORM" >> "$LOG" 2>/dev/null || true

if [ -s "$LOG" ] && [ ! -f "$REPORT" ]; then
  printf 'vibelog: today (%s) has activity but no report yet. Run /vibeout to summarize.\n' "$DATE"
fi

exit 0
