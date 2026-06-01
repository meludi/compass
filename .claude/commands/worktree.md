---
description: Create a new worktree + feature branch and open a fresh Claude session
argument-hint: <feature-name>
---

# /worktree — Create Worktree and Open Session

> **Recommended:** `/model haiku` — saves tokens, this command only runs shell operations.

Creates a new Git worktree on `feat/<name>` and opens a fresh Claude Code session inside it.

**Input**: $ARGUMENTS (feature name, e.g. `add-search`)

## Steps

Use the worktree script (handles install, `.env.local` symlink, and DB copy):

```bash
bash .claude/scripts/worktree.sh $ARGUMENTS open
```

Or manually:

```bash
git worktree add {worktree_prefix}{name} -b feat/{name}
cd {worktree_prefix}{name}
# Install dependencies, symlink .env.local, copy DB if needed
claude .
```

## Result

- Branch: `feat/<name>`
- Directory: `{worktree_prefix}<name>` (from `.claude/project.yml`)
- New Claude session opens inside the worktree

## After the session opens

Run `/plan-feature` — it loads project context (via `/context`) and creates the implementation plan. For orientation-only without writing a plan, call `/context` directly.

Start the dev server for this worktree (each gets its own port):

```bash
PORT=$(cat .worktree-port) {dev_cmd}
```

## Open in your editor

While Claude runs in the terminal, open the worktree in a separate VS Code window:

```bash
code ../<worktree-dir>              # from the main project directory
code .                              # if your terminal is already inside the worktree
```

After `/plan-feature` creates the plan, open it directly to review:

```bash
code .work/plans/<feature-name>.plan.md
```

## Notes

- Run from the **main project directory** — never from an existing worktree
- For parallel features: open a second terminal and run `/worktree <other-name>`
- Each worktree gets its own dev port printed after setup — start with `PORT=$(cat .worktree-port) {dev_cmd}`
- To remove a worktree when done: `bash .claude/scripts/worktree.sh <name> rm`
- See `.claude/reference/WORKTREES.md` for the mental model, lifecycle, and VS Code patterns.
