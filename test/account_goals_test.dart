import 'package:couples_finance/data/models/account_model.dart';
import 'package:couples_finance/data/models/goal_model.dart';
import 'package:couples_finance/data/repositories/account_repository.dart';
import 'package:couples_finance/data/repositories/goal_repository.dart';
import 'package:couples_finance/domain/enums/account_type.dart';
import 'package:couples_finance/domain/enums/owner_scope.dart';
import 'package:couples_finance/presentation/providers/account_provider.dart';
import 'package:couples_finance/presentation/providers/goal_provider.dart';
import 'package:couples_finance/presentation/screens/accounts/accounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AccountModel account(String name, double balance) => AccountModel(
  id: name,
  name: name,
  type: AccountType.values.first,
  ownerScope: OwnerScope.personal,
  ownerUserId: 'test-user',
  currency: 'JPY',
  initialBalance: balance,
  createdAt: DateTime(2026),
);

GoalModel goal(String name, double target) => GoalModel(
  id: name,
  name: name,
  emoji: '',
  userId: 'test-user',
  targetAmount: target,
  currentAmount: 1,
  createdAt: DateTime(2026),
);

class TestAccounts extends AccountsNotifier {
  TestAccounts(List<AccountModel> accounts)
    : super(AccountRepository(), null, [], [], 'JPY') {
    replace(accounts);
  }
  void replace(List<AccountModel> accounts) =>
      state = AsyncValue.data(accounts);
  void fail() =>
      state = AsyncValue.error(StateError('Unavailable'), StackTrace.current);
}

class TestGoals extends GoalsNotifier {
  TestGoals(List<GoalModel> goals) : super(GoalRepository(), null) {
    state = AsyncValue.data(goals);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://account-tests.invalid',
      anonKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  test(
    'all goals follow account total as balances change; targets stay unchanged',
    () {
      final accounts = TestAccounts([
        account('Bank', 5000),
        account('Cash', 2000),
        account('PayPay', 0),
        account('Card', -500),
      ]);
      final container = ProviderContainer(
        overrides: [
          accountsProvider.overrideWith((ref) => accounts),
          goalsProvider.overrideWith(
            (ref) =>
                TestGoals([goal('Savings', 40000000), goal('Trip', 10000)]),
          ),
        ],
      );
      addTearDown(container.dispose);
      var goals = container.read(accountLinkedGoalsProvider).requireValue;
      expect(goals.map((g) => g.currentAmount), [6500, 6500]);
      expect(goals.map((g) => g.targetAmount), [40000000, 10000]);
      expect(goals.last.isCompleted, isFalse);
      accounts.replace([account('Bank', 15000)]);
      goals = container.read(accountLinkedGoalsProvider).requireValue;
      expect(goals.map((g) => g.currentAmount), [15000, 15000]);
      expect(goals.first.isCompleted, isFalse);
      expect(goals.last.isCompleted, isTrue);
      expect(
        container.read(goalsProvider).requireValue.first.currentAmount,
        1,
        reason:
            'Derived progress must not overwrite stored targets or goal data',
      );
    },
  );

  test(
    'zero balances are hidden without dropping debts or underlying accounts',
    () {
      final container = ProviderContainer(
        overrides: [
          accountsProvider.overrideWith(
            (ref) => TestAccounts([
              account('Bank', 5000),
              account('PayPay', 0),
              account('Rakuten Pay', 0),
              account('Card', -100),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(fundedAccountsProvider).requireValue.map((a) => a.name),
        ['Bank', 'Card'],
      );
      expect(container.read(accountsProvider).requireValue.length, 4);
      expect(container.read(accountsTotalProvider).requireValue, 4900);
    },
  );

  test('account failures do not turn goal progress into a false zero', () {
    final accounts = TestAccounts([account('Bank', 5000)]);
    final container = ProviderContainer(
      overrides: [
        accountsProvider.overrideWith((ref) => accounts),
        goalsProvider.overrideWith(
          (ref) => TestGoals([goal('Savings', 40000000)]),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container
          .read(accountLinkedGoalsProvider)
          .requireValue
          .first
          .currentAmount,
      5000,
    );
    accounts.fail();
    expect(container.read(accountLinkedGoalsProvider).hasError, isTrue);
  });

  testWidgets('Accounts hides empty wallets and the eye button restores them', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith(
            (ref) =>
                TestAccounts([account('Bank', 5000), account('PayPay', 0)]),
          ),
        ],
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('PayPay'), findsNothing);
    await tester.tap(find.byTooltip('Show zero-balance accounts'));
    await tester.pumpAndSettle();
    expect(find.text('PayPay'), findsOneWidget);
    await tester.tap(find.byTooltip('Hide zero-balance accounts'));
    await tester.pumpAndSettle();
    expect(find.text('PayPay'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
