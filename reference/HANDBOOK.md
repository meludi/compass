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

**A tracker is optional.** When configured (e.g. `LINEAR_API_KEY`), tracker issues are the spec. Without one, stories live in `.work/stories/` — same workflow, no external tool required. Plans live in `.work/plans/`, backlog in `.work/BACKLOG.md`. Describe the feature directly in `/compass:plan-feature` instead of passing an issue ID.

---

## The `.work/` Directory

Your session-persistent workspace — local to your machine.

```
.work/
├── prds/          # /compass:ideate              → committed
├── stories/       # /compass:create-stories      → committed
├── plans/         # /compass:plan-feature        → committed
├── reports/       # /compass:implement               → gitignored
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
1. Write the missing context as a **project** doc (e.g. in `docs/`)
2. Add it to the "Project Context" table in `CLAUDE.md` (framework docs are plugin-owned — indexed by the compass SessionStart hook, not here)
3. `/compass:plan-feature` and `/compass:context` pull from that table — the agent picks it up next session

**`CLAUDE.md` is a living document** — update it after significant features as the project evolves.

The `/compass:reflect` command guides you through all of the above.

---

## Models

| | Opus 4.8 | Sonnet 4.6 | Haiku 4.5 |
|---|---|---|---|
| **Best for** | Complex reasoning, architecture, deep analysis | Balanced quality + speed | Fast, lightweight tasks |
| **In this workflow** | `/compass:ideate`, `/compass:plan-feature`, `/compass:ship`, `/compass:review`, `/compass:security-review` | `/compass:setup`, `/compass:setup-stack`, `/compass:implement`, `/compass:auto-implement`, `/compass:validate`, `/compass:create-stories`, `/compass:reflect` | `/compass:commit`, `/compass:worktree` |
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
| `/compass:setup`           | —                                             | Once       | Configure project — generates `compass.yml` + `CLAUDE.md`         | Sonnet  | —         | User |
| `/compass:ideate`          | `<initiative name>`                           | Initiative | Brain dump → approaches → PRD → self-review (full flow)           | Opus    | **Yes**   | User |
| `/compass:setup-stack`     | `[path to .work/prds/*.prd.md]`               | Once       | Scaffold stack, record style, create seed files (greenfield only) | Sonnet  | —         | User |
| `/compass:setup-tracker`   | —                                             | Once       | Switch issue tracker (Linear / Jira / Azure DevOps)               | Sonnet  | —         | User |
| `/compass:create-stories`  | `[path to .work/prds/*.prd.md]`               | Initiative | Break PRD into stories (`.work/stories/` + optionally a tracker)  | Sonnet  | —         | User |
| `/compass:worktree`        | `<feature-name>`                              | PIV        | Create worktree + branch + open new Claude session                | Haiku   | —         | User |
| `/compass:context`         | `[issue-id \| path to .work/stories/*.md \| feature description]` _(optional)_ | PIV | Refresh mental model — rules, git, spec, on-demand docs. Auto in plan/implement; standalone on resume or stale context | Sonnet  | —         | Auto (via `/compass:plan-feature`, `/compass:implement`) or User |
| `/compass:plan-feature`    | `<path to .work/stories/*.md \| issue-id \| feature description>` | PIV | Load context, then design the changes — plan only                | Opus    | **Yes**   | User |
| `/compass:implement`           | `<path to .work/plans/*.plan.md>`             | PIV        | Execute plan step by step, then full validation                  | Sonnet  | —         | User |
| `/compass:auto-implement`  | `<path to .work/plans/*.plan.md>`             | PIV        | Run a confirmed plan to PR-open without confirmation — implement + commit + push + PR. Never merges. | Sonnet  | —         | User |
| `/compass:validate`        | —                                             | PIV        | Run all checks — lint, types, tests, browser smoke test           | Sonnet  | —         | User |
| `/compass:commit`          | —                                             | PIV        | Stage and commit locally — no push, no PR                         | Haiku   | —         | Auto (via `/compass:ship`) or User |
| `/compass:ship`            | —                                             | PIV        | Commit + push + open PR, then optional parallel review            | Opus    | —         | User |
| `/compass:review`          | `[PR-number]`                                 | PIV        | 3-subagent parallel review + security check + verdict; works with or without a PR | Opus    | —         | Auto (via `/compass:ship`) or User |
| `/compass:apply-ci-review` | `[PR-number]`                                 | PIV (Fix)  | Apply the CI review's comments locally + validate — no commit    | Opus    | —         | User |
| `/compass:security-review` | `[file-or-directory]`                         | PIV        | Security review of changed files                                 | Opus    | —         | Auto (via `/compass:review`) or User |
| `/compass:reflect`         | —                                             | Anytime    | Capture learnings, evolve system — after merge, bug, or session   | Sonnet  | —         | User |
| `agent-browser`    | `<subcommand>` (CLI tool, not slash command)  | PIV        | Browser smoke test — part of `/compass:validate` and `/compass:implement`             | —       | —         | Auto or User |

### When to run `/compass:context` standalone

`/compass:context` runs automatically as the first step of `/compass:plan-feature` and `/compass:implement`, so you rarely need to call it yourself. Run it explicitly when:

- **Mid-story resume** — coming back to a worktree after time away. Run `/compass:context` to see a clean recap (branch, plan status, existing report) before deciding whether to `/compass:implement` or revise the plan.
- **Stale session** — after a long conversation, when the agent starts missing things it should know. Bare `/compass:context` (no argument) reloads rules + git state without writing a plan.
- **Before `/compass:reflect`** — gives `/compass:reflect` an up-to-date project state to analyze.
- **Debugging missing context** — if the agent overlooked a pattern or rule, run `/compass:context` to verify what is actually in the working set.

With no argument, `/compass:context` skips the spec-loading step and only refreshes project rules, git state, and existing plans/reports.

### When to run `/compass:validate` standalone

`/compass:validate` runs automatically as the final step of `/compass:implement` (full validation suite after all tasks). Run it explicitly when:

- **Before `/compass:ship`** — sanity check that nothing has regressed after a manual edit or commit fix.
- **Quick Path changes** (typo, copy tweak, config value) — used in place of `/compass:implement` to verify the change before shipping.
- **Debugging a failing check** — re-run a specific lint/type/test cycle without re-running the implementation flow.
- **Mid-implementation** — if you suspect a previous task broke something, run `/compass:validate` to confirm before continuing.

### When to run `/compass:commit` standalone

`/compass:commit` runs automatically as the first step of `/compass:ship` (commit + push + PR + review). Run it explicitly when:

- **WIP checkpoint** — saving progress mid-story without pushing or opening a PR yet.
- **Multiple commits per story** — when you want several focused commits before opening the PR via `/compass:ship`.
- **Doc-only or trivial change** — when `/compass:ship`'s PR + review flow is overkill and you just want a tidy commit.
- **Pre-`/compass:ship` cleanup** — committing a small fix before the actual ship step.

### Commit checkpoints — when to commit

Commit when the state is **consistent and describable in one sentence** — by logical unit, not by elapsed time. A passing task, a working scaffold, a green validation run are all natural checkpoints. Several commands end by surfacing such a checkpoint and suggesting `/compass:commit`.

The suggestion is always a prompt, never an action: Claude proposes the commit, you confirm. **Nothing auto-commits** — the only sanctioned exception is `/compass:auto-implement` (a pre-approved plan on a `feat/*` branch).

### When to run `/compass:review` standalone

`/compass:review` triggers automatically when you answer "yes" inside `/compass:ship`. Run it explicitly when:

- **Before `/compass:ship`** — review local changes early, before pushing. No PR needed; falls back to `git diff {base_branch}...HEAD`.
- **Re-review** — after addressing feedback from a previous run, re-run to verify the findings are resolved.
- **Manual push** — you pushed and opened the PR yourself (without `/compass:ship`), and now want the review.
- **External PR** — reviewing a contributed PR or a branch you did not write. Pass the PR number: `/compass:review 42`.
- **Clean-context review** — the conversation has grown long; run `/clear` first, then `/compass:review` for the sharpest results.

Always run `/clear` before `/compass:review` — the three subagents benefit from a clean context window.

**Diff source resolution:**
1. PR number passed as argument → `gh pr diff <number>`
2. No argument, PR exists for current branch → `gh pr diff` (inferred)
3. No argument, no PR → `git diff {base_branch}...HEAD` (local fallback)

### `/compass:review` vs `/code-review` — and choosing an effort level

Two different reviewers with confusingly similar names:

- **`/compass:review`** — this starter's command (`${CLAUDE_PLUGIN_ROOT}/commands/review.md`). Fans out 3 subagents tuned to *your* project: CLAUDE.md convention compliance, pattern reuse, test-coverage gaps. **Advisory only** — reports inline, never edits or commits. One fixed configuration.
- **`/code-review`** — a built-in Claude Code skill (not in this repo). Generic deep bug hunt with a tunable **effort dial**, a verify stage to filter false positives, and `--fix` / `--comment` flags. `ultra` runs in the cloud.

They overlap (both flag reuse/simplification) but are complementary: `/compass:review` for *your* conventions, `/code-review` for deep bugs + direct fixing. Higher effort = more tokens and time, but higher recall and fewer false positives. **Match the level to the risk** (and pass it explicitly — don't rely on the default):

| Level | Cost | Use it for |
|-------|------|-----------|
| `low` / `medium` | cheap, fast | Trivial or small diffs; a quick pre-`/compass:ship` pass; few but high-confidence findings |
| `high` | moderate | Normal feature work, non-trivial logic — broader coverage, may surface less-certain findings |
| `max` | high | Risky changes where a missed bug is costly — widest local coverage, includes uncertain findings |
| `ultra` | highest (cloud) | High-stakes diffs: DB migrations, auth, money logic, large refactors; a final pre-merge gate on critical PRs |

```
/code-review low              # quick local pass
/code-review high --fix       # deep hunt + apply fixes (then re-run /compass:validate)
/code-review ultra 42         # cloud review of PR #42
```

> After `/code-review --fix` changes code, run `/compass:validate` again — fixes can break lint/types/tests.

### When to run `/compass:apply-ci-review`

The Fix-loop entry point for the CI case (`review-only` / `full`). After the CI `claude-review` posts comments on your PR, `/compass:apply-ci-review` pulls them and applies the fixes **locally**, then runs `/compass:validate`. It stops before commit — you commit and push, and the push re-triggers the CI review.

- Use it instead of a second local review: the CI already reviewed the diff, so `/code-review` would be redundant.
- In `off` mode (no CI review) or before the PR exists, use `/code-review --fix` instead.

### When to run `/compass:security-review` standalone

`/compass:security-review` auto-runs inside `/compass:ship` when the diff touches risky paths (API routes, DB queries, auth, forms). Run it explicitly when:

- **Pre-emptive scan** — before `/compass:ship`, when you know you touched sensitive code and want feedback early.
- **Specific files** — pass a file or directory path to audit it without involving the rest of a diff.
- **External code** — reviewing a contributed PR, a third-party snippet, or vendored code.
- **After a security advisory** — when an upstream CVE drops and you want to verify exposure.

### When to run `agent-browser` standalone

`agent-browser` runs automatically inside `/compass:validate` (and therefore `/compass:implement`) for the smoke test. Run it explicitly when:

- **UI debugging** — manually inspect a page or component, open the snapshot, click around interactively.
- **Screenshot capture** — grabbing a screenshot for documentation, a PR description, or a tracker issue.
- **Cross-feature regression check** — verifying that a change in one area didn't break adjacent UI.
- **Custom URL** — when the dev server isn't on the standard port or you want to test a non-local URL.

### When to run `/compass:reflect`

`/compass:reflect` is anytime-triggered — no auto path. Run it when:

- **After a merge** — capture what deviated, what was missing, what should become a rule before the next story starts.
- **After a frustrating session** — when you corrected the same thing twice, or the agent missed something obvious.
- **After a bug** — fix both the bug AND the system that allowed it (`BUG → ? → + RULE`).
- **Periodically** — a deep-review pass across `CLAUDE.md`, commands, and reference docs to keep them aligned with how the project has evolved.

---

## Test quality — what a good test looks like

Used by `/compass:plan-feature` (when listing behaviors), `/compass:implement` (when writing a task's test), and `/compass:validate` (when judging the test step). Stack-neutral:

- **Test behavior, not implementation.** Assert what the code does through its results, not how it does it internally.
- **Use the public interface.** Drive the code the way a real caller would; don't reach into private internals or assert on intermediate state.
- **A good test survives an internal refactor.** If renaming or restructuring an internal function breaks the test while behavior is unchanged, the test was coupled to implementation — fix the test.
- **Prefer integration-style over heavy mocking.** Exercise real code paths; mock only true boundaries (network, clock, external services), not your own collaborators.

Write tests one behavior at a time alongside the code (see `/compass:implement` Step 3) — not all tests up front, which tends to test imagined rather than actual behavior.

---

## Refactor candidates

After a task's tests are **green** (never while red), scan for these and clean up — used by `/compass:implement` (post-green), `/compass:review`, and `/code-review`:

| Smell | Remediation |
|---|---|
| Duplication / copy-paste | Extract a function or module; reuse an existing utility instead of reimplementing |
| Long method | Break into smaller helpers; keep tests on the public interface |
| Shallow module (big interface, little behind it) | Combine or **deepen** — hide more complexity behind a smaller interface |
| Feature envy (a function mostly uses another object's data) | Move the logic to where the data lives |
| Primitive obsession (bare strings/numbers for domain concepts) | Introduce a small value object / typed wrapper |
| Existing code the new code just revealed as awkward | Fix it now while context is fresh — or note it in `.work/BACKLOG.md` |

Refactor in small steps and re-run tests after each — behavior must not change. Tests written per the *Test quality* rules above stay green through these moves; if a refactor breaks a test without changing behavior, the test was coupled to implementation.

---

## Project config & validation

`.claude/compass.yml` is the single source of project config. Two things keep it robust:

- **Schema** — `${CLAUDE_PLUGIN_ROOT}/project.schema.json` defines required keys, enums, and types. The `# yaml-language-server: $schema=` line at the top of `compass.yml` gives autocomplete + inline validation in editors with the YAML extension, and `/compass:setup` validates against it (a mistyped key or bad enum is reported, not silently defaulted).
- **One reader** — `${CLAUDE_PLUGIN_ROOT}/scripts/read-config.sh` (`read_config <key>`) is the only parser; `worktree.sh` sources it and CI calls it. It reads **flat** `key: value` only (by design — zero runtime dependencies). Don't nest fields; add new ones flat and to the schema.

Command fields (`dev_cmd`, `test_cmd`, …) are populated from `package.json` by `/compass:setup`/`/compass:setup-stack`; re-run `/compass:setup` to re-sync if scripts change.

**Guidance split (plugin hook vs CLAUDE.md).** The compass plugin's SessionStart hook injects the workflow orientation + the framework on-demand doc index at session start — it is **plugin-owned** and updates with the plugin. The generated `CLAUDE.md` stays **user-owned** — project facts plus a "Project Context" table for your own docs. Keep framework pointers in the hook, project pointers in CLAUDE.md.

---

## Troubleshooting

| Problem                            | Fix                                                                                   |
| ---------------------------------- | ------------------------------------------------------------------------------------- |
| Dev server port conflict in worktree | Run `PORT=$(cat .worktree-port) <dev_cmd>` — each worktree has its own port in `.worktree-port`. |
| DB state missing in worktree       | `/compass:worktree` copies DB at creation time. If main DB has new data, copy again manually.  |
| Type errors after implement        | Run `type_check_cmd` (from `.claude/compass.yml`) and fix before committing.           |
| Tracker issue not created          | Check the API key in `.claude/settings.local.json` and `enabledMcpjsonServers`.        |
| Fork won't push `base_branch`      | Use `git push origin <base_branch>` from the terminal instead.                         |
| Claude session feels slow/confused | Start a fresh session and run `/compass:context` to reload the mental model.                   |
| CI jobs not running as expected    | Check `autonomy_mode` and `ci_review_provider` in `.claude/compass.yml` and that the matching secret (`ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GEMINI_API_KEY`) is set. See `AUTONOMY.md`. |

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
set build command and publish directory from `compass.yml`. Deploy Previews per
PR are enabled by default.

For any of these: keep production secrets in the host's environment variables,
not in the repo. The CI workflow only needs the review provider's key —
`ANTHROPIC_API_KEY` by default, or `OPENAI_API_KEY` / `GEMINI_API_KEY`
(see `AUTONOMY.md`).
