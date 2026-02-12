import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.displayNumber,
    required super.name,
    required super.emoji,
    required super.type,
    super.parentId,
    super.parentKey,
    super.isEnabled,
    required super.sortOrder,
    required super.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      displayNumber: json['display_number'] as int? ?? 0,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '📋',
      type: json['type'] as String? ?? 'expense',
      parentId: json['parent_id'] as String?,
      parentKey: json['parent_key'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_number': displayNumber,
      'name': name,
      'emoji': emoji,
      'type': type,
      'parent_id': parentId,
      'parent_key': parentKey,
      'is_enabled': isEnabled,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      displayNumber: entity.displayNumber,
      name: entity.name,
      emoji: entity.emoji,
      type: entity.type,
      parentId: entity.parentId,
      parentKey: entity.parentKey,
      isEnabled: entity.isEnabled,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
    );
  }
}
