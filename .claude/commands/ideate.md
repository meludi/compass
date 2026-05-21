---
description: Structured brain dump — before /create-prd
---

# /ideate — Initiative Brain Dump

Guides the IDEATE step from Level 1 of the workflow. Goal: build a shared understanding of the initiative before writing a PRD.

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

## Step 1 — Invite the brain dump

```
Tell me everything about your initiative — unstructured, no format required.

What do you want to build? Why? What do you already have? What's giving you trouble?
Get it all out — raw ideas, fragments, contradictions. I'm listening.
```

Do not interrupt. No follow-up questions mid-dump. User talks, Claude listens.

---

## Step 2 — Suggest subagent research

After the brain dump: check whether any open questions can be answered through research.

If yes — propose concretely:

- Technology comparisons, library options → `"Should I send an agent to research X?"`
- Codebase patterns, existing implementations → `"Should I search the codebase for X?"`
- External resources, docs → `"Should I fetch the documentation for X?"`

Only suggest when genuinely relevant. No research overkill.

If no research needed: proceed directly to Step 3.

---

## Step 3 — Summary

Claude summarizes its understanding concisely:

- **What** is being built
- **Why** (problem / goal)
- **Known constraints** (technical, timeline, scope)
- **What is still unclear**

---

## Step 4 — Clarifying questions

Address only genuine gaps — no checklist, no completeness questions.

Ask one question at a time. Wait for the answer before asking the next.
If multiple gaps exist: prioritize — ask the most important first.

Typical categories:
- Scope boundaries: What is explicitly out of scope?
- Success criterion: How will you know it works?
- Technical constraints: Are there existing systems that affect this?

---

## Step 5 — Close

When the user is satisfied and no open questions remain:

```
Understood. We're aligned.

→ Next step: /create-prd — turns this conversation into a structured spec.
```
