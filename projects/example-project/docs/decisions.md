# Decisions: example-project

Architectural decisions logged by agents during execution.

---

### Markdown as primary state format — 2026-03-31T00:00:00Z

**Context:** Needed a state format that works for both human review in Obsidian
and programmatic read/write by agents without external dependencies.

**Decision:** All state stored as structured markdown files.

**Rationale:** Git-native, human-readable, Obsidian-compatible, zero infrastructure.
Agents can read/write with basic bash and grep — no parsing libraries needed.

**Tokens spent deciding:** 2,400

**Consequences:** State queries require grep patterns rather than SQL. Offset by
consistent file naming and section header conventions.
