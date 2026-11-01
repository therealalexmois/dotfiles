---
name: redis-best-practices
disable-model-invocation: true
description: Review checklist for Redis usage in code and configuration - key naming, data structure choice, caching and invalidation, TTL and memory, atomicity, messaging, high availability, persistence, security, connections and performance. Use explicitly when designing or reviewing Redis usage.
metadata:
  origin: derived
  upstream: https://github.com/mindrally/skills/tree/main/redis-best-practices
  upstream_note: "restructured into a checklist; the original guide is references/redis-patterns.md"
  imported_at: 2026-06-25
---

# Redis Review Checklist

Walk the checklist against the code or config under review. Report each item as OK, ISSUE (with file:line and the concrete risk) or N/A. Read [references/redis-patterns.md](references/redis-patterns.md) for commands and examples behind any item.

## Keys
- [ ] Keys follow one `object-type:id:field` scheme with a service prefix.
- [ ] Keys are short but readable; no unbounded user input inside key names.

## Data structures
- [ ] The structure fits the access pattern: hash for objects, sorted set for rankings and time ranges, stream for durable queues, set for membership.
- [ ] No large values or collections that grow without a cap (use `LTRIM`, `ZREMRANGEBYSCORE`, stream `MAXLEN`).

## Caching
- [ ] Pattern is explicit (cache-aside or write-through) and the source of truth is clear.
- [ ] Invalidation is defined for every write path; tag sets or versioned keys for group invalidation.
- [ ] No `KEYS` in production code; `SCAN` for iteration.
- [ ] Stampede protection for hot keys (lock, early refresh or jittered TTL).

## TTL and memory
- [ ] Every cache key has a TTL; TTLs are jittered where many keys expire together.
- [ ] `maxmemory` and `maxmemory-policy` match the workload (cache vs. durable data).
- [ ] Big keys checked with `MEMORY USAGE` or `--bigkeys`.

## Atomicity
- [ ] Multi-step updates use `MULTI`/`EXEC`, `WATCH` or a Lua script, not read-modify-write from the client.
- [ ] Lua scripts are short, deterministic and touch only keys passed in `KEYS`.

## Messaging
- [ ] Pub/Sub only where message loss is acceptable; streams with consumer groups and `XACK` otherwise.
- [ ] Pending entries are reclaimed (`XAUTOCLAIM`) and dead letters handled.

## Availability and persistence
- [ ] Topology (single, replica + Sentinel, Cluster) matches the availability target.
- [ ] Cluster keys that are used together share a hash tag `{...}`.
- [ ] RDB/AOF settings match the acceptable data loss; restore was tested.

## Security
- [ ] Auth/ACL enabled, TLS on untrusted networks, Redis not exposed publicly.
- [ ] Dangerous commands (`FLUSHALL`, `CONFIG`, `KEYS`) disabled or renamed.

## Connections and performance
- [ ] Connection pool with bounded size and timeouts; clients reused.
- [ ] Batched calls use pipelining or `MGET`/`MSET`; no N+1 round trips.
- [ ] No blocking or O(N) commands on the hot path; slow log and latency monitored.
