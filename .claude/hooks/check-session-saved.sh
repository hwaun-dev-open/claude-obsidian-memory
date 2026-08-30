#!/bin/bash
# Stop hook — backstop for the session log.
#
# The CLAUDE.md rules are the primary mechanism: Claude should save when a request completes,
# not when the session ends (it cannot observe the end). This hook catches the case where that
# didn't happen, by blocking the stop once and telling Claude to write the note.
#
# Does nothing unless VAULT below points at a real directory, so it's safe to ship unconfigured.
#
# Requires: jq

# ── Configure ────────────────────────────────────────────────────────────────
# Absolute path to your Obsidian vault. Leave empty to disable this hook entirely.
VAULT=""
# Folder under "Claude Code/Sessions/" for this project. Defaults to the project directory name.
PROJECT=""
# ─────────────────────────────────────────────────────────────────────────────

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
[ -z "$PROJECT" ] && PROJECT="$(basename "$ROOT")"

# Not configured, or the vault moved: stay out of the way.
[ -z "$VAULT" ] && exit 0
[ -d "$VAULT" ] || exit 0

TODAY=$(date +%Y-%m-%d)
SESSION_DIR="$VAULT/Claude Code/Sessions/$PROJECT"

# Already saved today? Let the stop through.
if [ -d "$SESSION_DIR" ] && \
   find "$SESSION_DIR" -maxdepth 1 -name "$TODAY - *.md" -print -quit 2>/dev/null | grep -q .; then
  exit 0
fi

# Nag at most once per day, so a failed save (MCP down, vault unmounted) can't trap the session.
MARKER="$ROOT/.claude/.session-save-prompted"
[ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$TODAY" ] && exit 0
echo "$TODAY" > "$MARKER"

jq -cn --arg p "$PROJECT" '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    decision: "block",
    reason: ("この会話のセッションログがまだ保存されていません。CLAUDE.md の「保存のタイミング」に従い、"
      + "Claude Code/Sessions/" + $p + "/YYYY-MM-DD - <topic>.md に保存してください。"
      + "frontmatter の summary と aliases を必ず埋めること（次回の検索で使う唯一の手がかりのため）。"
      + "保存したら、その日のデイリーノートの ## Claude Code 見出しにもリンクを追記してください。")
  }
}'
