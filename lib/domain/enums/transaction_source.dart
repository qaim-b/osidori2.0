/// Source of a transaction — manual now, sync later.
/// Architecture is ready for future bank integrations.
enum TransactionSource {
  manual,
  sync;

  String get label {
    switch (this) {
      case TransactionSource.manual:
        return 'Manual';
      case TransactionSource.sync:
        return 'Auto-Synced';
    }
  }

  static TransactionSource fromString(String value) {
    return TransactionSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionSource.manual,
    );
  }
}
