# scripts/bootstrap.ps1 - zero-dependency Windows bootstrap
#
# Run this in PowerShell (no other tools required) to go from a bare Windows
# machine to a fully configured autonomous workspace.
#
# Usage (PowerShell, run as normal user - NOT Administrator):
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
#   .\scripts\bootstrap.ps1
#
# Or download and run before cloning (replace URL with your raw GitHub URL):
#   irm <raw-github-url>/scripts/bootstrap.ps1 | iex
#
# What it does:
#   1. Verifies winget is available
#   2. Installs Git for Windows (includes Git Bash)
#   3. Installs Node.js LTS
#   4. Refreshes PATH
#   5. Hands off to bash scripts/install-deps.sh for the rest

$ErrorActionPreference = "Stop"

function Write-Step  { param($msg) Write-Host "  --> $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "  ok  $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "  warn $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "  FAIL $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "================================================" -ForegroundColor White
Write-Host "  Autonomous Workspace - Windows Bootstrap" -ForegroundColor White
Write-Host "================================================" -ForegroundColor White
Write-Host ""

# --- winget ------------------------------------------------------------------

Write-Step "Checking winget..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Fail "winget not found."
    Write-Host ""
    Write-Host "winget ships with Windows 10 1709+ and Windows 11." -ForegroundColor Yellow
    Write-Host "If missing, install App Installer from the Microsoft Store," -ForegroundColor Yellow
    Write-Host "or grab the .msixbundle from github.com/microsoft/winget-cli/releases" -ForegroundColor Yellow
    exit 1
}
Write-Ok "winget $(winget --version)"

# --- Git for Windows ---------------------------------------------------------

Write-Host ""
Write-Step "Git for Windows..."
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Ok "git $(git --version) - already installed"
} else {
    Write-Step "Installing Git for Windows via winget..."
    winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Git install failed (winget exit $LASTEXITCODE)"
        exit 1
    }
    Write-Ok "Git installed"
}

# --- Node.js -----------------------------------------------------------------

Write-Host ""
Write-Step "Node.js LTS..."
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Ok "node $(node --version) - already installed"
} else {
    Write-Step "Installing Node.js LTS via winget..."
    winget install --id OpenJS.NodeJS.LTS -e --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Node.js install failed (winget exit $LASTEXITCODE)"
        exit 1
    }
    Write-Ok "Node.js installed"
}

# --- Refresh PATH ------------------------------------------------------------

Write-Host ""
Write-Step "Refreshing PATH..."
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:PATH    = $machinePath + ";" + $userPath
Write-Ok "PATH refreshed"

# --- Locate bash -------------------------------------------------------------

Write-Host ""
Write-Step "Locating Git Bash..."

$bashCandidates = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe"
)

$bash = $null
foreach ($c in $bashCandidates) {
    if (Test-Path $c) { $bash = $c; break }
}

if (-not $bash) {
    $bashFromPath = Get-Command bash -ErrorAction SilentlyContinue
    if ($bashFromPath) { $bash = $bashFromPath.Source }
}

if (-not $bash) {
    Write-Warn "Git Bash not found at expected paths."
    Write-Host "  Git was just installed - you may need to open a new terminal." -ForegroundColor Yellow
    Write-Host "  Then run: bash scripts/install-deps.sh" -ForegroundColor Yellow
    exit 0
}

Write-Ok "bash: $bash"

# --- Hand off to install-deps.sh ---------------------------------------------

Write-Host ""
Write-Host "================================================" -ForegroundColor White
Write-Host "  Handing off to install-deps.sh..." -ForegroundColor White
Write-Host "================================================" -ForegroundColor White
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir

Push-Location $repoRoot
& $bash "scripts/install-deps.sh"
$exitCode = $LASTEXITCODE
Pop-Location

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "  Bootstrap complete!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Open Git Bash and run:" -ForegroundColor White
    Write-Host "  bw login" -ForegroundColor Cyan
    Write-Host "  task secrets:set -- ANTHROPIC_API_KEY <your-key>" -ForegroundColor Cyan
    Write-Host "  task secrets:set -- GITHUB_TOKEN <your-token>" -ForegroundColor Cyan
    Write-Host "  task secrets:pull" -ForegroundColor Cyan
} else {
    Write-Fail "install-deps.sh exited with code $exitCode"
    exit 1
}
