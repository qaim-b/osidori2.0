import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/transaction_model.dart';
import '../constants/app_constants.dart';

class CsvExporter {
  CsvExporter._();

  static Future<String> exportTransactions({
    required List<TransactionModel> transactions,
    required Map<String, String> categoryNames,
    required int year,
    required int month,
  }) async {
    final dateFormat = DateFormat(AppConstants.csvDateFormat);
    final monthLabel = DateFormat('yyyy-MM').format(DateTime(year, month));

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

    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final txn in sorted) {
      rows.add([
        dateFormat.format(txn.date),
        txn.type.name,
        categoryNames[txn.categoryId] ??
            txn.categoryNameSnapshot ??
            txn.categoryId,
        txn.amount.toString(),
        txn.currency,
        txn.fromAccountId,
        txn.visibility.name,
        txn.note ?? '',
        txn.source.name,
      ]);
    }

    double totalIncome = 0;
    double totalExpense = 0;
    for (final txn in sorted) {
      if (txn.isIncome) totalIncome += txn.amount;
      if (txn.isExpense) totalExpense += txn.amount;
    }

    rows.add([]);
    rows.add([
      '',
      '',
      'Total Income',
      totalIncome.toString(),
      '',
      '',
      '',
      '',
      '',
    ]);
    rows.add([
      '',
      '',
      'Total Expense',
      totalExpense.toString(),
      '',
      '',
      '',
      '',
      '',
    ]);
    rows.add([
      '',
      '',
      'Net',
      (totalIncome - totalExpense).toString(),
      '',
      '',
      '',
      '',
      '',
    ]);

    final csvString = const ListToCsvConverter().convert(rows);
    final fileName = '${AppConstants.csvFileName}_$monthLabel.csv';
    return _persistText(
      content: csvString,
      fileName: fileName,
      mimeType: 'text/csv',
    );
  }

  static Future<String> exportExpenseCategoryMatrix({
    required List<TransactionModel> transactions,
    required Map<String, String> categoryNames,
    required int year,
    required int month,
  }) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 1);
    final expenseTxns = transactions.where((t) {
      return t.isExpense && !t.date.isBefore(from) && t.date.isBefore(to);
    }).toList();

    final categoryIds = categoryNames.keys.toList()
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

    final dateKeys = List.generate(
      DateTime(year, month + 1, 0).day,
      (i) => DateFormat('yyyy-MM-dd').format(DateTime(year, month, i + 1)),
    );

    final rows = <List<String>>[header];
    final categoryTotals = <String, double>{
      for (final id in categoryIds) id: 0,
    };
    double grandTotal = 0;

    for (final dateKey in dateKeys) {
      final values = byDate[dateKey] ?? {};
      double rowTotal = 0;
      final row = <String>[dateKey];
      for (final id in categoryIds) {
        final amount = values[id] ?? 0;
        rowTotal += amount;
        categoryTotals[id] = (categoryTotals[id] ?? 0) + amount;
        row.add(amount.toStringAsFixed(2));
      }
      grandTotal += rowTotal;
      row.add(rowTotal.toStringAsFixed(2));
      rows.add(row);
    }

    rows.add(<String>[
      'TOTAL',
      ...categoryIds.map((id) => (categoryTotals[id] ?? 0).toStringAsFixed(2)),
      grandTotal.toStringAsFixed(2),
    ]);

    final csvString = const ListToCsvConverter().convert(rows);
    final fileName =
        '${AppConstants.csvFileName}_category_matrix_${DateFormat('yyyy-MM').format(from)}.csv';
    return _persistText(
      content: csvString,
      fileName: fileName,
      mimeType: 'text/csv',
    );
  }

  static Future<String> exportTransactionsXlsx({
    required List<TransactionModel> transactions,
    required Map<String, String> categoryNames,
    required int year,
    required int month,
  }) async {
    final monthLabel = DateFormat('yyyy-MM').format(DateTime(year, month));
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];

    final headers = [
      'Date',
      'Type',
      'Category',
      'Amount',
      'Currency',
      'Account',
      'Visibility',
      'Note',
      'Source',
    ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final txn in sorted) {
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(txn.date)),
        TextCellValue(txn.type.name),
        TextCellValue(
          categoryNames[txn.categoryId] ??
              txn.categoryNameSnapshot ??
              txn.categoryId,
        ),
        DoubleCellValue(txn.amount),
        TextCellValue(txn.currency),
        TextCellValue(txn.fromAccountId),
        TextCellValue(txn.visibility.name),
        TextCellValue(txn.note ?? ''),
        TextCellValue(txn.source.name),
      ]);
    }

    final income = sorted
        .where((t) => t.isIncome)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = sorted
        .where((t) => t.isExpense)
        .fold<double>(0, (s, t) => s + t.amount);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Total Income'), DoubleCellValue(income)]);
    sheet.appendRow([TextCellValue('Total Expense'), DoubleCellValue(expense)]);
    sheet.appendRow([TextCellValue('Net'), DoubleCellValue(income - expense)]);

    final bytes = Uint8List.fromList(excel.encode()!);
    final fileName = '${AppConstants.csvFileName}_$monthLabel.xlsx';
    return _persistBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  static Future<String> exportExpenseCategoryMatrixXlsx({
    required List<TransactionModel> transactions,
    required Map<String, String> categoryNames,
    required int year,
    required int month,
  }) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 1);
    final expenseTxns = transactions.where((t) {
      return t.isExpense && !t.date.isBefore(from) && t.date.isBefore(to);
    }).toList();

    final categoryIds = categoryNames.keys.toList()
      ..sort(
        (a, b) => (categoryNames[a] ?? a).compareTo(categoryNames[b] ?? b),
      );

    final byDate = <String, Map<String, double>>{};
    for (final txn in expenseTxns) {
      final dateKey = DateFormat('yyyy-MM-dd').format(txn.date);
      final dateMap = byDate.putIfAbsent(dateKey, () => <String, double>{});
      dateMap[txn.categoryId] = (dateMap[txn.categoryId] ?? 0) + txn.amount;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Expense Matrix'];

    sheet.appendRow([
      TextCellValue('Date'),
      ...categoryIds.map((id) => TextCellValue(categoryNames[id] ?? id)),
      TextCellValue('Total'),
    ]);

    final categoryTotals = <String, double>{
      for (final id in categoryIds) id: 0,
    };
    double grandTotal = 0;

    for (int i = 1; i <= DateTime(year, month + 1, 0).day; i++) {
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime(year, month, i));
      final values = byDate[dateKey] ?? {};
      double rowTotal = 0;
      final row = <CellValue>[TextCellValue(dateKey)];
      for (final id in categoryIds) {
        final amount = values[id] ?? 0;
        rowTotal += amount;
        categoryTotals[id] = (categoryTotals[id] ?? 0) + amount;
        row.add(DoubleCellValue(amount));
      }
      grandTotal += rowTotal;
      row.add(DoubleCellValue(rowTotal));
      sheet.appendRow(row);
    }

    sheet.appendRow([
      TextCellValue('TOTAL'),
      ...categoryIds.map((id) => DoubleCellValue(categoryTotals[id] ?? 0)),
      DoubleCellValue(grandTotal),
    ]);

    final bytes = Uint8List.fromList(excel.encode()!);
    final fileName =
        '${AppConstants.csvFileName}_category_matrix_${DateFormat('yyyy-MM').format(from)}.xlsx';
    return _persistBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  static Future<void> shareFile(String filePath) async {
    if (kIsWeb && filePath.startsWith('web://')) {
      return;
    }
    await Share.shareXFiles([XFile(filePath)], subject: 'Osidori 2.0 Export');
  }

  static Future<String> _persistText({
    required String content,
    required String fileName,
    required String mimeType,
  }) {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return _persistBytes(bytes: bytes, fileName: fileName, mimeType: mimeType);
  }

  static Future<String> _persistBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      await Share.shareXFiles([
        XFile.fromData(bytes, mimeType: mimeType, name: fileName),
      ], subject: 'Osidori 2.0 Export');
      return 'web://$fileName';
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
