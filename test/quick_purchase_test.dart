import 'dart:io';
import 'dart:ui' as ui;

import 'package:couples_finance/core/utils/quick_categories.dart';
import 'package:couples_finance/data/repositories/receipt_scanner.dart';
import 'package:couples_finance/domain/entities/category_entity.dart';
import 'package:couples_finance/presentation/widgets/transaction/quick_purchase_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryEntity category(String id, String name, int number) => CategoryEntity(
  id: id,
  name: name,
  displayNumber: number,
  emoji: '🍳',
  type: 'expense',
  sortOrder: number,
  createdAt: DateTime(2026),
);

final categories = [
  category('food', 'Home Cooking', 12),
  category('dining', 'Dining Out', 19),
  category('snack', 'Snacking', 13),
  category('house', 'Household Goods', 15),
  category('train', 'Public Transport', 17),
  category('date', 'Dating', 18),
  category('meds', 'Meds', 32),
  category('family', 'Mami Aunty & Uncle Sadaqah', 43),
];

void main() {
  setUpAll(() async {
    // Use SDK fonts for readable local previews instead of the test-only Ahem font.
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root == null) return;
    for (final font in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final file = File(
        '$root/bin/cache/artifacts/material_fonts/${font.value}',
      );
      if (!await file.exists()) continue;
      final loader = FontLoader(font.key);
      loader.addFont(file.readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
  });
  test(
    'recent choices keep actual IDs, remove duplicates and ignore stale IDs',
    () {
      expect(
        quickCategories(categories, [
          'meds',
          'deleted',
          'food',
          'meds',
        ]).map((c) => c.id),
        ['meds', 'food', 'dining', 'snack', 'house', 'train'],
      );
    },
  );

  test(
    'receipt result preserves purchase date and refuses invalid totals/currency',
    () {
      final json = <String, dynamic>{
        'amount': 2480,
        'currency': 'JPY',
        'date': '2026-10-26',
        'merchant': 'OK Store',
        'category_id': 'food',
        'needs_review': false,
      };
      final scan = ReceiptScan.fromJson(json);
      expect(scan.date, DateTime(2026, 10, 26));
      expect(scan.amount, 2480);
      expect(scan.merchant, 'OK Store');
      expect(scan.needsReview, isFalse);
      expect(
        () => ReceiptScan.fromJson({...json, 'amount': -20}),
        throwsFormatException,
      );
      expect(
        () => ReceiptScan.fromJson({...json, 'currency': 'UNKNOWN'}),
        throwsFormatException,
      );
      expect(
        () => ReceiptScan.fromJson({...json, 'date': '2026-02-30'}),
        throwsFormatException,
      );
      expect(
        ReceiptScan.fromJson({...json}..remove('needs_review')).needsReview,
        isTrue,
      );
    },
  );

  Future<void> pumpForm(
    WidgetTester tester, {
    String? selected,
    required TextEditingController amount,
    required TextEditingController note,
    required VoidCallback save,
    double width = 360,
    double height = 640,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(scale),
          ),
          child: StatefulBuilder(
            builder: (context, setState) => RepaintBoundary(
              key: const Key('preview'),
              child: QuickPurchaseForm(
                categories: categories,
                recentIds: const [],
                selectedId: selected,
                onSelect: (id) => setState(() => selected = id),
                amountController: amount,
                noteController: note,
                date: DateTime(2026, 10, 27),
                currency: 'JPY',
                onDate: () {},
                onCurrency: () {},
                onSave: save,
                onCamera: () {},
                onGallery: () {},
                onAdvanced: () {},
                onClose: () {},
                onRetryCategories: () {},
                onCreateAccount: () {},
                loading: false,
                categoryError: false,
                accountLoading: false,
                hasAccount: true,
                saving: false,
                scanning: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/quick_purchase_previews');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('six categories then thumb keypad and save, preserving note', (
    tester,
  ) async {
    final amount = TextEditingController();
    final note = TextEditingController(text: 'OK Store');
    addTearDown(amount.dispose);
    addTearDown(note.dispose);
    var saved = 0;
    await pumpForm(tester, amount: amount, note: note, save: () => saved++);
    expect(find.text('Home Cooking'), findsOneWidget);
    expect(find.text('Meds'), findsNothing);
    await screenshot(tester, 'categories');
    await tester.tap(find.text('Home Cooking'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Enter amount'),
          )
          .onPressed,
      isNull,
    );
    for (final digit in ['2', '4', '8', '0']) {
      await tester.tap(find.widgetWithText(FilledButton, digit));
      await tester.pump();
    }
    expect(amount.text, '2480');
    await screenshot(tester, 'amount');
    await tester.tap(find.text('Save ¥2,480'));
    await tester.pump();
    expect(saved, 1);
    expect(note.text, 'OK Store');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all categories can be searched and selected without parent groups',
    (tester) async {
      final amount = TextEditingController();
      final note = TextEditingController();
      addTearDown(amount.dispose);
      addTearDown(note.dispose);
      await pumpForm(tester, amount: amount, note: note, save: () {});
      await tester.tap(find.text('All categories · search or scroll'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '32');
      await tester.pumpAndSettle();
      expect(find.text('Meds'), findsOneWidget);
      await tester.tap(find.text('Meds'));
      await tester.pumpAndSettle();
      expect(find.text('Category 32'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('narrow screen with larger text keeps keypad usable', (
    tester,
  ) async {
    final amount = TextEditingController(text: '2480');
    final note = TextEditingController();
    addTearDown(amount.dispose);
    addTearDown(note.dispose);
    await pumpForm(
      tester,
      selected: 'family',
      amount: amount,
      note: note,
      save: () {},
      width: 320,
      height: 568,
      scale: 1.3,
    );
    expect(find.text('Save ¥2,480'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
