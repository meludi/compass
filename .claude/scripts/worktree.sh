#!/usr/bin/env bash
# worktree.sh <name> [open|rm] — full worktree lifecycle.
#
#   worktree.sh feature-name          -> create worktree on feat/feature-name
#   worktree.sh feature-name open     -> create + launch claude inside it
#   worktree.sh feature-name rm       -> remove worktree dir + git branch
#
# Reads from .claude/project.yml:
#   package_manager  — npm | pnpm | yarn | bun
#   db_file          — optional DB to copy per worktree (e.g. myapp.db); leave blank to skip
#
# Rules:
#   - Dev server ALWAYS runs from the main project dir, never from the worktree.
#   - .env.local is symlinked from main (read-only config, safe to share).
#   - db_file is COPIED (not symlinked) — each worktree gets its own isolated DB.
#   - No manual file copying across worktrees — all changes via git commit on feature branch.

set -euo pipefail

NAME="${1:?usage: worktree.sh <name> [open|rm]}"
ACTION="${2:-create}"
ROOT="$(git rev-parse --show-toplevel)"
PARENT="$(dirname "$ROOT")"
TARGET="$PARENT/$(basename "$ROOT")-$NAME"
BRANCH="feat/$NAME"

# Read from .claude/project.yml
YML="$ROOT/.claude/project.yml"
PM=$(grep -m1 "^package_manager:" "$YML" 2>/dev/null | cut -d: -f2 | tr -d ' ' || true)
DB=$(grep -m1 "^db_file:" "$YML" 2>/dev/null | cut -d: -f2 | tr -d ' ' || true)
PM="${PM:-npm}"

if [ "$ACTION" = "rm" ]; then
  git -C "$ROOT" worktree remove --force "$TARGET" 2>/dev/null || true
  rm -rf "$TARGET"
  git -C "$ROOT" worktree prune
  git -C "$ROOT" branch -D "$BRANCH" 2>/dev/null || true
  echo "[worktree] removed $TARGET"
  exit 0
fi

if [ ! -d "$TARGET" ]; then
  git -C "$ROOT" worktree add "$TARGET" -b "$BRANCH"

  # .env.local: symlink from main (config, not state)
  if [ -f "$ROOT/.env.local" ]; then
    ln -sf "$ROOT/.env.local" "$TARGET/.env.local"
  fi

  # DB: copy from main so each worktree has an isolated DB
  if [ -n "$DB" ] && [ -f "$ROOT/$DB" ]; then
    cp "$ROOT/$DB" "$TARGET/$DB"
    echo "[worktree] copied $DB to $TARGET"
  elif [ -n "$DB" ]; then
    echo "[worktree] db_file=$DB configured but not found in $ROOT — skipping"
  fi

  # Install dependencies
  case "$PM" in
    pnpm) pnpm --dir "$TARGET" install --frozen-lockfile --prefer-offline ;;
    yarn) yarn --cwd "$TARGET" install --frozen-lockfile ;;
    bun)  bun install --cwd "$TARGET" ;;
    *)    npm --prefix "$TARGET" ci ;;
  esac
fi

echo "[worktree] worktree: $TARGET  branch: $BRANCH"
if [ "$ACTION" = "open" ]; then
  cd "$TARGET" && claude
fi
