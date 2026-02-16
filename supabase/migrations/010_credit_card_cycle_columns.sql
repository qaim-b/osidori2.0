-- Credit card billing cycle settings on accounts
-- Helps separate statement cycle expenses from payment date.

ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS credit_cycle_start_day INTEGER,
  ADD COLUMN IF NOT EXISTS credit_payment_day INTEGER;

ALTER TABLE accounts
  DROP CONSTRAINT IF EXISTS accounts_credit_cycle_start_day_check;
ALTER TABLE accounts
  ADD CONSTRAINT accounts_credit_cycle_start_day_check
  CHECK (
    credit_cycle_start_day IS NULL
    OR (credit_cycle_start_day >= 1 AND credit_cycle_start_day <= 31)
  );

ALTER TABLE accounts
  DROP CONSTRAINT IF EXISTS accounts_credit_payment_day_check;
ALTER TABLE accounts
  ADD CONSTRAINT accounts_credit_payment_day_check
  CHECK (
    credit_payment_day IS NULL
    OR (credit_payment_day >= 1 AND credit_payment_day <= 31)
  );
