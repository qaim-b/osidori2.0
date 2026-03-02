import 'dart:convert';

import 'package:http/http.dart' as http;

class FxConverter {
  FxConverter._();

  static final Map<String, double> _rateCache = <String, double>{};
  static final Map<String, Future<double>> _pending = <String, Future<double>>{};

  static Future<double> getRate({
    required String fromCurrency,
    required String toCurrency,
  }) {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();
    if (from == to) return Future.value(1.0);

    final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final key = '$day|$from|$to';
    final cached = _rateCache[key];
    if (cached != null) return Future.value(cached);

    final inFlight = _pending[key];
    if (inFlight != null) return inFlight;

    final future = _fetchRate(from: from, to: to).then((rate) {
      _rateCache[key] = rate;
      _pending.remove(key);
      return rate;
    }).catchError((_) {
      _pending.remove(key);
      return _fallbackRate(from: from, to: to);
    });

    _pending[key] = future;
    return future;
  }

  static Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final rate = await getRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
    return amount * rate;
  }

  static Future<double> _fetchRate({
    required String from,
    required String to,
  }) async {
    final uri = Uri.parse(
      'https://api.frankfurter.app/latest?from=$from&to=$to',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('FX API request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = decoded['rates'] as Map<String, dynamic>?;
    final value = rates?[to];
    if (value is num && value > 0) {
      return value.toDouble();
    }
    throw Exception('FX API missing rate for $from->$to');
  }

  static double _fallbackRate({
    required String from,
    required String to,
  }) {
    if (from == to) return 1.0;

    // Offline fallback for primary app currencies.
    if (from == 'MYR' && to == 'JPY') return 33.5;
    if (from == 'JPY' && to == 'MYR') return 1 / 33.5;

    // Safe fallback: no conversion.
    return 1.0;
  }
}

