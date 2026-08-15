# Connections and memory

## Model

PostgreSQL normally uses one backend process per client connection plus auxiliary/parallel processes. Memory is a mixture of shared allocation and per-backend/per-operation allocation.

Treat `work_mem` as a per-plan-operation limit, multiplied by concurrent operations, parallel participants, and sessions; hash operations may use an additional multiplier. `effective_cache_size` is a planner estimate, not allocated memory.

## Connection incident

Collect:

- `max_connections`, reserved slots, current/peak sessions by user/database/application/state;
- active vs idle vs idle-in-transaction, connection age, churn, leaks, and timeouts;
- pooler mode/configuration and number of user/database pool pairs;
- backend/private memory, parallelism, temp spills, OOM/container limits;
- application concurrency, worker counts, retry storms, and failover/routing behavior.

Do not raise `max_connections` as the first response. It can increase process, memory, scheduling, and contention pressure.

## Pooling

Choose application pooling, PgBouncer session/transaction pooling, or direct connections from workload and feature requirements.

Transaction pooling can affect session state, temporary objects, advisory locks, prepared-statement behavior (depending on versions/configuration), `LISTEN/NOTIFY`, and connection-affine features. Verify the actual client, driver, ORM, PgBouncer version, and configuration.

Size pools from database capacity and total pool multiplication, not from one application's desired concurrency. Reserve operational access and account for migrations, monitoring, replicas, and failover.

## Memory tuning

- Diagnose temp spills and plan operators before increasing `work_mem`.
- Prefer targeted session/role/query settings for exceptional analytical work.
- Account for autovacuum workers and `maintenance_work_mem`/`autovacuum_work_mem`.
- Treat generic RAM percentages as initial hypotheses, not final settings.
- Correlate database memory with OS page cache, cgroup/container limits, swap, huge pages, and OOM events.

## Verification

Measure connection acquisition latency/errors, active backend count, throughput/latency, memory peak, temp I/O, CPU context switching, lock contention, and failover behavior. Include a pool rollback/bypass path.
