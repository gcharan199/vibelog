#!/usr/bin/env bash
# vibelog: multi-platform installer.
# Sets up user-level hook configs for Codex CLI and Cursor.
# Claude Code installs separately via `/plugin marketplace add` — this script
# does NOT touch Claude Code config.
#
# Idempotent: re-run safely. Each platform is detected; missing platforms skipped.
set -e

VIBELOG_ROOT="$(cd "$(dirname "$0")" && pwd)"
echo "vibelog root: $VIBELOG_ROOT"

# Sanity: hook scripts must be executable
for f in "$VIBELOG_ROOT"/hooks/*.sh; do
  [ -x "$f" ] || chmod +x "$f"
done

substitute() {
  # $1 = source template, $2 = dest path
  sed "s|__VIBELOG_ROOT__|$VIBELOG_ROOT|g" "$1" > "$2"
}

backup_if_exists() {
  if [ -f "$1" ] && [ ! -L "$1" ]; then
    cp "$1" "$1.vibelog-backup-$(date +%s)"
    echo "  (backed up existing $1)"
  fi
}

# ------------------------------------------------------------- Codex CLI
echo
echo "── Codex CLI ──"
if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then
  mkdir -p "$HOME/.codex"
  TARGET="$HOME/.codex/hooks.json"
  backup_if_exists "$TARGET"
  substitute "$VIBELOG_ROOT/.codex/hooks.json" "$TARGET"
  echo "  ✓ wrote $TARGET"

  # Check feature flag
  CONFIG="$HOME/.codex/config.toml"
  if [ ! -f "$CONFIG" ] || ! grep -q "codex_hooks[[:space:]]*=[[:space:]]*true" "$CONFIG" 2>/dev/null; then
    echo
    echo "  ⚠ Codex hooks are experimental and require an opt-in flag."
    echo "    Add the following to $CONFIG:"
    echo
    echo "      [features]"
    echo "      codex_hooks = true"
    echo
  else
    echo "  ✓ codex_hooks feature flag is enabled"
  fi
else
  echo "  Codex CLI not detected (no \`codex\` binary, no ~/.codex directory). Skipped."
fi

# ------------------------------------------------------------- Cursor
echo
echo "── Cursor ──"
if [ -d "$HOME/Library/Application Support/Cursor" ] \
  || [ -d "$HOME/.config/Cursor" ] \
  || [ -d "$HOME/.cursor" ]; then
  mkdir -p "$HOME/.cursor"
  TARGET="$HOME/.cursor/hooks.json"
  backup_if_exists "$TARGET"
  substitute "$VIBELOG_ROOT/.cursor/hooks.json" "$TARGET"
  echo "  ✓ wrote $TARGET"
  echo "  Restart Cursor (or reload window) to load hooks."
  echo "  Requires Cursor 1.7 or later."
else
  echo "  Cursor not detected. Skipped."
fi

# ------------------------------------------------------------- Claude Code (info only)
echo
echo "── Claude Code ──"
echo "  Install via the Claude Code plugin marketplace:"
echo "    /plugin marketplace add gcharan199/vibelog"
echo "    /plugin install vibelog@vibelog"
echo "    /reload-plugins"

echo
echo "Done. Logs: $HOME/.vibelog/logs/<date>.jsonl"
