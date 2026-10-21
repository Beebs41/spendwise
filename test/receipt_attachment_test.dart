import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';
import 'package:spendwise/features/transactions/bloc/transaction_cubit.dart';

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

  group('Receipt Attachment Tests', () {
    test('Can save and retrieve a transaction with receiptPath', () async {
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Shopping',
              icon: '🛍️',
              color: 0xFFFF8A5C,
              isIncome: const Value(false),
            ),
          );

      final txId = await repo.addTransaction(
        type: 'expense',
        amount: 89.99,
        categoryId: catId,
        date: DateTime(2026, 10, 20),
        note: 'Electronics store',
        receiptPath: '/data/user/0/com.spendwise/app_flutter/receipts/receipt_12345.jpg',
      );

      final all = await repo.getAllTransactions();
      expect(all.length, 1);
      expect(all.first.transaction.id, txId);
      expect(
        all.first.transaction.receiptPath,
        '/data/user/0/com.spendwise/app_flutter/receipts/receipt_12345.jpg',
      );
    });

    test('Can update receiptPath or remove receiptPath from transaction', () async {
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Dining',
              icon: '🍔',
              color: 0xFFFF6B6B,
              isIncome: const Value(false),
            ),
          );

      final txId = await repo.addTransaction(
        type: 'expense',
        amount: 35.50,
        categoryId: catId,
        date: DateTime(2026, 10, 20),
        receiptPath: '/path/to/old_receipt.jpg',
      );

      // Update with new receipt
      await repo.updateTransaction(
        id: txId,
        type: 'expense',
        amount: 35.50,
        categoryId: catId,
        date: DateTime(2026, 10, 20),
        receiptPath: '/path/to/new_receipt.jpg',
      );

      var txList = await repo.getAllTransactions();
      expect(txList.first.transaction.receiptPath, '/path/to/new_receipt.jpg');

      // Remove receipt (set to null)
      await repo.updateTransaction(
        id: txId,
        type: 'expense',
        amount: 35.50,
        categoryId: catId,
        date: DateTime(2026, 10, 20),
        receiptPath: null,
      );

      txList = await repo.getAllTransactions();
      expect(txList.first.transaction.receiptPath, isNull);
    });

    test('Backup export and restore preserves receiptPath', () async {
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Supplies',
              icon: '📦',
              color: 0xFF45B7D1,
              isIncome: const Value(false),
            ),
          );

      await repo.addTransaction(
        type: 'expense',
        amount: 150.00,
        categoryId: catId,
        date: DateTime(2026, 10, 15),
        receiptPath: '/storage/receipts/office_supplies.png',
      );

      final backup = await db.exportBackupPayload();
      final txData = (backup['data'] as Map<String, dynamic>)['transactions'] as List;
      expect(txData.first['receiptPath'], '/storage/receipts/office_supplies.png');

      // Create a new in-memory database and restore
      final freshDb = AppDatabase(NativeDatabase.memory());
      await freshDb.restoreBackupPayload(backup, wipeExisting: true);

      final restoredList = await freshDb.getAllTransactions();
      expect(restoredList.length, 1);
      expect(
        restoredList.first.transaction.receiptPath,
        '/storage/receipts/office_supplies.png',
      );
      await freshDb.close();
    });

    test('TransactionCubit addTransaction supports receiptPath', () async {
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Groceries',
              icon: '🛒',
              color: 0xFF2ECC71,
              isIncome: const Value(false),
            ),
          );

      final cubit = TransactionCubit(repo);

      await cubit.addTransaction(
        type: 'expense',
        amount: 45.0,
        categoryId: catId,
        date: DateTime.now(),
        receiptPath: '/local/path/receipt.jpg',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final all = await repo.getAllTransactions();
      expect(all.any((t) => t.transaction.receiptPath == '/local/path/receipt.jpg'), isTrue);

      await cubit.close();
    });
  });
}
