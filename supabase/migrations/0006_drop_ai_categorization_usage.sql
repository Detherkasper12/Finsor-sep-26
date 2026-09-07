-- Remove AI categorization usage table (AI categorization removed from app)
DROP POLICY IF EXISTS ai_usage_select ON ai_categorization_usage;
DROP POLICY IF EXISTS ai_usage_insert ON ai_categorization_usage;
DROP POLICY IF EXISTS ai_usage_update ON ai_categorization_usage;
DROP TABLE IF EXISTS ai_categorization_usage;
