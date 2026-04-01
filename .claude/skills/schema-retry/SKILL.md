---
name: schema-retry
description: >
  Retries a failing command or API call with exponential backoff and jitter.
  Configurable max attempts, base delay, and cap. Use when dealing with
  flaky external services (SchemaRegistry, APIs, databases during startup).
  Created by skill-writer to resolve data-pipeline connector blocker.
allowed-tools: Bash
---

# Schema-Retry Skill

Wrap any command with exponential backoff retry logic.

## Usage

```bash
/schema-retry "<command>" [max_attempts] [base_delay_ms] [cap_ms]
```

Or use the script directly:
```bash
.claude/skills/schema-retry/scripts/retry.sh "<command>" 3 500 10000
```

## Arguments

`$ARGUMENTS` — format: `"<command>" [max=3] [base_ms=500] [cap_ms=10000]`

## Defaults

| Parameter | Default | Notes |
|-----------|---------|-------|
| max_attempts | 3 | Total attempts including first |
| base_delay_ms | 500 | First retry waits ~500ms |
| cap_ms | 10000 | Max wait between retries |

## Algorithm

```
wait = min(cap, base * 2^attempt) + random(0, base * 0.1)
```

Full jitter prevents thundering herd on shared services.

## Example

```bash
# Retry kafka schema registry check up to 5 times
.claude/skills/schema-retry/scripts/retry.sh \
  "curl -sf http://schema-registry:8081/subjects" \
  5 1000 15000
```

## Exit codes

- 0 — command succeeded within allowed attempts
- 1 — all attempts exhausted, last exit code returned
- 2 — usage error

## Output

On each retry, prints to stderr:
```
Attempt 2/3 failed (exit 1). Retrying in 1043ms...
```

On final failure:
```
ERROR: command failed after 3 attempts
Last output: <last stdout/stderr>
```
