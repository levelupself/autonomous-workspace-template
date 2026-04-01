# Home

> Master index — updated automatically by the docs-writer agent after every overnight run.
> Last updated: manually initialized

## System status

| Metric | Value |
|--------|-------|
| Active projects | 0 |
| Plans awaiting approval | 0 |
| PRs open | 0 |
| Escalations needing you | 0 |
| Skills in library | 8 |
| Last overnight run | — |
| Next scheduled run | tonight 10:00 PM |

## Projects

| Project | Stage | Status | Tokens used | Last run | Notes |
|---------|-------|--------|-------------|----------|-------|
| — | — | — | — | — | Add projects to queue.md to get started |

## Awaiting your decision

_Nothing needs your attention yet. Escalations will appear here when agents get stuck._

## Queue

_See [queue.md](queue.md) for projects waiting to be planned._

## Recent decisions

_Architectural decisions logged by agents will appear here with links to decisions.md._

## Skills library

See `.claude/skills/` — 8 skills available.

## How to use this workspace

1. Add a project to `queue.md`
2. Run `task plan:queue` — planner agent creates scope + stages, awaits your approval
3. Review the plan in this file and in `projects/<name>/docs/scope.md`
4. Run `task plan:approve <project-name>` to unlock execution
5. Run `task agent:run` each night (or schedule it)
6. Review this file each morning

## Taskfile quick reference

```bash
task plan:queue          # plan all unstarted projects in queue.md
task plan:approve NAME   # approve a plan and unlock execution
task agent:checkpoint    # git snapshot before any run
task agent:run           # run overnight agents (all approved projects)
task agent:diff          # show what changed overnight
task agent:discard NAME  # remove a worktree and its branch
task morning:review      # open this file + show PRs + show escalations
task skill:create NAME   # scaffold a new skill
```
