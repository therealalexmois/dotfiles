# Partitioning and storage

## Partitioning decision

Partition for a concrete operational or query benefit:

- cheap retention/drop/detach;
- partition pruning on stable keys;
- isolated maintenance/index builds;
- bounded working sets or data placement;
- loading/switching data by partition.

Do not partition solely because a table crossed a generic row or byte threshold. Account for query predicates, partition count, planning overhead, skew, uniqueness constraints, foreign keys, default partitions, and operational automation.

## Design

- Choose range/list/hash from access and lifecycle semantics.
- Ensure common queries constrain the partition key and verify pruning in the target version.
- Pre-create future partitions and define behavior for unexpected keys.
- Understand that unique/primary-key constraints on a partitioned table generally must include partition keys; verify version-specific capabilities.
- Plan attach/detach/drop locks and validation. `CONCURRENTLY` options have restrictions.
- Require confirmation before detach/drop; detaching changes query-visible data and dropping destroys it.

## Storage mechanics

- Heap, indexes, TOAST, free-space map, visibility map, WAL, and temporary files have different growth/maintenance mechanisms.
- TOAST may compress/store wide values out of line; selecting a wide value can dominate I/O even when few rows match.
- Lower fillfactor may enable more HOT updates on update-heavy tables at the cost of space/cache density. Verify HOT rate and workload.
- Tablespaces add placement complexity and do not replace capacity management or backup design.

## Capacity and remediation

Track relation/partition/index/TOAST sizes, filesystem free space/inodes, growth rate, WAL/slot retention, temp files, and reclaim requirements. Distinguish space reusable by PostgreSQL from space returned to the filesystem.

Before any rewrite, detach, move, or reclaim operation, estimate extra disk, WAL, duration, locks, replica lag, backup coverage, cancellation behavior, and rollback.
