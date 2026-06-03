#!/usr/bin/env bash
# compass SessionStart hook — prints always-on workflow orientation.
# stdout is injected into Claude's context before the first prompt.
# ${CLAUDE_PLUGIN_ROOT} and ${CLAUDE_PROJECT_DIR} are exported into this process.
set -euo pipefail

ROOT="${CLAUDE_PLUGIN_ROOT:-}"
PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
REF="$ROOT/references"

cat <<ORIENTATION
# compass — workflow orientation

This Claude Code session has the **compass** plugin available: a PIV loop
(Plan -> Implement -> Validate) with parallel subagent review and worktree
isolation. Plugin commands and skills are namespaced \`/compass:<name>\`
(e.g. \`/compass:plan-feature\`, \`/compass:implement\`, \`/compass:ship\`).

## Framework docs — load on demand (not every session)

| Topic                | File                                      |
| -------------------- | ----------------------------------------- |
| Workflow concepts    | $REF/CONCEPTS.md                          |
| Command flow         | $REF/WORKFLOW.md                          |
| Reference / handbook | $REF/HANDBOOK.md                          |
| Worktrees            | $REF/WORKTREES.md                         |
| CI & autonomy        | $REF/AUTONOMY.md                          |

## Project-side files

- Config: \`$PROJECT/.claude/compass.yml\` (stack, package manager, tracker).
- Conventions: \`$PROJECT/.claude/CLAUDE.md\` (project facts + project-context table).

If \`.claude/compass.yml\` is missing, run \`/compass:setup\` to scaffold it.
Read the framework docs above only when a task actually needs them.
ORIENTATION
