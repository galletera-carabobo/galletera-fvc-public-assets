-- ============================================================================
-- SPRINT 01b — MIGRATION: VENDOR MONTHLY QUOTAS
-- ============================================================================
-- Sistema de cupos mensuales por vendedor.
--
-- Modelo de negocio (definido con Jose, gerente Galletera Carabobo):
--   - A principio de mes, admin asigna cupo en kg a cada vendedor
--   - Pedidos en status: aprobado, despachado, entregado, pagado
--     descuentan del cupo (cancelados/rechazados NO descuentan)
--   - Pendientes muestran como "potencial" pero NO descuentan hasta aprobar
--   - Opcional: cupo en USD y cupo por categoría (soda, maria, cafe)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.vendor_monthly_quotas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendedor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Periodo
  year INTEGER NOT NULL CHECK (year >= 2024 AND year <= 2100),
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  
  -- Cupo principal (REQUERIDO)
  target_kg NUMERIC(10, 2) NOT NULL CHECK (target_kg > 0),
  
  -- Cupo USD (OPCIONAL)
  target_amount NUMERIC(12, 2) CHECK (target_amount IS NULL OR target_amount > 0),
  
  -- Cupos por categoría (OPCIONAL, todos nullable)
  -- Si están NULL, no se hace tracking por categoría
  target_kg_soda NUMERIC(10, 2) CHECK (target_kg_soda IS NULL OR target_kg_soda >= 0),
  target_kg_maria NUMERIC(10, 2) CHECK (target_kg_maria IS NULL OR target_kg_maria >= 0),
  target_kg_cafe NUMERIC(10, 2) CHECK (target_kg_cafe IS NULL OR target_kg_cafe >= 0),
  
  -- Notas del admin al asignar
  notes TEXT,
  
  -- Audit
  assigned_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Solo un cupo por vendedor-año-mes
  UNIQUE (vendedor_id, year, month)
);

CREATE INDEX idx_quotas_vendedor ON public.vendor_monthly_quotas(vendedor_id);
CREATE INDEX idx_quotas_period ON public.vendor_monthly_quotas(year, month);
CREATE INDEX idx_quotas_assigned_by ON public.vendor_monthly_quotas(assigned_by);

-- Trigger updated_at
CREATE TRIGGER trg_quotas_updated_at BEFORE UPDATE ON public.vendor_monthly_quotas
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ----------------------------------------------------------------------------
-- RLS Policies
-- ----------------------------------------------------------------------------
ALTER TABLE public.vendor_monthly_quotas ENABLE ROW LEVEL SECURITY;

-- Vendedores ven solo su propio cupo
CREATE POLICY quotas_select_own ON public.vendor_monthly_quotas
  FOR SELECT TO authenticated
  USING (vendedor_id = auth.uid() OR public.is_admin_or_supervisor());

-- Solo admin/supervisor crean cupos
CREATE POLICY quotas_insert_admin ON public.vendor_monthly_quotas
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin_or_supervisor());

-- Solo admin/supervisor modifican
CREATE POLICY quotas_update_admin ON public.vendor_monthly_quotas
  FOR UPDATE TO authenticated
  USING (public.is_admin_or_supervisor())
  WITH CHECK (public.is_admin_or_supervisor());

-- Solo admin elimina
CREATE POLICY quotas_delete_admin ON public.vendor_monthly_quotas
  FOR DELETE TO authenticated
  USING (public.is_admin());

-- Grants
GRANT ALL ON public.vendor_monthly_quotas TO anon, authenticated, service_role;

-- ----------------------------------------------------------------------------
-- VISTA: vendor_quota_progress_v
-- Combina cupo asignado + ventas reales del mes para mostrar progreso
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.vendor_quota_progress_v AS
WITH monthly_sales AS (
  SELECT
    o.vendedor_id,
    EXTRACT(YEAR FROM o.order_date)::INTEGER AS year,
    EXTRACT(MONTH FROM o.order_date)::INTEGER AS month,
    
    -- KGs vendidos (solo status que cuentan)
    COALESCE(SUM(o.total_weight_kg) FILTER (
      WHERE o.status IN ('aprobado', 'despachado', 'entregado', 'pagado')
    ), 0) AS kg_sold,
    
    -- USD vendidos
    COALESCE(SUM(o.total_amount) FILTER (
      WHERE o.status IN ('aprobado', 'despachado', 'entregado', 'pagado')
    ), 0) AS amount_sold,
    
    -- KGs pendientes (potencial)
    COALESCE(SUM(o.total_weight_kg) FILTER (
      WHERE o.status = 'pendiente'
    ), 0) AS kg_pending,
    
    -- Pedidos count
    COUNT(*) FILTER (WHERE o.status IN ('aprobado', 'despachado', 'entregado', 'pagado')) AS orders_approved,
    COUNT(*) FILTER (WHERE o.status = 'pendiente') AS orders_pending
    
  FROM public.orders o
  GROUP BY o.vendedor_id, EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
),
monthly_sales_by_category AS (
  SELECT
    o.vendedor_id,
    EXTRACT(YEAR FROM o.order_date)::INTEGER AS year,
    EXTRACT(MONTH FROM o.order_date)::INTEGER AS month,
    p.category,
    SUM(oi.weight_kg) AS kg_sold
  FROM public.orders o
  JOIN public.order_items oi ON oi.order_id = o.id
  JOIN public.products p ON p.id = oi.product_id
  WHERE o.status IN ('aprobado', 'despachado', 'entregado', 'pagado')
  GROUP BY o.vendedor_id, EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date), p.category
)
SELECT
  q.id AS quota_id,
  q.vendedor_id,
  p.full_name AS vendedor_name,
  p.zone AS vendedor_zone,
  q.year,
  q.month,
  
  -- Cupos asignados
  q.target_kg,
  q.target_amount,
  q.target_kg_soda,
  q.target_kg_maria,
  q.target_kg_cafe,
  
  -- Ventas reales
  COALESCE(ms.kg_sold, 0) AS kg_sold,
  COALESCE(ms.amount_sold, 0) AS amount_sold,
  COALESCE(ms.kg_pending, 0) AS kg_pending,
  COALESCE(ms.orders_approved, 0) AS orders_approved,
  COALESCE(ms.orders_pending, 0) AS orders_pending,
  
  -- Cupo restante
  GREATEST(q.target_kg - COALESCE(ms.kg_sold, 0), 0) AS kg_remaining,
  
  -- % cumplimiento (puede pasar 100% si supera el cupo)
  CASE
    WHEN q.target_kg > 0 THEN ROUND((COALESCE(ms.kg_sold, 0) / q.target_kg) * 100, 1)
    ELSE 0
  END AS completion_percent,
  
  -- Status text para UI
  CASE
    WHEN COALESCE(ms.kg_sold, 0) >= q.target_kg THEN 'completed'
    WHEN COALESCE(ms.kg_sold, 0) / q.target_kg >= 0.8 THEN 'on_track'
    WHEN COALESCE(ms.kg_sold, 0) / q.target_kg >= 0.5 THEN 'in_progress'
    WHEN COALESCE(ms.kg_sold, 0) / q.target_kg >= 0.25 THEN 'behind'
    ELSE 'critical'
  END AS status_label,
  
  -- Ventas por categoría (subqueries para no romper join cardinality)
  (SELECT kg_sold FROM monthly_sales_by_category msc 
   WHERE msc.vendedor_id = q.vendedor_id AND msc.year = q.year AND msc.month = q.month AND msc.category = 'soda') AS kg_sold_soda,
  
  (SELECT kg_sold FROM monthly_sales_by_category msc 
   WHERE msc.vendedor_id = q.vendedor_id AND msc.year = q.year AND msc.month = q.month AND msc.category = 'maria') AS kg_sold_maria,
  
  (SELECT kg_sold FROM monthly_sales_by_category msc 
   WHERE msc.vendedor_id = q.vendedor_id AND msc.year = q.year AND msc.month = q.month AND msc.category = 'cafe') AS kg_sold_cafe,
  
  q.notes,
  q.assigned_by,
  q.created_at,
  q.updated_at
FROM public.vendor_monthly_quotas q
JOIN public.profiles p ON p.id = q.vendedor_id
LEFT JOIN monthly_sales ms ON ms.vendedor_id = q.vendedor_id 
                           AND ms.year = q.year 
                           AND ms.month = q.month;

-- Grant access
GRANT SELECT ON public.vendor_quota_progress_v TO anon, authenticated, service_role;

-- ----------------------------------------------------------------------------
-- Función helper: get_current_quota(vendedor_id)
-- Retorna el cupo del mes actual o NULL si no hay
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_current_vendor_quota(p_vendedor_id UUID)
RETURNS TABLE (
  quota_id UUID,
  year INTEGER,
  month INTEGER,
  target_kg NUMERIC,
  target_amount NUMERIC,
  kg_sold NUMERIC,
  kg_pending NUMERIC,
  kg_remaining NUMERIC,
  completion_percent NUMERIC,
  status_label TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.quota_id,
    v.year,
    v.month,
    v.target_kg,
    v.target_amount,
    v.kg_sold,
    v.kg_pending,
    v.kg_remaining,
    v.completion_percent,
    v.status_label
  FROM public.vendor_quota_progress_v v
  WHERE v.vendedor_id = p_vendedor_id
    AND v.year = EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER
    AND v.month = EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_current_vendor_quota TO anon, authenticated, service_role;

-- ----------------------------------------------------------------------------
-- Verificación
-- ----------------------------------------------------------------------------
SELECT 'Tabla creada' AS resultado, 
  (SELECT COUNT(*) FROM information_schema.tables 
   WHERE table_schema = 'public' AND table_name = 'vendor_monthly_quotas') AS check;

SELECT 'Vista creada' AS resultado,
  (SELECT COUNT(*) FROM information_schema.views 
   WHERE table_schema = 'public' AND table_name = 'vendor_quota_progress_v') AS check;

SELECT 'Función creada' AS resultado,
  (SELECT COUNT(*) FROM information_schema.routines 
   WHERE routine_schema = 'public' AND routine_name = 'get_current_vendor_quota') AS check;
