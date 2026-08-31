# WAL, replication, and recovery

## WAL and checkpoints

- WAL provides crash recovery and replication; never disable durability controls in production for convenience.
- Diagnose checkpoint pressure from target-version statistics, WAL generation rate, requested vs timed checkpoints, write/sync time, and storage latency.
- `max_wal_size` is not a hard cap. Replication slots, archiving failures, backups, and high write load can retain more WAL.
- Monitor slot retention and archive failures before disk pressure becomes an outage.

## Replication design

Clarify physical vs logical replication, synchronous guarantees, read routing, lag tolerance, schema/DDL handling, failover ownership, and RPO/RTO.

- Physical streaming replicas require compatible binaries/storage and reproduce the cluster at WAL level.
- Logical replication has publication/subscription, replica identity, sequence, DDL, conflict, and large-transaction considerations.
- Replication slots protect consumers but can exhaust disk; never drop one without identifying its owner, activity, downstream recovery cost, and authorization.
- Byte lag, time lag, replay state, and application staleness answer different questions.

## Failover

Promotion is not complete HA. A safe design also covers:

1. failure detection and decision authority;
2. fencing the old primary and preventing split brain;
3. client routing/DNS/proxy/driver behavior and pool invalidation;
4. data-loss assessment and timeline consistency;
5. rebuilding/rejoining the old primary and other replicas;
6. failback and tested runbooks.

Require explicit confirmation immediately before manual promotion/failover. Do not provide a generic copy-paste Patroni/HAProxy recipe without topology, quorum store, authentication, TLS, and fencing context.

## Backup and PITR

- A backup is not proven until restore has been tested.
- Choose logical, physical, and PITR tooling from scale, selective recovery, version portability, RPO/RTO, encryption, retention, and provider support.
- PITR requires a valid base backup plus continuous usable WAL through the target; monitor archive freshness and restore tooling.
- Replication is not a backup against operator error, corruption, or unwanted replicated changes.

## Recovery workflow

Document exact source/target, immutable backup identity, checksums/manifest, target time/LSN, timeline, credentials, free space, expected duration, validation queries, application cutover, and rollback.

Restoring or replacing a data directory is destructive. Never emit a broad recursive-delete command as a routine step. Validate an exact target, stop the service, preserve/rename the old directory when feasible, verify backup and ownership, obtain explicit confirmation, then use provider/package-supported procedures.
