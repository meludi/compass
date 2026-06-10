# Review guidelines

Project-specific review conventions. CI appends this file to the code-review
prompt for every provider (see `ci_review_guidelines` in `.claude/compass.yml`).
**Edit it to match your project** — the items below are a sensible starting point,
not a finished policy. Safe to delete entirely; the review still runs with its
built-in criteria.

## Always flag

- Public API / exported-signature changes not reflected in callers, types, or docs.
- New I/O (network, filesystem, DB) without error handling or a timeout.
- Swallowed errors (empty catch, ignored rejected promises) or debug/`console.log` left in.
- Secrets, tokens, or credentials in code or fixtures.
- A new dependency for something the stack can already do.

## Prefer

- Clarity over cleverness — a reviewer should grasp the change without the author.
- Reuse of existing utilities and patterns over reinventing them.
- Small, focused functions and narrow public interfaces.

## Tests

- New behaviour has a test that asserts observable behaviour, not implementation.
- A bug fix has a test that fails without the fix.

## This project (fill in)

- <naming conventions, preferred libraries, patterns reviewers here always check>
