\# Session handoff — from claude.ai planning session



\## What this workspace is



A self-driving autonomous development workspace built across a long planning 

session. Agents run overnight, you review in the morning. Full architecture 

documented in README.md.



\## What was designed and built



\### The full system (all files are already in this repo)



1\. \*\*Planning pipeline\*\* — new projects go through planner-opus (Opus 4.6) 

&#x20;  which writes scope.md + stages.md. validator-sonnet reviews. You approve 

&#x20;  before any code runs.



2\. \*\*Execution loop\*\* — meta-planner reads all stages.md nightly, scores 

&#x20;  projects, writes tonight.md. orchestrator agent runs each project in its 

&#x20;  own worktree. builder + validator subagents per stage.



3\. \*\*Supervision\*\* — supervisor agent wakes when blockers.md is written. 

&#x20;  Routes to skill-writer (creates new SKILL.md files) or research agent. 

&#x20;  Only scope ambiguity and credentials escalate to human.



4\. \*\*Safety layers\*\* — PreToolUse hooks block rm on root/home, force push, 

&#x20;  curl|shell pipes, git reset --hard. Worktree isolation. Local pre-push 

&#x20;  hook. GitHub branch protection (set up manually on GitHub).



5\. \*\*Usage limit handling\*\* — stop-write-back.sh hook detects usage\_limit 

&#x20;  stop reason, writes paused\_usage\_limit + resume\_after to stages.md. 

&#x20;  Meta-planner reads this and resumes next cycle automatically.



6\. \*\*Obsidian vault\*\* — home.md is the morning dashboard. All docs, metrics, 

&#x20;  decisions, ideas are markdown files committed to the repo. Clone = full 

&#x20;  restore on any machine.



\### Key architectural decisions made



\- Markdown as state (not SQLite/JSON) — git-native, Obsidian-compatible

\- Opus for planning (once per project), Haiku for execution (nightly)

\- Worktrees not containers — no Docker required

\- Plans must be approved before execution — scope.md is locked after approval

\- Non-goals are first-class in scope.md — prevents agent scope creep

\- Skills library grows autonomously — skill-writer commits new SKILL.md files

\- Stop hook always runs — writes state even on forced exits



\### What still needs to be done



\- \[ ] Push this repo to GitHub and set branch protection on main

&#x20;     (Settings → Branches → require PR, disable force push, include admins)

\- \[ ] Add ANTHROPIC\_API\_KEY to your environment

\- \[ ] Add your first real project to queue.md

\- \[ ] Run: task plan:queue (plans it), task plan:approve -- name (unlocks it)

\- \[ ] Schedule task agent:run nightly at 10pm PT (off-peak window)



\## Key files to read



\- README.md — full architecture docs

\- CLAUDE.md — your instructions as an agent in this workspace  

\- home.md — morning dashboard

\- queue.md — add new projects here

\- .claude/agents/ — all 6 agent definitions

\- .claude/skills/ — 8 skills, grows over time

\- .claude/hooks/ — 5 hooks wired in settings.json

\- projects/example-project/ — complete reference implementation



\## How to continue in Claude Code



You can ask Claude Code to:

\- "Read HANDOFF.md and explain the system architecture"

\- "Add a project to queue.md" (fill out the template)

\- "Run task plan:queue to plan the project"  

\- "Show me what task morning:review outputs"

\- "Create a new skill for X" → runs task skill:create -- X

\- "What is blocked in project Y" → reads projects/Y/docs/blockers.md



\## Context that does NOT survive (was only in the chat)



\- The full back-and-forth reasoning behind each design choice

\- Diagram explorations and alternatives considered

\- The specific wording of prompts we discussed



For any of that, the README.md and agent files contain the distilled 

decisions — the reasoning is captured in the architecture itself.

```



Then tell Claude Code when you start:

```

Read HANDOFF.md and CLAUDE.md. This is an autonomous development workspace 

we designed in a previous session. I want to continue building it out. 

Start by showing me the current state with: task morning:review

