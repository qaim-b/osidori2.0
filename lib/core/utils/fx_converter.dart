import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'local_data_cache.dart';

class FxQuote {
  final double rate;
  final DateTime quotedAt;
  final bool isFallback;

  const FxQuote({
    required this.rate,
    required this.quotedAt,
    this.isFallback = false,
  });
}

class FxConverter {
  FxConverter._();

  static final Map<String, FxQuote> _rateCache = <String, FxQuote>{};
  static final Map<String, Future<FxQuote>> _pending =
      <String, Future<FxQuote>>{};

  static Future<FxQuote> getQuote({
    required String fromCurrency,
    required String toCurrency,
    DateTime? forDate,
  }) {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();
    final targetDate = (forDate ?? DateTime.now()).toUtc();
    final day = DateFormat('yyyy-MM-dd').format(targetDate);
    if (from == to) {
      return Future.value(FxQuote(rate: 1.0, quotedAt: targetDate));
    }

    final key = '$day|$from|$to';
    final cached = _rateCache[key];
    if (cached != null) return Future.value(cached);

    final inFlight = _pending[key];
    if (inFlight != null) return inFlight;

    final future = _getQuoteWithCache(
      day: day,
      from: from,
      to: to,
      key: key,
      targetDate: targetDate,
    );

    _pending[key] = future;
    return future;
  }

  static Future<double> getRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? forDate,
  }) async {
    final quote = await getQuote(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      forDate: forDate,
    );
    return quote.rate;
  }

  static Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    DateTime? forDate,
  }) async {
    final quote = await getQuote(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      forDate: forDate,
    );
    return amount * quote.rate;
  }

  static Future<FxQuote> _fetchQuote({
    required String from,
    required String to,
    required String day,
  }) async {
    final dayUri = Uri.parse(
      'https://$day.currency-api.pages.dev/v1/currencies/${from.toLowerCase()}.min.json',
    );
    final latestUri = Uri.parse(
      'https://latest.currency-api.pages.dev/v1/currencies/${from.toLowerCase()}.min.json',
    );

    for (final uri in [dayUri, latestUri]) {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        continue;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = decoded[from.toLowerCase()] as Map<String, dynamic>?;
      final value = rates?[to.toLowerCase()];
      if (value is num && value > 0) {
        final quoteDateRaw = decoded['date'] as String? ?? day;
        return FxQuote(
          rate: value.toDouble(),
          quotedAt: DateTime.parse(quoteDateRaw).toUtc(),
        );
      }
    }

    throw Exception('FX API missing rate for $from->$to');
  }

  static Future<FxQuote> _getQuoteWithCache({
    required String day,
    required String from,
    required String to,
    required String key,
    required DateTime targetDate,
  }) async {
    final dayCacheKey = LocalDataCache.fxRateKey(from: from, to: to, day: day);
    final latestCacheKey = LocalDataCache.latestFxRateKey(from: from, to: to);
    try {
      final storedForDay = await LocalDataCache.getJsonObject(dayCacheKey);
      final storedRate = (storedForDay?['rate'] as num?)?.toDouble();
      final storedDay = storedForDay?['day'] as String?;
      if (_isUsableRate(from: from, to: to, rate: storedRate) &&
          storedDay != null) {
        final quote = FxQuote(
          rate: storedRate!,
          quotedAt: DateTime.parse(storedDay).toUtc(),
        );
        _rateCache[key] = quote;
        _pending.remove(key);
        return quote;
      } else if (storedForDay != null) {
        await LocalDataCache.remove(dayCacheKey);
      }

      final quote = await _fetchQuote(from: from, to: to, day: day);
      _rateCache[key] = quote;
      await LocalDataCache.setJsonObject(dayCacheKey, {
        'rate': quote.rate,
        'day': DateFormat('yyyy-MM-dd').format(quote.quotedAt),
        'from': from,
        'to': to,
      });
      await LocalDataCache.setJsonObject(latestCacheKey, {
        'rate': quote.rate,
        'day': DateFormat('yyyy-MM-dd').format(quote.quotedAt),
        'from': from,
        'to': to,
        'saved_at': DateTime.now().toUtc().toIso8601String(),
      });
      _pending.remove(key);
      return quote;
    } catch (_) {
      final latestStored = await LocalDataCache.getJsonObject(latestCacheKey);
      final latestRate = (latestStored?['rate'] as num?)?.toDouble();
      final latestDay = latestStored?['day'] as String?;
      if (_isUsableRate(from: from, to: to, rate: latestRate) &&
          latestDay != null) {
        final quote = FxQuote(
          rate: latestRate!,
          quotedAt: DateTime.parse(latestDay).toUtc(),
          isFallback: true,
        );
        _rateCache[key] = quote;
        _pending.remove(key);
        return quote;
      } else if (latestStored != null) {
        await LocalDataCache.remove(latestCacheKey);
      }
      _pending.remove(key);
      return _fallbackQuote(from: from, to: to, targetDate: targetDate);
    }
  }

  static bool _isUsableRate({
    required String from,
    required String to,
    required double? rate,
  }) {
    if (rate == null || rate <= 0) return false;
    if (from != to && rate == 1.0) return false;
    return true;
  }

  static FxQuote _fallbackQuote({
    required String from,
    required String to,
    required DateTime targetDate,
  }) {
    if (from == to) {
      return FxQuote(rate: 1.0, quotedAt: targetDate, isFallback: true);
    }

    // Safe fallback: no conversion.
    return FxQuote(rate: 1.0, quotedAt: targetDate, isFallback: true);
  }
}
