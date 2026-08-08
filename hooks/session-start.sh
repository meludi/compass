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
(Plan -> Implement -> Validate -> Ship) with per-task validation gates and
worktree isolation. Plugin commands are namespaced \`/compass:<name>\`:

  worktree -> plan-feature -> implement -> /code-review -> ship
  (+ validate, commit, fix-ci-review)

Unsure which command fits a situation? \`/compass:help\` routes it — including
the cases whose answer is a Claude Code built-in, a skill, or no command at all.

compass covers the execution loop only. \`/code-review\` in that chain is Claude
Code's own, not a compass command — run it on the branch before shipping, where a
finding costs one edit instead of a review round. On the PR, review comes from
\`anthropics/claude-code-action\`. Do not look for a compass review command.

## Framework docs — load on demand (not every session)

| Topic                  | File                                    |
| ---------------------- | --------------------------------------- |
| The two loops          | $REF/WORKFLOW.md                        |
| Commands in detail     | $REF/COMMANDS.md                        |
| Proving "done", config | $REF/HANDBOOK.md                        |

## Project-side files

- \`$PROJECT/.claude/CLAUDE.md\` — project facts, review conventions, the
  project-context table, and the \`## Commands\` table. **That table is compass'
  configuration**: gate commands plus test policy, dev port and base branch.
  There is no compass config file.

If \`.claude/CLAUDE.md\` is missing, run \`/compass:setup\` to scaffold it.
Read the framework docs above only when a task actually needs them.
ORIENTATION
