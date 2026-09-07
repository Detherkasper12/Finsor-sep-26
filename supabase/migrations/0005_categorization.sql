-- Categorization rules (synced from client, used for local + learned rules)
CREATE TABLE IF NOT EXISTS categorization_rules (
  id TEXT NOT NULL,
  user_id UUID NOT NULL DEFAULT auth.uid(),
  pattern TEXT NOT NULL,
  normalized_pattern TEXT NOT NULL,
  category_id TEXT NOT NULL,
  transaction_type TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'user_learned',
  priority INTEGER NOT NULL DEFAULT 100,
  hit_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT,
  PRIMARY KEY (id, user_id)
);

ALTER TABLE categorization_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY categorization_rules_select ON categorization_rules FOR SELECT USING (user_id = auth.uid());
CREATE POLICY categorization_rules_insert ON categorization_rules FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY categorization_rules_update ON categorization_rules FOR UPDATE USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_categorization_rules_user_updated
  ON categorization_rules (user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_categorization_rules_user_deleted
  ON categorization_rules (user_id, deleted_at);

CREATE TRIGGER trg_categorization_rules_updated_at
  BEFORE UPDATE ON categorization_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- AI categorization usage for rate limiting (free tier: 20/month, premium: unlimited)
CREATE TABLE IF NOT EXISTS ai_categorization_usage (
  user_id UUID NOT NULL,
  period_start DATE NOT NULL,
  calls_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, period_start)
);

ALTER TABLE ai_categorization_usage ENABLE ROW LEVEL SECURITY;
-- Only service role can read/write (Edge Function uses service role for rate limit check)
CREATE POLICY ai_usage_select ON ai_categorization_usage FOR SELECT USING (user_id = auth.uid());
CREATE POLICY ai_usage_insert ON ai_categorization_usage FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY ai_usage_update ON ai_categorization_usage FOR UPDATE USING (user_id = auth.uid());
