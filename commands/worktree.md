---
description: Create a worktree + feature branch, or remove one (guarded) with `rm`
argument-hint: <feature-name> [rm]
---

# /compass:worktree — Create Worktree and Open Session

> **Model:** `/model haiku` — saves tokens, this command only runs shell operations.

Creates a new Git worktree on `feat/<name>` and opens a fresh Claude Code session inside it.

**Input**: $ARGUMENTS (feature name, e.g. `add-search`)

## Steps

Parse `$ARGUMENTS`: if the last token is `rm`, this is a **removal** — see *Removing a worktree* below. Otherwise **create + open**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh <name> open
```

The script handles branch, install, `.env.local` symlink, DB copy, and port assignment. Manual equivalent:

```bash
git worktree add {worktree_prefix}{name} -b feat/{name}
cd {worktree_prefix}{name}
# Install dependencies, symlink .env.local, copy DB if needed
claude .
```

## Result

- Branch: `feat/<name>`
- Directory: `{worktree_prefix}<name>` (from `.claude/compass.yml`)
- New Claude session opens inside the worktree

## After the session opens

Run `/compass:plan-feature` — it loads project context (via `/compass:context`) and creates the implementation plan. For orientation-only without writing a plan, call `/compass:context` directly.

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

After `/compass:plan-feature` creates the plan, open it directly to review:

```bash
code .work/plans/<feature-name>.plan.md
```

## Removing a worktree

When the PR is merged, clean up from the **main project directory**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh <name> rm
```

Removal is **guarded** — it refuses and changes nothing if:

- the worktree has **uncommitted changes**, or
- the branch has **commits not merged** into `base_branch` (the message notes whether they're pushed/recoverable or local-only).

If a guard trips, surface the reason to the user and **ask before** re-running with `--force` — never force automatically:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh <name> rm --force
```

On success it removes the directory, prunes worktree metadata, and deletes the branch (safe `git branch -d`; `-D` only under `--force`).

## Notes

- Run from the **main project directory** — never from an existing worktree
- For parallel features: open a second terminal and run `/compass:worktree <other-name>`
- Each worktree gets its own dev port printed after setup — start with `PORT=$(cat .worktree-port) {dev_cmd}`
- To remove a worktree when done: `/compass:worktree <name> rm` (guarded) — see *Removing a worktree* above
- See `${CLAUDE_PLUGIN_ROOT}/references/WORKTREES.md` for the mental model, lifecycle, and VS Code patterns.
