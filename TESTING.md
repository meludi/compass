# compass self-test

End-to-end test of the workflow this plugin ships, run against a throwaway **sandbox project** with a real GitHub remote:

```
Dry-run (static)       bash scripts/selftest.sh    (manifests, config table, doc links, shell — no human/GitHub needed)
Stage 0 — Plugin check claude plugin details       (well-formed: 8 commands, 0 agents, 1 hook, 0 MCP servers)
Stage 1 — Setup        /compass:setup
Loop  — PIV            /compass:worktree → /compass:plan-feature → /compass:implement → /code-review → /compass:ship
Fix   — after review   claude-code-action on the PR → /compass:fix-ci-review → push
Quick Path             /compass:worktree → edit → /compass:validate → /compass:ship
+ worktree lifecycle   /compass:worktree <name> rm   (guarded)
```

**How to use:** work top to bottom, tick each box after it passes. Log every deviation as a one-liner — those are the input for the next round of tightening. This file is for the compass maintainer. It ships with the plugin (it lives at the repo root) but is **not** a loaded component — zero runtime cost.

> Commands are written stack-agnostically as `{test_cmd}` / `{lint_cmd}` / `{type_check_cmd}` — substitute the values from your sandbox CLAUDE.md `## Commands` table. **Browser-smoke** (`agent-browser`, folded into `/compass:validate` and `/compass:implement`) needs a web app with a running dev server; on a non-web sandbox it skips gracefully (⏭) — that's expected.

---

## Installing compass

`<compass>` below = the path to your clone of this repo.

**A — From the marketplace** (once the plugin is merged to the repo's default branch `main`):

```
/plugin marketplace add meludi/compass
/plugin install compass@compass
```

Restart Claude Code if prompted. Later updates: `/plugin update compass`.

**B — From a local clone** (to test *this* branch before it's published — what you do now):

- Session-only, simplest — load it just for one session, nothing installed globally:
  ```bash
  claude --plugin-dir <compass>
  ```
- Or install it from the local path like a marketplace (persists until you remove it):
  ```bash
  claude plugin marketplace add <compass>
  claude plugin install compass@compass
  # undo when done:
  claude plugin uninstall compass && claude plugin marketplace remove compass
  ```

For testing this branch, use **B**. Route **A** only works after the merge to `main`.

---

## Prerequisites

- [ ] `gh` authenticated (`gh auth status`)
- [ ] Node + your package manager installed
- [ ] _(PR-review test, optional)_ `anthropics/claude-code-action` installed via `/install-github-app` with the *Claude Code Review* workflow selected, and `ANTHROPIC_API_KEY` set as a repo secret

---

## Stage 0 — Plugin check

```bash
claude plugin details compass
```

- [ ] Inventory: **8 commands**, **0 agents**, 1 skill, 1 SessionStart hook, **0 MCP servers**
- [ ] No command named `review-*`, `ideate`, `create-stories`, `setup-stack`, `setup-tracker`, `context`, `status`, `debug`, `onboard`, `reflect`, `update`, or `auto-implement` — those were dropped deliberately

Uninstall again when done:

```bash
claude plugin uninstall compass
claude plugin marketplace remove compass
```

---

## Sandbox bootstrap

A fresh repo so the test never touches a real project.

**Recommended stack: minimal Next.js** — so the dev server + browser-smoke are real. Lighter alternative: a minimal TS-Node + Vitest project (faster CI; browser-smoke is skipped). Either works; the test is about the *workflow*, not the app.

1. **Create the project + repo**
   ```bash
   npx create-next-app@latest compass-sandbox --ts --eslint --app --no-tailwind --no-src-dir --use-npm
   cd compass-sandbox
   gh repo create compass-sandbox --private --source=. --remote=origin --push
   ```
2. **Load the plugin** — launch Claude in the sandbox with compass loaded from your clone (nothing is copied in):
   ```bash
   claude --plugin-dir <compass>
   ```
3. **Configure** — `/compass:setup`.

- [ ] Sandbox repo exists on GitHub, `main` pushed
- [ ] Plugin loaded (`/compass:*` commands + SessionStart hook present)
- [ ] `/compass:setup` produced `.claude/CLAUDE.md` — and nothing else
- [ ] The generated `CLAUDE.md` contains a **Review conventions** section
- [ ] **No** CI workflow is written — compass ships none

---

## Stage 1 — Setup

### `/compass:setup`
- [ ] One phase, one file: `.claude/CLAUDE.md`, with code-pattern sections marked `TODO: update after first feature`
- [ ] The `## Commands` table carries `Dev`, `Build`, `Lint`, `Format`, `Type check`, `Test` with the row labels intact, filled from `package.json` — a script that does not exist leaves its row **blank**, not guessed
- [ ] **Test policy**, **Dev port** and **Base branch** lines are present; base branch matches `origin/HEAD`
- [ ] Re-running it does **not** overwrite the existing `CLAUDE.md` — it reports what a fresh scan would have written
- [ ] The closing message points at `/compass:plan-feature` and mentions `/install-github-app` as optional

---

## The PIV loop

### `/compass:worktree self-test-piv` (from the main dir)
- [ ] `git worktree list` shows the new path; branch `feat/self-test-piv`
- [ ] In the worktree: `.env.local` is a **symlink**; `.worktree-port` holds a free port; deps installed from the lockfile
- [ ] It works with **no** `.claude/CLAUDE.md` present and with **no** `origin` remote — the script reads no config
- [ ] A `.claude/worktree-setup.sh` in the sandbox runs, with `WT_NAME`/`WT_DIR`/`WT_BRANCH`/`WT_PORT` exported; a failing hook warns but does not abort
- [ ] A fresh Claude session opens in the worktree

### `/compass:plan-feature "a version helper that returns the app version, with a unit test"`
Run it with a plain description — no story file, no tracker. That is the supported entry point.
- [ ] Notice asks for `/model opus` + plan mode
- [ ] Context loads inline (CLAUDE.md incl. the `## Commands` table, git state) — **no** `/compass:context` call
- [ ] The built-in `Explore` subagent spawns — **no** `codebase-explorer`
- [ ] Plan written to `.work/plans/…`; **no code written**; sections: Goal, Patterns, Files (table), Tasks (File/Action/Implement/Mirror/Validate), Validation, Acceptance criteria, Loop log

### `/compass:implement .work/plans/<plan>.md`
**Deliberate-failure check:** before running, add an obvious error to a file the plan lists as **UPDATE** (typed stack: `const _x: number = 'no';`; otherwise a line that fails `{lint_cmd}`/`{test_cmd}`).
- [ ] Per task: read target + verify plan refs → implement → `{type_check_cmd}`/`{test_cmd}`; pass → task `[x]`
- [ ] Under **Test policy** `first`, the test is run and **watched to fail** before the code is written
- [ ] Blank the `Type check` row and re-run: that gate disappears without an error. Blank the `Test` row: the policy behaves as `none`
- [ ] The deliberate error is caught (pre-read check or first type/lint run) and triggers a **fix loop**, not a skip
- [ ] Final `/compass:validate` suite runs; report written to `.work/reports/…`; browser-smoke screenshot in `.work/screenshots/` (web sandbox) or ⏭ (non-web)
- [ ] The deliberate error is gone at the end
- [ ] `## Loop log` in the plan has at least one delta line

### `/code-review` (before shipping)
- [ ] `/compass:implement`'s closing output points at `/code-review` **before** `/compass:ship`
- [ ] It picks up the project's *Review conventions* from `.claude/CLAUDE.md`
- [ ] Findings are fixed on the branch, then `/compass:validate` is re-run — no PR exists yet
- [ ] **Staleness guard:** edit a source file *without* re-validating, then run `/compass:ship` — its pre-flight must notice the file is newer than the report and re-run `/compass:validate` before committing

### `/compass:ship`
- [ ] Reads the report; `/compass:commit` shows status/diff, proposes a Conventional Commit, **waits for confirmation**; pushes; opens a PR with the template body
- [ ] `## Manual Test Plan` checklist is in the PR body
- [ ] The closing message names the review options and `/compass:fix-ci-review` — compass itself runs **no** review and posts **no** GitHub comment
- [ ] No `Co-Authored-By` trailer anywhere

---

## Fix — after review

The PR from the loop above is open. `/code-review` already ran on the branch in Loop 1 — this stage tests what comes back **from the PR**.

### claude-code-action on the PR
Requires `/install-github-app` and the `ANTHROPIC_API_KEY` secret. Push a change carrying a **real finding**.
- [ ] With `claude-code-review.yml` installed, the action runs on the push (`synchronize`) without being asked
- [ ] With only `claude.yml` installed, it runs after commenting `@claude review this`
- [ ] The action posts inline review comments on the PR
- [ ] A rule added to `.claude/CLAUDE.md` → *Review conventions* is reflected in the review
- [ ] `/compass:fix-ci-review` reads those comments (`gh pr view --comments` + the inline API), lists them, and **waits for confirmation**
- [ ] Fixes are applied **locally**; `/compass:validate` runs; the command **stops** without committing
- [ ] Disagreeing with a finding flags it for the author instead of forcing a change
- [ ] **Stop at three:** a finding that resists three attempts switches to root-cause mode instead of a fourth patch

---

## Quick Path — trivial change (parallel worktree)

Second terminal, from the main dir:

### `/compass:worktree self-test-quick`
- [ ] `git worktree list` shows 3 paths (main + PIV + Quick); both worktrees run without conflict

### Manual 1-line edit → `/compass:validate` → `/compass:ship`
Make a one-line edit (a comment or a string). No plan, no `/compass:implement`.
- [ ] `/compass:validate` shows the 4-check table (lint/types/tests/browser); failures cite file + line
- [ ] `/compass:ship` opens a PR with a compact body; **no** plan or report was created in the Quick worktree

---

## Worktree lifecycle — guarded `rm`

From the main dir, after the PRs are merged (or to abort):
- [ ] `/compass:worktree self-test-piv rm` with uncommitted changes → **refuses** (changes nothing)
- [ ] with commits not merged into `base_branch` → **refuses**, message notes pushed-vs-local-only
- [ ] `… rm --force` → removes dir + branch; or after merge, plain `… rm` removes via safe `git branch -d`
- [ ] `git worktree list` shows only main; `git worktree prune` is idempotent

---

## End-to-end verification

- [ ] `git worktree list` → only main
- [ ] `.work/{plans,reports,screenshots}` populated; **no** `prds/` or `stories/` directory was created
- [ ] `gh pr list --state all` → the PIV PR and the Quick-Path PR are visible
- [ ] No compass-generated workflow appears in `.github/workflows/`
- [ ] `bash scripts/selftest.sh` still exits 0 against the plugin clone

---

## Cost estimate

Local commands cost normal session tokens. compass ships no CI, so it triggers no Actions minutes and no API calls of its own. If claude-code-action is installed, its review is billed by Anthropic per PR run and re-charged on each push that re-triggers it.

---

## Abort / cleanup

```bash
# worktrees (guarded; --force if you mean it)
bash ${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh self-test-piv rm
bash ${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh self-test-quick rm

# close test PRs instead of merging
gh pr list --search "head:feat/self-test" --state open
gh pr close <number>

# the whole sandbox
gh repo delete <owner>/compass-sandbox --yes   # or just delete the local dir
```
