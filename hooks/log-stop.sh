#!/usr/bin/env bash
# vibelog: Stop / stop hook. Appends one turn_end line. NEVER does anything else.
# CRITICAL: must exit 0, must not return exit code 2 (would force the agent to
# continue → infinite loop). Append + exit 0. No conditional logic.
# Arg $1 = platform identifier. Defaults to "claude-code".
set -u

PLATFORM="${1:-claude-code}"
DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG="$HOME/.vibelog/logs/$DATE.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

# Drain stdin so the parent doesn't see a SIGPIPE, but we don't use it.
cat > /dev/null 2>&1 || true

printf '{"ts":"%s","platform":"%s","event":"turn_end"}\n' "$TS" "$PLATFORM" >> "$LOG" 2>/dev/null || true

exit 0
