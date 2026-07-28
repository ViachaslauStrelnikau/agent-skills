# Legacy Hibernate Criteria mapping

Use this reference while translating individual queries. Names below refer to the legacy `org.hibernate.Criteria` API, not Hibernate's JPA Criteria implementation. Treat the mappings as common cases, not as a substitute for checking overload-specific semantics.

| Legacy construct | JPA Criteria counterpart | Notes |
| --- | --- | --- |
| `session.createCriteria(Foo.class)` | `CriteriaQuery<Foo> cq = cb.createQuery(Foo.class); Root<Foo> root = cq.from(Foo.class);` | Create the typed query before creating its root. |
| `createAlias("customer", "c")` | `root.join("customer")` | Retain the `Join` variable instead of a string alias. |
| `createAlias(..., Criteria.LEFT_JOIN)` | `root.join(..., JoinType.LEFT)` | Check effects of later predicates. |
| `createAlias(..., joinType, withClause)` | `Join<?, ?> join = root.join(..., joinType); join.on(predicate);` | Rebuild the predicate from this join's query tree. Keep an alias restriction in `ON`; moving it to `WHERE` can change outer-join semantics. |
| nested `createCriteria(...)` / dotted aliases | chained `join(...)` calls | Retain each intermediate `Join`; do not assume a dotted string path creates the same joins or join types. |
| `Restrictions.eq(x, y)` | `cb.equal(path, y)` for non-null `y` | Plain legacy `eq` was not null-aware. With null, the SQL comparison evaluates to `UNKNOWN`; confirm intent rather than silently changing it to `isNull` or a constant predicate. A constant false predicate is only result-equivalent for a positive top-level restriction, not under negation or other three-valued predicate composition. |
| `Restrictions.ne(x, y)` | `cb.notEqual(path, y)` for non-null `y` | Plain legacy `ne` was not null-aware. Apply the same null and predicate-composition review as for `eq`; do not silently reinterpret null as `isNotNull`. |
| `Restrictions.eqOrIsNull(x, y)` | `y == null ? cb.isNull(path) : cb.equal(path, y)` | Preserve the legacy method's explicit null-aware behavior. |
| `Restrictions.neOrIsNotNull(x, y)` | `y == null ? cb.isNotNull(path) : cb.notEqual(path, y)` | Preserve the legacy method's explicit null-aware behavior. |
| `Restrictions.gt/ge/lt/le` | `cb.greaterThan`, `greaterThanOrEqualTo`, `lessThan`, `lessThanOrEqualTo` | Ensure attribute and value types are comparable. |
| `Restrictions.eqProperty/neProperty` | `cb.equal(path1, path2)` / `cb.notEqual(path1, path2)` | Resolve both paths from the correct root or join. |
| `Restrictions.gtProperty/geProperty/ltProperty/leProperty` | corresponding `CriteriaBuilder` comparison with two expressions | Ensure both expressions have compatible comparable types. |
| `Property.forName("x")` criteria and projection helpers | resolve `root.get("x")` or the appropriate join path, then apply the corresponding `CriteriaBuilder` predicate, order, or selection | `Property` combines path lookup with several operations; translate the invoked operation, not only the string property name. Prefer a static metamodel attribute when available. |
| `Restrictions.allEq(values)` | one `cb.equal(path, value)` per entry, combined with `cb.and(...)` | Apply the same null review as plain `eq`; do not silently reinterpret null entries. |
| `Restrictions.like` / `ilike` | `cb.like` / `cb.like(cb.lower(path), pattern.toLowerCase(Locale.ROOT))` | `ilike` is Hibernate-specific. Choose normalization based on storage and database behavior; see Case-insensitive matching below. |
| `Restrictions.like/ilike(..., MatchMode)` | construct the equivalent pattern, then use `cb.like(...)` | `EXACT`: value; `START`: value + `%`; `END`: `%` + value; `ANYWHERE`: `%` + value + `%`. Preserve existing `%` and `_` behavior unless the application intentionally introduces escaping. |
| `Restrictions.in` | `path.in(values)` | Define behavior for an empty collection. |
| `Restrictions.isNull/isNotNull` | `cb.isNull/isNotNull` | |
| `Restrictions.between` | `cb.between` | Use two comparisons for optional bounds. |
| `Restrictions.isEmpty/isNotEmpty` | `cb.isEmpty(collectionPath)` / `cb.isNotEmpty(collectionPath)` | Use a collection-valued path. Inspect generated SQL and indexes for large collections. |
| `Restrictions.sizeEq/sizeNe/sizeGt/sizeGe/sizeLt/sizeLe` | compare `cb.size(collectionPath)` with the requested size | Check provider SQL and performance; an existence or aggregate subquery may be preferable for complex cases. |
| `Restrictions.idEq(value)` / `Projections.id()` | compare or select the mapped ID path | Use the embedded-ID path or individual ID attributes required by the application's composite-ID mapping. |
| `Restrictions.naturalId().set(...)` | explicit predicates on mapped natural-ID attributes | Portable JPA Criteria has no natural-ID shortcut. Preserve every component and its null semantics; use Hibernate's natural-ID API only when provider lock-in is accepted. |
| `Example.create(entity)` | an explicit application predicate builder | JPA has no portable example-query equivalent. Reproduce the configured excluded properties, zero/null handling, case policy, and match mode deliberately. |
| `Restrictions.and/or/not` | `cb.and/or/not` | `cb.not(...)` wraps one predicate; parenthesize the intended predicate tree explicitly. |
| `Restrictions.conjunction()` | `cb.conjunction()` or `cb.and(predicates...)` | An empty conjunction is true. Do not mutate `predicate.getExpressions()`: JPA does not guarantee that the returned collection is mutable or live, and a provider may already have captured the predicate tree. Collect predicates in an application-owned list and pass them to `cb.and`. |
| `Restrictions.disjunction()` | `cb.disjunction()` or `cb.or(predicates...)` | An empty disjunction is false. Apply the same non-mutation rule and pass an application-owned predicate list to `cb.or`. |
| `Restrictions.sqlRestriction` | mapped expressions, `cb.function(...)`, or a native query | Use `cb.function` for a SQL function expression, not an arbitrary SQL fragment. Restructure through mapped paths when possible; otherwise use a native query or an explicitly accepted provider extension. |
| alias-dependent SQL restrictions, SQL alias placeholders, or internal Criteria translator output | mapped paths and standard predicates, or an isolated parameterized native query/provider extension | JPA Criteria exposes no portable physical SQL alias. Do not recover one through internal Hibernate translators or assume generated alias text is stable. Bind all external values in any fallback. |
| `add(...)` | `cq.where(...)` | Multiple legacy `add` calls are normally conjunctive. |
| `addOrder(Order.asc/desc(...))` | `cq.orderBy(cb.asc/desc(...))` | Put all `Order` instances in one call. |
| `Order.ignoreCase()` | order by `cb.lower(stringPath)` | Verify database collation and null ordering. Applying a function can prevent use of a normal index. |
| `setFirstResult`, `setMaxResults` | same methods on `TypedQuery` | Do not put pagination on `CriteriaQuery`. |
| `setFetchMode` / `FetchMode.JOIN` | `root.fetch(..., JoinType.LEFT)` | Verify duplicates and pagination. |
| `setProjection(Projections.rowCount())` | `cq.select(cb.count(root))` | Define whether the required total represents joined rows or distinct roots. Preserve joined-row counting when intentional; use `countDistinct` only when distinct roots are the required unit. |
| `Projections.property` | `cq.select(root.get(...))` | Change query result generic type. |
| `Projections.count/countDistinct` | `cb.count(path)` / `cb.countDistinct(path)` | The result type is `Long`; check null and join-duplication semantics. |
| `Projections.avg/sum/min/max` | corresponding `CriteriaBuilder` aggregate | Match the `CriteriaQuery` result type to the aggregate's JPA type. For nonnumeric comparable values, use `least` or `greatest` where appropriate. |
| `Projections.distinct(projection)` | select the mapped expression and call `cq.distinct(true)` | Verify SQL and result semantics; this is query-level duplicate elimination, not root-entity post-processing. |
| `Projections.projectionList` | `select(cb.construct(...))`, `select(cb.tuple(...))`, or `select(cb.array(...))` | Prefer DTO construction for stable output. `CriteriaQuery.multiselect(...)` is available on older baselines but deprecated in Jakarta Persistence 3.2. |
| `Projections.sqlProjection(...)` | mapped selections, portable `CriteriaBuilder` expressions/functions, or a typed native query/provider extension | There is no portable arbitrary SQL select fragment or equivalent for its SQL alias and Hibernate `Type[]` contract. Do not concatenate external values, and do not depend on generated table aliases. |
| `Projections.alias(projection, alias)` with `AliasToBeanResultTransformer` | `cb.construct(Dto.class, ...)` or aliased `Tuple` selections plus explicit mapping | Constructor projection is positional and requires a matching constructor. JPA has no portable setter-based `AliasToBean` equivalent. |
| setter-based result transformer targeting an entity class | `select(root)` for a full entity, or a DTO/record/`Tuple`/scalar projection for partial data | A setter-populated partial object is not a portable managed-entity projection. Do not use `cb.construct(EntityClass.class, ...)` to imitate partial entity state. |
| `Projections.groupProperty` | `groupBy(path)` plus selection | Add `having` separately. |
| `Criteria.DISTINCT_ROOT_ENTITY` | provider-aware result handling, `cq.distinct(true)`, or distinct-ID paging followed by an entity fetch | SQL/query distinct is not always equivalent to legacy post-materialization root deduplication. Hibernate 6 removes duplicate roots caused by join fetching during materialization. Application-side deduplication after pagination may shrink pages. |
| `setResultTransformer` | DTO constructor, `Tuple`, or mapper | There is no direct portable equivalent. |
| `DetachedCriteria` | reusable predicate method or `Subquery` | Bind it to the owning query explicitly. |
| `Subqueries.exists/notExists(detached)` | `cb.exists(subquery)` / `cb.not(cb.exists(subquery))` | Build the `Subquery` from the owning `CriteriaQuery`; a subquery cannot be executed independently. |
| `Subqueries.propertyIn/propertyNotIn` | `path.in(subquery)` / `cb.not(path.in(subquery))` | Match the selected subquery type to the outer path and preserve empty/null behavior. |
| scalar comparisons such as `Subqueries.lt(value, detached)` | compare a typed parameter expression with the scalar `Subquery`, for example `cb.lessThan(parameter, subquery)` | Preserve operand order: this form means the external value is less than the subquery result. Bind the parameter on the created query, use numeric comparison overloads when appropriate, and ensure the subquery selects exactly one compatible value. |
| property-to-subquery comparisons such as `Subqueries.propertyEq("x", detached)` | `cb.equal(resolvePath(root, "x"), subquery)` | Resolve the outer property from its actual root or join, preserve the comparison operator, and make the scalar subquery selection type compatible with the path. |
| correlated `DetachedCriteria` | `Subquery.correlate(outerRootOrJoin)` | Correlate explicitly when the inner query refers to the outer query; do not create an unrelated second root. |

## Case-insensitive matching

- When stored values have mixed case and the database comparison is case-sensitive, apply `cb.lower(path)` and normalize the parameter with `Locale.ROOT`, or apply the database's `lower()` semantics to both expressions.
- When values are normalized on write or the column/collation is already case-insensitive, normalize only as required by that contract and avoid wrapping the column unnecessarily.
- Check database collation, Unicode behavior, wildcard escaping, and the execution plan. Applying `lower()` to a column can prevent use of a normal index; prefer an appropriate case-insensitive collation, column type, or functional index when portability requirements permit it.

## Subquery sketch

```java
Subquery<Long> childIds = cq.subquery(Long.class);
Root<Child> child = childIds.from(Child.class);
childIds.select(child.get(Child_.parent).get(Parent_.id));
childIds.where(cb.equal(child.get(Child_.state), State.OPEN));

cq.where(root.get(Parent_.id).in(childIds));
```

## Review checklist

- Check entity result type, DTO constructor order, and scalar types.
- Check every legacy alias's join type and its use in predicates, sorting, and projections.
- Check alias `withClause` predicates remain in `ON` when outer-join semantics depend on them.
- Check `null`, empty collection, and case-insensitive matching behavior.
- Check duplicate roots, `distinct`, grouping, and count-query results separately; do not use a grouped `count(root)` result as a scalar page total.
- Check two-step ID pagination uses deterministic ordering and restores the ID-page order after fetching.
- Check distinct-ID ordering is legal for the target database and reduces joined or collection values to one explicit sort value per root.
- Check eager loading does not introduce N+1 queries or break pagination.
- Check no SQL fragment contains concatenated external values or smuggles `ORDER BY` into a predicate.
