---
description: Create a new worktree + feature branch and open a fresh Claude session
argument-hint: <feature-name>
---

# /worktree — Create Worktree and Open Session

> **Empfohlen:** `/model haiku` — spart Tokens, dieser Command führt nur Shell-Operationen aus.

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

Run `/prime` to load context, then start working.

## Notes

- Run from the **main project directory** — never from an existing worktree
- For parallel features: open a second terminal and run `/worktree <other-name>`
- Dev server always runs from the main directory — never from a worktree
- To remove a worktree when done: `bash .claude/scripts/worktree.sh <name> rm`
