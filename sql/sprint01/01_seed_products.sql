-- ============================================================================
-- SPRINT 01 — SEED 01: PRODUCTOS GALLETERA CARABOBO
-- ============================================================================
-- 5 SKUs reales del portfolio Galletera Carabobo
-- Precios iniciales en USD (cambiar a Bs con UPDATE al final si se requiere)
-- Pesos y unidades por caja basados en presentaciones estándar VE
-- SAP fields preparados (sap_matnr) para integración Phase 2
-- ============================================================================

INSERT INTO public.products (
  sku, name, description, category,
  price, cost,
  unit, units_per_case, weight_kg,
  sap_matnr, sap_meins, sap_brgew,
  display_order, is_active
) VALUES
  -- Línea SODA
  ('GC-SODA-250',
   'Galletas Soda 250g',
   'Galletas de soda tradicional, paquete familiar de 250g, sabor neutro ideal para acompañar comidas',
   'soda',
   2.30, 1.25,
   'paquete', 24, 0.250,
   'GC0010001', 'EA', 0.250,
   1, TRUE),

  ('GC-SODA-SS-250',
   'Galletas Soda Sin Sal 250g',
   'Galletas de soda sin sal añadida, ideal para dietas bajas en sodio, paquete 250g',
   'soda',
   2.45, 1.35,
   'paquete', 24, 0.250,
   'GC0010002', 'EA', 0.250,
   2, TRUE),

  -- Línea MARIA
  ('GC-MARIA-200',
   'Galletas María 200g',
   'Galletas María tradicionales, sabor clásico, paquete de 200g',
   'maria',
   1.90, 1.05,
   'paquete', 30, 0.200,
   'GC0020001', 'EA', 0.200,
   3, TRUE),

  ('GC-MARIA-VAIN-200',
   'Galletas María Vainilla 200g',
   'Galletas María con sabor a vainilla, paquete 200g, premium',
   'maria',
   2.05, 1.15,
   'paquete', 30, 0.200,
   'GC0020002', 'EA', 0.200,
   4, TRUE),

  -- Línea ESPECIALIDADES
  ('GC-CAFE-180',
   'Galletas Café 180g',
   'Galletas con sabor a café, presentación 180g, edición especial',
   'cafe',
   1.75, 0.95,
   'paquete', 36, 0.180,
   'GC0030001', 'EA', 0.180,
   5, TRUE);

-- Verificación
SELECT sku, name, category, price, units_per_case, weight_kg
FROM public.products
ORDER BY display_order;
