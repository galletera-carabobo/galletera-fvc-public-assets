-- ============================================================================
-- SPRINT 01b — Add rejection_reason to orders
-- ============================================================================
-- Required for admin to log why a pending order was rejected
-- ============================================================================

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Verify
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'orders'
  AND column_name IN ('approved_by', 'approved_at', 'rejection_reason')
ORDER BY column_name;
