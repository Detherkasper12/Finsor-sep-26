-- Finsor Cloud Sync Schema
-- All tables include: id, user_id, created_at, updated_at, deleted_at, device_id

CREATE TABLE IF NOT EXISTS wallets (
  id TEXT NOT NULL,
  user_id UUID NOT NULL DEFAULT auth.uid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- cash, bank, card, savings, investment, crypto, other
  currency TEXT NOT NULL DEFAULT 'USD',
  initial_balance DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  current_balance DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  description TEXT,
  color TEXT,
  icon_name TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  include_in_total BOOLEAN NOT NULL DEFAULT TRUE,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT,
  PRIMARY KEY (id, user_id)
);

CREATE TABLE IF NOT EXISTS categories (
  id TEXT NOT NULL,
  user_id UUID NOT NULL DEFAULT auth.uid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- income, expense, transfer
  parent_id TEXT,
  description TEXT,
  icon_name TEXT NOT NULL,
  color TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT,
  PRIMARY KEY (id, user_id)
);

CREATE TABLE IF NOT EXISTS transactions (
  id TEXT NOT NULL,
  user_id UUID NOT NULL DEFAULT auth.uid(),
  amount DOUBLE PRECISION NOT NULL,
  type TEXT NOT NULL, -- income, expense, transfer
  category_id TEXT NOT NULL,
  wallet_id TEXT NOT NULL,
  to_wallet_id TEXT,
  description TEXT,
  date TIMESTAMPTZ NOT NULL DEFAULT now(),
  recurring_id TEXT,
  goal_id TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT,
  PRIMARY KEY (id, user_id)
);

CREATE TABLE IF NOT EXISTS budgets (
  id TEXT NOT NULL,
  user_id UUID NOT NULL DEFAULT auth.uid(),
  name TEXT NOT NULL,
  category_id TEXT,
  wallet_id TEXT,
  amount DOUBLE PRECISION NOT NULL,
  spent DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  period TEXT NOT NULL, -- weekly, monthly, quarterly, yearly, custom
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  notify_when_exceeded BOOLEAN NOT NULL DEFAULT FALSE,
  warning_threshold DOUBLE PRECISION NOT NULL DEFAULT 80.0,
  description TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT,
  PRIMARY KEY (id, user_id)
);

CREATE TABLE IF NOT EXISTS recurring_transactions (
  id TEXT NOT NULL,
  user_id UUID NOT NULL DEFAULT auth.uid(),
  amount DOUBLE PRECISION NOT NULL,
  type TEXT NOT NULL,
  category_id TEXT NOT NULL,
  wallet_id TEXT NOT NULL,
  to_wallet_id TEXT,
  description TEXT,
  frequency TEXT NOT NULL, -- daily, weekly, monthly, yearly
  interval_count INTEGER NOT NULL DEFAULT 1,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  next_run_date TIMESTAMPTZ NOT NULL,
  last_generated_date TIMESTAMPTZ,
  is_paused BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT,
  PRIMARY KEY (id, user_id)
);

CREATE TABLE IF NOT EXISTS goals (
  id TEXT NOT NULL,
  user_id UUID NOT NULL DEFAULT auth.uid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- savings, debt
  target_amount DOUBLE PRECISION NOT NULL,
  current_amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  linked_wallet_id TEXT,
  debtor_name TEXT,
  due_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'active', -- active, completed, cancelled
  icon_name TEXT NOT NULL DEFAULT 'savings',
  color TEXT NOT NULL DEFAULT '#4CAF50',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT,
  PRIMARY KEY (id, user_id)
);

CREATE TABLE IF NOT EXISTS user_settings (
  id TEXT NOT NULL DEFAULT 'default',
  user_id UUID NOT NULL DEFAULT auth.uid(),
  theme_mode TEXT NOT NULL DEFAULT 'system',
  primary_currency JSONB NOT NULL DEFAULT '{"code":"USD","name":"US Dollar","symbol":"$","decimalPlaces":2,"exchangeRate":1.0}',
  locale TEXT NOT NULL DEFAULT 'en',
  require_pin_for_access BOOLEAN NOT NULL DEFAULT FALSE,
  use_biometrics BOOLEAN NOT NULL DEFAULT FALSE,
  show_balance_on_home BOOLEAN NOT NULL DEFAULT TRUE,
  enable_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  enable_budget_alerts BOOLEAN NOT NULL DEFAULT TRUE,
  enable_cloud_sync BOOLEAN NOT NULL DEFAULT FALSE,
  include_transfer_in_stats BOOLEAN NOT NULL DEFAULT TRUE,
  week_start_day INTEGER NOT NULL DEFAULT 1,
  start_of_month_day INTEGER NOT NULL DEFAULT 1,
  auto_lock_timeout INTEGER NOT NULL DEFAULT 0,
  default_wallet_id TEXT NOT NULL DEFAULT '',
  last_backup_date TIMESTAMPTZ,
  is_premium_user BOOLEAN NOT NULL DEFAULT FALSE,
  premium_expiry_date TIMESTAMPTZ,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT,
  PRIMARY KEY (id, user_id)
);
