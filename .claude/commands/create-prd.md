---
description: Generate a Product Requirements Document from conversation context
argument-hint: <feature name or description>
---

# /create-prd — Generate Product Requirements Document

> **Note:** For new initiatives, use `/ideate` — it covers the full flow:
> brain dump → scope check → approaches → design approval → spec → self-review → handoff.
>
> `/create-prd` remains available for quick PRDs without the ideation flow.

> **Recommended:** `/model opus` + Plan Mode (`/plan`) — deep thinking for spec work, no accidental execution.

Generate a PRD from the current conversation context. Use this before `/create-stories` or `/feature-plan`.

## Input

`/create-prd <feature name or description>`

Or run after a conversation where the feature has been discussed.

## Steps

### 1. Extract context

From the conversation, identify:

- What problem is being solved
- Who benefits (user-facing or developer workflow)
- What the MVP scope is
- What is explicitly out of scope

### 2. Ask clarifying questions (if needed)

Only ask if critical information is missing:

- What is the success criterion?
- Are there constraints (performance, DB schema, existing UI)?

### 3. Propose approaches (if a real choice exists)

Before writing the spec, present 2–3 approaches for the core design decision.

**Approach A — {name}:** {one sentence}. Trade-off: {the flaw}
**Approach B — {name}:** {one sentence}. Trade-off: {the flaw}
**Approach C (optional):** …

**Recommendation:** Approach {X} — {why it's the least-bad option}

Wait for user confirmation before proceeding. If they pick a different approach, note it and continue with their choice.

Skip this step if there is only one sensible approach.

### 4. Generate PRD

Save to `.work/prds/{kebab-case-name}.prd.md`:

```markdown
# PRD: {Feature Name}

## Summary

{2-3 sentences: what, why, for whom}

## Problem

{What breaks or is missing today}

## Goal

{One measurable outcome}

## In scope

- {item}

## Out of scope

- {item}

## User stories

- As a user, I want to {action} so that {benefit}

## Acceptance criteria

- [ ] {criterion}

## Technical notes

{Stack constraints, existing patterns to follow, DB changes needed}

## Phases

1. MVP: {minimal viable version}
2. (optional) Follow-up: {enhancements}
```

### 5. Spec self-review

After writing the PRD, review it before handing off:

1. **Placeholder scan** — any "TBD", "TODO", "…", or empty sections? Fill or remove.
2. **Internal consistency** — do any sections contradict each other? Does the goal match the acceptance criteria?
3. **Ambiguity check** — can any requirement be interpreted two ways? Pick one, make it explicit.
4. **Scope check** — is this focused enough for one initiative, or does it need decomposition?

Fix issues inline. No re-review loop — just fix and move on.

### 6. Output

```
PRD saved to .work/prds/{name}.prd.md
→ Next: /setup-stack (greenfield) or /create-stories
```
