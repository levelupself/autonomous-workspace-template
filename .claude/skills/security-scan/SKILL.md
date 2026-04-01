---
name: security-scan
description: >
  Runs security analysis on changed files. Checks for hardcoded secrets,
  common vulnerabilities, and unsafe patterns. Use before opening a PR
  or completing a hardening stage. Reports findings to decisions.md.
allowed-tools: Bash, Read, Write, Glob
---

# Security-Scan Skill

Scan for security issues in the current changes.

## Usage

```
/security-scan [path]
```

Default path: all changed files vs main (`git diff --name-only main..HEAD`)

## Step 1 — Get files to scan

```bash
# Changed files in this branch
CHANGED=$(git diff --name-only main..HEAD 2>/dev/null | grep -v "^\.claude/")

# Or specific path if provided
TARGET="${ARGUMENTS:-$CHANGED}"
```

## Step 2 — Check for hardcoded secrets

```bash
# API keys, tokens, passwords in changed files
grep -rn \
  -E "(api_key|apikey|secret|password|passwd|token|bearer)\s*[=:]\s*['\"][^'\"]{8,}" \
  $TARGET 2>/dev/null \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.go" \
  | grep -v "process.env\|os.environ\|getenv\|secrets\." || echo "No hardcoded secrets found"
```

## Step 3 — Check for common vulnerabilities

Run pattern checks for:

**SQL injection patterns:**
```bash
grep -rn "query.*\$\{.*\}\|query.*\+.*req\." $TARGET 2>/dev/null || true
```

**Shell injection:**
```bash
grep -rn "exec.*req\.\|spawn.*req\.\|shell.*true" $TARGET 2>/dev/null || true
```

**Unsafe deserialization:**
```bash
grep -rn "eval(\|pickle.loads\|yaml.load(" $TARGET 2>/dev/null || true
```

**Path traversal:**
```bash
grep -rn "readFile.*req\.\|join.*req\." $TARGET 2>/dev/null || true
```

## Step 4 — Run semgrep (if available)

```bash
if command -v semgrep &>/dev/null; then
  semgrep --config=auto $TARGET --json 2>/dev/null | \
    jq -r '.results[] | "[\(.check_id)] \(.path):\(.start.line) \(.extra.message)"' \
    | head -20
else
  echo "semgrep not available — install with: pip install semgrep"
fi
```

## Step 5 — Write findings report

Append to `projects/<project>/docs/decisions.md`:

```markdown
### Security scan — <ISO8601>

**Files scanned:** <count>
**Issues found:** <count>

<if issues>
#### Findings

| Severity | File | Line | Issue |
|----------|------|------|-------|
| <HIGH/MED/LOW> | <file> | <n> | <description> |

#### Required fixes before PR merge
- [ ] <fix required>
```

If no issues found:
```markdown
### Security scan — <ISO8601>
**Result:** Clean — no issues found in <n> files scanned.
```

## Step 6 — Block PR if HIGH severity found

If any HIGH severity issues are found, output:
```
SECURITY_BLOCK: HIGH severity issues found — do not open PR until resolved
```

This signals the orchestrator to not invoke pr-opener.
