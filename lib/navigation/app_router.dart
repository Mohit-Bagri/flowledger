import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/income/income_screen.dart';
import '../presentation/screens/expenses/expenses_screen.dart';
import '../presentation/screens/insights/insights_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/bank_accounts_screen.dart';
import '../presentation/screens/settings/payment_methods_screen.dart';
import '../presentation/screens/settings/categories_screen.dart';
import '../presentation/screens/settings/merchants_screen.dart';
import '../presentation/screens/settings/budgets_screen.dart';
import '../presentation/screens/settings/goals_screen.dart';
import '../presentation/screens/settings/recurring_transactions_screen.dart';
import '../presentation/screens/settings/notification_settings_screen.dart';
import '../presentation/screens/settings/export_screen.dart';
import '../presentation/screens/settings/cloud_sync_screen.dart';
import '../presentation/screens/settings/currency_screen.dart';
import '../presentation/screens/settings/language_screen.dart';
import '../presentation/screens/settings/profile_screen.dart';
import '../presentation/screens/settings/change_email_screen.dart';
import '../presentation/screens/settings/subscription_screen.dart';
import '../presentation/screens/settings/csv_import_screen.dart';
import '../presentation/screens/settings/about_screen.dart';
import '../presentation/screens/paywall/paywall_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/reset_password_screen.dart';
import '../presentation/screens/settings/email_change_confirmed_screen.dart';
import '../presentation/widgets/common/main_scaffold.dart';

/// Custom page transition for tab navigation (fade + scale)
CustomTransitionPage<void> _buildTabTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade + subtle scale for smooth tab switching
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

/// Custom page transition for push navigation (slide + fade)
CustomTransitionPage<void> _buildSlideTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Slide from right + fade for push navigation
      const begin = Offset(0.08, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: Curves.easeOutCubic),
      );
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: CurveTween(curve: Curves.easeOut).animate(animation),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// App Routes
class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String income = '/income';
  static const String expenses = '/expenses';
  static const String insights = '/insights';
  static const String settings = '/settings';
  static const String addIncome = '/add-income';
  static const String addExpense = '/add-expense';
  static const String bankAccounts = '/settings/bank-accounts';
  static const String paymentMethods = '/settings/payment-methods';
  static const String budgets = '/settings/budgets';
  static const String goals = '/settings/goals';
  static const String recurring = '/settings/recurring';
  static const String categories = '/settings/categories';
  static const String merchants = '/settings/merchants';
  static const String notifications = '/settings/notifications';
  static const String export = '/settings/export';
  static const String cloudSync = '/settings/cloud-sync';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String emailChangeConfirmed = '/email-change-confirmed';

  // New settings routes
  static const String currency = '/settings/currency';
  static const String language = '/settings/language';
  static const String profile = '/settings/profile';
  static const String changeEmail = '/settings/change-email';
  static const String subscription = '/settings/subscription';
  static const String csvImport = '/settings/csv-import';
  static const String about = '/settings/about';
  static const String paywall = '/paywall';
}

/// Navigation Keys
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// App Router Configuration
class AppRouter {
  static GoRouter router({bool showOnboarding = false}) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: showOnboarding ? AppRoutes.onboarding : AppRoutes.home,
      routes: [
        // Redirect /home to /
        GoRoute(
          path: '/home',
          redirect: (context, state) => '/',
        ),

        // Onboarding Route
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),

        // Main App with Bottom Navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainScaffold(child: child);
          },
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) => _buildTabTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.income,
              pageBuilder: (context, state) => _buildTabTransitionPage(
                key: state.pageKey,
                child: const IncomeScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.expenses,
              pageBuilder: (context, state) => _buildTabTransitionPage(
                key: state.pageKey,
                child: const ExpensesScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.insights,
              pageBuilder: (context, state) => _buildTabTransitionPage(
                key: state.pageKey,
                child: const InsightsScreen(),
              ),
            ),
          ],
        ),

        // Settings Route (outside shell)
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
        ),

        // Bank Accounts Route
        GoRoute(
          path: AppRoutes.bankAccounts,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const BankAccountsScreen(),
          ),
        ),

        // Payment Methods Route
        GoRoute(
          path: AppRoutes.paymentMethods,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const PaymentMethodsScreen(),
          ),
        ),

        // Budgets Route
        GoRoute(
          path: AppRoutes.budgets,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const BudgetsScreen(),
          ),
        ),

        // Goals Route
        GoRoute(
          path: AppRoutes.goals,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const GoalsScreen(),
          ),
        ),

        // Recurring Transactions Route
        GoRoute(
          path: AppRoutes.recurring,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const RecurringTransactionsScreen(),
          ),
        ),

        // Categories Route
        GoRoute(
          path: AppRoutes.categories,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const CategoriesScreen(),
          ),
        ),

        // Merchants Route
        GoRoute(
          path: AppRoutes.merchants,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const MerchantsScreen(),
          ),
        ),

        // Notification Settings Route
        GoRoute(
          path: AppRoutes.notifications,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const NotificationSettingsScreen(),
          ),
        ),

        // Export Route
        GoRoute(
          path: AppRoutes.export,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const ExportScreen(),
          ),
        ),

        // CSV Import Route
        GoRoute(
          path: AppRoutes.csvImport,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const CsvImportScreen(),
          ),
        ),

        // About Route
        GoRoute(
          path: AppRoutes.about,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const AboutScreen(),
          ),
        ),

        // Cloud Sync Route
        GoRoute(
          path: AppRoutes.cloudSync,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const CloudSyncScreen(),
          ),
        ),

        // Currency Route
        GoRoute(
          path: AppRoutes.currency,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const CurrencyScreen(),
          ),
        ),

        // Language Route
        GoRoute(
          path: AppRoutes.language,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const LanguageScreen(),
          ),
        ),

        // Profile Route
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const ProfileScreen(),
          ),
        ),

        // Change Email Route
        GoRoute(
          path: AppRoutes.changeEmail,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const ChangeEmailScreen(),
          ),
        ),

        // Subscription Route
        GoRoute(
          path: AppRoutes.subscription,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const SubscriptionScreen(),
          ),
        ),

        // Paywall Route
        GoRoute(
          path: AppRoutes.paywall,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const PaywallScreen(),
          ),
        ),

        // Auth Routes
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.signup,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const SignUpScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const ForgotPasswordScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const ResetPasswordScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.emailChangeConfirmed,
          pageBuilder: (context, state) => _buildSlideTransitionPage(
            key: state.pageKey,
            child: const EmailChangeConfirmedScreen(),
          ),
        ),
      ],
    );
  }
}
