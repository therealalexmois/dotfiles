# Transactions, MVCC, and VACUUM

## Transaction semantics

- PostgreSQL treats `READ UNCOMMITTED` as `READ COMMITTED`.
- `READ COMMITTED` uses a new snapshot per statement; multi-statement invariants may require explicit locking or stronger isolation.
- `REPEATABLE READ` and `SERIALIZABLE` can abort transactions; applications must retry the complete transaction safely.
- Keep transactions short. Investigate `idle in transaction`, long snapshots, prepared transactions, replication slots, and standbys that retain horizons.
- "Readers do not block writers" is only a shorthand; DDL, explicit locks, row conflicts, predicate locks, and maintenance introduce important exceptions.

## MVCC and vacuum

Updates/deletes leave tuple versions until no snapshot needs them. Plain `VACUUM` makes space reusable and maintains visibility/freeze state; it usually does not shrink the relation file. `VACUUM FULL` rewrites and takes an `ACCESS EXCLUSIVE` lock.

Do not diagnose bloat from `n_dead_tup` or a size ratio alone. Distinguish dead tuples, reusable free space, sparse pages, index bloat, TOAST growth, and expected retained capacity.

## Autovacuum diagnosis

Check:

1. last vacuum/analyze and current progress;
2. table size, change rate, dead/live estimates, inserts since vacuum;
3. per-table reloptions and global defaults;
4. long transactions and horizon blockers;
5. worker saturation, cost throttling, I/O, locks, and logs;
6. XID and multixact ages;
7. whether vacuum completes before new churn recreates pressure.

Tune per table from observed churn and vacuum duration before changing global settings. Never disable autovacuum globally. Avoid fixed scale factors or cost values without table size, workload, and I/O evidence.

## XID safety

Monitor database and relation age against the actual target-version settings. Treat wraparound warnings as an incident. Do not run aggressive cluster-wide maintenance blindly; identify blockers, disk/I/O capacity, table priority, and recovery options.

## Remediation choices

- Fix transaction scope/horizon blockers first.
- Tune autovacuum thresholds/cost/worker capacity from measured inability to keep up.
- Use plain vacuum for routine reuse/freeze.
- Consider `REINDEX`, `pg_repack`, `CLUSTER`, or `VACUUM FULL` only from the specific bloat/reclaim objective; each has locks, disk, WAL, and operational caveats.
- Verify reclaimed/reusable space, query performance, vacuum cadence, WAL, and replica lag.
