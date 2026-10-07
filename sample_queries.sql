-- Sample queries for the login system

-- 1. Login query: get roles and permissions for one user
SELECT u.username, r.role_name, p.permission_name
FROM users u
JOIN user_roles ur ON ur.user_id = u.user_id
JOIN roles r ON r.role_id = ur.role_id
JOIN role_permissions rp ON rp.role_id = r.role_id
JOIN permissions p ON p.permission_id = rp.permission_id
WHERE u.username = 'madhu' AND u.is_active = true;

-- 2. Execution plan for the login query
EXPLAIN ANALYZE
SELECT u.username, r.role_name, p.permission_name
FROM users u
JOIN user_roles ur ON ur.user_id = u.user_id
JOIN roles r ON r.role_id = ur.role_id
JOIN role_permissions rp ON rp.role_id = r.role_id
JOIN permissions p ON p.permission_id = rp.permission_id
WHERE u.username = 'madhu' AND u.is_active = true;

-- 3. Users who logged in during the last hour (uses idx_users_last_login_at)
EXPLAIN ANALYZE
SELECT user_id, username
FROM users
WHERE last_login_at > NOW() - interval '1 hour';

-- 4. Add 100,000 test users (for performance testing)
INSERT INTO users (username, email, password_hash, is_active, created_at, last_login_at)
SELECT 'user_' || g,
       'user_' || g || '@example.com',
       md5(g::text),
       (g % 10 <> 0),
       NOW() - random() * interval '365 days',
       NOW() - random() * interval '30 days'
FROM generate_series(1, 100000) AS g;
