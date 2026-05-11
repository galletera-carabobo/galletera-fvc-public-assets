-- ============================================================================
-- SPRINT 01b — SEED: CUPOS MENSUALES (enero-mayo 2026)
-- ============================================================================
-- 5 meses x 13 vendedores = 65 cupos
-- Variación realista:
--   - Cupos crecen mes a mes (Galletera planifica crecimiento)
--   - Cupos en kg basados en monthly_target_kg de profiles
--   - Cupos en USD basados en monthly_target_amount
--   - Mayo (mes actual) tiene cupo asignado, esperando cumplimiento
-- ============================================================================

DO $$
DECLARE
  v_admin_id UUID := 'caeefa3e-2081-49e1-b453-b004722a4e6b'::uuid;
  v_vendedor RECORD;
  v_month INTEGER;
  v_target_kg NUMERIC;
  v_target_amount NUMERIC;
  v_growth_factor NUMERIC;
  v_inserted INTEGER := 0;
BEGIN
  FOR v_vendedor IN
    SELECT id, full_name, monthly_target_kg, monthly_target_amount
    FROM public.profiles
    WHERE role = 'vendedor'
  LOOP
    FOR v_month IN 1..5 LOOP
      -- Factor de crecimiento: enero 0.92, feb 0.96, mar 1.0, abr 1.04, may 1.08
      v_growth_factor := CASE v_month
        WHEN 1 THEN 0.92
        WHEN 2 THEN 0.96
        WHEN 3 THEN 1.00
        WHEN 4 THEN 1.04
        WHEN 5 THEN 1.08
      END;
      
      v_target_kg := ROUND(v_vendedor.monthly_target_kg * v_growth_factor, 2);
      v_target_amount := ROUND(v_vendedor.monthly_target_amount * v_growth_factor, 2);
      
      INSERT INTO public.vendor_monthly_quotas (
        vendedor_id, year, month,
        target_kg, target_amount,
        notes,
        assigned_by
      ) VALUES (
        v_vendedor.id, 2026, v_month,
        v_target_kg, v_target_amount,
        CASE v_month
          WHEN 5 THEN 'Cupo del mes en curso'
          ELSE 'Cupo planificado'
        END,
        v_admin_id
      )
      ON CONFLICT (vendedor_id, year, month) DO NOTHING;
      
      v_inserted := v_inserted + 1;
    END LOOP;
  END LOOP;
  
  RAISE NOTICE 'Cupos creados: %', v_inserted;
END $$;

-- Verificación: vista del progreso
SELECT 
  vendedor_name,
  vendedor_zone,
  month,
  target_kg,
  kg_sold,
  kg_remaining,
  completion_percent,
  status_label
FROM public.vendor_quota_progress_v
WHERE year = 2026 AND month = 4  -- abril
ORDER BY completion_percent DESC;

-- Resumen por mes
SELECT 
  month,
  COUNT(*) AS num_quotas,
  ROUND(SUM(target_kg), 2) AS total_kg_asignado,
  ROUND(SUM(kg_sold), 2) AS total_kg_vendido,
  ROUND(AVG(completion_percent), 1) AS avg_completion
FROM public.vendor_quota_progress_v
WHERE year = 2026
GROUP BY month
ORDER BY month;
