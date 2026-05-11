-- ============================================================================
-- FIX: Grant table privileges to Supabase roles
-- ============================================================================
-- After applying custom schemas, Supabase does NOT automatically grant
-- SELECT/INSERT/UPDATE/DELETE to the `anon` and `service_role` roles.
-- This script grants them explicitly so the SDK can query the tables.
-- RLS still applies and protects per-row access.
-- ============================================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Grant all on existing tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Grant all on future tables (so we don't have to re-run this after every migration)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;

-- Verify grants on profiles table
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY grantee, privilege_type;
