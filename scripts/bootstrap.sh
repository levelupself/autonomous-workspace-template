#!/usr/bin/env bash
# scripts/bootstrap.sh — zero-dependency Linux/macOS bootstrap
#
# Run with bash (curl pipe or after manual download):
#   Linux:  bash scripts/bootstrap.sh
#   macOS:  bash scripts/bootstrap.sh
#
# Or from the internet before cloning:
#   curl -fsSL <raw-github-url>/scripts/bootstrap.sh | bash

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "  ${CYAN}-->${NC} $*"; }
ok()   { echo -e "  ${GREEN}ok${NC}   $*"; }
warn() { echo -e "  ${YELLOW}warn${NC} $*"; }
die()  { echo -e "  ${RED}FAIL${NC} $*" >&2; exit 1; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

OS=$(detect_os)
echo ""
echo "================================================"
echo "  Autonomous Workspace — Bootstrap ($OS)"
echo "================================================"
echo ""

# ── macOS: Homebrew ───────────────────────────────────────────────────────────

if [ "$OS" = "macos" ]; then
  step "Homebrew..."
  if command -v brew &>/dev/null; then
    ok "brew $(brew --version | head -1) — already installed"
  else
    step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for this session
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
    ok "Homebrew installed"
  fi
fi

# ── Git ───────────────────────────────────────────────────────────────────────

echo ""
step "Git..."
if command -v git &>/dev/null; then
  ok "$(git --version) — already installed"
else
  case "$OS" in
    macos) brew install git && ok "git installed via brew" || die "brew install git failed" ;;
    linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y git && ok "git installed via apt"
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y git && ok "git installed via dnf"
      else
        die "Cannot auto-install git. Install manually and re-run."
      fi
      ;;
  esac
fi

# ── Node.js ───────────────────────────────────────────────────────────────────

echo ""
step "Node.js..."
if command -v node &>/dev/null; then
  ok "$(node --version) — already installed"
else
  case "$OS" in
    macos)
      brew install node && ok "node installed via brew" || die "brew install node failed"
      ;;
    linux)
      # Use NodeSource LTS
      if command -v apt-get &>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs && ok "node installed via NodeSource"
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y nodejs && ok "node installed via dnf"
      else
        die "Cannot auto-install Node.js. Install manually and re-run."
      fi
      ;;
  esac
fi

# ── Hand off ──────────────────────────────────────────────────────────────────

echo ""
echo "================================================"
echo "  Handing off to install-deps.sh..."
echo "================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
bash "$SCRIPT_DIR/install-deps.sh"

echo ""
echo "================================================"
echo -e "  ${GREEN}Bootstrap complete!${NC}"
echo "================================================"
echo ""
echo "Next:"
echo -e "  ${CYAN}bw login${NC}"
echo -e "  ${CYAN}task secrets:set -- ANTHROPIC_API_KEY <your-key>${NC}"
echo -e "  ${CYAN}task secrets:set -- GITHUB_TOKEN <your-token>${NC}"
echo -e "  ${CYAN}task secrets:pull${NC}"
