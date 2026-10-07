\set uid random(1,200000)
SELECT DISTINCT p.name FROM user_roles ur
JOIN role_permissions rp ON rp.role_id = ur.role_id
JOIN permissions p ON p.id = rp.permission_id WHERE ur.user_id = :uid;
