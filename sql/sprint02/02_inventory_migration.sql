-- ============================================================================
-- SPRINT 02 — INVENTORY SYSTEM (centralized)
-- ============================================================================
-- Modelo de negocio (definido con Jose):
--   - Inventario CENTRALIZADO (un solo "depósito virtual" — toda Galletera produce desde una fábrica)
--   - Stock se descuenta al APROBAR pedido (consistente con cupos)
--   - Stock se DEVUELVE si se cancela/rechaza un pedido aprobado
--   - Admin puede ajustar stock manualmente (entrada producción, merma, conteo físico, devolución)
--   - Toda operación queda auditada en inventory_movements
--   - Alertas: si stock < stock_min_alert, muestra warning
-- ============================================================================

-- (1) Agregar campos de stock a products
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  ADD COLUMN IF NOT EXISTS stock_min_alert INTEGER NOT NULL DEFAULT 0 CHECK (stock_min_alert >= 0);

-- Índice para queries de "productos bajo stock"
CREATE INDEX IF NOT EXISTS idx_products_low_stock 
  ON public.products(stock_quantity, stock_min_alert) 
  WHERE is_active = TRUE;

-- (2) Tabla de movimientos de inventario (auditoría completa)
CREATE TABLE IF NOT EXISTS public.inventory_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  
  -- Tipo de movimiento
  movement_type TEXT NOT NULL CHECK (movement_type IN (
    'entrada_produccion',    -- llegada desde fábrica
    'salida_venta',           -- pedido aprobado
    'devolucion_venta',       -- pedido cancelado/rechazado que estaba aprobado
    'merma',                  -- producto dañado/vencido
    'ajuste_conteo',          -- inventario físico mensual
    'ajuste_manual'           -- ajuste con razón libre
  )),
  
  -- Cantidad: positivo = entrada, negativo = salida
  quantity INTEGER NOT NULL CHECK (quantity != 0),
  
  -- Stock antes y después (para auditoría)
  stock_before INTEGER NOT NULL,
  stock_after INTEGER NOT NULL,
  
  -- Referencia opcional al pedido (si fue por venta)
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  
  -- Notas y auditoría
  notes TEXT,
  performed_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_movements_product ON public.inventory_movements(product_id);
CREATE INDEX idx_movements_type ON public.inventory_movements(movement_type);
CREATE INDEX idx_movements_order ON public.inventory_movements(order_id);
CREATE INDEX idx_movements_date ON public.inventory_movements(created_at DESC);

-- RLS
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;

-- Vendedores pueden VER movimientos de sus pedidos (transparencia)
CREATE POLICY movements_select ON public.inventory_movements
  FOR SELECT TO authenticated
  USING (
    public.is_admin_or_supervisor() 
    OR EXISTS (
      SELECT 1 FROM public.orders o 
      WHERE o.id = inventory_movements.order_id 
      AND o.vendedor_id = auth.uid()
    )
  );

-- Solo admin/supervisor pueden crear movimientos manuales
CREATE POLICY movements_insert ON public.inventory_movements
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin_or_supervisor());

GRANT SELECT, INSERT ON public.inventory_movements TO anon, authenticated, service_role;

-- (3) Function: aplicar movimiento de stock (atómica)
-- Verifica stock no negativo, actualiza product, registra movimiento
CREATE OR REPLACE FUNCTION public.apply_inventory_movement(
  p_product_id UUID,
  p_movement_type TEXT,
  p_quantity INTEGER,  -- positivo = sumar, negativo = restar
  p_order_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_performed_by UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_stock_before INTEGER;
  v_stock_after INTEGER;
  v_movement_id UUID;
BEGIN
  -- Lock row to prevent race conditions
  SELECT stock_quantity INTO v_stock_before
  FROM public.products
  WHERE id = p_product_id
  FOR UPDATE;
  
  IF v_stock_before IS NULL THEN
    RAISE EXCEPTION 'Producto no encontrado: %', p_product_id;
  END IF;
  
  v_stock_after := v_stock_before + p_quantity;
  
  IF v_stock_after < 0 THEN
    RAISE EXCEPTION 'Stock insuficiente. Disponible: %, intentando salida: %', 
      v_stock_before, ABS(p_quantity);
  END IF;
  
  -- Actualizar stock del producto
  UPDATE public.products
  SET stock_quantity = v_stock_after, updated_at = NOW()
  WHERE id = p_product_id;
  
  -- Registrar movimiento
  INSERT INTO public.inventory_movements (
    product_id, movement_type, quantity,
    stock_before, stock_after,
    order_id, notes, performed_by
  ) VALUES (
    p_product_id, p_movement_type, p_quantity,
    v_stock_before, v_stock_after,
    p_order_id, p_notes, p_performed_by
  ) RETURNING id INTO v_movement_id;
  
  RETURN v_movement_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.apply_inventory_movement TO authenticated, service_role;

-- (4) Trigger: cuando un pedido cambia de status, ajustar stock automáticamente
CREATE OR REPLACE FUNCTION public.handle_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_item RECORD;
  v_old_was_approved BOOLEAN;
  v_new_is_approved BOOLEAN;
BEGIN
  -- Solo actuamos en UPDATEs de status
  IF TG_OP != 'UPDATE' OR NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;
  
  v_old_was_approved := OLD.status IN ('aprobado', 'despachado', 'entregado', 'pagado');
  v_new_is_approved := NEW.status IN ('aprobado', 'despachado', 'entregado', 'pagado');
  
  -- Caso 1: estaba pendiente y se aprueba → descontar stock
  IF NOT v_old_was_approved AND v_new_is_approved THEN
    FOR v_item IN
      SELECT product_id, quantity FROM public.order_items WHERE order_id = NEW.id
    LOOP
      PERFORM public.apply_inventory_movement(
        v_item.product_id,
        'salida_venta',
        -v_item.quantity,
        NEW.id,
        'Salida por aprobación pedido ' || NEW.order_number,
        NEW.approved_by
      );
    END LOOP;
  END IF;
  
  -- Caso 2: estaba aprobado y se cancela/rechaza → devolver stock
  IF v_old_was_approved AND NOT v_new_is_approved THEN
    FOR v_item IN
      SELECT product_id, quantity FROM public.order_items WHERE order_id = NEW.id
    LOOP
      PERFORM public.apply_inventory_movement(
        v_item.product_id,
        'devolucion_venta',
        v_item.quantity,
        NEW.id,
        'Devolución por ' || NEW.status || ' de pedido ' || NEW.order_number,
        NEW.approved_by
      );
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_order_status_inventory ON public.orders;
CREATE TRIGGER trg_order_status_inventory
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_order_status_change();

-- ============================================================================
-- SEED: Asignar stock inicial a productos existentes
-- ============================================================================
-- Estimaciones basadas en categoría y rotación esperada
-- Jose puede editar estos valores después en /admin/inventario
-- ============================================================================

UPDATE public.products SET stock_quantity = 12000, stock_min_alert = 2000 WHERE sku = 'GC-SODA-250';
UPDATE public.products SET stock_quantity = 6000,  stock_min_alert = 1000 WHERE sku = 'GC-SODA-SS-250';
UPDATE public.products SET stock_quantity = 8000,  stock_min_alert = 1500 WHERE sku = 'GC-SALTIN-280';
UPDATE public.products SET stock_quantity = 10000, stock_min_alert = 2000 WHERE sku = 'GC-MARIA-200';
UPDATE public.products SET stock_quantity = 500,   stock_min_alert = 100  WHERE sku = 'GC-CHIPS-200';  -- lanzamiento piloto
UPDATE public.products SET stock_quantity = 4500,  stock_min_alert = 800  WHERE sku = 'GC-AVENA-220';

-- Registrar movimientos iniciales como "entrada_produccion"
INSERT INTO public.inventory_movements (
  product_id, movement_type, quantity,
  stock_before, stock_after, notes,
  performed_by
)
SELECT 
  p.id,
  'entrada_produccion',
  p.stock_quantity,
  0,
  p.stock_quantity,
  'Stock inicial — carga del sistema',
  'caeefa3e-2081-49e1-b453-b004722a4e6b'::uuid
FROM public.products p
WHERE p.stock_quantity > 0;

-- ============================================================================
-- Verificación
-- ============================================================================
SELECT 
  sku,
  name,
  stock_quantity,
  stock_min_alert,
  CASE 
    WHEN stock_quantity <= stock_min_alert THEN '⚠️ BAJO'
    WHEN stock_quantity <= stock_min_alert * 2 THEN '🟡 ATENCIÓN'
    ELSE '🟢 OK'
  END AS status
FROM public.products
WHERE is_active = TRUE
ORDER BY display_order;

SELECT 
  movement_type,
  COUNT(*) as movimientos,
  SUM(quantity) as unidades_totales
FROM public.inventory_movements
GROUP BY movement_type;
