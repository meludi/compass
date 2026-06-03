# compass — workflow guidance

This project runs the **compass** workflow (a PIV loop: Plan → Implement → Validate, with parallel review and worktree isolation). The engine and docs live under `.claude/compass/`; this file is starter-owned and is replaced on update — **do not add project-specific notes here** (put those in `CLAUDE.md`).

`CLAUDE.md` imports this file via `@compass/AGENTS.md`, so this guidance loads at session start alongside your project conventions.

## On-Demand Context — framework docs

Load these only when relevant — not every session.

| Topic                | File                                                          |
| -------------------- | ------------------------------------------------------------ |
| Workflow concepts    | `.claude/compass/reference/CONCEPTS.md`                      |
| Command flow         | `.claude/compass/reference/WORKFLOW.md`                      |
| Reference / handbook | `.claude/compass/reference/HANDBOOK.md`                      |
| Test quality         | `.claude/compass/reference/HANDBOOK.md` → Test quality       |
| Refactor candidates  | `.claude/compass/reference/HANDBOOK.md` → Refactor candidates |
| Worktrees            | `.claude/compass/reference/WORKTREES.md`                     |
| CI & autonomy        | `.claude/compass/reference/AUTONOMY.md`                      |

Project-specific docs are indexed separately in `CLAUDE.md` (the "Project Context" table) — that table is yours to grow; this one is maintained by the starter.
