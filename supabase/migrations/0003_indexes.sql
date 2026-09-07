-- Sync indexes: (user_id, updated_at) for delta pull
CREATE INDEX idx_wallets_sync ON wallets (user_id, updated_at);
CREATE INDEX idx_categories_sync ON categories (user_id, updated_at);
CREATE INDEX idx_transactions_sync ON transactions (user_id, updated_at);
CREATE INDEX idx_budgets_sync ON budgets (user_id, updated_at);
CREATE INDEX idx_recurring_sync ON recurring_transactions (user_id, updated_at);
CREATE INDEX idx_goals_sync ON goals (user_id, updated_at);
CREATE INDEX idx_settings_sync ON user_settings (user_id, updated_at);

-- Soft delete indexes: (user_id, deleted_at)
CREATE INDEX idx_wallets_deleted ON wallets (user_id, deleted_at);
CREATE INDEX idx_categories_deleted ON categories (user_id, deleted_at);
CREATE INDEX idx_transactions_deleted ON transactions (user_id, deleted_at);
CREATE INDEX idx_budgets_deleted ON budgets (user_id, deleted_at);
CREATE INDEX idx_recurring_deleted ON recurring_transactions (user_id, deleted_at);
CREATE INDEX idx_goals_deleted ON goals (user_id, deleted_at);
CREATE INDEX idx_settings_deleted ON user_settings (user_id, deleted_at);

-- Transaction-specific: (user_id, date) for queries by period
CREATE INDEX idx_transactions_date ON transactions (user_id, date);
