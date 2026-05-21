# Worktrees

A worktree is a **feature branch with its own directory**. Not a clone, not a copy — Git shares the full history, but each worktree has an independent file checkout.

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
| Git history | shared | shared |
| Claude session | own | own (resume with `/resume`) |

---

## Lifecycle

```
/worktree <name>          → creates directory + branch + installs deps
  └─ open claude session  → run /prime to load context, then start working
  └─ commit changes       → commits go to feat/<name> only
  └─ merge into main      → git merge or PR
  └─ worktree.sh <name> rm → removes directory + branch + prunes git metadata
```

---

## Rules

- **Changes in a worktree only affect its branch** — main is never touched
- **Dev server runs from main only** — never start it from a worktree directory
- **Same branch cannot be checked out in two worktrees simultaneously**
- **`node_modules` is duplicated per worktree** — 3 worktrees = 3× disk usage
- **Always clean up** with `worktree.sh <name> rm` after merging — stale worktree metadata breaks Git GUIs (e.g. Fork)

---

## Working with Multiple Worktrees in VS Code

**Option A — Separate windows (recommended for parallel features):**
```bash
code /path/to/claude-workflow-starter-mil-6-…
code /path/to/claude-workflow-starter-mil-7-…
```
Each window has its own Git panel, terminal, and Claude session.

**Option B — Multi-root workspace (all in one window):**
Create a `stock-lookup.code-workspace` file:
```json
{
  "folders": [
    { "path": "." },
    { "path": "../claude-workflow-starter-mil-6-…" },
    { "path": "../claude-workflow-starter-mil-7-…" }
  ]
}
```
Open with `code stock-lookup.code-workspace`.

**Option C — One window, multiple terminals:**
Stay in the main window, open a terminal per worktree:
```bash
cd ../claude-workflow-starter-mil-6-… && claude .
```
The Explorer shows main, but each terminal and Claude session operates on its own branch.

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
| `bash .claude/scripts/worktree.sh <name> rm` | Remove worktree directory, delete branch, prune git metadata |
| `git worktree list` | List all active worktrees |
| `git worktree prune` | Clean up stale metadata (fixes Git GUI errors) |
