# Stages: example-project

**current_stage:** 1
**status:** active
**last_run:** —
**velocity:** — tasks/night

---

## Stage 1: scaffolding

**token_budget:** 15,000
**entry_criteria:** Project approved by human
**exit_criteria:** All items checked AND directory structure verified
**test_strategy:** `ls -R projects/example-project/` confirms all files exist

### Tasks
- [ ] Verify all docs/ files exist and have content
- [ ] Verify all metrics/ files exist and have headers
- [ ] Verify CLAUDE.md has all required sections
- [ ] Verify .claude/skills/ has at least 5 skills
- [ ] Verify Taskfile.yml tasks all have descriptions

**resume_point:** — (not started)
**completed_at:** —

---

## Stage 2: example content

**token_budget:** 25,000
**entry_criteria:** Stage 1 complete
**exit_criteria:** All items checked AND content is realistic
**test_strategy:** Manual review — content should be self-explanatory to a new user

### Tasks
- [ ] decisions.md has 3+ realistic decision entries
- [ ] tokens.md has 5+ realistic session entries
- [ ] burndown.md shows realistic velocity
- [ ] ideas.md has 5+ realistic idea entries
- [ ] blockers.md shows a resolved blocker example

**resume_point:** —
**completed_at:** —
