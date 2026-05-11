-- ============================================================================
-- SPRINT 01 — SEED 03: 70 CLIENTES DISTRIBUIDOS
-- ============================================================================
-- Mix realista por tipo de negocio venezolano:
--   25 bodegas (urbanas pequeñas)
--   18 supermercados pequeños
--   14 distribuidores (mediano)
--   10 mayoristas (grandes)
--   3 institucionales (colegios, hospitales)
-- 
-- Cada cliente asignado al vendedor de su zona
-- RIF venezolanos válidos (formato J-12345678-9)
-- Coordenadas reales aproximadas de cada ciudad
-- SAP kunnr preparado para integración Phase 2
-- ============================================================================

-- ============= VENDOR UUIDs REFERENCE =============
-- 11111111-1111-1111-1111-000000000001 = Carlos Mendoza (Valencia Centro)
-- 11111111-1111-1111-1111-000000000002 = Andrea Pérez (Valencia Norte)
-- 11111111-1111-1111-1111-000000000003 = Luis Rodríguez (Naguanagua)
-- 11111111-1111-1111-1111-000000000004 = María Hernández (San Diego)
-- 11111111-1111-1111-1111-000000000005 = José Castillo (Puerto Cabello)
-- 11111111-1111-1111-1111-000000000006 = Roberto Silva (Maracay)
-- 11111111-1111-1111-1111-000000000007 = Daniela Torres (Turmero)
-- 11111111-1111-1111-1111-000000000008 = Pedro Ramírez (Caracas Centro)
-- 11111111-1111-1111-1111-000000000009 = Carmen López (Caracas Este)
-- 11111111-1111-1111-1111-000000000010 = Gabriel Acosta (Caracas Oeste)
-- 11111111-1111-1111-1111-000000000011 = Francisco Bracho (Maracaibo)
-- 11111111-1111-1111-1111-000000000012 = Beatriz Mujica (Barquisimeto)
-- 11111111-1111-1111-1111-000000000013 = Ricardo Salazar (Los Teques)

INSERT INTO public.clients (
  business_name, trade_name, contact_name, contact_phone, contact_email,
  client_type, status, payment_term, credit_limit,
  state, city, address, zone,
  latitude, longitude, tax_id,
  visit_frequency, assigned_vendedor_id,
  sap_kunnr, sap_vkorg, sap_region
) VALUES

-- ============= CARABOBO - VALENCIA CENTRO (Carlos Mendoza) =============
('Bodega La Esquina C.A.', 'Bodega La Esquina',
 'Juan García', '+58-414-1110001', 'lacesquina@gmail.com',
 'bodega', 'activo', 'contado', 500,
 'Carabobo', 'Valencia', 'Av. Bolívar Norte, Edif. Centro, PB Local 1', 'Valencia Centro',
 10.1620, -68.0090, 'J-30123456-7',
 'semanal', '11111111-1111-1111-1111-000000000001'::uuid,
 'V0010001', 'GC01', 'CARABOBO'),

('Supermercado El Trigal', 'El Trigal',
 'Pedro Méndez', '+58-414-1110002', 'eltrigal@hotmail.com',
 'supermercado', 'activo', 'credito_15', 2500,
 'Carabobo', 'Valencia', 'Av. Lara, C.C. El Recreo Local 25', 'Valencia Centro',
 10.1850, -68.0125, 'J-30234567-8',
 'semanal', '11111111-1111-1111-1111-000000000001'::uuid,
 'V0010002', 'GC01', 'CARABOBO'),

('Distribuidora Aragua Norte', 'Dist. Aragua Norte',
 'Carlos Petit', '+58-424-1110003', 'distaraguan@gmail.com',
 'distribuidor', 'activo', 'credito_30', 8000,
 'Carabobo', 'Valencia', 'Zona Industrial Sur, Galpón 42', 'Valencia Centro',
 10.1500, -67.9900, 'J-30345678-9',
 'quincenal', '11111111-1111-1111-1111-000000000001'::uuid,
 'V0010003', 'GC01', 'CARABOBO'),

('Bodega Don Pepe', 'Don Pepe',
 'José Hernández', '+58-412-1110004', NULL,
 'bodega', 'activo', 'contado', 350,
 'Carabobo', 'Valencia', 'Av. Las Ferias, frente a la plaza', 'Valencia Centro',
 10.1700, -68.0050, 'J-30456789-0',
 'semanal', '11111111-1111-1111-1111-000000000001'::uuid,
 'V0010004', 'GC01', 'CARABOBO'),

('Mayorista Centro C.A.', 'Mayorista Centro',
 'María Salinas', '+58-416-1110005', 'mayoristacentro@gmail.com',
 'mayorista', 'activo', 'credito_30', 15000,
 'Carabobo', 'Valencia', 'Av. Principal Industrial, Galpón 7', 'Valencia Centro',
 10.1450, -67.9850, 'J-30567890-1',
 'quincenal', '11111111-1111-1111-1111-000000000001'::uuid,
 'V0010005', 'GC01', 'CARABOBO'),

('Bodega El Buen Vecino', 'El Buen Vecino',
 'Roberto Salas', '+58-414-1110006', NULL,
 'bodega', 'activo', 'contado', 400,
 'Carabobo', 'Valencia', 'C/c Norte cra 3, casa 15', 'Valencia Centro',
 10.1620, -68.0140, 'J-30678901-2',
 'semanal', '11111111-1111-1111-1111-000000000001'::uuid,
 'V0010006', 'GC01', 'CARABOBO'),

-- ============= CARABOBO - VALENCIA NORTE (Andrea Pérez) =============
('Supermercado El Recreo', 'El Recreo',
 'Luis Marchán', '+58-414-1120001', 'elrecreoval@gmail.com',
 'supermercado', 'activo', 'credito_15', 3000,
 'Carabobo', 'Valencia', 'Av. Andrés Eloy Blanco, La Viña', 'Valencia Norte',
 10.1980, -68.0050, 'J-30789012-3',
 'semanal', '11111111-1111-1111-1111-000000000002'::uuid,
 'V0010007', 'GC01', 'CARABOBO'),

('Bodega Mama Rosa', 'Mama Rosa',
 'Rosa González', '+58-424-1120002', NULL,
 'bodega', 'activo', 'contado', 300,
 'Carabobo', 'Valencia', 'Av. Norte-Sur 9, Local 3', 'Valencia Norte',
 10.2010, -68.0100, 'J-30890123-4',
 'semanal', '11111111-1111-1111-1111-000000000002'::uuid,
 'V0010008', 'GC01', 'CARABOBO'),

('Distribuidora La Viña', 'Dist. La Viña',
 'Carlos Pereira', '+58-412-1120003', 'distviña@gmail.com',
 'distribuidor', 'activo', 'credito_15', 6000,
 'Carabobo', 'Valencia', 'C.C. La Viña, Local 8', 'Valencia Norte',
 10.2050, -68.0080, 'J-30901234-5',
 'quincenal', '11111111-1111-1111-1111-000000000002'::uuid,
 'V0010009', 'GC01', 'CARABOBO'),

('Supermercado Plaza Norte', 'Plaza Norte',
 'Pedro Ríos', '+58-416-1120004', 'plazanorte@gmail.com',
 'supermercado', 'activo', 'credito_15', 2800,
 'Carabobo', 'Valencia', 'Av. Bolívar Norte, C.C. Plaza Norte', 'Valencia Norte',
 10.1990, -68.0020, 'J-30012345-6',
 'semanal', '11111111-1111-1111-1111-000000000002'::uuid,
 'V0010010', 'GC01', 'CARABOBO'),

('Bodega Los Sauces', 'Los Sauces',
 'Ana Martínez', '+58-414-1120005', NULL,
 'bodega', 'activo', 'contado', 380,
 'Carabobo', 'Valencia', 'Urb. Los Sauces, cra 5 c-12', 'Valencia Norte',
 10.2080, -68.0130, 'J-30123450-7',
 'semanal', '11111111-1111-1111-1111-000000000002'::uuid,
 'V0010011', 'GC01', 'CARABOBO'),

-- ============= CARABOBO - NAGUANAGUA (Luis Rodríguez) =============
('Supermercado Naguanagua', 'Super Naguanagua',
 'Ricardo Pérez', '+58-414-1130001', 'supernaguanagua@gmail.com',
 'supermercado', 'activo', 'credito_15', 3200,
 'Carabobo', 'Naguanagua', 'Av. Universidad, C.C. Norte', 'Naguanagua',
 10.2370, -67.9990, 'J-30234561-8',
 'semanal', '11111111-1111-1111-1111-000000000003'::uuid,
 'V0010012', 'GC01', 'CARABOBO'),

('Bodega El Estudiante', 'El Estudiante',
 'Miguel Ortega', '+58-424-1130002', NULL,
 'bodega', 'activo', 'contado', 280,
 'Carabobo', 'Naguanagua', 'Frente a UC, edif. Universitario PB', 'Naguanagua',
 10.2400, -68.0050, 'J-30345672-9',
 'semanal', '11111111-1111-1111-1111-000000000003'::uuid,
 'V0010013', 'GC01', 'CARABOBO'),

('Mayorista Norte C.A.', 'Mayorista Norte',
 'José Linares', '+58-412-1130003', 'mayoristanorte@gmail.com',
 'mayorista', 'activo', 'credito_30', 12000,
 'Carabobo', 'Naguanagua', 'Zona Industrial, Galpón 18', 'Naguanagua',
 10.2300, -67.9920, 'J-30456783-0',
 'quincenal', '11111111-1111-1111-1111-000000000003'::uuid,
 'V0010014', 'GC01', 'CARABOBO'),

('Distribuidora Naguanagua', 'Dist. Naguanagua',
 'Carolina Romero', '+58-416-1130004', 'distnaguanagua@gmail.com',
 'distribuidor', 'activo', 'credito_30', 7500,
 'Carabobo', 'Naguanagua', 'Av. Principal, Galpón 5', 'Naguanagua',
 10.2350, -67.9870, 'J-30567894-1',
 'quincenal', '11111111-1111-1111-1111-000000000003'::uuid,
 'V0010015', 'GC01', 'CARABOBO'),

('Bodega La Paz', 'La Paz',
 'Carmen Vargas', '+58-414-1130005', NULL,
 'bodega', 'activo', 'contado', 320,
 'Carabobo', 'Naguanagua', 'Sec. La Paz, cra 8 c-23', 'Naguanagua',
 10.2420, -68.0100, 'J-30678905-2',
 'semanal', '11111111-1111-1111-1111-000000000003'::uuid,
 'V0010016', 'GC01', 'CARABOBO'),

-- ============= CARABOBO - SAN DIEGO (María Hernández) =============
('Supermercado San Diego', 'Super San Diego',
 'Roberto Salazar', '+58-414-1140001', 'supersandiego@gmail.com',
 'supermercado', 'activo', 'credito_15', 2700,
 'Carabobo', 'San Diego', 'Av. Don Julio Centeno, C.C. Diamond', 'San Diego',
 10.2550, -67.9700, 'J-30789016-3',
 'semanal', '11111111-1111-1111-1111-000000000004'::uuid,
 'V0010017', 'GC01', 'CARABOBO'),

('Bodega El Morro', 'El Morro',
 'Pedro Jiménez', '+58-424-1140002', NULL,
 'bodega', 'activo', 'contado', 350,
 'Carabobo', 'San Diego', 'Urb. El Morro, cra 12 c-45', 'San Diego',
 10.2600, -67.9750, 'J-30890127-4',
 'semanal', '11111111-1111-1111-1111-000000000004'::uuid,
 'V0010018', 'GC01', 'CARABOBO'),

('Distribuidora San Diego C.A.', 'Dist. San Diego',
 'Andrea Camacho', '+58-412-1140003', 'distsandiego@gmail.com',
 'distribuidor', 'activo', 'credito_15', 5500,
 'Carabobo', 'San Diego', 'Av. Principal, Galpón 12', 'San Diego',
 10.2580, -67.9650, 'J-30901238-5',
 'quincenal', '11111111-1111-1111-1111-000000000004'::uuid,
 'V0010019', 'GC01', 'CARABOBO'),

('Mayorista Diamante', 'Mayorista Diamante',
 'Luis Romero', '+58-416-1140004', 'mayoristadiamante@gmail.com',
 'mayorista', 'activo', 'credito_30', 14000,
 'Carabobo', 'San Diego', 'Zona Industrial San Diego', 'San Diego',
 10.2520, -67.9620, 'J-30012349-6',
 'quincenal', '11111111-1111-1111-1111-000000000004'::uuid,
 'V0010020', 'GC01', 'CARABOBO'),

-- ============= CARABOBO - PUERTO CABELLO (José Castillo) =============
('Supermercado Puerto', 'Super Puerto',
 'Ana Gómez', '+58-414-1150001', 'superpuerto@gmail.com',
 'supermercado', 'activo', 'credito_15', 2900,
 'Carabobo', 'Puerto Cabello', 'Av. Salóm, C.C. El Puerto', 'Puerto Cabello',
 10.4730, -68.0140, 'J-30123461-7',
 'semanal', '11111111-1111-1111-1111-000000000005'::uuid,
 'V0010021', 'GC01', 'CARABOBO'),

('Bodega El Pirata', 'El Pirata',
 'Carlos Briceño', '+58-424-1150002', NULL,
 'bodega', 'activo', 'contado', 400,
 'Carabobo', 'Puerto Cabello', 'Casco Histórico, c/ Bolívar 23', 'Puerto Cabello',
 10.4770, -68.0150, 'J-30234572-8',
 'semanal', '11111111-1111-1111-1111-000000000005'::uuid,
 'V0010022', 'GC01', 'CARABOBO'),

('Mayorista Costa', 'Mayorista Costa',
 'Roberto Marín', '+58-412-1150003', 'mayoristacosta@gmail.com',
 'mayorista', 'activo', 'credito_30', 13000,
 'Carabobo', 'Puerto Cabello', 'Zona Industrial Puerto', 'Puerto Cabello',
 10.4650, -68.0070, 'J-30345683-9',
 'quincenal', '11111111-1111-1111-1111-000000000005'::uuid,
 'V0010023', 'GC01', 'CARABOBO'),

('Distribuidora Marina', 'Dist. Marina',
 'María Pacheco', '+58-416-1150004', 'distmarina@gmail.com',
 'distribuidor', 'activo', 'credito_15', 6500,
 'Carabobo', 'Puerto Cabello', 'Av. Principal, sector portuario', 'Puerto Cabello',
 10.4700, -68.0100, 'J-30456794-0',
 'quincenal', '11111111-1111-1111-1111-000000000005'::uuid,
 'V0010024', 'GC01', 'CARABOBO'),

('Instituto Educativo Carabobo', 'IECarabobo',
 'Lic. Carmen Pérez', '+58-414-1150005', 'iecarabobo@edu.ve',
 'institucional', 'activo', 'credito_30', 8000,
 'Carabobo', 'Puerto Cabello', 'Av. Salóm, edif. educativo', 'Puerto Cabello',
 10.4740, -68.0130, 'J-30567805-1',
 'mensual', '11111111-1111-1111-1111-000000000005'::uuid,
 'V0010025', 'GC01', 'CARABOBO');

-- Verificación parcial (CARABOBO)
SELECT city, client_type, COUNT(*) AS clientes
FROM public.clients
WHERE state = 'Carabobo'
GROUP BY city, client_type
ORDER BY city, client_type;
