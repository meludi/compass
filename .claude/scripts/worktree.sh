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
#   dev_port         — base dev server port (default 3000); worktrees get dev_port + N
#   dev_cmd          — dev server start command (default: npm run dev)
#
# Rules:
#   - Each worktree gets its own dev port (dev_port + N), stored in .worktree-port.
#   - Start the dev server from the worktree: PORT=$(cat .worktree-port) <dev_cmd>
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
DEV_PORT=$(grep -m1 "^dev_port:" "$YML" 2>/dev/null | cut -d: -f2 | tr -d ' "' || true)
DEV_CMD=$(grep -m1 "^dev_cmd:" "$YML" 2>/dev/null | sed 's/^dev_cmd:[[:space:]]*//' | tr -d '"' || true)
PM="${PM:-npm}"
DEV_PORT="${DEV_PORT:-3000}"
DEV_CMD="${DEV_CMD:-npm run dev}"

if [ "$ACTION" = "rm" ]; then
  git -C "$ROOT" worktree remove --force "$TARGET" 2>/dev/null || true
  rm -rf "$TARGET"
  git -C "$ROOT" worktree prune
  git -C "$ROOT" branch -D "$BRANCH" 2>/dev/null || true
  echo "[worktree] removed $TARGET"
  exit 0
fi

if [ ! -d "$TARGET" ]; then
  WORKTREE_COUNT=$(git -C "$ROOT" worktree list | wc -l | tr -d ' ')
  WORKTREE_PORT=$((DEV_PORT + WORKTREE_COUNT))

  git -C "$ROOT" worktree add "$TARGET" -b "$BRANCH"

  # .env.local: symlink from main (config, not state)
  if [ -f "$ROOT/.env.local" ]; then
    ln -sf "$ROOT/.env.local" "$TARGET/.env.local"
  fi

  echo "$WORKTREE_PORT" > "$TARGET/.worktree-port"

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
if [ -f "$TARGET/.worktree-port" ]; then
  echo "[worktree] dev server:  PORT=$(cat "$TARGET/.worktree-port") $DEV_CMD"
fi
if [ "$ACTION" = "open" ]; then
  cd "$TARGET" && claude
fi
