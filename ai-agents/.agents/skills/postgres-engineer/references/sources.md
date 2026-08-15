# Sources and maintenance

## Canonical sources

Verify version-sensitive behavior against primary documentation:

- PostgreSQL current docs: <https://www.postgresql.org/docs/current/>
- PostgreSQL versioned docs: `https://www.postgresql.org/docs/<major>/`
- `EXPLAIN`: <https://www.postgresql.org/docs/current/sql-explain.html>
- Indexes: <https://www.postgresql.org/docs/current/indexes.html>
- Routine vacuuming: <https://www.postgresql.org/docs/current/routine-vacuuming.html>
- Monitoring: <https://www.postgresql.org/docs/current/monitoring.html>
- HA/replication: <https://www.postgresql.org/docs/current/high-availability.html>
- Backup/restore: <https://www.postgresql.org/docs/current/backup.html>

For managed services, extensions, PgBouncer, drivers, ORMs, and migration tools, use the official documentation for the exact deployed product/version. Clearly label inferences.

## Version discipline

- Determine `server_version`/`server_version_num` rather than assuming "current".
- Distinguish server, client/driver, extension, pooler, and provider versions.
- Do not copy defaults from another major version without verification.
- When a feature differs by version, state the supported range or provide version branches.

## Upstream inspirations

This skill was synthesized and substantially rewritten from provider-neutral parts of:

- PlanetScale `database-skills/skills/postgres`: <https://github.com/planetscale/database-skills/tree/main/skills/postgres>
- Jeff Allan `claude-skills/skills/postgres-pro`: <https://github.com/Jeffallan/claude-skills/tree/main/skills/postgres-pro>

Source snapshots used for the initial synthesis on 2026-08-15:

- PlanetScale: `af0ce0cfb65cca4cc21d18ca0d9cf270ca99d488`
- Jeff Allan: `882ef55e377dbf9a4dbe496bb41ac6ccd0e555cf`

PlanetScale hosting recommendations, CLI/Insights material, and other provider-specific instructions were intentionally excluded. Unsafe recipes, universal thresholds, stale version claims, and categorical tuning rules were replaced with evidence and safety gates. See the bundled license notices.
