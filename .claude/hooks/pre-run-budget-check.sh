#!/usr/bin/env bash
# .claude/hooks/pre-run-budget-check.sh
# Checks usage budget before starting overnight agents.
# Writes deferred status to all projects if budget is too low.
# exit 1 = defer run, exit 0 = proceed

set -euo pipefail

MIN_BUDGET_PCT=${MIN_BUDGET_PCT:-20}
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "Checking usage budget..."

# Try to get usage via claude CLI
USAGE_OUTPUT=$(claude /usage 2>&1 || echo "")
REMAINING_PCT=$(echo "$USAGE_OUTPUT" | grep -oP '\d+(?=% remaining)' | head -1 || echo "")

if [[ -z "$REMAINING_PCT" ]]; then
  echo "WARNING: Could not read usage percentage — proceeding with caution" >&2
  echo "If run fails due to limits, check claude.ai/settings/usage" >&2
  exit 0
fi

echo "Usage remaining: ${REMAINING_PCT}%"

if (( REMAINING_PCT < MIN_BUDGET_PCT )); then
  echo "Budget too low (${REMAINING_PCT}% < ${MIN_BUDGET_PCT}% threshold) — deferring run" >&2
  
  # Write deferred status to all active project stages.md
  for stages_file in projects/*/docs/stages.md; do
    project=$(echo "$stages_file" | grep -oP 'projects/\K[^/]+')
    
    # Only defer active projects (not already done or blocked)
    current_status=$(grep -oP '(?<=status: )[^\n]+' "$stages_file" 2>/dev/null | head -1 || echo "")
    
    if [[ "$current_status" != "done" ]] && [[ "$current_status" != "awaiting_approval" ]]; then
      cat >> "$stages_file" << EOF

## $TIMESTAMP — DEFERRED (low budget)

status: deferred_low_budget
remaining_pct: ${REMAINING_PCT}%
retry: next usage window
EOF
      echo "  Deferred: $project"
    fi
  done
  
  # Update home.md
  if [[ -f "home.md" ]]; then
    DEFER_MSG="$TIMESTAMP — Run deferred: only ${REMAINING_PCT}% usage remaining"
    sed -i "s/\*\*Last overnight run:\*\* .*/\*\*Last overnight run:\*\* $DEFER_MSG/" home.md 2>/dev/null || true
  fi
  
  exit 1
fi

echo "Budget OK (${REMAINING_PCT}% remaining) — proceeding with overnight run"
exit 0
