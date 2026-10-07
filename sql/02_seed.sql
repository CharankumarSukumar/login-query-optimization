-- 02_seed.sql : 200,000 users so performance differences are visible
TRUNCATE role_permissions, user_roles, permissions, roles, users RESTART IDENTITY CASCADE;

INSERT INTO roles (name) VALUES ('viewer'),('support'),('editor'),('manager'),('admin');

INSERT INTO permissions (name) VALUES
 ('profile.read'),('profile.update'),('content.read'),('content.write'),
 ('content.delete'),('users.read'),('users.write'),('users.delete'),
 ('reports.read'),('reports.export'),('settings.read'),('settings.write');

-- viewer: 2, support: 4, editor: 5, manager: 9, admin: all 12
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON
   (r.name='viewer'  AND p.id <= 2)
OR (r.name='support' AND p.id <= 4)
OR (r.name='editor'  AND p.id <= 5)
OR (r.name='manager' AND p.id <= 9)
OR (r.name='admin');

-- one bcrypt hash computed once, reused for all users (password: Password@123)
INSERT INTO users (username, email, password_hash, is_active, last_login, created_at)
SELECT 'user' || g,
       'user' || g || '@example.com',
       h.p,
       (random() > 0.1),
       now() - make_interval(days => (random()*90)::int),
       now() - make_interval(days => (random()*365)::int)
FROM generate_series(1, 200000) g
CROSS JOIN (SELECT crypt('Password@123', gen_salt('bf', 8)) AS p) h;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r WHERE r.name = 'viewer';

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON
   (r.name='support' AND u.id % 25   = 0)
OR (r.name='editor'  AND u.id % 10   = 0)
OR (r.name='manager' AND u.id % 50   = 0)
OR (r.name='admin'   AND u.id % 1000 = 0);

ANALYZE;
SELECT 'users' t, count(*) FROM users
UNION ALL SELECT 'user_roles', count(*) FROM user_roles
UNION ALL SELECT 'role_permissions', count(*) FROM role_permissions;
