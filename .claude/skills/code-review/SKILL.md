---
name: code-review
description: Review local code changes for correctness, design, and style. Use whenever the user wants feedback on their changes before committing or opening a PR — no GitHub PR needed. Covers bug detection, architecture violations, CLAUDE.md compliance, and actionable findings with file:line references.
allowed-tools:
  - Bash(git diff*)
  - Bash(git status*)
  - Bash(git log*)
  - Bash(flutter analyze*)
  - Bash(dart analyze*)
  - Read
---

# Code Review

Review the current working changes for correctness, design, and style. Works on local diffs — no PR required.

## Steps

### 1. Gather the diff

```bash
git diff HEAD           # staged + unstaged changes vs last commit
git diff --stat HEAD    # file summary
```

If the working tree is clean, fall back to the last commit:
```bash
git diff HEAD~1 HEAD
```

### 2. Read changed files in full

For each changed file, read the whole file — not just the diff lines. You need the surrounding context to judge whether a change is correct. Also read any test files that cover the changed code.

### 3. Run static analysis

Detect the project type and run the linter:

```bash
# Flutter / Dart
flutter analyze 2>/dev/null || dart analyze 2>/dev/null
```

Treat linter errors as confirmed issues. Only surface warnings if they're in the changed lines and a senior engineer would flag them.

### 4. Check CLAUDE.md for project conventions

Read the root `CLAUDE.md` and any `CLAUDE.md` files inside directories of changed files. These define binding project conventions.

### 5. Review for issues

**Correctness**
- Logic errors, null/empty cases not handled, off-by-one
- Broken contracts with callers or violated API assumptions
- Race conditions, missing awaits, swallowed exceptions

**Design**
- Violations of the architecture described in CLAUDE.md
- Abstractions introduced before they're needed (three similar lines beats a premature helper)
- Scope creep — features added beyond what the change requires

**Style**
- Naming inconsistent with the codebase
- Comments that explain *what* instead of *why* (or are noise)
- Dead code, unused variables, backwards-compat shims for things that no longer exist

**Security** (flag only clear issues)
- User input used without validation at a system boundary
- Secrets or tokens hardcoded
- Obvious injection surfaces

### 6. Filter ruthlessly

Skip:
- Pre-existing issues not touched by this change
- Issues a linter or type-checker already caught
- Nitpicks a senior engineer wouldn't raise
- Style violations not mentioned in CLAUDE.md

Only report issues you're confident are real and worth fixing.

### 7. Output

```
## Code Review

### Critical (must fix before commit)
- **path/file.dart:42** — [what's wrong and why it matters]

### Important (should fix)
- **path/file.dart:17** — [brief description]

### Suggestions (optional)
- **path/file.dart:88** — [brief suggestion]

### Clean
- [files reviewed with no findings]
```

If nothing to report: `No issues found. Reviewed N files.`

Each finding: one or two sentences. Cite the exact location. Explain what's wrong — don't summarize what the code does.
