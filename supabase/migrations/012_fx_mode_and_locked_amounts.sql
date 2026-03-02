-- FX display mode and locked conversion metadata.
-- This enables:
-- 1) Accounting mode (historical locked values)
-- 2) Live FX mode (revalued by today's rate)

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS fx_display_mode TEXT NOT NULL DEFAULT 'accounting'
  CHECK (fx_display_mode IN ('accounting', 'live'));

ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS original_amount NUMERIC(15,2),
  ADD COLUMN IF NOT EXISTS original_currency TEXT,
  ADD COLUMN IF NOT EXISTS fx_rate_to_base NUMERIC(18,8),
  ADD COLUMN IF NOT EXISTS fx_base_currency TEXT,
  ADD COLUMN IF NOT EXISTS base_amount_locked NUMERIC(15,2),
  ADD COLUMN IF NOT EXISTS fx_rate_date TIMESTAMPTZ;

-- Backfill legacy rows where original_* data is missing.
UPDATE transactions
SET
  original_amount = COALESCE(original_amount, amount),
  original_currency = COALESCE(original_currency, currency),
  fx_rate_to_base = COALESCE(fx_rate_to_base, 1),
  fx_base_currency = COALESCE(fx_base_currency, currency),
  base_amount_locked = COALESCE(base_amount_locked, amount),
  fx_rate_date = COALESCE(fx_rate_date, created_at)
WHERE
  original_amount IS NULL
  OR original_currency IS NULL
  OR fx_rate_to_base IS NULL
  OR fx_base_currency IS NULL
  OR base_amount_locked IS NULL
  OR fx_rate_date IS NULL;

