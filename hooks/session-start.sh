#!/usr/bin/env bash
# vibelog: SessionStart / sessionStart hook. Logs session_start AND prints a
# context note to stdout if there are unsummarized days. On Claude Code +
# Codex, SessionStart stdout becomes added context.
# Must never block — always exit 0.
# Arg $1 = platform identifier. Defaults to "claude-code".
set -u

PLATFORM="${1:-claude-code}"
DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG_DIR="$HOME/.vibelog/logs"
REPORT_DIR="$HOME/.vibelog/reports"
LOG="$LOG_DIR/$DATE.jsonl"
mkdir -p "$LOG_DIR" "$REPORT_DIR" 2>/dev/null || true

cat > /dev/null 2>&1 || true

printf '{"ts":"%s","platform":"%s","event":"session_start"}\n' "$TS" "$PLATFORM" >> "$LOG" 2>/dev/null || true

# Find log dates without matching reports.
unsummarized=""
if [ -d "$LOG_DIR" ]; then
  for f in "$LOG_DIR"/*.jsonl; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .jsonl)
    [ "$base" = "$DATE" ] && continue
    if [ ! -f "$REPORT_DIR/$base.md" ]; then
      unsummarized="$unsummarized $base"
    fi
  done
fi

if [ -n "$unsummarized" ]; then
  list=$(echo $unsummarized | tr ' ' ',')
  printf 'vibelog: unsummarized days found: %s. Run /vibeout <date> to summarize.\n' "$list"
fi

exit 0
