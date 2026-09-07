# Supabase Migrations — Finsor

| Ref | Environment | Dashboard |
|-----|-------------|-----------|
| `qwzqpgtispittliygcan` | DEV | https://supabase.com/dashboard/project/qwzqpgtispittliygcan |
| `bnvcznkfmnyqzoniwioc` | PROD | https://supabase.com/dashboard/project/bnvcznkfmnyqzoniwioc |

## Migration files

| File | Purpose |
|------|---------|
| `0001_schema.sql` | 7 tables: wallets, categories, transactions, budgets, recurring_transactions, goals, user_settings |
| `0002_rls.sql` | RLS enabled + SELECT/INSERT/UPDATE policies (`user_id = auth.uid()`) |
| `0003_indexes.sql` | Sync `(user_id, updated_at)`, soft-delete `(user_id, deleted_at)`, transaction date indexes |
| `0004_triggers.sql` | Auto-update `updated_at` trigger on all tables |

---

## Prerequisites: `supabase/config.toml`

The Supabase CLI **requires** `supabase/config.toml` to identify the project root.
Without it, even if you `cd` to the project folder, the CLI falls back to your home directory (`C:\Users\abrek_otvjrzk`) and finds zero migration files.

This file was created at `supabase/config.toml`. If it ever goes missing, recreate it:

```toml
[api]
enabled = false

[db]
major_version = 15

[studio]
enabled = false
```

> Do NOT run `supabase init` if `supabase/migrations/` already has files — it may overwrite the folder.
> Just create `config.toml` manually.

---

## Full CLI workflow — DEV then PROD (Windows PowerShell)

### Phase 0 — Diagnose workdir problems

```powershell
# Print current directory — must be the Finsor project root
pwd
# Expected: C:\Users\abrek_otvjrzk\StudioProjects\Finsor

# If not, cd there first
cd C:\Users\abrek_otvjrzk\StudioProjects\Finsor

# Confirm config.toml exists (this is what tells the CLI "this is the project root")
Test-Path supabase\config.toml
# Expected: True
# If False → the CLI will use the WRONG workdir. See Prerequisites above.

# Confirm migration files exist
ls supabase\migrations\
# Expected: 0001_schema.sql  0002_rls.sql  0003_indexes.sql  0004_triggers.sql

# Check if any env vars are overriding the workdir
$env:SUPABASE_WORKDIR
$env:SUPABASE_CONFIG_DIR
# Expected: both should be blank (no output).
# If either prints a path, clear it for this session:
$env:SUPABASE_WORKDIR = $null
$env:SUPABASE_CONFIG_DIR = $null
```

### Phase 1 — Link to DEV and push

```powershell
# Link CLI to DEV project (stores ref in supabase/.temp/project-ref)
supabase link --project-ref qwzqpgtispittliygcan

# Verify the link file was written in the RIGHT place
dir -Force supabase\.temp\
# Expected: project-ref file should exist

Get-Content supabase\.temp\project-ref
# Expected: qwzqpgtispittliygcan
# If it says bnvcznkfmnyqzoniwioc → you linked PROD by mistake. Re-run link with DEV ref.

# Push with debug to see exactly what happens
supabase db push --debug
# Watch the output for:
#   "Using workdir C:\Users\abrek_otvjrzk\StudioProjects\Finsor"  ← CORRECT
#   "Applying migration 0001_schema.sql..."
#   "Applying migration 0002_rls.sql..."
#   "Applying migration 0003_indexes.sql..."
#   "Applying migration 0004_triggers.sql..."
#
# BAD signs:
#   "Using workdir C:\Users\abrek_otvjrzk"  ← config.toml missing or env var override
#   "Remote database is up to date"          ← see Troubleshooting section below
```

### Phase 2 — Verify DEV tables

Run this in Supabase SQL Editor (DEV dashboard: https://supabase.com/dashboard/project/qwzqpgtispittliygcan/sql):

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Expected 7 rows:

| table_name |
|---|
| budgets |
| categories |
| goals |
| recurring_transactions |
| transactions |
| user_settings |
| wallets |

### Phase 3 — Deploy to PROD (only after DEV verified)

```powershell
# Relink to PROD
supabase link --project-ref bnvcznkfmnyqzoniwioc

# Confirm
Get-Content supabase\.temp\project-ref
# Expected: bnvcznkfmnyqzoniwioc

# Push
supabase db push

# Relink back to DEV so daily work defaults to DEV
supabase link --project-ref qwzqpgtispittliygcan
```

---

## Safe diagnostic SQL (read-only, safe on any environment)

Run any of these in the Supabase SQL Editor to inspect state without modifying anything.

**Check 1: List public tables**

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

**Check 2: Does the migration tracking schema exist?**

```sql
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'supabase_migrations';
```

If this returns 0 rows → the CLI has never successfully pushed to this database.

**Check 3: List recorded migration versions**

```sql
SELECT version, name
FROM supabase_migrations.schema_migrations
ORDER BY version;
```

If Check 2 returned 0 rows, this query will error with "relation does not exist" — that's expected, it means no migrations have ever run.

**Check 4: Confirm RLS is enabled on all tables**

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

`rowsecurity` should be `true` for every table.

**Check 5: Count rows per table (useful post-sync)**

```sql
SELECT 'wallets' AS tbl, count(*) FROM wallets
UNION ALL SELECT 'categories', count(*) FROM categories
UNION ALL SELECT 'transactions', count(*) FROM transactions
UNION ALL SELECT 'budgets', count(*) FROM budgets
UNION ALL SELECT 'recurring_transactions', count(*) FROM recurring_transactions
UNION ALL SELECT 'goals', count(*) FROM goals
UNION ALL SELECT 'user_settings', count(*) FROM user_settings;
```

All checks are SELECT-only — they never modify data.

---

## Troubleshooting: workdir mismatch ("Using workdir C:\Users\abrek_otvjrzk")

**Root cause**: `supabase/config.toml` is missing from the project. The CLI walks up the directory tree looking for it. If it finds one in your home folder, or finds none at all, it uses the wrong root.

**Fix**:

```powershell
# 1. Confirm you are in the project root
cd C:\Users\abrek_otvjrzk\StudioProjects\Finsor

# 2. Confirm config.toml exists
Test-Path supabase\config.toml
# If False:
# DO NOT run supabase init (it may overwrite migrations/)
# Instead, create it manually — see Prerequisites section above.

# 3. Clear any env var overrides
$env:SUPABASE_WORKDIR = $null
$env:SUPABASE_CONFIG_DIR = $null

# 4. Check if a stale config.toml exists in your home directory
Test-Path $HOME\supabase\config.toml
# If True → delete it so the CLI doesn't pick it up:
# Remove-Item $HOME\supabase\config.toml

# 5. Retry
supabase db push --debug
# First line should now say: "Using workdir C:\Users\abrek_otvjrzk\StudioProjects\Finsor"
```

---

## Troubleshooting: "db push says up to date" but no tables visible

This means `supabase_migrations.schema_migrations` has version rows (CLI thinks migrations ran) but the actual CREATE TABLE statements failed or never executed.

### Step 1 — Diagnose (run in DEV SQL Editor)

```sql
-- Are there any public tables?
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- What does the migration tracker say?
SELECT version, name
FROM supabase_migrations.schema_migrations
ORDER BY version;
```

If the second query returns rows but the first is empty → tracker is out of sync.

### Step 2 — Fix DEV (safe reset, DEV only)

```sql
-- Drop any partial tables
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS budgets CASCADE;
DROP TABLE IF EXISTS recurring_transactions CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- Clear migration history so db push re-applies everything
DELETE FROM supabase_migrations.schema_migrations;
```

### Step 3 — Re-push

```powershell
supabase link --project-ref qwzqpgtispittliygcan
supabase db push --debug
```

---

## Troubleshooting: "relation supabase_migrations.schema_migrations does not exist"

This is **normal** on a fresh database. The CLI checks for this table to know which migrations already ran. If it doesn't exist, the CLI should create it automatically and then apply all migrations.

If `db push` errors out instead of creating it (rare edge case), bootstrap it manually in DEV SQL Editor:

```sql
-- DEV ONLY — create the migration tracking schema the CLI expects
CREATE SCHEMA IF NOT EXISTS supabase_migrations;
CREATE TABLE IF NOT EXISTS supabase_migrations.schema_migrations (
    version TEXT NOT NULL PRIMARY KEY,
    statements TEXT[],
    name TEXT
);
```

Then re-run `supabase db push` from PowerShell.

> **NEVER run bootstrap SQL on PROD without team lead approval.**

---

### SAFETY NOTE

> **NEVER run destructive SQL (DROP TABLE, DELETE FROM schema_migrations, CREATE SCHEMA) on PROD (`bnvcznkfmnyqzoniwioc`).**
> PROD may have real user data. All destructive commands in this README are explicitly marked DEV-only.
> If PROD has the same issue, contact the team lead first.

---

## Auth providers

Enable in Supabase Dashboard > Authentication > Providers:
- Apple
- Google
- Email (Magic Link / OTP)
