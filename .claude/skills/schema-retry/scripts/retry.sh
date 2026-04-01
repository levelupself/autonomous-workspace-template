#!/usr/bin/env bash
# .claude/skills/schema-retry/scripts/retry.sh
# Retry a command with exponential backoff + jitter
# Usage: retry.sh "<command>" [max_attempts=3] [base_ms=500] [cap_ms=10000]

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: retry.sh \"<command>\" [max_attempts] [base_ms] [cap_ms]" >&2
  exit 2
fi

CMD="$1"
MAX="${2:-3}"
BASE_MS="${3:-500}"
CAP_MS="${4:-10000}"

attempt=1
last_exit=0
last_output=""

while (( attempt <= MAX )); do
  # Run command and capture output + exit code
  last_output=$(eval "$CMD" 2>&1) && last_exit=0 || last_exit=$?
  
  if [[ $last_exit -eq 0 ]]; then
    echo "$last_output"
    exit 0
  fi
  
  if (( attempt == MAX )); then
    break
  fi
  
  # Calculate wait: min(cap, base * 2^(attempt-1)) + jitter
  raw_wait=$(( BASE_MS * (1 << (attempt - 1)) ))
  capped_wait=$(( raw_wait < CAP_MS ? raw_wait : CAP_MS ))
  jitter=$(( RANDOM % (BASE_MS / 10 + 1) ))
  wait_ms=$(( capped_wait + jitter ))
  wait_sec=$(echo "scale=3; $wait_ms / 1000" | bc 2>/dev/null || echo "1")
  
  echo "Attempt $attempt/$MAX failed (exit $last_exit). Retrying in ${wait_ms}ms..." >&2
  sleep "$wait_sec"
  
  (( attempt++ ))
done

echo "ERROR: command failed after $MAX attempts" >&2
echo "Last output: $last_output" >&2
exit "$last_exit"
