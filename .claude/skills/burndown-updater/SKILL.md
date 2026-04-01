---
name: burndown-updater
description: >
  Recalculates burndown.md from the current state of stages.md.
  Updates completed task count, velocity (tasks per night), and
  projected completion date. Run at the end of each session.
allowed-tools: Bash, Read, Write
---

# Burndown-Updater Skill

Recalculate project progress metrics from stages.md.

## Usage

```
/burndown-updater <project-name>
```

## Step 1 — Count tasks

```bash
PROJECT="$ARGUMENTS"
STAGES="projects/$PROJECT/docs/stages.md"

# Total tasks (all checkboxes)
TOTAL=$(grep -c '^\- \[' "$STAGES" 2>/dev/null || echo "0")

# Completed tasks
DONE=$(grep -c '^\- \[x\]' "$STAGES" 2>/dev/null || echo "0")

# Remaining
REMAINING=$(( TOTAL - DONE ))

# Percentage
if [[ $TOTAL -gt 0 ]]; then
  PCT=$(( DONE * 100 / TOTAL ))
else
  PCT=0
fi
```

## Step 2 — Calculate velocity

Count nights run from tokens.md:

```bash
TOKENS="projects/$PROJECT/metrics/tokens.md"
NIGHTS=$(grep -c '^| 202' "$TOKENS" 2>/dev/null || echo "1")
VELOCITY=$(echo "scale=1; $DONE / $NIGHTS" | bc 2>/dev/null || echo "0")
```

## Step 3 — Project completion

```bash
if (( $(echo "$VELOCITY > 0" | bc 2>/dev/null || echo 0) )); then
  NIGHTS_LEFT=$(echo "scale=0; $REMAINING / $VELOCITY" | bc 2>/dev/null || echo "?")
  COMPLETION=$(date -d "+${NIGHTS_LEFT} days" +%Y-%m-%d 2>/dev/null || echo "unknown")
else
  COMPLETION="—"
fi
```

## Step 4 — Count stages

```bash
TOTAL_STAGES=$(grep -c '^## Stage' "$STAGES" 2>/dev/null || echo "0")
DONE_STAGES=$(grep -c 'completed_at:' "$STAGES" 2>/dev/null || echo "0")
```

## Step 5 — Update burndown.md

Rewrite the metrics section of `projects/$PROJECT/metrics/burndown.md`:

```markdown
# Burndown: <project>

**Updated:** <ISO8601>
**total_stages:** <n>
**completed_stages:** <n>
**total_tasks:** <n>
**completed_tasks:** <n>
**remaining_tasks:** <n>
**percent_complete:** <n>%
**velocity:** <n> tasks/night
**projected_completion:** <date>
**nights_run:** <n>

## Progress by stage

| Stage | Tasks total | Completed | % |
|-------|------------|-----------|---|
<one row per stage>
```

## Step 6 — Output summary

Print to stdout:
```
Burndown updated for <project>:
  <done>/<total> tasks complete (<pct>%)
  Velocity: <v> tasks/night
  Projected completion: <date>
```
