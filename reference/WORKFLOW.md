# AI Coding Workflow

This document maps four methodology frameworks (AI Coding Logical Flow, Four Golden Rules, Greenfield Project Planning, 10x AI Coding Playbook) onto the day-to-day development workflow.

---

## The Big Picture

The workflow has two clearly separated levels:

```
LEVEL 1 — Initiative Setup (done once per initiative)
  IDEATE → TICKET → Issues in Linear

LEVEL 2 — PIV Loop (run for every ticket)
  PLAN → IMPLEMENT → VALIDATE → MERGE
```

**The spec is either a Linear issue or a `.work/` artifact** — you don't write a new document per feature from scratch.

**Linear is optional.** When configured (`LINEAR_API_KEY`), Linear issues are the spec — pick a ticket and run the PIV loop. When not configured, use `.work/` instead: PRDs in `.work/prds/`, plans in `.work/plans/`, backlog in `.work/BACKLOG.md`. Run `/prime` without an issue ID and describe the feature directly in `/feature-plan`.

---

## Level 1: Initiative Setup (once per initiative)

This is the IDEATE → TICKET phase from the AI Coding Logical Flow. Done once when starting a new initiative or major feature set — not repeated for every small feature.

### Step 1 — IDEATE

Brain dump with the agent. Raw ideas, context, goals. No structure yet.

1. **Describe what you want to build** — talk freely, no structure required. Share the problem, the goal, constraints, examples. The more context the better.

2. **Delegate research to Claude Code agents** — if the initiative requires web research, reading library docs, or comparing approaches, ask Claude Code to spawn an agent for it (e.g. _"Search for how other projects handle dividend tracking"_). Claude Code runs this in an isolated agent with its own context — web search, WebFetch, etc. Only the summary returns to your main conversation, keeping it clean and focused.

3. **AI summarizes and asks clarifying questions** — after the brain dump, ask the agent to summarize its understanding and surface open questions. This surfaces misalignments before any structure is created. Example prompt: _"Summarize what you understood and ask me anything that's still unclear."_

4. **Align** — answer the questions, correct misunderstandings. Repeat until both you and the agent are on the same page.

**Result:** Shared understanding of the initiative — ready to write the PRD.

### Step 2 — Write a PRD — `/create-prd`

The PRD becomes the source of truth for every AI conversation in this initiative. It is broken into stories — not recreated per feature.

```
/create-prd "Dividend tracking feature set"
→ saves to .work/prds/dividend-tracking.prd.md
```

### Step 3 — Create Linear issues — `/create-stories`

Break the PRD into individual, actionable stories with acceptance criteria. Each story becomes a Linear issue.

```
# Directly after /create-prd — PRD still in context:
/create-stories

# Or later, from file:
/create-stories .work/prds/dividend-tracking.prd.md

→ creates multiple issues in Linear (via MCP)
→ saves to .work/stories/
```

Each issue is now the spec for one PIV Loop iteration.

---

## Level 2: PIV Loop (per ticket)

Run this for every ticket. One worktree session per ticket — plan, build, and validate all happen inside it. This is the core of the 10x Playbook: **Plan / Build / Validate**.

### Step 1 — Pick a ticket

Open Linear, pick an issue. The issue description is your spec — no additional document needed.

> **Linear is optional.** If Linear is not configured (no `LINEAR_API_KEY`), run `/prime` without an issue ID — it skips the Linear step and loads git state + project rules only. Describe the feature directly in `/feature-plan` instead.

### Step 2 — Create a worktree (new session)

Each ticket gets its own branch, directory, and Claude session.

```
/worktree <issue-name>
# creates {worktree_prefix from project.yml}/<issue-name> on feat/<issue-name>
# opens a fresh Claude Code session inside it
```

> Steps 3–7 run inside this new session.

### Step 3 — PLAN — `/prime` + `/feature-plan`

In the new session — context is clean, focus is sharp (Four Golden Rules: Context Reset).

```
/prime
```

Loads mental model: Linear issue (if provided), latest plan from `.work/plans/`, last commits, git state.

```
/feature-plan "Add dividend display per position"
→ saves to .work/plans/dividend-display.plan.md
```

> If `/prime` loaded a Linear issue or story file, `/feature-plan` picks it up from context — no argument needed.

The plan uses the Linear issue, story file, or feature description as input. It includes: files to create/update, task list with Mirror patterns, validation steps.

### Step 4 — IMPLEMENT — `/feature-build`

```
/feature-build .work/plans/dividend-display.plan.md
```

For each task: reads target + adjacent files first (Verify Assumptions), implements following the Mirror pattern, then runs `type_check_cmd` (from project.yml) — PASS to proceed, FAIL to fix immediately. After all tasks pass:

**AI Validation (automated):**

- `test_cmd` (from project.yml) — unit + integration tests
- `agent-browser` — automated E2E: navigate, interact, screenshot to `.work/screenshots/`

Both must pass before writing the report.

### Step 4.5 — VALIDATE — `/validate`

Before opening a PR, run all checks:

```
/validate
```

Runs lint, TypeScript check, and tests. All must pass before proceeding.

### Step 5 — COMMIT + PR — `/create-pr`

```
/create-pr
```

Reads the implementation report, shows `git status` + `git diff --staged`, proposes a commit message, waits for confirmation, then commits, pushes, and opens a PR via `gh pr create --base base_branch (from project.yml)` with a structured body (Summary, Changes, Manual Test Plan). Outputs the PR URL.

### Step 6 — REVIEW — `/review` + manual testing

With the PR open, validation splits into two tracks:

**Human validation:**

- Code review — read the diff, check logic and patterns
- Manual tests — run the app, test the feature in the browser yourself

**AI validation (`/review`):**

```
/review 42
```

Runs 3 subagents in parallel, then auto-triggers `/security-review` if the diff touches API routes, DB queries, forms, or user input:

- `code-reviewer` — compliance, security, performance
- `pr-test-analyzer` — missing tests
- `codebase-explorer` — pattern consistency

Dev server must be running from the main project directory (`dev_cmd` (from project.yml)).

### Step 7 — Merge + cleanup

After review passes: merge PR into `base_branch (from project.yml)`, then remove the worktree (shell command — no slash command for this):

```bash
bash scripts/w.sh <issue-name> rm
```

---

## Parallel Development (10x pattern)

Same human, same hours — multiple tickets shipping simultaneously.

```
# Main directory — dev server only
{dev_cmd from project.yml}

# Terminal 1 — Ticket A
/worktree feature-a
# Session A: /prime → /feature-plan → /feature-build → /validate → /create-pr → /review

# Terminal 2 — Ticket B
/worktree feature-b
# Session B: /prime → /feature-plan → /feature-build → /validate → /create-pr → /review
```

Each worktree has its own branch, DB copy, and Claude session — no interference.

---

## System Evolution (ongoing)

Every bug or deviation is an opportunity to improve the system itself.

```
BUG → ? → + RULE
```

| When                     | What to fix                                        |
| ------------------------ | -------------------------------------------------- |
| Agent deviated from plan | Update the relevant command in `.claude/commands/` |
| Agent repeated a mistake | Add a rule to `CLAUDE.md`                          |
| Context was missing      | Add a new on-demand context doc to `reference/`    |

> Don't just fix the bug. Fix the system that allowed the bug.

---

## Command Reference

| Command            | Level      | When to use                                                     |
| ------------------ | ---------- | --------------------------------------------------------------- |
| `/worktree`        | PIV        | Create worktree + branch + open new Claude session              |
| `/prime`           | PIV        | Start of every session — loads mental model                     |
| `/create-prd`      | Initiative | Turning an initiative idea into a structured spec               |
| `/create-stories`  | Initiative | Breaking PRD into Linear issues                                 |
| `/feature-plan`    | PIV        | Before implementing — design the changes                        |
| `/feature-build`   | PIV        | Executing a plan step by step                                   |
| `/validate`        | PIV        | Run all checks — lint, types, tests                             |
| `/commit`          | PIV        | Stage and commit locally — no push, no PR                       |
| `/create-pr`       | PIV        | Commit + push + open PR in one step                             |
| `/review <PR>`     | PIV        | After PR is open — full parallel code review                    |
| `/security-review` | PIV        | Auto-triggered by `/review` — or run manually on specific files |
| `agent-browser`    | PIV        | Testing UI after implementation                                 |

---

## The Four Golden Rules (applied)

| Rule                       | How it applies                                                                                                                                                    |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Context Reset**          | Plan in one session, implement in a fresh worktree session                                                                                                        |
| **Command-ify Everything** | `/worktree`, `/prime`, `/feature-plan`, `/feature-build`, `/validate`, `/commit`, `/create-pr`, `/review`, `/security-review` — all repeated actions are commands |
| **Git Log as Memory**      | Conventional commits (`feat:`, `fix:`, `chore:`) give future sessions context                                                                                     |
| **System Evolution**       | Every bug → update CLAUDE.md or a command                                                                                                                         |

---

## Worktree Rules

- Dev server: **always** from the main project directory, never from a worktree
- DB: **copied** per worktree (not symlinked) — isolated state, no races
- `.env.local`: symlinked from main
- All commits: directly in the worktree on the feature branch
- Never copy files manually between directories

---

## Troubleshooting

| Problem                            | Fix                                                                                   |
| ---------------------------------- | ------------------------------------------------------------------------------------- |
| Dev server error in worktree       | You started `dev_cmd` (from project.yml) from the worktree. Run it from the main project dir instead. |
| DB state missing in worktree       | `/worktree` copies DB at creation time. If main DB has new data, copy again manually.  |
| Type errors after implement        | Run `type_check_cmd` (from project.yml) and fix before committing.                                    |
| Linear issue not created           | Check `LINEAR_API_KEY` in `.claude/settings.local.json` and `enabledMcpjsonServers`.  |
| Fork won't push `base_branch (from project.yml)`  | Use `git push origin base_branch (from project.yml)` from the terminal instead.                       |
| Claude session feels slow/confused | Start a fresh session and run `/prime` (Context Reset).                                |
