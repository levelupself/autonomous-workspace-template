#!/usr/bin/env bash
# .claude/hooks/pre-bash-firewall.sh
# Blocks dangerous bash commands before execution.
# exit 2 = hard block, exit 0 = allow

set -euo pipefail

HOOK_INPUT=$(cat)
CMD=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

[[ -z "$CMD" ]] && exit 0

block() {
  echo "🛡️  BLOCKED: $1" >&2
  echo "Command: $CMD" >&2
  exit 2
}

# ── Absolute destroyers ──────────────────────────────────────────────────────

# rm on root, home, or bare tilde
echo "$CMD" | grep -qE 'rm\s+-[rf]+\s+(/[^a-zA-Z]|/$|~/?$|~/[^/])' \
  && block "rm on root or home directory"

# Tilde directory expansion trap (~/ inside rm)
echo "$CMD" | grep -qE 'rm\s+.*\s+~/?\s*$' \
  && block "ambiguous tilde expansion in rm"

# ── Remote code execution ────────────────────────────────────────────────────

echo "$CMD" | grep -qE '(curl|wget).*\|\s*(bash|sh|zsh|fish)' \
  && block "piping remote content to shell"

echo "$CMD" | grep -qE '(curl|wget).*-[^s]*s.*\|\s*(bash|sh)' \
  && block "silent curl piped to shell"

# ── Destructive git operations ───────────────────────────────────────────────

echo "$CMD" | grep -qE 'git\s+push.*(-f|--force)' \
  && block "force push (use git revert instead)"

echo "$CMD" | grep -qE 'git\s+push.*(origin\s+)?(main|master)($|\s|$)' \
  && block "direct push to main/master (open a PR instead)"

echo "$CMD" | grep -qE 'git\s+reset\s+--hard' \
  && block "git reset --hard (use git revert to preserve history)"

echo "$CMD" | grep -qE 'git\s+branch\s+-[Dd]\s+(main|master)' \
  && block "deleting main or master branch"

# ── Credential exposure ──────────────────────────────────────────────────────

echo "$CMD" | grep -qiE '(api_key|secret|password|token)\s*=' \
  && block "potential credential in command (use Bitwarden Secrets Manager)"

# ── Scope escape ─────────────────────────────────────────────────────────────

# Writing outside worktree — detect by checking CWD vs write target
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")
if [[ -n "$CWD" ]]; then
  echo "$CMD" | grep -qE '^(echo|printf|tee|cat>|cat >>)\s+/(?!(home|tmp))' \
    && block "writing to absolute path outside home (likely outside worktree)"
fi

# ── Allow ────────────────────────────────────────────────────────────────────
exit 0
