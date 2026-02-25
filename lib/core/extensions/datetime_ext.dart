import 'package:intl/intl.dart';

/// Date helpers used across the app.
extension DateTimeExt on DateTime {
  /// "Jan 2026"
  String get monthYear => DateFormat('MMM yyyy').format(this);

  /// "2026-01-15"
  String get isoDate => DateFormat('yyyy-MM-dd').format(this);

  /// "Jan 15"
  String get shortDate => DateFormat('MMM d').format(this);

  /// "Jan 15, 2026"
  String get monthDayYear => DateFormat('MMM d, yyyy').format(this);

  /// "Wednesday, Jan 15"
  String get longDate => DateFormat('EEEE, MMM d').format(this);

  /// "15 Jan 2026, 3:30 PM"
  String get full => DateFormat('d MMM yyyy, h:mm a').format(this);

  /// First day of this month
  DateTime get firstDayOfMonth => DateTime(year, month, 1);

  /// Last day of this month
  DateTime get lastDayOfMonth => DateTime(year, month + 1, 0);

  /// Are two dates in the same month?
  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  /// Is this date today?
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}
