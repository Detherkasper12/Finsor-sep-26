-- Account types (1Money-style) + currency format + start screen
-- Wallets: account_type and type-specific fields
ALTER TABLE wallets
  ADD COLUMN IF NOT EXISTS account_type TEXT NOT NULL DEFAULT 'regular',
  ADD COLUMN IF NOT EXISTS credit_limit DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS debt_i_owe DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS debt_owed_to_me DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS debt_total DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS show_debt_in_expenses BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS goal_amount DOUBLE PRECISION;

-- user_settings: currency format pattern id + start screen tab index
ALTER TABLE user_settings
  ADD COLUMN IF NOT EXISTS currency_format_id TEXT NOT NULL DEFAULT 'default',
  ADD COLUMN IF NOT EXISTS start_screen_index INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN wallets.account_type IS 'regular, debt, savings';
COMMENT ON COLUMN user_settings.currency_format_id IS 'Key for currency display format (thousand/decimal/symbol position)';
COMMENT ON COLUMN user_settings.start_screen_index IS 'Tab index to open on app launch: 0=Accounts,1=Categories,2=Operations,3=Budget,4=Overview';
