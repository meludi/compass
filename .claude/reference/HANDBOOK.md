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

Each story runs in its own worktree, branch, and Claude session, so several can ship simultaneously (the dev server runs from the main dir only). The 10x reframe, the 5 pillars, and the 5 blockers are explained in `CONCEPTS.md`; worktree mechanics in `WORKTREES.md`.

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

| | Opus 4.8 | Sonnet 4.6 | Haiku 4.5 |
|---|---|---|---|
| **Best for** | Complex reasoning, architecture, deep analysis | Balanced quality + speed | Fast, lightweight tasks |
| **In this workflow** | `/ideate`, `/plan-feature`, `/ship`, `/review`, `/security-review` | `/setup`, `/setup-stack`, `/implement`, `/auto-implement`, `/validate`, `/create-stories`, `/reflect` | `/commit`, `/worktree` |
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
| `/context`         | `[issue-id \| path to .work/stories/*.md \| feature description]` _(optional)_ | PIV | Refresh mental model — rules, git, spec, on-demand docs. Auto in plan/implement; standalone on resume or stale context | Sonnet  | —         | Auto (via `/plan-feature`, `/implement`) or User |
| `/plan-feature`    | `<path to .work/stories/*.md \| issue-id \| feature description>` | PIV | Load context, then design the changes — plan only                | Opus    | **Yes**   | User |
| `/implement`           | `<path to .work/plans/*.plan.md>`             | PIV        | Execute plan step by step, then full validation                  | Sonnet  | —         | User |
| `/auto-implement`  | `<path to .work/plans/*.plan.md>`             | PIV        | Run a confirmed plan to PR-open without confirmation — implement + commit + push + PR. Never merges. | Sonnet  | —         | User |
| `/validate`        | —                                             | PIV        | Run all checks — lint, types, tests, browser smoke test           | Sonnet  | —         | User |
| `/commit`          | —                                             | PIV        | Stage and commit locally — no push, no PR                         | Haiku   | —         | Auto (via `/ship`) or User |
| `/ship`            | —                                             | PIV        | Commit + push + open PR, then optional parallel review            | Opus    | —         | User |
| `/review`          | `[PR-number]`                                 | PIV        | 3-subagent parallel review + security check + verdict; works with or without a PR | Opus    | —         | Auto (via `/ship`) or User |
| `/apply-ci-review` | `[PR-number]`                                 | PIV (Fix)  | Apply the CI review's comments locally + validate — no commit    | Opus    | —         | User |
| `/security-review` | `[file-or-directory]`                         | PIV        | Security review of changed files                                 | Opus    | —         | Auto (via `/review`) or User |
| `/reflect`         | —                                             | Anytime    | Capture learnings, evolve system — after merge, bug, or session   | Sonnet  | —         | User |
| `agent-browser`    | `<subcommand>` (CLI tool, not slash command)  | PIV        | Browser smoke test — part of `/validate` and `/implement`             | —       | —         | Auto or User |

### When to run `/context` standalone

`/context` runs automatically as the first step of `/plan-feature` and `/implement`, so you rarely need to call it yourself. Run it explicitly when:

- **Mid-story resume** — coming back to a worktree after time away. Run `/context` to see a clean recap (branch, plan status, existing report) before deciding whether to `/implement` or revise the plan.
- **Stale session** — after a long conversation, when the agent starts missing things it should know. Bare `/context` (no argument) reloads rules + git state without writing a plan.
- **Before `/reflect`** — gives `/reflect` an up-to-date project state to analyze.
- **Debugging missing context** — if the agent overlooked a pattern or rule, run `/context` to verify what is actually in the working set.

With no argument, `/context` skips the spec-loading step and only refreshes project rules, git state, and existing plans/reports.

### When to run `/validate` standalone

`/validate` runs automatically as the final step of `/implement` (full validation suite after all tasks). Run it explicitly when:

- **Before `/ship`** — sanity check that nothing has regressed after a manual edit or commit fix.
- **Quick Path changes** (typo, copy tweak, config value) — used in place of `/implement` to verify the change before shipping.
- **Debugging a failing check** — re-run a specific lint/type/test cycle without re-running the implementation flow.
- **Mid-implementation** — if you suspect a previous task broke something, run `/validate` to confirm before continuing.

### When to run `/commit` standalone

`/commit` runs automatically as the first step of `/ship` (commit + push + PR + review). Run it explicitly when:

- **WIP checkpoint** — saving progress mid-story without pushing or opening a PR yet.
- **Multiple commits per story** — when you want several focused commits before opening the PR via `/ship`.
- **Doc-only or trivial change** — when `/ship`'s PR + review flow is overkill and you just want a tidy commit.
- **Pre-`/ship` cleanup** — committing a small fix before the actual ship step.

### Commit checkpoints — when to commit

Commit when the state is **consistent and describable in one sentence** — by logical unit, not by elapsed time. A passing task, a working scaffold, a green validation run are all natural checkpoints. Several commands end by surfacing such a checkpoint and suggesting `/commit`.

The suggestion is always a prompt, never an action: Claude proposes the commit, you confirm. **Nothing auto-commits** — the only sanctioned exception is `/auto-implement` (a pre-approved plan on a `feat/*` branch).

### When to run `/review` standalone

`/review` triggers automatically when you answer "yes" inside `/ship`. Run it explicitly when:

- **Before `/ship`** — review local changes early, before pushing. No PR needed; falls back to `git diff {base_branch}...HEAD`.
- **Re-review** — after addressing feedback from a previous run, re-run to verify the findings are resolved.
- **Manual push** — you pushed and opened the PR yourself (without `/ship`), and now want the review.
- **External PR** — reviewing a contributed PR or a branch you did not write. Pass the PR number: `/review 42`.
- **Clean-context review** — the conversation has grown long; run `/clear` first, then `/review` for the sharpest results.

Always run `/clear` before `/review` — the three subagents benefit from a clean context window.

**Diff source resolution:**
1. PR number passed as argument → `gh pr diff <number>`
2. No argument, PR exists for current branch → `gh pr diff` (inferred)
3. No argument, no PR → `git diff {base_branch}...HEAD` (local fallback)

### `/review` vs `/code-review` — and choosing an effort level

Two different reviewers with confusingly similar names:

- **`/review`** — this starter's command (`commands/review.md`). Fans out 3 subagents tuned to *your* project: CLAUDE.md convention compliance, pattern reuse, test-coverage gaps. **Advisory only** — reports inline, never edits or commits. One fixed configuration.
- **`/code-review`** — a built-in Claude Code skill (not in this repo). Generic deep bug hunt with a tunable **effort dial**, a verify stage to filter false positives, and `--fix` / `--comment` flags. `ultra` runs in the cloud.

They overlap (both flag reuse/simplification) but are complementary: `/review` for *your* conventions, `/code-review` for deep bugs + direct fixing. Higher effort = more tokens and time, but higher recall and fewer false positives. **Match the level to the risk** (and pass it explicitly — don't rely on the default):

| Level | Cost | Use it for |
|-------|------|-----------|
| `low` / `medium` | cheap, fast | Trivial or small diffs; a quick pre-`/ship` pass; few but high-confidence findings |
| `high` | moderate | Normal feature work, non-trivial logic — broader coverage, may surface less-certain findings |
| `max` | high | Risky changes where a missed bug is costly — widest local coverage, includes uncertain findings |
| `ultra` | highest (cloud) | High-stakes diffs: DB migrations, auth, money logic, large refactors; a final pre-merge gate on critical PRs |

```
/code-review low              # quick local pass
/code-review high --fix       # deep hunt + apply fixes (then re-run /validate)
/code-review ultra 42         # cloud review of PR #42
```

> After `/code-review --fix` changes code, run `/validate` again — fixes can break lint/types/tests.

### When to run `/apply-ci-review`

The Fix-loop entry point for the CI case (`review-only` / `full`). After the CI `claude-review` posts comments on your PR, `/apply-ci-review` pulls them and applies the fixes **locally**, then runs `/validate`. It stops before commit — you commit and push, and the push re-triggers the CI review.

- Use it instead of a second local review: the CI already reviewed the diff, so `/code-review` would be redundant.
- In `off` mode (no CI review) or before the PR exists, use `/code-review --fix` instead.

### When to run `/security-review` standalone

`/security-review` auto-runs inside `/ship` when the diff touches risky paths (API routes, DB queries, auth, forms). Run it explicitly when:

- **Pre-emptive scan** — before `/ship`, when you know you touched sensitive code and want feedback early.
- **Specific files** — pass a file or directory path to audit it without involving the rest of a diff.
- **External code** — reviewing a contributed PR, a third-party snippet, or vendored code.
- **After a security advisory** — when an upstream CVE drops and you want to verify exposure.

### When to run `agent-browser` standalone

`agent-browser` runs automatically inside `/validate` (and therefore `/implement`) for the smoke test. Run it explicitly when:

- **UI debugging** — manually inspect a page or component, open the snapshot, click around interactively.
- **Screenshot capture** — grabbing a screenshot for documentation, a PR description, or a tracker issue.
- **Cross-feature regression check** — verifying that a change in one area didn't break adjacent UI.
- **Custom URL** — when the dev server isn't on the standard port or you want to test a non-local URL.

### When to run `/reflect`

`/reflect` is anytime-triggered — no auto path. Run it when:

- **After a merge** — capture what deviated, what was missing, what should become a rule before the next story starts.
- **After a frustrating session** — when you corrected the same thing twice, or the agent missed something obvious.
- **After a bug** — fix both the bug AND the system that allowed it (`BUG → ? → + RULE`).
- **Periodically** — a deep-review pass across `CLAUDE.md`, commands, and reference docs to keep them aligned with how the project has evolved.

---

## Test quality — what a good test looks like

Used by `/plan-feature` (when listing behaviors), `/implement` (when writing a task's test), and `/validate` (when judging the test step). Stack-neutral:

- **Test behavior, not implementation.** Assert what the code does through its results, not how it does it internally.
- **Use the public interface.** Drive the code the way a real caller would; don't reach into private internals or assert on intermediate state.
- **A good test survives an internal refactor.** If renaming or restructuring an internal function breaks the test while behavior is unchanged, the test was coupled to implementation — fix the test.
- **Prefer integration-style over heavy mocking.** Exercise real code paths; mock only true boundaries (network, clock, external services), not your own collaborators.

Write tests one behavior at a time alongside the code (see `/implement` Step 3) — not all tests up front, which tends to test imagined rather than actual behavior.

---

## Troubleshooting

| Problem                            | Fix                                                                                   |
| ---------------------------------- | ------------------------------------------------------------------------------------- |
| Dev server port conflict in worktree | Run `PORT=$(cat .worktree-port) <dev_cmd>` — each worktree has its own port in `.worktree-port`. |
| DB state missing in worktree       | `/worktree` copies DB at creation time. If main DB has new data, copy again manually.  |
| Type errors after implement        | Run `type_check_cmd` (from `.claude/project.yml`) and fix before committing.           |
| Tracker issue not created          | Check the API key in `.claude/settings.local.json` and `enabledMcpjsonServers`.        |
| Fork won't push `base_branch`      | Use `git push origin <base_branch>` from the terminal instead.                         |
| Claude session feels slow/confused | Start a fresh session and run `/context` to reload the mental model.                   |
| CI jobs not running as expected    | Check `autonomy_mode` and `ci_review_provider` in `.claude/project.yml` and that the matching secret (`ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GEMINI_API_KEY`) is set. See `AUTONOMY.md`. |

---

## Deploying

The starter does not opinionate on deployment — pick what fits the project.
Three common patterns once `auto-merge` lands code on your `base_branch`:

**Vercel** — connect the repo at <https://vercel.com/new>, pick `base_branch`
as the production branch. Every merge auto-deploys. Preview deployments are
created per PR automatically.

**Coolify** (self-hosted) — in the Coolify dashboard, create a service for the
repo, set the deployment branch to `base_branch`, copy the webhook URL, and add
it as a GitHub webhook (Settings → Webhooks → Push event).

**Netlify** — connect the repo at <https://app.netlify.com>, pick `base_branch`,
set build command and publish directory from `project.yml`. Deploy Previews per
PR are enabled by default.

For any of these: keep production secrets in the host's environment variables,
not in the repo. The CI workflow only needs the review provider's key —
`ANTHROPIC_API_KEY` by default, or `OPENAI_API_KEY` / `GEMINI_API_KEY`
(see `AUTONOMY.md`).
