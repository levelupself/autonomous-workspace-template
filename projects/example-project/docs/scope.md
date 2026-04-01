# Scope: example-project

**Status:** approved
**Created:** 2026-03-31T00:00:00Z
**Planned by:** planner-opus
**Approved by:** human
**Approved at:** 2026-03-31T09:00:00Z

## Goal

Demonstrate the autonomous development workspace structure with a minimal
working example that agents can reference when onboarding new projects.

## Why this matters

New projects need a reference implementation to copy patterns from.
This project serves as the canonical example for scope, stages, decisions,
and metrics file structure.

## Success criteria

The project is complete when:
- [ ] All template files are populated with realistic example content
- [ ] A complete overnight run can be simulated by reading the files
- [ ] Another developer can clone the repo and understand the system from this example

## Non-goals

The following are explicitly out of scope:
- **Real code generation** — this is a structural template, not a working application
- **CI/CD integration** — that is a separate project
- **Database schemas** — this example uses no persistence layer

## Architecture decisions

### Markdown as state
**Decision:** All state is stored in markdown files readable by both humans and agents.
**Rationale:** Portability, git-trackability, Obsidian compatibility, zero dependencies.
**Alternatives considered:** SQLite, JSON files, YAML
**Trade-offs:** No structured queries — offset by consistent file naming conventions.

## Tech stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| State | Markdown | Human-readable, git-native, Obsidian-compatible |
| Orchestration | Taskfile | Simple, readable, cross-platform |
| Version control | Git + GitHub | Standard, worktrees supported natively |
| Secrets | Bitwarden CLI | Cross-platform, CLI-native |

## External dependencies

| Dependency | Purpose | How to obtain | Stored in |
|------------|---------|---------------|-----------|
| None | — | — | — |

## Token budget estimate

| Stage | Est. tokens | Notes |
|-------|------------|-------|
| Stage 1: scaffolding | 15,000 | File creation |
| Stage 2: content | 25,000 | Writing example content |
| **Total** | **40,000** | Small project |

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Example becomes stale | medium | low | Agents update it when conventions change |
| Too abstract to be useful | low | medium | Use concrete realistic content |
