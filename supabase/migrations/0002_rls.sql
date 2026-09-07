-- Enable RLS on all tables
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Wallets policies
CREATE POLICY wallets_select ON wallets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY wallets_insert ON wallets FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY wallets_update ON wallets FOR UPDATE USING (user_id = auth.uid());

-- Categories policies
CREATE POLICY categories_select ON categories FOR SELECT USING (user_id = auth.uid());
CREATE POLICY categories_insert ON categories FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY categories_update ON categories FOR UPDATE USING (user_id = auth.uid());

-- Transactions policies
CREATE POLICY transactions_select ON transactions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY transactions_insert ON transactions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY transactions_update ON transactions FOR UPDATE USING (user_id = auth.uid());

-- Budgets policies
CREATE POLICY budgets_select ON budgets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY budgets_insert ON budgets FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY budgets_update ON budgets FOR UPDATE USING (user_id = auth.uid());

-- Recurring transactions policies
CREATE POLICY recurring_select ON recurring_transactions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY recurring_insert ON recurring_transactions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY recurring_update ON recurring_transactions FOR UPDATE USING (user_id = auth.uid());

-- Goals policies
CREATE POLICY goals_select ON goals FOR SELECT USING (user_id = auth.uid());
CREATE POLICY goals_insert ON goals FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY goals_update ON goals FOR UPDATE USING (user_id = auth.uid());

-- User settings policies
CREATE POLICY settings_select ON user_settings FOR SELECT USING (user_id = auth.uid());
CREATE POLICY settings_insert ON user_settings FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY settings_update ON user_settings FOR UPDATE USING (user_id = auth.uid());
