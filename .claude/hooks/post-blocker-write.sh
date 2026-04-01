#!/usr/bin/env bash
# .claude/hooks/post-blocker-write.sh
# Fires after any Write to a blockers.md file.
# Spawns the supervisor agent asynchronously.

set -euo pipefail

HOOK_INPUT=$(cat)
FILE=$(echo "$HOOK_INPUT" | jq -r '.tool_input.path // ""' 2>/dev/null || echo "")

# Only fire on blockers.md writes
echo "$FILE" | grep -q "blockers\.md" || exit 0

mkdir -p .claude/logs

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "$TIMESTAMP — blocker detected in $FILE — spawning supervisor" >> .claude/logs/supervisor.log

# Spawn supervisor asynchronously — don't block current session
nohup claude \
  --dangerously-skip-permissions \
  --agent supervisor \
  -p "A new blocker was written to $FILE at $TIMESTAMP. Read it, classify it, and route it according to your instructions. Project context: $(dirname $(dirname $FILE))" \
  >> .claude/logs/supervisor.log 2>&1 &

echo "Supervisor spawned (PID $!) for blocker in $FILE" >&2
exit 0
