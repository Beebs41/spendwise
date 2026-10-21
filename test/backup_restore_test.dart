import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);

    // Seed test category
    final catId = await db.insertCategory(
      CategoriesCompanion.insert(
        name: 'Dining',
        icon: '🍔',
        color: 0xFFFF6B6B,
      ),
    );

    // Seed test occasion
    final occasionId = await repository.addOccasion(
      name: 'Kerala Trip',
      icon: '🌴',
      budget: 20000,
    );

    // Seed test transaction
    await repository.addTransaction(
      type: 'expense',
      amount: 1500,
      categoryId: catId,
      date: DateTime(2026, 10, 15),
      note: 'Dinner at beachfront cafe',
      occasionId: occasionId,
    );

    // Seed savings goal
    await repository.addSavingsGoal(
      title: 'Emergency Fund',
      targetAmount: 50000,
      currentAmount: 12000,
      color: 0xFF2ECC71,
    );

    // Seed debt
    final debtId = await repository.addDebt(
      DebtsCompanion.insert(
        personName: 'Rohan Sharma',
        type: 'lent',
        amount: 3000,
        notes: const Value('Camera rental share'),
      ),
    );

    await repository.recordDebtPayment(
      debtId: debtId,
      amount: 1000,
      note: 'First installment',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Export complete backup payload', () async {
    final payload = await repository.exportBackupPayload();

    expect(payload['app'], equals('SpendWise'));
    expect(payload['version'], equals(1));
    expect(payload['metadata'], isNotNull);
    expect(payload['data'], isNotNull);

    final data = payload['data'] as Map<String, dynamic>;
    final txList = data['transactions'] as List;
    final catList = data['categories'] as List;
    final goalList = data['savingsGoals'] as List;
    final debtList = data['debts'] as List;
    final paymentList = data['debtPayments'] as List;
    final occList = data['occasions'] as List;

    expect(txList.length, equals(1));
    expect(txList.first['amount'], equals(1500.0));
    expect(txList.first['note'], equals('Dinner at beachfront cafe'));

    expect(catList.isNotEmpty, isTrue);
    expect(goalList.length, equals(1));
    expect(goalList.first['title'], equals('Emergency Fund'));

    expect(debtList.length, equals(1));
    expect(debtList.first['personName'], equals('Rohan Sharma'));

    expect(paymentList.length, equals(1));
    expect(paymentList.first['amount'], equals(1000.0));

    expect(occList.length, equals(1));
    expect(occList.first['name'], equals('Kerala Trip'));
  });

  test('Full restore replaces database with backup state', () async {
    // 1. Export initial backup
    final backup = await repository.exportBackupPayload();

    // 2. Modify database (add new records, delete original)
    final newCatId = await db.insertCategory(
      CategoriesCompanion.insert(
        name: 'Temporary Category',
        icon: '🗑️',
        color: 0xFF888888,
      ),
    );

    await repository.addTransaction(
      type: 'expense',
      amount: 9999,
      categoryId: newCatId,
      date: DateTime.now(),
      note: 'Temporary transaction to be overwritten',
    );

    var currentTx = await repository.getAllTransactions();
    expect(currentTx.length, equals(2));

    // 3. Restore from backup with wipeExisting: true
    await repository.restoreBackupPayload(backup, wipeExisting: true);

    // 4. Verify restored state matches the backup exactly
    currentTx = await repository.getAllTransactions();
    expect(currentTx.length, equals(1));
    expect(currentTx.first.transaction.amount, equals(1500.0));
    expect(currentTx.first.transaction.note, equals('Dinner at beachfront cafe'));

    final goals = await repository.watchSavingsGoals().first;
    expect(goals.length, equals(1));
    expect(goals.first.title, equals('Emergency Fund'));
    expect(goals.first.currentAmount, equals(12000.0));

    final debts = await repository.watchAllDebts().first;
    expect(debts.length, equals(1));
    expect(debts.first.personName, equals('Rohan Sharma'));
  });
}
