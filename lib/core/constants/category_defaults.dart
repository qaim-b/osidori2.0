/// All default categories — matches the life planning sheet EXACTLY.
/// Numbering preserved. Parent groups map to sub-categories.
/// These are seeded on first launch and are editable later.
class CategoryDefaults {
  CategoryDefaults._();

  /// Parent category groups (for grouping in reports & UI)
  static const List<ParentCategoryDef> parentCategories = [
    ParentCategoryDef(key: 'housing', name: 'Housing', emoji: '🏠', sortOrder: 0),
    ParentCategoryDef(key: 'communication', name: 'Communication', emoji: '🛜', sortOrder: 1),
    ParentCategoryDef(key: 'subscription', name: 'Subscription', emoji: '📅', sortOrder: 2),
    ParentCategoryDef(key: 'taxes_social', name: 'Taxes & Social Security', emoji: '💲', sortOrder: 3),
    ParentCategoryDef(key: 'utility', name: 'Utility', emoji: '🔥', sortOrder: 4),
    ParentCategoryDef(key: 'food', name: 'Food', emoji: '🥘', sortOrder: 5),
    ParentCategoryDef(key: 'household', name: 'Household Goods', emoji: '🛒', sortOrder: 6),
    ParentCategoryDef(key: 'transportation', name: 'Transportation', emoji: '🚆', sortOrder: 7),
    ParentCategoryDef(key: 'socializing', name: 'Socializing', emoji: '🤝', sortOrder: 8),
    ParentCategoryDef(key: 'hobbies', name: 'Hobbies/Misc.', emoji: '🎮', sortOrder: 9),
    ParentCategoryDef(key: 'leisure', name: 'Leisure', emoji: '🎉', sortOrder: 10),
    ParentCategoryDef(key: 'homecoming', name: 'Homecoming', emoji: '🚗', sortOrder: 11),
    ParentCategoryDef(key: 'education', name: 'Education', emoji: '📚', sortOrder: 12),
    ParentCategoryDef(key: 'beauty', name: 'Beauty', emoji: '💆‍♀️', sortOrder: 13),
    ParentCategoryDef(key: 'medical', name: 'Medical Care', emoji: '🏥', sortOrder: 14),
    ParentCategoryDef(key: 'deens', name: 'Deens', emoji: '☪️', sortOrder: 15),
    ParentCategoryDef(key: 'others', name: 'Others', emoji: '🌱', sortOrder: 16),
    ParentCategoryDef(key: 'investment', name: 'Investment', emoji: '💹', sortOrder: 17),
    ParentCategoryDef(key: 'sadaqah', name: 'Sadaqah', emoji: '☾⋆', sortOrder: 18),
  ];

  /// Sub-categories with their EXACT numbering from the planning sheet.
  /// parentKey links to the parent category above.
  static const List<SubCategoryDef> expenseCategories = [
    // Housing
    SubCategoryDef(number: 1,  key: 'housing',               name: 'Housing',                emoji: '🏠', parentKey: 'housing'),

    // Communication
    SubCategoryDef(number: 2,  key: 'wifi',                   name: 'Wi-Fi',                  emoji: '🌐', parentKey: 'communication'),
    SubCategoryDef(number: 3,  key: 'phone',                  name: 'Phone',                  emoji: '📱', parentKey: 'communication'),

    // Subscription
    SubCategoryDef(number: 4,  key: 'ai',                     name: 'AI',                     emoji: '🤖', parentKey: 'subscription'),
    SubCategoryDef(number: 5,  key: 'spotify_canva',          name: 'Spotify/Canva',          emoji: '🎧', parentKey: 'subscription'),

    // Taxes & Social Security
    SubCategoryDef(number: 6,  key: 'taxes',                  name: 'Taxes',                  emoji: '🧾', parentKey: 'taxes_social'),
    SubCategoryDef(number: 7,  key: 'social_insurance',       name: 'Social Insurance',       emoji: '🛡️', parentKey: 'taxes_social'),
    SubCategoryDef(number: 8,  key: 'pension',                name: 'Pension',                emoji: '💰', parentKey: 'taxes_social'),
    SubCategoryDef(number: 9,  key: 'insurance',              name: 'Insurance',              emoji: '🛡️', parentKey: 'taxes_social'),

    // Others (scholarship is income-like but tracked as expense category per sheet)
    SubCategoryDef(number: 9,  key: 'scholarship',            name: 'Scholarship',            emoji: '📜', parentKey: 'others'),

    // Utility
    SubCategoryDef(number: 10, key: 'water_bill',             name: 'Water Bill',             emoji: '🚰', parentKey: 'utility'),
    SubCategoryDef(number: 11, key: 'utility_bill',           name: 'Utility Bill',           emoji: '💡', parentKey: 'utility'),

    // Food
    SubCategoryDef(number: 12, key: 'home_cooking',           name: 'Home Cooking',           emoji: '🍳', parentKey: 'food'),
    SubCategoryDef(number: 13, key: 'snacking',               name: 'Snacking',               emoji: '🥨', parentKey: 'food'),

    // Household Goods
    SubCategoryDef(number: 14, key: 'clothing',               name: 'Clothing',               emoji: '👕', parentKey: 'household'),
    SubCategoryDef(number: 15, key: 'household_goods',        name: 'Household Goods',        emoji: '🛒', parentKey: 'household'),
    SubCategoryDef(number: 16, key: 'gadgets',                name: 'Gadgets',                emoji: '📷', parentKey: 'household'),

    // Transportation
    SubCategoryDef(number: 17, key: 'public_transport',       name: 'Public Transport',       emoji: '🚋', parentKey: 'transportation'),

    // Socializing
    SubCategoryDef(number: 18, key: 'dating',                 name: 'Dating',                 emoji: '💑', parentKey: 'socializing'),
    SubCategoryDef(number: 19, key: 'dining_out',             name: 'Dining Out',             emoji: '🍴', parentKey: 'socializing'),
    SubCategoryDef(number: 20, key: 'social_mami',            name: 'Social Mami',            emoji: '👩🏻', parentKey: 'socializing'),
    SubCategoryDef(number: 21, key: 'social_qaim',            name: 'Social Qaim',            emoji: '👦🏽', parentKey: 'socializing'),

    // Hobbies/Misc
    SubCategoryDef(number: 22, key: 'hobby_mami',             name: 'Hobby Mami',             emoji: '🎮', parentKey: 'hobbies'),
    SubCategoryDef(number: 23, key: 'hobby_qaim',             name: 'Hobby Qaim',             emoji: '🎮', parentKey: 'hobbies'),

    // Leisure
    SubCategoryDef(number: 24, key: 'travel',                 name: 'Travel',                 emoji: '✈️', parentKey: 'leisure'),

    // Homecoming
    SubCategoryDef(number: 25, key: 'anjyo',                  name: 'Anjyo',                  emoji: '🇯🇵', parentKey: 'homecoming'),
    SubCategoryDef(number: 26, key: 'malaysia',               name: 'Malaysia',               emoji: '🇲🇾', parentKey: 'homecoming'),

    // Leisure (continued)
    SubCategoryDef(number: 27, key: 'honeymoon',              name: 'Honeymoon',              emoji: '🍯', parentKey: 'leisure'),

    // Education
    SubCategoryDef(number: 28, key: 'books',                  name: 'Books',                  emoji: '📖', parentKey: 'education'),
    SubCategoryDef(number: 29, key: 'other_education',        name: 'Other Education',        emoji: '📖', parentKey: 'education'),

    // Beauty
    SubCategoryDef(number: 30, key: 'haircut',                name: 'Haircut',                emoji: '💇‍♂️', parentKey: 'beauty'),

    // Medical Care
    SubCategoryDef(number: 31, key: 'hospital',               name: 'Hospital',               emoji: '🏥', parentKey: 'medical'),
    SubCategoryDef(number: 32, key: 'meds',                   name: 'Meds',                   emoji: '💊', parentKey: 'medical'),

    // Deens
    SubCategoryDef(number: 33, key: 'charity',                name: 'Charity',                emoji: '🤲', parentKey: 'deens'),

    // Others
    SubCategoryDef(number: 34, key: 'gifts',                  name: 'Gifts',                  emoji: '🎁', parentKey: 'others'),
    SubCategoryDef(number: 35, key: 'furniture_appliances',   name: 'Furniture/Appliances',   emoji: '📠', parentKey: 'others'),
    SubCategoryDef(number: 36, key: 'moving',                 name: 'Moving',                 emoji: '🚚', parentKey: 'others'),
    SubCategoryDef(number: 37, key: 'miscellaneous',          name: 'Miscellaneous',          emoji: '🔧', parentKey: 'others'),

    // Investment
    SubCategoryDef(number: 38, key: 'qaim_account',           name: 'Qaim Account',           emoji: '👦🏾', parentKey: 'investment'),
    SubCategoryDef(number: 39, key: 'mami_account',           name: 'Mami Account',           emoji: '👧🏻', parentKey: 'investment'),

    // Deens (continued)
    SubCategoryDef(number: 40, key: 'hari_raya_angpao',       name: 'Hari Raya Angpao',       emoji: '🪅', parentKey: 'deens'),

    // Sadaqah
    SubCategoryDef(number: 41, key: 'qaim_sadaqah',           name: 'Qaim Sadaqah',           emoji: '👦🏾', parentKey: 'sadaqah'),
    SubCategoryDef(number: 42, key: 'mami_family_sadaqah',    name: 'Mami Family Sadaqah',    emoji: '👧🏻', parentKey: 'sadaqah'),
    SubCategoryDef(number: 43, key: 'mami_aunty_uncle_sadaqah', name: 'Mami Aunty & Uncle Sadaqah', emoji: '👵👴', parentKey: 'sadaqah'),
  ];

  /// Income categories — simpler, can be expanded later.
  static const List<SubCategoryDef> incomeCategories = [
    SubCategoryDef(number: 1, key: 'salary_qaim',     name: 'Salary (Qaim)',     emoji: '💼', parentKey: 'income'),
    SubCategoryDef(number: 2, key: 'salary_mami',     name: 'Salary (Mami)',     emoji: '💼', parentKey: 'income'),
    SubCategoryDef(number: 3, key: 'scholarship_inc', name: 'Scholarship',       emoji: '📜', parentKey: 'income'),
    SubCategoryDef(number: 4, key: 'freelance',       name: 'Freelance',         emoji: '💻', parentKey: 'income'),
    SubCategoryDef(number: 5, key: 'gift_income',     name: 'Gift Money',        emoji: '🎁', parentKey: 'income'),
    SubCategoryDef(number: 6, key: 'investment_inc',  name: 'Investment Return', emoji: '📈', parentKey: 'income'),
    SubCategoryDef(number: 7, key: 'other_income',    name: 'Other Income',      emoji: '💰', parentKey: 'income'),
  ];
}

/// Parent category definition — used for grouping.
class ParentCategoryDef {
  final String key;
  final String name;
  final String emoji;
  final int sortOrder;

  const ParentCategoryDef({
    required this.key,
    required this.name,
    required this.emoji,
    required this.sortOrder,
  });
}

/// Sub-category definition — the actual categories users select.
class SubCategoryDef {
  final int number;
  final String key;
  final String name;
  final String emoji;
  final String parentKey;

  const SubCategoryDef({
    required this.number,
    required this.key,
    required this.name,
    required this.emoji,
    required this.parentKey,
  });
}
