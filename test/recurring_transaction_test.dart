import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/core/services/recurring_transaction_service.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RecurringTransactionService - Date Calculations', () {
    test('calculateNextDueDate computes correct daily date', () {
      final start = DateTime(2026, 10, 1);
      final next = RecurringTransactionService.calculateNextDueDate(start, 'daily');
      expect(next, DateTime(2026, 10, 2));
    });

    test('calculateNextDueDate computes correct weekly date', () {
      final start = DateTime(2026, 10, 1);
      final next = RecurringTransactionService.calculateNextDueDate(start, 'weekly');
      expect(next, DateTime(2026, 10, 8));
    });

    test('calculateNextDueDate computes correct monthly date and clamps month end', () {
      final start = DateTime(2026, 1, 31);
      final next = RecurringTransactionService.calculateNextDueDate(start, 'monthly');
      // 2026 is not a leap year, Feb has 28 days
      expect(next, DateTime(2026, 2, 28));

      final startDec = DateTime(2026, 12, 15);
      final nextYear = RecurringTransactionService.calculateNextDueDate(startDec, 'monthly');
      expect(nextYear, DateTime(2027, 1, 15));
    });

    test('calculateNextDueDate computes correct yearly date', () {
      final start = DateTime(2026, 5, 20);
      final next = RecurringTransactionService.calculateNextDueDate(start, 'yearly');
      expect(next, DateTime(2027, 5, 20));
    });
  });

  group('Recurring Transactions - Database & Auto-generation', () {
    test('Auto-generates transactions for past due recurring rules', () async {
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Subscriptions',
              icon: '📺',
              color: 0xFFA855F7,
              isIncome: const Value(false),
            ),
          );

      // Rule created with due date 14 days ago, weekly frequency
      final startDate = DateTime(2026, 10, 1);
      final dueDate = DateTime(2026, 10, 1);

      await repo.addRecurringTransaction(
        type: 'expense',
        amount: 499.0,
        categoryId: catId,
        frequency: 'weekly',
        startDate: startDate,
        nextDueDate: dueDate,
        note: 'Streaming Service',
      );

      // Simulate running on 2026-10-16 (should generate 10/01, 10/08, 10/15 -> 3 transactions)
      final generated = await RecurringTransactionService.checkAndGenerateDueTransactions(
        repo,
        simulatedNow: DateTime(2026, 10, 16),
      );

      expect(generated, 3);

      final txList = await repo.getAllTransactions();
      expect(txList.length, 3);
      for (final tx in txList) {
        expect(tx.transaction.isRecurring, isTrue);
        expect(tx.transaction.amount, 499.0);
        expect(tx.transaction.note, contains('Streaming Service'));
      }

      // Check updated rule state
      final rules = await repo.getAllRecurringTransactions();
      expect(rules.first.recurring.nextDueDate, DateTime(2026, 10, 22));
      expect(rules.first.recurring.lastGeneratedDate, DateTime(2026, 10, 15));
    });

    test('Does not generate transactions if nextDueDate is in the future', () async {
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Rent',
              icon: '🏠',
              color: 0xFFF5A623,
              isIncome: const Value(false),
            ),
          );

      final futureDate = DateTime(2026, 11, 1);

      await repo.addRecurringTransaction(
        type: 'expense',
        amount: 15000.0,
        categoryId: catId,
        frequency: 'monthly',
        startDate: DateTime(2026, 10, 1),
        nextDueDate: futureDate,
        note: 'Apartment Rent',
      );

      final generated = await RecurringTransactionService.checkAndGenerateDueTransactions(
        repo,
        simulatedNow: DateTime(2026, 10, 20),
      );

      expect(generated, 0);

      final txList = await repo.getAllTransactions();
      expect(txList.isEmpty, isTrue);
    });

    test('Ignores paused recurring rules', () async {
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Gym',
              icon: '💪',
              color: 0xFF2ECC71,
              isIncome: const Value(false),
            ),
          );

      final ruleId = await repo.addRecurringTransaction(
        type: 'expense',
        amount: 1200.0,
        categoryId: catId,
        frequency: 'monthly',
        startDate: DateTime(2026, 9, 1),
        nextDueDate: DateTime(2026, 9, 1),
        isActive: false, // Paused
      );

      final generated = await RecurringTransactionService.checkAndGenerateDueTransactions(
        repo,
        simulatedNow: DateTime(2026, 10, 20),
      );

      expect(generated, 0);

      // Now resume rule
      await repo.toggleRecurringActive(ruleId, true);

      final generatedAfterResume = await RecurringTransactionService.checkAndGenerateDueTransactions(
        repo,
        simulatedNow: DateTime(2026, 10, 20),
      );

      expect(generatedAfterResume, 2); // 09/01 and 10/01
    });

    test('Recurring rules are exported and restored in database backups', () async {
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Salary',
              icon: '💰',
              color: 0xFF2ECC71,
              isIncome: const Value(true),
            ),
          );

      await repo.addRecurringTransaction(
        type: 'income',
        amount: 80000.0,
        categoryId: catId,
        frequency: 'monthly',
        startDate: DateTime(2026, 1, 1),
        nextDueDate: DateTime(2026, 11, 1),
        note: 'Monthly salary credit',
      );

      final backup = await repo.exportBackupPayload();
      final data = backup['data'] as Map<String, dynamic>;
      expect(data['recurringTransactions'], isNotEmpty);

      // Restore into fresh db
      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRepo = TransactionRepository(freshDb);

      await freshRepo.restoreBackupPayload(backup, wipeExisting: true);

      final restoredRules = await freshRepo.getAllRecurringTransactions();
      expect(restoredRules.length, 1);
      expect(restoredRules.first.recurring.amount, 80000.0);
      expect(restoredRules.first.recurring.frequency, 'monthly');
      expect(restoredRules.first.recurring.note, 'Monthly salary credit');

      await freshDb.close();
    });
  });
}
