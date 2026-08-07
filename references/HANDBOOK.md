# Handbook

The parts of compass that are neither the flow nor a single command: where files
live, the one discipline enforced everywhere, how config works, and what to do
when something breaks.

The loops are in `WORKFLOW.md`. Each command in detail is in `COMMANDS.md`.

---

## The `.work/` Directory

Your session-persistent workspace — local to your machine.

```
.work/
├── plans/         # /compass:plan-feature   → committed
├── reports/       # /compass:implement      → gitignored
└── screenshots/   # agent-browser           → gitignored
```

Plans are committed — they are the durable record of how a feature was built. Reports and screenshots are generated output — gitignored.

Each plan ends with a `## Loop log`, filled in *during* implementation: decisions made while coding, snags, and "tried X — failed because Y" landmines. Deltas only, never a restatement of the plan. It is the feature's durable scratch space across sessions and handovers.

**Feature state is derived, not stored.** There is no status file — phase, PR, and CI come from `git` and `gh` when you ask.

---

## Verification before completion

"Done" is a claim, and a claim needs evidence. Before reporting a task, a fix, or a feature as complete — or committing, or opening a PR — name the command that proves it, run it **fresh**, and read the actual output (exit code, pass/fail counts). Then report what the output showed, not what you expected.

- **Hedge words are not a verdict.** "should pass", "looks right", "probably fine" describe an expectation, not an observation — they don't close a task.
- **Run it now, in full.** A stale run from three edits ago, or a filtered subset, doesn't prove the current state. Re-run the real command.
- **Read output, not a wrapper's summary.** A green tick in a tool is not the exit code — confirm the underlying result.
- **An honest failure beats a blind success.** If the proof command fails, say so with the output; never paper over it.

Binding in `/compass:implement` (Steps 4 & 6), `/compass:ship` (the PR body), `/compass:validate`, and `/compass:fix-ci-review`. It is the same reason feature state is derived rather than stored — re-proven, not remembered.

**Stop at three.** The same rule applied to fixing: if a gate or a finding survives three distinct attempts, the diagnosis is wrong, not the patch. Stop and re-investigate instead of making a fourth blind change.

---

## Project config

**compass has no config file.** Everything it needs is the `## Commands` table in `.claude/CLAUDE.md`, plus the **Test policy**, **Dev port** and **Base branch** lines under it. Edit that table directly; there is nothing to regenerate and no schema to refresh after a plugin update.

It lives there because only commands ever read it — no script and no workflow parses project config, and the selftest fails if one starts to. A file read exclusively by an LLM does not need to be YAML, and `CLAUDE.md` is already loaded in every session and read by claude-code-action on the PR. A separate file was a second copy of the same truth.

Two consequences worth knowing:

- **Nothing validates it.** A misspelled `Test policy` value falls back to `first`, silently. The upside is that a row you delete simply removes that gate — a project without a type checker leaves `Type check` blank and loses nothing else. A blank command is skipped, never guessed.
- **The row labels are the interface.** `Dev`, `Build`, `Lint`, `Format`, `Type check`, `Test` — commands look them up by name. Rename one and its gate stops running. Extra rows are ignored, so add your own freely.

Worktrees read nothing at all: default branch from `origin/HEAD`, package manager from the lockfile, a free port scanned from 3000 up. Anything stateful is the project's own business — `scripts/worktree.sh` runs `.claude/worktree-setup.sh` and `.claude/worktree-teardown.sh` if they exist, with `WT_NAME`, `WT_DIR`, `WT_BRANCH` and `WT_PORT` exported. Create a database there, seed a schema, write a per-worktree `.env`; compass cannot know what your stack needs, and stops pretending it does.

**Guidance split.** The SessionStart hook injects workflow orientation and the doc index — it is **plugin-owned** and updates with the plugin. The generated `CLAUDE.md` stays **user-owned**: project facts, review conventions, and a "Project Context" table for your own docs.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Dev server port conflict in worktree | Run `PORT=$(cat .worktree-port) <your dev command>` — each worktree reserves its own free port. |
| DB state missing in worktree | compass isolates dir, branch and port only. Per-worktree state is your `.claude/worktree-setup.sh` — see `/compass:worktree`. |
| Type errors after implement | Run the `Type check` command (from `.claude/CLAUDE.md` → `## Commands`) and fix before committing. |
| Fork won't push `base_branch` | Use `git push origin <base_branch>` from the terminal instead. |
| Claude session feels slow/confused | Start a fresh session and re-run `/compass:plan-feature` — it reloads the mental model first. |
| No review appears on the PR | `/install-github-app` offers two workflows. If you installed only *Claude PR Assistant* (`claude.yml`), it waits for an `@claude` mention — comment `@claude review this`, or re-run the setup and add *Claude Code Review* (`claude-code-review.yml`). Also check `ANTHROPIC_API_KEY`. |
| `command not found: gh` | Install the GitHub CLI (`brew install gh` → `gh auth login`). `ship` and `fix-ci-review` check for it up front. Or skip it: `/compass:commit --push` and open the PR yourself. |

> **Git host.** compass targets **GitHub** — `gh` for PRs, GitHub Actions for CI, and claude-code-action for PR review (GitHub-only). The local loop (plan → implement → validate → commit) is host-agnostic; on GitLab/Bitbucket, push works and you open the MR/PR yourself. There is no `glab`/`.gitlab-ci.yml` path by design.
