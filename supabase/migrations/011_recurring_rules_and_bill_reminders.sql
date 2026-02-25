-- Recurring transactions + bill reminders

-- 1) Extend transaction source for generated recurring rows.
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_source_check;
ALTER TABLE transactions
  ADD CONSTRAINT transactions_source_check
  CHECK (source IN ('manual', 'sync', 'recurring'));

-- 2) Link generated rows to recurring rule + occurrence date for dedupe.
ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS recurring_rule_id UUID,
  ADD COLUMN IF NOT EXISTS recurrence_occurrence_date DATE;

CREATE INDEX IF NOT EXISTS idx_txn_recurring_rule ON transactions(recurring_rule_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_txn_rule_occurrence
  ON transactions(recurring_rule_id, recurrence_occurrence_date)
  WHERE recurring_rule_id IS NOT NULL AND recurrence_occurrence_date IS NOT NULL;

-- 3) Recurring transaction rules
CREATE TABLE IF NOT EXISTS recurring_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('expense', 'income', 'transfer')),
  amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'JPY',
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  from_account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
  to_account_id UUID REFERENCES accounts(id) ON DELETE RESTRICT,
  note TEXT,
  visibility TEXT NOT NULL CHECK (visibility IN ('personal', 'shared')),
  frequency TEXT NOT NULL CHECK (frequency IN ('weekly', 'monthly', 'yearly')),
  interval_count INTEGER NOT NULL DEFAULT 1 CHECK (interval_count >= 1 AND interval_count <= 60),
  start_date DATE NOT NULL,
  end_date DATE,
  last_generated_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_recurring_rules_user ON recurring_rules(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_rules_group ON recurring_rules(group_id);
CREATE INDEX IF NOT EXISTS idx_recurring_rules_active ON recurring_rules(is_active, start_date);

-- 4) Bill reminders
CREATE TABLE IF NOT EXISTS bill_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
  recurring_rule_id UUID REFERENCES recurring_rules(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  amount NUMERIC(15,2) CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'JPY',
  due_frequency TEXT NOT NULL CHECK (due_frequency IN ('monthly', 'yearly')),
  due_interval_count INTEGER NOT NULL DEFAULT 1 CHECK (due_interval_count >= 1 AND due_interval_count <= 60),
  anchor_date DATE NOT NULL,
  reminder_days_before INTEGER[] NOT NULL DEFAULT ARRAY[7,2,0],
  send_overdue BOOLEAN NOT NULL DEFAULT TRUE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bill_reminders_user ON bill_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_bill_reminders_group ON bill_reminders(group_id);
CREATE INDEX IF NOT EXISTS idx_bill_reminders_active ON bill_reminders(is_active, anchor_date);

-- 5) Updated-at trigger helper
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_recurring_rules_updated_at ON recurring_rules;
CREATE TRIGGER trg_recurring_rules_updated_at
BEFORE UPDATE ON recurring_rules
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_bill_reminders_updated_at ON bill_reminders;
CREATE TRIGGER trg_bill_reminders_updated_at
BEFORE UPDATE ON bill_reminders
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- 6) RLS
ALTER TABLE recurring_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS recurring_rules_select ON recurring_rules;
CREATE POLICY recurring_rules_select ON recurring_rules
  FOR SELECT USING (
    auth.uid() = user_id
    OR (visibility = 'shared' AND group_id IN (
      SELECT g.id FROM groups g WHERE auth.uid() = ANY(g.member_ids)
    ))
  );

DROP POLICY IF EXISTS recurring_rules_insert ON recurring_rules;
CREATE POLICY recurring_rules_insert ON recurring_rules
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS recurring_rules_update ON recurring_rules;
CREATE POLICY recurring_rules_update ON recurring_rules
  FOR UPDATE USING (
    auth.uid() = user_id
    OR (visibility = 'shared' AND group_id IN (
      SELECT g.id FROM groups g WHERE auth.uid() = ANY(g.member_ids)
    ))
  );

DROP POLICY IF EXISTS recurring_rules_delete ON recurring_rules;
CREATE POLICY recurring_rules_delete ON recurring_rules
  FOR DELETE USING (
    auth.uid() = user_id
    OR (visibility = 'shared' AND group_id IN (
      SELECT g.id FROM groups g WHERE auth.uid() = ANY(g.member_ids)
    ))
  );

DROP POLICY IF EXISTS bill_reminders_select ON bill_reminders;
CREATE POLICY bill_reminders_select ON bill_reminders
  FOR SELECT USING (
    auth.uid() = user_id
    OR (group_id IN (
      SELECT g.id FROM groups g WHERE auth.uid() = ANY(g.member_ids)
    ))
  );

DROP POLICY IF EXISTS bill_reminders_insert ON bill_reminders;
CREATE POLICY bill_reminders_insert ON bill_reminders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS bill_reminders_update ON bill_reminders;
CREATE POLICY bill_reminders_update ON bill_reminders
  FOR UPDATE USING (
    auth.uid() = user_id
    OR (group_id IN (
      SELECT g.id FROM groups g WHERE auth.uid() = ANY(g.member_ids)
    ))
  );

DROP POLICY IF EXISTS bill_reminders_delete ON bill_reminders;
CREATE POLICY bill_reminders_delete ON bill_reminders
  FOR DELETE USING (
    auth.uid() = user_id
    OR (group_id IN (
      SELECT g.id FROM groups g WHERE auth.uid() = ANY(g.member_ids)
    ))
  );

