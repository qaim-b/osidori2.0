/// Match supported currency precision and the database's NUMERIC(15,2) limit.
/// Never silently round a purchase total before saving or exporting it.
bool isValidPurchaseAmount(double? amount, String currency) {
  if (amount == null || !amount.isFinite || amount <= 0 || amount >= 1e13) {
    return false;
  }
  final digits = switch (currency.toUpperCase()) {
    'JPY' => 0,
    'MYR' => 2,
    _ => null,
  };
  return digits != null &&
      double.parse(amount.toStringAsFixed(digits)) == amount;
}
