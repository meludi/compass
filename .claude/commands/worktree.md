---
description: Create a new worktree + feature branch and open a fresh Claude session
argument-hint: <feature-name>
---

# /worktree — Create Worktree and Open Session

Creates a new Git worktree on `feat/<name>` and opens a fresh Claude Code session inside it.

**Input**: $ARGUMENTS (feature name, e.g. `add-search`)

## Steps

Read `worktree_prefix` from `project.yml`, then:

```bash
git worktree add {worktree_prefix}{name} -b feat/{name}
cd {worktree_prefix}{name}
# Install dependencies if needed
# Open new Claude Code session: claude .
```

Or if the project uses a worktree script:

```bash
bash scripts/w.sh $ARGUMENTS open
```

## Result

- Branch: `feat/<name>`
- Directory: `{worktree_prefix}<name>` (from `project.yml`)
- New Claude session opens inside the worktree

## After the session opens

Run `/prime` to load context, then start working.

## Notes

- Run from the **main project directory** — never from an existing worktree
- For parallel features: open a second terminal and run `/worktree <other-name>`
- Dev server always runs from the main directory — never from a worktree
- To remove a worktree when done: `git worktree remove {worktree_prefix}<name> && git branch -d feat/<name>`
