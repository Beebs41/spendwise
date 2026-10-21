import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/currency_formatter.dart';
import '../../data/repositories/transaction_repository.dart';

/// Representation of the metrics displayed on the Android Home Screen Widget.
class WidgetData {
  final String todaySpend;
  final String budgetRemaining;
  final String budgetStatus;
  final String statusColor;
  final String lastUpdated;
  final String footerText;
  final double rawTodaySpend;
  final double rawBudgetRemaining;
  final double rawMonthBudget;

  const WidgetData({
    required this.todaySpend,
    required this.budgetRemaining,
    required this.budgetStatus,
    required this.statusColor,
    required this.lastUpdated,
    required this.footerText,
    required this.rawTodaySpend,
    required this.rawBudgetRemaining,
    required this.rawMonthBudget,
  });

  Map<String, dynamic> toMap() => {
        'todaySpend': todaySpend,
        'budgetRemaining': budgetRemaining,
        'budgetStatus': budgetStatus,
        'statusColor': statusColor,
        'lastUpdated': lastUpdated,
        'footerText': footerText,
      };
}

/// Service to calculate, synchronize, and handle actions for the
/// SpendWise Android Home Screen Widget.
class WidgetSyncService {
  WidgetSyncService._();

  static const MethodChannel channel = MethodChannel('com.shabeeb.spendwise/widget');

  static final StreamController<String> _actionController = StreamController<String>.broadcast();

  /// Stream of route actions triggered by widget interaction (e.g. '/add_transaction')
  static Stream<String> get onWidgetAction => _actionController.stream;

  static bool _initialized = false;

  /// Initializes listening for native widget broadcast actions.
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final route = call.arguments as String?;
        if (route != null && route.isNotEmpty) {
          _actionController.add(route);
        }
      }
    });
  }

  /// Checks if the app was launched from a widget action intent.
  static Future<String?> getInitialRoute() async {
    try {
      return await channel.invokeMethod<String>('getInitialRoute');
    } catch (_) {
      return null;
    }
  }

  /// Calculates the current widget data from database state.
  static Future<WidgetData> calculateWidgetData(
    TransactionRepository repository, [
    DateTime? testNow,
  ]) async {
    final now = testNow ?? DateTime.now();
    final settings = await repository.getUserSettings();
    final symbol = settings?.currencySymbol ?? CurrencyFormatter.activeSymbol;

    // Fetch month transactions
    final monthTxs = await repository.getTransactionsForMonth(now.year, now.month);

    double todayTotal = 0.0;
    double monthTotal = 0.0;

    for (final tx in monthTxs) {
      if (tx.transaction.type == 'expense') {
        monthTotal += tx.transaction.amount;
        final d = tx.transaction.date;
        if (d.year == now.year && d.month == now.month && d.day == now.day) {
          todayTotal += tx.transaction.amount;
        }
      }
    }

    // Fetch monthly budgets
    final budgets = await repository.getBudgetsForMonth(now.year, now.month);
    final totalBudget = budgets.fold<double>(0.0, (sum, b) => sum + b.budget.amount);

    final String budgetStatus;
    final String statusColor;
    final double remaining;
    final String footerText;

    if (totalBudget <= 0) {
      budgetStatus = 'No Budget';
      statusColor = '#94A3B8'; // slate grey
      remaining = 0;
      footerText = 'Set a monthly budget';
    } else {
      remaining = totalBudget - monthTotal;
      final pct = (monthTotal / totalBudget) * 100;

      if (monthTotal > totalBudget) {
        budgetStatus = 'Over Budget';
        statusColor = '#EF4444'; // crimson red
        footerText = '${(pct - 100).toStringAsFixed(0)}% over budget limit';
      } else if (monthTotal >= totalBudget * 0.8) {
        budgetStatus = 'Near Limit';
        statusColor = '#F59E0B'; // amber warning
        footerText = '${(100 - pct).toStringAsFixed(0)}% budget remaining';
      } else {
        budgetStatus = 'On Track';
        statusColor = '#10B981'; // emerald green
        footerText = '${(100 - pct).toStringAsFixed(0)}% budget remaining';
      }
    }

    final formattedToday = CurrencyFormatter.format(todayTotal, symbol: symbol);
    final formattedRemaining = totalBudget > 0
        ? CurrencyFormatter.format(remaining < 0 ? 0 : remaining, symbol: symbol)
        : 'Not Set';
    final updatedTime = DateFormat('HH:mm').format(now);

    return WidgetData(
      todaySpend: formattedToday,
      budgetRemaining: formattedRemaining,
      budgetStatus: budgetStatus,
      statusColor: statusColor,
      lastUpdated: updatedTime,
      footerText: footerText,
      rawTodaySpend: todayTotal,
      rawBudgetRemaining: remaining,
      rawMonthBudget: totalBudget,
    );
  }

  /// Calculates latest data and pushes it to the native Android AppWidget.
  static Future<bool> syncWidget(
    TransactionRepository repository, [
    DateTime? testNow,
  ]) async {
    try {
      final data = await calculateWidgetData(repository, testNow);
      final result = await channel.invokeMethod<bool>('updateWidget', data.toMap());
      return result ?? true;
    } catch (_) {
      // Graceful fallback on non-Android platforms or test environments
      return false;
    }
  }
}
