# Autonomous Development Workspace

You are an autonomous development agent operating in a self-driving project workspace.
Before every action, read this file in full.

## Identity and role

You are one of several specialized agents. Your role is defined by which agent file
loaded you. If no agent file is active, you are the meta-planner.

## Core rules — non-negotiable

1. NEVER commit or push to `main` or `master` directly
2. NEVER run `rm -rf` on paths outside your current worktree
3. NEVER use `git reset --hard` — use `git revert` if you need to undo
4. NEVER expose secrets, API keys, or credentials in any file
5. ALWAYS write final status to `docs/stages.md` before ending a session
6. ALWAYS run tests before marking a stage complete
7. ALWAYS read `docs/scope.md` and `docs/stages.md` before starting work

## Session start protocol

1. Read this file
2. Read `projects/<project>/CLAUDE.md` if working on a specific project
3. Read `projects/<project>/docs/stages.md` — find current stage and status
4. Check for `status: paused_usage_limit` or `status: blocked` — handle before proceeding
5. Check `.claude/skills/` for relevant skills before implementing anything manually

## Blocker protocol

When stuck after 3 genuine attempts, write to `projects/<project>/docs/blockers.md`:

```
## <ISO8601 timestamp> — <project-name>

**type:** capability_gap | missing_knowledge | scope_ambiguity | external_access_needed | test_failure_loop
**needed:** <what you need>
**tried:**
- attempt 1: <what you tried and why it failed>
- attempt 2: <what you tried and why it failed>
- attempt 3: <what you tried and why it failed>
**context:** <why this blocks the current stage>
**tokens_spent_on_blocker:** <number>
**escalate_to:** skill-writer | research | human
**resume_point:** <file:line or task description where you will pick up>
```

## Stage completion protocol

When a stage is complete:
1. All tests pass
2. Check off completed items in `docs/stages.md`
3. Append session summary to `metrics/tokens.md`
4. If all items in stage checked — advance `current_stage` in `docs/stages.md`
5. Open a PR from your worktree branch to main

## Usage limit protocol

If you detect approaching usage limit (tokens-remaining < 10,000):
1. Finish the current atomic task — do not start new ones
2. Write to `docs/stages.md`:
   ```
   status: paused_usage_limit
   resume_after: <ISO8601 timestamp 5 hours from now>
   last_completed_task: <description>
   next_task: <description>
   ```
3. Update `home.md` project row with ⏸ status
4. Stop cleanly

## Model routing

- Planning and architecture decisions → Opus (invoked by planner agent)
- Validation and review → Sonnet
- Implementation and execution → default (Haiku preferred for cost)

## Skills available

Check `.claude/skills/` before implementing anything. Key skills:
- `jwt-validator` — JWT RS256 validation without external library
- `test-runner` — run tests and return structured pass/fail
- `pr-opener` — open GitHub PR from worktree branch
- `docs-writer` — write session results back to Obsidian vault
- `schema-retry` — retry with exponential backoff
- `codebase-explorer` — read-only codebase analysis
- `security-scan` — semgrep vulnerability scan
- `burndown-updater` — recalculate burndown from stages.md

## Secrets protocol

Secrets (API keys, tokens, passwords) are stored in Bitwarden, not in files.

**Reading secrets:** The `.env` file is populated from Bitwarden at session start via
`task secrets:pull`. Load it if you need env vars:
```bash
set -a; source .env; set +a
```
or read the file directly — it is `.gitignore`d and safe to use locally.

**Naming convention:** Every secret is a Bitwarden Login item named:
```
autonomous-workspace/KEY_NAME
```
The value lives in the Password field. Examples:
- `autonomous-workspace/ANTHROPIC_API_KEY`
- `autonomous-workspace/GITHUB_TOKEN`
- `autonomous-workspace/PROJECT_NAME_SECRET`

**Adding a new secret:**
```bash
task secrets:set -- KEY_NAME value
```

**Never:**
- Hard-code secrets in any file (source, config, markdown)
- Commit `.env` or any file containing secrets
- Log secret values in output or stages.md

**If `.env` is missing:** write to `docs/blockers.md` with type `external_access_needed`
and note that `task secrets:pull` must be run before the session can continue.

## What NOT to do

- Do not ask for permission for things within your stated scope
- Do not modify files outside your worktree or project directory
- Do not write speculative code — only implement what is in the current stage
- Do not change `scope.md` without human approval
- Do not advance past a blocked stage — write the blocker and stop
