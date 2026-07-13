# Migrate Struts 2 to Spring Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create and validate a repository-local Codex skill that guides behavior-preserving, route-by-route migrations from Struts 2 to Spring MVC, including JSP/client migration and an external route catalog.

**Architecture:** Keep the frequently loaded workflow in a concise `SKILL.md`, place detailed migration guidance in one reference, and provide a reusable YAML route-catalog asset. Validate the skill test-first with fresh-context baseline and forward-test agents, then run the official structural validator and YAML parsing checks.

**Tech Stack:** Codex skills (`SKILL.md`), Markdown, YAML, Python skill-creator utilities, Context7 documentation lookup, Git.

## Global Constraints

- Name the skill and folder exactly `migrate-struts2-to-spring`.
- Migrate one backend route and all associated JSP, JavaScript, or external clients as a functional slice.
- Preserve client-visible behavior during Struts removal.
- Retain compatibility mappings while any registered client remains pending.
- Record every legacy-to-canonical route mapping in the external route catalog.
- Keep Struts removal separate from later Spring, Java, servlet-container, and Jakarta modernization.
- Do not prescribe Spring Boot, a frontend framework, workflow redesign, or generic automated source rewriting.
- Preserve unrelated user changes in the working tree.

---

## File Structure

| Path | Responsibility |
|---|---|
| `migrate-struts2-to-spring/SKILL.md` | Trigger metadata, concise workflow, task modes, safeguards, and resource routing |
| `migrate-struts2-to-spring/agents/openai.yaml` | Generated user-facing skill metadata |
| `migrate-struts2-to-spring/references/migration-guidelines.md` | Detailed route, frontend, security, testing, catalog, and removal guidance |
| `migrate-struts2-to-spring/assets/route-mapping.yaml` | Copyable old-route/new-route/client-status catalog template |
| `struts2-to-spring-migration-guidelines.md` | Existing source document; move into the skill reference path and remove from repository root |

### Task 1: Establish the failing baseline

**Files:** None.

**Interfaces:**
- Consumes: the approved design at `docs/superpowers/specs/2026-07-13-migrate-struts2-to-spring-design.md`.
- Produces: raw baseline output and a checklist of missed requirements for Task 2.

- [ ] **Step 1: Run a fresh-context agent without the new skill**

Use `fork_turns="none"` and this exact prompt:

```text
We have a legacy Java WAR with Struts 2 `.do` actions, Spring MVC 3.2 REST endpoints, JSP pages, JavaScript callers, and an external reporting client. Plan the migration of POST /customer/search.do to canonical POST /rest/customers/search. The JSP workflow must look and behave the same, and other clients will migrate later. Explain the implementation and completion criteria.
```

- [ ] **Step 2: Verify the baseline fails at least one required behavior**

Score the raw response against these exact criteria:

```text
[ ] Treats route + JSP + JavaScript clients as one migration slice
[ ] Keeps POST semantics without a redirect that can drop the body
[ ] Retains a server-side compatibility mapping for pending clients
[ ] Requires an external route-catalog update with per-client status
[ ] Preserves validation, security, session, errors, redirects, and payloads
[ ] Separates Struts removal from Spring/Java modernization
[ ] Requires characterization, contract, security, and end-to-end tests
```

Expected: at least one unchecked item. Preserve the agent's exact output in the task record; do not add a repository test-results file.

- [ ] **Step 3: Record the smallest guidance needed**

List only the failed criteria and any unsafe rationalization used by the baseline agent. Those failures define the minimum content of Task 2.

### Task 2: Scaffold and author the reference-backed skill

**Files:**
- Create: `migrate-struts2-to-spring/SKILL.md`
- Create: `migrate-struts2-to-spring/agents/openai.yaml`
- Create: `migrate-struts2-to-spring/assets/route-mapping.yaml`
- Move: `struts2-to-spring-migration-guidelines.md` to `migrate-struts2-to-spring/references/migration-guidelines.md`

**Interfaces:**
- Consumes: failed baseline criteria from Task 1 and the existing migration guideline.
- Produces: `$migrate-struts2-to-spring`, a readable detailed reference, and a copyable YAML route catalog.

- [ ] **Step 1: Initialize the skill with official tooling**

Run from `C:\MyFolder\agent-skills`:

```powershell
python 'C:\Users\User\.codex\skills\.system\skill-creator\scripts\init_skill.py' migrate-struts2-to-spring --path 'C:\MyFolder\agent-skills' --resources references,assets --interface 'display_name=Migrate Struts 2 to Spring' --interface 'short_description=Route-safe Struts 2 to Spring migration' --interface 'default_prompt=Use $migrate-struts2-to-spring to plan or implement a behavior-preserving route migration from Struts 2 to Spring MVC.'
```

Expected: the skill directory, resource directories, `SKILL.md`, and `agents/openai.yaml` are created without placeholder example files.

- [ ] **Step 2: Move the approved guideline into the skill**

Verify both resolved paths are inside `C:\MyFolder\agent-skills`, then run:

```powershell
Move-Item -LiteralPath 'C:\MyFolder\agent-skills\struts2-to-spring-migration-guidelines.md' -Destination 'C:\MyFolder\agent-skills\migrate-struts2-to-spring\references\migration-guidelines.md'
```

Expected: the full guideline exists only under `references/`.

- [ ] **Step 3: Replace the generated `SKILL.md` with this exact content**

```markdown
---
name: migrate-struts2-to-spring
description: Use when Codex needs to analyze, plan, implement, diagnose, or review a staged migration from Apache Struts 2 actions, JSPs, interceptors, or `.do` routes to Spring MVC while preserving HTTP contracts and client-visible behavior.
---

# Migrate Struts 2 to Spring

## Core principle

Migrate one route and every associated JSP, JavaScript caller, and external client as a functional slice. Preserve observable behavior during Struts removal; modernize Spring, Java, and the container afterward.

## Workflow

1. Classify the request as analysis, planning, diagnosis, implementation, or review. Stay read-only unless implementation is requested.
2. Inspect build metadata or JARs, `web.xml`, Struts and Spring configuration, filters, security rules, actions, controllers, JSPs, JavaScript, tests, and known consumers.
3. Establish effective framework versions. If duplicate JARs exist, report uncertainty rather than guessing. Use Context7 to resolve and fetch version-current Struts and Spring documentation before applying framework-specific APIs.
4. Inventory routes and select one low-risk slice. Capture method, path, parameters, payload, validation, security, session, errors, redirects, uploads, view, and consumers.
5. Write characterization and contract tests before migration changes.
6. Replace the action with a thin Spring MVC controller that delegates to existing services. Use explicit request, response, and view models.
7. Rework the slice's JSP and clients to remove Struts tags, ValueStack access, action names, implicit binding, and response assumptions without changing visible behavior.
8. When the canonical route changes, retain the legacy route as a Spring mapping or server-side adapter. Do not redirect a request when doing so can change its method, body, authentication, or status semantics.
9. Copy `assets/route-mapping.yaml` into the target project and update it in the same change. Keep the legacy mapping while any registered client is pending.
10. Run narrow controller/client tests, then relevant regression, security, upload, and end-to-end checks. Remove migrated Struts configuration only after both routes pass and traffic confirms the old route can retire.
11. Remove Struts filters, plugins, configuration, tags, and JARs only after every route and client passes the removal gate.

## Task modes

| Request | Action |
|---|---|
| Analyze or review | Report route coupling, compatibility risks, missing clients, and evidence; do not edit. |
| Plan | Produce ordered slices, contracts, catalog entries, tests, rollback, and completion gates. |
| Diagnose | Reproduce behavior and identify the Struts/Spring boundary; do not fix unless requested. |
| Implement | Change the smallest complete route-and-client slice and verify it. |

## Resources

- Read `references/migration-guidelines.md` before planning, implementing, or reviewing a migration.
- Copy and adapt `assets/route-mapping.yaml` when the target project lacks a route catalog.

## Non-negotiable safeguards

- Preserve URLs or provide compatibility mappings, payloads, status codes, validation messages, redirects, cookies, locale, security, and session behavior.
- Do not expose persistence entities as HTTP contracts.
- Do not weaken authentication, authorization, CSRF, CORS, validation, assertions, or tests to complete a migration.
- Do not combine route migration with unrelated business redesign.
- Do not retire a legacy route while its catalog contains a pending client.
- Preserve unrelated changes in dirty worktrees.

## Handoff

State the migrated route, compatibility route, clients updated, catalog path, tests run, remaining consumers, rollback method, and retirement gate.
```

- [ ] **Step 4: Create `assets/route-mapping.yaml` with this exact content**

```yaml
version: 1

routes:
  - id: customer-search
    owner: customer-team
    legacy:
      method: POST
      path: /customer/search.do
    canonical:
      method: POST
      path: /rest/customers/search
    compatibility:
      mode: server-side-alias
      legacy_route_active: true
      retirement_after: 2027-01-31
    contract:
      breaking: false
      request_changes: none
      response_changes: none
      authentication: existing-session
    backend_status: migrated
    clients:
      - name: customer-jsp
        owner: web-team
        status: migrated
      - name: reporting-client
        owner: reporting-team
        status: pending
```

- [ ] **Step 5: Validate structure, size, YAML, metadata, and placeholders**

Run:

```powershell
python 'C:\Users\User\.codex\skills\.system\skill-creator\scripts\quick_validate.py' 'C:\MyFolder\agent-skills\migrate-struts2-to-spring'
python -c "import pathlib,yaml; p=pathlib.Path(r'C:\MyFolder\agent-skills\migrate-struts2-to-spring\assets\route-mapping.yaml'); d=yaml.safe_load(p.read_text(encoding='utf-8')); assert d['version']==1 and d['routes'][0]['clients'][1]['status']=='pending'; print('route catalog valid')"
$words = ((Get-Content -Raw 'migrate-struts2-to-spring\SKILL.md') -split '\s+' | Where-Object { $_ }).Count; if ($words -gt 500) { throw "SKILL.md has $words words" } else { "SKILL.md words: $words" }
rg -n 'TBD|TODO|PLACEHOLDER' 'migrate-struts2-to-spring'
Get-Content -Raw 'migrate-struts2-to-spring\agents\openai.yaml'
```

Expected:

```text
Skill is valid!
route catalog valid
SKILL.md words: 500 or fewer
No placeholder matches
openai.yaml contains the approved display name, short description, and default prompt
```

- [ ] **Step 6: Commit the green implementation**

```powershell
git add -- 'migrate-struts2-to-spring'
git commit -m 'feat: add Struts 2 to Spring migration skill'
```

Expected: the skill files and root-file deletion are committed; unrelated files remain untouched.

### Task 3: Forward-test and close gaps

**Files:**
- Modify only if a test exposes a gap: `migrate-struts2-to-spring/SKILL.md`
- Modify only if a test exposes a gap: `migrate-struts2-to-spring/references/migration-guidelines.md`
- Modify only if a test exposes a gap: `migrate-struts2-to-spring/assets/route-mapping.yaml`

**Interfaces:**
- Consumes: the completed `$migrate-struts2-to-spring` skill from Task 2.
- Produces: verified behavior on JSP and external-client migration variants.

- [ ] **Step 1: Re-run the baseline scenario with the skill**

Use a fresh agent with `fork_turns="none"` and this exact prompt:

```text
Use $migrate-struts2-to-spring at C:\MyFolder\agent-skills\migrate-struts2-to-spring. We have a legacy Java WAR with Struts 2 `.do` actions, Spring MVC 3.2 REST endpoints, JSP pages, JavaScript callers, and an external reporting client. Plan the migration of POST /customer/search.do to canonical POST /rest/customers/search. The JSP workflow must look and behave the same, and other clients will migrate later. Explain the implementation and completion criteria.
```

Expected: every criterion from Task 1 is checked, including a server-side POST-compatible alias and route-catalog client status.

- [ ] **Step 2: Run an external-client retirement variation**

Use another fresh agent with `fork_turns="none"` and this exact prompt:

```text
Use $migrate-struts2-to-spring at C:\MyFolder\agent-skills\migrate-struts2-to-spring. Review a proposed change that deletes GET /reports/export.do after adding GET /rest/reports/export. The WAR contains duplicate Struts JAR versions. The JSP is migrated, but a scheduled reporting client has no named owner or migration confirmation. The pull request also upgrades Spring and Java. Decide whether the old route can be removed and list required changes.
```

Expected: the agent rejects route retirement, records the client as pending with an owner to resolve, preserves a compatibility mapping, refuses to guess the effective Struts version, separates modernization, and requests contract/security/regression evidence.

- [ ] **Step 3: Refactor only for observed failures**

If either forward test misses a criterion, edit the smallest relevant instruction or resource. Repeat the failing scenario until all criteria pass. Do not add hypothetical rules unsupported by a test failure.

- [ ] **Step 4: Run final verification**

Run:

```powershell
python 'C:\Users\User\.codex\skills\.system\skill-creator\scripts\quick_validate.py' 'C:\MyFolder\agent-skills\migrate-struts2-to-spring'
python -c "import pathlib,yaml; yaml.safe_load(pathlib.Path(r'C:\MyFolder\agent-skills\migrate-struts2-to-spring\assets\route-mapping.yaml').read_text(encoding='utf-8')); print('route catalog valid')"
rg -n 'TBD|TODO|PLACEHOLDER' 'migrate-struts2-to-spring'
git diff --check
git status --short
```

Expected: structural and YAML validation pass, no placeholders or whitespace errors appear, and Git shows only intentional tested refinements.

- [ ] **Step 5: Commit tested refinements when present**

```powershell
git add -- 'migrate-struts2-to-spring'
git diff --cached --check
git commit -m 'docs: harden Struts migration skill guidance'
```

Expected: create this commit only when forward testing required changes. If no files changed, report that no refactor commit was necessary.

### Task 4: Final handoff

**Files:** None.

**Interfaces:**
- Consumes: validator output, both forward-test outputs, and Git status.
- Produces: user-facing installation path, trigger examples, verification evidence, and any remaining limitations.

- [ ] **Step 1: Verify repository state and commit history**

Run:

```powershell
git status --short
git log -3 --oneline
```

Expected: no unintended changes; history contains the design and skill implementation commits.

- [ ] **Step 2: Report the finished skill**

Include:

```text
Skill path: C:\MyFolder\agent-skills\migrate-struts2-to-spring
Invoke with: $migrate-struts2-to-spring
Validated with: quick_validate.py, YAML parsing, baseline replay, JSP scenario, external-client scenario
Key limitation: no generic source-rewrite script; migrations remain project-specific and route-by-route
```
