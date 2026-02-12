-- ============================================================
-- Osidori 2.0 — Initial Database Schema
-- Supabase (PostgreSQL) migration
-- ============================================================

-- 1. Profiles (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create profile on signup via trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Groups (couples / small groups)
CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  member_ids UUID[] NOT NULL DEFAULT '{}',
  created_by_user_id UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Group Members junction table (for RLS policies)
CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

CREATE INDEX idx_group_members_user ON group_members(user_id);
CREATE INDEX idx_group_members_group ON group_members(group_id);

-- 4. Accounts (manual conceptual accounts)
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('cash', 'bank', 'credit', 'wallet')),
  owner_scope TEXT NOT NULL CHECK (owner_scope IN ('personal', 'shared')),
  owner_user_id UUID NOT NULL REFERENCES profiles(id),
  group_id UUID REFERENCES groups(id),
  currency TEXT NOT NULL DEFAULT 'JPY',
  initial_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_accounts_owner ON accounts(owner_user_id);
CREATE INDEX idx_accounts_group ON accounts(group_id);

-- 5. Categories (per-user, seeded from defaults)
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  display_number INTEGER NOT NULL DEFAULT 0,
  name TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '📋',
  type TEXT NOT NULL CHECK (type IN ('expense', 'income')),
  parent_id UUID REFERENCES categories(id),
  parent_key TEXT,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_user ON categories(user_id);
CREATE INDEX idx_categories_type ON categories(user_id, type);

-- 6. Transactions (THE core table)
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('expense', 'income', 'transfer')),
  amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'JPY',
  date TIMESTAMPTZ NOT NULL,
  category_id UUID NOT NULL REFERENCES categories(id),
  from_account_id UUID NOT NULL REFERENCES accounts(id),
  to_account_id UUID REFERENCES accounts(id),
  note TEXT,
  visibility TEXT NOT NULL CHECK (visibility IN ('personal', 'shared')),
  owner_user_id UUID NOT NULL REFERENCES profiles(id),
  group_id UUID REFERENCES groups(id),
  source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'sync')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Performance indexes for common queries
CREATE INDEX idx_txn_owner_date ON transactions(owner_user_id, date DESC);
CREATE INDEX idx_txn_group_vis ON transactions(group_id, visibility, date DESC);
CREATE INDEX idx_txn_category ON transactions(category_id);
CREATE INDEX idx_txn_date ON transactions(date DESC);
CREATE INDEX idx_txn_type_date ON transactions(type, date DESC);

-- ============================================================
-- Row Level Security (RLS) — critical for multi-user safety
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only read/update their own profile
CREATE POLICY profiles_select ON profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY profiles_update ON profiles
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY profiles_insert ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Groups: members can read their groups
CREATE POLICY groups_select ON groups
  FOR SELECT USING (
    auth.uid() = ANY(member_ids)
  );
CREATE POLICY groups_insert ON groups
  FOR INSERT WITH CHECK (auth.uid() = created_by_user_id);
CREATE POLICY groups_update ON groups
  FOR UPDATE USING (auth.uid() = ANY(member_ids));

-- Group Members: can see own memberships
CREATE POLICY gm_select ON group_members
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY gm_insert ON group_members
  FOR INSERT WITH CHECK (TRUE); -- controlled by app logic

-- Accounts: own accounts + shared group accounts
CREATE POLICY accounts_select ON accounts
  FOR SELECT USING (
    auth.uid() = owner_user_id
    OR (owner_scope = 'shared' AND group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid()
    ))
  );
CREATE POLICY accounts_insert ON accounts
  FOR INSERT WITH CHECK (auth.uid() = owner_user_id);
CREATE POLICY accounts_update ON accounts
  FOR UPDATE USING (auth.uid() = owner_user_id);
CREATE POLICY accounts_delete ON accounts
  FOR DELETE USING (auth.uid() = owner_user_id);

-- Categories: users only see their own
CREATE POLICY categories_select ON categories
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY categories_insert ON categories
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY categories_update ON categories
  FOR UPDATE USING (auth.uid() = user_id);

-- Transactions: own + shared group transactions
CREATE POLICY txn_select ON transactions
  FOR SELECT USING (
    auth.uid() = owner_user_id
    OR (visibility = 'shared' AND group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid()
    ))
  );
CREATE POLICY txn_insert ON transactions
  FOR INSERT WITH CHECK (auth.uid() = owner_user_id);
CREATE POLICY txn_update ON transactions
  FOR UPDATE USING (auth.uid() = owner_user_id);
CREATE POLICY txn_delete ON transactions
  FOR DELETE USING (auth.uid() = owner_user_id);
