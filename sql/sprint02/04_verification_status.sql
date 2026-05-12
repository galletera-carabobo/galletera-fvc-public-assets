-- ============================================================================
-- VERIFICACIÓN COMPLETA — confirmar estado pre-UI
-- ============================================================================

-- (1) Los 6 productos con stock
SELECT 
  display_order as "#",
  sku, 
  name, 
  stock_quantity as stock,
  stock_min_alert as min,
  CASE 
    WHEN stock_quantity <= stock_min_alert THEN '🔴 BAJO'
    WHEN stock_quantity <= stock_min_alert * 2 THEN '🟡 ATENCIÓN'
    ELSE '🟢 OK'
  END AS status_stock
FROM public.products
WHERE is_active = TRUE
ORDER BY display_order;

-- (2) Resumen de pedidos por status (para saber qué hay aprobado vs pendiente)
SELECT 
  status,
  COUNT(*) as cantidad,
  ROUND(SUM(total_amount), 2) as monto_usd
FROM public.orders
GROUP BY status
ORDER BY cantidad DESC;

-- (3) Pedidos pendientes que necesitarán aprobación (para test del trigger)
SELECT 
  COUNT(*) as pedidos_pendientes_para_aprobar
FROM public.orders
WHERE status = 'pendiente';
