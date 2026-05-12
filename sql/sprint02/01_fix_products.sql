-- ============================================================================
-- SPRINT 02 — FIX 01: Corregir catálogo de productos a la realidad de Galletera
-- ============================================================================
-- Productos reales según Jose Partidas (Gerente General Galletera Carabobo):
--   1. Galleta Soda
--   2. Galleta Soda Sin Sal
--   3. Galleta Saltín
--   4. Galleta María
--   5. Galleta Chocolate Chips (en lanzamiento piloto)
--   6. Galleta Avena y Pasas
--
-- Estrategia:
--   - UPDATE in-place de los 2 productos incorrectos (mantiene UUIDs → no rompe order_items)
--   - INSERT 1 producto nuevo (Chocolate Chips)
-- ============================================================================

-- (1) Corregir "Galletas María Vainilla" → Galletas Saltín
UPDATE public.products
SET 
  sku = 'GC-SALTIN-280',
  name = 'Galletas Saltín 280g',
  description = 'Galletas saladas tipo saltín, presentación 280g, ideal para acompañar comidas',
  category = 'saltin',
  price = 2.10,
  cost = 1.15,
  unit = 'paquete',
  units_per_case = 24,
  weight_kg = 0.280,
  sap_matnr = 'GC0040001',
  sap_meins = 'EA',
  sap_brgew = 0.280,
  display_order = 3
WHERE sku = 'GC-MARIA-VAIN-200';

-- (2) Corregir "Galletas Café" → Galletas Avena y Pasas
UPDATE public.products
SET 
  sku = 'GC-AVENA-220',
  name = 'Galletas Avena y Pasas 220g',
  description = 'Galletas de avena con pasas, presentación 220g, opción saludable',
  category = 'avena',
  price = 2.55,
  cost = 1.40,
  unit = 'paquete',
  units_per_case = 24,
  weight_kg = 0.220,
  sap_matnr = 'GC0050001',
  sap_meins = 'EA',
  sap_brgew = 0.220,
  display_order = 5
WHERE sku = 'GC-CAFE-180';

-- (3) Agregar Galletas Chocolate Chips (producto nuevo en lanzamiento)
INSERT INTO public.products (
  sku, name, description, category,
  price, cost,
  unit, units_per_case, weight_kg,
  sap_matnr, sap_meins, sap_brgew,
  display_order, is_active
) VALUES (
  'GC-CHIPS-200',
  'Galletas Chocolate Chips 200g',
  'Galletas con chispas de chocolate, presentación 200g, producto en lanzamiento piloto',
  'chocolate_chips',
  2.95, 1.55,
  'paquete', 24, 0.200,
  'GC0060001', 'EA', 0.200,
  6, TRUE
);

-- Verificación: deberían aparecer 6 productos correctos
SELECT sku, name, category, price, units_per_case, weight_kg, display_order, is_active
FROM public.products
ORDER BY display_order;
