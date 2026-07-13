# Struts 2 to Spring MVC Migration Guidelines

## 1. Migration objective

Use a route-by-route strangler migration:

- Replace each Struts action with a Spring MVC controller.
- Rework the corresponding JSP, JavaScript, and other clients in the same migration slice.
- Preserve observable client behavior during the transition.
- Keep legacy routes temporarily available when canonical routes change.
- Remove Struts only after every route and client has migrated.
- Upgrade Spring, Java, Spring Security, and other dependencies in a later phase.

Spring 3.2 is only a temporary migration platform, not the final target.

## 2. Stabilize the application first

Before migrating routes:

- Establish the effective runtime classpath.
- Remove duplicate Struts versions and align Spring module versions.
- Introduce Maven or Gradle with locked versions, initially reproducing the existing WAR.
- Record servlet filters, ordering, URL mappings, security rules, and interceptors.
- Add automated smoke tests around critical workflows.
- Avoid combining route migration with business-logic refactoring.

The current combination of checked-in JARs, several Struts versions, and mixed Spring patch versions makes reproducible builds a prerequisite.

## 3. Create a complete route inventory

For every Struts action, record:

- HTTP method and route.
- Struts namespace and action class.
- Request parameters and accepted content types.
- Struts interceptors.
- Validation rules.
- JSP result, redirect, or serialized response.
- Session attributes and cookies.
- Authentication and authorization rules.
- Error and validation responses.
- JSP, JavaScript, mobile, integration, or third-party clients.
- File upload or download behavior.
- Downstream business services.

Prioritize low-risk routes first, followed by representative complex routes. Leave authentication, large uploads, and highly shared workflows until the migration pattern is proven.

## 4. Migration mapping

| Struts concept | Spring replacement |
|---|---|
| Action class | Focused `@Controller` method |
| `struts.xml` action mapping | Explicit `@RequestMapping` |
| Action fields and ValueStack | Request DTOs and explicit model attributes |
| Parameters interceptor | Spring binding with allowed fields |
| `validate()` or validation XML | Bean Validation and `BindingResult` |
| Struts result | View name, redirect, or `ResponseEntity` |
| Struts interceptor | MVC interceptor, servlet filter, Spring Security, or service decorator |
| Exception mapping | Central `@ControllerAdvice` and exception handlers |
| Struts form tags | Spring form tags, JSTL, or standard HTML |
| `SessionAware` and similar interfaces | Explicit session access; minimize session state |
| Struts file upload | Spring multipart handling |

Spring MVC supports annotated mappings, request-body conversion and validation, explicit responses, and centralized exception handling. Use only APIs available in the temporary Spring 3.2 baseline during phase one. See the Spring documentation for [`@RequestMapping`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/bind/annotation/RequestMapping.html) and [`@RequestBody`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/bind/annotation/RequestBody.html).

## 5. Per-route procedure

For each migration slice:

1. Capture the existing behavior with characterization and contract tests.
2. Extract business logic from the Struts action if it is not already in a service.
3. Implement a thin Spring MVC controller calling the existing service.
4. Use explicit request and response DTOs; do not expose persistence entities.
5. Reproduce validation, authorization, redirects, status codes, and errors.
6. Rework the corresponding JSP and JavaScript code.
7. Add the new route to the external route catalog.
8. Provide a compatibility mapping for the legacy route when necessary.
9. Run old-versus-new contract comparisons.
10. Deploy behind a feature flag or controlled routing rule.
11. Monitor errors, latency, authentication failures, and unexpected legacy-route traffic.
12. Remove the Struts action only after all known clients have migrated.

## 6. Frontend and client requirements

Frontend migration is part of each route migration, not a later cleanup task.

Reworked clients must remove dependencies on:

- `.do` action naming conventions.
- Struts namespaces and result names.
- Struts-generated form field names.
- ValueStack property resolution.
- Struts form, URL, iterator, and error tags.
- Implicit parameter conversion.
- Struts-specific validation responses.
- Accidental response formats or undocumented redirects.

During the first phase, users and external clients should not observe changes to:

- Page appearance and workflow.
- Authentication and session behavior.
- Validation messages.
- Redirect destinations.
- Response fields and HTTP semantics.
- Cookies, headers, locale, and encoding behavior.

Where a route changes, keep the old route as a temporary alias or adapter. Avoid a redirect when it would change POST semantics, request bodies, authentication, or status codes.

## 7. External route catalog

Store every migrated route in a source-controlled file independent of Spring and Struts configuration, for example:

`docs/migration/route-mapping.yaml`

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

Catalog rules:

- Update the file in the same change as the controller.
- Give every route a stable identifier and owner.
- Record the HTTP method as well as the path.
- List all known clients and their migration status.
- Record compatibility behavior and the planned retirement date.
- Mark request or response differences explicitly.
- Do not retire a legacy route while any registered client remains pending.
- Publish the catalog to other client teams or CI as a versioned artifact.
- Use OpenAPI alongside it for REST contracts; retain the route catalog for migration status, aliases, JSP flows, and client ownership.

## 8. Security and cross-cutting behavior

- Preserve Spring Security filter ordering and access rules.
- Verify CSRF, session fixation, logout, cookies, and JWT behavior.
- Replace security-related Struts interceptors with Spring Security rules.
- Maintain a single authoritative CORS configuration.
- Do not run conflicting Tomcat and Spring CORS policies.
- Allow only explicit trusted origins, especially when credentials are enabled. See [Spring MVC CORS configuration](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/servlet/config/annotation/WebMvcConfigurer.html).
- Preserve correlation IDs, audit events, locale selection, and logging context.
- Return consistent sanitized errors without exposing stack traces.

## 9. Testing requirements

Each migrated route should have:

- Contract tests for request and response compatibility.
- Controller tests.
- Service tests where logic was extracted.
- JSP rendering and form-submission tests.
- Authentication and authorization tests.
- Validation and error-path tests.
- Upload and download tests where applicable.
- End-to-end tests for critical workflows.
- Tests confirming both canonical and compatibility routes behave correctly.
- Monitoring that identifies remaining traffic to legacy routes.

## 10. Struts removal gate

Remove Struts only when:

- No route is handled by a Struts action.
- No JSP contains Struts tags.
- No client depends on Struts URLs or payload conventions.
- The external route catalog has no pending clients.
- Compatibility routes are either intentionally retained in Spring or retired.
- Struts filters, listeners, plugins, configuration, and JARs are removed.
- The application starts and passes its complete regression suite without Struts.
- A dependency scan confirms that Struts is absent from the WAR.

## 11. Subsequent modernization phase

After Struts removal:

- Upgrade to a supported Java version.
- Upgrade Spring Framework and Spring Security in controlled increments.
- Upgrade Jackson, JJWT, Commons FileUpload, Commons IO, logging, and SOAP dependencies.
- Modernize the servlet container and deployment descriptor.
- Consider replacing JSP incrementally, without changing backend contracts unnecessarily.
- Remove temporary compatibility routes after all registered clients have migrated.

Do not select the final Spring version until the supported Java version, servlet container, Jakarta migration requirements, and deployment constraints are known.
