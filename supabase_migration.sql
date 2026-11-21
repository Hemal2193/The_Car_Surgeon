-- ============================================================================
-- SQL Migration: Replace device_id with user_id + RLS Policies
-- ============================================================================
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================================

-- 1. Drop device_id columns and add user_id columns
ALTER TABLE customers DROP COLUMN IF EXISTS device_id;
ALTER TABLE customers ADD COLUMN user_id UUID REFERENCES auth.users(id);

ALTER TABLE vehicles DROP COLUMN IF EXISTS device_id;
ALTER TABLE vehicles ADD COLUMN user_id UUID REFERENCES auth.users(id);

ALTER TABLE items DROP COLUMN IF EXISTS device_id;
ALTER TABLE items ADD COLUMN user_id UUID REFERENCES auth.users(id);

ALTER TABLE invoices DROP COLUMN IF EXISTS device_id;
ALTER TABLE invoices ADD COLUMN user_id UUID REFERENCES auth.users(id);

ALTER TABLE reminders DROP COLUMN IF EXISTS device_id;
ALTER TABLE reminders ADD COLUMN user_id UUID REFERENCES auth.users(id);

ALTER TABLE payments DROP COLUMN IF EXISTS device_id;
ALTER TABLE payments ADD COLUMN user_id UUID REFERENCES auth.users(id);

-- 2. Create indexes on user_id for performance
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON customers(user_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_user_id ON vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_items_user_id ON items(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);

-- 3. Enable Row Level Security on all tables
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles   ENABLE ROW LEVEL SECURITY;
ALTER TABLE items      ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices   ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders  ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments   ENABLE ROW LEVEL SECURITY;

-- 4. Drop existing policies if any (safe to re-run)
DROP POLICY IF EXISTS "Users can manage own customers" ON customers;
DROP POLICY IF EXISTS "Users can manage own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can manage own items" ON items;
DROP POLICY IF EXISTS "Users can manage own invoices" ON invoices;
DROP POLICY IF EXISTS "Users can manage own reminders" ON reminders;
DROP POLICY IF EXISTS "Users can manage own payments" ON payments;

-- 5. Create RLS policies — users can only access their own rows
CREATE POLICY "Users can manage own customers" ON customers
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage own vehicles" ON vehicles
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage own items" ON items
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage own invoices" ON invoices
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage own reminders" ON reminders
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage own payments" ON payments
  FOR ALL USING (user_id = auth.uid());

-- ============================================================================
-- NOTE: After running this migration:
-- 1. Existing rows will have user_id = NULL initially.
--    You cannot retroactively assign user_id to existing data since it's
--    tied to device_id which has no relation to auth.users.
-- 2. New data will be correctly tagged with the authenticated user's ID.
-- 3. If you need to keep old data, you'll need to manually update user_id
--    for each row based on which user "owns" that data.
-- ============================================================================