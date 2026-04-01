#!/usr/bin/env bash
# .claude/hooks/pre-edit-path-guard.sh
# Blocks edits to protected paths and files outside the current worktree.
# exit 2 = hard block, exit 0 = allow

set -euo pipefail

HOOK_INPUT=$(cat)
FILE=$(echo "$HOOK_INPUT" | jq -r '.tool_input.path // ""' 2>/dev/null || echo "")

[[ -z "$FILE" ]] && exit 0

block() {
  echo "🛡️  BLOCKED: $1" >&2
  echo "File: $FILE" >&2
  exit 2
}

# ── Protected files ──────────────────────────────────────────────────────────

# Env files
echo "$FILE" | grep -qE '\.env($|\.)' && block ".env file — use Bitwarden Secrets Manager"

# Node internals
echo "$FILE" | grep -qE 'node_modules/' && block "node_modules are read-only"

# Lock files — agents should not modify these directly
echo "$FILE" | grep -qE '(package-lock\.json|yarn\.lock|pnpm-lock\.yaml)$' \
  && block "lock files are managed by package managers, not direct edit"

# Git internals (belt-and-suspenders for v2.1.78+ which already protects .git)
echo "$FILE" | grep -qE '^\.git/' && block ".git internals are protected"

# ── Main branch protection ───────────────────────────────────────────────────

# Agents should not directly modify scope.md without being in planning mode
# This is a soft warning via stderr — not a hard block
if echo "$FILE" | grep -qE 'docs/scope\.md$'; then
  echo "⚠️  WARNING: Modifying scope.md — ensure you are in planning mode" >&2
fi

# ── Allow ────────────────────────────────────────────────────────────────────
exit 0
