-- FX rates table for live revaluation mode.
-- Stores daily rates by base/quote currency pair.

CREATE TABLE IF NOT EXISTS fx_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rate_date DATE NOT NULL,
  base_currency TEXT NOT NULL CHECK (char_length(base_currency) = 3),
  quote_currency TEXT NOT NULL CHECK (char_length(quote_currency) = 3),
  rate NUMERIC(18,8) NOT NULL CHECK (rate > 0),
  source TEXT NOT NULL DEFAULT 'provider',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(rate_date, base_currency, quote_currency, source)
);

CREATE INDEX IF NOT EXISTS idx_fx_rates_pair_date
  ON fx_rates(base_currency, quote_currency, rate_date DESC);

ALTER TABLE fx_rates ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read FX rates.
CREATE POLICY fx_rates_select ON fx_rates
  FOR SELECT USING (auth.role() = 'authenticated');
