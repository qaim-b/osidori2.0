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

    final categoryDisplayNames = <String, String>{...categoryNames};
    final categoryIdToCanonical = <String, String>{};
    final canonicalToDisplay = <String, String>{};
    String toCanonicalFromRaw(String raw) {
      final canonical = _canonicalCategoryKey(raw);
      canonicalToDisplay[canonical] =
          canonicalToDisplay[canonical] ?? _displayCategoryLabel(raw);
      return canonical;
    }

    for (final txn in expenseTxns) {
      categoryDisplayNames[txn.categoryId] =
          categoryDisplayNames[txn.categoryId] ??
          txn.categoryNameSnapshot ??
          txn.categoryId;
      final raw =
          categoryDisplayNames[txn.categoryId] ??
          txn.categoryNameSnapshot ??
          txn.categoryId;
      final numberedKey = txn.categoryDisplayNumberSnapshot == null
          ? null
          : 'n:${txn.categoryDisplayNumberSnapshot}';
      final canonical = numberedKey ?? toCanonicalFromRaw(raw);
      canonicalToDisplay[canonical] =
          canonicalToDisplay[canonical] ?? _displayCategoryLabel(raw);
      categoryIdToCanonical[txn.categoryId] = canonical;
    }

    // One column per category label (merge duplicate IDs with same label).
    final keys = <String>{
      ...categoryIdToCanonical.values,
    }.toList()
      ..sort();

    final labels = keys.map((k) => canonicalToDisplay[k] ?? k).toList();

    final header = <String>[
      'Date',
      ...labels,
      'Total',
    ];

    final byDate = <String, Map<String, double>>{};
    for (final txn in expenseTxns) {
      final dateKey = DateFormat('yyyy-MM-dd').format(txn.date);
      final raw =
          categoryDisplayNames[txn.categoryId] ??
          txn.categoryNameSnapshot ??
          txn.categoryId;
      final canonical = categoryIdToCanonical[txn.categoryId] ??
          toCanonicalFromRaw(raw);
      final dateMap = byDate.putIfAbsent(dateKey, () => <String, double>{});
      dateMap[canonical] = (dateMap[canonical] ?? 0) + txn.amount;
    }

    final dateKeys = List.generate(
      DateTime(year, month + 1, 0).day,
      (i) => DateFormat('yyyy-MM-dd').format(DateTime(year, month, i + 1)),
    );

    final rows = <List<String>>[header];
    final categoryTotals = <String, double>{
      for (final key in keys) key: 0,
    };
    double grandTotal = 0;

    for (final dateKey in dateKeys) {
      final values = byDate[dateKey] ?? {};
      double rowTotal = 0;
      final row = <String>[dateKey];
      for (final key in keys) {
        final amount = values[key] ?? 0;
        rowTotal += amount;
        categoryTotals[key] = (categoryTotals[key] ?? 0) + amount;
        row.add(amount.toStringAsFixed(2));
      }
      grandTotal += rowTotal;
      row.add(rowTotal.toStringAsFixed(2));
      rows.add(row);
    }

    rows.add(<String>[
      'TOTAL',
      ...keys.map((key) => (categoryTotals[key] ?? 0).toStringAsFixed(2)),
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
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    final sheet = excel['Transactions'];
    final moneyFormat = NumFormat.custom(formatCode: '#,##0.00;[Red]-#,##0.00');
    final thinBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#FFD2D9E6'),
    );
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#FF2F5597'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFFFF'),
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );
    final amountStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      numberFormat: moneyFormat,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );
    final textStyle = CellStyle(
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

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
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(0, 24);
    const widths = [13.0, 12.0, 22.0, 14.0, 10.0, 18.0, 11.0, 26.0, 11.0];
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }

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
      final rowIndex = sheet.maxRows - 1;
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
        );
        if (col == 3) {
          cell.cellStyle = amountStyle;
        } else {
          cell.cellStyle = textStyle;
        }
      }
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
    final totalsStart = sheet.maxRows - 3;
    final totalLabelStyle = headerStyle.copyWith(
      backgroundColorHexVal: ExcelColor.fromHexString('#FFE8F0FF'),
      fontColorHexVal: ExcelColor.fromHexString('#FF1D4ED8'),
      horizontalAlignVal: HorizontalAlign.Left,
    );
    final totalValueStyle = amountStyle.copyWith(
      boldVal: true,
      backgroundColorHexVal: ExcelColor.fromHexString('#FFF5F8FF'),
    );
    for (var r = totalsStart; r <= totalsStart + 2; r++) {
      final labelCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r),
      );
      final valueCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r),
      );
      labelCell.cellStyle = totalLabelStyle;
      valueCell.cellStyle = totalValueStyle;
    }

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
    Map<String, double> budgetLimits = const {},
  }) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 1);
    final expenseTxns = transactions.where((t) {
      return t.isExpense && !t.date.isBefore(from) && t.date.isBefore(to);
    }).toList();

    final categoryDisplayNames = <String, String>{...categoryNames};
    final categoryIdToCanonical = <String, String>{};
    for (final txn in expenseTxns) {
      categoryDisplayNames[txn.categoryId] =
          categoryDisplayNames[txn.categoryId] ??
          txn.categoryNameSnapshot ??
          txn.categoryId;
    }

    final excel = Excel.createExcel();
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    final planningSheet = excel['Planning Summary'];

    final currency = expenseTxns.isNotEmpty ? expenseTxns.first.currency : 'JPY';
    final symbol = currency.toUpperCase() == 'MYR' ? 'RM' : '\u00A5';
    final decimalDigits = currency.toUpperCase() == 'JPY' ? 0 : 2;

    final canonicalToDisplay = <String, String>{};

    String toCanonical(String raw) {
      final canonical = _canonicalCategoryKey(raw);
      canonicalToDisplay[canonical] =
          canonicalToDisplay[canonical] ?? _displayCategoryLabel(raw);
      return canonical;
    }

    for (final name in categoryDisplayNames.values) {
      toCanonical(name);
    }

    final expenseTotalsByCanonical = <String, double>{};
    for (final txn in expenseTxns) {
      final rawLabel =
          categoryDisplayNames[txn.categoryId] ??
          txn.categoryNameSnapshot ??
          txn.categoryId;
      final numberedKey = txn.categoryDisplayNumberSnapshot == null
          ? null
          : 'n:${txn.categoryDisplayNumberSnapshot}';
      final key = numberedKey ?? toCanonical(rawLabel);
      canonicalToDisplay[key] =
          canonicalToDisplay[key] ?? _displayCategoryLabel(rawLabel);
      categoryIdToCanonical[txn.categoryId] = key;
      expenseTotalsByCanonical[key] =
          (expenseTotalsByCanonical[key] ?? 0) + txn.amount;
    }

    final budgetByCanonical = <String, double>{};
    for (final entry in budgetLimits.entries) {
      final rawLabel = categoryDisplayNames[entry.key] ?? entry.key;
      final key = categoryIdToCanonical[entry.key] ?? toCanonical(rawLabel);
      budgetByCanonical[key] = (budgetByCanonical[key] ?? 0) + entry.value;
    }

    final keys = <String>{
      ...canonicalToDisplay.keys,
      ...expenseTotalsByCanonical.keys,
      ...budgetByCanonical.keys,
    }.toList()
      ..sort((a, b) {
        final aDisplay = canonicalToDisplay[a] ?? a;
        final bDisplay = canonicalToDisplay[b] ?? b;
        return aDisplay.compareTo(bDisplay);
      });

    final totalColumns = keys.length + 2;
    final titleText =
        'Osidori 2.0 Planning Summary - ${DateFormat('MMMM yyyy').format(from)}';
    planningSheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: totalColumns - 1, rowIndex: 0),
      customValue: TextCellValue(titleText),
    );

    final header = <CellValue>[
      TextCellValue('Metric'),
      ...keys.map((k) => TextCellValue(canonicalToDisplay[k] ?? k)),
      TextCellValue('Monthly Sum'),
    ];
    planningSheet.appendRow(header);

    double expenseSum = 0;
    final expenseRow = <CellValue>[TextCellValue('Expense')];
    for (final key in keys) {
      final amount = expenseTotalsByCanonical[key] ?? 0;
      expenseSum += amount;
      expenseRow.add(DoubleCellValue(amount));
    }
    expenseRow.add(DoubleCellValue(expenseSum));
    planningSheet.appendRow(expenseRow);

    double budgetSum = 0;
    final budgetRow = <CellValue>[TextCellValue('Budget')];
    for (final key in keys) {
      final amount = budgetByCanonical[key] ?? 0;
      budgetSum += amount;
      budgetRow.add(DoubleCellValue(amount));
    }
    budgetRow.add(DoubleCellValue(budgetSum));
    planningSheet.appendRow(budgetRow);

    final diffRow = <CellValue>[TextCellValue('Exp-Bud')];
    for (final key in keys) {
      final diff =
          (expenseTotalsByCanonical[key] ?? 0) - (budgetByCanonical[key] ?? 0);
      diffRow.add(DoubleCellValue(diff));
    }
    diffRow.add(DoubleCellValue(expenseSum - budgetSum));
    planningSheet.appendRow(diffRow);

    final amountFormat = NumFormat.custom(
      formatCode:
          decimalDigits == 0
              ? '[$symbol]#,##0;[Red]-[$symbol]#,##0'
              : '[$symbol]#,##0.00;[Red]-[$symbol]#,##0.00',
    );
    final borderThin = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#FFD2D9E6'),
    );
    final borderMedium = Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString('#FF4A78C2'),
    );
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 15,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#FF2F5597'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFFFF'),
      leftBorder: borderMedium,
      rightBorder: borderMedium,
      topBorder: borderMedium,
      bottomBorder: borderMedium,
    );
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      backgroundColorHex: ExcelColor.fromHexString('#FF4A78C2'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFFFF'),
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );
    final expenseStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFE7F5E9'),
      fontColorHex: ExcelColor.fromHexString('#FF14532D'),
      numberFormat: amountFormat,
      horizontalAlign: HorizontalAlign.Right,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );
    final budgetStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFE8F0FF'),
      fontColorHex: ExcelColor.fromHexString('#FF1D4ED8'),
      numberFormat: amountFormat,
      horizontalAlign: HorizontalAlign.Right,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );
    final diffStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFFFF4E6'),
      fontColorHex: ExcelColor.fromHexString('#FF9A3412'),
      numberFormat: amountFormat,
      horizontalAlign: HorizontalAlign.Right,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );
    final expenseFirstColStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
      backgroundColorHex: ExcelColor.fromHexString('#FFE7F5E9'),
      fontColorHex: ExcelColor.fromHexString('#FF14532D'),
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );
    final budgetFirstColStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
      backgroundColorHex: ExcelColor.fromHexString('#FFE8F0FF'),
      fontColorHex: ExcelColor.fromHexString('#FF1D4ED8'),
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );
    final diffFirstColStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
      backgroundColorHex: ExcelColor.fromHexString('#FFFFF4E6'),
      fontColorHex: ExcelColor.fromHexString('#FF9A3412'),
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );
    final summaryStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFEDEFF5'),
      fontColorHex: ExcelColor.fromHexString('#FF1F2937'),
      numberFormat: NumFormat.custom(formatCode: '0.0%'),
      horizontalAlign: HorizontalAlign.Right,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );
    final summaryFirstColStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFEDEFF5'),
      fontColorHex: ExcelColor.fromHexString('#FF1F2937'),
      horizontalAlign: HorizontalAlign.Left,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    for (var col = 0; col < header.length; col++) {
      final titleCell = planningSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      titleCell.cellStyle = titleStyle;
      final headerCell = planningSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1),
      );
      headerCell.cellStyle = headerStyle;
      final headerText = switch (header[col]) {
        TextCellValue(value: final value) => value.toString(),
        IntCellValue(value: final value) => value.toString(),
        DoubleCellValue(value: final value) => value.toString(),
        BoolCellValue(value: final value) => value.toString(),
        _ => '',
      };
      final minWidth = col == 0 ? 14.0 : 16.0;
      planningSheet.setColumnWidth(
        col,
        (headerText.length + 4).toDouble().clamp(minWidth, 40.0),
      );
    }
    planningSheet.setRowHeight(0, 30);
    planningSheet.setRowHeight(1, 28);
    planningSheet.setRowHeight(2, 24);
    planningSheet.setRowHeight(3, 24);
    planningSheet.setRowHeight(4, 24);

    for (var col = 0; col < header.length; col++) {
      final expenseCell = planningSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2),
      );
      final budgetCell = planningSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3),
      );
      final diffCell = planningSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 4),
      );
      final summaryCell = planningSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 5),
      );

      if (col == 0) {
        expenseCell.cellStyle = expenseFirstColStyle;
        budgetCell.cellStyle = budgetFirstColStyle;
        diffCell.cellStyle = diffFirstColStyle;
        summaryCell.value = TextCellValue('Spend/Budget %');
        summaryCell.cellStyle = summaryFirstColStyle;
      } else {
        expenseCell.cellStyle = expenseStyle;
        budgetCell.cellStyle = budgetStyle;
        diffCell.cellStyle = diffStyle;
        final expenseValue =
            (expenseCell.value as DoubleCellValue?)?.value ?? 0.0;
        final budgetValue = (budgetCell.value as DoubleCellValue?)?.value ?? 0.0;
        final ratio = budgetValue <= 0 ? 0.0 : (expenseValue / budgetValue);
        summaryCell.value = DoubleCellValue(ratio);
        summaryCell.cellStyle = summaryStyle;
      }
    }

    // Freeze panes is not exposed in excel ^4.0.6 API.
    // We keep strong header/title styling so first rows remain visually anchored.

    final bytes = Uint8List.fromList(excel.encode()!);
    final fileName =
        '${AppConstants.csvFileName}_planning_summary_${DateFormat('yyyy-MM').format(from)}.xlsx';
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

  static Future<void> shareFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    if (kIsWeb) return;
    await Share.shareXFiles(
      filePaths.map((p) => XFile(p)).toList(),
      subject: 'Osidori 2.0 Export',
    );
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

  static String _canonicalCategoryKey(String raw) {
    final noPrefix = raw.trim().replaceFirst(RegExp(r'^\d+\.\s*'), '');
    final noEmoji = noPrefix.replaceFirst(
      RegExp(r'^[^\p{L}\p{N}]+', unicode: true),
      '',
    );
    return noEmoji.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  static String _displayCategoryLabel(String raw) {
    final noPrefix = raw.trim().replaceFirst(RegExp(r'^\d+\.\s*'), '');
    final noEmoji = noPrefix.replaceFirst(
      RegExp(r'^[^\p{L}\p{N}]+', unicode: true),
      '',
    );
    return noEmoji.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
