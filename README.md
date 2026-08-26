# agent-skills

Six agent skills for modernising legacy Java applications and for designing tests that are worth
running. Written and used in production on a large Struts 2 → Spring migration.

## What a skill is

A *skill* is a structured instruction document an AI coding agent loads on demand when a task
matches it. Instead of re-explaining a workflow in every prompt, the skill carries it: the ordered
steps, the task modes, the guardrails, and a set of reference documents the agent reads only when
the specific task needs them.

These six were written while migrating a large, long-lived enterprise Java web application off
Struts 2 — hundreds of `.do` routes, a Hibernate 3 data layer, and an Ext JS front end, all with
live users and no downtime budget. The method had to survive being applied several hundred times,
by different sessions, without drifting. That is the part worth publishing; the application itself
is client-owned and private.

## The skills

| Skill | What it does |
|---|---|
| [`migrate-struts2-to-spring`](migrate-struts2-to-spring) | Analyse, plan, implement, diagnose, or review a staged migration from Struts 2 actions, JSPs, and interceptors to Spring MVC — one route and all of its clients as a single functional slice, preserving the observable HTTP contract. Ships a [route-catalog schema](migrate-struts2-to-spring/assets/route-mapping.yaml). |
| [`struts2-to-spring-migration-quality-gate`](struts2-to-spring-migration-quality-gate) | Verify that a migrated slice actually works in the running application, from the API, client, and user perspective. Focused rule review, targeted build and tests, HTTP verification, browser E2E where UI integration matters, persistence checks for mutations. Returns exactly `PASS`, `FAIL`, or `INCOMPLETE`. |
| [`hibernate-criteria-to-jpa-criteria`](hibernate-criteria-to-jpa-criteria) | Convert legacy `org.hibernate.Criteria`, `Restrictions`, `Projections`, `DetachedCriteria`, and result transformers to the standard JPA Criteria API — including the staged Hibernate 3/4 → 5.6 → 6+ route and the `javax` → `jakarta` namespace transition. |
| [`java-tester`](java-tester) | Risk-focused Java test design, implementation, review, debugging, and CI placement. Unit, slice, integration, contract, Testcontainers, Spring Boot and Spring Security tests, with explicit test-pyramid decisions. |
| [`front-end-angular-tester`](front-end-angular-tester) | Version-aware Angular (2+) testing across Vitest, Karma/Jasmine, and Jest; standalone or NgModule; zone-based or zoneless. Covers components, signals, `@defer`, forms, routing, guards, HTTP, accessibility, visual regression, and E2E. |
| [`add-production-logging`](add-production-logging) | Audit, plan, add, or review production logging and observability without changing business behaviour. Preserves meaningful legacy events, removes duplicate and unsafe logging, and treats credentials and personal data as omissions by default. |

## Shared design conventions

All six follow the same rules. They are the actual content of the repo — the domain knowledge is
the easy half.

- **Read-only until asked.** Analysis, planning, review, and diagnosis modes do not edit. Only an
  explicit implementation request permits changes.
- **Explicit task modes.** Every skill classifies the request first — analyse, plan, implement,
  diagnose, review — because the obligations differ. A review that quietly starts fixing things is
  a failed review.
- **Detect before applying.** Read the build files, lockfile, CI config, and neighbouring code to
  establish actual versions, runners, and conventions. Fetch current documentation (Context7) for
  version-sensitive APIs rather than recalling them. Where duplicate JARs make the effective version
  ambiguous, report the uncertainty instead of picking one.
- **Smallest useful change.** The narrowest slice that proves the requested behaviour, and the
  cheapest test layer that catches the risk. Don't prove the same local detail at four levels.
- **Never buy a green run.** No weakened assertions, added skips, broadened mocks, raised timeouts
  or retries, accepted visual baselines, or production changes made to satisfy a test. The quality
  gate is explicitly forbidden from editing source to make itself pass.
- **Report gaps; don't fill them silently.** When no production-capable logging stack exists, when
  a route's clients can't be fully enumerated, when runtime evidence is unavailable — say so.
  `INCOMPLETE` is a permitted outcome, because "we could not check this" is not "this is fine".
- **Preserve observable behaviour.** During a migration, URLs, payloads, status codes, validation
  messages, redirects, cookies, locale, session, and security semantics are contracts. Modernising
  the framework, language level, and container is separate, later work.

## Using them

Skills are plain Markdown with YAML front matter (`name`, `description`). The `description` is what
the agent matches against, so it is written to say both when to use the skill and when not to.

Install globally, for every project:

```
~/.codex/skills/<skill-name>/
```

Or per project, checked in alongside the code it applies to:

```
<repo>/.agents/SKILLS/<skill-name>/
```

Then invoke by name:

```
$migrate-struts2-to-spring plan the next route slice
$java-tester review the tests added in the current diff
```

Each skill also ships `agents/openai.yaml`, which supplies the display name, short description, and
default prompt for the Codex skill picker.

**Portability.** Nothing here depends on Codex beyond that one metadata file. The skills are
Markdown, and the `SKILL.md` + `references/` + `assets/` layout is the same shape other agent
runtimes use, so porting is a matter of the front matter and the install path.

## Where these came from

The migration these were built for currently has **621 routes catalogued, 601 of them Spring-owned**,
349 with test or live-runtime verification, and 31 legacy action classes remaining, against a suite
of roughly 2,000 test files. Every route carries a contract record, a compatibility alias, and an
explicit list of what has *not* been verified yet.

The method behind that — functional slices, characterization before change, compatibility forwards
instead of redirects, a closed status vocabulary, and verification as a separate role from
implementation — is written up here:

**[Case study: migrating 600+ routes from Struts 2 to Spring](https://viachaslaustrelnikau.github.io/case-study.html)**

## Licence

MIT — see [LICENSE](LICENSE).
