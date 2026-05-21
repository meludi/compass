# AI Coding Workflow

This document maps four methodology frameworks (AI Coding Logical Flow, Four Golden Rules, Greenfield Project Planning, 10x AI Coding Playbook) onto the day-to-day development workflow.

---

## The Big Picture

The workflow has two clearly separated levels:

```
LEVEL 1 — Initiative Setup (done once per initiative)
  /ideate (brain dump → spec → self-review) → /setup-stack (greenfield) → /create-stories → stories in .work/stories/ (+ Linear if configured)

LEVEL 2 — PIV Loop (run for every story)
  PLAN → IMPLEMENT → VALIDATE → MERGE
```

**Glossary:**
- **IDEATE** — structured brain dump with the agent before writing any spec. Raw ideas, no structure yet.
- **STORY** — a scoped unit of work with acceptance criteria. Saved to `.work/stories/`; optionally synced to Linear.
- **PIV** — Plan → Implement → Validate. The three phases of every development iteration.
- **PRD** — Product Requirements Document. A structured feature spec that gets broken into stories.

**The spec is either a story file or a Linear issue** — you don't write a new document per feature from scratch.

**Linear is optional.** When configured (`LINEAR_API_KEY`), Linear issues are the spec. Without Linear, stories live in `.work/stories/` — same workflow, no external tool required. Plans in `.work/plans/`, backlog in `.work/BACKLOG.md`. Run `/prime` without an issue ID and describe the feature directly in `/feature-plan`.

---

## The `.work/` Directory

Your session-persistent workspace — local to your machine.

```
.work/
├── prds/          # /create-prd         → versioniert
├── stories/       # /create-stories     → versioniert
├── plans/         # /feature-plan       → versioniert
├── reports/       # /feature-build      → gitignored
├── screenshots/   # agent-browser       → gitignored
└── BACKLOG.md     # optional, ohne Linear → versioniert
```

Plans, PRDs, stories, and BACKLOG are committed — they are your project's spec artifacts. Reports and screenshots are generated output — gitignored.

---

## Level 1: Initiative Setup (once per initiative)

This is the IDEATE → STORY phase from the AI Coding Logical Flow. Done once when starting a new initiative or major feature set — not repeated for every small feature.

### Step 1 — IDEATE

Brain dump with the agent. Raw ideas, context, goals. No structure yet.

1. **Describe what you want to build** — talk freely, no structure required. Share the problem, the goal, constraints, examples. The more context the better.

2. **Delegate research to Claude Code agents** — if the initiative requires web research, reading library docs, or comparing approaches, ask Claude Code to spawn an agent for it (e.g. _"Search for how other projects handle dividend tracking"_). Claude Code runs this in an isolated agent with its own context — web search, WebFetch, etc. Only the summary returns to your main conversation, keeping it clean and focused.

3. **AI summarizes and asks clarifying questions** — after the brain dump, ask the agent to summarize its understanding and surface open questions. This surfaces misalignments before any structure is created. Example prompt: _"Summarize what you understood and ask me anything that's still unclear."_

4. **Align** — answer the questions, correct misunderstandings. Repeat until both you and the agent are on the same page.

**Result:** Shared understanding of the initiative — ready to write the PRD.

### Step 2 — IDEATE + PRD — `/ideate`

Brain dump → scope check → research → approaches → incremental design approval → write PRD → self-review → handoff. The full obra-inspired flow in one session.

```
/ideate "Dividend tracking feature set"
→ saves to .work/prds/dividend-tracking.prd.md
```

For quick PRDs without the full ideation flow: `/create-prd` remains available.

### Step 3 — Scaffold the stack — `/setup-stack` _(greenfield only)_

Run once for new projects directly after the PRD is written — the PRD already contains the tech stack hints in `## Technical notes`. Scaffolds the framework, fills the CLAUDE.md Code Patterns section, and creates canonical seed files that `/feature-plan` can reference as Mirror sources.

```
/setup-stack .work/prds/dividend-tracking.prd.md
```

Skip for brownfield — the existing codebase already provides Mirror sources.

### Step 4 — Create stories — `/create-stories`

Break the PRD into individual, actionable stories with acceptance criteria.

```
# Directly after /create-prd (or /setup-stack) — PRD still in context:
/create-stories

# Or later, from file:
/create-stories .work/prds/dividend-tracking.prd.md

→ saves to .work/stories/
→ optionally creates Linear issues if LINEAR_API_KEY is configured
```

Each story is now the spec for one PIV Loop iteration.

---

## Level 2: PIV Loop (per story)

Run this for every story. One worktree session per story — plan, build, and validate all happen inside it. This is the core of the 10x Playbook: **Plan / Build / Validate** (PIV).

### Step 1 — Pick a story

Pick a story from `.work/stories/` — or from Linear if configured. The story description is your spec — no additional document needed.

> **Without Linear:** browse `.work/stories/`, pick a file, pass its path to `/prime`. Same flow, no external tool.

### Step 2 — Create a worktree (new session)

Each story gets its own branch, directory, and Claude session.

```
/worktree <story-name>
# creates {worktree_prefix from `.claude/project.yml`}/<story-name> on feat/<story-name>
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

For each task: reads target + adjacent files first (Verify Assumptions), implements following the Mirror pattern, then runs `type_check_cmd` (from `.claude/project.yml`) — PASS to proceed, FAIL to fix immediately. After all tasks pass:

**AI Validation (automated):**

- `test_cmd` (from `.claude/project.yml`) — unit + integration tests
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

Reads the implementation report, shows `git status` + `git diff --staged`, proposes a commit message, waits for confirmation, then commits, pushes, and opens a PR via `gh pr create --base base_branch (from `.claude/project.yml`)` with a structured body (Summary, Changes, Manual Test Plan). Outputs the PR URL.

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

Dev server must be running from the main project directory (`dev_cmd` (from `.claude/project.yml`)).

### Step 7 — Merge + cleanup

After review passes: merge PR into `base_branch (from `.claude/project.yml`)`, then remove the worktree:

```bash
bash .claude/scripts/worktree.sh <issue-name> rm
```

---

## Parallel Development (10x pattern)

> Bolting AI on = 2x. Building for parallelism = 10x.

Same human, same hours — multiple stories shipping simultaneously.

```
# Main directory — dev server only
{dev_cmd from `.claude/project.yml`}

# Terminal 1 — Story A
/worktree feature-a
# Session A: /prime → /feature-plan → /feature-build → /validate → /create-pr → /review

# Terminal 2 — Story B
/worktree feature-b
# Session B: /prime → /feature-plan → /feature-build → /validate → /create-pr → /review
```

### The 5 blockers — and how this starter handles them

| Blocker | Fix |
|---------|-----|
| Port `:3000` conflict | Dev server runs from main dir only — worktrees never start their own |
| `node_modules` × N | Each worktree installs its own (pnpm content store deduplicates on disk) |
| DB races | `worktree.sh` copies `db_file` per worktree — isolated state, no races |
| Token blowouts | Subagents for research; only summaries return to main context |
| PR pile-up | `/review` fans out 3 parallel subagents per PR |

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

### How to do it

**Agent deviated from a pattern:**
1. Identify exactly what it did vs. what was expected (file, line, action)
2. Open the relevant command in `.claude/commands/`
3. Add a concrete rule: "Always X. Never Y." with an example reference
4. Commit: `docs: tighten feature-plan — require Mirror pattern reference per task`

**Bug slipped through:**
1. Fix the bug
2. Ask: what system property allowed this? Missing type, no validation, wrong assumption?
3. Add a rule to `CLAUDE.md` under the relevant section
4. Add a test that would have caught it

**Context was missing:**
1. Write the missing context as a doc in `.claude/reference/`
2. Add it to the On-Demand Context table in `CLAUDE.md`
3. `/prime` loads the table — the agent picks it up next session

**`CLAUDE.md` is a living document** — update it after significant features as the project evolves.

---

## Models

| | Opus 4.7 | Sonnet 4.6 | Haiku 4.5 |
|---|---|---|---|
| **Best for** | Complex reasoning, architecture, deep analysis | Balanced quality + speed | Fast, lightweight tasks |
| **In this workflow** | `/ideate`, `/create-prd`, `/feature-plan`, `/review`, `/security-review` | `/setup`, `/setup-stack`, `/prime`, `/feature-build`, `/create-stories`, `/reflect` | `/validate`, `/commit`, `/create-pr`, `/worktree` |
| **Latency** | Moderate | Fast | Fastest |
| **Context window** | 1M tokens | 1M tokens | 200k tokens |
| **Max output** | 128k tokens | 64k tokens | 64k tokens |
| **Input price** | $5 / MTok | $3 / MTok | $1 / MTok |
| **Output price** | $25 / MTok | $15 / MTok | $5 / MTok |

Switch model with `/model opus`, `/model sonnet`, or `/model haiku`.

---

## Command Reference

| Command            | Argument                                      | Level      | When to use                                                     | Model   | Plan Mode | Trigger |
| ------------------ | --------------------------------------------- | ---------- | --------------------------------------------------------------- | ------- | --------- | ------- |
| `/setup`           | —                                             | Once       | Configure project — generates `project.yml` + `CLAUDE.md`      | Sonnet  | —         | User |
| `/ideate`          | `<initiative name>`                           | Initiative | Brain dump → approaches → PRD → self-review (full flow)         | Opus    | **Ja**    | User |
| `/create-prd`      | `<feature name>`                              | Initiative | Quick PRD without ideation flow (deprecated for new initiatives) | Opus   | **Ja**    | User |
| `/setup-stack`     | `[path to .work/prds/*.prd.md]`               | Once       | Scaffold stack, record style, create seed files (greenfield only) | Sonnet | —         | User |
| `/create-stories`  | `[path to .work/prds/*.prd.md]`               | Initiative | Break PRD into stories (`.work/stories/` + optionally Linear)   | Sonnet  | —         | User |
| `/prime`           | `[issue-id \| path to .work/stories/*.md]`    | PIV        | Start of every session — loads mental model                     | Sonnet  | —         | User |
| `/worktree`        | `<feature-name>`                              | PIV        | Create worktree + branch + open new Claude session              | Haiku   | —         | User |
| `/feature-plan`    | `"<feature description>"`                     | PIV        | Before implementing — design the changes                        | Opus    | **Ja**    | User |
| `/feature-build`   | `<path to .work/plans/*.plan.md>`             | PIV        | Execute plan step by step                                       | Sonnet  | —         | User |
| `/validate`        | —                                             | PIV        | Run all checks — lint, types, tests, browser smoke test         | Sonnet  | —         | User |
| `/commit`          | —                                             | PIV        | Stage and commit locally — no push, no PR                       | Haiku   | —         | User |
| `/create-pr`       | —                                             | PIV        | Commit + push + open PR in one step                             | Haiku   | —         | User |
| `/review`          | `<PR number>`                                 | PIV        | After PR is open — full parallel code review                    | Opus    | —         | User |
| `/security-review` | —                                             | PIV        | Security review of changed files                                | Opus    | —         | Auto (via `/review`) or User |
| `/reflect`         | —                                             | Anytime    | Capture learnings, evolve system — after merge, bug, or session | Sonnet  | —         | User |
| `agent-browser`    | —                                             | PIV        | Browser smoke test — UI verification before PR                  | —       | —         | Auto (via `/validate`) or User |

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
| Dev server error in worktree       | You started `dev_cmd` (from `.claude/project.yml`) from the worktree. Run it from the main project dir instead. |
| DB state missing in worktree       | `/worktree` copies DB at creation time. If main DB has new data, copy again manually.  |
| Type errors after implement        | Run `type_check_cmd` (from `.claude/project.yml`) and fix before committing.                                    |
| Linear issue not created           | Check `LINEAR_API_KEY` in `.claude/settings.local.json` and `enabledMcpjsonServers`.  |
| Fork won't push `base_branch (from `.claude/project.yml`)`  | Use `git push origin base_branch (from `.claude/project.yml`)` from the terminal instead.                       |
| Claude session feels slow/confused | Start a fresh session and run `/prime` (Context Reset).                                |
