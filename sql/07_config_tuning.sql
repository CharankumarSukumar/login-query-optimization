-- 07_config_tuning.sql : server configuration (Week 3) and network hardening (Week 4)
-- Run as the postgres superuser. shared_buffers and listen_addresses need a service RESTART.
-- Sizes assume a laptop with 8 GB RAM; scale them to your machine.

ALTER SYSTEM SET shared_buffers        = '256MB';  -- default 128MB: more table/index pages cached in memory
ALTER SYSTEM SET work_mem              = '16MB';   -- default 4MB: bigger sorts/hashes before spilling to disk
ALTER SYSTEM SET maintenance_work_mem  = '128MB';  -- faster CREATE INDEX / REFRESH MATERIALIZED VIEW
ALTER SYSTEM SET effective_cache_size  = '1GB';    -- tells the planner how much the OS also caches
ALTER SYSTEM SET listen_addresses      = 'localhost'; -- default '*' (every network card): only this computer may connect

SELECT pg_reload_conf();

-- after the restart, check with:
-- SELECT name, setting, unit, pending_restart FROM pg_settings
--  WHERE name IN ('shared_buffers','work_mem','maintenance_work_mem','effective_cache_size','listen_addresses');

-- to undo everything:
-- ALTER SYSTEM RESET ALL;  then restart the service
