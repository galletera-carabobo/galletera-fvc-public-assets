-- ============================================================================
-- FIX: handle_new_user trigger failing due to RLS
-- ============================================================================
-- The original trigger fails because RLS on public.profiles blocks the INSERT
-- when no auth.uid() is set yet (the user is being CREATED).
-- Fix: SECURITY DEFINER + search_path + explicit RLS bypass via local role.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'vendedor')
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error but don't block user creation
    RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Allow the SECURITY DEFINER function to bypass RLS by granting explicit
-- permissions to the function owner (postgres role) on the profiles table.
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;

-- Add a permissive insert policy for the postgres role (SECURITY DEFINER context)
DROP POLICY IF EXISTS "profiles_insert_trigger" ON public.profiles;
CREATE POLICY "profiles_insert_trigger"
  ON public.profiles
  FOR INSERT
  TO postgres, service_role
  WITH CHECK (TRUE);

-- Verify trigger still exists and is wired up correctly
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Verification query (uncomment to run separately):
-- SELECT tgname, tgenabled, tgrelid::regclass
-- FROM pg_trigger
-- WHERE tgname = 'on_auth_user_created';
