# Handbook

Reference companion to `WORKFLOW.md`. Everything that is not the day-to-day flow:
glossary, the `.work/` layout, parallel development, system evolution, models, the
full command table, and troubleshooting.

For the *why* behind the workflow's structure, see `CONCEPTS.md`.

---

## Glossary

- **IDEATE** — structured brain dump with the agent before writing any spec. Raw ideas, no structure yet.
- **STORY** — a scoped unit of work with acceptance criteria. Saved to `.work/stories/`; optionally synced to a tracker.
- **PIV** — Plan → Implement → Validate. The three phases of every development iteration.
- **PRD** — Product Requirements Document. A structured feature spec that gets broken into stories.

**The spec is either a story file or a tracker issue** — you don't write a new document per feature from scratch.

**A tracker is optional.** When configured (e.g. `LINEAR_API_KEY`), tracker issues are the spec. Without one, stories live in `.work/stories/` — same workflow, no external tool required. Plans live in `.work/plans/`, backlog in `.work/BACKLOG.md`. Describe the feature directly in `/plan-feature` instead of passing an issue ID.

---

## The `.work/` Directory

Your session-persistent workspace — local to your machine.

```
.work/
├── prds/          # /ideate              → committed
├── stories/       # /create-stories      → committed
├── plans/         # /plan-feature        → committed
├── reports/       # /implement               → gitignored
├── screenshots/   # agent-browser        → gitignored
└── BACKLOG.md     # optional, no tracker → committed
```

Plans, PRDs, stories, and BACKLOG are committed — they are your project's spec artifacts. Reports and screenshots are generated output — gitignored.

---

## Parallel Development

> Bolting AI on = 2x. Building for parallelism = 10x.

Same human, same hours — multiple stories shipping simultaneously. Each story runs in its own worktree, branch, and Claude session.

```
# Main directory — dev server only
{dev_cmd from `.claude/project.yml`}

# Terminal 1 — Story A
/worktree feature-a
# Session A: /plan-feature → /implement → /ship

# Terminal 2 — Story B
/worktree feature-b
# Session B: /plan-feature → /implement → /ship
```

The 10x reframe, the 5 pillars, and the 5 blockers this enables are explained in `CONCEPTS.md`.

---

## System Evolution

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
4. Commit: `docs: tighten plan-feature — require Mirror pattern reference per task`

**Bug slipped through:**
1. Fix the bug
2. Ask: what system property allowed this? Missing type, no validation, wrong assumption?
3. Add a rule to `CLAUDE.md` under the relevant section
4. Add a test that would have caught it

**Context was missing:**
1. Write the missing context as a doc in `.claude/reference/`
2. Add it to the On-Demand Context table in `CLAUDE.md`
3. `/plan-feature` loads the table — the agent picks it up next session

**`CLAUDE.md` is a living document** — update it after significant features as the project evolves.

The `/reflect` command guides you through all of the above.

---

## Models

| | Opus 4.7 | Sonnet 4.6 | Haiku 4.5 |
|---|---|---|---|
| **Best for** | Complex reasoning, architecture, deep analysis | Balanced quality + speed | Fast, lightweight tasks |
| **In this workflow** | `/ideate`, `/plan-feature`, `/ship`, `/security-review` | `/setup`, `/setup-stack`, `/implement`, `/validate`, `/create-stories`, `/reflect` | `/commit`, `/worktree` |
| **Latency** | Moderate | Fast | Fastest |
| **Context window** | 1M tokens | 1M tokens | 200k tokens |
| **Max output** | 128k tokens | 64k tokens | 64k tokens |
| **Input price** | $5 / MTok | $3 / MTok | $1 / MTok |
| **Output price** | $25 / MTok | $15 / MTok | $5 / MTok |

Switch model with `/model opus`, `/model sonnet`, or `/model haiku`.

---

## Command Reference

| Command            | Argument                                      | Level      | When to use                                                       | Model   | Plan Mode | Trigger |
| ------------------ | --------------------------------------------- | ---------- | ----------------------------------------------------------------- | ------- | --------- | ------- |
| `/setup`           | —                                             | Once       | Configure project — generates `project.yml` + `CLAUDE.md`         | Sonnet  | —         | User |
| `/ideate`          | `<initiative name>`                           | Initiative | Brain dump → approaches → PRD → self-review (full flow)           | Opus    | **Yes**   | User |
| `/setup-stack`     | `[path to .work/prds/*.prd.md]`               | Once       | Scaffold stack, record style, create seed files (greenfield only) | Sonnet  | —         | User |
| `/setup-tracker`   | —                                             | Once       | Switch issue tracker (Linear / Jira / Azure DevOps)               | Sonnet  | —         | User |
| `/create-stories`  | `[path to .work/prds/*.prd.md]`               | Initiative | Break PRD into stories (`.work/stories/` + optionally a tracker)  | Sonnet  | —         | User |
| `/worktree`        | `<feature-name>`                              | PIV        | Create worktree + branch + open new Claude session                | Haiku   | —         | User |
| `/plan-feature`    | `<path to .work/stories/*.md \| issue-id \| feature description>` | PIV | Load context, then design the changes — plan only                | Opus    | **Yes**   | User |
| `/implement`           | `<path to .work/plans/*.plan.md>`             | PIV        | Execute plan step by step, then full validation                  | Sonnet  | —         | User |
| `/validate`        | —                                             | PIV        | Run all checks — lint, types, tests, browser smoke test           | Sonnet  | —         | User |
| `/commit`          | —                                             | PIV        | Stage and commit locally — no push, no PR                         | Haiku   | —         | Auto (via `/ship`) or User |
| `/ship`            | —                                             | PIV        | Commit + push + open PR, then optional parallel review            | Opus    | —         | User |
| `/security-review` | `[file-or-directory]`                         | PIV        | Security review of changed files                                 | Opus    | —         | Auto (via `/ship`) or User |
| `/reflect`         | —                                             | Anytime    | Capture learnings, evolve system — after merge, bug, or session   | Sonnet  | —         | User |
| `agent-browser`    | `<subcommand>` (CLI tool, not slash command)  | PIV        | Browser smoke test — part of `/validate` and `/implement`             | —       | —         | Auto or User |

---

## Troubleshooting

| Problem                            | Fix                                                                                   |
| ---------------------------------- | ------------------------------------------------------------------------------------- |
| Dev server error in worktree       | You started `dev_cmd` (from `.claude/project.yml`) from the worktree. Run it from the main project dir instead. |
| DB state missing in worktree       | `/worktree` copies DB at creation time. If main DB has new data, copy again manually.  |
| Type errors after implement        | Run `type_check_cmd` (from `.claude/project.yml`) and fix before committing.           |
| Tracker issue not created          | Check the API key in `.claude/settings.local.json` and `enabledMcpjsonServers`.        |
| Fork won't push `base_branch`      | Use `git push origin <base_branch>` from the terminal instead.                         |
| Claude session feels slow/confused | Start a fresh session and run `/plan-feature` to reload context.                       |
