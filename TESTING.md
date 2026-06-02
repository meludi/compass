# Starter self-test

End-to-end test of the workflow this starter ships. It exercises all four flows from `.claude/reference/WORKFLOW.md` against a throwaway **sandbox project** with a real GitHub remote:

```
Stage 0 — Setup        /setup → [/setup-tracker] → /ideate → [/setup-stack] → /create-stories
Loop 1 — PIV           /worktree → /plan-feature → /implement → /ship → /reflect
Loop 2 — Fix           review → fix → /validate → /commit → push   (mode off: local · review-only: CI)
Quick Path             /worktree → edit → /validate → /ship
+ worktree lifecycle   /worktree <name> rm   (guarded)
```

**How to use:** work top to bottom, tick each box after it passes. Keep a `reflect-notes.md` open and log every deviation as a one-liner — feed it to `/reflect` (Scope 3) at the end. This file is for the starter maintainer; it is **not** copied into user projects (it lives at the repo root, outside `.claude/`).

> Commands are written stack-agnostically as `{test_cmd}` / `{lint_cmd}` / `{type_check_cmd}` / `{dev_cmd}` — substitute your sandbox's `project.yml` values. **Browser-smoke** (`agent-browser`, folded into `/validate` and `/implement`) needs a web app with a running dev server; on a non-web sandbox it skips gracefully (⏭) — that's expected.

---

## Prerequisites

- [ ] `gh` authenticated (`gh auth status`)
- [ ] Node + your package manager installed
- [ ] An `ANTHROPIC_API_KEY` available (needed for the `review-only` part of Loop 2)
- [ ] Budget awareness: each `review-only` PR costs ~$0.03 (see `.claude/reference/AUTONOMY.md` → Cost estimate)

---

## Sandbox bootstrap

A fresh repo so the test never touches a real project.

**Recommended stack: minimal Next.js** — so `{dev_cmd}` + browser-smoke are real. Lighter alternative: a minimal TS-Node + Vitest project (faster CI; browser-smoke is skipped). Either works; the test is about the *workflow*, not the app.

1. **Create the project + repo**
   ```bash
   # example: minimal Next.js
   npx create-next-app@latest starter-sandbox --ts --eslint --app --no-tailwind --no-src-dir --use-npm
   cd starter-sandbox
   gh repo create starter-sandbox --private --source=. --remote=origin --push
   ```
2. **Drop the starter in** — copy from this repo into the sandbox:
   ```bash
   cp -R <starter>/.claude .claude
   cp -R <starter>/.github .github
   cp <starter>/.mcp.json .mcp.json
   ```
3. **Configure** — `/setup` (twice: fill `project.yml`, then generate `CLAUDE.md`). Set `base_branch: main`.
4. **CI secret + protection**
   ```bash
   gh secret set ANTHROPIC_API_KEY
   ```
   GitHub → Settings → Branches → require the `test` status check on `main` (and `claude-review` + `claude-checklist` once you switch to `review-only`).

- [ ] Sandbox repo exists on GitHub, `main` pushed
- [ ] `.claude/`, `.github/`, `.mcp.json` present; `/setup` produced `project.yml` + `CLAUDE.md`
- [ ] `ANTHROPIC_API_KEY` secret set; branch protection requires `test`

---

## Stage 0 — Setup (once per initiative)

### `/setup`
- [ ] Phase 1 writes `project.yml` with all inline comments; stops
- [ ] After filling `name`/`repo`, Phase 2 validates (catches a bad `package_manager`/`dev_port`) and generates `CLAUDE.md` (code-pattern sections marked `TODO: update after first feature`)

### `/setup-tracker` _(optional)_
- [ ] Run only if testing Jira/Azure; otherwise skip (Linear is default)

### `/ideate "Self-test feature"`
Suggested feature (small, one PIV pass): **"a `version` helper that returns the app version, with a unit test"** (web sandbox: also render it somewhere for browser-smoke).
- [ ] Notice asks for `/model opus` + plan mode; waits for "go"
- [ ] Clarifying questions come **one at a time**, then 2–3 approaches, then design sections with yes/revise
- [ ] PRD written to `.work/prds/…`; no `TBD`/`TODO`/`…` left; closing points to `/create-stories`

### `/setup-stack` _(greenfield only)_ — skip for the sandbox (already scaffolded).

### `/create-stories .work/prds/<prd>.md`
- [ ] Stories written to `.work/stories/…`; each has testable acceptance criteria
- [ ] Linear prompt → answer **no/skip**; command ends cleanly (does not silently continue)

---

## Loop 1 — PIV (per story)

### `/worktree self-test-piv` (from the main dir)
- [ ] `git worktree list` shows the new path; branch `feat/self-test-piv`
- [ ] In the worktree: `.env.local` is a **symlink**; `.worktree-port` exists with `dev_port + N`; deps installed (via `package_manager` or `install_cmd`)
- [ ] DB/state isolation present if configured (`db_file` copied per worktree)
- [ ] A fresh Claude session opens in the worktree

### `/plan-feature .work/stories/<story>.md` (in the worktree session)
- [ ] Notice asks for `/model opus` + plan mode; context loads; `codebase-explorer` spawns
- [ ] Plan written to `.work/plans/…`; **no code written**; sections: Goal, Patterns, Files (table), Tasks (File/Action/Implement/Mirror/Validate), Validation, Acceptance criteria

### `/implement .work/plans/<plan>.md`
**Deliberate-failure check:** before running, add an obvious error to a file the plan lists as **UPDATE** (typed stack: `const _x: number = 'no';`; otherwise a line that fails `{lint_cmd}`/`{test_cmd}`).
- [ ] Per task: read target + verify plan refs → implement → `{type_check_cmd}`/`{test_cmd}`; pass → task `[x]`
- [ ] The deliberate error is caught (pre-read check or first type/lint run) and triggers a **fix loop**, not a skip
- [ ] Final `/validate` suite runs; report written to `.work/reports/…`; browser-smoke screenshot in `.work/screenshots/` (web sandbox) or ⏭ (non-web)
- [ ] The deliberate error is gone at the end

### `/ship`
- [ ] Reads the report; `/commit` shows status/diff, proposes a Conventional Commit, **waits for confirmation**; pushes; opens a PR with the template body (Summary/Changes/Manual Test Plan/Notes)
- [ ] `## Manual Test Plan` checklist is in the PR body (from `/ship`, mode-independent)
- [ ] "Run code review now?" → **yes** → 3 subagents run; verdict inline; **no** GitHub comment posted; **no** `Co-Authored-By`
- [ ] No `/security-review` auto-trigger for a non-risky diff

### `/reflect` (Scope 2 — Post-Feature)
- [ ] 5 questions come **one at a time**; empty answers produce no diff; confirmation before any apply

---

## Loop 2 — Fix (until the PR is clean) — both modes

The PR from Loop 1 is open. This is the same loop in two modes; run both.

### Mode A — `autonomy_mode: off` (local)
With `off` in `project.yml`, intentionally leave/introduce a fixable issue, then:
- [ ] `/code-review` (or `/code-review --fix`) surfaces it locally; you apply the fix
- [ ] `/validate` green → `/commit` → `git push`
- [ ] On GitHub, only the **`test`** job runs (no Claude jobs); merge is yours
- [ ] "Clean" is your own judgement — no CI review comments appear

### Mode B — `autonomy_mode: review-only` (CI + API)
Set `autonomy_mode: review-only`, commit, push. Open (or update) a PR that carries a **real finding**.
- [ ] CI runs `test` + `claude-review` (inline comments) + `claude-checklist` (PR comment) + **one `## Review Summary`** comment
- [ ] GitHub notifies you; the `## Review Summary` states the finding count and the "fix locally, never by CI" reminder
- [ ] `/apply-ci-review` pulls the PR comments and applies fixes **locally** (no second review); it **stops before commit**
- [ ] `/validate` → `/commit` → `git push` → CI **re-reviews** automatically; repeat until the Summary reports no findings
- [ ] CI never commits; the merge is yours

> No `autonomy_mode: full` test here — auto-merge belongs only in a disposable sandbox with a label gate, and is out of this guide's default path.

---

## Quick Path — trivial change (parallel worktree)

Second terminal, from the main dir:
### `/worktree self-test-quick`
- [ ] `git worktree list` shows 3 paths (main + PIV + Quick); both worktrees run without conflict

### Manual 1-line edit → `/validate` → `/ship`
Make a one-line edit (a comment or a string). No PRD/story/plan/`/implement`.
- [ ] `/validate` shows the 4-check table (lint/types/tests/browser); failures cite file + line
- [ ] `/ship` → "Run code review now?" → **no**
- [ ] PR opened with a compact body; **no** subagent review ran; **no** PRD/story/plan/report was created in the Quick worktree

---

## Worktree lifecycle — guarded `rm`

From the main dir, after the PRs are merged (or to abort):
- [ ] `/worktree self-test-piv rm` with uncommitted changes → **refuses** (changes nothing)
- [ ] with commits not merged into `base_branch` → **refuses**, message notes pushed-vs-local-only
- [ ] `… rm --force` → removes dir + branch; or after merge, plain `… rm` removes via safe `git branch -d`
- [ ] `git worktree list` shows only main; `git worktree prune` is idempotent

---

## End-to-end verification

- [ ] `git worktree list` → only main
- [ ] `.work/{prds,stories,plans,reports,screenshots}` populated
- [ ] `gh pr list --state all` → the PIV PR and the Quick-Path PR are visible
- [ ] `review-only` PR shows inline comments + a `## Review Summary` + the checklist comment
- [ ] `reflect-notes.md` holds the full findings list → run `/reflect` (Scope 3 — Deep Review) to fold them back into commands/docs

---

## Cost estimate

Local commands cost normal session tokens. The only CI/API cost is Loop 2 Mode B: ~$0.03 per `review-only` PR run (review + checklist), re-charged on each push that re-triggers the review. Budget a handful of pushes → well under $0.50.

---

## Abort / cleanup

```bash
# worktrees (guarded; --force if you mean it)
bash .claude/scripts/worktree.sh self-test-piv rm
bash .claude/scripts/worktree.sh self-test-quick rm

# close test PRs instead of merging
gh pr list --search "head:feat/self-test" --state open
gh pr close <number>

# the whole sandbox
gh repo delete <owner>/starter-sandbox --yes   # or just delete the local dir
```
