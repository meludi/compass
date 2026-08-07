#!/usr/bin/env bash
# worktree.sh <name> [open|rm] — full worktree lifecycle.
#
#   worktree.sh feature-name          -> create worktree on feat/feature-name
#   worktree.sh feature-name open     -> create + launch claude inside it
#   worktree.sh feature-name rm       -> remove worktree dir + git branch (guarded:
#                                        refuses on uncommitted or unmerged work)
#   worktree.sh feature-name rm -f    -> force removal (skips the guards)
#
# Reads no configuration. Everything is derived from the repo:
#   base branch      — origin's HEAD, else the current branch
#   package manager  — the lockfile present (pnpm/yarn/bun/npm); skipped if none
#   port             — first free port from 3000 up, written to .worktree-port
#
# Project-owned isolation hooks (optional, both skipped when absent):
#   .claude/worktree-setup.sh     — run in the new worktree after install
#   .claude/worktree-teardown.sh  — run before removal
# Both run with CWD = the worktree dir and these vars exported:
#   WT_NAME  WT_DIR  WT_BRANCH  WT_PORT
# Use them for anything stateful: create/drop a database, seed a schema, write a
# per-worktree .env. compass does not know what your project needs — the hook does.
#
# Isolation scope: dir + branch + port are universal and handled here. State
# isolation is the hooks' job.
#   - .env.local and .claude/settings.local.json are symlinked from main (shared
#     config) — per-worktree env must be written by the setup hook.
#   - No manual file copying across worktrees — all changes via git commit on the
#     feature branch.

set -euo pipefail

NAME="${1:?usage: worktree.sh <name> [open|rm]}"
ACTION="${2:-create}"
ROOT="$(git rev-parse --show-toplevel)"
PARENT="$(dirname "$ROOT")"
TARGET="$PARENT/$(basename "$ROOT")-$NAME"
BRANCH="feat/$NAME"

# Base branch: whatever origin points HEAD at, else the branch we're standing on.
# Both lookups must tolerate failure (no origin, detached HEAD) — under `set -e`
# with pipefail a bare command substitution would abort the script.
BASE="$(git -C "$ROOT" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
[ -z "$BASE" ] && BASE="$(git -C "$ROOT" symbolic-ref --short HEAD 2>/dev/null || true)"
[ -z "$BASE" ] && BASE="main"

# Run a project isolation hook if the project ships one. Non-fatal: a failing
# hook warns but does not abort — losing a worktree to a bad hook is worse than
# an unseeded database.
run_hook() {
  local script="$ROOT/.claude/worktree-$1.sh" rc=0
  [ -f "$script" ] || return 0
  echo "[worktree] $1 hook: .claude/worktree-$1.sh"
  ( cd "$TARGET" 2>/dev/null \
      && WT_NAME="$NAME" WT_DIR="$TARGET" WT_BRANCH="$BRANCH" \
         WT_PORT="$(cat "$TARGET/.worktree-port" 2>/dev/null || echo "")" \
         bash "$script" ) || rc=$?
  [ "$rc" -ne 0 ] && echo "[worktree] WARNING: $1 hook exited $rc — continuing"
  return 0
}

# First free TCP port from $1 upward. Falls back to the start port after 100
# tries so a locked-down box still gets a worktree.
free_port() {
  local p="$1" limit=$(( $1 + 100 ))
  while [ "$p" -lt "$limit" ]; do
    if ! (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then echo "$p"; return; fi
    exec 3>&- 2>/dev/null || true
    p=$((p + 1))
  done
  echo "$1"
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
  run_hook teardown
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
  git -C "$ROOT" worktree add "$TARGET" -b "$BRANCH"

  # .env.local + settings.local.json: symlink from main (config, not state)
  if [ -f "$ROOT/.env.local" ]; then
    ln -sf "$ROOT/.env.local" "$TARGET/.env.local"
  fi
  if [ -f "$ROOT/.claude/settings.local.json" ]; then
    mkdir -p "$TARGET/.claude"
    ln -sf "$ROOT/.claude/settings.local.json" "$TARGET/.claude/settings.local.json"
  fi

  free_port 3000 > "$TARGET/.worktree-port"

  # Install dependencies — the lockfile decides. No lockfile, no install: a
  # non-JS project brings its own setup hook.
  if   [ -f "$TARGET/pnpm-lock.yaml" ]; then pnpm --dir "$TARGET" install --frozen-lockfile --prefer-offline
  elif [ -f "$TARGET/yarn.lock" ];      then yarn --cwd "$TARGET" install --frozen-lockfile
  elif [ -f "$TARGET/bun.lockb" ];      then bun install --cwd "$TARGET"
  elif [ -f "$TARGET/package-lock.json" ]; then npm --prefix "$TARGET" ci
  else echo "[worktree] no lockfile — skipping install (use .claude/worktree-setup.sh if your stack needs one)"
  fi

  # Per-worktree setup hook (DB/schema/env) — runs after install.
  run_hook setup
fi

echo "[worktree] worktree: $TARGET  branch: $BRANCH  base: $BASE"
echo "[worktree] open in editor: code $TARGET"
if [ -f "$TARGET/.worktree-port" ]; then
  echo "[worktree] free port reserved: $(cat "$TARGET/.worktree-port") (start your dev server with PORT=\$(cat .worktree-port))"
fi
if [ "$ACTION" = "open" ]; then
  cd "$TARGET" && claude 2>/dev/null || \
    echo "[worktree] Note: open a new terminal, cd $TARGET, and run 'claude' to start a session."
fi
