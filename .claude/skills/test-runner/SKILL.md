---
name: test-runner
description: >
  Runs the project test suite and returns a structured pass/fail summary.
  Detects test framework automatically (jest, pytest, vitest, go test, etc).
  Use before marking any stage complete or opening a PR.
allowed-tools: Bash, Read, Glob
---

# Test-Runner Skill

Run the test suite and return a structured result.

## Step 1 — Detect test framework

```bash
# Check for common test configs
ls package.json pytest.ini setup.py go.mod Makefile 2>/dev/null
cat package.json 2>/dev/null | jq -r '.scripts.test // ""'
```

| File found | Framework | Command |
|-----------|-----------|---------|
| package.json with jest | Jest | `npm test -- --passWithNoTests` |
| package.json with vitest | Vitest | `npx vitest run` |
| pytest.ini or setup.py | Pytest | `python -m pytest -v` |
| go.mod | Go | `go test ./...` |
| Makefile with test target | Make | `make test` |

If no framework detected, check `projects/<project>/CLAUDE.md` for
`## Testing` section.

## Step 2 — Run tests with timeout

```bash
timeout 300 <test-command> 2>&1 | tee /tmp/test-output.txt
TEST_EXIT=$?
```

## Step 3 — Parse results

Extract from output:
- Total tests run
- Passing count
- Failing count
- Failing test names and error messages

## Step 4 — Write structured summary

Output a summary in this format for the calling agent:

```
TEST RESULTS — <project> — <ISO8601>

Framework: <detected framework>
Command: <command run>
Duration: <seconds>s

✓ Passing: <n>
✗ Failing: <n>
○ Skipped: <n>

Status: PASS | FAIL

<if FAIL>
Failing tests:
- <test name>: <error message first line>
- <test name>: <error message first line>

Full output: /tmp/test-output.txt
```

## Step 5 — Handle timeout

If tests time out after 300 seconds:
- Report as TIMEOUT
- List what was running when timeout occurred
- Recommend the calling agent write a `test_failure_loop` blocker
