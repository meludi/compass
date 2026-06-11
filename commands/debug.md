---
description: Find the root cause of a failure before fixing it — four-phase investigation with a 3-fix boundary
argument-hint: <symptom | failing test | error message>
---

# /compass:debug — Root-cause a failure

> **Model:** `/model sonnet` — balanced model for investigation.

Diagnose a failing test, red CI check, or runtime error **before** changing code. Enforces the discipline in `${CLAUDE_PLUGIN_ROOT}/references/DEBUGGING.md`: no fix without a root cause, one hypothesis at a time, and a hard stop after three failed attempts.

Use this when "just fix it" already failed once — an obvious one-line cause doesn't need it.

## Input

`/compass:debug <symptom | failing test | error message>`

Without an argument, use the most recent failure in context (last validation/CI output).

## Steps

Follow the four phases from `references/DEBUGGING.md` — read it if not already loaded.

### 1. Root-cause investigation

- Read the full error and stack trace; reproduce with the smallest reliable command.
- Check what changed recently (`git log`/`git diff` on the failing area).
- Trace the data backward from the symptom to where it first goes wrong. Gather evidence; don't assume.

### 2. Pattern analysis

Find a working example of the same operation in the repo (search `src_dir` from `.claude/compass.yml`). Compare it against the broken path and list every difference.

### 3. Hypothesis and testing

State **one** theory ("X fails because Y"). Test it with the smallest change, one variable at a time. If it doesn't hold, form a new one — never stack fixes.

### 4. Implementation

- Write a failing test that captures the bug (verify-RED), then apply **one** root-cause fix.
- Re-run the proof command and confirm green — report from fresh output (`references/HANDBOOK.md` → *Verification before completion*).

### 3-fix boundary

If three distinct fix attempts on the same problem fail, **stop**. Don't try a fourth. Re-open Phase 1 with what the failures ruled out, or hand back to the user with the evidence — the problem is likely structural. Patching past this point is churn.

### Record it

If a plan exists for this work, append one delta line to its `## Loop log` (`.work/plans/{feature}.plan.md`): the root cause and the fix — "tried X — failed because Y" landmines only, not a restatement.

## Output

- The root cause, in one sentence.
- The single fix applied (or, if at the 3-fix boundary, the evidence and why it's likely structural).
- Validation result from a fresh run.

## Rules

- **No fix without a root cause** — never change code on a guess.
- **One hypothesis at a time** — never stack multiple fixes in one change.
- **Stop at three** — three failed attempts means re-investigate, don't keep patching.
- **Never auto-commit** — hand back after the fix is validated; the user commits.
