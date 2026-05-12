-- ============================================================================
-- VENDEDOR DEMO — Setup completo para Sprint 03 testing
-- UUID: 161a5e10-e6c1-4c49-99f3-4aaa34f759ad
-- Email: vendedor.demo@galletera-carabobo.com
-- ============================================================================

-- 1) Crear profile del vendedor
INSERT INTO public.profiles (
  id, email, full_name, role, phone, zone, is_active, created_at, updated_at
) VALUES (
  '161a5e10-e6c1-4c49-99f3-4aaa34f759ad',
  'vendedor.demo@galletera-carabobo.com',
  'Carlos Mendoza',
  'vendedor',
  '+58 414 555 1234',
  'Valencia Centro',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role,
  zone = EXCLUDED.zone,
  is_active = true,
  updated_at = NOW();

-- 2) Asignarle 10 clientes de Carabobo (los primeros activos)
WITH clients_to_assign AS (
  SELECT id
  FROM public.clients
  WHERE state = 'Carabobo' AND status = 'activo'
  ORDER BY business_name
  LIMIT 10
)
UPDATE public.clients
SET assigned_vendedor_id = '161a5e10-e6c1-4c49-99f3-4aaa34f759ad',
    updated_at = NOW()
WHERE id IN (SELECT id FROM clients_to_assign);

-- 3) Crear cupo del mes actual (Mayo 2026)
INSERT INTO public.vendor_monthly_quotas (
  vendedor_id, year, month,
  target_kg, target_amount,
  target_kg_soda, target_kg_maria,
  notes,
  created_at, updated_at
) VALUES (
  '161a5e10-e6c1-4c49-99f3-4aaa34f759ad',
  2026, 5,
  8000, 16000,
  3000, 2500,
  'Cupo asignado para demo Sprint 03',
  NOW(), NOW()
)
ON CONFLICT (vendedor_id, year, month) DO UPDATE SET
  target_kg = EXCLUDED.target_kg,
  target_amount = EXCLUDED.target_amount,
  target_kg_soda = EXCLUDED.target_kg_soda,
  target_kg_maria = EXCLUDED.target_kg_maria,
  notes = EXCLUDED.notes,
  updated_at = NOW();

-- ============================================================================
-- VERIFICACION
-- ============================================================================

SELECT 
  '✅ Profile creado' as accion,
  full_name,
  zone,
  role,
  email
FROM public.profiles
WHERE id = '161a5e10-e6c1-4c49-99f3-4aaa34f759ad';

SELECT 
  '✅ Clientes asignados' as accion,
  COUNT(*) as cantidad
FROM public.clients
WHERE assigned_vendedor_id = '161a5e10-e6c1-4c49-99f3-4aaa34f759ad';

SELECT 
  '✅ Cupo del mes' as accion,
  year, month, 
  target_kg as meta_kg,
  target_amount as meta_usd,
  target_kg_soda as meta_soda,
  target_kg_maria as meta_maria
FROM public.vendor_monthly_quotas
WHERE vendedor_id = '161a5e10-e6c1-4c49-99f3-4aaa34f759ad'
  AND year = 2026 AND month = 5;

SELECT 
  '📋 Clientes asignados:' as info,
  business_name,
  trade_name,
  city,
  client_type
FROM public.clients
WHERE assigned_vendedor_id = '161a5e10-e6c1-4c49-99f3-4aaa34f759ad'
ORDER BY business_name;
