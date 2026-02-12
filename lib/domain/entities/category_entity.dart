/// A spending/income category. Supports parent-child hierarchy.
/// Categories have a display number matching the planning sheet.
class CategoryEntity implements Comparable<CategoryEntity> {
  final String id;
  final int displayNumber;
  final String name;
  final String emoji;
  final String type; // 'expense' or 'income'
  final String? parentId;
  final String? parentKey;
  final bool isEnabled;
  final int sortOrder;
  final DateTime createdAt;

  const CategoryEntity({
    required this.id,
    required this.displayNumber,
    required this.name,
    required this.emoji,
    required this.type,
    this.parentId,
    this.parentKey,
    this.isEnabled = true,
    required this.sortOrder,
    required this.createdAt,
  });

  /// Full display label: "12. 🍳 Home Cooking"
  String get displayLabel => '$displayNumber. $emoji $name';

  /// Short label: "🍳 Home Cooking"
  String get shortLabel => '$emoji $name';

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isParent => parentId == null && parentKey == null;

  CategoryEntity copyWith({
    String? id,
    int? displayNumber,
    String? name,
    String? emoji,
    String? type,
    String? parentId,
    String? parentKey,
    bool? isEnabled,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      displayNumber: displayNumber ?? this.displayNumber,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      parentKey: parentKey ?? this.parentKey,
      isEnabled: isEnabled ?? this.isEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Sort by displayNumber for consistent ordering
  @override
  int compareTo(CategoryEntity other) => sortOrder.compareTo(other.sortOrder);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
