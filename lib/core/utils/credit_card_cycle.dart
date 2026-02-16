import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

class CreditCycleSnapshot {
  final DateTime lastStatementStart;
  final DateTime lastStatementEnd;
  final DateTime currentCycleStart;
  final DateTime currentCycleEnd;
  final DateTime nextPaymentDate;
  final double lastStatementAmount;
  final double currentCycleAmount;

  const CreditCycleSnapshot({
    required this.lastStatementStart,
    required this.lastStatementEnd,
    required this.currentCycleStart,
    required this.currentCycleEnd,
    required this.nextPaymentDate,
    required this.lastStatementAmount,
    required this.currentCycleAmount,
  });
}

class CreditCardCycle {
  const CreditCardCycle._();

  static CreditCycleSnapshot? buildSnapshot({
    required AccountModel account,
    required List<TransactionModel> transactions,
    DateTime? now,
  }) {
    if (!account.type.name.contains('credit')) return null;
    final ref = now ?? DateTime.now();
    final startDay = (account.creditCycleStartDay ?? 27).clamp(1, 31);
    final paymentDay = (account.creditPaymentDay ?? startDay).clamp(1, 31);

    final monthStart = _safeDate(ref.year, ref.month, startDay);
    final currentCycleStart = ref.isBefore(monthStart)
        ? _safeDate(ref.year, ref.month - 1, startDay)
        : monthStart;
    final nextCycleStart = _safeDate(
      currentCycleStart.year,
      currentCycleStart.month + 1,
      startDay,
    );
    final currentCycleEnd = nextCycleStart.subtract(const Duration(days: 1));
    final lastStatementStart = _safeDate(
      currentCycleStart.year,
      currentCycleStart.month - 1,
      startDay,
    );
    final lastStatementEnd = currentCycleStart.subtract(
      const Duration(days: 1),
    );

    final nextPaymentDate = ref.day <= paymentDay
        ? _safeDate(ref.year, ref.month, paymentDay)
        : _safeDate(ref.year, ref.month + 1, paymentDay);

    double lastAmount = 0;
    double currentAmount = 0;
    for (final t in transactions) {
      final amount = _signedAmountForCard(account.id, t);
      if (amount == 0) continue;
      if (!_isBeforeDay(t.date, lastStatementStart) &&
          !_isAfterDay(t.date, lastStatementEnd)) {
        lastAmount += amount;
      }
      if (!_isBeforeDay(t.date, currentCycleStart) &&
          !_isAfterDay(t.date, currentCycleEnd)) {
        currentAmount += amount;
      }
    }

    if (lastAmount < 0) lastAmount = 0;
    if (currentAmount < 0) currentAmount = 0;

    return CreditCycleSnapshot(
      lastStatementStart: lastStatementStart,
      lastStatementEnd: lastStatementEnd,
      currentCycleStart: currentCycleStart,
      currentCycleEnd: currentCycleEnd,
      nextPaymentDate: nextPaymentDate,
      lastStatementAmount: lastAmount,
      currentCycleAmount: currentAmount,
    );
  }

  static double _signedAmountForCard(String accountId, TransactionModel t) {
    if (t.isExpense && t.fromAccountId == accountId) return t.amount;
    if (t.isIncome && t.fromAccountId == accountId) return -t.amount;
    if (t.isTransfer && t.toAccountId == accountId) return -t.amount;
    if (t.isTransfer && t.fromAccountId == accountId) return t.amount;
    return 0;
  }

  static DateTime _safeDate(int year, int month, int day) {
    final base = DateTime(year, month, 1);
    final lastDay = DateTime(base.year, base.month + 1, 0).day;
    return DateTime(base.year, base.month, day.clamp(1, lastDay));
  }

  static bool _isBeforeDay(DateTime a, DateTime b) => DateTime(
    a.year,
    a.month,
    a.day,
  ).isBefore(DateTime(b.year, b.month, b.day));

  static bool _isAfterDay(DateTime a, DateTime b) => DateTime(
    a.year,
    a.month,
    a.day,
  ).isAfter(DateTime(b.year, b.month, b.day));
}
