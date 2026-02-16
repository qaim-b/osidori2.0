import '../../domain/entities/account_entity.dart';
import '../../domain/enums/account_type.dart';
import '../../domain/enums/owner_scope.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.name,
    required super.type,
    required super.ownerScope,
    required super.ownerUserId,
    super.groupId,
    required super.currency,
    super.initialBalance,
    required super.createdAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.fromString(json['type'] as String),
      ownerScope: OwnerScope.fromString(json['owner_scope'] as String),
      ownerUserId: json['owner_user_id'] as String,
      groupId: json['group_id'] as String?,
      currency: json['currency'] as String? ?? 'JPY',
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'owner_scope': ownerScope.name,
      'owner_user_id': ownerUserId,
      'group_id': groupId,
      'currency': currency,
      'initial_balance': initialBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      ownerScope: entity.ownerScope,
      ownerUserId: entity.ownerUserId,
      groupId: entity.groupId,
      currency: entity.currency,
      initialBalance: entity.initialBalance,
      createdAt: entity.createdAt,
    );
  }
}
