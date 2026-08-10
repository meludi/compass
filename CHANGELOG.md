# Changelog

## v0.14.0 — 2026-08-10

### Fixed
- **Claude can no longer invoke the shipping commands on its own.** Custom commands are skills now, and a skill is model-invocable unless it says otherwise — so `/compass:commit`, `/compass:ship` and `/compass:plan-to-pr` were reachable by an agent that decided the code looked ready, `plan-to-pr` being the one command that commits and pushes without asking. Every command with a side effect — `setup`, `worktree`, `plan-feature`, `implement`, `plan-to-pr`, `commit`, `ship`, `fix-ci-review` — now carries `disable-model-invocation: true`. `/compass:validate` and `/compass:help` stay open: reading and routing are what you *want* an agent to reach for. Nothing in the chain breaks, because `plan-to-pr` delegates by reading `commands/*.md` rather than by invoking the commands.

## v0.13.0 — 2026-08-10

### Added
- **Plans record where they came from.** The plan template gained a `## Source` line — the issue reference, the spec path, or `conversation` — with the instruction not to restate what it points at. Everything below that line is what the plan *adds*: the `Mirror:` targets, the ordered tasks, the gates. Without it, a plan read three sessions later gave no way back to the issue it was built against, and the pull request had nothing to close.

### Fixed
- **`/compass:plan-feature <issue-id>` confirms which issue it found.** The command mentioned `gh issue view` but required nothing, so a bare `#2` was resolved against whatever numbered list was in view — a todo file, a checklist, another repository — confidently rather than fail-closed, and the mistake only surfaced once a plan for the wrong work existed. It now fetches the issue and prints the title back before planning.

## v0.12.0 — 2026-08-09

### Added
- **`/compass:setup` writes `.work/.gitignore`.** The README and the handbook had said for several versions that `reports/` and `screenshots/` were gitignored, and nothing ever wrote the rule — `setup` touched nothing outside `.claude/`. So the first implementation report and the first browser screenshot sat there untracked, waiting to be swept into a commit. Two lines, inside `.work/` rather than in the `.gitignore` you maintain, and an existing file is left alone. Plans stay committed; they are the feature's record.
- **A misread `## Commands` table now says so.** No config file means no schema, and no schema meant a renamed row label silently deleted its gate while a typo in **Test policy** silently became `first`. `/compass:validate` and `/compass:implement` now print one line when a label is missing entirely or a policy value is not `first`/`after`/`none`, then carry on. A deliberately blank command stays silent — that is a gate you chose not to have, and it was never the problem. This is not validation; it is the reader saying out loud what it read, which is the only check a schemaless file can carry.
- **Three coherence checks in `scripts/selftest.sh`** (now 17 static checks): every command must appear in `references/COMMANDS.md`, `commands/help.md` and `TESTING.md`; `plugin.json`'s version must match the newest CHANGELOG heading; and every `FILE.md → *Section*` pointer must hit a heading that exists. The first exists because `/compass:plan-to-pr` shipped in v0.11.0 while `TESTING.md` still said "9 commands" and had no test for it — an untested command is what a missing doc entry looks like from the outside.
- **`references/COMMANDS.md` spells out a `/compass:plan-to-pr` run end to end** — pre-flight, the three phases, the hard stop, plus a table of every point it can abort at and what it leaves behind. The command file delegates by step number to `implement.md` and `ship.md`, so the actual sequence had to be assembled from three files. For the one command that commits without asking, being able to read what happens in your name is part of picking it deliberately. The section orders the steps and points at `commands/` for the rules; it does not restate them.
- **`TESTING.md` covers `/compass:plan-to-pr`**, guards first: each pre-flight refusal, an aborted run on a broken build, the report and PR body carrying the Phase 2 review fixes, and the staging rules. The command that commits without asking is the one whose refusals need proving.

### Fixed
- **`/compass:commit` gained the two guards the other shipping commands already had.** `--push` on the base branch now asks instead of pushing straight to `main` with no PR and no review, and a path matching `.env*`, `*.db` or a credential shape aborts the commit by name rather than being quietly staged. `ship.md` and `plan-to-pr.md` both carried these rules; the one command routed as "just commit, no PR" did not.
- **`/compass:plan-to-pr` writes its review round into the report.** Phase 2 applied `/code-review` findings and re-validated, then Phase 3 built the PR body from a report written before any of that happened — so the PR described older code than the branch carried, in a command whose whole premise is that nobody is watching. Phase 2 now appends *Review findings applied* and *Validation after review* before the commit.
- **`/compass:ship` picks the report that belongs to the branch**, matching `feat/<name>` against `.work/reports/<name>-report.md` instead of taking whatever file is newest. With two features in one checkout, "newest" was a PR body describing someone else's work; `ls -t` remains as a fallback that now announces itself.
- **`origin/HEAD` is repaired rather than worked around.** `gh repo create --source=.` leaves it unset, and the lookup in `/compass:setup` and `/compass:ship` then failed into the current branch — which, in a worktree, is the feature branch a PR cannot open against. Both now run `git remote set-head origin --auto` once and retry; `ship` asks rather than guessing if that fails too.
- **Dead cross-reference `HANDBOOK.md → Project config`** in the CLAUDE.md template and `TESTING.md`; the section is called *Why there is no config file*. The template ships into every project that runs `/compass:setup`. The new selftest check is what keeps the next rename from doing this again.
- **`/setup` → `/compass:setup`** in the template header, the last unnamespaced command name in the repo.

### Changed
- **`/compass:help` routes "the plan turned out wrong halfway through"** to `/compass:plan-feature` with an explicit revision request. The command has always refused to silently overwrite a complete plan and always accepted being asked; nothing told you the door was there.

## v0.11.0 — 2026-08-08

### Added
- **`/compass:plan-to-pr` — a confirmed plan to an open PR, unattended.** Loop 2 already had an automated path (`/autofix-pr`); Loop 1 had none, so the only way to skip the per-task confirmations was the Quick Path, which assumes no plan at all. The command chains what already exists — `/compass:implement` with its per-task gates, the full validation suite, `/code-review` on the branch, a re-validate of the fixes it applied, then commit, push and PR — and **stops at the PR URL**. It never merges, never force-pushes, and aborts before the commit on any failed check, so a broken state cannot reach the PR. Pre-flight refuses to start on the base branch, on a working tree with changes outside the plan's scope, on an unreadable plan path, or without `gh` — the `gh` check runs *first* so a run cannot implement its way into a missing CLI. A tripped 3-fix boundary aborts rather than asking, since nobody is watching.

  **`/compass:plan-feature` is deliberately not in the chain.** Every guard checks the state the run happens in; none can check whether the plan is right. The plan you read is the only human gate, which is what makes the rest safe to automate — and what makes this the wrong command for migrations, auth boundaries, or the first use of a library in your codebase. Reach for it when the plan is stable and the change follows patterns already there; otherwise stay with `/compass:implement`.

  This is the **one** compass command that commits without confirmation. `Never auto-commit` still holds everywhere else. A version of this command existed before v0.10.0 under the name **`/compass:auto-implement`** and was dropped with the config layer it depended on; this one is rebuilt on the `## Commands` table and git alone — no `compass.yml`, no reviewer agent. The new name states both endpoints because the old one named only the start of the chain, while the part worth knowing about is where it ends.

  **Compass is now nine workflow commands plus the router.** The selftest asserts the new count and still fails if an `agents/` directory reappears.

## v0.10.0 — 2026-08-07

**Compass is now eight workflow commands plus a router.** It covers the execution loop — plan, implement, validate, ship — and nothing else. Everything that another maintained tool already does better was removed rather than kept in step with it. If you relied on a dropped command, see the migration table below.

### Removed
- **Code review inside compass** — `/compass:review-code`, `/compass:review-project`, `/compass:review-security` and all three agents (`code-reviewer`, `codebase-explorer`, `pr-test-analyzer`) are gone. Claude Code ships `/code-review` and `/security-review` natively; keeping a parallel implementation meant tracking a moving target for no gain. `/compass:plan-feature` now uses the built-in `Explore` agent instead of `codebase-explorer`.
- **The CI autonomy layer** — `autonomy_mode`, `ci_review_provider`, `ci_review_model`, `ci_review_guidelines`, `autofix_max_pushes`, `references/AUTONOMY.md`, the `ci-review` / `ci-checklist` / `autofix-guard` / `auto-merge` jobs, and `templates/review-guidelines.md`. Automated PR review is now `anthropics/claude-code-action`, installed once per repo with `/install-github-app` — it owns its own workflow, reads `.claude/CLAUDE.md`, and is maintained for you. **This drops provider neutrality**: the Codex/OpenAI/Gemini review paths no longer exist.
- **The CI workflow template** — `templates/pr-validation.yml` is gone. A workflow that runs your lint/type/test suite is generic CI your stack already has a template for, and `/compass:validate` runs the same checks locally before every ship. compass now ships no workflow at all; `/install-github-app` handles PR review and writes its own.
- **The config file itself** — `.claude/compass.yml` and `compass.schema.json` are gone, along with `templates/compass.yml`, `scripts/read-config.sh`, the schema copy `/compass:setup` used to place in your project, and every key that only a script needed (`package_manager`, `install_cmd`, `dev_cmd`, `db_file`, `worktree_prefix`, `worktree_setup_cmd`, `worktree_teardown_cmd`, the dead `src_dir`). **Project config is now the `## Commands` table in `.claude/CLAUDE.md`** — the gate commands as table rows, plus `Test policy`, `Dev port` and `Base branch` lines beneath it. Nothing else parses project config, and the selftest fails if a machine consumer reappears. Rationale: only commands ever read the file, so it was already LLM-read prose in YAML clothing, while `CLAUDE.md` is loaded in every session anyway and is what claude-code-action reads on the PR. **Migration:** move your `compass.yml` values into that table; the row labels (`Dev`, `Build`, `Lint`, `Format`, `Type check`, `Test`) are the lookup keys and must stay spelled as generated. `repo` is no longer stored at all — `/compass:fix-ci-review` derives it from `gh repo view`, and `/compass:ship` falls back to `origin/HEAD` when no `Base branch` line exists. **What you lose:** schema validation and editor autocomplete. A misspelled policy value now falls back to `first` silently.
- **The upstream half of the workflow** — `/compass:ideate`, `/compass:create-stories`, `/compass:setup-stack`, `/compass:setup-tracker`, `/compass:onboard`, `/compass:context`, `/compass:reflect`, `/compass:debug`, `/compass:status`, `/compass:update`, `/compass:auto-implement`, plus `references/CONCEPTS.md`, `references/DEBUGGING.md`, `references/COMMANDS.md` and `templates/mcp.json`. compass no longer produces specs, scaffolds stacks, or syncs trackers.
- **Tracker config** — `tracker`, `tracker_get_issue_tool`, `tracker_create_issue_tool`, `tracker_get_team_tool`. `/compass:plan-feature` takes a spec file, an issue id, or a plain description; it does not need to know your tracker.
- **`.work/prds/` and `.work/stories/`** — only `plans/`, `reports/` and `screenshots/` remain.

### Changed
- **The command files audited against `writing-for-agents`** — mattpocock's reference for documents an agent consumes, applied to `commands/`, `skills/` and the SessionStart hook. **`agent-browser` lost its `--help` cache**: 95 lines were mostly the CLI's own command lists, which the tool already answers and which go stale on every release. What is left (34 lines) is what `--help` cannot say — the `.work/screenshots/` convention, where the dev port comes from, that refs die with their snapshot, and to read the console before calling the UI broken. **Stale facts fixed** — `/compass:commit` still described push behaviour in terms of `review-only`/`full`, autonomy modes that were removed in this same release; this repo's `CLAUDE.md` pointed at `scripts/read-config.sh` and an `agents/` directory that no longer exist; the README told you to re-run `/compass:setup` after every plugin update "to refresh the local schema copy", nine lines above a sentence correctly stating there is no schema to refresh, and `WORKFLOW.md` still listed `schema` as setup's output. The README and `/compass:setup` also claimed `.claude/CLAUDE.md` holds "the review conventions both reviewers read" — `HANDBOOK.md` documents the opposite: the `code-review` plugin reads the repo-root `CLAUDE.md` and ancestors of changed files, not `.claude/CLAUDE.md`. `/compass:fix-ci-review` also states in its hand-back step that the human decides when to merge, rather than leaving it to the Rules block alone. **What the audit deliberately did not change:** the duplicated guardrails (`Never auto-commit`, `Never merge`, `Stop at three`) and the hook's "Do not look for a compass review command". Both are things the reference would prune, and both stay — a guardrail repeated in a Rules block is tail insurance that survives someone editing the step it duplicates, and that hook line was written against an observed problem when v0.10.0 removed the review commands. The reference's own no-op test is model-relative, and compass pins `haiku` for several commands; advice calibrated for the strongest models does not transfer to a file run by the smallest.
- **`HANDBOOK.md` names the two silent PR-review failures, and Loop 2 says to check the first run** — a review workflow that goes green and posts nothing looks identical to one waiting for an `@claude` mention, and only the third case was documented. Both new causes were found testing `/install-github-app` end to end. The first is `permissions:` in `claude-code-review.yml`: with `pull-requests: read` the run succeeds and the comments are buffered and dropped, visible in the Actions log and nowhere else. The second is a defect in the bundled `code-review` plugin — it tells the agent to "launch a haiku agent", but `haiku` is a model, not a subagent type, so the call fails and the retries exhaust the turn budget. That one cannot be updated past: the workflow reinstalls the plugin from upstream `HEAD` every run and the line is still there ([#38964](https://github.com/anthropics/claude-code/issues/38964) was closed by a stale bot, not by a fix). `WORKFLOW.md` still recommends the *Claude Code Review* workflow — it works once configured — but no longer implies it works untended. The plugin row carries an explicit re-check marker, since compass is documenting someone else's open bug.
- **`COMMANDS.md` answers *whether*, never *how*** — it had accumulated a second copy of rules the command files own: the golden rule, the whole **Test policy** table, the 3-fix boundary (a fourth copy, after `implement`, `fix-ci-review` and `HANDBOOK`), the commit guardrails, the finding-disagreement rule. Unlike a repeated guardrail in a Rules block, nobody acts on this file — it is read for orientation, so a stale copy misleads without ever being caught by a failing run. Each entry now carries what actually decides whether to reach for the command: that `/compass:implement` is safe to interrupt because every task is gated, that re-running `/compass:setup` cannot overwrite your file, that `rm` is guarded and cannot lose work. The rule is stated at the top of the file so the next edit does not re-add procedure.
- **`HANDBOOK.md` cut from 94 to 74 lines, and its pointers now name an occasion** — it opened by defining itself as "the parts of compass that are neither the flow nor a single command", and a document defined by its negation has no trigger, so every pointer at it listed topics instead. Two sections earn deep links from commands (*Verification before completion* from `/compass:implement` and `/compass:ship`, the husky hook from `/compass:setup`) and are untouched. The rest was overlap: the `.work/` tree and the config-row descriptions are in the README, so what stays is only what the README does not say — the Loop log's semantics, that feature state is derived rather than stored, and *why* there is no config file. Troubleshooting dropped the two rows whose fix the command already prints (`command not found: gh` has pre-flights in both `ship` and `fix-ci-review`; "type errors after implement" said to run the type checker). `WORKFLOW.md`, the README and the SessionStart hook now point at it with a condition rather than a table of contents.
- **`/compass:help` prints all three sections when called bare** — it said "print the situation table, then the boundary table below it. Nothing else", which left *Nothing to run* as dead content the router never surfaced. All three now print.
- **`TESTING.md` fixes four checks that could not pass as written** — the `/code-review` step asserted it "picks up *Review conventions* from `.claude/CLAUDE.md`", the same claim corrected elsewhere in this release; *Abort / cleanup* used `${CLAUDE_PLUGIN_ROOT}` inside blocks the maintainer runs in a plain terminal, where it expands to nothing; the plan-section list omitted `Behavior`, the line that decides whether **Test policy** fires at all; and nothing checked that a task's `Mirror` points at a file that exists.
- **`/compass:plan-feature` explores until every planned file has a mirror** — step 3 listed what to look for but set no bound, so "explored enough" was self-declared and a thin pass produced tasks whose `Mirror:` lines pointed at paths nobody opened. Exploration is now done when every file the plan touches has a real `file:line` target, or the plan states why none exists.
- **`/compass:ship` checks that its evidence is current** — a new pre-flight lists source files touched after the implementation report was written and re-runs `/compass:validate` if any turn up. Without it, fixing `/code-review` findings and shipping straight after would push unproven code *and* a PR body claiming validation that never covered it. Uses `find -newer` rather than `stat`, whose flags differ between macOS and Linux.
- **`/compass:ship` hands off instead of reviewing** — it commits, pushes, opens the PR, and names who reviews it. The "Run code review now?" fan-out is gone.
- **Both loops are now numbered steps** — Loop 1 (build) ends when the PR opens; Loop 2 (fix) is everything after, as the same shape: diagram, numbered table, a few short notes. `/code-review` is **step 4 of Loop 1**, before `/compass:ship`, because a finding is cheaper to fix while no PR exists — it is Claude Code's command, not compass', and is marked as such. Loop 2 splits into two named paths: **CI Fix** (`/compass:fix-ci-review` — you confirm, fixes are validated locally before they leave your machine) and **Autofix** (`/autofix-pr` — the PR monitors itself and pushes its own fixes, skipping `/compass:validate`). `/code-review ultra` is no longer mentioned: compass cannot launch it, and listing every adjacent tool turned the review section into a decision tree instead of a workflow.
- **PR review is documented as automatic** — `/install-github-app` installs two selectable workflows, and the docs previously named only one. *Claude Code Review* (`claude-code-review.yml`) triggers on `pull_request: opened, synchronize, ready_for_review, reopened` with no mention gate, so it reviews every PR and every push to it, running the same `/code-review` you run locally; *Claude PR Assistant* (`claude.yml`) is the `@claude`-triggered one. `@claude review this` is now described as the fallback for the second setup, not the normal path.
- **`/compass:fix-ci-review` is now the only fix bridge** — it reads the review comments on a PR (from claude-code-action or a human) and applies them **locally**, so every fix passes `/compass:validate` before you push. It still never commits and never merges.
- **The PIV core delegates doctrine instead of restating it** — `/compass:implement` and `/compass:validate` point at the `tdd` skill for what a good test is, and at `diagnosing-bugs` for root-cause method, keeping only the mechanics compass owns: the per-task gate, `test_policy`, verify-RED, the 3-fix boundary, the Loop log, and the report. The pointers are soft — compass runs fine without those skills, falling back to a one-line summary inline. `HANDBOOK.md` → *Test quality* shrank accordingly.
- **`worktree.sh` reads no configuration** — it derives the base branch from `origin/HEAD` (falling back to the current branch), the package manager from the lockfile, and reserves the first free port from 3000 up. Per-worktree state moved from two config strings to project-owned hooks: if `.claude/worktree-setup.sh` or `.claude/worktree-teardown.sh` exist, they run in the worktree with `WT_NAME`, `WT_DIR`, `WT_BRANCH`, `WT_PORT` exported. This is **more** general than before — the old `db_file` key handled exactly one case (a single SQLite file), while a hook covers Postgres, Docker, migrations, per-worktree env, anything. A failing hook warns instead of aborting. **The port is no longer predictable** (`dev_port + N` before); read it from `.worktree-port`.
- **`references/WORKTREES.md` folded into `/compass:worktree`** — a separate 178-line doc whose every example was a config key that no longer exists. The command now carries all of it: mental model, isolation scope, hooks, the stack recipes (Postgres, Mongo/Payload, Docker Compose, SQLite, non-JS installs) rewritten as hook scripts, multi-worktree editor setups, and session resuming. One file to open instead of two to keep in sync.
- **Review conventions moved into `CLAUDE.md`** — the `CLAUDE.md` template scaffolds a *Review conventions* section, read by both `/code-review` locally and claude-code-action on the PR. It replaces `.github/review-guidelines.md`.
- **Model guidance is tiers, not names** — `HANDBOOK.md` lists opus/sonnet/haiku with what each is for, dropping the pricing and context-window table that went stale every release.
- **`scripts/selftest.sh` asserts the shape** — it now checks the nine commands by name, fails on a tenth, and fails if an `agents/` directory reappears.
- **Three reference docs, one job each** — `WORKFLOW.md` is the loops: Loop 0 (deciding what to build, entirely mattpocock/skills), Loop 1 (build), Loop 2 (fix), plus a dedicated `/install-github-app` section answering when and how often to run it, and a three-line *Where compass stops*. `COMMANDS.md` returns as the per-command reference — argument, trigger, what it writes, when to run it standalone. `HANDBOOK.md` keeps only what belongs to neither: `.work/`, the verification discipline, config mechanics, troubleshooting. The mattpocock/skills pointers, previously scattered across three files, now live in one place with the skill names spelled out per question.
- **`HANDBOOK.md` cut from 237 to 71 lines** — it had become a grab-bag nobody reads. What's left is the part with no other home: the `.work/` layout, the *Verification before completion* discipline, config mechanics, and troubleshooting. Dropped: the model pricing/context table (every command names its own tier), *Test quality* (delegated to `tdd`), *Refactor candidates* (that's `/code-review`'s job), *Deploying* (not compass' business), and the glossary. *System Evolution* moved into this repo's own `CLAUDE.md` — it was advice for maintaining compass, not for using it, and it referenced the now-removed `/compass:reflect`.

### Added
- **`WORKFLOW.md` → *Automated PR review*, and Codex named as a second reviewer** — `/install-github-app` had grown a fifteen-line subsection inside *Once per project*: one vendor's workflows, permissions and webhooks wedged into compass' setup step. Reviewer setup is now its own section with a lead table comparing the two — what you set up, what triggers it, what it costs, and which file its repo guidance comes from. **compass ships neither and sets up neither.** `/compass:fix-ci-review` already worked with any reviewer: it reads PR comments through `gh` and never cared who wrote them, which its own description now says instead of naming claude-code-action and a human as if that were the full list. Codex code review needs no workflow file and nothing committed, so there is nothing for compass to generate — this is not the provider config v0.10.0 removed, and no `ci_review_provider` returns. Its repo guidance is `AGENTS.md`, noted in `HANDBOOK.md` beside the existing asymmetry: nothing propagates between that file and the `CLAUDE.md` compass writes.
- **Loop 2 states its default, and Autofix leads with what it needs** — the two paths were offered as an even choice ("pick one per PR"), though only one lets `/compass:validate` gate what reaches the PR; the headings now read *CI Fix — the default* and *Autofix — optional*. Autofix also stopped overstating what it requires and shrank to the shape of its sibling: one line for what it is, one for how it runs, then the table. It never needed the Claude GitHub app — that is a warning when missing, not a gate — and what the app actually buys is latency, where it is **necessary but not sufficient**: real-time webhooks also need Remote Control connected from the mobile or web app, so a plain terminal session polls every 30 minutes even with the app installed. compass never mentioned that second condition, which is the one that bites, since everything looks correctly set up. An automated reviewer is optional for **both** Loop 2 paths — a human review feeds `/compass:fix-ci-review` and triggers autofix just the same — and *Once per project* now says so instead of naming only Loop 1.
- **mattpocock/skills is installed as a plugin now, and named with its prefix** — `WORKFLOW.md` → Loop 0 and `/compass:help` used to point at `npx skills@latest add mattpocock/skills`, which copies the skills into `.claude/skills/` where they load **unprefixed** — and one of them is named `code-review`, the same name as Claude Code's built-in. Claude Code deduplicates skills by resolved file path, not by name, so both load, no warning is shown, and which one `/code-review` reaches is undefined. Since step 4 of Loop 1 *is* `/code-review`, following compass' own Loop 0 advice could silently swap it. Both docs now say `claude plugins install mattpocock-skills` and spell every skill with its `mattpocock-skills:` prefix, so the ambiguity cannot arise; the npx route stays documented for anyone who intends to fork the skills, with the rename called out. Loop 0 and `/compass:help` also point at `mattpocock-skills:ask-matt` — mattpocock's router over his own set, which goes deeper there than compass' router can. It routes its own main flow onward into `mattpocock-skills:implement`, so Loop 0 now names the handoff point explicitly: the spec is the argument for step 2, and that is where you leave his flow. His `implement` builds from a spec and commits; compass' executes a plan file, gates every task, and writes the report `/compass:ship` checks — not the same command under two names. Left bare on purpose: the soft `tdd` / `diagnosing-bugs` pointers inside `/compass:implement`, `/compass:validate` and `/compass:fix-ci-review`, which test for availability and should match either install route.
- **`/compass:help` — a router, not a command list** — answers "which command fits *this* situation" across all four sources at once: compass, Claude Code's built-ins, mattpocock/skills, and the cases whose answer is no command at all. Called with a description it names one command and stops; called bare it prints the table. It exists because the hard part was never remembering the eight commands, it was the boundaries between them — so the file leads with *The pairs people confuse* (`/code-review` vs `fix-ci-review` vs `/autofix-pr`, `validate` vs `code-review`, `plan-feature` vs `to-spec`). This makes nine commands; `WORKFLOW.md` still orders them by flow, `COMMANDS.md` by ownership, `help` by the question you have.
- **`HANDBOOK.md` explains the two `CLAUDE.md` files** — Claude Code loads project memory from both the repo root and `.claude/`, and compass writes the second. mattpocock/skills' setup only looks at the root file and will offer to create it; the sections do not collide. Noted alongside it: the `code-review` plugin tells its reviewer to read the root file and ancestors of changed files, not `.claude/CLAUDE.md` — conventions still arrive as loaded memory, but move that section to the root file if you want it in the explicitly-read set.
- **`WORKFLOW.md` → *mattpocock's `code-review` — the spec axis*** — names the one thing Claude Code's `/code-review` never checks: whether the branch implements what the spec asked for. mattpocock's `code-review` covers it with a Spec axis (missing requirements, scope creep), never a replacement for step 4 — the built-in finds bugs and verifies them, the other one finds drift. Two placements, named **A** and **B** with the reason for each: A is Loop 1 between step 4 and step 5, the last moment before the PR exists and scope creep is still cheap to cut; B is Loop 2 once a PR has stopped moving after several `/compass:fix-ci-review` rounds, each of which added code nobody re-checked against the spec. One or the other, not both, and the fixed point is the branch point in both cases — comparing against the last push shows the fixes, not the feature. Spelled out as three conditions, because the skill is worth nothing without them: a written spec, a feature large enough to drift, and `docs/agents/issue-tracker.md` for issue resolution. Skipped entirely on the Quick Path and for anyone who skipped Loop 0. Sits next to *Quick Path* as a side path, not inside a loop — it belongs to neither and applies to both.
- **`HANDBOOK.md` → *Gating commits made outside compass*** — `templates/husky-pre-commit.sh` shipped for releases without a single doc pointing at it, so nobody could find it. It closes a real gap: compass' gates only run when you invoke a compass command, while this hook fires on every `git commit` whatever triggered it. Findings are printed, never applied. Its header no longer refers to the removed `review-only` autonomy mode. `/compass:setup` now names it in the closing output next to `/install-github-app` — as text only: it installs nothing, since that would mean a dev dependency and a `.husky/` directory, and setup touches nothing outside `.claude/`.

### Migration

In each project, move the values from `.claude/compass.yml` into a `## Commands` table in `.claude/CLAUDE.md`, then delete `compass.yml` and `compass.schema.json`:

```markdown
## Commands

| Step       | Command             |
| ---------- | ------------------- |
| Dev        | `npm run dev`       |
| Build      | `npm run build`     |
| Lint       | `npm run lint`      |
| Format     | `npm run format`    |
| Type check |                     |
| Test       | `npm test`          |

- **Test policy:** `first`
- **Dev port:** `3000`
- **Base branch:** `main`
```

`name` and `repo` have no replacement — nothing reads them. `/compass:setup` generates this table for a fresh project, but **will not overwrite an existing `CLAUDE.md`**, so this move is manual for projects you already set up. `.mcp.json` and `.github/review-guidelines.md` can go if compass was their only consumer. Keep `.github/workflows/pr-validation.yml` if you want it — compass no longer generates or updates it, so it is yours now.

If you used `db_file` or the worktree hook keys, move them into a `.claude/worktree-setup.sh` (and `-teardown.sh`):

```bash
#!/usr/bin/env bash
# was: db_file: myapp.db
cp "$(git rev-parse --show-toplevel)/../$(basename "$PWD" | sed 's/-[^-]*$//')/myapp.db" . 2>/dev/null || true
# was: worktree_setup_cmd: createdb "myapp_$WT_NAME"
createdb "myapp_$WT_NAME"
```

| Dropped | Use instead |
|---|---|
| `/compass:review-code`, `/compass:review-project` | `/code-review` |
| `/compass:review-security` | `/security-review` |
| `autonomy_mode: review-only` / `full` | `/install-github-app` → `anthropics/claude-code-action` |
| `autofix_max_pushes` | `/autofix-pr` and its own limits |
| `/compass:ideate`, `/compass:create-stories` | [mattpocock/skills](https://github.com/mattpocock/skills) — `grill-with-docs`, `to-spec`, `to-tickets` |
| `/compass:debug` | its `diagnosing-bugs` skill |
| `/compass:setup-tracker` | your tracker directly; `/compass:plan-feature` accepts an issue id or a description |
| `/compass:status` | `git status`, `gh pr view` |
| `/compass:setup-stack` | no replacement — scaffold the stack yourself |
| `templates/pr-validation.yml` | your stack's own CI template; `/compass:validate` already gates locally |
| `db_file`, `worktree_setup_cmd`, `worktree_teardown_cmd` | `.claude/worktree-setup.sh` / `-teardown.sh` in your project |
| `package_manager`, `install_cmd`, `dev_cmd` | derived from the lockfile; a non-JS stack installs in its setup hook |
| `.claude/compass.yml`, `compass.schema.json` | the `## Commands` table in `.claude/CLAUDE.md` |
| `name`, `repo` | nothing reads them; `repo` comes from `gh repo view` |

## v0.9.0 — 2026-06-11

### Added
- **`/compass:debug` + `references/DEBUGGING.md` — root-cause discipline** — a new Fix-loop command that diagnoses a failing test, red CI check, or runtime error **before** changing code: four phases (root-cause investigation → pattern analysis → one-hypothesis-at-a-time testing → fix-with-failing-test) and a hard **3-fix boundary** — after three failed attempts on the same problem, stop patching and re-investigate, because three misses mean the diagnosis is wrong. Closes the gap where Compass had no debugging method; the per-finding counterpart to the `autofix_max_pushes` push-count brake. The 3-fix boundary is **binding** wherever fixes happen — `/compass:implement` (per-task gate), `/compass:fix-ci-review` (per finding), and `/compass:auto-implement` (per task) all stop after three failed attempts and switch to root-cause mode; `references/AUTONOMY.md` frames it as the reasoning-level counterpart to the `autofix_max_pushes` push cap. The `/compass:debug` *command* stays optional (root-causing inline is fine); the *discipline* is what's required. Surfaced in the SessionStart hook's on-demand doc index, `COMMANDS.md`, `HANDBOOK.md`, and `WORKFLOW.md` Loop 2.
- **`/compass:auto-implement --review-tasks` — optional per-task spec check** — in an unattended plan-to-PR run, dispatch the `code-reviewer` subagent on each task's diff right after its gate passes, catching drift early where no human is watching task by task. Off by default (interactive work still uses the end-of-PR review, better for cohesion); the trade-off is one extra subagent per task. Documented in `COMMANDS.md`.
- **`scripts/selftest.sh` — dry-run / self-test (maintainer tool)** — one command that validates the parts of the plugin that need no human: JSON manifests, template YAML, `compass.yml` keys vs the schema (`additionalProperties: false` guard), the CI workflow's jobs, shell syntax, `${CLAUDE_PLUGIN_ROOT}`/doc-link integrity, code-fence balance, and the component inventory. `--full` also runs a **functional `worktree.sh` test** in a throwaway temp repo (create, port, symlink, `rm` guards, `--force`). `--report [file]` writes a timestamped Markdown report (default `reports/selftest-report-<date-time>.md`, gitignored). Exits non-zero on any failure; the static checks change nothing. The "lint" to `TESTING.md`'s manual E2E — referenced from `TESTING.md` (run it first) and `CLAUDE.md` (run before a release commit).

### Changed
- **Verification before completion** — a new discipline section in `references/HANDBOOK.md` and gate lines in `/compass:implement` (Steps 4 & 6) and `/compass:ship`: "done" is reported only from **fresh** proof-command output (exit code, pass/fail counts), never from memory, a stale run, or a hedge ("should pass"). The same principle Compass already applies by deriving `/compass:status` live instead of storing it.
- **Verify-RED for `test_policy: first`** — `/compass:implement`'s test-first path now requires **running the new test and watching it fail for the expected reason** before writing code (a test that errors out or passes immediately proves nothing), and to write the test first if code came first. Noted under `HANDBOOK.md` → *Test quality*. Affects only the `first` policy; `after`/`none` unchanged.

### Docs
- **Delegating CI review + fix to an external reviewer (Codex)** — `references/AUTONOMY.md` gains a subsection (with a Mermaid schema and a review-fix-loop-per-provider table) on handing PR review **and** fix to Codex's native GitHub integration: set `autonomy_mode: off` (compass review stands down, the `test` gate stays), keep `autofix_max_pushes` as the brake, put conventions in `AGENTS.md`, and run **one autonomous fixer per PR** (Codex *or* Claude auto-fix). README's *Auto-fix the PR* section links to it. Setup links added for both Codex and Claude auto-fix. Docs-only; no config or workflow change.
- **`TESTING.md` — auto-fix flow steps** — added an "Auto-fix the PR — both flows" section with test checklists for Claude native auto-fix (`/autofix-pr` + the `autofix-guard` brake) and the Codex external-reviewer path, plus matching overview and prerequisite lines.

## v0.8.0 — 2026-06-10

### Added
- **`ci_review_guidelines` — project review conventions in the CI prompt** — CI appends a Markdown file of your conventions to the review prompt for **every** provider (Claude, OpenAI, Gemini) as higher-priority criteria, so the CI review carries your project's signature. **On by default:** `/compass:setup-stack` drops a starter at `.github/review-guidelines.md` and points the field at it; edit it to taste, or set the field blank to disable (a missing file is harmless). The cross-provider stand-in for a review "skill" — external providers are a plain API call with no skill system, so the prompt is the only lever.

### Fixed
- **Config schema completed** — `compass.schema.json` was missing `ci_review_model` and `autofix_max_pushes` (added in earlier 0.6.x/0.7.0 releases); with `additionalProperties: false` they were flagged as invalid keys by editor validation and `/compass:setup`. Added them plus `ci_review_guidelines`.

## v0.7.0 — 2026-06-10

### Added
- **Manual-test checklist for every CI provider** — `ci-checklist` previously ran only for `claude`; `openai` and `gemini` now also post the `## Manual Verification Before Merge` checklist (a second API call, same rules: ≤10 manual, user-facing items). Inline review comments remain Claude-only.

### Changed
- **CI review/checklist are provider-neutral** — the old `claude-review` and `external-review` jobs are merged into one **`ci-review`** job whose status check is named **"CI review"** regardless of `ci_review_provider` (claude posts inline comments; openai/gemini post one summary comment). The checklist job is **`ci-checklist`** (check "CI checklist"). Branch-protection check names now stay stable when you switch providers.
  - **Migration:** if your branch protection required `claude-review` / `claude-checklist`, change them to `CI review` / `CI checklist`.

## v0.6.0 — 2026-06-10

### Added
- **`/compass:status`** — reports where the feature on the current branch stands (phase, PR, CI, findings, auto-fix push count) **derived live** from `git` + `gh` every time, so it can never drift. Phases: `not-started`, `local — no PR yet`, `ci-running`, `ci-failing`, `awaiting-fixes`, `awaiting-checklist`, `ready-to-merge`, `escalated`, `merged`, each with the facts behind it and a one-line next step. Read-only; falls back to local-only status when `gh` is absent. Replaces the idea of a hand-maintained status file — there is no state file to forget to update.
- **`## Loop log` section in every plan** — `/compass:plan-feature` now ends the plan with a `## Loop log`; `/compass:implement` and `/compass:fix-ci-review` append deltas to it during the loop (decisions made while coding, snags, "tried X — failed because Y" landmines). It is the feature's durable scratch space across sessions and handovers — the only thing persisted, since live status is derived.
- **`autofix_max_pushes` config + `autofix-guard` CI job** — a circuit-breaker for Claude Code's native `auto-fix` toggle (Desktop/web/CLI), which otherwise has no documented stop condition. Set `autofix_max_pushes: N` (`>0`) and the CI job fails (red) and posts a single `## Auto-fix stopped` comment once a PR reaches N pushes without going green, so a human takes over. Independent of `autonomy_mode`; idempotent; blocks auto-merge in `full` mode when tripped. Rests only on `gh` commit counts, not on auto-fix internals. Documented in `references/AUTONOMY.md`.
- **"Running the autonomous PR loop" docs** — `references/AUTONOMY.md` now explains end to end how the native `auto-fix` loop is started (it is not a compass command) and an actor table contrasting it with `/compass:auto-implement` (one-shot, pre-PR, local commit) vs `auto-fix` (iterative, post-PR, client pushes). Surfaced in the README Workflow section.
- **Mermaid workflow diagrams** — step-by-step flowcharts for the overall map, Loop 1 (PIV), and Loop 2 (Fix) in `references/WORKFLOW.md`, and the autonomous PR loop in `references/AUTONOMY.md`. The existing ASCII overview is kept for terminal-friendly scanning.
- **`ci_review_model` config** — pin the model the CI review uses. Blank keeps the provider default (`claude-code-action` default / `gpt-4o` / `gemini-1.5-pro`); set a full model id to override. Wired into the Claude jobs (`claude_args --model`) and the OpenAI/Gemini path. Documented in `references/AUTONOMY.md`.
- **README "Auto-fix the PR" section** — dedicated, plain-language explanation of how to start Claude's native `auto-fix` (`/autofix-pr` or the Desktop toggle), with a link to the Claude Code docs and how `autofix_max_pushes` brakes it.

### Changed
- **CI `claude-checklist` prompt tightened** — the manual-verification checklist now excludes anything CI already covers (no "tests pass"/"types check") and requires every item to describe observable, user-facing behaviour, hard-capped at 10 items.
- **Docs simplified for scannability** — `references/AUTONOMY.md` restructured (lead-with-summary sections, tighter tables, less repetition; ~30% shorter, same information); `references/HANDBOOK.md` "Deploying" prose turned into a table; `references/WORKFLOW.md` Loop 2 reframed as two independent axes (local-vs-CI × which-review) with a "which command when" guide.
- **README condensed to a quick-start** — tightened to Install → Configure → Workflow → docs, with a key-config table (`test_policy`, `autonomy_mode`, `ci_review_provider`/`ci_review_model`, `autofix_max_pushes`). The supported-trackers table moved to `references/HANDBOOK.md`; deeper detail now links out instead of living on the front page (~180 → ~95 lines).

### Fixed
- **WORKFLOW.md Stage 0 ordering** — `/compass:setup-stack` was listed as step 1c (before `/compass:ideate`), contradicting its own "run after ideate" instruction and PRD input; moved to after `ideate`, before `create-stories`.
- **README polish** — corrected a `--scope` typo and a "Level 1/Level 2" label that should read "Loop 1/Loop 2".

## v0.5.0 — 2026-06-08

### Added
- **`/compass:update`** — reconciles an existing project's `.claude/compass.yml` with the installed plugin after a `/plugin update compass`. Refreshes the schema copy, diffs config keys against the plugin template, surfaces keys the update added (with defaults + comments) or removed, adds the new ones non-destructively on confirmation, and re-validates. Behaviour-changing new keys (e.g. `test_policy`, `autonomy_mode`) are called out with a pointer to their docs. Existing values are never changed; orphaned keys are reported, not deleted. Closes the gap where plugin updates left existing configs untouched, silently defaulting new switches.

## v0.4.0 — 2026-06-08

### Added
- **`test_policy` config option** (`first | after | none`) in `.claude/compass.yml` — choose how tests relate to logic-bearing tasks: `first` = test-first TDD (RED → GREEN, the default and unchanged behavior), `after` = implement then write the test, `none` = no forced test. UI/glue/config tasks never force a test, regardless of policy. Honored by `/compass:implement`; surfaced in the README Configuration section and documented in `/compass:plan-feature`, `references/COMMANDS.md`, and `references/HANDBOOK.md`.

## v0.3.1 — 2026-06-04

### Fixed
- **`/compass:worktree` — graceful `claude` auto-open** — when invoked from within a Claude Code session, the `claude` launch no longer errors; instead it prints a note to open a new terminal manually.
- **`/compass:worktree` — symlink `settings.local.json`** — `.claude/settings.local.json` is now symlinked from the main project into each new worktree (same as `.env.local`), so tracker auth and MCP config are available immediately.

## v0.3.0 — 2026-06-04

### Changed
- **Review commands renamed and improved** — consistent `review-*` prefix for all review commands; `apply-ci-review` renamed to `fix-ci-review` (clarifies it applies CI findings rather than reviewing). `review-project` (was `review`) and `review-security` (was `security-review`) gain a `--fix` flag. All three `review-*` commands prompt to run `/clear` first for a clean context.
- **`references/COMMANDS.md` — `Uses` field per command** — each command entry now lists which other compass commands it invokes internally (explicit calls and inline procedure inclusions), making the dependency graph visible at a glance.
- **`/compass:onboard` is now self-contained** — no longer requires a prior `/compass:setup` run. If `compass.yml` is missing (the normal case for any brownfield project), it bootstraps the config inline (Phase 1: copy template + auto-detect values, Phase 2: validate + generate `CLAUDE.md` if absent), then proceeds directly to the codebase scan. Running `/compass:setup` first is no longer necessary.

## v0.2.0 — 2026-06-04

### Added
- **`/compass:onboard`** — brownfield project onboarding: scans the existing codebase and fills `CLAUDE.md` (Architecture, Code Patterns, Testing, Key Files) instead of leaving TODO stubs. Supports `--refresh` to re-scan after codebase evolution.
- **`/compass:review-code`** — namespaced wrapper around the built-in `/code-review` with compass-specific follow-up: after `--fix` applies changes, automatically runs `/compass:validate`. All bare `/code-review` references updated to `/compass:review-code` throughout.
- **`references/COMMANDS.md`** — single source for every command: consistent schema per entry (description, metadata table with Level/Recommended model/Argument/Trigger, With/Without argument, When to run standalone). HANDBOOK and WORKFLOW now point here instead of duplicating command details.
- **`/compass:commit --push` flag** — commit and push in one step; without the flag, `/compass:commit` asks whether to push after committing.
- **`gh` pre-flight checks** in `/compass:ship`, `/compass:auto-implement`, `/compass:fix-ci-review`, `/compass:review-project`, and `/compass:setup-stack` — stops before committing if `gh` is not installed, with install instructions and a manual alternative.

### Changed
- **`reference/` renamed to `references/`** — all cross-references updated.
- **WORKFLOW.md tables** — Stage 0, Loop 1, Loop 2, and Other commands tables now use `→ details` links to `COMMANDS.md` instead of inline descriptions. Loop 1 and Loop 2 are fully tabular (consistent with Stage 0).
- **HANDBOOK.md Command Reference** — slimmed to 3 columns (Command / Level / Trigger); details moved to `COMMANDS.md`.
- **README** — install section documents project-scoped install (`--scope local` / `--scope project` via shell CLI); Requirements table adds "If missing" column; GitHub-centric scope noted.
- **GitHub-centric scope documented** — compass targets GitHub (`gh` + GitHub Actions); local PIV loop is host-agnostic; noted in README and HANDBOOK Troubleshooting.

## v0.1.0 — 2026-06-03 — first plugin release

The starter is now a **Claude Code plugin** (`meludi/compass`), installed via the marketplace instead of copying `.claude/` into each project. Versioning restarts at `0.x` (`1.0.0` at first stable release); the prior `1.x` history below is the copy-model era. **This is a one-way migration** — the copy-`.claude/` workflow is retired.

### Added
- **Plugin packaging** — `.claude-plugin/plugin.json` (manifest, `version`) and `.claude-plugin/marketplace.json` (catalog). Install with `/plugin marketplace add meludi/compass` then `/plugin install compass@compass`; develop locally with `claude --plugin-dir .`.
- **MIT license** + manifest metadata — `LICENSE` file and `plugin.json` `repository`, `homepage`, `license`, `keywords`, `displayName`, `$schema`, and `author.url`.
- **Namespaced commands** — every command is now invoked as `/compass:<name>` (e.g. `/compass:plan-feature`, `/compass:implement`, `/compass:ship`). All cross-references updated.
- **Always-on guidance via SessionStart hook** — `hooks/hooks.json` + `hooks/session-start.sh` inject a short orientation (PIV loop, on-demand framework docs, project config/conventions) at session start. This replaces the `@compass/AGENTS.md` import (a plugin `CLAUDE.md` is not loaded by Claude Code), which is removed.
- **`/compass:setup` generates the project files** from plugin templates — `.claude/compass.yml` (from `templates/compass.yml`), a copy of the schema at `.claude/compass.schema.json` (so the editor `$schema` line resolves; refreshed by re-running setup), `.claude/CLAUDE.md`, and a project `.mcp.json` for tracker sync. Nothing is copied wholesale anymore.
- **Self-contained CI template** — `templates/pr-validation.yml` reads `.claude/compass.yml` with an inline reader, so it runs in GitHub Actions on the user repo without the plugin installed. `/compass:setup-stack` copies it into `.github/workflows/`.
- **Config-driven issue tracker** — the tracker's MCP tool names live in `.claude/compass.yml` (`tracker`, `tracker_get_issue_tool`, `tracker_create_issue_tool`, `tracker_get_team_tool`). `/compass:context` and `/compass:create-stories` read them generically, and `/compass:setup-tracker` switches trackers by rewriting that config + `.mcp.json` + `settings.local.json` — it no longer edits command files (which are read-only in the plugin cache). `tracker: none` keeps stories local to `.work/stories/`.

### Changed
- **BREAKING — repo root is the plugin root.** `commands/`, `agents/`, `skills/`, `reference/`, `scripts/`, `templates/`, and the schema (renamed `project.schema.json` → `compass.schema.json` to pair with `compass.yml`) moved from `.claude/` (and `.claude/compass/`) to the repo root. Bundled-file references use `${CLAUDE_PLUGIN_ROOT}/…`; project-side files use `${CLAUDE_PROJECT_DIR}/…`. The `.claude/` directory no longer ships.
- **BREAKING — versioning** is the semver `version` in `plugin.json` plus git tags (`vX.Y.Z`). The standalone `VERSION` file is dropped.
- **`.mcp.json` is project-side, not bundled** — the plugin no longer ships a `.mcp.json` (which would auto-push the Linear MCP server onto every install). The tracker MCP config now lives in the user's project, generated by `/compass:setup` and switched by `/compass:setup-tracker`.
- Folds in the prior consolidation work: machinery gathered under one tree, `project.yml` renamed to `compass.yml` (user-owned config at `.claude/compass.yml` in the project), a single shared config reader (`scripts/read-config.sh`), and schema-backed `compass.yml`.

### Removed
- `VERSION` file and `compass/AGENTS.md` — superseded by `plugin.json` `version` and the SessionStart hook, respectively.
- The plugin no longer tracks `.work/` (project working dir) or `.mcp.json` (project tracker config) — both are project-side, created in the user's repo.

## v1.8.0 — 2026-06-02

### Added
- `.claude/project.schema.json` — JSON Schema for `project.yml` (required keys, enums, types, `owner/repo` pattern, `dev_port` integer). A `# yaml-language-server: $schema=` line in `project.yml` enables editor autocomplete + inline validation; `/setup` validates against it so a mistyped key or bad value is reported instead of silently defaulting.
- `.claude/scripts/read-config.sh` — single shared reader (`read_config <key>`) for `project.yml`, used by both `scripts/worktree.sh` (sourced) and CI (executed). Zero runtime dependencies (flat `key: value` only).

### Changed
- `scripts/worktree.sh` and `.github/workflows/pr-validation.yml` now use the shared reader instead of two separate hand-rolled `grep|cut|sed` parsers.
- `/setup` no longer embeds a duplicate `project.yml` template (which had drifted from the shipped file) — it edits the canonical shipped file in place, pre-fills command fields from `package.json`, and validates against the schema.
- `project.yml` fields grouped under comment headers (Identity / Commands / Worktrees / CI) for readability; format stays flat YAML (no nesting, no new dependency).

## v1.7.0 — 2026-06-02

### Added
- **Refactor candidates** catalogue in `reference/HANDBOOK.md` — structural smells with remediations (duplication, long method, shallow/deep modules, feature envy, primitive obsession, plus code the new change reveals as awkward). Scanned post-green by `/implement`, and referenced by the `code-reviewer` agent and `/code-review`. Surfaced in the On-Demand Context table (`CLAUDE-template.md`).

## v1.6.0 — 2026-06-02

### Added
- Test-quality guidance — new **Test quality** section in `reference/HANDBOOK.md` (behavior over implementation, public interface only, survives refactor, integration over heavy mocking), surfaced in the On-Demand Context table (`CLAUDE-template.md`) and referenced by `/plan-feature`, `/implement`, `/validate`.
- `/plan-feature` task template — optional `Behavior` line (the observable behavior to verify). Present for logic tasks, omitted for pure UI/glue/config.

### Changed
- `/implement` Step 3 now branches by task type: **logic-bearing tasks** (those with a `Behavior` line) are built **test-first** (RED → GREEN, one behavior at a time, the test is the per-task gate alongside the type check); **UI/glue/config tasks** keep the type-check-only gate. Post-green cleanup cross-links the built-in `/code-review` rather than refactoring while red.

## v1.5.0 — 2026-06-02

### Added
- `/setup-stack` now leaves a **runnable app**: it scaffolds a visible welcome screen (project name + `Button`) wired into the app entry point, adds a first smoke test for it, and ends with a **boot check** (build or briefly start the dev server) plus exact instructions to open the app in the browser.
- `ci_review_provider` (`project.yml`) — choose which LLM runs the CI PR review: `claude` (default, inline comments + checklist via `claude-code-action`, `ANTHROPIC_API_KEY`), or `openai` / `gemini` (a single `## Review Summary` comment via the provider API, `OPENAI_API_KEY` / `GEMINI_API_KEY`). New `external-review` job in `pr-validation.yml`; `auto-merge` tolerates whichever review path is skipped. The field is now a visible default in the `project.yml` template (`commands/setup.md`) next to `autonomy_mode`, which is also surfaced in the committed `project.yml`.
- `/setup-stack` Step 11 now **verifies** the matching CI secret is present (`gh secret list`) when enabling `review-only`/`full`, and warns if it's missing — instead of silently producing red checks. It still never sets the secret (interactive, handles the raw key); the user runs `gh secret set` themselves.
- Commit checkpoints — `/implement`, `/validate`, and `/setup-stack` now suggest a `/commit` when the working tree is a consistent, one-sentence-describable unit. Suggestion only; nothing auto-commits. Documented as a convention in `reference/HANDBOOK.md`.
- `.claude/VERSION` — plaintext starter version that ships with the copied `.claude/`, so a project can tell which starter version it is on (CHANGELOG and git tags don't travel with the copy). Release process (`CLAUDE.md`) now bumps it alongside the CHANGELOG and tag.

### Changed
- Model recommendation in every command normalized to a single `> **Model:** /model <alias>` callout right under the title, using stable aliases (no version numbers) so it never goes stale; `reference/HANDBOOK.md` model table updated to Opus 4.8.
- `reference/AUTONOMY.md`, `reference/HANDBOOK.md`, `TESTING.md`, `commands/setup-stack.md`, `README.md` — document the review-provider choice and the matching GitHub secret per provider (incl. the README "CI & autonomy" note that an LLM-backed CI review requires the key as a GitHub secret).

## v1.4.0 — 2026-06-02

### Added
- `install_cmd` (`project.yml`) — custom install command for any stack (e.g. `uv sync`, `poetry install`, `go mod download`); overrides the package-manager install in `worktree.sh`. JS projects leave it blank.
- `worktree_setup_cmd` / `worktree_teardown_cmd` (`project.yml`) — per-worktree isolation hooks run by `worktree.sh` on create (after install) / before removal, with `WT_NAME` / `WT_DIR` / `WT_BRANCH` / `WT_PORT` exported. Enables server-DB isolation (Postgres/MySQL) that the `db_file` copy can't cover.
- `reference/WORKTREES.md` — "Isolation scope" section: what worktrees isolate automatically (dir/branch/port, file DB) vs what needs hooks (server DB, non-JS), with a security note; plus copy-paste **Recipes** for Payload CMS + MongoDB, Python + Postgres, Docker Compose, and a non-JS install-only stack.
- `TESTING.md` (repo root) — maintainer self-test covering all four workflow flows (Stage 0 Setup, Loop 1 PIV, Loop 2 Fix in both `off` and `review-only` modes, Quick Path) plus the guarded worktree lifecycle, run against a throwaway sandbox repo. Stack-agnostic; not shipped via `.claude/`.

### Changed
- `scripts/worktree.sh` — `read_yml` now strips only a trailing ` # comment` and one surrounding quote pair, **preserving internal quotes** so command values (`install_cmd`, hooks) survive intact (also a more robust fix for the earlier comment-pollution issue).
- `commands/setup.md`, `project.yml` — document the new fields (with a commented Postgres example).
- `reference/CONCEPTS.md` — the "DB races" blocker now notes the setup hook for server DBs.

## v1.3.0 — 2026-06-02

### Added
- `/apply-ci-review` — new Fix-loop command: pulls the CI `claude-review` comments from the PR and applies the fixes **locally**, then runs `/validate`. Stops before commit (no auto-commit); the human commits and pushes. The non-redundant fix path in `review-only` / `full`.
- CI `claude-review` now posts a single `## Review Summary` comment on the PR alongside its inline comments — finding count plus a verbatim reminder that findings are fixed locally, never by CI.
- `reference/AUTONOMY.md` — at-a-glance mode-comparison matrix (off / review-only / full) covering CI jobs, who reviews/fixes/merges, cost, risk, and suitability; plus notes on no-API-key behaviour and draft-PR exclusion. New "Fixing review findings (the Fix Loop)" section covering both fix entry paths (local pre-PR, CI post-PR).
- `reference/HANDBOOK.md` — "`/review` vs `/code-review` — and choosing an effort level" section (effort recommendation table); `/apply-ci-review` added to the command table with standalone guidance.

### Changed
- `scripts/worktree.sh` — `rm` is now **guarded**: it refuses (and changes nothing) on uncommitted changes, on commits not merged into `base_branch` (with a pushed-vs-local-only note), or when run from inside the target worktree. `-f`/`--force` overrides; deletion uses safe `git branch -d` unless forced. Documented as `/worktree <name> rm` in `commands/worktree.md`.
- `reference/WORKFLOW.md` — rewritten as the canonical map around four phases: **Setup** (once) · **PIV Loop** · **Fix Loop** · **autonomy axis**. The Fix Loop (review → fix → validate → commit → push → repeat) is now a first-class section with a reviewer / fix-path decision tree and an `off` vs `review-only` side-by-side.
- `reference/` docs de-duplicated to single-source each concept: glossary + logical flow → HANDBOOK; 10x / parallel development → CONCEPTS; command flow → WORKFLOW; autonomy modes → AUTONOMY. Removed duplicated representations — AUTONOMY's intro mode-table (the matrix covers it), WORKFLOW's autonomy re-explanation (folded into the Fix-loop mode contrast), the CONCEPTS logical-flow stub, the HANDBOOK parallel-dev block, and the WORKTREES VS Code + repeated port explanations.

### Fixed
- `scripts/worktree.sh` — `project.yml` field parsing now strips inline comments. Previously a commented field (e.g. `package_manager: pnpm  # ...`) was read with the comment attached, silently falling back to `npm` and mis-reading `dev_port` / `db_file` / `dev_cmd`.

## v1.2.0 — 2026-06-01

### Added
- `/review` — standalone parallel code review command (3 subagents: code-reviewer, pr-test-analyzer, codebase-explorer). Works with or without an open PR: falls back to `git diff {base_branch}...HEAD` when no PR exists. `/ship` now delegates to `/review` instead of duplicating the logic.
- `CLAUDE.md` — maintainer rules for this repo (changelog discipline, commit format, project context).
- Per-worktree dev server ports: `worktree.sh` now assigns each worktree a unique port (`dev_port + N`), writes it to `.worktree-port`, and prints the ready-to-use start command after setup.
- `.worktree-port` added to `.gitignore`.

### Changed
- `README.md` — Setup section now includes `git clone` step and `.mcp.json` copy; directory tree updated with `AUTONOMY.md`, `templates/`, `.github/workflows/`, and `.mcp.json`.
- `commands/ship.md` — steps 6–9 (subagent fan-out, aggregation, security check, verdict) removed; step 5 now delegates to `/review`. `/clear` hint added to the review prompt.
- `commands/worktree.md` — updated Notes and "After the session opens" to reflect per-worktree port and editor hint.
- `reference/WORKTREES.md` — corrected "Dev server runs from main only" rule; added "Dev Server per Worktree" section and port table.
- `reference/WORKFLOW.md` — `/review` added as standalone step 4b; `/ship` includes entry updated.
- `reference/HANDBOOK.md` — `/review` added to command table and Models table; "When to run `/review` standalone" section added; troubleshooting entry updated.
- `scripts/worktree.sh` — reads `dev_port` and `dev_cmd` from `project.yml`; port assignment and `.worktree-port` write added.

## v1.1.0 — 2026-05-30

### Added
- `/auto-implement` — runs a confirmed plan from `.work/plans/` to PR-open without intermediate confirmation. Implements, validates, commits, pushes, opens PR — then hard-stops. Never merges. The only sanctioned exception to the `Never auto-commit` rule, gated by `feat/*` branch + worktree pre-flight checks.

### Changed
- `commands/commit.md` and `commands/ship.md` Rules — note that `/auto-implement` is the sanctioned exception to `Never auto-commit`.
- `reference/WORKFLOW.md` — new "Auto Path" entry in the top diagram and a section explaining when `/auto-implement` is the right tool and when to stay on `/implement` → `/ship`.
- `reference/HANDBOOK.md` — Command Reference table and Models table extended with `/auto-implement`.
- `reference/AUTONOMY.md` — `/auto-implement` added to the "Relationship to other commands" section; husky pre-commit interaction documented.

## v1.0.0 — 2026-05-27

Initial stable release.

### Commands
- `/setup` — project configuration + CLAUDE.md generation
- `/setup-tracker` — switch issue tracker (Linear / Jira / Azure DevOps)
- `/ideate` — brain dump → PRD with incremental design approval
- `/setup-stack` — greenfield tech stack scaffolding
- `/create-stories` — PRD → stories + tracker issues
- `/worktree` — create isolated Git worktree + open Claude session
- `/context` — load rules, git state, optional spec
- `/plan-feature` — implementation plan (plan only, no code)
- `/implement` — execute plan task-by-task with type-check loop
- `/validate` — lint + type check + tests + browser smoke test
- `/commit` — stage and commit with Conventional Commit message
- `/ship` — commit → push → PR → 3-agent parallel review
- `/security-review` — security-focused code review
- `/reflect` — system evolution after merge

### Agents
- `code-reviewer` — CLAUDE.md compliance, security, performance
- `codebase-explorer` — find existing patterns before planning
- `pr-test-analyzer` — test coverage gaps and missing edge cases

### Skills
- `agent-browser` — browser automation for UI smoke tests

### Structure
- `.claude/project.yml` — single source of truth for all commands
- `.claude/scripts/worktree.sh` — full worktree lifecycle script
- `.claude/reference/` — WORKFLOW, CONCEPTS, HANDBOOK, WORKTREES, AUTONOMY
- `.work/` — PIV Loop artifacts (prds, stories, plans, reports, screenshots)
