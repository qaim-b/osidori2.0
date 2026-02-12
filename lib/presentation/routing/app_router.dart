import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/accounts/accounts_screen.dart';
import '../screens/accounts/add_account_screen.dart';
import '../screens/app_shell.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/budget/category_transactions_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/onboarding/role_selection_screen.dart';
import '../screens/overview/overview_screen.dart';
import '../screens/settings/manage_goals_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/summary/set_budget_limit_screen.dart';
import '../screens/summary/summary_screen.dart';
import '../screens/transaction/add_transaction_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isAuthRoute) return '/login';

      if (isLoggedIn && isAuthRoute) {
        if (!user.hasRole) return '/onboarding';
        return '/';
      }

      if (isLoggedIn && !user.hasRole && !isOnboarding && !isAuthRoute) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const OverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/summary',
                builder: (context, state) => const SummaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budget',
                builder: (context, state) => const BudgetScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/accounts/add',
        builder: (context, state) => const AddAccountScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/goals',
        builder: (context, state) => const ManageGoalsScreen(),
      ),
      GoRoute(
        path: '/summary/set-budget',
        builder: (context, state) => const SetBudgetLimitScreen(),
      ),
      GoRoute(
        path: '/budget/category/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return CategoryTransactionsScreen(categoryId: categoryId);
        },
      ),
    ],
  );
});
