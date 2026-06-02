---
description: Structured brain dump → PRD — runs once per initiative, before /create-stories
argument-hint: <initiative name or description>
---

# /ideate — Initiative Brain Dump + PRD

> **Model:** `/model opus` + Plan Mode (`/plan`) — deep thinking, no accidental execution.

Full ideation flow for a new initiative or epic. Covers brain dump, research, scope check, clarifying questions, approaches, incremental design approval, and writes the PRD — all in one session.

**Output:** `.work/prds/{name}.prd.md` — ready for `/setup-stack` (greenfield) or `/create-stories`

---

## Notice

Output this first, before anything else:

```
Recommended for this command:
  Model:     /model opus   — deep thinking for structured ideation
  Plan Mode: /plan         — prevents accidental execution

Ready? Go ahead.
```

Wait until the user signals they are ready.

---

## Step 1 — Load project context

Before the conversation starts, read silently:
- `.claude/CLAUDE.md` — conventions, stack, patterns
- `.claude/project.yml` — commands, repo, base branch
- Recent commits: `git log --oneline -10`
- Existing PRDs in `.work/prds/` — are there related specs?

Use this context to inform questions and the final PRD.

---

## Step 2 — Invite the brain dump

**If the initiative was already discussed in depth earlier in this conversation**, a fresh brain dump is redundant. Summarize what you already understand and ask:

```
I have enough context from our conversation to write the spec directly.
Skip the brain dump and go to clarifying questions? (yes/no)
```

On "yes", jump to Step 6. On "no", or if there is no prior context, invite the brain dump:

```
Tell me everything about your initiative — unstructured, no format required.

What do you want to build? Why? What do you already have? What's giving you trouble?
Get it all out — raw ideas, fragments, contradictions. I'm listening.
```

Do not interrupt. No follow-up questions mid-dump. User talks, Claude listens.

---

## Step 3 — Scope check

Before asking any questions, assess scope: is this one initiative or multiple independent subsystems?

If too large (e.g. "platform with chat, billing, analytics, and user management"):

```
This is too large for a single PRD. Let's decompose first:
  — {Subsystem A}
  — {Subsystem B}
  — {Subsystem C}

Which piece should we tackle first?
```

Wait for answer, then continue with the selected subsystem only.

For appropriately-scoped initiatives: proceed to Step 4.

---

## Step 4 — Suggest subagent research

Check whether any open questions can be answered through research.

If yes — propose concretely:
- Technology comparisons, library options → `"Should I send an agent to research X?"`
- Codebase patterns, existing implementations → `"Should I search the codebase for X?"`
- External resources, docs → `"Should I fetch the documentation for X?"`

Only suggest when genuinely relevant. No research overkill.

If no research needed: proceed to Step 5.

---

## Step 5 — Visual Companion offer _(skip for non-visual topics)_

Only offer when the initiative involves UI, layouts, or architecture diagrams. Skip for pure backend/API/CLI projects.

This offer is its own message — do not combine with questions or summaries:

```
Some topics we'll cover might be easier to discuss visually —
mockups, diagrams, layout comparisons. I can create these using Excalidraw.

Want visual support? (yes/no)
```

Wait for response before continuing.

**If "yes":** use `mcp__excalidraw__create_view` / `mcp__excalidraw__export_to_excalidraw` for questions that are genuinely visual. Decide per question:
- **Visual:** UI mockups, wireframes, layout comparisons, architecture diagrams
- **Terminal:** requirements, scope decisions, tradeoffs, A/B options as text

**If "no":** proceed to Step 6.

---

## Step 6 — Summary

Summarize understanding concisely:

- **What** is being built
- **Why** (problem / goal)
- **Known constraints** (technical, timeline, scope)
- **What is still unclear**

---

## Step 7 — Clarifying questions — one at a time

Address only genuine gaps — no checklist, no completeness questions.

**One question per message. Wait for the answer before asking the next.**
If multiple gaps exist: prioritize — ask the most important first.

Typical categories:
- Scope boundaries: What is explicitly out of scope?
- Success criterion: How will you know it works?
- Technical constraints: Are there existing systems that affect this?

---

## Step 8 — Propose 2–3 approaches

Before writing anything, present options for the core design decision.
Skip if there is only one sensible approach.

```
Approach A — {name}: {one sentence}. Trade-off: {the flaw}
Approach B — {name}: {one sentence}. Trade-off: {the flaw}
Approach C (optional): …

Recommendation: Approach X — {why it's the least-bad option}
```

Wait for confirmation. If the user picks a different approach, note it and proceed with their choice.

---

## Step 9 — Present design sections + incremental approval

Present sections one at a time. After each: "Does this look right? (yes/revise)"

Scale each section to its complexity — a few sentences if straightforward, up to 200 words if nuanced.

Sections:
1. **Architecture overview** — overall structure, key components
2. **Components / modules** — what gets built, what already exists
3. **Data flow** — how data moves through the system
4. **Error handling** — failure modes and how they're handled
5. **Testing approach** — unit, integration, E2E

On "revise": update and re-present that section before moving on.

---

## Step 10 — Write PRD

Based on the approved design, save to `.work/prds/{kebab-case-name}.prd.md`:

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
{Include the chosen approach from Step 8 and its rationale}

## Phases

1. MVP: {minimal viable version}
2. (optional) Follow-up: {enhancements}
```

---

## Step 11 — Spec self-review

After writing, review with fresh eyes before handing off:

1. **Placeholder scan** — any "TBD", "TODO", "…", or empty sections? Fill or remove.
2. **Internal consistency** — do any sections contradict each other? Does the goal match the acceptance criteria?
3. **Ambiguity check** — can any requirement be interpreted two ways? Pick one, make it explicit.
4. **Scope check** — is this focused enough for one initiative, or does it need decomposition?

Fix issues inline. No re-review loop — just fix and move on.

---

## Step 12 — User review + close

```
PRD saved: .work/prds/{name}.prd.md
Please review — any changes? (yes/looks good)
```

If changes requested: update PRD and re-run Step 11.

When approved:

```
Aligned.

→ Next: /setup-stack (greenfield) or /create-stories
```
