-- Partner account visibility policy
-- Grouped users can see each other's accounts (including older rows without group_id)

DROP POLICY IF EXISTS accounts_select ON accounts;
CREATE POLICY accounts_select ON accounts
  FOR SELECT USING (
    auth.uid() = owner_user_id
    OR (
      group_id IS NOT NULL
      AND group_id IN (
        SELECT group_id FROM group_members WHERE user_id = auth.uid()
      )
    )
    OR owner_user_id IN (
      SELECT gm2.user_id
      FROM group_members gm1
      JOIN group_members gm2 ON gm1.group_id = gm2.group_id
      WHERE gm1.user_id = auth.uid()
    )
  );
