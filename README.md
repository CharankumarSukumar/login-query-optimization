# Optimizing Query Performance for a User Login System (PostgreSQL)

Final project - CodeZoner internship (SQL & Database Engineering).
Author: Charan (GitHub: CharankumarSukumar)

## 1. Goal
Make the queries of a login/authorization database (users, roles, permissions,
user_roles, role_permissions) fast, safe and measurable, with 200,000 sample users.

## 2. Project layout
| Path | Purpose |
|---|---|
| `sql/01_schema.sql` | Baseline schema (primary keys + unique username only) |
| `sql/02_seed.sql` | 200,000 users, 5 roles, 12 permissions |
| `sql/03_queries_baseline.sql` | 4 login/authorization queries with `EXPLAIN (ANALYZE, BUFFERS)` BEFORE tuning |
| `sql/04_optimizations.sql` | Indexes + materialized view |
| `sql/05_queries_optimized.sql` | Same queries AFTER tuning |
| `sql/06_security.sql` | bcrypt login function, lockout, least-privilege role |
| `pgbench/*.sql` | Load-test scripts |
| `sql/07_config_tuning.sql` | Server memory settings and `listen_addresses = localhost` |
| `config/pgbouncer.ini` | Optional connection pooling (provided, not load-tested) |
| `scripts/run_all.ps1` | Runs everything and saves results to `results/` |
| `scripts/backup_restore.ps1` | Backup (`pg_dump`) and restore test |
| `scripts/stress_test.ps1` | pgbench with 20, 50 and 90 clients |
| `docs/` | Normalization review, security/config notes, test plan, progress log |

## 3. How to run (Windows PowerShell)
```powershell
createdb -U postgres login_db
.\scripts\run_all.ps1 -Db login_db -User postgres
.\scripts\backup_restore.ps1 -Db login_db -User postgres
```

## 4. Optimizations applied
1. **Expression index** `lower(email)` - login by email no longer scans the whole table (also makes emails unique, case-insensitively).
2. **Index on `user_roles(role_id)`** - the primary key starts with `user_id`, so "users with role X" could not use it.
3. **Partial index** on `last_login WHERE is_active` - smaller index for the common "recent active users" report.
4. **Materialized view** `mv_user_permissions` - pre-joins 3 tables; acts as the in-database cache (replaces Redis from the roadmap). Refresh with `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_user_permissions;` after role changes.
5. **Connection pooling** with PgBouncer (`config/pgbouncer.ini`) - replaces the MySQL pooling item.

## 5. Results
Measured on my own laptop (Windows, PostgreSQL 18.6, 200,000 users).
EXPLAIN ANALYZE execution time:

| Query | Before | After | Plan change |
|---|---|---|---|
| Q1 login by email | 153.4 ms | 0.47 ms | Parallel Seq Scan -> Index Scan |
| Q2 permissions of a user | 1.49 ms (join) | 0.78 ms | 4-table join -> index-only scan on view |
| Q3 users with admin role | 212.2 ms | 110.1 ms | Seq Scan on user_roles -> Index Scan |
| Q4 recent active users | 160.2 ms | 10.05 ms | Parallel Seq Scan -> Bitmap Index Scan |

Note: Q2 was already fast before tuning (the join uses primary-key indexes), so the
single-query gain is small; the materialized view mainly helps under load (see below).
Q3 still scans the users table, so it improved about 2x, not more.

pgbench (20 clients, 4 threads, 30 s each, 0 failed transactions):

| Script | Throughput | Avg latency |
|---|---|---|
| login_email (indexed) | 17,110 tps | 1.17 ms |
| perm_join (4-table join) | 5,233 tps | 3.82 ms |
| perm_mv (materialized view) | 15,431 tps | 1.30 ms |

Stress test after configuration tuning (15 s per run, 0 failed transactions):

| Clients | login_email tps | perm_mv tps |
|---|---|---|
| 20 | 17,093 | 18,414 |
| 50 | 11,854 | 18,921 |
| 90 | 12,318 | 18,827 |

`login_email` peaks at 20 clients and slows down beyond that (the laptop has 8 threads), which is
the case for connection pooling. `perm_mv` stays flat. Raw outputs are in the `results/` folder;
see `docs/test_plan.md` for the full test plan.

## 6. Security and backup
- Passwords stored as bcrypt hashes (`pgcrypto`, `crypt` + `gen_salt('bf')`), never plain text.
- `authenticate_user()` locks an account after 5 failed attempts.
- App role `login_app` can only run the login function and read permissions.
- Backup/restore verified with `scripts/backup_restore.ps1` (200,000 users restored).
- PostgreSQL listens on `localhost` only (`sql/07_config_tuning.sql`); see `docs/security_and_config.md`.
- Known limitations: SSL is off (acceptable only for local connections), `login_app` has a placeholder
  password in `sql/06_security.sql`, and PgBouncer was not installed here.

## 7. Differences from the original roadmap
The roadmap mentions MySQL, Redis and a UI. This project uses PostgreSQL, so:
`EXPLAIN ANALYZE` replaces MySQL `EXPLAIN`, a materialized view replaces Redis,
PgBouncer replaces MySQL pooling, and the project is database-focused (no UI).

## 8. Conclusion
Targeted indexes cut login-by-email time from 153 ms to 0.47 ms (about 325x) and the
recent-active-users report from 160 ms to 10 ms (about 16x). The admin-role query and the
single permission lookup improved about 2x each. Under load, the materialized view served
about 2.9x more permission lookups per second than the 4-table join (15,431 vs 5,233 tps).
Remaining improvement: refresh the materialized view on a schedule and add table
partitioning if users grow into millions.
