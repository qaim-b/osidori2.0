import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_client.dart';
import '../models/transaction_model.dart';
import '../../core/constants/app_constants.dart';

/// The heart of the app — CRUD + queries for transactions.
/// Uses efficient pagination and date-range filtering.
class TransactionRepository {
  final SupabaseClient _client = AppSupabase.client;
  bool _fxColumnsUnsupported = false;

  /// Create a new transaction
  Future<TransactionModel> create(TransactionModel txn) async {
    final payload = _txPayload(txn);
    try {
      await _client.from(AppSupabase.transactionsTable).insert(payload);
    } on PostgrestException catch (e) {
      if (_shouldFallbackToLegacyFxPayload(e)) {
        _fxColumnsUnsupported = true;
        await _client
            .from(AppSupabase.transactionsTable)
            .insert(_legacyFxPayload(payload));
      } else {
        rethrow;
      }
    }
    return txn;
  }

  /// Get transactions for a user in a date range, with pagination.
  /// Includes personal + shared (if groupId provided).
  Future<List<TransactionModel>> getForUser({
    required String userId,
    List<String> groupIds = const [],
    required DateTime from,
    required DateTime to,
    int page = 0,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    var query = _client
        .from(AppSupabase.transactionsTable)
        .select()
        .eq('owner_user_id', userId)
        .gte('date', from.toIso8601String())
        .lte('date', to.toIso8601String())
        .order('date', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    final data = await query;
    final personalTxns =
        data.map((json) => TransactionModel.fromJson(json)).toList();

    if (groupIds.isEmpty) return personalTxns;

    // Also fetch shared transactions from other group members
    final sharedData = await _client
        .from(AppSupabase.transactionsTable)
        .select()
        .inFilter('group_id', groupIds)
        .neq('owner_user_id', userId)
        .gte('date', from.toIso8601String())
        .lte('date', to.toIso8601String())
        .order('date', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    final sharedTxns =
        sharedData.map((json) => TransactionModel.fromJson(json)).toList();

    // Merge and sort by date descending
    final all = [...personalTxns, ...sharedTxns];
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  /// Get all transactions for a month (for CSV export)
  Future<List<TransactionModel>> getForMonth({
    required String userId,
    required int year,
    required int month,
    List<String> groupIds = const [],
  }) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);

    return getForUser(
      userId: userId,
      groupIds: groupIds,
      from: from,
      to: to,
      pageSize: 10000, // No pagination for export
    );
  }

  /// Get category totals for a month (for charts)
  Future<Map<String, double>> getCategoryTotals({
    required String userId,
    required DateTime from,
    required DateTime to,
    required String type, // 'expense' or 'income'
    String? groupId,
    String? visibility, // null = all, 'personal', 'shared'
  }) async {
    var query = _client
        .from(AppSupabase.transactionsTable)
        .select('category_id, amount')
        .eq('type', type)
        .gte('date', from.toIso8601String())
        .lte('date', to.toIso8601String());

    if (visibility != null) {
      query = query.eq('visibility', visibility);
    }

    if (groupId != null && visibility == 'shared') {
      query = query.eq('group_id', groupId);
    } else {
      query = query.eq('owner_user_id', userId);
    }

    final data = await query;

    // Aggregate in Dart (efficient for reasonable data sizes)
    final totals = <String, double>{};
    for (final row in data) {
      final catId = row['category_id'] as String;
      final amount = (row['amount'] as num).toDouble();
      totals[catId] = (totals[catId] ?? 0) + amount;
    }
    return totals;
  }

  /// Monthly totals for income/expense/net (for overview)
  Future<Map<String, double>> getMonthlyTotals({
    required String userId,
    required DateTime from,
    required DateTime to,
    String? groupId,
    String? visibility,
  }) async {
    var query = _client
        .from(AppSupabase.transactionsTable)
        .select('type, amount')
        .gte('date', from.toIso8601String())
        .lte('date', to.toIso8601String());

    if (visibility == 'shared' && groupId != null) {
      query = query.eq('group_id', groupId).eq('visibility', 'shared');
    } else if (visibility == 'personal') {
      query = query
          .eq('owner_user_id', userId)
          .eq('visibility', 'personal');
    } else {
      // All visible transactions
      query = query.eq('owner_user_id', userId);
    }

    final data = await query;

    double totalIncome = 0;
    double totalExpense = 0;

    for (final row in data) {
      final type = row['type'] as String;
      final amount = (row['amount'] as num).toDouble();
      if (type == 'income') {
        totalIncome += amount;
      } else if (type == 'expense') {
        totalExpense += amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'net': totalIncome - totalExpense,
    };
  }

  Future<void> update(TransactionModel txn) async {
    final payload = _txPayload(txn);
    try {
      await _client
          .from(AppSupabase.transactionsTable)
          .update(payload)
          .eq('id', txn.id);
    } on PostgrestException catch (e) {
      if (_shouldFallbackToLegacyFxPayload(e)) {
        _fxColumnsUnsupported = true;
        await _client
            .from(AppSupabase.transactionsTable)
            .update(_legacyFxPayload(payload))
            .eq('id', txn.id);
      } else {
        rethrow;
      }
    }
  }

  Future<void> delete(String id) async {
    await _client.from(AppSupabase.transactionsTable).delete().eq('id', id);
  }

  /// Repairs legacy rows where "shared" transactions were saved with null group_id.
  Future<int> assignUngroupedSharedToGroup({
    required String userId,
    required String groupId,
  }) async {
    final updated = await _client
        .from(AppSupabase.transactionsTable)
        .update({'group_id': groupId})
        .eq('owner_user_id', userId)
        .eq('visibility', 'shared')
        .isFilter('group_id', null)
        .select('id');
    return updated.length;
  }

  Map<String, dynamic> _txPayload(TransactionModel txn) {
    final payload = txn.toJson();
    return _fxColumnsUnsupported ? _legacyFxPayload(payload) : payload;
  }

  bool _shouldFallbackToLegacyFxPayload(PostgrestException e) {
    if (e.code != 'PGRST204') return false;
    final message = e.message.toLowerCase();
    return message.contains('base_amount_locked') ||
        message.contains('original_amount') ||
        message.contains('original_currency') ||
        message.contains('fx_rate_to_base') ||
        message.contains('fx_base_currency') ||
        message.contains('fx_rate_date');
  }

  Map<String, dynamic> _legacyFxPayload(Map<String, dynamic> payload) {
    final legacy = Map<String, dynamic>.from(payload);
    legacy.remove('original_amount');
    legacy.remove('original_currency');
    legacy.remove('fx_rate_to_base');
    legacy.remove('fx_base_currency');
    legacy.remove('base_amount_locked');
    legacy.remove('fx_rate_date');
    return legacy;
  }
}
