import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/transaction_model.dart';
import '../constants/app_constants.dart';

/// Exports transactions to CSV for monthly record-keeping.
/// File format matches the life planning sheet structure.
class CsvExporter {
  CsvExporter._();

  /// Generate a CSV file and return its path.
  static Future<String> exportTransactions({
    required List<TransactionModel> transactions,
    required Map<String, String> categoryNames,
    required int year,
    required int month,
  }) async {
    final dateFormat = DateFormat(AppConstants.csvDateFormat);
    final monthLabel = DateFormat('yyyy-MM').format(DateTime(year, month));

    // CSV header row
    final rows = <List<String>>[
      [
        'Date',
        'Type',
        'Category',
        'Amount',
        'Currency',
        'Account',
        'Visibility',
        'Note',
        'Source',
      ],
    ];

    // Sort transactions by date ascending for the export
    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final txn in sorted) {
      rows.add([
        dateFormat.format(txn.date),
        txn.type.name,
        categoryNames[txn.categoryId] ?? txn.categoryId,
        txn.amount.toString(),
        txn.currency,
        txn.fromAccountId,
        txn.visibility.name,
        txn.note ?? '',
        txn.source.name,
      ]);
    }

    // Summary rows at the bottom
    double totalIncome = 0;
    double totalExpense = 0;
    for (final txn in sorted) {
      if (txn.isIncome) totalIncome += txn.amount;
      if (txn.isExpense) totalExpense += txn.amount;
    }

    rows.add([]); // blank row
    rows.add(['', '', 'Total Income', totalIncome.toString(), '', '', '', '', '']);
    rows.add(['', '', 'Total Expense', totalExpense.toString(), '', '', '', '', '']);
    rows.add(['', '', 'Net', (totalIncome - totalExpense).toString(), '', '', '', '', '']);

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(rows);

    // Write to file
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${AppConstants.csvFileName}_$monthLabel.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  /// Share the CSV file using the system share sheet.
  static Future<void> shareFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Osidori 2.0 Transactions Export',
    );
  }

  /// Export one row per day, with one column per expense category.
  static Future<String> exportExpenseCategoryMatrix({
    required List<TransactionModel> transactions,
    required Map<String, String> categoryNames,
    required int year,
    required int month,
  }) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 1);
    final expenseTxns = transactions.where((t) {
      return t.isExpense &&
          !t.date.isBefore(from) &&
          t.date.isBefore(to);
    }).toList();

    final categoryIds = expenseTxns
        .map((t) => t.categoryId)
        .toSet()
        .toList()
      ..sort((a, b) {
        final an = categoryNames[a] ?? a;
        final bn = categoryNames[b] ?? b;
        return an.compareTo(bn);
      });

    final header = <String>[
      'Date',
      ...categoryIds.map((id) => categoryNames[id] ?? id),
      'Total',
    ];

    final byDate = <String, Map<String, double>>{};
    for (final txn in expenseTxns) {
      final dateKey = DateFormat('yyyy-MM-dd').format(txn.date);
      final dateMap = byDate.putIfAbsent(dateKey, () => <String, double>{});
      dateMap[txn.categoryId] = (dateMap[txn.categoryId] ?? 0) + txn.amount;
    }

    final dateKeys = byDate.keys.toList()..sort();

    final rows = <List<String>>[header];
    final categoryTotals = <String, double>{for (final id in categoryIds) id: 0};
    double grandTotal = 0;

    for (final dateKey in dateKeys) {
      final values = byDate[dateKey]!;
      double rowTotal = 0;
      final row = <String>[dateKey];
      for (final id in categoryIds) {
        final amount = values[id] ?? 0;
        rowTotal += amount;
        categoryTotals[id] = (categoryTotals[id] ?? 0) + amount;
        row.add(amount == 0 ? '' : amount.toStringAsFixed(2));
      }
      grandTotal += rowTotal;
      row.add(rowTotal.toStringAsFixed(2));
      rows.add(row);
    }

    rows.add(<String>[
      'TOTAL',
      ...categoryIds.map((id) {
        final total = categoryTotals[id] ?? 0;
        return total == 0 ? '' : total.toStringAsFixed(2);
      }),
      grandTotal.toStringAsFixed(2),
    ]);

    final csvString = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        '${AppConstants.csvFileName}_category_matrix_${DateFormat('yyyy-MM').format(from)}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);
    return file.path;
  }
}
