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

```bash
# 1. Clone the repo
git clone <your-repo>
cd <repo>

# 2. Install dependencies
npm install -g @anthropic-ai/claude-code
# Install Taskfile: https://taskfile.dev/installation/

# 3. Run setup (makes hooks executable, installs git hooks)
task setup

# 4. Add a project
task project:new
# — fill out the template in queue.md

# 5. Plan it (planner-opus creates scope + stages, you review)
task plan:queue

# 6. Approve the plan
task plan:review
task plan:approve -- <project-name>

# 7. Run tonight
task agent:run

# 8. Review in the morning
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
| Local git hooks | pre-push blocks direct pushes to main |
| GitHub branch protection | Server-side enforcement regardless of local config |

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

- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- Taskfile (`https://taskfile.dev/installation/`)
- GitHub CLI (`gh`) — optional, for PR automation
- jq — for hook JSON parsing (`brew install jq` / `apt install jq`)
- Obsidian — for vault UI (free download at obsidian.md)

## Environment

Set in your shell or CI:
```bash
export ANTHROPIC_API_KEY=your_key_here
```

For secrets in projects, use Bitwarden CLI:
```bash
bw get password "project-name/service-name"
```

## New machine setup

```bash
git clone <repo>
cd <repo>
task setup
# Open repo as Obsidian vault — everything is already there
```

That's it. The full project history, decisions, metrics, skills library,
and agent configuration restore on clone.
