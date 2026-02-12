-- Allow grouped partners to edit/delete each other's transactions in shared group context

DROP POLICY IF EXISTS txn_update ON transactions;
CREATE POLICY txn_update ON transactions
  FOR UPDATE
  USING (
    auth.uid() = owner_user_id
    OR (
      group_id IS NOT NULL
      AND group_id IN (
        SELECT group_id FROM group_members WHERE user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    auth.uid() = owner_user_id
    OR (
      group_id IS NOT NULL
      AND group_id IN (
        SELECT group_id FROM group_members WHERE user_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS txn_delete ON transactions;
CREATE POLICY txn_delete ON transactions
  FOR DELETE USING (
    auth.uid() = owner_user_id
    OR (
      group_id IS NOT NULL
      AND group_id IN (
        SELECT group_id FROM group_members WHERE user_id = auth.uid()
      )
    )
  );
