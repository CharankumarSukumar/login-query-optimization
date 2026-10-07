\set uid random(1,200000)
SELECT permission FROM mv_user_permissions WHERE user_id = :uid;
