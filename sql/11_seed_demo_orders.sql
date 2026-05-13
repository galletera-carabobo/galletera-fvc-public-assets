-- ============================================================================
-- DEMO DATA — Pedidos pendientes + algunos aprobados para que el demo tenga vida
-- ============================================================================
-- Estrategia:
--   - 5 pedidos NUEVOS de Carlos Mendoza (3 pendientes + 2 aprobados) → su cupo sube
--   - 3 pedidos NUEVOS pendientes de otros vendedores → bandeja con variedad
--   - Todos con productos y cantidades realistas
-- ============================================================================

-- Limpieza opcional: si querés re-correr el script, descomenta
-- DELETE FROM public.order_items WHERE order_id IN (
--   SELECT id FROM public.orders WHERE internal_notes = 'DEMO_SEED'
-- );
-- DELETE FROM public.orders WHERE internal_notes = 'DEMO_SEED';

-- ============================================================================
-- PEDIDO 1 — Carlos Mendoza → cliente Carabobo (APROBADO)
-- Productos: Soda 250g (100 paq) + María (80 paq)
-- ============================================================================
DO $$
DECLARE
  v_carlos_id UUID := '161a5e10-e6c1-4c49-99f3-4aaa34f759ad';
  v_client_id UUID;
  v_order_id UUID;
  v_admin_id UUID := 'caeefa3e-2081-49e1-b453-b004722a4e6b'; -- Juan Riera admin
  v_soda_id UUID;
  v_maria_id UUID;
  v_saltin_id UUID;
  v_avena_id UUID;
  v_sodass_id UUID;
  v_chips_id UUID;
BEGIN
  -- Get product IDs
  SELECT id INTO v_soda_id FROM public.products WHERE sku = 'GC-SODA-250';
  SELECT id INTO v_sodass_id FROM public.products WHERE sku = 'GC-SODASS-250';
  SELECT id INTO v_saltin_id FROM public.products WHERE sku = 'GC-SALTIN-280';
  SELECT id INTO v_maria_id FROM public.products WHERE sku = 'GC-MARIA-200';
  SELECT id INTO v_chips_id FROM public.products WHERE sku = 'GC-CHIPS-200';
  SELECT id INTO v_avena_id FROM public.products WHERE sku = 'GC-AVENA-220';

  -- ========== PEDIDO 1: Carlos → Bodega aleatoria → APROBADO ==========
  SELECT id INTO v_client_id FROM public.clients
    WHERE assigned_vendedor_id = v_carlos_id ORDER BY business_name LIMIT 1;
  
  INSERT INTO public.orders (
    client_id, vendedor_id, status, order_date,
    subtotal, tax_amount, total_amount, total_weight_kg,
    payment_term, paid_amount, notes, internal_notes,
    is_synced, synced_at, created_by, approved_by, approved_at,
    created_at, updated_at
  ) VALUES (
    v_client_id, v_carlos_id, 'aprobado', CURRENT_DATE - INTERVAL '2 days',
    310.00, 49.60, 359.60, 41.000,
    'credito_15', 0,
    'Pedido semanal regular del cliente', 'DEMO_SEED',
    true, NOW() - INTERVAL '2 days', v_carlos_id, v_admin_id, NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_order_id;
  
  INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, subtotal, weight_kg) VALUES
    (v_order_id, v_soda_id,    100, 1.85, 185.00, 25.000),
    (v_order_id, v_maria_id,    80, 1.55, 124.00, 16.000);

  -- ========== PEDIDO 2: Carlos → otro cliente → APROBADO ==========
  SELECT id INTO v_client_id FROM public.clients
    WHERE assigned_vendedor_id = v_carlos_id ORDER BY business_name LIMIT 1 OFFSET 1;
  
  INSERT INTO public.orders (
    client_id, vendedor_id, status, order_date,
    subtotal, tax_amount, total_amount, total_weight_kg,
    payment_term, paid_amount, notes, internal_notes,
    is_synced, synced_at, created_by, approved_by, approved_at,
    created_at, updated_at
  ) VALUES (
    v_client_id, v_carlos_id, 'aprobado', CURRENT_DATE - INTERVAL '1 day',
    563.50, 90.16, 653.66, 73.500,
    'contado', 653.66,
    'Cliente paga al contado', 'DEMO_SEED',
    true, NOW() - INTERVAL '1 day', v_carlos_id, v_admin_id, NOW() - INTERVAL '12 hours',
    NOW() - INTERVAL '1 day', NOW() - INTERVAL '12 hours'
  ) RETURNING id INTO v_order_id;
  
  INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, subtotal, weight_kg) VALUES
    (v_order_id, v_soda_id,    150, 1.85, 277.50, 37.500),
    (v_order_id, v_saltin_id,   70, 2.10, 147.00, 19.600),
    (v_order_id, v_chips_id,    50, 2.78, 139.00, 10.000);

  -- ========== PEDIDO 3: Carlos → APROBADO (más grande) ==========
  SELECT id INTO v_client_id FROM public.clients
    WHERE assigned_vendedor_id = v_carlos_id ORDER BY business_name LIMIT 1 OFFSET 2;
  
  INSERT INTO public.orders (
    client_id, vendedor_id, status, order_date,
    subtotal, tax_amount, total_amount, total_weight_kg,
    payment_term, paid_amount, notes, internal_notes,
    is_synced, synced_at, created_by, approved_by, approved_at,
    created_at, updated_at
  ) VALUES (
    v_client_id, v_carlos_id, 'aprobado', CURRENT_DATE - INTERVAL '3 days',
    901.50, 144.24, 1045.74, 122.000,
    'credito_30', 0,
    'Pedido grande - distribución mayorista', 'DEMO_SEED',
    true, NOW() - INTERVAL '3 days', v_carlos_id, v_admin_id, NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days'
  ) RETURNING id INTO v_order_id;
  
  INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, subtotal, weight_kg) VALUES
    (v_order_id, v_soda_id,    200, 1.85, 370.00, 50.000),
    (v_order_id, v_sodass_id,  120, 1.95, 234.00, 30.000),
    (v_order_id, v_maria_id,   100, 1.55, 155.00, 20.000),
    (v_order_id, v_avena_id,    65, 2.20, 143.00, 14.300);

  -- ========== PEDIDO 4: Carlos → PENDIENTE (nuevo, hoy) ==========
  SELECT id INTO v_client_id FROM public.clients
    WHERE assigned_vendedor_id = v_carlos_id ORDER BY business_name LIMIT 1 OFFSET 3;
  
  INSERT INTO public.orders (
    client_id, vendedor_id, status, order_date,
    subtotal, tax_amount, total_amount, total_weight_kg,
    payment_term, paid_amount, notes, internal_notes,
    is_synced, synced_at, created_by,
    created_at, updated_at
  ) VALUES (
    v_client_id, v_carlos_id, 'pendiente', CURRENT_DATE,
    402.50, 64.40, 466.90, 50.400,
    'credito_15', 0,
    'Cliente solicita entrega antes del viernes', 'DEMO_SEED',
    true, NOW() - INTERVAL '2 hours', v_carlos_id,
    NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours'
  ) RETURNING id INTO v_order_id;
  
  INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, subtotal, weight_kg) VALUES
    (v_order_id, v_soda_id,    120, 1.85, 222.00, 30.000),
    (v_order_id, v_saltin_id,   60, 2.10, 126.00, 16.800),
    (v_order_id, v_chips_id,    20, 2.78,  55.60,  4.000);

  -- ========== PEDIDO 5: Carlos → PENDIENTE ==========
  SELECT id INTO v_client_id FROM public.clients
    WHERE assigned_vendedor_id = v_carlos_id ORDER BY business_name LIMIT 1 OFFSET 4;
  
  INSERT INTO public.orders (
    client_id, vendedor_id, status, order_date,
    subtotal, tax_amount, total_amount, total_weight_kg,
    payment_term, paid_amount, notes, internal_notes,
    is_synced, synced_at, created_by,
    created_at, updated_at
  ) VALUES (
    v_client_id, v_carlos_id, 'pendiente', CURRENT_DATE,
    254.80, 40.77, 295.57, 33.500,
    'contado', 0,
    NULL, 'DEMO_SEED',
    true, NOW() - INTERVAL '1 hour', v_carlos_id,
    NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour'
  ) RETURNING id INTO v_order_id;
  
  INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, subtotal, weight_kg) VALUES
    (v_order_id, v_sodass_id,   80, 1.95, 156.00, 20.000),
    (v_order_id, v_maria_id,    50, 1.55,  77.50, 10.000),
    (v_order_id, v_avena_id,    10, 2.20,  22.00,  2.200);

  -- ========== PEDIDO 6: Carlos → PENDIENTE (recién creado) ==========
  SELECT id INTO v_client_id FROM public.clients
    WHERE assigned_vendedor_id = v_carlos_id ORDER BY business_name LIMIT 1 OFFSET 5;
  
  INSERT INTO public.orders (
    client_id, vendedor_id, status, order_date,
    subtotal, tax_amount, total_amount, total_weight_kg,
    payment_term, paid_amount, notes, internal_notes,
    is_synced, synced_at, created_by,
    created_at, updated_at
  ) VALUES (
    v_client_id, v_carlos_id, 'pendiente', CURRENT_DATE,
    178.00, 28.48, 206.48, 22.500,
    'credito_7', 0,
    'Reorden quincenal', 'DEMO_SEED',
    true, NOW() - INTERVAL '30 minutes', v_carlos_id,
    NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes'
  ) RETURNING id INTO v_order_id;
  
  INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, subtotal, weight_kg) VALUES
    (v_order_id, v_soda_id,     60, 1.85, 111.00, 15.000),
    (v_order_id, v_maria_id,    25, 1.55,  38.75,  5.000),
    (v_order_id, v_chips_id,    10, 2.78,  27.80,  2.000);

  RAISE NOTICE 'Pedidos de Carlos creados: 3 aprobados + 3 pendientes';
END $$;

-- ============================================================================
-- PEDIDOS DE OTROS VENDEDORES (Pendientes — variedad para la bandeja)
-- ============================================================================
DO $$
DECLARE
  v_vendedor_id UUID;
  v_client_id UUID;
  v_order_id UUID;
  v_soda_id UUID;
  v_maria_id UUID;
  v_saltin_id UUID;
  v_avena_id UUID;
  v_sodass_id UUID;
  v_chips_id UUID;
BEGIN
  SELECT id INTO v_soda_id FROM public.products WHERE sku = 'GC-SODA-250';
  SELECT id INTO v_sodass_id FROM public.products WHERE sku = 'GC-SODASS-250';
  SELECT id INTO v_saltin_id FROM public.products WHERE sku = 'GC-SALTIN-280';
  SELECT id INTO v_maria_id FROM public.products WHERE sku = 'GC-MARIA-200';
  SELECT id INTO v_chips_id FROM public.products WHERE sku = 'GC-CHIPS-200';
  SELECT id INTO v_avena_id FROM public.products WHERE sku = 'GC-AVENA-220';

  -- ========== PEDIDO A: Vendedor ficticio random → pendiente grande ==========
  -- Usamos un vendedor ficticio (Francisco Bracho - Maracaibo)
  SELECT p.id INTO v_vendedor_id FROM public.profiles p
    WHERE p.role = 'vendedor' AND p.full_name LIKE 'Francisco%' LIMIT 1;
  
  IF v_vendedor_id IS NOT NULL THEN
    SELECT c.id INTO v_client_id FROM public.clients c
      WHERE c.assigned_vendedor_id = v_vendedor_id LIMIT 1;
    
    IF v_client_id IS NOT NULL THEN
      INSERT INTO public.orders (
        client_id, vendedor_id, status, order_date,
        subtotal, tax_amount, total_amount, total_weight_kg,
        payment_term, paid_amount, notes, internal_notes,
        is_synced, synced_at, created_by,
        created_at, updated_at
      ) VALUES (
        v_client_id, v_vendedor_id, 'pendiente', CURRENT_DATE,
        725.00, 116.00, 841.00, 95.500,
        'credito_30', 0,
        'Reposición mensual mayorista', 'DEMO_SEED',
        true, NOW() - INTERVAL '4 hours', v_vendedor_id,
        NOW() - INTERVAL '4 hours', NOW() - INTERVAL '4 hours'
      ) RETURNING id INTO v_order_id;
      
      INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, subtotal, weight_kg) VALUES
        (v_order_id, v_soda_id,    180, 1.85, 333.00, 45.000),
        (v_order_id, v_sodass_id,  100, 1.95, 195.00, 25.000),
        (v_order_id, v_saltin_id,   60, 2.10, 126.00, 16.800),
        (v_order_id, v_avena_id,    30, 2.20,  66.00,  6.600);
    END IF;
  END IF;

  -- ========== PEDIDO B: Otro vendedor → pendiente mediano ==========
  SELECT p.id INTO v_vendedor_id FROM public.profiles p
    WHERE p.role = 'vendedor' AND p.full_name LIKE 'Andrea%' LIMIT 1;
  
  IF v_vendedor_id IS NOT NULL THEN
    SELECT c.id INTO v_client_id FROM public.clients c
      WHERE c.assigned_vendedor_id = v_vendedor_id LIMIT 1;
    
    IF v_client_id IS NOT NULL THEN
      INSERT INTO public.orders (
        client_id, vendedor_id, status, order_date,
        subtotal, tax_amount, total_amount, total_weight_kg,
        payment_term, paid_amount, notes, internal_notes,
        is_synced, synced_at, created_by,
        created_at, updated_at
      ) VALUES (
        v_client_id, v_vendedor_id, 'pendiente', CURRENT_DATE,
        308.00, 49.28, 357.28, 39.000,
        'contado', 0,
        NULL, 'DEMO_SEED',
        true, NOW() - INTERVAL '3 hours', v_vendedor_id,
        NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours'
      ) RETURNING id INTO v_order_id;
      
      INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, subtotal, weight_kg) VALUES
        (v_order_id, v_soda_id,     90, 1.85, 166.50, 22.500),
        (v_order_id, v_maria_id,    70, 1.55, 108.50, 14.000),
        (v_order_id, v_chips_id,    12, 2.78,  33.36,  2.400);
    END IF;
  END IF;

  -- ========== PEDIDO C: tercer vendedor ==========
  SELECT p.id INTO v_vendedor_id FROM public.profiles p
    WHERE p.role = 'vendedor' AND p.id != '161a5e10-e6c1-4c49-99f3-4aaa34f759ad'
    ORDER BY random() LIMIT 1;
  
  IF v_vendedor_id IS NOT NULL THEN
    SELECT c.id INTO v_client_id FROM public.clients c
      WHERE c.assigned_vendedor_id = v_vendedor_id LIMIT 1;
    
    IF v_client_id IS NOT NULL THEN
      INSERT INTO public.orders (
        client_id, vendedor_id, status, order_date,
        subtotal, tax_amount, total_amount, total_weight_kg,
        payment_term, paid_amount, notes, internal_notes,
        is_synced, synced_at, created_by,
        created_at, updated_at
      ) VALUES (
        v_client_id, v_vendedor_id, 'pendiente', CURRENT_DATE,
        445.00, 71.20, 516.20, 56.500,
        'credito_15', 0,
        'Cliente solicita Chocolate Chips piloto', 'DEMO_SEED',
        true, NOW() - INTERVAL '90 minutes', v_vendedor_id,
        NOW() - INTERVAL '90 minutes', NOW() - INTERVAL '90 minutes'
      ) RETURNING id INTO v_order_id;
      
      INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, subtotal, weight_kg) VALUES
        (v_order_id, v_soda_id,    100, 1.85, 185.00, 25.000),
        (v_order_id, v_saltin_id,   50, 2.10, 105.00, 14.000),
        (v_order_id, v_chips_id,    35, 2.78,  97.30,  7.000),
        (v_order_id, v_avena_id,    25, 2.20,  55.00,  5.500);
    END IF;
  END IF;

  RAISE NOTICE 'Pedidos de otros vendedores: 3 pendientes creados';
END $$;

-- ============================================================================
-- VERIFICACION
-- ============================================================================
SELECT 
  '✅ Total pedidos creados' as info,
  COUNT(*) as cantidad
FROM public.orders
WHERE internal_notes = 'DEMO_SEED';

SELECT 
  '📊 Por status' as info,
  status,
  COUNT(*) as cantidad,
  ROUND(SUM(total_amount)::numeric, 2) as monto_usd,
  ROUND(SUM(total_weight_kg)::numeric, 1) as kg
FROM public.orders
WHERE internal_notes = 'DEMO_SEED'
GROUP BY status
ORDER BY status;

SELECT 
  '🎯 Cupo Carlos actualizado' as info,
  v.target_kg as meta_kg,
  v.sold_kg as vendido_kg,
  ROUND(v.completion_percent::numeric, 1) as completion_pct
FROM public.vendor_quota_progress_v v
WHERE v.vendedor_id = '161a5e10-e6c1-4c49-99f3-4aaa34f759ad'
  AND v.year = 2026 AND v.month = 5;

SELECT 
  '📋 Bandeja pendientes' as info,
  o.order_number,
  c.business_name as cliente,
  p.full_name as vendedor,
  o.total_amount as monto_usd,
  o.total_weight_kg as kg
FROM public.orders o
JOIN public.clients c ON c.id = o.client_id
JOIN public.profiles p ON p.id = o.vendedor_id
WHERE o.status = 'pendiente'
ORDER BY o.created_at DESC
LIMIT 20;
