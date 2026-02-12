-- Goals and reusable category budget limits

CREATE TABLE IF NOT EXISTS goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '🎯',
  target_amount NUMERIC(15,2) NOT NULL CHECK (target_amount > 0),
  current_amount NUMERIC(15,2) NOT NULL DEFAULT 0,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_goals_user ON goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_group ON goals(group_id);

CREATE TABLE IF NOT EXISTS budget_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_budget_limits_user ON budget_limits(user_id);
CREATE INDEX IF NOT EXISTS idx_budget_limits_category ON budget_limits(category_id);

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_limits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS goals_select ON goals;
CREATE POLICY goals_select ON goals
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS goals_insert ON goals;
CREATE POLICY goals_insert ON goals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS goals_update ON goals;
CREATE POLICY goals_update ON goals
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS goals_delete ON goals;
CREATE POLICY goals_delete ON goals
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS budget_limits_select ON budget_limits;
CREATE POLICY budget_limits_select ON budget_limits
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS budget_limits_insert ON budget_limits;
CREATE POLICY budget_limits_insert ON budget_limits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS budget_limits_update ON budget_limits;
CREATE POLICY budget_limits_update ON budget_limits
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS budget_limits_delete ON budget_limits;
CREATE POLICY budget_limits_delete ON budget_limits
  FOR DELETE USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION update_budget_limits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_budget_limits_updated_at ON budget_limits;
CREATE TRIGGER trg_budget_limits_updated_at
BEFORE UPDATE ON budget_limits
FOR EACH ROW EXECUTE FUNCTION update_budget_limits_updated_at();
