# Query performance

## Evidence sequence

1. Capture the normalized query, parameter values/distribution, frequency, concurrency, result cardinality, and latency objective.
2. Inspect schema, indexes, statistics freshness, table/index sizes, and relevant settings.
3. Start with `EXPLAIN (FORMAT JSON)` if executing the query is unsafe or expensive.
4. Use `EXPLAIN (ANALYZE, BUFFERS, WAL, SETTINGS, FORMAT JSON)` only after assessing execution, locks, load, and side effects.
5. Compare estimated vs actual rows, loops, filters, I/O, temp spill, memory, and time at each important node.

## Reading plans

- There is no universal ranking of Seq Scan, Index Scan, Bitmap Scan, and Index Only Scan.
- A Seq Scan may be optimal for a small table or a query reading a large fraction of it.
- Multiply per-loop actual rows/time by loops when reasoning about repeated nodes.
- Large estimate errors point to stale/insufficient statistics, correlation, skew, expressions, or cross-column dependency.
- `Index Only Scan` still depends on visibility-map coverage and may perform heap fetches.
- Separate server execution from client/network/result-serialization time.

## Candidate interventions

- Rewrite only after identifying the expensive mechanism: excess rows, poor join order, repeated work, sort/hash spill, non-sargable predicate, deep offset, or N+1 calls.
- Consider extended statistics for correlated columns before forcing planner settings.
- Use keyset pagination when stable ordering and navigation semantics permit it; keep a deterministic tie-breaker.
- Replace `UNION` with `UNION ALL` only when deduplication is unnecessary.
- Replace a correlated subquery or `IN` with a join/`EXISTS` only when semantics remain identical and the measured plan improves.
- Avoid session/global planner toggles as a permanent fix unless the root cause and wider workload impact are understood.

## Benchmarking

- Compare identical logical work with warmed and cold-cache effects labeled.
- Use representative parameters and concurrency, not one convenient literal.
- Record plan, runtime distribution, CPU/I/O, rows returned, locks, WAL, and replica impact.
- Re-run correctness tests. A faster query returning different rows is a regression.

## Output checklist

State the bottleneck node/mechanism, evidence, proposed change, expected trade-off, exact verification query, and rollback. If the plan or parameters are absent, do not fabricate them; provide a targeted collection command or request.
