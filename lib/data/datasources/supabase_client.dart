import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

/// Singleton access to Supabase client.
/// Initialize once in main.dart, access anywhere via SupabaseClient.instance.
class AppSupabase {
  AppSupabase._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // Table names — single source of truth
  static const String usersTable = 'profiles';
  static const String groupsTable = 'groups';
  static const String groupMembersTable = 'group_members';
  static const String accountsTable = 'accounts';
  static const String categoriesTable = 'categories';
  static const String transactionsTable = 'transactions';
  static const String goalsTable = 'goals';
  static const String budgetLimitsTable = 'budget_limits';
}
