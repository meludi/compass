---
description: Set up claude-workflow-starter for a new project
---

# /setup — Project Setup

> **Model:** `/model sonnet` — balanced model for this command.

Configure this Claude workflow for your project. Run once after copying the starter into your project. Runs in two phases — same command both times.

**What it does:**
1. Phase 1 — writes `.claude/project.yml` with defaults, asks you to fill it in
2. Phase 2 — validates `.claude/project.yml`, generates `.claude/CLAUDE.md`

---

## Phase Detection

Read `.claude/project.yml`.

- `name: ""` (empty) → **run Phase 1**
- `name` has a value → **run Phase 2**

---

## Phase 1 — Prepare the config

The canonical template is the **shipped `.claude/project.yml`** — it carries the
schema reference (`# yaml-language-server: $schema=./project.schema.json`) and
inline docs. **Do not rewrite or duplicate it** (no embedded copy lives here, on
purpose). Edit it in place. If the file is somehow missing, restore it from the
starter.

**Pre-fill what can be detected** — leave the rest for the user:

- `package_manager` — from the lockfile (`pnpm-lock.yaml`→pnpm, `yarn.lock`→yarn, `bun.lockb`→bun, else npm).
- `dev_cmd` / `test_cmd` / `lint_cmd` / `format_cmd` / `type_check_cmd` — from the matching `package.json` script when it exists (e.g. set `npm run lint` only if a `lint` script is present); **blank** the field if there is no matching script. This keeps `project.yml` an accurate snapshot instead of guessing. Skip for non-JS projects (no `package.json`) — the user fills `install_cmd` and commands manually.
- `repo` — from `git remote get-url origin` (as `owner/repo`).
- `base_branch` — the repo's current default branch.

Then output:

```
.claude/project.yml is ready (schema-validated, commands taken from package.json).
Fill in: name, description — and anything detection left blank.
Then run /setup again.
```

Stop. Do not proceed to Phase 2.

---

## Phase 2 — Validate + Generate

### Step 1 — Validate against the schema

Validate `.claude/project.yml` against `.claude/project.schema.json` — that file
is the single source of validation rules (required keys, enums, types, the
`repo` `owner/repo` pattern, `dev_port` integer). Collect **all** violations
before reporting; do not stop at the first.

If any errors exist, output them all at once and stop:

```
Validation failed — fix the following in .claude/project.yml:

  - package_manager: "npmp" is not valid. Must be one of: npm, pnpm, yarn, bun
  - dev_port: "abc" is not an integer
  - repo: "my-app" must match owner/repo
```

Do not generate CLAUDE.md until all errors are resolved.

### Step 2 — Sanity-check commands

The command fields were taken from `package.json` in Phase 1, but the schema
cannot confirm they actually run. Briefly confirm they look right:

```
Commands (from package.json — verify they run):
  dev: {dev_cmd} · test: {test_cmd} · lint: {lint_cmd} · format: {format_cmd} · types: {type_check_cmd or "—"}
```

### Step 3 — Generate `.claude/CLAUDE.md`

Read `.claude/CLAUDE-template.md`. Generate `CLAUDE.md` in two phases:

**Fill immediately** (from `project.yml` + codebase scan):
- Project description — from `description` field
- Tech stack — scan existing files (package.json, lock files, config files)
- Commands — from `dev_cmd`, `test_cmd`, `lint_cmd`, `format_cmd`, `type_check_cmd`
- Directory structure, key files — scan existing files (brownfield); leave as placeholder (greenfield)

**Mark as TODO** (not enough context yet):
- Code Patterns (Naming, Error Handling, File Organization)
- Architecture details
- Testing patterns

Mark these sections explicitly as `TODO: update after first feature` — do not invent or leave blank.

Do not modify `CLAUDE-template.md` — it stays as the reusable source.

### Step 4 — Confirm

```
Project configured:
  Name:     {name}
  Repo:     {repo}
  Branch:   {base_branch}
  Test:     {test_cmd}
  Dev:      {dev_cmd} on :{dev_port}

Generated: .claude/CLAUDE.md
  ✓ Filled:  description, tech stack, commands, directory structure
  ~ TODO:    code patterns, architecture details, testing patterns
             → update after your first feature

Next: run /ideate — brain dump with the agent; it writes the spec.
```
