#!/bin/bash
# Stop hook — report git repositories under the project that have uncommitted changes.
# Stays silent when everything is clean, so it only speaks up when it matters.
#
# Requires: jq

# Where to look. Claude Code sets CLAUDE_PROJECT_DIR; fall back to this script's grandparent.
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Repositories to skip — substring match against the repo path.
# Add vendored clones, scratch areas, or anything you deliberately keep untracked.
EXCLUDES=("/.tools/" "/vendor/" "/node_modules/")

# How deep to search for .git directories.
MAXDEPTH=4

dirty=""

while IFS= read -r gitdir; do
  repo="${gitdir%/.git}"

  skip=""
  for ex in "${EXCLUDES[@]}"; do
    case "$repo" in *"$ex"*) skip=1; break ;; esac
  done
  [ -n "$skip" ] && continue

  n=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -gt 0 ]; then
    # Show a path relative to ROOT. When the repo *is* ROOT, the prefix strip is a
    # no-op, so fall back to the basename rather than printing an absolute path.
    rel="${repo#"$ROOT"/}"
    [ "$rel" = "$repo" ] && rel="$(basename "$repo")"
    dirty="${dirty}
  ${rel} … ${n}"
  fi
done < <(find "$ROOT" -maxdepth "$MAXDEPTH" -type d -name .git 2>/dev/null | sort)

# Clean: say nothing at all.
[ -z "$dirty" ] && exit 0

jq -cn --arg m "⚠ Uncommitted changes:${dirty}" '{systemMessage: $m}'
