---
name: add-production-logging
description: Audit, plan, add, improve, or review production logging and observability for a selected class, package, migrated operation, module, migration stage, or complete application. Use when Codex needs to preserve meaningful legacy logs, add diagnostic context to business operations and integrations, remove duplicate or unsafe logging, or perform a logging and observability audit without changing business behavior.
---

# Add Production Logging

## Objective

Improve production diagnosability with purposeful, searchable events. Use metrics
to reveal problems, traces to locate latency and failures, and logs to explain
identifiers, decisions, state changes, warnings, and failures. Do not create
mechanical logging merely to ensure that every class declares a logger.

## Scope modes

| Request | Action |
|---|---|
| Analyze or audit | Report useful coverage, duplication, sensitive-data risks, and infrastructure gaps without editing. |
| Plan | Specify exact event locations, levels, messages, fields, omissions, tests, and acceptance criteria. |
| Implement | Add or improve the smallest useful set of logs without changing business behavior. |
| Review | Inspect the diff for diagnostic value, duplication, severity, stack traces, performance, and data exposure. |

## Workflow

1. Read repository instructions and preserve unrelated work.
2. Identify the logging facade and implementation, configuration, appenders,
   output format, environment-specific levels, and nearby coding conventions.
3. Inspect centralized HTTP request logging, correlation or trace ID creation,
   MDC propagation, asynchronous boundaries, and cleanup.
4. Inspect global exception handling. Determine where unhandled exceptions and
   stack traces are already logged before adding failure events elsewhere.
5. Trace the requested business operations, state changes, rejected decisions,
   external calls, retries, timeouts, fallbacks, and partial failures.
6. Inspect corresponding legacy code when relevant. Preserve meaningful
   operational, business, security, and audit events unless an approved decision
   changes them.
7. Identify credentials, tokens, secrets, personal data, document contents, and
   request or response data that must be omitted or masked.
8. Plan each event's exact location, level, stable message, safe fields, and
   ownership before editing. Record why apparently plausible events should be
   omitted.
9. Add or improve only events that help an operator understand a meaningful
   decision, transition, integration, abnormal condition, or failure.
10. Run the smallest relevant tests and static checks. Review the diff for
    business-behavior changes, accidental data exposure, duplicate events,
    repeated stack traces, and avoidable runtime cost.

## Technology selection

Prefer the repository's established logging facade, implementation,
configuration, and conventions. Do not add, replace, or upgrade logging
dependencies unless the user explicitly requests a logging-stack change.

When no production-capable logging stack exists, report the gap instead of
silently choosing a technology. Propose options based on the language and
framework, supported dependency versions, deployment platform, output and
ingestion requirements, structured-field support, correlation or tracing
integration, performance, and operational ownership.

When the user requests a new or replacement stack:

1. Separate the application-facing logging API from its implementation,
   formatting, transport, and storage concerns.
2. Prefer technology already compatible with the framework and telemetry
   pipeline over introducing a parallel ecosystem.
3. Explain the selected option, material alternatives, and tradeoffs before
   making broad cross-cutting changes.
4. Add only the dependencies and configuration required for the requested
   scope, then verify startup, production output, level controls, and failure
   behavior.

## Event ownership

### Central HTTP layer

Use an existing or explicitly requested filter or interceptor for normal request
lifecycle information:

- HTTP method and canonical route or safe request URI
- response status and duration
- safe authenticated user or client identifier
- correlation or trace ID
- canonical `/rest/...` versus legacy compatibility traffic

Do not repeat these fields independently in every controller. Do not introduce
new cross-cutting infrastructure during a narrowly scoped logging change unless
the user requests it; report the gap instead.

### Global exception handler

Use centralized exception handling for consistent unexpected-exception logging,
safe request context, correlation ID, stack trace ownership, and safe HTTP
response mapping. Log a complete stack trace once where an exception becomes
unhandled. Do not log the same exception with a stack trace at every layer.

### Controllers

Keep thin controllers free of routine lifecycle logs. Add a controller event
only for a meaningful decision owned by the HTTP boundary and not better placed
in a service, filter, security component, or exception handler. A controller
with no local logger is acceptable when centralized and service logging provide
sufficient observability.

### Services

Add service events when they provide production value for:

- significant business commands and completed state transitions
- rejected operations and important validation outcomes
- outbound integration attempts and outcomes
- retries, timeouts, fallbacks, circuit breakers, and degraded behavior
- partial failures or suspicious but recoverable conditions
- idempotency, duplicate-detection, or conflict decisions
- failures not already captured centrally with sufficient context

Avoid logging expected success for high-volume read-only operations unless it is
an operational milestone or approved audit event.

### Repositories

Do not log ordinary repository entry, exit, or successful queries. Rely on
database metrics and framework diagnostics for routine persistence activity.
Add an application event only for domain-relevant persistence outcomes, custom
repair behavior, or unusual fallback logic that cannot be understood at a
higher layer.

## Levels

- `ERROR`: Log an unexpected failure requiring investigation or intervention.
  Include its stack trace once.
- `WARN`: Log a recoverable abnormal condition, suspicious or rejected
  operation, exhausted retry, or degraded behavior.
- `INFO`: Log a meaningful business event, state transition, integration
  outcome, or operational milestone useful under normal production levels.
- `DEBUG`: Log investigation detail that is too noisy for normal production.
- `TRACE`: Reserve for exceptional low-level troubleshooting; do not introduce
  it routinely.

Choose severity from the event, not the method or class type. Follow stricter
project-specific level conventions when present.

## Message and field rules

- Prefer stable event wording and parameterized or structured fields supported
  by the current logging stack.
- Describe what happened instead of merely naming the execution location.
- Include safe, stable identifiers such as document ID, operation ID,
  customer or client ID, user ID, and correlation ID when available.
- Use MDC for correlation or trace IDs when existing infrastructure supports it.
- Make success, rejection, degradation, and failure events distinguishable and
  searchable.
- Avoid string concatenation when parameterized logging is available.
- Guard expensive diagnostic computations when the logging API does not defer
  their evaluation.
- Do not dump complete objects, collections, documents, requests, responses, or
  exception payloads.
- Avoid routine method-entry and method-exit events.
- Avoid duplicate events across filters, controllers, services, repositories,
  integration clients, and exception handlers.

## Sensitive data

Never log:

- passwords or credentials
- authentication or authorization headers
- access tokens, refresh tokens, session IDs, or API keys
- encryption keys or other secrets
- full personal data when an internal identifier is sufficient
- complete customs, invoice, waybill, or other sensitive document contents
- unfiltered request or response bodies

Apply the repository's masking policy when one exists. When uncertain, omit the
value and log only a safe identifier. Treat exception messages and third-party
payloads as potentially sensitive rather than automatically safe.

## Verification

Verify behavior with focused tests that exercise success, rejection, recoverable
abnormal conditions, and unexpected failure as applicable. Capture emitted
events only when tests can do so without coupling to incidental formatting.
Check that:

- the right layer owns each event
- required identifiers appear and forbidden data does not
- expected failures do not produce repeated stack traces
- disabled diagnostic logging avoids expensive work
- changes do not alter return values, exceptions, transactions, retries, or
  other business behavior

## Handoff

Report:

- logs added, changed, removed, or re-leveled
- useful logs intentionally omitted and which layer already owns the context
- remaining request logging, correlation, metrics, tracing, dashboard, alerting,
  or configuration gaps
- sensitive-data risks found and how they were handled
- tests and static checks run
