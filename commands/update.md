---
description: Reconcile the project config with the installed compass plugin after an update — refresh the schema, surface new/removed config keys, re-validate
---

# /compass:update — Sync project config with the installed plugin

> **Model:** `/model sonnet` — balanced model for this command.

Run this **after updating the compass plugin** to bring your project's `.claude/compass.yml` in line with the new plugin version: refresh the schema copy, surface config keys the update added (or removed), add the new ones on your confirmation, and re-validate.

> **Not the plugin update itself.** The plugin is updated with `/plugin update compass` (or `claude plugin marketplace update compass`). This command only reconciles your **project config** with whatever plugin version is already installed — it never installs or changes the plugin.

## Precondition

Read `.claude/compass.yml`. If it does not exist, this project was never set up — stop and tell the user:

```
No .claude/compass.yml found — run /compass:setup first.
```

## Steps

### 1. Refresh the schema copy

Copy `${CLAUDE_PLUGIN_ROOT}/compass.schema.json` → `.claude/compass.schema.json` (overwrite). This is the same step as `/compass:setup` Phase 1 Step 2 — it keeps the editor's autocomplete + inline validation matched to the installed plugin.

### 2. Diff the config keys

Read the top-level keys (flat `^key:` lines — the same flat convention `scripts/read-config.sh` relies on) from both:

- the plugin template `${CLAUDE_PLUGIN_ROOT}/templates/compass.yml`
- the project's `.claude/compass.yml`

Compute:

- **New keys** — present in the template, missing from the project config (config the update added).
- **Orphaned keys** — present in the project config but **not** in the template or schema (likely removed or renamed by the update).

### 3. Report

Show the diff. For each **new** key, take its default value and inline comment straight from the template:

```
New config keys in this plugin version:
  test_policy: first   # first | after | none — when/whether tests are written for logic tasks

Removed / unknown keys in your compass.yml:
  (none)
```

Call out **behaviour-changing** new keys explicitly (e.g. `test_policy`, `autonomy_mode`) — these change how compass works, not just stack details. Point to where they're documented (README Configuration section, `references/HANDBOOK.md`, or `references/AUTONOMY.md`).

If there are no new keys and no orphans, skip to Step 6 with an "already up to date" message.

### 4. Add the new keys (on confirmation)

Ask before writing. On confirmation, append each missing key to `.claude/compass.yml` with the **default value and inline comment from the template**, placed near its related section. This is **non-destructive**:

- Never change an existing key's value.
- Never reorder or reformat existing lines.
- Defaults match the template, so adding a key is a no-op for behaviour until the user changes it.

If the user declines, leave the config untouched — the keys still fall back to their defaults at runtime; this only means they won't be visible in the file.

### 5. Orphaned keys — report only

List orphaned keys but **do not remove them** (destructive — the user's call; a key may be intentional or a typo to fix). Re-validation in Step 6 will flag invalid ones anyway (the schema is `additionalProperties: false`).

### 6. Re-validate

Validate `.claude/compass.yml` against the refreshed `${CLAUDE_PLUGIN_ROOT}/compass.schema.json` — same as `/compass:setup` Phase 2 Step 1. Collect **all** violations before reporting; do not stop at the first.

```
Validation failed — fix the following in .claude/compass.yml:

  - package_manager: "npmp" is not valid. Must be one of: npm, pnpm, yarn, bun
```

### 7. Summary

```
compass config synced with the installed plugin:
  Schema:   refreshed
  Added:    test_policy (default: first)
  Removed:  none
  Review:   test_policy changes how /compass:implement tests logic tasks
            → README Configuration / references/HANDBOOK.md

Config is schema-valid.
```

If nothing changed:

```
compass config is already up to date with the installed plugin — nothing to add.
```
