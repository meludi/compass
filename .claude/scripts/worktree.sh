#!/usr/bin/env bash
# worktree.sh <name> [open|rm] — full worktree lifecycle.
#
#   worktree.sh feature-name          -> create worktree on feat/feature-name
#   worktree.sh feature-name open     -> create + launch claude inside it
#   worktree.sh feature-name rm       -> remove worktree dir + git branch (guarded:
#                                        refuses on uncommitted or unmerged work)
#   worktree.sh feature-name rm -f    -> force removal (skips the guards)
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

# Read from .claude/project.yml (strip inline comments + surrounding quotes/space)
YML="$ROOT/.claude/project.yml"
read_yml() {
  grep -m1 "^$1:" "$YML" 2>/dev/null | cut -d: -f2- | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' | tr -d '"' || true
}
PM=$(read_yml package_manager)
DB=$(read_yml db_file)
DEV_PORT=$(read_yml dev_port)
DEV_CMD=$(read_yml dev_cmd)
BASE=$(read_yml base_branch)
PM="${PM:-npm}"
DEV_PORT="${DEV_PORT:-3000}"
DEV_CMD="${DEV_CMD:-npm run dev}"
BASE="${BASE:-main}"

# rm supports a force flag: worktree.sh <name> rm [-f|--force]
FORCE=""
case "${3:-}" in -f | --force) FORCE=1 ;; esac

if [ "$ACTION" = "rm" ]; then
  WT_EXISTS=0; [ -d "$TARGET" ] && WT_EXISTS=1
  BR_EXISTS=0; git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BRANCH" && BR_EXISTS=1

  if [ "$WT_EXISTS" -eq 0 ] && [ "$BR_EXISTS" -eq 0 ]; then
    echo "[worktree] nothing to remove: no dir at $TARGET and no branch $BRANCH"
    exit 0
  fi

  # Refuse if invoked from inside the worktree being removed
  case "$PWD/" in
    "$TARGET/"*) echo "[worktree] refusing: you are inside $TARGET — run from the main project dir"; exit 1 ;;
  esac

  if [ -z "$FORCE" ]; then
    # Guard 1 — uncommitted changes in the worktree
    if [ "$WT_EXISTS" -eq 1 ] && [ -n "$(git -C "$TARGET" status --porcelain 2>/dev/null)" ]; then
      echo "[worktree] refusing: uncommitted changes in $TARGET — commit/stash, or pass --force"
      exit 1
    fi
    # Guard 2 — commits not merged into the base branch
    if [ "$BR_EXISTS" -eq 1 ]; then
      if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BASE"; then
        BASEREF="$BASE"
      elif git -C "$ROOT" show-ref --verify --quiet "refs/remotes/origin/$BASE"; then
        BASEREF="origin/$BASE"
      else
        echo "[worktree] refusing: base branch '$BASE' not found locally or on origin — cannot verify merge; pass --force to remove anyway"
        exit 1
      fi
      AHEAD=$(git -C "$ROOT" rev-list --count "$BASEREF..$BRANCH" 2>/dev/null || echo 0)
      if [ "$AHEAD" -gt 0 ]; then
        if git -C "$ROOT" rev-parse --verify --quiet "$BRANCH@{upstream}" >/dev/null 2>&1; then
          UNPUSHED=$(git -C "$ROOT" rev-list --count "$BRANCH@{upstream}..$BRANCH" 2>/dev/null || echo 0)
          [ "$UNPUSHED" -eq 0 ] && NOTE="pushed to its upstream — recoverable from remote" || NOTE="$UNPUSHED commit(s) not pushed — local-only, will be lost"
        else
          NOTE="no upstream set — local-only, will be lost"
        fi
        echo "[worktree] refusing: $BRANCH has $AHEAD commit(s) not merged into $BASEREF ($NOTE). Merge first, or pass --force"
        exit 1
      fi
    fi
  fi

  # Guards passed (or --force) → remove
  if [ -n "$FORCE" ]; then
    git -C "$ROOT" worktree remove --force "$TARGET" 2>/dev/null || true
  else
    git -C "$ROOT" worktree remove "$TARGET" 2>/dev/null || true
  fi
  rm -rf "$TARGET"
  git -C "$ROOT" worktree prune
  if [ "$BR_EXISTS" -eq 1 ]; then
    if [ -n "$FORCE" ]; then
      git -C "$ROOT" branch -D "$BRANCH" 2>/dev/null || true
    else
      git -C "$ROOT" branch -d "$BRANCH" 2>/dev/null || true
    fi
  fi
  echo "[worktree] removed $TARGET (branch $BRANCH)"
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
