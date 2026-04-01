# Autonomous Development Workspace

A self-driving project workspace where AI agents plan, build, and document
software overnight. You review in the morning and make a small number of decisions.

## What this is

A git repository that is simultaneously:
- A **Claude Code agent workspace** — agents run here autonomously
- An **Obsidian vault** — every doc, decision, and metric is human-readable
- A **project management system** — stages, burndown, token tracking built in
- A **self-improving tool library** — agents create new skills when they get stuck

Open `home.md` in Obsidian to see everything.

## Quick start

**Windows (zero prereqs — opens PowerShell):**
```powershell
# 1. Use this template on GitHub, clone your new repo, then:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
.\scripts\bootstrap.ps1
```

**Linux / macOS:**
```bash
git clone <your-repo> && cd autonomous-workspace
bash scripts/bootstrap.sh
```

**After bootstrap completes:**
```bash
# 2. Log into Bitwarden and add secrets
bw login
task secrets:set -- ANTHROPIC_API_KEY <key>   # skip if using Claude Pro
task secrets:pull                              # writes .env

# 3. Add a project
# Edit queue.md and fill out the template

# 4. Plan it (planner-opus creates scope + stages, you review)
task plan:queue
task plan:review
task plan:approve -- <project-name>

# 5. Run tonight
task agent:run

# 6. Review in the morning
task morning:review
```

## Architecture

```
repo/
├── home.md                      ← master dashboard (open in Obsidian)
├── queue.md                     ← add new projects here
├── CLAUDE.md                    ← agent instructions (read by all agents)
├── Taskfile.yml                 ← all workflow commands
│
├── projects/
│   └── <project-name>/
│       ├── CLAUDE.md            ← project-specific agent instructions
│       └── docs/
│           ├── scope.md         ← full spec (approved before execution)
│           ├── stages.md        ← task checklist + current stage
│           ├── decisions.md     ← architectural decisions log
│           ├── ideas.md         ← agent-generated improvement ideas
│           └── blockers.md      ← active/resolved blockers
│       └── metrics/
│           ├── tokens.md        ← token burn per session
│           └── burndown.md      ← progress tracking
│
├── .claude/
│   ├── settings.json            ← hooks, permissions, agent teams
│   ├── agents/
│   │   ├── meta-planner.md      ← schedules overnight runs
│   │   ├── planner-opus.md      ← creates project plans (Opus)
│   │   ├── validator-sonnet.md  ← reviews plans (Sonnet)
│   │   ├── orchestrator.md      ← per-project execution coordinator
│   │   ├── supervisor.md        ← handles blockers, routes to skill-writer
│   │   └── skill-writer.md      ← creates new skills when agents get stuck
│   ├── hooks/
│   │   ├── pre-bash-firewall.sh     ← blocks dangerous commands
│   │   ├── pre-edit-path-guard.sh   ← blocks writes to protected paths
│   │   ├── stop-write-back.sh       ← writes session results to vault
│   │   ├── post-blocker-write.sh    ← wakes supervisor on blocker writes
│   │   └── pre-run-budget-check.sh  ← defers if usage too low
│   ├── skills/
│   │   ├── docs-writer/         ← updates vault after session
│   │   ├── pr-opener/           ← opens GitHub PRs
│   │   ├── test-runner/         ← runs test suite
│   │   ├── jwt-validator/       ← RS256 JWT validation
│   │   ├── schema-retry/        ← exponential backoff retry
│   │   ├── codebase-explorer/   ← read-only analysis
│   │   ├── security-scan/       ← vulnerability scanning
│   │   └── burndown-updater/    ← recalculates progress metrics
│   └── tasks/
│       └── tonight.md           ← generated nightly by meta-planner
│
├── .obsidian/                   ← Obsidian config (committed)
└── .github/workflows/
    └── nightly.yml              ← scheduled GitHub Actions run
```

## Four defense layers (safety)

| Layer | What it does |
|-------|-------------|
| PreToolUse hooks | Block dangerous bash commands and protected file writes |
| Worktree isolation | Each agent gets its own branch — main is never touched |
| Local git hooks | pre-push blocks direct pushes to main from agent worktrees |
| GitHub branch protection | Server-side enforcement regardless of local config |

Run `task hooks:test` at any time to verify all 37 safety checks pass.

## Planning pipeline (new projects)

```
queue.md entry
    ↓
planner-opus (Opus 4.6)
    → writes scope.md, stages.md, CLAUDE.md, metrics files
    ↓
validator-sonnet reviews plan
    → quality report, flags ambiguities
    ↓
YOU approve (task plan:approve)
    ↓
meta-planner schedules for tonight
    ↓
orchestrator executes nightly
```

Nothing executes until you approve the plan.

## Supervision and self-improvement

When an agent gets stuck:
1. Writes structured blocker to `docs/blockers.md`
2. `post-blocker-write.sh` hook wakes the supervisor agent
3. Supervisor classifies: capability gap → skill-writer, knowledge gap → research, scope → you
4. Skill-writer creates a new `SKILL.md` and commits it
5. Next session auto-discovers the skill and continues

The `.claude/skills/` library grows with every overnight run.

## Token tracking

Every session the `stop-write-back.sh` hook records:
- Tokens used (input + output)
- Cost in USD
- Stop reason (complete / usage_limit / error)

Burndown tracks tasks completed per night = velocity = projected completion date.

## Usage limits

The system handles both limit types automatically:
- **429 rate limit** — agent self-recovers using `retry-after` header
- **5h usage window** — Stop hook writes `paused_usage_limit`, next run resumes from `last_completed_task`

Off-peak window (10 PM – 5 AM PT) burns the quota slower — schedule runs here.

## Requirements

`scripts/bootstrap.ps1` (Windows) or `scripts/bootstrap.sh` (Linux/macOS) installs everything automatically. Manual prereqs:

| Tool | Auto-installed | Notes |
|------|---------------|-------|
| Node.js | Yes (via winget/brew/apt) | Required first on Windows |
| Git + Git Bash | Yes (via winget/brew/apt) | Required first on Windows |
| Bitwarden CLI (`bw`) | Yes (via npm) | |
| Taskfile (`task`) | Yes (via npm/winget/brew) | |
| GitHub CLI (`gh`) | Yes (via winget/brew/apt) | Optional — for PR automation |
| jq | Yes (via winget/brew/apt) | Required for hook JSON parsing |
| Claude Code CLI | Yes (via npm) | |
| Obsidian | No | Free download at obsidian.md — open repo as vault |

## Secrets

All secrets live in **Bitwarden**, never in the repository. Naming convention:

```
autonomous-workspace/KEY_NAME
```

```bash
task secrets:set -- KEY_NAME value   # store in Bitwarden
task secrets:pull                    # sync vault to .env (gitignored)
task secrets:list                    # show available keys
```

See `.env.example` for the full list of keys the workspace expects.

**For nightly unattended runs**, store your Bitwarden API credentials as
Windows user environment variables (`BW_CLIENTID`, `BW_CLIENTSECRET`, `BW_PASSWORD`)
so the vault unlocks without a prompt.

## Authentication

This workspace works with either a **Claude Pro/Max subscription** or an **Anthropic API key**.

**Claude Pro/Max (no API key needed):**
```bash
claude login   # one-time browser login; session persists for nightly runs
```

**Anthropic API key:**
```bash
task secrets:set -- ANTHROPIC_API_KEY your_key_here
task secrets:pull
```

The main difference: Pro/Max has a 5-hour usage window with rate limits; API access is pay-per-token. The workspace handles both — the `stop-write-back.sh` hook writes `paused_usage_limit` state when the window is hit, and the next run resumes automatically.

## New machine setup

```bash
# Windows (PowerShell — zero prereqs)
.\scripts\bootstrap.ps1

# Linux / macOS
bash scripts/bootstrap.sh

# Then:
bw login
task secrets:pull
# Open repo as Obsidian vault — full history, skills, and config restore on clone
```
