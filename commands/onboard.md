---
description: Onboard an existing (brownfield) project — scan the codebase and fill CLAUDE.md with real patterns. Use when adding compass to a project that already has source code.
argument-hint: [--refresh]
---

# /compass:onboard — Brownfield Project Onboarding

> **Model:** `/model opus` — deep codebase analysis.

Add compass to a project that already has source code. Unlike `/compass:setup` (which
marks Code Patterns / Architecture / Testing as `TODO: update after first feature`),
`/compass:onboard` reads the actual codebase and fills those sections now.

**`--refresh`** — re-run the scan on an already-onboarded project to update `CLAUDE.md`
as the codebase evolves. Safe to repeat.

---

## Pre-condition

Check whether compass is already configured:

- `.claude/compass.yml` missing **or** `name: ""` → run `/compass:setup` (both phases)
  first, then continue below.
- Already configured → skip straight to the scan.

---

## Codebase Scan

### 1 — Architecture

```bash
find . -maxdepth 3 -type d \
  \( -name src -o -name app -o -name lib -o -name api \
     -o -name components -o -name features -o -name pages \
     -o -name services -o -name controllers -o -name models \
     -o -name tests -o -name __tests__ \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' | sort
```

Identify the organising principle:

| Pattern | Signal |
|---|---|
| Feature-based | `features/<name>/` or `modules/<name>/` grouping |
| Layered | separate `services/`, `controllers/`, `repositories/`, `models/` |
| MVC | `routes/` or `controllers/` + `views/` |
| Component-based | flat `components/` with co-located styles/tests |
| Domain-driven | top-level domain directories with internal layers |

Write 1–3 sentences: what the pattern is and how data/requests flow.

### 2 — Tech Stack

```bash
cat package.json 2>/dev/null | head -60
cat pyproject.toml 2>/dev/null | head -40
cat go.mod 2>/dev/null | head -20
cat Cargo.toml 2>/dev/null | head -20
```

Note: language/runtime, framework, test runner, linter, formatter. This supplements
(do not duplicate) what `/compass:setup` already put in `compass.yml`.

### 3 — Code Patterns

Find 3–5 representative source files (preferably one component/class, one utility,
one route/handler):

```bash
# JS/TS: sample a component and a utility
find src -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -v test | head -10
# Python: sample a service and a model
find . -name "*.py" -not -path '*/migrations/*' -not -path '*/__pycache__/*' 2>/dev/null | head -10
```

Read the sampled files. Extract:

| Pattern | What to look for |
|---|---|
| **Naming** | camelCase / snake_case / PascalCase for files, functions, variables |
| **Component style** | named function declaration vs arrow function (`export const X = () =>`) |
| **Export style** | named-only / default for routes+pages / mixed |
| **Error handling** | try/catch / Result type / throws / explicit error returns |
| **File organisation** | import order (external → internal → relative), co-location of tests/styles |

Write concrete, brief rules (e.g. "Arrow functions for all components. Named exports only — exception: Next.js page files use default export.").

### 4 — Testing Patterns

```bash
# find test files and the test runner config
find . \( -name "*.test.*" -o -name "*.spec.*" -o -name "jest.config.*" \
          -o -name "vitest.config.*" -o -name "pytest.ini" -o -name "conftest.py" \) \
  -not -path '*/node_modules/*' 2>/dev/null | head -20
```

Read 2–3 test files. Note:

- **Runner** — Jest / Vitest / pytest / Go test / etc.
- **Location** — co-located (`*.test.ts` next to source) / collected (`__tests__/` or `tests/`)
- **What tests exercise** — behaviour + acceptance criteria / implementation details / snapshot tests
- **Mocking approach** — mocks at the module boundary / integration hits real DB / etc.

Write 2–4 bullet-point rules.

### 5 — Key Files

Identify up to 8 files a new contributor should know about: entry points, root
config, the most-touched module, the DB schema or data model, CI workflow.

```bash
# entry points and root configs
ls -1 src/index.* app/page.* main.* server.* 2>/dev/null
ls -1 *.config.* .env.example Makefile docker-compose.yml 2>/dev/null
```

---

## Write into CLAUDE.md

Open `.claude/CLAUDE.md`. For each section below, **replace the placeholder / TODO
content** (do not append — overwrite that section only):

- **Architecture** — your findings from Step 1
- **Code Patterns** — Naming Conventions, Component/Function style, Export style,
  Error Handling, File Organisation from Step 3
- **Testing** — runner, location, exercise-style, mocking from Step 4
- **Key Files** — table from Step 5 (File | Purpose)
- **Tech Stack** — update/confirm from Step 2 if setup left any rows incomplete

Leave all other sections (Project Overview, Commands, Validation, Project Context,
Notes) exactly as they are.

---

## Output Summary

```
/compass:onboard complete

Filled:
  ✓ Architecture     — {pattern inferred, e.g. "feature-based"}
  ✓ Code Patterns    — {N conventions extracted from N files}
  ✓ Testing          — {runner} / {location} / {exercise style}
  ✓ Key Files        — {N rows}
  ✓ Tech Stack       — {any additions}

Couldn't infer (left as-is or TODO):
  ~ {list anything that needed code that wasn't found}

Next: review .claude/CLAUDE.md — adjust anything the scan got wrong, then
run /compass:ideate to start your first initiative.
```

---

## Rules

- **Read-only scan** — never modify source files, only `.claude/CLAUDE.md`.
- **Replace, not append** — overwrite only the scanned sections; leave the rest untouched.
- **Brownfield, not scaffold** — no new files, no style questions, no seed components.
  That is `/compass:setup-stack`.
- **Honest about gaps** — if a pattern can't be inferred, say so rather than inventing.
