#!/usr/bin/env bash
# .claude/hooks/stop-write-back.sh
# Fires on every session end. Writes token metrics, status, and summaries
# back to the Obsidian vault. Handles both clean exits and limit hits.

set -euo pipefail

INPUT=$(cat)
STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | jq -r '.cwd // "."' 2>/dev/null || echo ".")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
COST_USD=$(echo "$INPUT" | jq -r '.total_cost_usd // 0' 2>/dev/null || echo "0")
INPUT_TOKENS=$(echo "$INPUT" | jq -r '.usage.input_tokens // 0' 2>/dev/null || echo "0")
OUTPUT_TOKENS=$(echo "$INPUT" | jq -r '.usage.output_tokens // 0' 2>/dev/null || echo "0")

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DATE=$(date -u +%Y-%m-%d)
TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS))

# ── Detect project ────────────────────────────────────────────────────────────

# Try to find which project we're in from CWD or worktree name
PROJECT=""
if echo "$CWD" | grep -q "worktrees/"; then
  WORKTREE=$(echo "$CWD" | grep -oP 'worktrees/\K[^/]+')
  PROJECT=$(echo "$WORKTREE" | sed 's/agent-//;s/-[0-9]\{8\}$//')
fi

# Fallback: find from stages.md files
if [[ -z "$PROJECT" ]]; then
  STAGES_FILE=$(find "$CWD" -name "stages.md" -maxdepth 4 2>/dev/null | head -1)
  if [[ -n "$STAGES_FILE" ]]; then
    PROJECT=$(echo "$STAGES_FILE" | grep -oP 'projects/\K[^/]+')
  fi
fi

# ── Write token entry ─────────────────────────────────────────────────────────

if [[ -n "$PROJECT" ]] && [[ -f "projects/$PROJECT/metrics/tokens.md" ]]; then
  TOKENS_FILE="projects/$PROJECT/metrics/tokens.md"
  
  cat >> "$TOKENS_FILE" << EOF
| $DATE | $SESSION_ID | $STOP_REASON | $TOTAL_TOKENS | \$$COST_USD |
EOF
fi

# ── Handle usage limit hit ────────────────────────────────────────────────────

if echo "$STOP_REASON" | grep -qiE "usage_limit|rate_limit"; then
  RESUME_AFTER=$(date -u -d '+5 hours' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -v+5H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || echo "unknown")
  
  if [[ -n "$PROJECT" ]] && [[ -f "projects/$PROJECT/docs/stages.md" ]]; then
    cat >> "projects/$PROJECT/docs/stages.md" << EOF

## $TIMESTAMP — SESSION PAUSED (usage limit)

status: paused_usage_limit
resume_after: $RESUME_AFTER
session_id: $SESSION_ID
tokens_used_this_session: $TOTAL_TOKENS
EOF
  fi
  
  # Update home.md project row
  if [[ -f "home.md" ]] && [[ -n "$PROJECT" ]]; then
    sed -i "s/| $PROJECT | .* | .* |/| $PROJECT | ⏸ paused (usage limit) |/" home.md 2>/dev/null || true
  fi
fi

# ── Update burndown ───────────────────────────────────────────────────────────

if [[ -n "$PROJECT" ]] && [[ -f "projects/$PROJECT/metrics/burndown.md" ]]; then
  # Count checked tasks in stages.md
  STAGES_FILE="projects/$PROJECT/docs/stages.md"
  if [[ -f "$STAGES_FILE" ]]; then
    TOTAL=$(grep -c '^\- \[' "$STAGES_FILE" 2>/dev/null || echo "0")
    DONE=$(grep -c '^\- \[x\]' "$STAGES_FILE" 2>/dev/null || echo "0")
    
    sed -i "s/\*\*completed_tasks:\*\* .*/\*\*completed_tasks:\*\* $DONE/" \
      "projects/$PROJECT/metrics/burndown.md" 2>/dev/null || true
    sed -i "s/\*\*total_tasks:\*\* .*/\*\*total_tasks:\*\* $TOTAL/" \
      "projects/$PROJECT/metrics/burndown.md" 2>/dev/null || true
  fi
fi

# ── Log to supervisor log ─────────────────────────────────────────────────────

mkdir -p .claude/logs
echo "$TIMESTAMP | $PROJECT | $STOP_REASON | ${TOTAL_TOKENS}tok | \$$COST_USD" \
  >> .claude/logs/sessions.log

exit 0
