-- Enable category deletion by owner.
-- Without this policy, category deletes can silently fail under RLS.

DROP POLICY IF EXISTS categories_delete ON categories;
CREATE POLICY categories_delete ON categories
  FOR DELETE USING (auth.uid() = user_id);

