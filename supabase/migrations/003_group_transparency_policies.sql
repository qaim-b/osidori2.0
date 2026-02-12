-- Group transparency policy update
-- Allows all members of the same group to view group-linked rows,
-- including legacy rows that were marked personal but have group_id.

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
  );

DROP POLICY IF EXISTS txn_select ON transactions;
CREATE POLICY txn_select ON transactions
  FOR SELECT USING (
    auth.uid() = owner_user_id
    OR (
      group_id IS NOT NULL
      AND group_id IN (
        SELECT group_id FROM group_members WHERE user_id = auth.uid()
      )
    )
  );
