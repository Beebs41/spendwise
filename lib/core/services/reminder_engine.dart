import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import 'notification_service.dart';

class ReminderEngine {
  /// Evaluates budget alerts when a transaction is added/updated for a category.
  static Future<void> checkBudgetAlerts({
    required TransactionRepository repository,
    required int categoryId,
    required double currentSpend,
    required double budgetAmount,
    required String categoryName,
    required String currencySymbol,
    DateTime? simulatedNow,
  }) async {
    if (budgetAmount <= 0) return;

    final settings = await repository.getUserSettings();
    if (settings != null && !settings.enableBudgetAlerts) return;

    final now = simulatedNow ?? DateTime.now();
    final percentage = (currentSpend / budgetAmount) * 100;

    String? type;
    String? payload;
    String? title;
    String? message;
    String icon = '🔔';

    if (percentage >= 100) {
      type = 'budget_exceeded';
      payload = 'budget_${categoryId}_${now.year}_${now.month}_100';
      title = '⚠️ Budget Exceeded: $categoryName';
      message =
          'You have spent $currencySymbol${currentSpend.toStringAsFixed(0)} of your $currencySymbol${budgetAmount.toStringAsFixed(0)} budget (${percentage.toStringAsFixed(0)}%).';
      icon = '⚠️';
    } else if (percentage >= 80) {
      type = 'budget_warning';
      payload = 'budget_${categoryId}_${now.year}_${now.month}_80';
      title = '⚡ Budget Warning: $categoryName';
      message =
          'You have reached ${percentage.toStringAsFixed(0)}% ($currencySymbol${currentSpend.toStringAsFixed(0)}) of your $currencySymbol${budgetAmount.toStringAsFixed(0)} budget.';
      icon = '⚡';
    }

    if (type != null && payload != null && title != null && message != null) {
      // Check if already notified for this threshold this month
      final all = await repository.getAllNotifications();
      final alreadyNotified = all.any((n) => n.payload == payload);
      if (alreadyNotified) return;

      await repository.addNotification(
        type: type,
        title: title,
        message: message,
        icon: icon,
        payload: payload,
      );

      await NotificationService.instance.showNotification(
        id: ('$categoryId$type'.hashCode & 0x7FFFFFFF),
        title: title,
        body: message,
        payload: payload,
      );
    }
  }

  /// Evaluates milestone celebrations when a savings goal is created or updated.
  static Future<void> checkSavingsMilestones({
    required TransactionRepository repository,
    required SavingsGoal goal,
    required String currencySymbol,
  }) async {
    if (goal.targetAmount <= 0) return;

    final settings = await repository.getUserSettings();
    if (settings != null && !settings.enableSavingsAlerts) return;

    final percentage = (goal.currentAmount / goal.targetAmount) * 100;

    String? type;
    String? payload;
    String? title;
    String? message;
    String icon = '🎉';

    if (percentage >= 100) {
      type = 'goal_completed';
      payload = 'goal_${goal.id}_100';
      title = '🎉 Goal Completed: ${goal.title}!';
      message =
          'Fantastic achievement! You reached 100% of your savings goal for "${goal.title}" ($currencySymbol${goal.targetAmount.toStringAsFixed(0)}).';
      icon = '🎉';
    } else if (percentage >= 80) {
      type = 'goal_milestone';
      payload = 'goal_${goal.id}_80';
      title = '🔥 Almost There: ${goal.title}!';
      message =
          'You are at 80% ($currencySymbol${goal.currentAmount.toStringAsFixed(0)}) of your savings goal for "${goal.title}"!';
      icon = '🔥';
    } else if (percentage >= 50) {
      type = 'goal_milestone';
      payload = 'goal_${goal.id}_50';
      title = '🎯 Halfway There: ${goal.title}!';
      message =
          'You have reached 50% ($currencySymbol${goal.currentAmount.toStringAsFixed(0)}) of your savings goal for "${goal.title}"!';
      icon = '🎯';
    }

    if (type != null && payload != null && title != null && message != null) {
      final all = await repository.getAllNotifications();
      final alreadyNotified = all.any((n) => n.payload == payload);
      if (alreadyNotified) return;

      await repository.addNotification(
        type: type,
        title: title,
        message: message,
        icon: icon,
        payload: payload,
      );

      await NotificationService.instance.showNotification(
        id: ('${goal.id}$type'.hashCode & 0x7FFFFFFF),
        title: title,
        body: message,
        payload: payload,
      );
    }
  }

  /// Evaluates unsettled debts for due date reminders (due today or in 1-3 days).
  static Future<int> checkDueDebts({
    required TransactionRepository repository,
    required String currencySymbol,
    DateTime? simulatedNow,
  }) async {
    final settings = await repository.getUserSettings();
    if (settings != null && !settings.enableDebtReminders) return 0;

    final now = simulatedNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final allDebts = await repository.getAllDebts();
    final unsettledDebts = allDebts.where((d) => !d.isSettled && d.dueDate != null).toList();

    int sentCount = 0;
    final allNotifications = await repository.getAllNotifications();

    for (final debt in unsettledDebts) {
      final due = debt.dueDate!;
      final dueDateOnly = DateTime(due.year, due.month, due.day);
      final differenceInDays = dueDateOnly.difference(today).inDays;

      final remaining = (debt.amount - debt.settledAmount).clamp(0.0, double.infinity);
      if (remaining <= 0) continue;

      String? type;
      String? payload;
      String? title;
      String? message;
      String icon = '⏰';

      if (differenceInDays == 0) {
        type = 'debt_due';
        payload = 'debt_${debt.id}_${today.year}_${today.month}_${today.day}_today';
        title = debt.type == 'borrowed'
            ? '⏰ Debt Due Today: ${debt.personName}'
            : '⏰ Collection Due Today: ${debt.personName}';
        message = debt.type == 'borrowed'
            ? 'Payment of $currencySymbol${remaining.toStringAsFixed(0)} to ${debt.personName} is due today.'
            : '${debt.personName} is scheduled to pay you $currencySymbol${remaining.toStringAsFixed(0)} today.';
        icon = '⏰';
      } else if (differenceInDays > 0 && differenceInDays <= 3) {
        type = 'debt_due';
        payload = 'debt_${debt.id}_${today.year}_${today.month}_${today.day}_in_$differenceInDays';
        title = debt.type == 'borrowed'
            ? '📅 Upcoming Debt Payment'
            : '📅 Upcoming Debt Collection';
        message =
            'Payment of $currencySymbol${remaining.toStringAsFixed(0)} for ${debt.personName} is due in $differenceInDays day${differenceInDays > 1 ? "s" : ""}.';
        icon = '📅';
      }

      if (type != null && payload != null && title != null && message != null) {
        final alreadyNotified = allNotifications.any((n) => n.payload == payload);
        if (alreadyNotified) continue;

        await repository.addNotification(
          type: type,
          title: title,
          message: message,
          icon: icon,
          payload: payload,
        );

        await NotificationService.instance.showNotification(
          id: ('${debt.id}$payload'.hashCode & 0x7FFFFFFF),
          title: title,
          body: message,
          payload: payload,
        );

        sentCount++;
      }
    }

    return sentCount;
  }

  /// Sends a summary notification when recurring transactions are automatically generated.
  static Future<void> notifyRecurringGenerated({
    required TransactionRepository repository,
    required int count,
    DateTime? simulatedNow,
  }) async {
    if (count <= 0) return;

    final now = simulatedNow ?? DateTime.now();
    final payload = 'recurring_${now.year}_${now.month}_${now.day}_${now.hour}_$count';

    final title = '🔄 Scheduled Transactions Processed';
    final message =
        'SpendWise auto-generated $count scheduled transaction${count > 1 ? "s" : ""}.';

    await repository.addNotification(
      type: 'recurring',
      title: title,
      message: message,
      icon: '🔄',
      payload: payload,
    );

    await NotificationService.instance.showNotification(
      id: (payload.hashCode & 0x7FFFFFFF),
      title: title,
      body: message,
      payload: payload,
    );
  }
}
