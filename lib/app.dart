import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/utils/currency_formatter.dart';
import 'data/database/app_database.dart';
import 'data/repositories/transaction_repository.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/transactions/screens/add_transaction_sheet.dart';
import 'features/budget/budget_screen.dart';
import 'features/savings/savings_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/security/lock_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'core/theme/app_colors.dart';
import 'features/budget/set_budget_sheet.dart';
import 'features/savings/add_savings_goal_sheet.dart';
import 'shared/widgets/speed_dial_fab.dart';

class MainShell extends StatefulWidget {
  final TransactionRepository repository;

  const MainShell({super.key, required this.repository});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() {
        _isUnlocked = false;
      });
    }
  }

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserSetting?>(
      stream: widget.repository.watchUserSettings(),
      builder: (context, userSnap) {
        final settings = userSnap.data;
        if (settings != null) {
          CurrencyFormatter.activeSymbol = settings.currencySymbol;
          CurrencyFormatter.activeCode = settings.currencyCode;
        }

        // First-Time Install Onboarding Gate
        if (settings != null && !settings.isOnboarded) {
          return OnboardingScreen(
            repository: widget.repository,
            onCompleted: () {
              setState(() {
                _isUnlocked = true;
              });
            },
          );
        }

        final isLockActive = settings != null &&
            settings.isLockEnabled &&
            settings.passcode != null &&
            settings.passcode!.isNotEmpty;

        if (isLockActive && !_isUnlocked) {
          return LockScreen(
            savedPasscode: settings.passcode,
            useBiometrics: settings.useBiometrics,
            onUnlocked: () {
              setState(() {
                _isUnlocked = true;
              });
            },
          );
        }

        final screens = [
          DashboardScreen(
            repository: widget.repository,
            onNavigateToTransactions: () => setState(() => _currentIndex = 1),
            onNavigateToBudget: () => setState(() => _currentIndex = 2),
          ),
          TransactionsScreen(repository: widget.repository),
          BudgetScreen(repository: widget.repository),
          SavingsScreen(repository: widget.repository),
          SettingsScreen(repository: widget.repository),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.pie_chart_rounded),
                label: 'Budgets',
              ),
              NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                selectedIcon: Icon(Icons.savings_rounded),
                label: 'Savings',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
          floatingActionButton: _currentIndex < 4
              ? SpeedDialFab(
                  actions: [
                    SpeedDialAction(
                      icon: Icons.trending_down_rounded,
                      label: 'Add Expense',
                      subtitle: 'Log daily spending',
                      color: AppColors.expense,
                      onTap: () => AddTransactionSheet.show(
                        context,
                        widget.repository,
                        initialType: 'expense',
                      ),
                    ),
                    SpeedDialAction(
                      icon: Icons.trending_up_rounded,
                      label: 'Add Income',
                      subtitle: 'Record earnings',
                      color: AppColors.income,
                      onTap: () => AddTransactionSheet.show(
                        context,
                        widget.repository,
                        initialType: 'income',
                      ),
                    ),
                    SpeedDialAction(
                      icon: Icons.pie_chart_rounded,
                      label: 'Set Budget',
                      subtitle: 'Monthly category limit',
                      color: const Color(0xFF3B82F6),
                      onTap: () => SetBudgetSheet.show(
                        context,
                        widget.repository,
                      ),
                    ),
                    SpeedDialAction(
                      icon: Icons.savings_rounded,
                      label: 'Savings Goal',
                      subtitle: 'Target a new milestone',
                      color: AppColors.darkPrimary,
                      onTap: () => AddSavingsGoalSheet.show(
                        context,
                        widget.repository,
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
