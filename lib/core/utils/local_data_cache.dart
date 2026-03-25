import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalDataCache {
  LocalDataCache._();

  static Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded
        .whereType<Map>()
        .map((item) => item.map((k, v) => MapEntry('$k', v)))
        .toList();
  }

  static Future<void> setJsonList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<Map<String, dynamic>?> getJsonObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return decoded.map((k, v) => MapEntry('$k', v));
  }

  static Future<void> setJsonObject(
    String key,
    Map<String, dynamic> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  static String categoriesKey(String userId) => 'cache.categories.$userId';

  static String monthlyTransactionsKey({
    required String userId,
    required int year,
    required int month,
  }) => 'cache.transactions.$userId.$year.${month.toString().padLeft(2, '0')}';

  static String fxRateKey({
    required String from,
    required String to,
    required String day,
  }) => 'cache.fx.$day.${from.toUpperCase()}.${to.toUpperCase()}';

  static String latestFxRateKey({required String from, required String to}) =>
      'cache.fx.latest.${from.toUpperCase()}.${to.toUpperCase()}';
}
