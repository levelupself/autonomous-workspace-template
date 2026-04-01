#!/usr/bin/env bash
# scripts/install-deps.sh — install all workspace dependencies
#
# Run this on any new machine after cloning the repo:
#   bash scripts/install-deps.sh
#
# What it installs:
#   - Bitwarden CLI (bw)    via npm
#   - jq                    via winget (Windows) or apt/brew (Linux/macOS)
#   - task (Taskfile)       via npm or direct install
#   - gh (GitHub CLI)       via winget (Windows) or apt/brew (Linux/macOS)
#
# What it does NOT install (must be done manually):
#   - Node.js / npm         https://nodejs.org  (required first)
#   - Git / Git Bash        https://git-scm.com (required first)
#   - Claude Code CLI       npm i -g @anthropic-ai/claude-code

set -uo pipefail

PASS=0
SKIP=0
FAIL=0

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}ok${NC}    $*"; PASS=$((PASS+1)); }
skip() { echo -e "  ${YELLOW}skip${NC}  $*"; SKIP=$((SKIP+1)); }
fail() { echo -e "  ${RED}fail${NC}  $*"; FAIL=$((FAIL+1)); }

detect_os() {
  case "$(uname -s)" in
    MINGW*|CYGWIN*|MSYS*) echo "windows" ;;
    Darwin)               echo "macos"   ;;
    Linux)                echo "linux"   ;;
    *)                    echo "unknown" ;;
  esac
}

OS=$(detect_os)
echo "Detected OS: $OS"
echo ""

# ── node / npm ─────────────────────────────────────────────────────────────────

echo "── Node.js / npm ──"
if command -v node &>/dev/null && command -v npm &>/dev/null; then
  ok "node $(node --version), npm $(npm --version) — already installed"
else
  fail "Node.js not found. Install from https://nodejs.org then re-run this script."
  echo "      Cannot continue without Node.js."
  exit 1
fi

# ── Bitwarden CLI ──────────────────────────────────────────────────────────────

echo ""
echo "── Bitwarden CLI (bw) ──"
if command -v bw &>/dev/null; then
  ok "bw $(bw --version 2>/dev/null | head -1) — already installed"
else
  echo "  Installing via npm..."
  if npm install -g @bitwarden/cli 2>/dev/null; then
    ok "bw installed"
  else
    fail "npm install -g @bitwarden/cli failed"
  fi
fi

# ── jq ────────────────────────────────────────────────────────────────────────

echo ""
echo "── jq ──"
if command -v jq &>/dev/null; then
  ok "jq $(jq --version) — already installed"
else
  echo "  Installing jq..."
  case "$OS" in
    windows)
      if command -v winget &>/dev/null; then
        winget install --id stedolan.jq -e --silent 2>/dev/null && ok "jq installed via winget" \
          || fail "winget install jq failed — install manually: https://jqlang.github.io/jq/"
      elif command -v choco &>/dev/null; then
        choco install jq -y 2>/dev/null && ok "jq installed via choco" \
          || fail "choco install jq failed"
      else
        fail "Cannot auto-install jq on Windows without winget or choco. Download from https://jqlang.github.io/jq/"
      fi
      ;;
    macos)
      if command -v brew &>/dev/null; then
        brew install jq 2>/dev/null && ok "jq installed via brew" \
          || fail "brew install jq failed"
      else
        fail "Homebrew not found. Install brew first: https://brew.sh"
      fi
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y jq 2>/dev/null && ok "jq installed via apt" \
          || fail "apt install jq failed"
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y jq 2>/dev/null && ok "jq installed via dnf" \
          || fail "dnf install jq failed"
      else
        fail "Cannot determine package manager. Install jq manually."
      fi
      ;;
  esac
fi

# ── task (Taskfile runner) ────────────────────────────────────────────────────

echo ""
echo "── task (Taskfile runner) ──"
if command -v task &>/dev/null; then
  ok "task $(task --version 2>/dev/null | head -1) — already installed"
else
  echo "  Installing task..."
  case "$OS" in
    windows)
      if command -v winget &>/dev/null; then
        winget install --id Task.Task -e --silent 2>/dev/null && ok "task installed via winget" \
          || fail "winget install task failed — see https://taskfile.dev/installation/"
      elif command -v choco &>/dev/null; then
        choco install go-task -y 2>/dev/null && ok "task installed via choco" \
          || fail "choco install go-task failed"
      else
        # npm fallback
        npm install -g @go-task/cli 2>/dev/null && ok "task installed via npm" \
          || fail "All task install methods failed. See https://taskfile.dev/installation/"
      fi
      ;;
    macos)
      if command -v brew &>/dev/null; then
        brew install go-task 2>/dev/null && ok "task installed via brew" \
          || fail "brew install go-task failed"
      fi
      ;;
    linux)
      # Use the official install script
      sh -c "$(curl -fsSL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin 2>/dev/null \
        && ok "task installed via official script" \
        || fail "task install failed. See https://taskfile.dev/installation/"
      ;;
  esac
fi

# ── GitHub CLI (gh) ───────────────────────────────────────────────────────────

echo ""
echo "── GitHub CLI (gh) ──"
if command -v gh &>/dev/null; then
  ok "$(gh --version 2>/dev/null | head -1) — already installed"
else
  echo "  Installing gh..."
  case "$OS" in
    windows)
      if command -v winget &>/dev/null; then
        winget install --id GitHub.cli -e --silent 2>/dev/null && ok "gh installed via winget" \
          || fail "winget install gh failed — see https://cli.github.com"
      elif command -v choco &>/dev/null; then
        choco install gh -y 2>/dev/null && ok "gh installed via choco" || fail "choco install gh failed"
      else
        fail "Cannot auto-install gh. Download from https://cli.github.com"
      fi
      ;;
    macos)
      brew install gh 2>/dev/null && ok "gh installed via brew" || fail "brew install gh failed"
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y gh 2>/dev/null && ok "gh installed via apt" \
          || {
            # GitHub's official apt repo
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
              | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
              | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update -qq && sudo apt-get install -y gh 2>/dev/null \
              && ok "gh installed via GitHub apt repo" \
              || fail "gh install failed"
          }
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y gh 2>/dev/null && ok "gh installed via dnf" || fail "dnf install gh failed"
      fi
      ;;
  esac
fi

# ── Claude Code CLI ───────────────────────────────────────────────────────────

echo ""
echo "── Claude Code CLI ──"
if command -v claude &>/dev/null; then
  ok "claude $(claude --version 2>/dev/null) — already installed"
else
  echo "  Installing via npm..."
  if npm install -g @anthropic-ai/claude-code 2>/dev/null; then
    ok "claude installed"
  else
    fail "npm install -g @anthropic-ai/claude-code failed"
  fi
fi

# ── workspace hooks + permissions ─────────────────────────────────────────────

echo ""
echo "── Workspace hooks ──"
chmod +x .claude/hooks/*.sh 2>/dev/null && ok "hooks marked executable" \
  || skip "chmod not supported (Windows — hooks still work via bash)"
chmod +x scripts/*.sh 2>/dev/null && ok "scripts marked executable" || true

# ── summary ───────────────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════"
echo "  $PASS installed/verified, $SKIP skipped, $FAIL failed"
echo "════════════════════════════════════════"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "Fix the failures above, then run: task setup"
  exit 1
fi

echo ""
echo "All dependencies ready. Next steps:"
echo ""
echo "  1. Log in to Bitwarden:"
echo "       bw login"
echo ""
echo "  2. Add your API key:"
echo "       task secrets:set -- ANTHROPIC_API_KEY <your-key>"
echo "       task secrets:set -- GITHUB_TOKEN <your-token>"
echo ""
echo "  3. Pull secrets to .env:"
echo "       task secrets:pull"
echo ""
echo "  4. Verify hooks:"
echo "       task hooks:test"
echo ""
echo "  5. Add a project and run:"
echo "       task plan:queue"
