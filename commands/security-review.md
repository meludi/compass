---
description: Security review of code changes
argument-hint: [file-or-directory]
---

# /compass:security-review

> **Model:** `/model opus` — deep analysis for security review.

Perform a security-focused code review on the specified files, directory, or staged changes.

**Input**: $ARGUMENTS (defaults to staged git changes if no path provided)

**When to run**: Auto-triggered by `/compass:ship`'s review step — or run manually on specific files.

---

## Phase 1: SCOPE

Determine what to review:

1. If a file path is given, review that file
2. If a directory is given, review all source files in it
3. If no input, review staged git changes: `git diff --cached --name-only`
4. If nothing staged, review unstaged changes: `git diff --name-only`

---

## Phase 2: ANALYZE

### Check Each Category

#### 1. Injection Vulnerabilities
- **SQL Injection**: Raw SQL with string concatenation — use parameterized queries / ORM only
- **Command Injection**: `exec()`, `spawn()`, shell calls with user input
- **XSS**: Unescaped user input in templates or `dangerouslySetInnerHTML`
- **Path Traversal**: User input in file paths without sanitization

#### 2. Authentication & Authorization
- Missing auth checks on API / route handlers
- Hardcoded credentials, tokens, or API keys in source
- Missing CSRF protection on state-changing endpoints
- Overly permissive CORS configuration
- Token handling and redirect URI validation in OAuth flows

#### 3. Data Exposure
- Sensitive data in logs
- API responses leaking internal data (stack traces, schema details)
- Secrets in source code
- Missing input validation at API/system boundaries
- Data returned to the wrong user / missing authorization checks

#### 4. Dependency & Configuration
- Known vulnerable dependencies (check lock file / `package.json`)
- Debug mode or dev-only flags enabled in production paths
- Missing security headers

#### 5. Error Handling
- Verbose error messages exposing internals
- Unhandled promise rejections
- Catch blocks that swallow errors silently

---

## Phase 3: REPORT

For each finding:

```markdown
### [SEVERITY] Finding Title

**Category**: Injection | Auth | Data Exposure | Dependency | Error Handling
**Severity**: Critical | High | Medium | Low | Info
**File**: `path/to/file.ts:LINE`

**Issue**: What the problem is

**Risk**: What could go wrong

**Fix**:
```ts
// Suggested fix
```
```

| Severity | Meaning | Action |
|----------|---------|--------|
| Critical | Exploitable, data breach risk | Block merge, fix immediately |
| High | Significant weakness | Fix before merge |
| Medium | Defense-in-depth issue | Fix soon, OK to merge with tracking |
| Low | Best practice deviation | Address when convenient |
| Info | Observation, no immediate risk | Consider later |

---

## Phase 4: SUMMARY

```markdown
## Security Review Complete

**Scope**: {files reviewed}
**Findings**: {total}

| Severity | Count |
|----------|-------|
| Critical | {n} |
| High     | {n} |
| Medium   | {n} |
| Low      | {n} |

### Verdict
{PASS | PASS WITH NOTES | FAIL}

### Action Items
1. {Most important fix}
2. ...

### What Looks Good
- {Positive patterns}
```

**Note:** Output is inline in the conversation. Do NOT post to GitHub unless explicitly asked.
