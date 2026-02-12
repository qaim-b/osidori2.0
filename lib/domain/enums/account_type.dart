/// Types of manual accounts a user can create.
/// No real bank connections — these are conceptual containers.
enum AccountType {
  cash,
  bank,
  credit,
  wallet;

  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.credit:
        return 'Credit Card';
      case AccountType.wallet:
        return 'Wallet';
    }
  }

  String get icon {
    switch (this) {
      case AccountType.cash:
        return '💵';
      case AccountType.bank:
        return '🏦';
      case AccountType.credit:
        return '💳';
      case AccountType.wallet:
        return '👛';
    }
  }

  static AccountType fromString(String value) {
    return AccountType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccountType.cash,
    );
  }
}
