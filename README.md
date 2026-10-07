# Optimizing Query Performance for User Login System

A PostgreSQL project to make login and authentication queries faster using indexes and execution plan analysis.

## Database

Database: `login_system` (PostgreSQL 18, pgAdmin 4)

Tables: `users`, `roles`, `permissions`, `user_roles`, `role_permissions`

## Files

- `schema.sql` - tables and indexes
- `sample_queries.sql` - login query and performance test queries

## Week 1 Progress

**Day 1 - Database setup:** Created 5 tables and added sample data (5 users, 3 roles, 4 permissions).

**Day 2 - Schema review and indexes:**
- Reviewed the schema. PostgreSQL made 9 indexes automatically (primary keys and UNIQUE columns).
- Added 2 indexes on JOIN columns: `user_roles(role_id)` and `role_permissions(permission_id)`.
- Verified the indexes with `pg_indexes` and `pg_stat_user_indexes`.

**Day 3 - Query performance analysis:**
- Added 100,000 test users and used `EXPLAIN ANALYZE`.
- Search on `last_login_at` without an index: Seq Scan, 67.973 ms.
- After adding `idx_users_last_login_at`: Bitmap Index Scan, 0.384 ms (about 177 times faster).
- The login JOIN query uses the UNIQUE index on `username` and runs in 0.422 ms.
- Ideas for more speed: caching (for example Redis), buffering (PostgreSQL shared buffers), connection pooling, and regular `ANALYZE`.

**Day 4 - GitHub setup:** Created the repository, a new branch (`week1-schema-and-queries`), and committed the schema and sample queries.

**Day 5 - Review:** Reviewed the work and updated this README.
