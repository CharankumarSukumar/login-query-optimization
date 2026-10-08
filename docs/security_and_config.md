# Server configuration and security (Weeks 3-4)

Environment: Windows laptop, PostgreSQL 18.6, database `login_db`, 200,000 users.

## 1. Configuration tuning (`sql/07_config_tuning.sql`)
| Setting | Before (default) | After | Purpose |
|---|---|---|---|
| shared_buffers | 128 MB | 256 MB | more table and index pages cached in memory |
| work_mem | 4 MB | 16 MB | bigger sorts and hashes before spilling to disk |
| maintenance_work_mem | 64 MB (default) | 128 MB | faster index builds and view refreshes |
| effective_cache_size | 4 GB (default) | 1 GB | planner estimate of OS cache (set to match a laptop) |
| listen_addresses | `*` | `localhost` | see section 2 |

Applied with `ALTER SYSTEM` and a service restart; verified in `pg_settings` (`pending_restart = f`).
Measured effect: single-row index queries did not change (`login_email` 17,110 tps before,
17,093 tps after at 20 clients), because they read one row. `perm_mv` at 20 clients went from
15,431 to 18,414 tps in a single run each, so treat that as suggestive, not proven.

## 2. Network exposure ("firewall")
- Before: `listen_addresses = '*'` - PostgreSQL accepted connections on every network card.
- After: `listen_addresses = 'localhost'`. Checked with
  `Get-NetTCPConnection -LocalPort 5432 -State Listen`, which shows only `127.0.0.1` and `::1`.
- Windows Defender Firewall has no PostgreSQL rule, so no inbound rule opens port 5432 to other computers.
- Client access rules live in `C:/Program Files/PostgreSQL/18/data/pg_hba.conf` (path from `SHOW hba_file`).

## 3. Passwords and encryption
- Passwords are never stored in plain text: `crypt(password, gen_salt('bf'))` (bcrypt, from `pgcrypto`).
- `authenticate_user()` compares with `crypt()`, locks the account after 5 failed attempts, and
  returns NULL for unknown, disabled or locked users (so it does not reveal which case it was).
- Least privilege: the application role `login_app` can only run `authenticate_user()` and read
  `mv_user_permissions`.
- Security tests are saved in `results/security_tests.txt` (correct password returns an id;
  wrong password and unknown user return NULL).

## 4. Backup and restore
`scripts/backup_restore.ps1` runs `pg_dump -Fc`, restores into `login_db_restore` and counts
users. Result on this laptop: `restored_users = 200000`.

## 5. Known limitations
- `ssl = off`: traffic to the database is not encrypted. This is acceptable only because the server
  accepts local connections only. Before allowing remote access, enable SSL and use `hostssl` rules in `pg_hba.conf`.
- `login_app` is created with a placeholder password in `sql/06_security.sql`; change it before any real use.
- PgBouncer: `config/pgbouncer.ini` is provided but PgBouncer was not installed or load-tested here.
