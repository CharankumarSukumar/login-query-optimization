# Test plan and results (Week 6)

Environment: Windows laptop (8 threads), PostgreSQL 18.6, 200,000 users, 232,200 user-role rows.

## Test cases
| ID | What is tested | How | Pass criterion | Result |
|---|---|---|---|---|
| T1 | Login by email speed | `EXPLAIN (ANALYZE, BUFFERS)` before and after index | Index scan, under 1 ms | 153.4 ms -> 0.47 ms: pass |
| T2 | One user's permissions | same | faster than the join | 1.49 ms -> 0.78 ms: pass (small gain) |
| T3 | Users with admin role | same | uses `idx_user_roles_role_id` | 212.2 ms -> 110.1 ms: pass (still scans `users`) |
| T4 | Recent active users | same | bitmap index scan | 160.2 ms -> 10.05 ms: pass |
| T5 | Security functions | `sql/06_security.sql` tests | id, NULL, NULL | pass |
| T6 | Load test | pgbench, 20 clients, 30 s | 0 failed transactions | pass (see below) |
| T7 | Stress test | `scripts/stress_test.ps1`, 20/50/90 clients, 15 s | 0 failed transactions | pass (see below) |
| T8 | Backup and restore | `scripts/backup_restore.ps1` | restored user count = 200000 | pass |
| T9 | Config applied | `pg_settings` after restart | `pending_restart = f` | pass |

## Load test (20 clients, 30 s, default configuration)
| Script | tps | Avg latency |
|---|---|---|
| login_email | 17,110 | 1.17 ms |
| perm_join | 5,233 | 3.82 ms |
| perm_mv | 15,431 | 1.30 ms |

## Stress test (tuned configuration, 15 s per run, 0 failed transactions)
| Clients | login_email tps | login_email latency | perm_mv tps | perm_mv latency |
|---|---|---|---|---|
| 20 | 17,093 | 1.17 ms | 18,414 | 1.09 ms |
| 50 | 11,854 | 4.22 ms | 18,921 | 2.64 ms |
| 90 | 12,318 | 7.31 ms | 18,827 | 4.78 ms |

## Findings
1. `login_email` peaks at 20 clients; with 50+ clients throughput falls about 30% and latency grows
   about 6x. The laptop has 8 threads, so extra clients compete for CPU. A connection pooler
   (PgBouncer, `config/pgbouncer.ini`) would keep the number of active connections near this peak.
2. `perm_mv` stays flat at roughly 18,500-18,900 tps up to 90 clients: the materialized view scales well.
3. The raw outputs are in `results/`.
4. Each figure is a single run on one laptop; repeat runs vary a few percent.
