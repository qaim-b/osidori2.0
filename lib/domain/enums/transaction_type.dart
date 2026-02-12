/// The three fundamental transaction types.
/// Transfer moves money between accounts without affecting net worth.
enum TransactionType {
  expense,
  income,
  transfer;

  String get label {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.expense:
        return '📤';
      case TransactionType.income:
        return '📥';
      case TransactionType.transfer:
        return '🔄';
    }
  }

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}
