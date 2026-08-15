# JSONB

## Modeling decision

Use `jsonb` when attributes are genuinely sparse, evolving, nested, or passed through as documents. Prefer relational columns/tables for stable invariants, joins, foreign keys, high-update fields, and frequently queried typed values.

Define required shape with generated columns and/or `CHECK` constraints when appropriate. JSONB validation is not inherently a PostgreSQL 15 feature; verify functions used against the target version.

## Operators and indexes

- `->` returns JSON/JSONB; `->>` returns text.
- `@>` containment can use a suitable GIN index.
- Default `jsonb_ops` supports more operators; `jsonb_path_ops` is narrower and often smaller/faster for supported containment/jsonpath operations.
- For a selective hot scalar path, an expression B-tree index on the extracted, correctly cast value may be better than indexing the whole document.
- Match the query expression and operator to the index expression/operator class exactly enough for planner use.

Examples:

```sql
CREATE INDEX events_payload_gin ON events USING gin (payload);
SELECT event_id FROM events WHERE payload @> '{"type":"login"}'::jsonb;

CREATE INDEX events_tenant_idx ON events ((payload ->> 'tenant_id'));
SELECT event_id FROM events WHERE payload ->> 'tenant_id' = $1;
```

Do not create both automatically. Choose from real predicates, cardinality, index size, update rate, and plan evidence.

## Operational considerations

- Updates create new row versions and may rewrite/compress large values; measure WAL and bloat.
- Large arrays/documents can cause write amplification and poor selectivity; normalize when elements have independent lifecycle/query needs.
- Casting malformed/missing scalar values can fail; encode validation or use safe application/migration handling.
- Avoid `SELECT *` as a reflexive ban, but avoid fetching large JSONB values when the caller does not need them.
- GIN indexes improve reads at write/storage/maintenance cost; inspect pending-list and vacuum behavior when relevant.

## Migration

For extracting JSONB fields into columns, backfill in bounded batches, validate equivalence, dual-read/write only when necessary, create indexes with an environment-appropriate method, switch readers, then remove old data only after explicit authorization and rollback expiry.
