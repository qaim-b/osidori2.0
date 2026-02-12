import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_client.dart';
import '../models/transaction_model.dart';
import '../../core/constants/app_constants.dart';

/// The heart of the app — CRUD + queries for transactions.
/// Uses efficient pagination and date-range filtering.
class TransactionRepository {
  final SupabaseClient _client = AppSupabase.client;

  /// Create a new transaction
  Future<TransactionModel> create(TransactionModel txn) async {
    await _client.from(AppSupabase.transactionsTable).insert(txn.toJson());
    return txn;
  }

  /// Get transactions for a user in a date range, with pagination.
  /// Includes personal + shared (if groupId provided).
  Future<List<TransactionModel>> getForUser({
    required String userId,
    String? groupId,
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

    if (groupId == null) return personalTxns;

    // Also fetch shared transactions from other group members
    final sharedData = await _client
        .from(AppSupabase.transactionsTable)
        .select()
        .eq('group_id', groupId)
        .eq('visibility', 'shared')
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
    String? groupId,
  }) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);

    return getForUser(
      userId: userId,
      groupId: groupId,
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
    await _client
        .from(AppSupabase.transactionsTable)
        .update(txn.toJson())
        .eq('id', txn.id);
  }

  Future<void> delete(String id) async {
    await _client.from(AppSupabase.transactionsTable).delete().eq('id', id);
  }
}
