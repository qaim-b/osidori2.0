-- Fix partner profile visibility for grouped users.
-- Root cause: profiles policy joined group_members twice, but group_members
-- select policy only exposed the caller's own membership rows.

-- 1) Allow a user to read all members of groups they belong to.
DROP POLICY IF EXISTS gm_select ON group_members;
CREATE POLICY gm_select ON group_members
  FOR SELECT USING (
    group_id IN (
      SELECT group_id
      FROM group_members
      WHERE user_id = auth.uid()
    )
  );

-- 2) Allow profile reads for everyone inside the same group.
-- Using groups.member_ids avoids the self-join visibility trap.
DROP POLICY IF EXISTS profiles_select ON profiles;
CREATE POLICY profiles_select ON profiles
  FOR SELECT USING (
    auth.uid() = id
    OR id IN (
      SELECT UNNEST(member_ids)
      FROM groups
      WHERE auth.uid() = ANY(member_ids)
    )
  );
