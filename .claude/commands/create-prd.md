---
description: Generate a Product Requirements Document from conversation context
argument-hint: <feature name or description>
---

# /create-prd — Generate Product Requirements Document

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

### 3. Generate PRD

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

### 4. Output

Report: PRD saved to `.work/prds/{name}.prd.md` — ready for `/create-stories` or `/feature-plan`.
