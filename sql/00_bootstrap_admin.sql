-- ============================================================================
-- BOOTSTRAP: Create first admin user (run manually after applying migration)
-- ============================================================================
-- Steps:
--   1. Apply migration 00001_initial_schema.sql FIRST.
--   2. Create user in Supabase Auth dashboard:
--      Authentication → Users → "Add user" → "Create new user"
--      Email: admin@galleteracarabobo.com
--      Password: [strong password — save to credentials file]
--      Auto Confirm User: ✓ YES
--   3. The handle_new_user trigger will create the profile with role='vendedor'.
--   4. Run THIS script to upgrade that profile to 'admin'.
-- ============================================================================

-- Replace the email below with the email you used in step 2:
UPDATE public.profiles
SET
  role = 'admin',
  full_name = 'Juan Riera',
  is_active = TRUE
WHERE email = 'admin@galleteracarabobo.com';

-- Verify:
SELECT id, email, full_name, role, is_active, created_at
FROM public.profiles
WHERE email = 'admin@galleteracarabobo.com';

-- Expected output: 1 row with role = 'admin'.
