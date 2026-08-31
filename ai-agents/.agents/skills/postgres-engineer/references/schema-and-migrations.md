# Schema and migrations

## Model from invariants

- Identify entities, ownership, lifecycle, cardinality, uniqueness, and deletion semantics before writing DDL.
- Encode durable invariants with `NOT NULL`, `CHECK`, `UNIQUE`, `FOREIGN KEY`, and exclusion constraints where appropriate.
- Do not add `ON DELETE CASCADE` by default. Choose `RESTRICT`/`NO ACTION`, `CASCADE`, or `SET NULL` from ownership and recovery requirements.
- Index a foreign-key column when deletes/updates of the parent or joins from the child make it useful; verify workload rather than applying a universal rule.

## Data types

- Prefer native semantic types (`uuid`, `timestamptz`, numeric types, ranges, arrays) when they encode real meaning.
- Choose integer identity vs UUID from generation locality, merge/offline requirements, exposure, index locality, storage, and interoperability.
- UUIDv4 may increase random B-tree insertion; time-ordered UUIDs reduce that effect but do not make UUID universally superior.
- Choose `ENUM`, lookup table, domain, or `CHECK` from change frequency, ownership, ordering, portability, and migration needs.
- Use `numeric` for exact decimal requirements; do not use it reflexively where bounded integers or floating point match the domain.
- Use `jsonb` for genuinely flexible/nested attributes, not to avoid modeling stable relational data.

## Naming and defaults

- Follow the project's established naming convention. Singular vs plural is not a PostgreSQL correctness rule.
- Avoid unquoted reserved or special keywords such as `user` and `order` in examples and new schemas.
- Add timestamps and audit columns only when their semantics and writers are defined.
- Clarify whether time represents an instant (`timestamptz`) or a wall-clock value independent of zone (`timestamp`).

## Migration review

For each migration, determine:

1. PostgreSQL version and migration runner transaction behavior.
2. Locks acquired and how long they may be held.
3. Whether the operation rewrites/scans the table or validates existing rows.
4. Additional disk, WAL, replica lag, and recovery implications.
5. Compatibility during rolling application deployment.
6. Cancellation behavior, retry/idempotency, and rollback.

Use expand/migrate/contract for changes that cannot be made atomically across old and new application versions. Separate schema compatibility from data backfill. Batch and checkpoint large backfills; monitor WAL, locks, replica lag, and autovacuum.

## Review output

Return the invariant, proposed DDL, compatibility sequence, lock/scan/rewrite assessment, data-validation query, rollout, success criteria, and rollback. Never infer "zero downtime" merely from a syntactically online command.
