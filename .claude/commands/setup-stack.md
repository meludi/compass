---
description: Scaffold the tech stack for a greenfield project — runs once, before the first /worktree
argument-hint: [path to .work/prds/*.prd.md]
---

# /setup-stack — Tech Stack Setup

> **Model:** `/model sonnet` — balanced model for this command.

Set up the tech stack for a new greenfield project. Run **once**, directly after `/ideate` and before `/create-stories`.

**What it does:**
1. Detects brownfield projects (guard)
2. Reads PRD for tech stack hints (if path provided)
3. Confirms framework and package manager
4. Scaffolds the project
5. Installs additional best-practice tooling
6. Asks 4 style decisions → records them in CLAUDE.md
7. Creates canonical seed files + a visible welcome screen + a first smoke test
8. Updates CLAUDE.md Code Patterns section
9. Updates `compass.yml` with actual commands
10. Verifies with lint + type check + smoke test, then boots the app to confirm it runs

**Input:** `$ARGUMENTS` — optional path to `.work/prds/*.prd.md`

---

## Brownfield Guard

Before anything else, check whether this is already an existing project:

```bash
ls package.json 2>/dev/null && find src -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' '
```

If `package.json` exists **and** `src/` contains more than 3 entries → warn:

```
This project already has source files. /setup-stack is designed for greenfield
projects (empty repos before scaffolding).

Running it on an existing codebase may overwrite your configuration.

Continue anyway? (yes/no)
```

Wait for explicit "yes" before continuing. On "no", stop.

Also check for previous runs: if `src/components/ui/Button.tsx` already exists, warn:

```
Seed files from a previous run detected. Re-running will overwrite them.
Continue? (yes/no)
```

---

## Step 1 — Read PRD for Tech Hints

If `$ARGUMENTS` is a file path:
- Read the file
- Find the `## Technical notes` section
- Extract technology names, framework references, stack constraints
- Store as `prd_tech_hints`

If no path given, or the section is empty: proceed silently with `prd_tech_hints = ""`.

---

## Step 2 — Framework Selection

If `prd_tech_hints` contains a recognizable framework name, pre-select it and confirm:

```
Based on your PRD I see: {hint}
→ Scaffold with Next.js App Router? (yes/change)
```

Otherwise, present the full menu:

```
Which framework should I scaffold?

1. Next.js App Router       — full-stack React, file-based routing
2. Vite + React             — SPA, client-side only
3. Express API              — Node.js REST API
4. Fastify API              — Node.js REST API, schema-first
5. Remix                    — full-stack React, loader/action pattern
6. SvelteKit                — full-stack Svelte
7. Other                    — I will enter the scaffold command manually
```

Wait for selection before continuing.

If "7 — Other": ask for the full scaffold command (e.g. `npx create-t3-app@latest`) and store it. The framework-specific sections in Steps 6–8 will use "Other" defaults.

---

## Step 3 — Package Manager

Read `package_manager` from `.claude/compass.yml`.

Ask:
```
Package manager: {value} — use this? (yes/change)
```

If blank, default to `npm`. If "change", accept: `npm | pnpm | yarn | bun`.

Store confirmed value as `pm` for use in Steps 4–10.

---

## Step 4 — Show Scaffold Plan and Confirm

Display the exact command before running anything:

```
Scaffold plan:
  Framework:  {selected framework}
  Command:    {exact scaffold command}
  Directory:  . (current directory)
  Package manager: {pm}

This will create files in the current directory.
Proceed? (yes/no)
```

**Scaffold commands per framework:**

| Framework | Command |
|-----------|---------|
| Next.js App Router | `npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-{pm}` |
| Vite + React | `npm create vite@latest . -- --template react-ts` |
| Express | `npx express-generator . --no-view` |
| Fastify | `npm create fastify@latest .` |
| Remix | `npx create-remix@latest .` |
| SvelteKit | `npx sv create .` |
| Other | the command the user provided |

If the current directory already has files and the scaffold tool typically refuses non-empty directories: offer to skip the scaffold step and proceed to Steps 6–10 (tooling + style only).

Wait for "yes" before running.

---

## Step 5 — Scaffold

Run the confirmed scaffold command. Show output inline.

After the command completes, verify:
```bash
ls package.json
```

If `package.json` is missing: stop and tell the user to resolve the scaffold failure, then re-run `/setup-stack`.

---

## Step 6 — Additional Tooling

Read `package.json` (devDependencies + dependencies). Check for gaps and install as needed.

Show planned additions **before** installing:

```
Additional tooling to install:
  + prettier          — not included in scaffold
  + clsx              — required by cn() utility
  + tailwind-merge    — required by cn() utility

Install these? (yes/no/customize)
```

Wait for confirmation. Do not install without "yes".

**What to check and when to install:**

| Tool | Install when |
|------|-------------|
| `prettier` | not in devDependencies |
| `vitest` + `@vitest/ui` | no test runner detected (no `jest`, `vitest`, `@jest/core` in deps) — skip for Next.js which includes Jest |
| `clsx` + `tailwind-merge` | Tailwind is present and neither package is already installed |

For Express/Fastify: also check for `typescript`, `ts-node`, `@types/node` — install if missing.

After installing, run `{pm} install` if the scaffold did not already do so.

---

## Step 7 — Style Decisions

Ask all 4 questions in a **single message** — not one at a time:

```
Four style decisions — these will be written to CLAUDE.md and reflected in seed files.
Answer with four letters, e.g. "a, a, a, a":

1. Component pattern
   a) Named declaration:  export function Button() {}
   b) Arrow function:     export const Button = () => {}

2. Folder structure
   a) Feature-based:  src/features/auth/LoginForm.tsx + src/features/auth/useAuth.ts
   b) Type-based:     src/components/LoginForm.tsx + src/hooks/useAuth.ts

3. Export style
   a) Named exports only (no export default — except Next.js route files)
   b) Default export for page/route components, named for everything else

4. {Framework-specific question — see table below}
```

**Question 4 by framework:**

| Framework | Question |
|-----------|---------|
| Next.js App Router | Server vs client: a) Server-first — add `"use client"` only when needed / b) Client-first — add `"use server"` only for actions |
| Vite + React | State management: a) React context only / b) Zustand / c) Props-only (no global state) |
| Express / Fastify | Error handling: a) Central error middleware / b) try/catch per handler |
| Remix | Data loading: a) Loader + action on every route / b) Only when route needs data |
| SvelteKit | Data loading: a) `+page.server.ts` for all data / b) Mix of server and universal loaders |
| Other | Skip Q4 |

Store answers as:
- `component_pattern`: `declaration` or `arrow`
- `folder_structure`: `feature` or `type`
- `export_style`: `named` or `mixed`
- `framework_specific`: the full text of the chosen answer

---

## Step 8 — Create Canonical Seed Files

Show planned files before creating. Wait for "yes".

```
Seed files to create:
  src/components/ui/Button.tsx   — canonical component
  src/lib/utils.ts               — canonical utility module
  {welcome screen}               — visible entry point, see table below
  {smoke test}                   — first runnable test for the welcome screen

The first three become the Mirror source for /plan-feature.
The welcome screen is what the user sees when they run the app (Step 12).
Create? (yes/no)
```

**File 1 — `src/components/ui/Button.tsx`**

Declaration variant (`component_pattern = declaration`):
```tsx
import { cn } from "@/lib/utils"

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost"
  size?: "sm" | "md" | "lg"
}

export function Button({ variant = "primary", size = "md", className, children, ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center rounded-md font-medium transition-colors",
        variant === "primary" && "bg-blue-600 text-white hover:bg-blue-700",
        variant === "secondary" && "bg-gray-100 text-gray-900 hover:bg-gray-200",
        variant === "ghost" && "hover:bg-gray-100",
        size === "sm" && "h-8 px-3 text-sm",
        size === "md" && "h-10 px-4",
        size === "lg" && "h-12 px-6 text-lg",
        className
      )}
      {...props}
    >
      {children}
    </button>
  )
}
```

Arrow variant (`component_pattern = arrow`) — replace the function line with:
```tsx
export const Button = ({ variant = "primary", size = "md", className, children, ...props }: ButtonProps): JSX.Element => {
  return ( ... )
}
```

**File 2 — `src/lib/utils.ts`**

Always uses named function declarations (utilities follow the same component_pattern):
```ts
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs))
}

export function formatDate(date: Date | string): string {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(new Date(date))
}
```

For arrow variant, use `export const cn = (...inputs: ClassValue[]): string =>` etc.

For non-Tailwind projects: omit `cn()`, keep `formatDate()` only.

**File 3 — Welcome screen (the visible entry point):**

This file is both the Mirror-source pattern example **and** a screen the user can actually see (frontend) or hit (backend) when the app runs in Step 12. Use the project `name` from `.claude/compass.yml` in the heading. Wire it into the app entry point so it shows on first run (replace the scaffold's default placeholder page).

| Framework | File | Content |
|-----------|------|---------|
| Next.js App Router | `src/app/page.tsx` | Welcome page — project name + `Button` |
| Vite + React | `src/App.tsx` + `src/hooks/useCounter.ts` | Welcome screen using `Button` + the `useCounter` hook |
| Express | `src/routes/welcome.ts` | Root `/` route returning a welcome HTML page |
| Fastify | `src/routes/welcome.ts` | Root `/` route returning a welcome HTML page |
| Remix | `app/routes/_index.tsx` | Welcome screen — loader + component |
| SvelteKit | `src/routes/+page.svelte` | Welcome screen |
| Other | (adapt) | A minimal welcome entry point for the chosen framework |

**Next.js `src/app/page.tsx`:**
```tsx
import { Button } from "@/components/ui/Button"

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 p-24">
      <h1 className="text-4xl font-bold">Welcome to {name}</h1>
      <p className="text-gray-600">Your app is running.</p>
      <Button>Get started</Button>
    </main>
  )
}
```
Note: `export default` is required by Next.js for page files — this is the documented exception to "named exports only".

**Vite + React** — replace the scaffold's `src/App.tsx`, keep the hook as a canonical example:
```tsx
// src/App.tsx
import { Button } from "@/components/ui/Button"
import { useCounter } from "@/hooks/useCounter"

export function App() {
  const { count, increment } = useCounter()
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6">
      <h1 className="text-4xl font-bold">Welcome to {name}</h1>
      <p className="text-gray-600">Your app is running.</p>
      <Button onClick={increment}>Clicked {count} times</Button>
    </main>
  )
}
```
```ts
// src/hooks/useCounter.ts
import { useState } from "react"

export function useCounter(initialValue = 0) {
  const [count, setCount] = useState(initialValue)

  function increment() { setCount(n => n + 1) }
  function decrement() { setCount(n => n - 1) }
  function reset() { setCount(initialValue) }

  return { count, increment, decrement, reset }
}
```
(For arrow variant, use arrow functions throughout. Ensure `src/main.tsx` imports `{ App }`.)

**Express `src/routes/welcome.ts`** (register on the app so `GET /` serves it):
```ts
import { Router, Request, Response } from "express"

export const welcomeRouter = Router()

welcomeRouter.get("/", (_req: Request, res: Response) => {
  res
    .type("html")
    .send("<h1>Welcome to {name}</h1><p>Your API is running.</p>")
})
```

**Fastify `src/routes/welcome.ts`:**
```ts
import { FastifyPluginAsync } from "fastify"

const welcomeRoute: FastifyPluginAsync = async (fastify) => {
  fastify.get("/", async (_req, reply) => {
    reply.type("text/html").send("<h1>Welcome to {name}</h1><p>Your API is running.</p>")
  })
}

export default welcomeRoute
```

For feature-based folder structure (`folder_structure = feature`): also create `src/features/.gitkeep` to establish the pattern.

**File 4 — Smoke test (first runnable test):**

One minimal test that proves the welcome entry point works — the first runnable test for the project. Use the project's test runner: **vitest** for most stacks, **Jest** for Next.js. If the minimal test deps are missing, show them and ask before installing (same confirm rule as Step 6):

- Frontend (Next.js / Vite / Remix): a render test via `@testing-library/react` (+ `jsdom` env for vitest) asserting the welcome heading renders.
- Backend (Express / Fastify): a request test — `fastify.inject({ method: "GET", url: "/" })` for Fastify; `supertest` for Express — asserting `GET /` returns 200 and the welcome text.

Representative frontend test (`src/App.test.tsx` for Vite, adapt the import for others):
```tsx
import { render, screen } from "@testing-library/react"
import { App } from "./App"

test("renders the welcome screen", () => {
  render(<App />)
  expect(screen.getByText(/welcome to/i)).toBeInTheDocument()
})
```

Keep it to a single assertion — this is a smoke test, not a coverage exercise. It becomes the Mirror source for how tests are written in this project.

---

## Step 9 — Update CLAUDE.md

Read `.claude/CLAUDE.md`. Find the `## Code Patterns` section.

If Code Patterns is already filled (no `TODO` marker): warn and offer options:
```
Code Patterns section appears to already have content.
a) Replace with generated content
b) Show diff and decide
c) Skip this section
```

Otherwise, replace the entire `## Code Patterns` section with the following, substituting based on style decision answers:

```markdown
## Code Patterns

### Naming Conventions

- Components: PascalCase — `Button`, `UserCard`
- Hooks: camelCase with `use` prefix — `useAuth`, `useModal`
- Utilities: camelCase — `formatDate`, `cn`
- Files: match the export name — `Button.tsx`, `useAuth.ts`
- Constants: SCREAMING_SNAKE_CASE for module-level constants

### Component Pattern

{if declaration}: Named function declaration — `export function ComponentName() {}`
{if arrow}: Arrow function — `export const ComponentName = (): JSX.Element => {}`

Mirror: `src/components/ui/Button.tsx`

### File Organization

{if feature-based}:
- Feature-based: `src/features/{domain}/{Component}.tsx` + `src/features/{domain}/use{Name}.ts`
- Shared UI: `src/components/ui/`
- Shared utilities: `src/lib/`
- Types: colocated as `{file}.types.ts` or in `src/types/`

{if type-based}:
- Type-based: `src/components/`, `src/hooks/`, `src/utils/` — organized by what it is
- No feature folders — co-location is by type, not domain

Mirror: `src/lib/utils.ts`

### Export Style

{if named}: Named exports only — no `export default`.
  Exception: Next.js route files (`page.tsx`, `layout.tsx`, `route.ts`) require default exports.
{if mixed}: Default export for page/route components, named exports for everything else.

### {Framework-specific heading}

{Q4 answer text}

Mirror: `{framework-specific seed file path}`
```

Also update these sections in CLAUDE.md from the actual installed state:
- `## Tech Stack` — read `package.json` dependencies, list the key libraries
- `## Architecture` — run `find src -type d | head -20` and update the directory tree
- `## Key Files` — add the seed files just created with one-line descriptions

Show the full intended changes as a diff before writing. Ask: "Write to CLAUDE.md? (yes/no)"

---

## Step 10 — Update compass.yml

Read `package.json` `scripts` section. Map to `compass.yml` fields:

| compass.yml field | package.json script name(s) |
|-------------------|-----------------------------|
| `dev_cmd` | `dev` |
| `test_cmd` | `test` |
| `lint_cmd` | `lint` |
| `format_cmd` | `format` |
| `type_check_cmd` | `typecheck`, `type-check`, `tsc` |

For each field: if the script exists, update to `{pm} run {script}` (or `{pm} {script}` for pnpm shortcuts). If not found, leave the current value unchanged.

If a script name is non-standard (not in the list above): show all detected script names and ask which to map to which field.

Show planned updates before applying:

```
compass.yml updates:
  dev_cmd:        {old}  →  {new}
  test_cmd:       {old}  →  {new}
  lint_cmd:       {old}  →  {new}
  format_cmd:     (unchanged)
  type_check_cmd: {old}  →  {new}

Apply? (yes/no)
```

Wait for "yes" before writing.

---

## Step 11 — Install CI workflow (optional)

Ask:

```
Install the CI workflow (.github/workflows/pr-validation.yml)?

The starter ships a PR-validation workflow with three modes:
  off          — pure CI (lint + types + tests). No API calls. Default.
  review-only  — adds Claude inline PR review + auto-generated test checklist.
  full         — adds auto-merge once all checks are green.

(yes / no — defaults to no)
```

If **no**: skip to Step 12.

If **yes**: ask which mode the project should start in. Default `off`. Update
`autonomy_mode` in `.claude/compass.yml` to the chosen value.

For `review-only` or `full`, also ask which LLM runs the CI review and write
`ci_review_provider` (default `claude`):

```
Which model runs the CI review?
  claude  — inline comments + checklist (recommended). Secret: ANTHROPIC_API_KEY
  openai  — single summary comment.                    Secret: OPENAI_API_KEY
  gemini  — single summary comment.                    Secret: GEMINI_API_KEY
```

The workflow file is already present in the starter at
`.github/workflows/pr-validation.yml` — no copy step needed unless the user
deleted it; if missing, restore from the starter.

For `review-only` or `full`, **verify the matching secret is present** before
finishing — otherwise the review job runs red on the first PR. Determine the
secret name from `ci_review_provider` (`claude`→`ANTHROPIC_API_KEY`,
`openai`→`OPENAI_API_KEY`, `gemini`→`GEMINI_API_KEY`) and check:

```bash
gh secret list | grep -q "^<SECRET_NAME>" && echo "present" || echo "MISSING"
```

(Requires `gh` authenticated and the repo to exist on GitHub. If `gh secret list`
errors — no remote yet — report that the secret can't be checked and move on.)

- **Present:** confirm and continue.
- **MISSING:** warn that the chosen mode will fail red until the secret is set,
  and tell the user to set it **themselves** — it is interactive (it prompts for
  the key value), so do **not** run it from here:

  ```
  ! gh secret set <SECRET_NAME>
  ```

  The `!` prefix runs it in this session so the user can paste the value. Claude
  never handles the raw key.

Full setup details (secrets, branch protection, costs, security
considerations) live in `.claude/compass/reference/AUTONOMY.md`.

---

## Step 12 — Verify and boot

Run lint, type check, and the smoke test (skip `type_check_cmd` if blank):

```bash
{lint_cmd}
{type_check_cmd}
{test_cmd}
```

Then run a **boot check** — prove the app actually starts, so the user inherits a working welcome screen, not just code that compiles:

- If a build command exists (`build` script in `package.json`): run it and confirm it succeeds.
- Otherwise start the dev server briefly and confirm it serves before stopping it:

```bash
{dev_cmd} &
DEV_PID=$!
sleep 5
curl -sf -o /dev/null "http://localhost:{dev_port}" && echo "boot: ok" || echo "boot: FAILED"
kill $DEV_PID
```

Report each result inline. If anything fails: show the errors and suggest a fix direction, but do not auto-fix.

**On success:**

```
Setup complete.

  Framework:   {framework}
  Style:       {component_pattern} declarations, {folder_structure} folders,
               {export_style} exports, {framework_specific summary}
  Seed files:  src/components/ui/Button.tsx
               src/lib/utils.ts
               {welcome screen}
               {smoke test}
  CLAUDE.md:   Code Patterns section filled
  compass.yml: Commands updated
  Lint:        ✓
  Types:       ✓
  Smoke test:  ✓
  Boot check:  ✓

See your welcome screen — run the app and open it:

  {dev_cmd}      then open http://localhost:{dev_port}

(Optional: use the agent-browser skill to capture a screenshot.)

The first three seed files are your Mirror source for /plan-feature.
```

**Commit checkpoint:** the scaffold is a consistent, describable unit ("scaffold {framework} stack with welcome screen and smoke test"). Suggest committing it before the first feature: `Run /commit to save the scaffold, then /worktree <first-story-name>?` Suggest only; never commit without confirmation.
