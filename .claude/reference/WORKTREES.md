# Worktrees

A worktree is a **feature branch with its own directory**. Not a clone, not a copy — Git shares the full history, but each worktree has an independent file checkout.

Used by `/worktree` — see `HANDBOOK.md` for the command reference.

---

## Mental Model

Think of it as: one Git repository, multiple working directories, each on its own branch.

```
claude-workflow-starter/          → main branch
claude-workflow-starter-mil-6-…/  → feat/mil-6-… branch
claude-workflow-starter-mil-7-…/  → feat/mil-7-… branch
```

All three share the same `.git` folder under the hood.

---

## What Each Worktree Has

| | Main | Worktree |
|---|---|---|
| Directory | `claude-workflow-starter/` | `claude-workflow-starter-<name>/` |
| Branch | `main` | `feat/<name>` |
| Files | independent | independent |
| `node_modules` | own copy | own copy (installed by `worktree.sh`) |
| Dev port | `dev_port` (e.g. 3000) | `dev_port + N` (e.g. 3001, 3002 — see `.worktree-port`) |
| Git history | shared | shared |
| Claude session | own | own (resume with `/resume`) |

---

## Isolation scope

Worktree isolation is **not automatic for every stack**. What you get out of the box and what you wire up:

| Concern | Isolated how | Universal? |
|---|---|---|
| Directory + branch | `git worktree` | ✅ any stack |
| Dev port | `dev_port + N` in `.worktree-port`, used via `PORT=$(cat .worktree-port) <dev_cmd>` | ✅ any stack that reads `PORT` |
| Dependencies | `package_manager` (JS) **or** `install_cmd` (any stack, e.g. `uv sync`) | ✅ with `install_cmd` |
| File DB (SQLite) | `db_file` copied per worktree | ✅ for a single file DB |
| Server DB (Postgres/MySQL/…) | **not automatic** — use `worktree_setup_cmd` / `worktree_teardown_cmd` | ⚙️ you write the hook |
| Env / connection string | `.env.local` is **symlinked (shared)** — per-worktree values come from the setup hook | ⚙️ you write the hook |

So a fully autonomous dev server per worktree is automatic only for **JS + a file DB**. For a server DB or a non-JS stack you supply the missing pieces via hooks.

### Hooks

`worktree_setup_cmd` runs after install (in the new worktree); `worktree_teardown_cmd` runs before removal. Both get `WT_NAME`, `WT_DIR`, `WT_BRANCH`, `WT_PORT` exported. Example (Postgres, in `.claude/project.yml`):

```yaml
install_cmd: "uv sync"
worktree_setup_cmd: createdb "myapp_$WT_NAME" && echo "DATABASE_URL=postgres:///myapp_$WT_NAME" > .env.worktree
worktree_teardown_cmd: dropdb --if-exists "myapp_$WT_NAME"
```

Your app must load `.env.worktree` (or whatever file the hook writes) — the starter does not inject it. For anything non-trivial, point a hook at a script file.

> **Security:** hooks run arbitrary shell from `project.yml` at the same trust level as `dev_cmd` — only run worktrees from configs you trust.

### Recipes

Copy-paste `project.yml` fragments. Each assumes the relevant client (`mongosh`, `createdb`/`dropdb`, `docker`) is installed locally and that **`.env.worktree` is gitignored**. The dev command sources `.env.worktree` because `.env.local` is shared.

**Payload CMS + MongoDB** — Mongo creates a db on first write, so just point at a unique name:

```yaml
package_manager: pnpm
worktree_setup_cmd: echo "DATABASE_URI=mongodb://127.0.0.1:27017/payload_$WT_NAME" > .env.worktree
worktree_teardown_cmd: mongosh "mongodb://127.0.0.1:27017/payload_$WT_NAME" --quiet --eval "db.dropDatabase()"
dev_cmd: bash -lc 'set -a; [ -f .env.worktree ] && . ./.env.worktree; set +a; PORT=$(cat .worktree-port) pnpm dev'
```

**Python (FastAPI / Django) + Postgres**:

```yaml
install_cmd: uv sync
worktree_setup_cmd: createdb "myapp_$WT_NAME" && echo "DATABASE_URL=postgresql:///myapp_$WT_NAME" > .env.worktree
worktree_teardown_cmd: dropdb --if-exists "myapp_$WT_NAME"
dev_cmd: bash -lc 'set -a; [ -f .env.worktree ] && . ./.env.worktree; set +a; uv run uvicorn app:app --port $(cat .worktree-port)'
```

Run migrations as part of setup if needed — append e.g. `&& uv run alembic upgrade head` (after the env is written) to `worktree_setup_cmd`.

**Any stack via Docker Compose** — isolate by compose project name:

```yaml
worktree_setup_cmd: COMPOSE_PROJECT_NAME=myapp_$WT_NAME docker compose up -d
worktree_teardown_cmd: COMPOSE_PROJECT_NAME=myapp_$WT_NAME docker compose down -v
```

Containers and volumes are per-worktree, but **host ports still collide** — shift them via `.env.worktree` (e.g. write `DB_PORT=...` keyed off `WT_PORT`) and reference those vars in `compose.yml`.

**Non-JS, install only** (Go — no DB):

```yaml
install_cmd: go mod download
dev_cmd: bash -lc 'PORT=$(cat .worktree-port) go run ./cmd/server'
```

---

## Lifecycle

```
/worktree <name>          → creates directory + branch + installs deps
  └─ open claude session  → run /plan-feature to load context and plan, then implement
  └─ commit changes       → commits go to feat/<name> only
  └─ merge into main      → git merge or PR
  └─ worktree.sh <name> rm → guarded removal: dir + branch + prune (refuses on uncommitted/unmerged work; --force overrides)
```

---

## Rules

- **Changes in a worktree only affect its branch** — main is never touched
- **Each worktree runs its own dev server** on its own port — see *Dev Server per Worktree* below
- **Same branch cannot be checked out in two worktrees simultaneously**
- **`node_modules` is duplicated per worktree** — 3 worktrees = 3× disk usage
- **Always clean up** with `worktree.sh <name> rm` after merging — stale worktree metadata breaks Git GUIs (e.g. Fork)

---

## Dev Server per Worktree

Each worktree gets a unique port assigned automatically when created (`dev_port + N` from `.claude/project.yml`). The assigned port is saved to `.worktree-port` and printed by `worktree.sh`.

```
main project   → port 3000  (dev_port)
first worktree → port 3001  (dev_port + 1)
second worktree→ port 3002  (dev_port + 2)
```

Start the dev server from inside the worktree:

```bash
PORT=$(cat .worktree-port) npm run dev    # or whatever dev_cmd is in project.yml
```

All three dev servers run simultaneously without conflicts.

---

## Working with Multiple Worktrees in VS Code

- **Separate windows (recommended):** `code /path/to/<repo>-<name>` per worktree — each gets its own Git panel, terminal, and Claude session. Open the plan with `code .work/plans/<name>.plan.md`.
- **Multi-root workspace:** one `*.code-workspace` file listing `.` plus each `../<repo>-<name>` folder; open it in a single window.
- **One window, many terminals:** `cd ../<repo>-<name> && claude .` per terminal — the Explorer stays on main, each session works on its own branch.

---

## Resuming a Claude Session

Claude saves conversation history per directory. To resume a previous session:

```bash
cd /path/to/worktree && claude .
# then: /resume
```

---

## Commands

| Command | What it does |
|---|---|
| `bash .claude/scripts/worktree.sh <name> open` | Create worktree, install deps, open Claude |
| `bash .claude/scripts/worktree.sh <name> rm` | Guarded removal: dir + branch + prune. Refuses on uncommitted/unmerged work — add `-f`/`--force` to override |
| `git worktree list` | List all active worktrees |
| `git worktree prune` | Clean up stale metadata (fixes Git GUI errors) |
