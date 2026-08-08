# Handbook

The rules that outlive any single command, plus what to do when something breaks.

The loops are in `WORKFLOW.md`. Each command in detail is in `COMMANDS.md`.

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

## `.work/`

`plans/` is committed; `reports/` and `screenshots/` are generated output and gitignored.

Each plan ends with a `## Loop log`, filled in *during* implementation: decisions made while coding, snags, and "tried X — failed because Y" landmines. Deltas only, never a restatement of the plan. It is the feature's durable scratch space across sessions and handovers.

**Feature state is derived, not stored.** There is no status file — phase, PR, and CI come from `git` and `gh` when you ask.

---

## Why there is no config file

The `## Commands` table in `.claude/CLAUDE.md` *is* the configuration — the README documents the rows. What it does not say is why they live there: only commands ever read them. No script and no workflow parses project config, and the selftest fails if one starts to. A file read exclusively by an LLM does not need to be YAML, and `CLAUDE.md` is already loaded every session and read by claude-code-action on the PR. A separate file was a second copy of the same truth.

The trade is that nothing validates it. A misspelled **Test policy** value falls back to `first`, silently, and a renamed row label stops its gate from running.

**Guidance is split by owner.** The SessionStart hook injects workflow orientation and the doc index — **plugin-owned**, updates with the plugin. The generated `CLAUDE.md` stays **user-owned**: project facts, review conventions, your own context table.

**Two CLAUDE.md files is normal.** Claude Code loads project memory from *both* `CLAUDE.md` at the repo root and `.claude/CLAUDE.md`; compass writes the second. mattpocock/skills' `setup-matt-pocock-skills` only looks at the root one, so it will offer to create it — say yes. The sections do not collide (`## Agent skills` vs. `## Commands`).

One asymmetry to know: the `code-review` plugin instructs its reviewer to read `~/.claude/CLAUDE.md`, the **repo-root** `CLAUDE.md`, and any `CLAUDE.md` above a changed file — `.claude/CLAUDE.md` is not on that list. It still arrives as loaded project memory, so *Review conventions* are honoured either way. To put them in the explicitly-read set, move that one section to the root file.

---

## Gating commits made outside compass

compass' gates run when you invoke a compass command. A commit made straight from the terminal, an editor, or another agent passes none of them.

`${CLAUDE_PLUGIN_ROOT}/templates/husky-pre-commit.sh` closes that gap: it runs the test suite and prints a read-only Claude review of the staged diff. Findings are **printed, never applied** — it does not fix, stage or commit anything. Not installed automatically:

```bash
npm install --save-dev husky && npx husky init
cp ${CLAUDE_PLUGIN_ROOT}/templates/husky-pre-commit.sh .husky/pre-commit
chmod +x .husky/pre-commit
```

It hardcodes `npm test`; edit that line for a non-npm stack.

---

## Troubleshooting

Only the symptoms whose fix is not already in the command that caused them.

| Problem | Fix |
|---|---|
| Dev server port conflict in worktree | Run `PORT=$(cat .worktree-port) <your dev command>` — each worktree reserves its own free port. |
| DB state missing in worktree | compass isolates dir, branch and port only. Per-worktree state is your `.claude/worktree-setup.sh` — see `/compass:worktree`. |
| Fork won't push `base_branch` | Use `git push origin <base_branch>` from the terminal instead. |
| Claude session feels slow/confused | Start a fresh session and re-run `/compass:plan-feature` — it reloads the mental model first. |
| The review workflow runs green but posts nothing | `permissions:` in `.github/workflows/claude-code-review.yml` needs `pull-requests: write`. With `read` the run succeeds and the comments are buffered and dropped — the log says so, the PR does not. |
| No review appears on the PR | `/install-github-app` offers two workflows. If you installed only *Claude PR Assistant* (`claude.yml`), it waits for an `@claude` mention — comment `@claude review this`, or re-run the setup and add *Claude Code Review* (`claude-code-review.yml`). Also check `ANTHROPIC_API_KEY`. |

> **Git host.** compass targets **GitHub** — `gh` for PRs, GitHub Actions for CI, and claude-code-action for PR review (GitHub-only). The local loop (plan → implement → validate → commit) is host-agnostic; on GitLab/Bitbucket, push works and you open the MR/PR yourself. There is no `glab`/`.gitlab-ci.yml` path by design.
