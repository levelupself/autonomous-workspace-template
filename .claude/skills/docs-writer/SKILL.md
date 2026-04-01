---
name: docs-writer
description: >
  Updates the Obsidian vault after a session completes. Writes token metrics
  to metrics/tokens.md, advances stages.md checkboxes, updates burndown.md,
  logs decisions to decisions.md, and updates the project row in home.md.
  Use at the end of every successful stage completion.
allowed-tools: Read, Write, Bash, Glob
---

# Docs-Writer Skill

Update all Obsidian vault files after completing work.

## Step 1 — Collect session data

Gather from the current session:
- Which project and stage was completed
- Total tokens used (from session context or `/usage` output)
- Which tasks were checked off
- Any architectural decisions made
- Any ideas generated during implementation

## Step 2 — Update metrics/tokens.md

Append a row:
```
| <YYYY-MM-DD> | <session-id or "manual"> | <stage-name> | <tokens> | $<cost> |
```

## Step 3 — Check off completed tasks in stages.md

For each task that was completed this session:
- Change `- [ ]` to `- [x]`
- Add `**completed_at:** <ISO8601>` below the task list

If all tasks in the stage are checked:
- Update `current_stage` to the next stage number
- Add `**completed_at:** <ISO8601>` to the stage header
- Set `status: active` on the next stage

## Step 4 — Update burndown.md

Recount:
```bash
grep -c '^\- \[x\]' projects/<project>/docs/stages.md
grep -c '^\- \[' projects/<project>/docs/stages.md
```

Update:
- `completed_tasks`
- `total_tasks`
- Calculate new velocity (completed tasks / nights run)
- Update `projected_completion`

## Step 5 — Log decisions (if any)

For each architectural decision made during the session, append to decisions.md:

```markdown
### <Decision title> — <ISO8601>

**Context:** <situation>
**Decision:** <what was chosen>
**Rationale:** <why>
**Tokens spent deciding:** <estimate>
**Consequences:** <what changes>
```

## Step 6 — Append to ideas.md (if any)

For each improvement idea noticed during implementation:

```
| <date> | <feature|perf|risk|refactor> | <idea description> | stage <n> |
```

## Step 7 — Update home.md project row

Find the project's row in home.md and update:
- Stage column: current stage name
- Status: ✓ PR open | 🔄 in progress | ⏸ paused
- Tokens used: running total
- Last run: today's date
