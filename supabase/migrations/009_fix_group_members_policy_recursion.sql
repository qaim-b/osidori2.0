-- Fix infinite recursion in group_members SELECT policy.
-- Previous policy queried group_members from within its own USING clause.

-- 1) Safe group_members read policy (no self-reference).
DROP POLICY IF EXISTS gm_select ON group_members;
CREATE POLICY gm_select ON group_members
  FOR SELECT USING (
    auth.uid() = user_id
    OR group_id IN (
      SELECT g.id
      FROM groups g
      WHERE auth.uid() = ANY(g.member_ids)
    )
  );

-- 2) Keep partner profile visibility via groups.member_ids (no group_members join).
DROP POLICY IF EXISTS profiles_select ON profiles;
CREATE POLICY profiles_select ON profiles
  FOR SELECT USING (
    auth.uid() = id
    OR EXISTS (
      SELECT 1
      FROM groups g
      WHERE auth.uid() = ANY(g.member_ids)
        AND profiles.id = ANY(g.member_ids)
    )
  );
