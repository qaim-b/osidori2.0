-- Profile preferences + transaction category snapshot support

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS role TEXT,
  ADD COLUMN IF NOT EXISTS preferred_currency TEXT NOT NULL DEFAULT 'JPY';

ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS category_name_snapshot TEXT,
  ADD COLUMN IF NOT EXISTS category_emoji_snapshot TEXT,
  ADD COLUMN IF NOT EXISTS category_display_number_snapshot INTEGER;

-- Backfill snapshots from currently visible categories where possible.
UPDATE transactions t
SET
  category_name_snapshot = c.name,
  category_emoji_snapshot = c.emoji,
  category_display_number_snapshot = c.display_number
FROM categories c
WHERE t.category_id = c.id
  AND (t.category_name_snapshot IS NULL
    OR t.category_emoji_snapshot IS NULL
    OR t.category_display_number_snapshot IS NULL);
