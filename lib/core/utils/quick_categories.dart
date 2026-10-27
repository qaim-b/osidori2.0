import '../../domain/entities/category_entity.dart';

/// Keep actual category IDs so quick entry uses the same Excel categories.
List<CategoryEntity> quickCategories(
  List<CategoryEntity> categories,
  List<String> recentIds, {
  int limit = 6,
}) {
  final byId = {for (final category in categories) category.id: category};
  final ordered = <CategoryEntity>[];
  final seen = <String>{};
  void add(CategoryEntity category) {
    if (seen.add(category.id)) ordered.add(category);
  }

  for (final id in recentIds) {
    final category = byId[id];
    if (category != null) add(category);
  }
  const common = [
    'Home Cooking',
    'Dining Out',
    'Snacking',
    'Household Goods',
    'Public Transport',
    'Dating',
  ];
  for (final name in common) {
    for (final category in categories) {
      if (category.name.toLowerCase() == name.toLowerCase()) add(category);
    }
  }
  for (final category in categories) {
    add(category);
  }
  return ordered.take(limit).toList();
}
