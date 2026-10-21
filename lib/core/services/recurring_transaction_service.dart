import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';

class RecurringTransactionService {
  /// Calculate the next due date based on the current due date and recurring frequency.
  static DateTime calculateNextDueDate(DateTime fromDate, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return DateTime(fromDate.year, fromDate.month, fromDate.day + 1, fromDate.hour, fromDate.minute);
      case 'weekly':
        return DateTime(fromDate.year, fromDate.month, fromDate.day + 7, fromDate.hour, fromDate.minute);
      case 'yearly':
        final isLeapFeb29 = fromDate.month == 2 && fromDate.day == 29;
        final targetYear = fromDate.year + 1;
        final targetDay = isLeapFeb29 ? 28 : fromDate.day;
        return DateTime(targetYear, fromDate.month, targetDay, fromDate.hour, fromDate.minute);
      case 'monthly':
      default:
        var year = fromDate.year;
        var month = fromDate.month + 1;
        if (month > 12) {
          year++;
          month = 1;
        }
        final daysInTargetMonth = DateTime(year, month + 1, 0).day;
        final day = fromDate.day > daysInTargetMonth ? daysInTargetMonth : fromDate.day;
        return DateTime(year, month, day, fromDate.hour, fromDate.minute);
    }
  }

  /// Scan for active recurring rules whose nextDueDate is on or before [now] and
  /// auto-generate corresponding transaction records up to the current date.
  /// Returns the number of transactions successfully created.
  static Future<int> checkAndGenerateDueTransactions(
    TransactionRepository repository, {
    DateTime? simulatedNow,
  }) async {
    final now = simulatedNow ?? DateTime.now();
    // End of the target day
    final cutoffDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final allRules = await repository.getAllRecurringTransactions();
    int generatedCount = 0;

    for (final item in allRules) {
      final rule = item.recurring;
      if (!rule.isActive) continue;

      var currentDue = rule.nextDueDate;
      DateTime? lastGenerated = rule.lastGeneratedDate;
      int iterations = 0;
      bool ruleChanged = false;

      while ((currentDue.isBefore(cutoffDate) || currentDue.isAtSameMomentAs(cutoffDate)) && iterations < 365) {
        iterations++;

        // Auto-generate transaction
        await repository.addTransaction(
          type: rule.type,
          amount: rule.amount,
          categoryId: rule.categoryId,
          date: currentDue,
          note: rule.note != null && rule.note!.trim().isNotEmpty
              ? '${rule.note!.trim()} • Recurring'
              : 'Recurring ${rule.frequency[0].toUpperCase()}${rule.frequency.substring(1)}',
          isRecurring: true,
          occasionId: rule.occasionId,
          receiptPath: rule.receiptPath,
        );

        lastGenerated = currentDue;
        currentDue = calculateNextDueDate(currentDue, rule.frequency);
        ruleChanged = true;
        generatedCount++;
      }

      if (ruleChanged) {
        await repository.updateRecurringTransaction(
          RecurringTransactionsCompanion(
            id: Value(rule.id),
            type: Value(rule.type),
            amount: Value(rule.amount),
            categoryId: Value(rule.categoryId),
            frequency: Value(rule.frequency),
            startDate: Value(rule.startDate),
            nextDueDate: Value(currentDue),
            lastGeneratedDate: Value(lastGenerated),
            note: Value(rule.note),
            isActive: Value(rule.isActive),
            occasionId: Value(rule.occasionId),
            receiptPath: Value(rule.receiptPath),
          ),
        );
      }
    }

    return generatedCount;
  }

  /// Helper to display user-friendly frequency label
  static String formatFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Every Day';
      case 'weekly':
        return 'Every Week';
      case 'yearly':
        return 'Every Year';
      case 'monthly':
      default:
        return 'Every Month';
    }
  }
}
