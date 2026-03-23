import '../../domain/entities/category_entity.dart';

CategoryEntity? findHoneymoonCategory(List<CategoryEntity> categories) {
  if (categories.isEmpty) return null;
  for (final cat in categories) {
    if (cat.name.toLowerCase().contains('honeymoon')) {
      return cat;
    }
  }
  for (final cat in categories) {
    if (cat.displayNumber == 27) {
      return cat;
    }
  }
  return null;
}
