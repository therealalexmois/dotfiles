# Indexes

## Design from access paths

- Derive indexes from frequent/important predicates, joins, ordering, grouping, and uniqueness—not from column presence alone.
- For multicolumn B-tree indexes, start from equality/range/order needs and data distribution. Do not repeat the obsolete absolute claim that later columns can never help: version and skip-scan behavior matter.
- Use partial indexes only when the query predicate implies the index predicate and the subset is stable/useful.
- Use `INCLUDE` for covering when payload width and write amplification are justified; index-only scans also require sufficient all-visible pages.
- Use expression indexes only when query expressions match and function volatility permits it.

## Access methods

| Method | Typical fit | Key caveat |
| --- | --- | --- |
| B-tree | equality, range, ordering, uniqueness | column order and distribution matter |
| GIN | JSONB, arrays, full text | higher write/maintenance cost; operator class matters |
| GiST/SP-GiST | ranges, geometry, nearest-neighbor, specialized types | often lossy; rechecks may occur |
| BRIN | large physically correlated data | ineffective without correlation/range selectivity |

## Index audit

Before calling an index unused or duplicate, inspect:

- statistics reset/server start and observation window;
- primary/unique/exclusion/FK constraint roles;
- expression, predicate, collation, operator class, sort order, and included columns;
- queries on replicas, maintenance/seasonal jobs, and failover workloads;
- invalid/build state, size, write rate, HOT impact, and WAL cost.

`idx_scan = 0` is a lead, not deletion authorization. Prefer workload history from monitoring and a reversible observation period.

## Creating and rebuilding

- Choose regular vs `CONCURRENTLY` from availability, duration, extra work, transaction restrictions, partitioning, and migration tooling.
- Before a concurrent build, define how to detect and clean up an invalid index after interruption.
- Estimate disk and WAL headroom and monitor replica lag.
- Verify the intended query with before/after plans; also measure write regression and other query paths.
- `REINDEX CONCURRENTLY` and `DROP INDEX CONCURRENTLY` have their own restrictions; verify against the target version.

## Dropping

Dropping an index is destructive and can remove a safety constraint or a rare critical access path. Present exact index identity, dependencies, evidence window, expected write benefit/read risk, rollback recreation DDL, and a monitoring window; require explicit confirmation immediately before execution.
