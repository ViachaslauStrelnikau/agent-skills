---
name: hibernate-criteria-to-jpa-criteria
description: Migrate legacy Hibernate 3/4/5 Criteria API code (`org.hibernate.Criteria`, `Restrictions`, `Projections`, `DetachedCriteria`, and result transformers) to the standard JPA Criteria API. Use when modernizing legacy Criteria queries, planning a staged Hibernate upgrade through 5.6, upgrading to Hibernate 6+, converting dynamic data-access searches, or preserving query semantics while replacing Hibernate-specific criteria constructs with `CriteriaBuilder`, `CriteriaQuery`, `Root`, joins, predicates, and typed projections.
---

# Hibernate Criteria to JPA Criteria

Convert each query deliberately; JPA Criteria has different composition and result-shaping rules from legacy Hibernate Criteria.

Scope this workflow to select queries built with legacy `org.hibernate.Criteria`. Treat JPA `CriteriaUpdate` and `CriteriaDelete` migrations as separate work because their construction, joins, persistence-context effects, and execution semantics differ.

Keep adjacent upgrade work separate. Inventory HQL, native SQL, CRUD and session lifecycle APIs, bootstrap internals, mappings, dialects, custom types, transaction integration, and caching, but do not silently rewrite them as part of a Criteria conversion. They have different compatibility boundaries and verification needs.

## Workflow

### Choose the upgrade route

Choose an exact target Hibernate version and its supported persistence namespace. Do not treat every Hibernate 6+ release as interchangeable.

For a staged runtime upgrade from Hibernate 3 or 4:

1. Reach Hibernate 5.6 with legacy Criteria temporarily intact. Treat 5.6 as a compatibility bridge, not the permanent target.
2. Run the query-conversion workflow below on 5.6 using `javax.persistence.criteria`.
3. Remove legacy Criteria imports, dependencies, translators, and alias-extraction assumptions.
4. Move to the selected Hibernate 6+ release and migrate Criteria imports to `jakarta.persistence.criteria` with the rest of the Jakarta namespace transition.

If the runtime is already on a suitable baseline, skip the bridge and run the same query-conversion workflow in that baseline's namespace.

### Convert each query

1. Inventory the source query: root entity, aliases, join types, restrictions, grouping, projection/result type, ordering, distinctness, pagination, fetches, and result transformation.
2. Build a typed query from either supported persistence entry point. The query tree is standard JPA Criteria in both cases; choosing `Session` or `EntityManager` does not require changing the surrounding persistence architecture:

   ```java
   // EntityManager entry
   CriteriaBuilder cb = entityManager.getCriteriaBuilder();
   CriteriaQuery<RecordType> cq = cb.createQuery(RecordType.class);
   Root<RecordType> root = cq.from(RecordType.class);
   List<RecordType> results = entityManager.createQuery(cq.select(root))
       .getResultList();
   ```

   ```java
   // Hibernate Session entry, still building a standard JPA Criteria query
   CriteriaBuilder cb = session.getCriteriaBuilder();
   CriteriaQuery<RecordType> cq = cb.createQuery(RecordType.class);
   Root<RecordType> root = cq.from(RecordType.class);
   List<RecordType> results = session.createQuery(cq.select(root))
       .getResultList();
   ```

3. Translate aliases to `Root`, `Join`, or `Fetch`; translate restrictions to `Predicate` values. Accumulate optional filters in a list and combine them explicitly with `cb.and(...)` or `cb.or(...)`.
4. Translate selection before execution. Use `select(root)` for entities, `select(cb.construct(...))` for DTOs, and `select(cb.tuple(...))` only where tuple access is intentional. `CriteriaQuery.multiselect(...)` remains relevant for older baselines but is deprecated in Jakarta Persistence 3.2.
5. Apply `where`, `groupBy`, `having`, `orderBy`, and `distinct` on the `CriteriaQuery`; apply `setFirstResult` and `setMaxResults` on the resulting `TypedQuery`.
6. Compare behavior with the old query against the same integration-test fixture. Assert ordered IDs, duplicates, counts, null handling, empty-filter behavior, and page boundaries; inspect generated SQL through the `org.hibernate.SQL` logger when the results or query shape differ.

Read [references/migration-map.md](references/migration-map.md) for legacy-to-JPA mappings and semantic traps.

## Core patterns

### Dynamic restrictions

Use typed metamodel attributes when available; otherwise use string paths carefully.

```java
CriteriaBuilder cb = entityManager.getCriteriaBuilder();
CriteriaQuery<Order> cq = cb.createQuery(Order.class);
Root<Order> order = cq.from(Order.class);
List<Predicate> filters = new ArrayList<>();

if (status != null) {
    filters.add(cb.equal(order.get(Order_.status), status));
}
if (from != null) {
    filters.add(cb.greaterThanOrEqualTo(order.get(Order_.createdAt), from));
}

cq.select(order)
  .where(cb.and(filters.toArray(new Predicate[0])))
  .orderBy(cb.desc(order.get(Order_.createdAt)));

List<Order> results = entityManager.createQuery(cq).getResultList();
```

### Spring Data JPA option

When the application already uses Spring Data JPA, consider expressing reusable predicate logic as `Specification<T>` and extending the repository with `JpaSpecificationExecutor<T>`. Keep direct JPA Criteria as the framework-neutral default. Use specifications primarily for composable filtering; assess custom projections, grouping, fetch joins, and count-query behavior separately.

```java
static Specification<Order> hasStatus(OrderStatus status) {
    return (root, query, cb) -> status == null
        ? cb.conjunction()
        : cb.equal(root.get(Order_.status), status);
}

interface OrderRepository
        extends JpaRepository<Order, Long>, JpaSpecificationExecutor<Order> {
}
```

### Joins and fetch joins

Create `Join` for predicates or selections. Use `fetch()` only to control fetching; it does not expose a portable path for filtering.

```java
Join<Order, Customer> customer = order.join(Order_.customer, JoinType.LEFT);
filters.add(cb.equal(customer.get(Customer_.active), true));

order.fetch(Order_.lines, JoinType.LEFT);
```

Decide query-level distinctness from the target provider and result semantics. Hibernate 6 removes duplicate root entities caused by join fetching during materialization, so do not add `distinct(true)` solely for that purpose on Hibernate 6. Other providers and non-fetch joins may require query-level distinctness; verify the result list and generated SQL.

Avoid collection fetch joins in a paged query unless the application has verified its provider-specific behavior. Prefer a two-step ID page plus a fetch query when correctness matters:

1. Page distinct root IDs using the full result-query predicates and a deterministic order ending in a unique tie-breaker such as the root ID.
2. Fetch the entities and required associations for exactly those IDs without database pagination.
3. Restore the ID-page order explicitly in SQL or application code; an `IN` predicate does not preserve input order.

Before using `distinct` ID pagination, verify that every ordering expression gives one deterministic value per root and is legal with the target database's `SELECT DISTINCT` rules. Ordering by a to-many or otherwise multiplying join is ambiguous: define an aggregate such as `min`/`max`, a correlated scalar subquery, or another explicit per-root sort rule. Merely adding the joined sort expression to the select list changes distinctness from IDs to tuples and can duplicate roots.

Keep the total-count query independent from both page queries.

### Counts and DTO projections

For an ungrouped entity query, give the count query its own `CriteriaQuery<Long>` and reuse only predicate-building logic. `Root`, `Join`, `Path`, and `Predicate` objects belong to the query tree that created them; never reuse result-query predicates in a count query. Invoke the predicate builder again with the count query's root. Do not carry fetch joins or entity ordering into it.

```java
private static Predicate[] buildOrderPredicates(
        CriteriaBuilder cb, Root<Order> root, OrderFilter filter) {
    List<Predicate> predicates = new ArrayList<>();
    if (filter.getStatus() != null) {
        predicates.add(cb.equal(root.get(Order_.status), filter.getStatus()));
    }
    if (filter.getFrom() != null) {
        predicates.add(cb.greaterThanOrEqualTo(
            root.get(Order_.createdAt), filter.getFrom()));
    }
    return predicates.toArray(new Predicate[0]);
}
```

Call the builder separately for each query root:

```java
CriteriaQuery<Order> resultCq = cb.createQuery(Order.class);
Root<Order> resultRoot = resultCq.from(Order.class);
resultCq.select(resultRoot)
        .where(buildOrderPredicates(cb, resultRoot, filter));

CriteriaQuery<Long> countCq = cb.createQuery(Long.class);
Root<Order> countRoot = countCq.from(Order.class);
countCq.select(cb.count(countRoot));
countCq.where(buildOrderPredicates(cb, countRoot, filter));
```

Define the count's unit before choosing the aggregate: joined rows, distinct root entities, or result groups. Preserve `cb.count(countRoot)` when the legacy query intentionally counted joined rows. Use `cb.countDistinct(countRoot)` only when the required total is distinct roots, including when joins multiply rows but the page total is defined in root entities. Verify this decision independently from result-query distinctness.

Handle grouped queries separately. Define whether the requested total means source rows or result groups. A query that selects `count(root)` and retains `groupBy` returns one count per group, not one scalar total; do not call `getSingleResult()` on it as a page total. Build and test a dedicated count of the grouping keys. When a multi-column or `having`-dependent group count is not expressible portably, use an explicitly accepted provider extension or native count query rather than silently changing its meaning.

Use a typed constructor selection for DTO results:

```java
CriteriaQuery<OrderSummary> summaryCq = cb.createQuery(OrderSummary.class);
Root<Order> summaryRoot = summaryCq.from(Order.class);
summaryCq.select(cb.construct(OrderSummary.class,
    summaryRoot.get(Order_.id), summaryRoot.get(Order_.total)));
```

## Migration guardrails

- Preserve `createAlias(..., LEFT_JOIN)` with `join(..., JoinType.LEFT)`; a predicate in `where` may intentionally turn a left join into an effective inner join, so confirm the old behavior.
- Do not translate plain `Restrictions.eq(path, null)` to `cb.isNull(path)`: legacy `eq` did not provide null-aware equality, so that rewrite changes behavior. The legacy SQL comparison evaluates to `UNKNOWN`, not simply false. Confirm the intended business behavior before choosing `isNull`, a constant predicate, or another explicit condition.
- Treat plain `Restrictions.ne(path, null)` the same way; do not translate it mechanically to `cb.isNotNull(path)`. A constant false predicate such as `cb.disjunction()` is result-equivalent only when the comparison contributes positively to the final restriction. It is not generally equivalent under `not` or in another context where SQL `UNKNOWN` is observable.
- Translate `Restrictions.eqOrIsNull(path, value)` to `value == null ? cb.isNull(path) : cb.equal(path, value)`, and translate `Restrictions.neOrIsNotNull(path, value)` analogously with `cb.isNotNull`/`cb.notEqual`.
- Treat empty `IN` inputs as a business-rule decision. Do not emit an invalid or accidental broad query.
- Replace `setResultTransformer` with an explicit DTO constructor, `Tuple`, or application-side mapping. Keep aliases only if the target mapping requires them.
- Never represent a partial projection by constructing or setter-populating an entity class. Select the full root when entity semantics are required; otherwise use a DTO, record, `Tuple`, or scalar result.
- Do not mechanically replace `Criteria.DISTINCT_ROOT_ENTITY` with `cq.distinct(true)`: SQL/query distinct is not identical to legacy post-materialization root deduplication, and Hibernate 6 already removes root duplicates caused by join fetching. For paged collection joins, page distinct root IDs, fetch entities in a second query, and restore the page order; application-side deduplication after pagination can produce short or inconsistent pages.
- Keep `distinct(true)` only when it corrects join-induced duplication; it can alter SQL and count semantics.
- Replace `DetachedCriteria` with a method that accepts `CriteriaBuilder` and the target `CriteriaQuery`/`Root`, or with a `Subquery` when the old query is embedded.
- Remove dependencies on internal Criteria translators, generated SQL aliases, and placeholder substitution. Rebuild the condition from mapped paths; if it is genuinely SQL-specific, isolate it in a parameterized native query or an explicitly accepted provider extension.
- Do not concatenate values originating outside the query definition into SQL restrictions, functions, or native SQL. Criteria API values are represented safely, but whether a provider binds or inlines them is provider- and configuration-dependent. When explicit binding is required, create a typed `ParameterExpression` and set it on the resulting query. Native-query fallbacks must use named or positional parameters.
- Reject helpers that accept a predicate fragment containing `ORDER BY`, grouping, pagination, or another non-predicate clause. Build ordering with `CriteriaQuery.orderBy(...)` and keep each clause in its proper query-model API.
- Do not use Hibernate's newer `org.hibernate.query.criteria` extensions unless the caller accepts provider lock-in; this skill targets portable JPA Criteria first.
- As an optional Hibernate-specific safeguard, enable `hibernate.query.fail_on_pagination_over_collection_fetch=true` where the selected Hibernate version supports it. This converts in-memory pagination over a collection fetch into a failure; it is not a portable JPA setting and does not replace query redesign or page-boundary tests.

## Verify

Compile after every batch. Execute old and new queries against the same fixture and compare ordered IDs, duplicates, counts, and page boundaries before deleting the legacy code. Capture generated SQL with the `org.hibernate.SQL` logger; enable bind-parameter logging for the project's Hibernate version when values matter. Use Hibernate statistics to detect query-count or N+1 regressions, but not as proof of result equivalence.
