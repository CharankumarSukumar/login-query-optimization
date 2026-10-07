-- 05_queries_optimized.sql : run AFTER optimizations
\echo === Q1: login lookup by email (expression index) ===
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, username, password_hash, is_active
FROM users WHERE lower(email) = lower('user150000@example.com');

\echo === Q2: permissions of one user (materialized view) ===
EXPLAIN (ANALYZE, BUFFERS)
SELECT permission FROM mv_user_permissions WHERE user_id = 150000;

\echo === Q3: all users that have the admin role (role_id index) ===
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.username
FROM users u
JOIN user_roles ur ON ur.user_id = u.id
WHERE ur.role_id = (SELECT id FROM roles WHERE name = 'admin');

\echo === Q4: active users who logged in during last 7 days (partial index) ===
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM users
WHERE is_active AND last_login > now() - interval '7 days';
