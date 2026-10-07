-- Login system schema (PostgreSQL)

CREATE TABLE users (
    user_id        SERIAL PRIMARY KEY,
    username       VARCHAR(50) UNIQUE,
    email          VARCHAR(100) UNIQUE,
    password_hash  VARCHAR(255),
    is_active      BOOLEAN,
    created_at     TIMESTAMP,
    last_login_at  TIMESTAMP
);

CREATE TABLE roles (
    role_id    SERIAL PRIMARY KEY,
    role_name  VARCHAR(50) UNIQUE
);

CREATE TABLE permissions (
    permission_id    SERIAL PRIMARY KEY,
    permission_name  VARCHAR(50) UNIQUE
);

CREATE TABLE user_roles (
    user_id  INT REFERENCES users(user_id) ON DELETE CASCADE,
    role_id  INT REFERENCES roles(role_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE role_permissions (
    role_id        INT REFERENCES roles(role_id) ON DELETE CASCADE,
    permission_id  INT REFERENCES permissions(permission_id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Extra indexes for JOIN and search columns
CREATE INDEX idx_user_roles_role_id ON user_roles (role_id);
CREATE INDEX idx_role_permissions_permission_id ON role_permissions (permission_id);
CREATE INDEX idx_users_last_login_at ON users (last_login_at);
