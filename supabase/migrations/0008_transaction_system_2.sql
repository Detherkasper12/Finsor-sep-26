-- Sprint 18: Transaction System 2.0
-- New columns on transactions; transaction_subcategories; transaction_edits; RLS + indexes

-- 1. Transaction columns: status, split support
ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'cleared',
  ADD COLUMN IF NOT EXISTS parent_transaction_id TEXT,
  ADD COLUMN IF NOT EXISTS is_split BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS split_index INTEGER;

-- 2. transaction_subcategories (tags; analytics use main category only)
CREATE TABLE IF NOT EXISTS transaction_subcategories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid(),
  transaction_id TEXT NOT NULL,
  subcategory_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_transaction_subcategories_user_tx ON transaction_subcategories (user_id, transaction_id);
CREATE INDEX idx_transaction_subcategories_user_sub ON transaction_subcategories (user_id, subcategory_id);
CREATE INDEX idx_transaction_subcategories_sync ON transaction_subcategories (user_id, updated_at);

ALTER TABLE transaction_subcategories ENABLE ROW LEVEL SECURITY;
CREATE POLICY transaction_subcategories_select ON transaction_subcategories FOR SELECT USING (user_id = auth.uid());
CREATE POLICY transaction_subcategories_insert ON transaction_subcategories FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY transaction_subcategories_update ON transaction_subcategories FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY transaction_subcategories_delete ON transaction_subcategories FOR DELETE USING (user_id = auth.uid());

-- 3. transaction_edits (audit trail)
CREATE TABLE IF NOT EXISTS transaction_edits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid(),
  transaction_id TEXT NOT NULL,
  previous_amount DOUBLE PRECISION,
  previous_category_id TEXT,
  previous_date TIMESTAMPTZ,
  previous_wallet_id TEXT,
  previous_status TEXT,
  edited_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_transaction_edits_transaction ON transaction_edits (user_id, transaction_id);
CREATE INDEX idx_transaction_edits_edited_at ON transaction_edits (user_id, edited_at);

ALTER TABLE transaction_edits ENABLE ROW LEVEL SECURITY;
CREATE POLICY transaction_edits_select ON transaction_edits FOR SELECT USING (user_id = auth.uid());
CREATE POLICY transaction_edits_insert ON transaction_edits FOR INSERT WITH CHECK (user_id = auth.uid());

-- 4. Indexes for transactions (status, date, wallet, category for filters and perf)
CREATE INDEX IF NOT EXISTS idx_transactions_user_wallet ON transactions (user_id, wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_category ON transactions (user_id, category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_parent ON transactions (user_id, parent_transaction_id) WHERE parent_transaction_id IS NOT NULL;
