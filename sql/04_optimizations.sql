-- 04_optimizations.sql
-- (a) expression index: makes lower(email) logins use an index + enforces unique emails
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email_lower ON users (lower(email));

-- (b) reverse lookup index on the junction table (role -> users)
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles (role_id);

-- (c) partial index: only active users, ordered by last_login
CREATE INDEX IF NOT EXISTS idx_users_active_last_login
    ON users (last_login) WHERE is_active;

-- (d) "caching" inside PostgreSQL: pre-joined permissions per user
DROP MATERIALIZED VIEW IF EXISTS mv_user_permissions;
CREATE MATERIALIZED VIEW mv_user_permissions AS
SELECT ur.user_id, p.name AS permission
FROM user_roles ur
JOIN role_permissions rp ON rp.role_id = ur.role_id
JOIN permissions p       ON p.id = rp.permission_id
GROUP BY ur.user_id, p.name;

CREATE UNIQUE INDEX uq_mv_user_permissions ON mv_user_permissions (user_id, permission);

-- refresh after role changes (CONCURRENTLY = no blocking of readers):
--   REFRESH MATERIALIZED VIEW CONCURRENTLY mv_user_permissions;

ANALYZE;
