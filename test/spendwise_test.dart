import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Add and fetch transaction', () async {
    // Add an initial category
    final catId = await db.insertCategory(
      CategoriesCompanion.insert(
        name: 'Dining',
        icon: '🍔',
        color: 0xFFFF6B6B,
      ),
    );

    // Add transaction
    await repository.addTransaction(
      type: 'expense',
      amount: 450.0,
      categoryId: catId,
      date: DateTime.now(),
      note: 'Dinner with friends',
    );

    // Watch transactions
    final list = await repository.watchRecentTransactions().first;
    expect(list.length, equals(1));
    expect(list.first.transaction.amount, equals(450.0));
    expect(list.first.category.name, equals('Dining'));
  });

  test('Savings goals deposits and progress calculation', () async {
    final goalId = await repository.addSavingsGoal(
      title: 'New Monitor',
      targetAmount: 30000,
      currentAmount: 10000,
      color: 0xFFF5A623,
    );

    await repository.updateSavingsAmount(goalId, 25000);

    final goals = await repository.watchSavingsGoals().first;
    final updated = goals.firstWhere((g) => g.id == goalId);
    expect(updated.currentAmount, equals(25000.0));
  });

  test('Debt creation, partial repayment and settlement', () async {
    // Add a lent debt
    final debtId = await repository.addDebt(
      DebtsCompanion.insert(
        personName: 'Alex Mercer',
        phoneNumber: const drift.Value('+15551234567'),
        type: 'lent',
        amount: 5000,
        dueDate: drift.Value(DateTime.now().add(const Duration(days: 14))),
        notes: const drift.Value('Lent for weekend gear'),
      ),
    );

    // Verify active debt created
    var activeDebts = await repository.watchActiveDebts().first;
    expect(activeDebts.length, equals(1));
    expect(activeDebts.first.personName, equals('Alex Mercer'));
    expect(activeDebts.first.amount, equals(5000.0));
    expect(activeDebts.first.settledAmount, equals(0.0));
    expect(activeDebts.first.isSettled, isFalse);

    // Record partial repayment of 2000
    await repository.recordDebtPayment(
      debtId: debtId,
      amount: 2000,
      paymentDate: DateTime.now(),
      note: 'UPI transfer 1',
    );

    // Verify settledAmount updated
    var debt = await db.getDebtById(debtId);
    expect(debt, isNotNull);
    expect(debt!.settledAmount, equals(2000.0));
    expect(debt.isSettled, isFalse);

    // Verify payment record exists
    final payments = await repository.watchPaymentsForDebt(debtId).first;
    expect(payments.length, equals(1));
    expect(payments.first.amount, equals(2000.0));

    // Record second payment of 3000 (total 5000 -> completes debt)
    await repository.recordDebtPayment(
      debtId: debtId,
      amount: 3000,
      paymentDate: DateTime.now(),
      note: 'UPI transfer 2',
    );

    debt = await db.getDebtById(debtId);
    expect(debt!.settledAmount, equals(5000.0));
    expect(debt.isSettled, isTrue);
    expect(debt.settledAt, isNotNull);

    // Active debts should now be empty
    activeDebts = await repository.watchActiveDebts().first;
    expect(activeDebts.isEmpty, isTrue);

    // All debts should still contain it in history
    final allDebts = await repository.watchAllDebts().first;
    expect(allDebts.length, equals(1));
    expect(allDebts.first.isSettled, isTrue);
  });
}

