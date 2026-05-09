#!/usr/bin/env bash
# vibelog: Stop hook. Appends one turn_end line. NEVER does anything else.
# CRITICAL: must exit 0, must not return exit code 2 (would force Claude to
# continue → infinite loop). Append + exit 0. No conditional logic.
set -u

DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG="$HOME/.claude/vibelog/logs/$DATE.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

# Drain stdin so the parent doesn't see a SIGPIPE, but we don't use it.
cat > /dev/null 2>&1 || true

printf '{"ts":"%s","event":"turn_end"}\n' "$TS" >> "$LOG" 2>/dev/null || true

exit 0
