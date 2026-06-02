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
