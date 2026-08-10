---
description: Create a worktree + feature branch, or remove one (guarded) with `rm`
argument-hint: <feature-name> [rm]
disable-model-invocation: true
---

# /compass:worktree — Create Worktree and Open Session

> **Model:** `/model haiku` — saves tokens, this command only runs shell operations.

Creates a new Git worktree on `feat/<name>` and opens a fresh Claude Code session inside it.

A worktree is a **feature branch with its own directory** — not a clone, not a copy. Git shares the full history; each worktree has an independent file checkout, so several features can be built at once without stashing or branch-switching. The dev server runs from the main dir only.

```
my-project/              → main branch
my-project-add-auth/     → feat/add-auth branch
my-project-fix-login/    → feat/fix-login branch
```

Worktrees are siblings of the project dir, never nested inside it — nesting confuses editors and Git alike.

**Input**: $ARGUMENTS (feature name, e.g. `add-search`)

## Steps

Parse `$ARGUMENTS`: if the last token is `rm`, this is a **removal** — see *Removing a worktree* below. Otherwise **create + open**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh <name> open
```

The script reads no configuration. It derives everything from the repo:

| What | Derived from |
|---|---|
| Base branch | `origin/HEAD`, else the current branch |
| Package manager | the lockfile present — no lockfile, no install |
| Dev port | first free port from 3000 up, written to `.worktree-port` |

It also symlinks `.env.local` and `.claude/settings.local.json` from the main dir — those are shared config, not per-worktree state.

## Result

- Branch: `feat/<name>`
- Directory: `../<project>-<name>`
- A reserved free port in `.worktree-port`
- New Claude session opens inside the worktree

## Per-worktree state — the setup hook

compass isolates directory, branch, and port. Anything stateful is the project's business, because compass cannot know whether you have a database, which one, or how it is seeded.

If these files exist, the script runs them:

| File | When |
|---|---|
| `.claude/worktree-setup.sh` | after install, in the new worktree |
| `.claude/worktree-teardown.sh` | before removal |

Both run with `WT_NAME`, `WT_DIR`, `WT_BRANCH`, `WT_PORT` exported. A failing hook warns but does not abort — losing a worktree to a bad hook is worse than an unseeded database.

> **Security:** the hooks are shell scripts in your repo and run at your trust level. Review them like any other code before running a worktree from a repo you did not write.

### Recipes

Each assumes the relevant client (`createdb`, `mongosh`, `docker`) is installed locally, and that **`.env.worktree` is gitignored**. Write env there rather than `.env.local` — that one is symlinked from main and therefore shared.

**Postgres** (Python, Rails, anything):

```bash
#!/usr/bin/env bash
# .claude/worktree-setup.sh
createdb "myapp_$WT_NAME"
echo "DATABASE_URL=postgresql:///myapp_$WT_NAME" > .env.worktree
uv run alembic upgrade head        # migrations, if you have them
```

```bash
#!/usr/bin/env bash
# .claude/worktree-teardown.sh
dropdb --if-exists "myapp_$WT_NAME"
```

**MongoDB / Payload CMS** — Mongo creates a database on first write, so a unique name is enough:

```bash
# setup
echo "DATABASE_URI=mongodb://127.0.0.1:27017/payload_$WT_NAME" > .env.worktree
# teardown
mongosh "mongodb://127.0.0.1:27017/payload_$WT_NAME" --quiet --eval "db.dropDatabase()"
```

**Docker Compose** — isolate by project name:

```bash
# setup
COMPOSE_PROJECT_NAME="myapp_$WT_NAME" docker compose up -d
# teardown
COMPOSE_PROJECT_NAME="myapp_$WT_NAME" docker compose down -v
```

Containers and volumes are then per-worktree, but **host ports still collide** — derive them from `$WT_PORT` in `.env.worktree` and reference those vars in `compose.yml`.

**File DB (SQLite)** — copy it from the main checkout:

```bash
# setup — $WT_DIR is this worktree, the main repo is its sibling
cp "$(git -C "$WT_DIR" rev-parse --git-common-dir)/../myapp.db" . 2>/dev/null || true
```

**Non-JS install** (Go, Python, Rust) — there is no lockfile the script recognises, so install here:

```bash
# setup
go mod download          # or: uv sync · cargo fetch
```

Start the dev server with the reserved port: `PORT=$(cat .worktree-port) go run ./cmd/server`. If your stack ignores `PORT`, write the value wherever it does read from.

## After the session opens

Run `/compass:plan-feature` — it loads project context and creates the implementation plan.

Start the dev server on this worktree's port:

```bash
PORT=$(cat .worktree-port) npm run dev     # or whatever your dev command is
```

If your stack does not read `PORT`, have the setup hook write the port where it belongs.

## Working in several worktrees

- **Separate editor windows (recommended)** — `code ../<repo>-<name>` per worktree. Each gets its own Git panel, terminal, and Claude session. Open the plan directly with `code .work/plans/<name>.plan.md`.
- **Multi-root workspace** — one `*.code-workspace` file listing `.` plus each `../<repo>-<name>` folder, opened in a single window.
- **One window, many terminals** — `cd ../<repo>-<name> && claude .` per terminal. The Explorer stays on main, each session works its own branch.

**Resuming a session:** Claude keeps history per directory, so `cd` into the worktree, run `claude`, then `/resume`.

## Removing a worktree

When the PR is merged, clean up from the **main project directory**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh <name> rm
```

Removal is **guarded** — it refuses and changes nothing if:

- you are standing inside the worktree being removed, or
- the worktree has **uncommitted changes**, or
- the branch has **commits not merged** into the base branch (the message notes whether they're pushed and recoverable, or local-only and about to be lost).

If a guard trips, surface the reason to the user and **ask before** re-running with `--force` — never force automatically:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh <name> rm --force
```

On success it runs the teardown hook, removes the directory, prunes worktree metadata, and deletes the branch (safe `git branch -d`; `-D` only under `--force`).

## Notes

- Run from the **main project directory** — never from an existing worktree
- For parallel features: open a second terminal and run `/compass:worktree <other-name>`
- No manual file copying between worktrees — move changes via commits on the feature branch
- `git worktree list` shows what exists; `git worktree prune` cleans stale metadata (fixes Git GUI errors after a manual delete)
