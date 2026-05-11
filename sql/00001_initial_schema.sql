-- ============================================================================
-- Galletera FVC App — Initial Schema
-- ============================================================================
-- Migration: 00001_initial_schema
-- Created: May 10, 2026
-- Author: Juan Riera
--
-- This schema is designed with SAP-ready fields for future Phase 2 integration.
-- SAP-specific fields (sap_*) are nullable in Phase 1 and populated during
-- bidirectional SAP sync in Phase 2.
-- ============================================================================

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE user_role AS ENUM ('admin', 'supervisor', 'vendedor');

CREATE TYPE order_status AS ENUM (
  'borrador',     -- Created offline, pending sync
  'pendiente',    -- Synced, awaiting admin review
  'aprobado',     -- Admin approved
  'despachado',   -- In transit
  'entregado',    -- Delivered
  'pagado',       -- Payment received
  'cancelado',    -- Cancelled
  'rechazado'     -- Admin rejected
);

CREATE TYPE client_status AS ENUM ('activo', 'inactivo', 'prospecto', 'bloqueado');

CREATE TYPE client_type AS ENUM (
  'bodega',
  'supermercado',
  'distribuidor',
  'mayorista',
  'minorista',
  'institucional'
);

CREATE TYPE payment_term AS ENUM ('contado', 'credito_7', 'credito_15', 'credito_30');

CREATE TYPE visit_frequency AS ENUM ('semanal', 'quincenal', 'mensual', 'esporadico');

CREATE TYPE visit_status AS ENUM ('planificada', 'en_curso', 'completada', 'no_realizada');

CREATE TYPE audit_action AS ENUM ('INSERT', 'UPDATE', 'DELETE');

-- ============================================================================
-- TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- profiles: extends auth.users with app-level data
-- ----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'vendedor',
  phone TEXT,
  avatar_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,

  -- Vendedor-specific
  zone TEXT,
  vehicle_plate TEXT,
  monthly_target_kg NUMERIC(10, 2),
  monthly_target_amount NUMERIC(12, 2),

  -- Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id)
);

CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_is_active ON public.profiles(is_active);

-- ----------------------------------------------------------------------------
-- products: catalog with SAP-ready fields
-- ----------------------------------------------------------------------------
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,

  -- Pricing
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  cost NUMERIC(10, 2) CHECK (cost >= 0),

  -- Inventory
  unit TEXT NOT NULL DEFAULT 'unidad',
  units_per_case INTEGER NOT NULL DEFAULT 1 CHECK (units_per_case > 0),
  weight_kg NUMERIC(8, 3) NOT NULL CHECK (weight_kg > 0),

  -- SAP-ready
  sap_matnr TEXT UNIQUE,
  sap_meins TEXT,
  sap_brgew NUMERIC(8, 3),

  -- Display
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,

  -- Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_category ON public.products(category);
CREATE INDEX idx_products_is_active ON public.products(is_active);
CREATE INDEX idx_products_sku ON public.products(sku);

-- ----------------------------------------------------------------------------
-- clients: customers with geolocation and SAP-ready fields
-- ----------------------------------------------------------------------------
CREATE TABLE public.clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  business_name TEXT NOT NULL,
  trade_name TEXT,

  -- Contact
  contact_name TEXT NOT NULL,
  contact_phone TEXT NOT NULL,
  contact_email TEXT,

  -- Type & status
  client_type client_type NOT NULL,
  status client_status NOT NULL DEFAULT 'activo',
  payment_term payment_term NOT NULL DEFAULT 'contado',
  credit_limit NUMERIC(12, 2),
  current_balance NUMERIC(12, 2) NOT NULL DEFAULT 0,

  -- Location
  state TEXT NOT NULL,
  city TEXT NOT NULL,
  address TEXT NOT NULL,
  zone TEXT,
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),

  -- Fiscal
  tax_id TEXT,

  -- Visit cadence
  visit_frequency visit_frequency NOT NULL DEFAULT 'mensual',

  -- SAP-ready
  sap_kunnr TEXT UNIQUE,
  sap_vkorg TEXT,
  sap_region TEXT,

  -- Photo & notes
  photo_url TEXT,
  notes TEXT,

  -- Assignment
  assigned_vendedor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

  -- Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id),
  last_visit_at TIMESTAMPTZ,
  last_order_at TIMESTAMPTZ
);

CREATE INDEX idx_clients_status ON public.clients(status);
CREATE INDEX idx_clients_state ON public.clients(state);
CREATE INDEX idx_clients_assigned_vendedor ON public.clients(assigned_vendedor_id);
CREATE INDEX idx_clients_code ON public.clients(code);
CREATE INDEX idx_clients_location ON public.clients(latitude, longitude);

-- ----------------------------------------------------------------------------
-- orders: sales orders with offline sync support
-- ----------------------------------------------------------------------------
CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT NOT NULL UNIQUE,

  -- Relations
  client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE RESTRICT,
  vendedor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,

  -- Status & dates
  status order_status NOT NULL DEFAULT 'pendiente',
  order_date DATE NOT NULL DEFAULT CURRENT_DATE,
  delivery_date DATE,

  -- Amounts (all stored, computed in app for consistency)
  subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
  tax_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
  total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
  total_weight_kg NUMERIC(10, 3) NOT NULL DEFAULT 0 CHECK (total_weight_kg >= 0),

  -- Payment
  payment_term payment_term NOT NULL DEFAULT 'contado',
  payment_due_date DATE,
  paid_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),

  -- Location at creation
  created_lat NUMERIC(10, 7),
  created_lng NUMERIC(10, 7),

  -- Notes
  notes TEXT,
  internal_notes TEXT,

  -- Offline sync
  is_synced BOOLEAN NOT NULL DEFAULT TRUE,
  local_id TEXT UNIQUE,
  synced_at TIMESTAMPTZ,

  -- SAP-ready
  sap_vbeln TEXT UNIQUE,
  sap_auart TEXT,
  sap_exported_at TIMESTAMPTZ,

  -- Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES public.profiles(id),
  approved_by UUID REFERENCES public.profiles(id),
  approved_at TIMESTAMPTZ
);

CREATE INDEX idx_orders_client ON public.orders(client_id);
CREATE INDEX idx_orders_vendedor ON public.orders(vendedor_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_order_date ON public.orders(order_date DESC);
CREATE INDEX idx_orders_local_id ON public.orders(local_id) WHERE local_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- order_items: line items of each order
-- ----------------------------------------------------------------------------
CREATE TABLE public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,

  quantity NUMERIC(10, 3) NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
  discount_percent NUMERIC(5, 2) NOT NULL DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
  subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal >= 0),
  weight_kg NUMERIC(10, 3) NOT NULL CHECK (weight_kg >= 0),

  notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_items_order ON public.order_items(order_id);
CREATE INDEX idx_order_items_product ON public.order_items(product_id);

-- ----------------------------------------------------------------------------
-- visits: vendedor check-ins to clients
-- ----------------------------------------------------------------------------
CREATE TABLE public.visits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  vendedor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

  status visit_status NOT NULL DEFAULT 'planificada',

  -- Check-in geolocation
  check_in_lat NUMERIC(10, 7),
  check_in_lng NUMERIC(10, 7),
  check_in_at TIMESTAMPTZ,
  check_in_accuracy NUMERIC(8, 2),

  check_out_at TIMESTAMPTZ,

  -- Result
  resulted_in_order BOOLEAN NOT NULL DEFAULT FALSE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,

  -- Notes
  visit_notes TEXT,
  client_feedback TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_visits_client ON public.visits(client_id);
CREATE INDEX idx_visits_vendedor ON public.visits(vendedor_id);
CREATE INDEX idx_visits_status ON public.visits(status);
CREATE INDEX idx_visits_check_in_at ON public.visits(check_in_at DESC);

-- ----------------------------------------------------------------------------
-- audit_log: track all changes for compliance
-- ----------------------------------------------------------------------------
CREATE TABLE public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  action audit_action NOT NULL,
  changed_by UUID REFERENCES public.profiles(id),
  changes JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_table_record ON public.audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_changed_by ON public.audit_log(changed_by);
CREATE INDEX idx_audit_log_created_at ON public.audit_log(created_at DESC);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- update_updated_at: auto-update updated_at timestamp
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_clients_updated_at BEFORE UPDATE ON public.clients
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_visits_updated_at BEFORE UPDATE ON public.visits
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ----------------------------------------------------------------------------
-- handle_new_user: create profile when auth.users gets a new entry
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'vendedor')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ----------------------------------------------------------------------------
-- generate_order_number: PED-2026-000001 format
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
  year_str TEXT;
  counter INTEGER;
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    year_str := TO_CHAR(NOW(), 'YYYY');
    SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 10) AS INTEGER)), 0) + 1
    INTO counter
    FROM public.orders
    WHERE order_number LIKE 'PED-' || year_str || '-%';

    NEW.order_number := 'PED-' || year_str || '-' || LPAD(counter::TEXT, 6, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_generate_number BEFORE INSERT ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.generate_order_number();

-- ----------------------------------------------------------------------------
-- generate_client_code: CL-000001 format
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_client_code()
RETURNS TRIGGER AS $$
DECLARE
  counter INTEGER;
BEGIN
  IF NEW.code IS NULL OR NEW.code = '' THEN
    SELECT COALESCE(MAX(CAST(SUBSTRING(code FROM 4) AS INTEGER)), 0) + 1
    INTO counter
    FROM public.clients
    WHERE code LIKE 'CL-%';

    NEW.code := 'CL-' || LPAD(counter::TEXT, 6, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_clients_generate_code BEFORE INSERT ON public.clients
  FOR EACH ROW EXECUTE FUNCTION public.generate_client_code();

-- ----------------------------------------------------------------------------
-- update_client_last_order: keep last_order_at in sync
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_client_last_order()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.clients
  SET last_order_at = NEW.created_at
  WHERE id = NEW.client_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_update_client_last_order AFTER INSERT ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_client_last_order();

-- ----------------------------------------------------------------------------
-- update_client_last_visit: keep last_visit_at in sync
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_client_last_visit()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.check_in_at IS NOT NULL AND (OLD.check_in_at IS NULL OR NEW.check_in_at <> OLD.check_in_at) THEN
    UPDATE public.clients
    SET last_visit_at = NEW.check_in_at
    WHERE id = NEW.client_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_visits_update_client_last_visit AFTER INSERT OR UPDATE ON public.visits
  FOR EACH ROW EXECUTE FUNCTION public.update_client_last_visit();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- Helper: get current user role (cached in claims)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin_or_supervisor()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role IN ('admin', 'supervisor')
      AND is_active = TRUE
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin' AND is_active = TRUE
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- profiles policies
-- ----------------------------------------------------------------------------

-- All authenticated users can read their own profile
CREATE POLICY "profiles_read_own"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Admins and supervisors can read all profiles
CREATE POLICY "profiles_read_all_admin"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (public.is_admin_or_supervisor());

-- Admins can insert profiles
CREATE POLICY "profiles_insert_admin"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- Users can update their own profile (limited fields enforced in app)
CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Admins can update any profile
CREATE POLICY "profiles_update_admin"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- products policies
-- ----------------------------------------------------------------------------

-- All authenticated users can read active products
CREATE POLICY "products_read_active"
  ON public.products FOR SELECT
  TO authenticated
  USING (is_active = TRUE OR public.is_admin_or_supervisor());

-- Only admins can manage products
CREATE POLICY "products_admin_all"
  ON public.products FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- clients policies
-- ----------------------------------------------------------------------------

-- Vendedores can only see clients assigned to them
CREATE POLICY "clients_read_vendedor"
  ON public.clients FOR SELECT
  TO authenticated
  USING (
    assigned_vendedor_id = auth.uid()
    OR public.is_admin_or_supervisor()
  );

-- Vendedores can update clients assigned to them (limited fields)
CREATE POLICY "clients_update_vendedor"
  ON public.clients FOR UPDATE
  TO authenticated
  USING (assigned_vendedor_id = auth.uid())
  WITH CHECK (assigned_vendedor_id = auth.uid());

-- Vendedores can create new clients (prospects)
CREATE POLICY "clients_insert_vendedor"
  ON public.clients FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (status = 'prospecto' OR public.is_admin_or_supervisor())
  );

-- Admins and supervisors can do everything
CREATE POLICY "clients_admin_all"
  ON public.clients FOR ALL
  TO authenticated
  USING (public.is_admin_or_supervisor())
  WITH CHECK (public.is_admin_or_supervisor());

-- ----------------------------------------------------------------------------
-- orders policies
-- ----------------------------------------------------------------------------

-- Vendedores see only their own orders
CREATE POLICY "orders_read_vendedor"
  ON public.orders FOR SELECT
  TO authenticated
  USING (
    vendedor_id = auth.uid()
    OR public.is_admin_or_supervisor()
  );

-- Vendedores can create orders for their clients
CREATE POLICY "orders_insert_vendedor"
  ON public.orders FOR INSERT
  TO authenticated
  WITH CHECK (
    vendedor_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.clients
      WHERE id = client_id
        AND (assigned_vendedor_id = auth.uid() OR public.is_admin_or_supervisor())
    )
  );

-- Vendedores can update only their own pending/draft orders
CREATE POLICY "orders_update_vendedor"
  ON public.orders FOR UPDATE
  TO authenticated
  USING (
    vendedor_id = auth.uid()
    AND status IN ('borrador', 'pendiente')
  )
  WITH CHECK (
    vendedor_id = auth.uid()
    AND status IN ('borrador', 'pendiente')
  );

-- Admins and supervisors can do everything
CREATE POLICY "orders_admin_all"
  ON public.orders FOR ALL
  TO authenticated
  USING (public.is_admin_or_supervisor())
  WITH CHECK (public.is_admin_or_supervisor());

-- ----------------------------------------------------------------------------
-- order_items policies (inherit access from parent order)
-- ----------------------------------------------------------------------------

CREATE POLICY "order_items_read"
  ON public.order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE id = order_id
        AND (vendedor_id = auth.uid() OR public.is_admin_or_supervisor())
    )
  );

CREATE POLICY "order_items_insert"
  ON public.order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE id = order_id
        AND vendedor_id = auth.uid()
        AND status IN ('borrador', 'pendiente')
    )
    OR public.is_admin_or_supervisor()
  );

CREATE POLICY "order_items_update"
  ON public.order_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE id = order_id
        AND vendedor_id = auth.uid()
        AND status IN ('borrador', 'pendiente')
    )
    OR public.is_admin_or_supervisor()
  );

CREATE POLICY "order_items_delete"
  ON public.order_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE id = order_id
        AND vendedor_id = auth.uid()
        AND status IN ('borrador', 'pendiente')
    )
    OR public.is_admin_or_supervisor()
  );

-- ----------------------------------------------------------------------------
-- visits policies
-- ----------------------------------------------------------------------------

CREATE POLICY "visits_read_vendedor"
  ON public.visits FOR SELECT
  TO authenticated
  USING (
    vendedor_id = auth.uid()
    OR public.is_admin_or_supervisor()
  );

CREATE POLICY "visits_insert_vendedor"
  ON public.visits FOR INSERT
  TO authenticated
  WITH CHECK (vendedor_id = auth.uid() OR public.is_admin_or_supervisor());

CREATE POLICY "visits_update_vendedor"
  ON public.visits FOR UPDATE
  TO authenticated
  USING (vendedor_id = auth.uid() OR public.is_admin_or_supervisor())
  WITH CHECK (vendedor_id = auth.uid() OR public.is_admin_or_supervisor());

-- ----------------------------------------------------------------------------
-- audit_log policies (read-only except for inserts via trigger)
-- ----------------------------------------------------------------------------

CREATE POLICY "audit_log_read_admin"
  ON public.audit_log FOR SELECT
  TO authenticated
  USING (public.is_admin_or_supervisor());

-- ============================================================================
-- DONE
-- ============================================================================
COMMENT ON SCHEMA public IS 'Galletera FVC App - Phase 1 Schema (May 2026). SAP-ready fields prepared for Phase 2 integration.';
