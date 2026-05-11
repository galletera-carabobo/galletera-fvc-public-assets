-- ============================================================================
-- SPRINT 01b — PROMOTE ADMINS
-- ============================================================================
-- PASO 1 (manual): Crear los 3 usuarios en Supabase Auth Dashboard
--   Authentication → Users → Add user → Create new user
--   Para cada uno: email + password 'Galletera2026!' + Auto-confirm email ✓
--
-- PASO 2: Correr este SQL para promoverlos a admin
-- ============================================================================

-- Promover a Iraida Parra
UPDATE public.profiles
SET role = 'admin', 
    full_name = 'Iraida Parra',
    is_active = TRUE
WHERE email = 'iraida.parra@galletera-carabobo.com';

-- Promover a Gustavo González
UPDATE public.profiles
SET role = 'admin',
    full_name = 'Gustavo González',
    is_active = TRUE
WHERE email = 'gustavogonzalez0112@gmail.com';

-- Promover a J. Partidas
UPDATE public.profiles
SET role = 'admin',
    full_name = 'J. Partidas',
    is_active = TRUE
WHERE email = 'jpartidas@galletera-carabobo.com';

-- Verificación: lista todos los admins
SELECT id, email, full_name, role, is_active, created_at
FROM public.profiles
WHERE role = 'admin'
ORDER BY full_name;
