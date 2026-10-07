-- 06_security.sql : secure password check, lockout, least-privilege app role
CREATE OR REPLACE FUNCTION authenticate_user(p_email TEXT, p_password TEXT)
RETURNS BIGINT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
DECLARE
    v_id BIGINT; v_hash TEXT; v_active BOOLEAN; v_fail INT;
BEGIN
    SELECT id, password_hash, is_active, failed_attempts
      INTO v_id, v_hash, v_active, v_fail
      FROM users WHERE lower(email) = lower(p_email);

    IF v_id IS NULL OR NOT v_active OR v_fail >= 5 THEN
        RETURN NULL;                         -- unknown, disabled or locked
    END IF;

    IF v_hash = crypt(p_password, v_hash) THEN
        UPDATE users SET last_login = now(), failed_attempts = 0 WHERE id = v_id;
        RETURN v_id;
    END IF;

    UPDATE users SET failed_attempts = failed_attempts + 1 WHERE id = v_id;
    RETURN NULL;
END $$;

REVOKE ALL ON FUNCTION authenticate_user(TEXT, TEXT) FROM PUBLIC;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'login_app') THEN
    CREATE ROLE login_app LOGIN PASSWORD 'ChangeThisPassword!123';
  END IF;
END $$;

GRANT EXECUTE ON FUNCTION authenticate_user(TEXT, TEXT) TO login_app;
GRANT SELECT ON mv_user_permissions TO login_app;   -- app can read permissions, nothing else

\echo === security tests (expect: id, NULL, NULL) ===
SELECT authenticate_user('user10@example.com', 'Password@123') AS correct_password;
SELECT authenticate_user('user10@example.com', 'wrong')        AS wrong_password;
SELECT authenticate_user('nobody@example.com', 'x')            AS unknown_user;
UPDATE users SET failed_attempts = 0 WHERE username = 'user10';
