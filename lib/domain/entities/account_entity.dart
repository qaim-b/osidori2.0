import '../enums/account_type.dart';
import '../enums/owner_scope.dart';

/// A conceptual financial account (NOT a real bank connection).
/// Examples: Cash, Credit Card, Bank Account, Wallet.
class AccountEntity {
  final String id;
  final String name;
  final AccountType type;
  final OwnerScope ownerScope;
  final String ownerUserId;
  final String? groupId;
  final String currency;
  final double initialBalance;
  final int? creditCycleStartDay;
  final int? creditPaymentDay;
  final DateTime createdAt;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerScope,
    required this.ownerUserId,
    this.groupId,
    required this.currency,
    this.initialBalance = 0,
    this.creditCycleStartDay,
    this.creditPaymentDay,
    required this.createdAt,
  });

  AccountEntity copyWith({
    String? id,
    String? name,
    AccountType? type,
    OwnerScope? ownerScope,
    String? ownerUserId,
    String? groupId,
    String? currency,
    double? initialBalance,
    int? creditCycleStartDay,
    int? creditPaymentDay,
    DateTime? createdAt,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerScope: ownerScope ?? this.ownerScope,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      groupId: groupId ?? this.groupId,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      creditCycleStartDay: creditCycleStartDay ?? this.creditCycleStartDay,
      creditPaymentDay: creditPaymentDay ?? this.creditPaymentDay,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AccountEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
