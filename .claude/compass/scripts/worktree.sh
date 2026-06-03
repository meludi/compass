#!/usr/bin/env bash
# worktree.sh <name> [open|rm] — full worktree lifecycle.
#
#   worktree.sh feature-name          -> create worktree on feat/feature-name
#   worktree.sh feature-name open     -> create + launch claude inside it
#   worktree.sh feature-name rm       -> remove worktree dir + git branch (guarded:
#                                        refuses on uncommitted or unmerged work)
#   worktree.sh feature-name rm -f    -> force removal (skips the guards)
#
# Reads from .claude/compass.yml:
#   package_manager        — npm | pnpm | yarn | bun (used when install_cmd is blank)
#   install_cmd            — custom install command for any stack; overrides package_manager
#   db_file                — optional file DB to copy per worktree (e.g. myapp.db, SQLite)
#   worktree_setup_cmd     — hook run in the new worktree after install (e.g. createdb myapp_$WT_NAME)
#   worktree_teardown_cmd  — hook run before removal (e.g. dropdb myapp_$WT_NAME)
#   dev_port               — base dev server port (default 3000); worktrees get dev_port + N
#   dev_cmd                — dev server start command (default: npm run dev)
#
# Hooks run with CWD = the worktree dir and these vars exported:
#   WT_NAME  WT_DIR  WT_BRANCH  WT_PORT
# For anything non-trivial, point a hook at a script file (avoids YAML quoting pitfalls).
#
# Isolation scope: dir + branch + port are universal. Dependency install needs
# package_manager or install_cmd. State isolation: db_file copy handles a single
# file DB (SQLite); server DBs (Postgres/MySQL/…) need worktree_setup_cmd/teardown_cmd.
#   - .env.local is symlinked from main (shared config) — per-worktree env must be
#     written by worktree_setup_cmd into a file your stack loads.
#   - No manual file copying across worktrees — all changes via git commit on feature branch.

set -euo pipefail

NAME="${1:?usage: worktree.sh <name> [open|rm]}"
ACTION="${2:-create}"
ROOT="$(git rev-parse --show-toplevel)"
PARENT="$(dirname "$ROOT")"
TARGET="$PARENT/$(basename "$ROOT")-$NAME"
BRANCH="feat/$NAME"

# Read from .claude/compass.yml via the shared reader (scripts/read-config.sh) so
# the parsing rules live in one place (also used by CI). read_config strips a
# trailing " # comment", trims whitespace, and removes one surrounding quote pair —
# internal quotes are preserved so command values (install_cmd, hooks) survive intact.
export PROJECT_YML="$ROOT/.claude/compass.yml"
# shellcheck source=read-config.sh
source "$ROOT/.claude/compass/scripts/read-config.sh"
PM=$(read_config package_manager)
INSTALL_CMD=$(read_config install_cmd)
DB=$(read_config db_file)
WT_SETUP_CMD=$(read_config worktree_setup_cmd)
WT_TEARDOWN_CMD=$(read_config worktree_teardown_cmd)
DEV_PORT=$(read_config dev_port)
DEV_CMD=$(read_config dev_cmd)
BASE=$(read_config base_branch)
PM="${PM:-npm}"
DEV_PORT="${DEV_PORT:-3000}"
DEV_CMD="${DEV_CMD:-npm run dev}"
BASE="${BASE:-main}"

# Run a compass.yml hook (setup/teardown) with worktree env exported.
# Non-fatal: a failing hook warns but does not abort the script.
run_hook() {
  local cmd="$1" label="$2" rc=0
  [ -z "$cmd" ] && return 0
  echo "[worktree] $label hook: $cmd"
  ( cd "$TARGET" 2>/dev/null \
      && WT_NAME="$NAME" WT_DIR="$TARGET" WT_BRANCH="$BRANCH" \
         WT_PORT="$(cat "$TARGET/.worktree-port" 2>/dev/null || echo "")" \
         bash -c "$cmd" ) || rc=$?
  [ "$rc" -ne 0 ] && echo "[worktree] WARNING: $label hook exited $rc — continuing"
  return 0
}

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

  # Guards passed (or --force) → teardown hook, then remove
  run_hook "$WT_TEARDOWN_CMD" "teardown"
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

  # Install dependencies — custom install_cmd wins, else the package manager.
  if [ -n "$INSTALL_CMD" ]; then
    echo "[worktree] install: $INSTALL_CMD"
    ( cd "$TARGET" && bash -c "$INSTALL_CMD" )
  else
    case "$PM" in
      pnpm) pnpm --dir "$TARGET" install --frozen-lockfile --prefer-offline ;;
      yarn) yarn --cwd "$TARGET" install --frozen-lockfile ;;
      bun)  bun install --cwd "$TARGET" ;;
      *)    npm --prefix "$TARGET" ci ;;
    esac
  fi

  # Per-worktree setup hook (DB/schema/env) — runs after install.
  run_hook "$WT_SETUP_CMD" "setup"
fi

echo "[worktree] worktree: $TARGET  branch: $BRANCH"
if [ -f "$TARGET/.worktree-port" ]; then
  echo "[worktree] dev server:  PORT=$(cat "$TARGET/.worktree-port") $DEV_CMD"
fi
if [ "$ACTION" = "open" ]; then
  cd "$TARGET" && claude
fi
