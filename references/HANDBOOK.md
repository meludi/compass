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
| Agent deviated from plan | Update the relevant command in `commands/` (plugin root) |
| Agent repeated a mistake | Add a rule to `CLAUDE.md`                          |
| Context was missing      | Add a new on-demand context doc to `references/`    |

> Don't just fix the bug. Fix the system that allowed the bug.

### How to do it

**Agent deviated from a pattern:**
1. Identify exactly what it did vs. what was expected (file, line, action)
2. Open the relevant command in `commands/` (plugin root)
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

Full details — arguments, with/without behavior, when to run standalone: `COMMANDS.md`.

| Command | Level | Trigger |
|---|---|---|
| `/compass:setup` | Once | User |
| `/compass:onboard` | Once | User |
| `/compass:ideate` | Initiative | User |
| `/compass:setup-stack` | Once | User |
| `/compass:setup-tracker` | Once | User |
| `/compass:create-stories` | Initiative | User |
| `/compass:worktree` | PIV | User |
| `/compass:context` | PIV | Auto or User |
| `/compass:plan-feature` | PIV | User |
| `/compass:implement` | PIV | User |
| `/compass:auto-implement` | PIV | User |
| `/compass:validate` | PIV | Auto or User |
| `/compass:commit` | PIV | Auto or User |
| `/compass:ship` | PIV | User |
| `/compass:review` | PIV | Auto or User |
| `/compass:code-review` | PIV | User |
| `/compass:apply-ci-review` | PIV (Fix) | User |
| `/compass:security-review` | PIV | Auto or User |
| `/compass:reflect` | Anytime | User |

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

After a task's tests are **green** (never while red), scan for these and clean up — used by `/compass:implement` (post-green), `/compass:review`, and `/compass:code-review`:

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

- **Schema** — `${CLAUDE_PLUGIN_ROOT}/compass.schema.json` defines required keys, enums, and types. The `# yaml-language-server: $schema=` line at the top of `compass.yml` gives autocomplete + inline validation in editors with the YAML extension, and `/compass:setup` validates against it (a mistyped key or bad enum is reported, not silently defaulted).
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
| `command not found: gh`            | Install the GitHub CLI (`brew install gh` → `gh auth login`). `ship`, `auto-implement`, and `apply-ci-review` check for it up front. Or skip it: `/compass:commit --push` and open the PR yourself. |

> **Git host.** compass targets **GitHub** — `gh` for PRs and GitHub Actions for the CI autonomy layer (`claude-code-action` is GitHub-only). The local PIV loop (plan → implement → validate → commit) is host-agnostic and works anywhere; on GitLab/Bitbucket, push works and you open the MR/PR yourself. There is no `glab`/`.gitlab-ci.yml` path by design.

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
