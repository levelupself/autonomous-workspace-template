---
name: codebase-explorer
description: >
  Read-only exploration of the codebase. Maps structure, finds patterns,
  identifies relevant files. Use before writing any implementation to
  understand existing conventions. Cannot modify files.
allowed-tools: Read, Glob, Grep, Bash
---

# Codebase-Explorer Skill

Explore the codebase without modifying anything.

## Usage

```
/codebase-explorer <question or area to explore>
```

## What this does

Runs a structured read-only analysis to answer a question about the codebase.

## Step 1 — Map relevant structure

```bash
# Top-level structure
find . -maxdepth 3 -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \
  | grep -v node_modules | grep -v .git | head -60

# Find files related to the query
grep -r "$ARGUMENTS" . --include="*.ts" --include="*.js" --include="*.py" \
  -l 2>/dev/null | grep -v node_modules | head -20
```

## Step 2 — Read key files

For each relevant file found:
- Read it completely if under 200 lines
- Read first 100 lines if larger, note it needs deeper reading

## Step 3 — Identify patterns

Document:
- Naming conventions (files, functions, variables)
- Import patterns (how modules are imported)
- Testing patterns (how tests are structured)
- Error handling patterns
- Any existing similar implementations

## Step 4 — Write findings report

Return a structured report:

```markdown
## Codebase exploration: <query>

### Relevant files
- `<path>` — <what it contains>

### Existing patterns
- <pattern>: <example from codebase>

### Conventions to follow
- <convention>

### Potential reuse
- <existing code/function> could be used for <purpose>

### Nothing found
<if no relevant patterns exist, state clearly so agent knows to implement from scratch>
```

## Constraints

- NEVER write, edit, or create files
- NEVER run commands that modify state (no git commits, no npm install, etc.)
- Only read and analyze
