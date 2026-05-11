-- ============================================================================
-- SPRINT 01 — SEED 05: PEDIDOS HISTÓRICOS (4 MESES)
-- ============================================================================
-- Generación procedural: ~380 pedidos distribuidos enero-abril 2026
-- Patrones realistas:
--   - Crecimiento mensual: +5% cada mes
--   - Mayoría de pedidos día 1-15, picos los días 25-30
--   - Mix de productos según tipo de cliente
--   - Drop sizes variados ($30 - $500)
--   - 80% pedidos aprobados/entregados/pagados (cerrados)
--   - 15% pendientes o en proceso
--   - 5% cancelados/rechazados
-- ============================================================================

DO $$
DECLARE
  v_client RECORD;
  v_product RECORD;
  v_vendedor_id UUID;
  v_admin_id UUID := 'caeefa3e-2081-49e1-b453-b004722a4e6b'::uuid; -- Juan Riera admin
  
  v_month INTEGER;
  v_day INTEGER;
  v_order_date DATE;
  v_num_orders INTEGER;
  v_order_id UUID;
  v_total_items INTEGER;
  v_status_roll FLOAT;
  v_order_status order_status;
  v_quantity NUMERIC;
  v_unit_price NUMERIC;
  v_subtotal_item NUMERIC;
  v_weight_item NUMERIC;
  v_total_subtotal NUMERIC;
  v_total_weight NUMERIC;
  v_tax NUMERIC;
  v_grand_total NUMERIC;
  v_payment_term payment_term;
  v_delivery_date DATE;
  
  -- Productos cache (para no consultar por cada pedido)
  v_product_ids UUID[];
  v_product_prices NUMERIC[];
  v_product_weights NUMERIC[];
  v_n_products INTEGER;
  v_idx INTEGER;
  
  v_orders_created INTEGER := 0;
BEGIN
  -- Cargar productos a arrays
  SELECT 
    array_agg(id ORDER BY display_order),
    array_agg(price ORDER BY display_order),
    array_agg(weight_kg ORDER BY display_order)
  INTO v_product_ids, v_product_prices, v_product_weights
  FROM public.products
  WHERE is_active = TRUE;
  
  v_n_products := array_length(v_product_ids, 1);
  
  IF v_n_products IS NULL OR v_n_products = 0 THEN
    RAISE EXCEPTION 'No products found. Run 01_seed_products.sql first.';
  END IF;
  
  RAISE NOTICE 'Productos cargados: %', v_n_products;
  
  -- Iterar por cada cliente
  FOR v_client IN
    SELECT id, client_type, payment_term, assigned_vendedor_id, latitude, longitude
    FROM public.clients
    WHERE status = 'activo'
    ORDER BY created_at
  LOOP
    v_vendedor_id := v_client.assigned_vendedor_id;
    
    IF v_vendedor_id IS NULL THEN
      CONTINUE;
    END IF;
    
    -- Iterar por cada mes (enero a abril 2026)
    FOR v_month IN 1..4 LOOP
      -- Cantidad de pedidos en el mes según tipo de cliente
      v_num_orders := CASE v_client.client_type
        WHEN 'mayorista' THEN floor(random() * 2 + 2)::INTEGER       -- 2-3 pedidos/mes
        WHEN 'distribuidor' THEN floor(random() * 2 + 1)::INTEGER    -- 1-2 pedidos/mes
        WHEN 'supermercado' THEN floor(random() * 2 + 2)::INTEGER    -- 2-3 pedidos/mes
        WHEN 'institucional' THEN 1                                    -- 1 pedido/mes
        ELSE floor(random() * 2 + 1)::INTEGER                          -- bodega: 1-2 pedidos/mes
      END;
      
      -- Aplicar growth factor (mes 1 base, mes 4 +20%)
      IF v_month = 4 AND random() < 0.3 THEN
        v_num_orders := v_num_orders + 1;
      END IF;
      
      -- Crear los pedidos
      FOR i IN 1..v_num_orders LOOP
        -- Día del mes con sesgo a fin de mes (60% últimos 10 días)
        IF random() < 0.6 THEN
          v_day := floor(random() * 10 + 20)::INTEGER;  -- días 20-29
        ELSE
          v_day := floor(random() * 19 + 1)::INTEGER;   -- días 1-19
        END IF;
        
        v_day := LEAST(v_day, 28);  -- safe para febrero
        v_order_date := MAKE_DATE(2026, v_month, v_day);
        
        -- Status del pedido
        v_status_roll := random();
        IF v_month < 3 THEN
          -- Meses pasados: 80% pagado/entregado, 15% despachado, 5% cancelado
          IF v_status_roll < 0.65 THEN
            v_order_status := 'pagado';
          ELSIF v_status_roll < 0.80 THEN
            v_order_status := 'entregado';
          ELSIF v_status_roll < 0.95 THEN
            v_order_status := 'despachado';
          ELSE
            v_order_status := 'cancelado';
          END IF;
        ELSIF v_month = 3 THEN
          -- Marzo: 50% pagado, 25% entregado, 15% despachado, 8% aprobado, 2% cancelado
          IF v_status_roll < 0.50 THEN
            v_order_status := 'pagado';
          ELSIF v_status_roll < 0.75 THEN
            v_order_status := 'entregado';
          ELSIF v_status_roll < 0.90 THEN
            v_order_status := 'despachado';
          ELSIF v_status_roll < 0.98 THEN
            v_order_status := 'aprobado';
          ELSE
            v_order_status := 'cancelado';
          END IF;
        ELSE
          -- Abril: 25% pagado, 25% entregado, 20% despachado, 20% aprobado, 8% pendiente, 2% cancelado
          IF v_status_roll < 0.25 THEN
            v_order_status := 'pagado';
          ELSIF v_status_roll < 0.50 THEN
            v_order_status := 'entregado';
          ELSIF v_status_roll < 0.70 THEN
            v_order_status := 'despachado';
          ELSIF v_status_roll < 0.90 THEN
            v_order_status := 'aprobado';
          ELSIF v_status_roll < 0.98 THEN
            v_order_status := 'pendiente';
          ELSE
            v_order_status := 'cancelado';
          END IF;
        END IF;
        
        v_payment_term := v_client.payment_term;
        v_delivery_date := v_order_date + INTERVAL '2 days';
        
        -- Crear order
        INSERT INTO public.orders (
          client_id, vendedor_id, status, order_date, delivery_date,
          subtotal, tax_amount, total_amount, total_weight_kg,
          payment_term, payment_due_date, paid_amount,
          created_lat, created_lng,
          is_synced, synced_at,
          created_at, created_by
        ) VALUES (
          v_client.id, v_vendedor_id, v_order_status, v_order_date, v_delivery_date,
          0, 0, 0, 0,  -- placeholders, llenamos abajo
          v_payment_term, 
          CASE v_payment_term
            WHEN 'credito_7' THEN v_delivery_date + INTERVAL '7 days'
            WHEN 'credito_15' THEN v_delivery_date + INTERVAL '15 days'
            WHEN 'credito_30' THEN v_delivery_date + INTERVAL '30 days'
            ELSE NULL
          END,
          0,
          v_client.latitude + (random() - 0.5) * 0.002,
          v_client.longitude + (random() - 0.5) * 0.002,
          TRUE,
          v_order_date + INTERVAL '5 minutes',
          v_order_date + INTERVAL '10 hours',  -- created during business hours
          v_admin_id
        ) RETURNING id INTO v_order_id;
        
        -- Crear order_items
        -- Mix según tipo de cliente: mayoristas/distribuidores piden de todo, bodegas 1-2 productos
        v_total_items := CASE v_client.client_type
          WHEN 'mayorista' THEN floor(random() * 2 + 4)::INTEGER       -- 4-5 productos
          WHEN 'distribuidor' THEN floor(random() * 2 + 3)::INTEGER    -- 3-4 productos
          WHEN 'supermercado' THEN floor(random() * 2 + 2)::INTEGER    -- 2-3 productos
          WHEN 'institucional' THEN floor(random() * 2 + 1)::INTEGER   -- 1-2 productos
          ELSE floor(random() * 1 + 1)::INTEGER                          -- bodega: 1-2 productos
        END;
        
        v_total_items := LEAST(v_total_items, v_n_products);
        
        v_total_subtotal := 0;
        v_total_weight := 0;
        
        -- Seleccionar productos aleatorios sin repetir
        FOR v_idx IN 1..v_total_items LOOP
          -- Cantidad según tipo cliente
          v_quantity := CASE v_client.client_type
            WHEN 'mayorista' THEN floor(random() * 80 + 50)::NUMERIC      -- 50-130 paquetes
            WHEN 'distribuidor' THEN floor(random() * 50 + 30)::NUMERIC   -- 30-80 paquetes
            WHEN 'supermercado' THEN floor(random() * 30 + 15)::NUMERIC   -- 15-45 paquetes
            WHEN 'institucional' THEN floor(random() * 40 + 20)::NUMERIC  -- 20-60 paquetes
            ELSE floor(random() * 12 + 6)::NUMERIC                          -- bodega: 6-18 paquetes
          END;
          
          v_unit_price := v_product_prices[v_idx];
          v_subtotal_item := v_quantity * v_unit_price;
          v_weight_item := v_quantity * v_product_weights[v_idx];
          
          INSERT INTO public.order_items (
            order_id, product_id, quantity, unit_price,
            discount_percent, subtotal, weight_kg
          ) VALUES (
            v_order_id, v_product_ids[v_idx], v_quantity, v_unit_price,
            0, v_subtotal_item, v_weight_item
          );
          
          v_total_subtotal := v_total_subtotal + v_subtotal_item;
          v_total_weight := v_total_weight + v_weight_item;
        END LOOP;
        
        -- IVA Venezuela 16%
        v_tax := ROUND(v_total_subtotal * 0.16, 2);
        v_grand_total := v_total_subtotal + v_tax;
        
        -- Actualizar order con totales
        UPDATE public.orders 
        SET 
          subtotal = v_total_subtotal,
          tax_amount = v_tax,
          total_amount = v_grand_total,
          total_weight_kg = v_total_weight,
          paid_amount = CASE WHEN v_order_status = 'pagado' THEN v_grand_total ELSE 0 END
        WHERE id = v_order_id;
        
        v_orders_created := v_orders_created + 1;
      END LOOP;  -- pedidos del mes
    END LOOP;  -- meses
  END LOOP;  -- clientes
  
  RAISE NOTICE 'Pedidos creados: %', v_orders_created;
END $$;

-- Verificación
SELECT 
  TO_CHAR(order_date, 'YYYY-MM') AS mes,
  COUNT(*) AS pedidos,
  ROUND(SUM(total_amount), 2) AS facturacion_usd,
  ROUND(AVG(total_amount), 2) AS drop_size_promedio,
  ROUND(SUM(total_weight_kg), 2) AS kg_total
FROM public.orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY mes;

SELECT status, COUNT(*) AS cantidad
FROM public.orders
GROUP BY status
ORDER BY cantidad DESC;

SELECT 'Total pedidos generados' AS metric, COUNT(*) AS value FROM public.orders;
SELECT 'Total order_items' AS metric, COUNT(*) AS value FROM public.order_items;
