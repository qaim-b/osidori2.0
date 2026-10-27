import 'package:couples_finance/core/utils/purchase_amount.dart';
import 'package:couples_finance/data/models/transaction_model.dart';
import 'package:couples_finance/data/repositories/transaction_repository.dart';
import 'package:couples_finance/domain/enums/transaction_type.dart';
import 'package:couples_finance/domain/enums/visibility_type.dart';
import 'package:couples_finance/presentation/providers/transaction_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaptureRepository extends TransactionRepository {
  TransactionModel? saved;
  @override
  Future<TransactionModel> create(TransactionModel txn) async {
    saved = txn;
    return txn;
  }
}

class CaptureNotifier extends TransactionsNotifier {
  CaptureNotifier(TransactionRepository repo, String? userId)
    : super(repo, userId, DateTime(2026, 10), [], 'JPY', 'accounting');
  @override
  Future<void> load() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://receipt-tests.invalid',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  test('purchase totals respect currency precision without rounding', () {
    expect(isValidPurchaseAmount(2480, 'JPY'), isTrue);
    expect(isValidPurchaseAmount(24.80, 'MYR'), isTrue);
    for (final amount in [0.0, -1.0, double.nan, double.infinity, 1e13]) {
      expect(isValidPurchaseAmount(amount, 'JPY'), isFalse);
    }
    expect(isValidPurchaseAmount(2480.5, 'JPY'), isFalse);
    expect(isValidPurchaseAmount(24.805, 'MYR'), isFalse);
    expect(isValidPurchaseAmount(10, 'UNKNOWN'), isFalse);
  });

  Future<void> save(CaptureNotifier notifier, {double amount = 2480}) =>
      notifier.addTransaction(
        type: TransactionType.expense,
        amount: amount,
        currency: 'JPY',
        date: DateTime(2026, 10, 26),
        categoryId: 'home-cooking-id',
        categoryNameSnapshot: 'Home Cooking',
        categoryDisplayNumberSnapshot: 12,
        fromAccountId: 'account-id',
        note: 'OK Store',
        visibility: VisibilityType.personal,
      );

  test('expired session cannot report a successful save', () async {
    final repository = CaptureRepository();
    final notifier = CaptureNotifier(repository, null);
    addTearDown(notifier.dispose);
    await expectLater(save(notifier), throwsStateError);
    expect(repository.saved, isNull);
  });

  test(
    'capture preserves exact amount, purchase date, Excel category and store note',
    () async {
      final repository = CaptureRepository();
      final notifier = CaptureNotifier(repository, 'test-user');
      addTearDown(notifier.dispose);
      await save(notifier);
      final payload = repository.saved!.toJson();
      expect(payload['amount'], 2480);
      expect(payload['date'], DateTime(2026, 10, 26).toIso8601String());
      expect(payload['category_id'], 'home-cooking-id');
      expect(payload['category_display_number_snapshot'], 12);
      expect(payload['note'], 'OK Store');
      expect(payload['from_account_id'], 'account-id');
      expect(payload['owner_user_id'], 'test-user');
    },
  );

  test('invalid precision never reaches the transaction repository', () async {
    final repository = CaptureRepository();
    final notifier = CaptureNotifier(repository, 'test-user');
    addTearDown(notifier.dispose);
    await expectLater(save(notifier, amount: 2480.5), throwsArgumentError);
    expect(repository.saved, isNull);
  });
}
