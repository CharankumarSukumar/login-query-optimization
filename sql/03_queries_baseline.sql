-- 03_queries_baseline.sql : run BEFORE optimizations
\echo === Q1: login lookup by email ===
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, username, password_hash, is_active
FROM users WHERE lower(email) = lower('user150000@example.com');

\echo === Q2: permissions of one user (4-table join) ===
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT p.name
FROM users u
JOIN user_roles ur       ON ur.user_id = u.id
JOIN role_permissions rp ON rp.role_id = ur.role_id
JOIN permissions p       ON p.id = rp.permission_id
WHERE u.username = 'user150000';

\echo === Q3: all users that have the admin role ===
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.username
FROM users u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r       ON r.id = ur.role_id
WHERE r.name = 'admin';

\echo === Q4: active users who logged in during last 7 days ===
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM users
WHERE is_active AND last_login > now() - interval '7 days';
