#!/usr/bin/env bash
# vibelog: SessionEnd hook. Logs session_end. If today's log has events but
# no report file exists, emit a reminder to stdout.
# Must never block — always exit 0.
set -u

DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG_DIR="$HOME/.claude/vibelog/logs"
REPORT_DIR="$HOME/.claude/vibelog/reports"
LOG="$LOG_DIR/$DATE.jsonl"
REPORT="$REPORT_DIR/$DATE.md"
mkdir -p "$LOG_DIR" "$REPORT_DIR" 2>/dev/null || true

cat > /dev/null 2>&1 || true

printf '{"ts":"%s","event":"session_end"}\n' "$TS" >> "$LOG" 2>/dev/null || true

if [ -s "$LOG" ] && [ ! -f "$REPORT" ]; then
  printf 'vibelog: today (%s) has activity but no report yet. Run /vibeout to summarize.\n' "$DATE"
fi

exit 0
