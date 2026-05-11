-- ============================================================================
-- SPRINT 01 — SEED 02: 13 VENDEDORES FICTICIOS
-- ============================================================================
-- Distribuidos en 6 estados de Venezuela
-- Cada vendedor tiene: full_name, email, zone, vehicle_plate, monthly_target
-- Passwords NO se setean — son users solo para queries, no para login real
-- En Phase 1 demo, vos como admin podés crearles users con password si los necesitan
--
-- Estrategia: crear directamente en public.profiles
-- (trigger handle_new_user solo dispara cuando se crea en auth.users,
--  para datos seed sin login, vamos directo a profiles)
-- ============================================================================

-- Primero deshabilitar temporalmente el FK constraint a auth.users
-- (los UUIDs ficticios no existen en auth.users)
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

INSERT INTO public.profiles (
  id, email, full_name, role,
  phone, is_active, zone, vehicle_plate,
  monthly_target_kg, monthly_target_amount
) VALUES
  -- ============= CARABOBO (5 vendedores) =============
  ('11111111-1111-1111-1111-000000000001'::uuid,
   'carlos.mendoza@galleteracarabobo.com', 'Carlos Mendoza', 'vendedor',
   '+58-414-1234567', TRUE, 'Valencia Centro', 'AB-123-CD',
   2500, 5500),

  ('11111111-1111-1111-1111-000000000002'::uuid,
   'andrea.perez@galleteracarabobo.com', 'Andrea Pérez', 'vendedor',
   '+58-424-2345678', TRUE, 'Valencia Norte', 'AB-234-DE',
   2200, 4800),

  ('11111111-1111-1111-1111-000000000003'::uuid,
   'luis.rodriguez@galleteracarabobo.com', 'Luis Rodríguez', 'vendedor',
   '+58-412-3456789', TRUE, 'Naguanagua', 'AB-345-EF',
   2400, 5200),

  ('11111111-1111-1111-1111-000000000004'::uuid,
   'maria.hernandez@galleteracarabobo.com', 'María Hernández', 'vendedor',
   '+58-416-4567890', TRUE, 'San Diego', 'AB-456-FG',
   2100, 4500),

  ('11111111-1111-1111-1111-000000000005'::uuid,
   'jose.castillo@galleteracarabobo.com', 'José Castillo', 'vendedor',
   '+58-414-5678901', TRUE, 'Puerto Cabello', 'AB-567-GH',
   2600, 5800),

  -- ============= ARAGUA (2 vendedores) =============
  ('11111111-1111-1111-1111-000000000006'::uuid,
   'roberto.silva@galleteracarabobo.com', 'Roberto Silva', 'vendedor',
   '+58-424-6789012', TRUE, 'Maracay', 'AC-123-CD',
   2300, 5000),

  ('11111111-1111-1111-1111-000000000007'::uuid,
   'daniela.torres@galleteracarabobo.com', 'Daniela Torres', 'vendedor',
   '+58-412-7890123', TRUE, 'Turmero', 'AC-234-DE',
   2000, 4400),

  -- ============= CARACAS (3 vendedores) =============
  ('11111111-1111-1111-1111-000000000008'::uuid,
   'pedro.ramirez@galleteracarabobo.com', 'Pedro Ramírez', 'vendedor',
   '+58-416-8901234', TRUE, 'Caracas Centro', 'AD-123-CD',
   2800, 6200),

  ('11111111-1111-1111-1111-000000000009'::uuid,
   'carmen.lopez@galleteracarabobo.com', 'Carmen López', 'vendedor',
   '+58-414-9012345', TRUE, 'Caracas Este', 'AD-234-DE',
   2700, 6000),

  ('11111111-1111-1111-1111-000000000010'::uuid,
   'gabriel.acosta@galleteracarabobo.com', 'Gabriel Acosta', 'vendedor',
   '+58-424-0123456', TRUE, 'Caracas Oeste', 'AD-345-EF',
   2500, 5500),

  -- ============= ZULIA (1 vendedor) =============
  ('11111111-1111-1111-1111-000000000011'::uuid,
   'francisco.bracho@galleteracarabobo.com', 'Francisco Bracho', 'vendedor',
   '+58-412-1122334', TRUE, 'Maracaibo', 'AE-123-CD',
   2400, 5300),

  -- ============= LARA (1 vendedor) =============
  ('11111111-1111-1111-1111-000000000012'::uuid,
   'beatriz.mujica@galleteracarabobo.com', 'Beatriz Mujica', 'vendedor',
   '+58-416-2233445', TRUE, 'Barquisimeto', 'AF-123-CD',
   2300, 5100),

  -- ============= MIRANDA (1 vendedor) =============
  ('11111111-1111-1111-1111-000000000013'::uuid,
   'ricardo.salazar@galleteracarabobo.com', 'Ricardo Salazar', 'vendedor',
   '+58-414-3344556', TRUE, 'Los Teques', 'AG-123-CD',
   2200, 4900);

-- Volver a habilitar el FK constraint (sin verificar registros existentes)
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id)
  REFERENCES auth.users(id) ON DELETE CASCADE
  NOT VALID;

-- Verificación
SELECT zone, COUNT(*) AS vendedores
FROM public.profiles
WHERE role = 'vendedor'
GROUP BY zone
ORDER BY zone;

SELECT full_name, role, zone, vehicle_plate, monthly_target_amount
FROM public.profiles
WHERE role = 'vendedor'
ORDER BY zone, full_name;
