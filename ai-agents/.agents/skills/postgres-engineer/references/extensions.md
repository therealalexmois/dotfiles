# Extensions

## Selection workflow

1. Confirm PostgreSQL exact version, provider/OS packaging, privileges, and allowed extension versions.
2. Verify whether the extension needs `shared_preload_libraries`, restart, background workers, superuser, external binaries, or schema objects.
3. Review upgrade, backup/restore, replication, failover, portability, and uninstall behavior.
4. Evaluate operational ownership, monitoring, security, and resource use.
5. Test on a representative environment before production enablement.

## Common categories

| Need | Candidates | Important checks |
| --- | --- | --- |
| Query statistics | `pg_stat_statements` | preload/restart, query text exposure, sizing |
| Text similarity | `pg_trgm` | GIN vs GiST, locale/collation, write cost |
| Spatial | PostGIS | geometry vs geography and matching index expression |
| Vectors | pgvector | model dimension, distance metric, exact vs ANN, recall, build memory |
| Maintenance | `pg_repack`, `pgstattuple` | binaries/privileges, locks, disk/WAL, provider support |
| Cryptographic functions | `pgcrypto` | key/secrets management, threat model, app-layer alternatives |
| Foreign access | `postgres_fdw` | credentials, pushdown, latency, distributed consistency |
| Time series | TimescaleDB or native partitioning | licensing/provider/version, migration and operational ownership |

## Guardrails

- Do not embed credentials in `CREATE USER MAPPING`, connection strings, or examples. Use protected mechanisms supported by the environment.
- Do not state a fixed vector dimension for "OpenAI embeddings"; it depends on the selected model/configuration.
- Do not assume extension SQL/API compatibility across versions.
- `pg_repack` minimizes blocking but still has lock, disk, WAL, trigger, and prerequisite considerations; do not call it lock-free.
- Installing an extension is a schema/operational change. Present impact and obtain authorization when implementation is requested.
- Dropping an extension may cascade to dependent objects/data and is destructive; require explicit confirmation.
