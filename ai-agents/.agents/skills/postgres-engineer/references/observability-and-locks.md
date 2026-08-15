# Observability and locks

## Evidence sources

| Question | Primary evidence |
| --- | --- |
| What is running/waiting? | `pg_stat_activity`, wait events |
| Who blocks whom? | `pg_blocking_pids()`, `pg_locks`, activity |
| Which statements consume time/I/O/WAL? | `pg_stat_statements`, logs, tracing |
| Are tables maintained? | `pg_stat_user_tables`, progress views |
| Are indexes used? | `pg_stat_user_indexes` plus stats age/workload history |
| Is the host saturated? | CPU, memory, swap, disk latency/queue, filesystem, network |
| Is replication healthy? | `pg_stat_replication`, slots, receiver/subscription views |

Statistics are cumulative and scoped; always record `stats_reset`, server start, collection configuration, and observation window. Ratios without workload context are not universal SLOs.

## Incident sequence

1. Preserve timestamps, symptoms, affected clients, and recent changes.
2. Check connection saturation, waits, blockers, longest transactions/queries, and error logs.
3. Correlate database evidence with host/container and network metrics.
4. Prefer cancellation over termination when intervention is authorized.
5. Confirm business impact and transaction ownership before canceling or terminating a backend.

## Locks

- Identify blocked PID, blocker PID, lock mode/object, transaction age, query, application/user, and wait duration.
- Do not kill the apparent blocker without checking whether it is performing a critical migration, backup, failover, or business transaction.
- Recognize that an idle transaction can retain locks and MVCC horizons even when it consumes little CPU.
- For planned DDL, set an appropriate `lock_timeout` and decide whether retry or abort is safer than waiting indefinitely.

## Logging and extensions

Use provider/version-appropriate logging. Avoid enabling highly verbose logging or `auto_explain` analysis globally without estimating overhead and sensitive-data exposure. `pg_stat_statements` requires compatible preload/configuration and a restart in common setups; verify provider support.

## Resetting statistics

Resetting statistics destroys evidence and can invalidate unused-index analysis. Snapshot first, state the purpose and scope, and require confirmation immediately before reset.
