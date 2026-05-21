---
description: Evolve the system based on learnings — run after a merge, a bug, or anytime
---

# /reflect — System Reflection

> **Recommended:** `/model sonnet` — balanced model for this command.

Guided session to improve the system based on what you've learned. Runs the Self-Healing Loop:
`BUG / DEVIATION / GAP → RULE → system gets smarter`.

Run anytime: after a merge, after a frustrating session, after a bug, or periodically.

---

## Step 1 — Choose scope

Ask the user:

```
What do you want to reflect on?

1. Quick fix — you know exactly what needs updating, describe it
2. Post-feature — what deviated, what was missing, what should become a rule
3. Deep review — full system audit: CLAUDE.md, commands, reference docs
```

---

## Scope 1: Quick Fix

User describes the issue directly. Skip the questionnaire.

1. Identify the target: CLAUDE.md rule, command in `.claude/commands/`, or reference doc in `.claude/reference/`
2. Propose the exact change
3. Wait for confirmation, then apply + commit

---

## Scope 2: Post-Feature

Ask these questions one at a time:

1. **Deviations** — Did the agent follow the plan? If not: what did it do instead, and in which file/step?
2. **Repeated mistakes** — Did you have to correct the same thing more than once?
3. **Missing context** — Was there information the agent didn't have that would have helped?
4. **New patterns** — Did this feature establish a pattern worth documenting (naming, structure, approach)?
5. **Missing commands** — Was there a repeated action that should become a slash command?

For each non-empty answer, propose a concrete change:
- Deviation → update the relevant command in `.claude/commands/`
- Repeated mistake → add a rule to `CLAUDE.md`
- Missing context → create a doc in `.claude/reference/`, add to On-Demand Context table
- New pattern → update Architecture or Code Patterns section in `CLAUDE.md`
- Missing command → draft a new command, ask if the user wants to create it

---

## Scope 3: Deep Review

Systematically go through each area. For each, read the current state and ask if anything needs updating:

1. **`CLAUDE.md`** — Project overview accurate? Patterns still correct? Key files up to date?
2. **Commands** — Any command that felt off, too verbose, or missing a rule?
3. **`reference/`** — Any topic that grew complex enough to deserve its own doc?
4. **`project.yml`** — Commands still correct? DB file, prefix still right?
5. **`.work/BACKLOG.md`** — Anything to add, close, or reprioritize?

---

## Final step (all scopes)

1. Show all proposed changes as a diff-style summary
2. Wait for confirmation
3. Apply confirmed changes
4. Commit: `docs: reflect — <one-line summary of what changed>`
