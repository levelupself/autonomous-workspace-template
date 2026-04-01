# Project Queue

Add new projects here. The meta-planner reads this file and creates a full plan
before any execution begins. You approve the plan before agents start building.

## How to add a project

Fill out one entry below. The more context you provide, the better the plan.

---

## Template

```
## project-name

**goal:** One sentence — what this builds and why.
**context:** Background, existing systems it connects to, constraints.
**non_goals:** What this explicitly does NOT include (prevents scope creep).
**tech_hints:** Preferred stack, libraries, patterns if you have opinions.
**priority:** high | medium | low
**token_budget_est:** rough estimate — small (~30k) | medium (~80k) | large (~150k+)
**external_deps:** API keys, credentials, or services needed before execution can start.
**references:** Links to docs, existing code, or related projects.
```

---

## Example entry (delete when you add real projects)

## example-auth-service

**goal:** JWT refresh token rotation with RS256 for internal service-to-service auth.
**context:** Three microservices need to authenticate against each other. Currently using shared secrets — want to move to asymmetric keys with rotation.
**non_goals:** Social login (OAuth with Google/GitHub) — separate project. User-facing auth — this is service-to-service only.
**tech_hints:** Node.js, fastify, jose library for JWT. No new databases — use existing Redis for token store.
**priority:** high
**token_budget_est:** medium (~80k)
**external_deps:** None — all internal.
**references:** See projects/existing-auth for current implementation patterns.

---

_Add your projects above this line_
