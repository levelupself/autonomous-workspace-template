# example-project

> This is a template. Replace with your project-specific instructions.
> The planner-opus agent will generate this file for new projects.

## What this project is

A template demonstrating the project structure. Replace this section with
a one-paragraph description of your actual project — goal, tech stack,
and key constraints.

## What agents must NOT do

- Modify `docs/scope.md` — this is locked after approval
- Implement anything listed in scope.md non-goals
- Push to main — always open a PR
- Skip tests before marking a stage complete
- Create new external API dependencies without noting them in scope.md

## Key files

| File | Purpose |
|------|---------|
| `docs/scope.md` | Full specification — read before acting |
| `docs/stages.md` | Current stage and task checklist |
| `docs/decisions.md` | Architectural decisions log |
| `docs/blockers.md` | Active and resolved blockers |
| `docs/ideas.md` | Generated improvement ideas |
| `metrics/tokens.md` | Session token tracking |
| `metrics/burndown.md` | Progress tracking |

## Skills to use

| Skill | When |
|-------|------|
| `/codebase-explorer` | Before implementing — understand existing patterns |
| `/test-runner` | After implementing — verify tests pass |
| `/security-scan` | Before opening PR |
| `/pr-opener` | After stage completes with passing tests |
| `/docs-writer` | After completing each stage |
| `/burndown-updater example-project` | After checking off tasks |

## Testing

```bash
# Replace with your actual test command
npm test
# or
python -m pytest
# or
go test ./...
```

## Session start checklist

Before doing any work:
- [ ] Read `docs/scope.md` — understand what to build and what NOT to build
- [ ] Read `docs/stages.md` — find `current_stage` and its task list
- [ ] Check `docs/blockers.md` — is anything unresolved?
- [ ] Run `/codebase-explorer` on the area you'll be working in
- [ ] Check `.claude/skills/` for relevant capabilities
