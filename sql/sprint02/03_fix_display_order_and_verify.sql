-- ============================================================================
-- SPRINT 02 — FIX 03: Corregir display_order duplicado + verificar inventario
-- ============================================================================

-- (1) Corregir display_order: el orden debe ser
--     Soda (1), Soda Sin Sal (2), Saltín (3), María (4), Chocolate Chips (5), Avena y Pasas (6)
UPDATE public.products SET display_order = 1 WHERE sku = 'GC-SODA-250';
UPDATE public.products SET display_order = 2 WHERE sku = 'GC-SODA-SS-250';
UPDATE public.products SET display_order = 3 WHERE sku = 'GC-SALTIN-280';
UPDATE public.products SET display_order = 4 WHERE sku = 'GC-MARIA-200';
UPDATE public.products SET display_order = 5 WHERE sku = 'GC-CHIPS-200';
UPDATE public.products SET display_order = 6 WHERE sku = 'GC-AVENA-220';

-- (2) Verificar productos finales con orden correcto
SELECT 
  sku, name, category, price, 
  stock_quantity, stock_min_alert,
  display_order, is_active
FROM public.products
ORDER BY display_order;

-- (3) Verificar que la tabla inventory_movements existe y tiene datos
SELECT 
  movement_type,
  COUNT(*) as movimientos,
  SUM(quantity) as unidades_totales
FROM public.inventory_movements
GROUP BY movement_type;

-- (4) Verificar que la función apply_inventory_movement existe
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public' 
  AND routine_name IN ('apply_inventory_movement', 'handle_order_status_change');

-- (5) Verificar que el trigger existe
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trg_order_status_inventory';
