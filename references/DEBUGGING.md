# Debugging

How to fix a failure without guessing. A blunt retry loop — change something, re-run, hope — burns the auto-fix budget and lands changes nobody understands. This is the reasoning discipline behind `/compass:debug`, and the per-finding analog of the `autofix_max_pushes` brake in `AUTONOMY.md`.

> **No fix without a root cause.** Don't change code until you can name what is actually wrong.

The flow is four phases, then a hard boundary.

---

## The four phases

### 1. Root-cause investigation

Understand the failure before touching anything.

- **Read the actual error** — the full message and stack trace, not a paraphrase. The first failing line is rarely the root.
- **Reproduce it reliably** — find the smallest command or input that triggers it every time. An intermittent repro means you don't understand it yet.
- **Look at what changed** — recent commits, new deps, config. `git log`/`git diff` on the failing area.
- **Trace backward** — follow the data from the symptom toward where it first goes wrong, across module/service boundaries. Gather evidence (logs, values), don't assume.

### 2. Pattern analysis

The codebase usually already does the thing correctly somewhere.

- Find a **working example** of the same operation in the repo.
- Compare it against the broken path line by line — note **every** difference, however small.
- Make the dependency and configuration assumptions explicit; a difference you dismissed is often the cause.

### 3. Hypothesis and testing

- State **one** specific theory: "X fails because Y."
- Test it with the **smallest possible change**, one variable at a time.
- It holds or it doesn't — if not, form a new hypothesis. **Never stack fixes** ("change these three things and see"); you lose which one mattered.

### 4. Implementation

- Write a **failing test that captures the bug** first (verify-RED — see `HANDBOOK.md` → *Test quality*). It proves the diagnosis and prevents regression.
- Apply **one** fix at the root cause — not a patch over the symptom.
- Re-run the proof command and confirm green (see `HANDBOOK.md` → *Verification before completion*).

---

## The 3-fix boundary

**After three failed fix attempts on the same problem, STOP.** Don't try a fourth variation.

Three misses means the model of the problem is wrong, not the patch — the bug is likely structural (an architectural assumption, a boundary you haven't questioned). Step back: re-open Phase 1 with what the failures ruled out, or hand back to a human with the evidence so far. Patching past this point produces churn and changes nobody can explain.

In the autonomous PR loop this boundary is the reasoning-level counterpart to `autofix_max_pushes`: the push-count cap (`AUTONOMY.md` → *Auto-fix the PR loop*) is the blunt outer brake; the 3-fix boundary is the discipline that should stop you well before it trips.

---

## When to reach for this

- A test or the validation suite fails and the cause isn't obvious.
- CI is red and `/compass:fix-ci-review`'s first pass didn't hold.
- The same fix has bounced twice — switch from patching to `/compass:debug`.

For a clean reproducible failure with an obvious one-line cause, just fix it. This is for when "just fix it" already failed once.
