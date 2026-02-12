import 'package:intl/intl.dart';

/// Formats monetary amounts based on currency code.
/// JPY has no decimals, most others have 2.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final Map<String, NumberFormat> _cache = {};

  static String format(double amount, {String currency = 'JPY'}) {
    final formatter = _cache.putIfAbsent(
      currency,
      () => NumberFormat.currency(
        symbol: _symbolFor(currency),
        decimalDigits: _decimalsFor(currency),
      ),
    );
    return formatter.format(amount);
  }

  /// Compact format for charts (e.g., "¥12K", "$1.2M")
  static String compact(double amount, {String currency = 'JPY'}) {
    final symbol = _symbolFor(currency);
    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$symbol${amount.toStringAsFixed(_decimalsFor(currency))}';
  }

  static String _symbolFor(String currency) {
    switch (currency.toUpperCase()) {
      case 'JPY':
        return '¥';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'MYR':
        return 'RM';
      default:
        return '$currency ';
    }
  }

  static int _decimalsFor(String currency) {
    switch (currency.toUpperCase()) {
      case 'JPY':
        return 0; // Yen has no decimals
      default:
        return 2;
    }
  }
}
