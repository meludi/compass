# compass self-test

End-to-end test of the workflow this plugin ships. It exercises all four flows from `${CLAUDE_PLUGIN_ROOT}/references/WORKFLOW.md` against a throwaway **sandbox project** with a real GitHub remote:

```
Dry-run (static)       bash scripts/selftest.sh         (manifests, schema, doc links, shell — no human/GitHub needed)
Stage 0 — Plugin check claude plugin details   (well-formed: ~21 cmds, 3 agents, 1 hook, 0 MCP servers)
Stage 1 — Setup        /compass:setup → [/compass:setup-tracker] → /compass:ideate → [/compass:setup-stack] → /compass:create-stories
Loop 1 — PIV           /compass:worktree → /compass:plan-feature → /compass:implement → /compass:ship → /compass:reflect
Loop 2 — Fix           review → fix → /compass:validate → /compass:commit → push   (mode off: local · review-only: CI)
Auto-fix flows         Claude native auto-fix · Codex external reviewer            (optional, per ecosystem)
Quick Path             /compass:worktree → edit → /compass:validate → /compass:ship
+ worktree lifecycle   /compass:worktree <name> rm   (guarded)
```

**How to use:** work top to bottom, tick each box after it passes. Keep a `reflect-notes.md` open and log every deviation as a one-liner — feed it to `/compass:reflect` (Scope 3) at the end. This file is for the compass maintainer. It ships with the plugin (it lives at the repo root) but is **not** a loaded component — zero runtime cost.

> Commands are written stack-agnostically as `{test_cmd}` / `{lint_cmd}` / `{type_check_cmd}` / `{dev_cmd}` — substitute your sandbox's `compass.yml` values. **Browser-smoke** (`agent-browser`, folded into `/compass:validate` and `/compass:implement`) needs a web app with a running dev server; on a non-web sandbox it skips gracefully (⏭) — that's expected.

---

## Installing compass

`<compass>` below = the path to your clone of this repo, e.g. `/Users/meludi/Work/projects/works/compass`.

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
- [ ] An `ANTHROPIC_API_KEY` available (needed for the `review-only` part of Loop 2; if `ci_review_provider` is `openai`/`gemini`, use that provider's key instead)
- [ ] Budget awareness: each `review-only` PR costs ~$0.03 (see `${CLAUDE_PLUGIN_ROOT}/references/AUTONOMY.md` → Cost estimate)
- [ ] _(Auto-fix Flow A, optional)_ Claude Code client with auto-fix available (`/autofix-pr` or the CI-status-bar toggle)
- [ ] _(Auto-fix Flow B, optional)_ Codex connected to the sandbox repo (OpenAI plan) — see `${CLAUDE_PLUGIN_ROOT}/references/AUTONOMY.md` → *Delegating review + fix to an external reviewer (Codex)*

---

## Dry-run first — `scripts/selftest.sh`

Before any of the manual stages, run the static dry-run from the repo root:

```bash
bash scripts/selftest.sh
```

It validates everything that needs no human: JSON manifests, template YAML,
`compass.yml` keys vs the schema, the CI workflow's jobs, shell syntax, doc-link and
`${CLAUDE_PLUGIN_ROOT}` reference integrity, code-fence balance, and the component
inventory. Exit 0 = all green; it changes nothing. Fix any `FAIL` before spending
time (or API budget) on the manual run below.

- [ ] `bash scripts/selftest.sh` exits 0 (all PASS)

---

## Stage 0 — Plugin loads & is well-formed

Before the sandbox, confirm Claude Code accepts the plugin. Register this clone as a
local marketplace, install it, and inspect the component inventory (let `<compass>` be
this clone's path):

```bash
claude plugin marketplace add <compass>
claude plugin install compass@compass
claude plugin details compass
```

Good if you see:
- `compass <version>` with its description line
- `Skills (~21)`, `Agents (3)`, `Hooks (1) SessionStart`, and **`MCP servers (0)`**
  — the `0` matters: the plugin must **not** force a tracker MCP server on every install

Clean up afterwards (so your global config is unchanged):

```bash
claude plugin uninstall compass
claude plugin marketplace remove compass
```

- [ ] Inventory correct; **0 MCP servers**; SessionStart hook present

---

## Sandbox bootstrap

A fresh repo so the test never touches a real project.

**Recommended stack: minimal Next.js** — so `{dev_cmd}` + browser-smoke are real. Lighter alternative: a minimal TS-Node + Vitest project (faster CI; browser-smoke is skipped). Either works; the test is about the *workflow*, not the app.

1. **Create the project + repo**
   ```bash
   # example: minimal Next.js
   npx create-next-app@latest compass-sandbox --ts --eslint --app --no-tailwind --no-src-dir --use-npm
   cd compass-sandbox
   gh repo create compass-sandbox --private --source=. --remote=origin --push
   ```
2. **Load the plugin** — launch Claude in the sandbox with compass loaded from your clone (nothing is copied in):
   ```bash
   claude --plugin-dir <path-to-compass-clone>
   ```
   The `/compass:*` commands and the SessionStart hook should be available. (Alternatively install via `/plugin marketplace add <path-to-compass-clone>` then `/plugin install compass@compass`.)
3. **Configure** — `/compass:setup` (generates `.claude/compass.yml`, `.claude/compass.schema.json`, and `.claude/CLAUDE.md`). Set `base_branch: main`.
4. **CI secret + protection**
   ```bash
   gh secret set ANTHROPIC_API_KEY
   ```
   GitHub → Settings → Branches → require the `test` status check on `main` (and `CI review` + `CI checklist` once you switch to `review-only`).

- [ ] Sandbox repo exists on GitHub, `main` pushed
- [ ] Plugin loaded (`/compass:*` commands + SessionStart hook present); `/compass:setup` produced `.claude/compass.yml` + `.claude/compass.schema.json` + `.claude/CLAUDE.md`
- [ ] `ANTHROPIC_API_KEY` secret set; branch protection requires `test`

---

## Stage 1 — Setup (once per initiative)

### `/compass:setup`
- [ ] Phase 1 writes `compass.yml` with all inline comments; stops
- [ ] After filling `name`/`repo`, Phase 2 validates (catches a bad `package_manager`/`dev_port`) and generates `CLAUDE.md` (code-pattern sections marked `TODO: update after first feature`)

### `/compass:setup-tracker` _(optional)_
- [ ] Run only if testing Jira/Azure; otherwise skip (Linear is default)

### `/compass:ideate "Self-test feature"`
Suggested feature (small, one PIV pass): **"a `version` helper that returns the app version, with a unit test"** (web sandbox: also render it somewhere for browser-smoke).
- [ ] Notice asks for `/model opus` + plan mode; waits for "go"
- [ ] Clarifying questions come **one at a time**, then 2–3 approaches, then design sections with yes/revise
- [ ] PRD written to `.work/prds/…`; no `TBD`/`TODO`/`…` left; closing points to `/compass:create-stories`

### `/compass:setup-stack` _(greenfield only)_ — skip for the sandbox (already scaffolded).

### `/compass:create-stories .work/prds/<prd>.md`
- [ ] Stories written to `.work/stories/…`; each has testable acceptance criteria
- [ ] Linear prompt → answer **no/skip**; command ends cleanly (does not silently continue)

---

## Loop 1 — PIV (per story)

### `/compass:worktree self-test-piv` (from the main dir)
- [ ] `git worktree list` shows the new path; branch `feat/self-test-piv`
- [ ] In the worktree: `.env.local` is a **symlink**; `.worktree-port` exists with `dev_port + N`; deps installed (via `package_manager` or `install_cmd`)
- [ ] DB/state isolation present if configured (`db_file` copied per worktree)
- [ ] A fresh Claude session opens in the worktree

### `/compass:plan-feature .work/stories/<story>.md` (in the worktree session)
- [ ] Notice asks for `/model opus` + plan mode; context loads; `codebase-explorer` spawns
- [ ] Plan written to `.work/plans/…`; **no code written**; sections: Goal, Patterns, Files (table), Tasks (File/Action/Implement/Mirror/Validate), Validation, Acceptance criteria

### `/compass:implement .work/plans/<plan>.md`
**Deliberate-failure check:** before running, add an obvious error to a file the plan lists as **UPDATE** (typed stack: `const _x: number = 'no';`; otherwise a line that fails `{lint_cmd}`/`{test_cmd}`).
- [ ] Per task: read target + verify plan refs → implement → `{type_check_cmd}`/`{test_cmd}`; pass → task `[x]`
- [ ] The deliberate error is caught (pre-read check or first type/lint run) and triggers a **fix loop**, not a skip
- [ ] Final `/compass:validate` suite runs; report written to `.work/reports/…`; browser-smoke screenshot in `.work/screenshots/` (web sandbox) or ⏭ (non-web)
- [ ] The deliberate error is gone at the end

### `/compass:ship`
- [ ] Reads the report; `/compass:commit` shows status/diff, proposes a Conventional Commit, **waits for confirmation**; pushes; opens a PR with the template body (Summary/Changes/Manual Test Plan/Notes)
- [ ] `## Manual Test Plan` checklist is in the PR body (from `/compass:ship`, mode-independent)
- [ ] "Run code review now?" → **yes** → 3 subagents run; verdict inline; **no** GitHub comment posted; **no** `Co-Authored-By`
- [ ] No `/compass:review-security` auto-trigger for a non-risky diff

### `/compass:reflect` (Scope 2 — Post-Feature)
- [ ] 5 questions come **one at a time**; empty answers produce no diff; confirmation before any apply

---

## Loop 2 — Fix (until the PR is clean) — both modes

The PR from Loop 1 is open. This is the same loop in two modes; run both.

### Mode A — `autonomy_mode: off` (local)
With `off` in `compass.yml`, intentionally leave/introduce a fixable issue, then:
- [ ] `/compass:review-code` (or `/compass:review-code --fix`) surfaces it locally; you apply the fix
- [ ] `/compass:validate` green → `/compass:commit` → `git push`
- [ ] On GitHub, only the **`test`** job runs (no Claude jobs); merge is yours
- [ ] "Clean" is your own judgement — no CI review comments appear

### Mode B — `autonomy_mode: review-only` (CI + API)
Set `autonomy_mode: review-only`, commit, push. Open (or update) a PR that carries a **real finding**.
- [ ] CI runs `test` + `ci-review` (inline comments) + `ci-checklist` (PR comment) + **one `## Review Summary`** comment
- [ ] GitHub notifies you; the `## Review Summary` states the finding count and the "fix locally, never by CI" reminder
- [ ] `/compass:fix-ci-review` pulls the PR comments and applies fixes **locally** (no second review); it **stops before commit**
- [ ] `/compass:validate` → `/compass:commit` → `git push` → CI **re-reviews** automatically; repeat until the Summary reports no findings
- [ ] CI never commits; the merge is yours

> No `autonomy_mode: full` test here — auto-merge belongs only in a disposable sandbox with a label gate, and is out of this guide's default path.

---

## Auto-fix the PR — both flows (optional, per ecosystem)

These exercise the **autonomous post-PR fix loop** (beyond Loop 2's manual fixing). Both need the open PR from Loop 1 and an external capability — run whichever you have set up. `autofix_max_pushes` brakes both; set it small (e.g. `2`) in `compass.yml` to test the brake quickly. See `${CLAUDE_PLUGIN_ROOT}/references/AUTONOMY.md` → *Auto-fix the PR loop*.

### Flow A — Claude native auto-fix (toggle / `/autofix-pr`)
Requires the Claude Code client feature. Give the PR a **red `test` check** (introduce a failing test/lint):
- [ ] Enable auto-fix — `/autofix-pr` (terminal) or the **auto-fix** toggle in the CI status bar (Desktop/web). Needs `gh` authenticated
- [ ] Claude reads the red check + review comments and **pushes a fix commit from your client** (author = you; CI itself never commits)
- [ ] CI re-runs on the push; on green the loop stops; `/compass:status` reports the state
- [ ] **Brake:** with `autofix_max_pushes: 2` and an issue small fixes can't resolve, after 2 pushes `autofix-guard` goes **red** + posts one `## Auto-fix stopped`; `/compass:status` → `escalated`
- [ ] Only one fixer runs (no `@codex fix` in parallel)

### Flow B — Codex external reviewer (`autonomy_mode: off`)
Requires Codex connected to the sandbox repo (OpenAI plan) and Claude auto-fix **off**. Set `autonomy_mode: off`:
- [ ] On a PR with a real finding, **compass posts nothing** — only the `test` job runs (no `ci-review`/`ci-checklist`)
- [ ] Codex auto-reviews (or `@codex review`) → inline P0/P1 comments appear
- [ ] `@codex fix <the issue>` → Codex **pushes a fix** to the branch; the `test` gate re-runs
- [ ] A rule added to `AGENTS.md` is reflected in Codex's review (its equivalent of `ci_review_guidelines`)
- [ ] **Brake:** `autofix-guard` counts Codex's pushes too — at the cap it trips with `## Auto-fix stopped`
- [ ] **One fixer:** Claude auto-fix stays **off** (running both = churn/races)

> Skip the flow whose ecosystem you don't have — they're add-ons to the manual Loop 2, not required for a workflow pass.

---

## Quick Path — trivial change (parallel worktree)

Second terminal, from the main dir:
### `/compass:worktree self-test-quick`
- [ ] `git worktree list` shows 3 paths (main + PIV + Quick); both worktrees run without conflict

### Manual 1-line edit → `/compass:validate` → `/compass:ship`
Make a one-line edit (a comment or a string). No PRD/story/plan/`/compass:implement`.
- [ ] `/compass:validate` shows the 4-check table (lint/types/tests/browser); failures cite file + line
- [ ] `/compass:ship` → "Run code review now?" → **no**
- [ ] PR opened with a compact body; **no** subagent review ran; **no** PRD/story/plan/report was created in the Quick worktree

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
- [ ] `.work/{prds,stories,plans,reports,screenshots}` populated
- [ ] `gh pr list --state all` → the PIV PR and the Quick-Path PR are visible
- [ ] `review-only` PR shows inline comments + a `## Review Summary` + the checklist comment
- [ ] `reflect-notes.md` holds the full findings list → run `/compass:reflect` (Scope 3 — Deep Review) to fold them back into commands/docs

---

## Cost estimate

Local commands cost normal session tokens. The only CI/API cost is Loop 2 Mode B: ~$0.03 per `review-only` PR run (review + checklist), re-charged on each push that re-triggers the review. Budget a handful of pushes → well under $0.50.

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
