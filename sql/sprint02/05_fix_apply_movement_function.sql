-- ============================================================================
-- FIX: Recrear apply_inventory_movement con tipos explícitos
-- ============================================================================
-- El error "function does not exist" ocurre porque PostgreSQL hace overloading
-- por tipos. Si el cliente Supabase pasa NUMERIC en lugar de INTEGER en quantity,
-- no encuentra la función. Recreamos con tipos exactos y un wrapper que acepta NUMERIC.
-- ============================================================================

-- Drop versión anterior por si quedó mal
DROP FUNCTION IF EXISTS public.apply_inventory_movement(UUID, TEXT, INTEGER, UUID, TEXT, UUID);
DROP FUNCTION IF EXISTS public.apply_inventory_movement(UUID, TEXT, NUMERIC, UUID, TEXT, UUID);

-- Recrear con NUMERIC para compatibilidad con clientes JS
CREATE OR REPLACE FUNCTION public.apply_inventory_movement(
  p_product_id UUID,
  p_movement_type TEXT,
  p_quantity NUMERIC,
  p_order_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_performed_by UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_stock_before INTEGER;
  v_stock_after INTEGER;
  v_movement_id UUID;
  v_quantity_int INTEGER;
BEGIN
  -- Convertir a INTEGER
  v_quantity_int := p_quantity::INTEGER;
  
  IF v_quantity_int = 0 THEN
    RAISE EXCEPTION 'La cantidad no puede ser cero';
  END IF;
  
  -- Lock row para evitar race conditions
  SELECT stock_quantity INTO v_stock_before
  FROM public.products
  WHERE id = p_product_id
  FOR UPDATE;
  
  IF v_stock_before IS NULL THEN
    RAISE EXCEPTION 'Producto no encontrado: %', p_product_id;
  END IF;
  
  v_stock_after := v_stock_before + v_quantity_int;
  
  IF v_stock_after < 0 THEN
    RAISE EXCEPTION 'Stock insuficiente. Disponible: %, intentando salida: %', 
      v_stock_before, ABS(v_quantity_int);
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
    p_product_id, p_movement_type, v_quantity_int,
    v_stock_before, v_stock_after,
    p_order_id, p_notes, p_performed_by
  ) RETURNING id INTO v_movement_id;
  
  RETURN v_movement_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.apply_inventory_movement(UUID, TEXT, NUMERIC, UUID, TEXT, UUID) TO authenticated, service_role;

-- Verificar que la función exists
SELECT 
  routine_name,
  pg_get_function_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as return_type
FROM information_schema.routines r
JOIN pg_proc p ON p.proname = r.routine_name
WHERE r.routine_schema = 'public' 
  AND r.routine_name = 'apply_inventory_movement';
