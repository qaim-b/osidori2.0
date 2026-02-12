/// App-wide constants. Keep this lean — no magic numbers scattered elsewhere.
class AppConstants {
  AppConstants._();

  static const String appName = 'Osidori 2.0';
  static const String appTagline = 'Finance, together.';

  // Default currency — can be changed per user in settings
  static const String defaultCurrency = 'JPY';

  // Group limits
  static const int minGroupMembers = 2;
  static const int maxGroupMembers = 10;

  // UI
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;

  // Supabase 
  static const String supabaseUrl = 'https://amybnvltdbtdrmixasxt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFteWJudmx0ZGJ0ZHJtaXhhc3h0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MjA3MTksImV4cCI6MjA4NjE5NjcxOX0.NzXechDoJBk20bYUNRZlkn2X97tpfbf-R7x4mc2aMe8';

  // CSV export
  static const String csvDateFormat = 'yyyy-MM-dd';
  static const String csvFileName = 'osidori2_transactions';

  // Pagination
  static const int defaultPageSize = 50;

  
}
