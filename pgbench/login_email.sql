\set uid random(1,200000)
SELECT id, password_hash FROM users WHERE lower(email) = 'user' || :uid || '@example.com';
