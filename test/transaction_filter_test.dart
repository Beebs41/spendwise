import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';
import 'package:spendwise/features/transactions/bloc/transaction_cubit.dart';
import 'package:spendwise/features/transactions/models/transaction_filter.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repository;
  late TransactionCubit cubit;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);

    // Seed test categories
    final foodCatId = await db.insertCategory(
      CategoriesCompanion.insert(
        name: 'Dining',
        icon: '🍔',
        color: 0xFFFF6B6B,
      ),
    );
    final shoppingCatId = await db.insertCategory(
      CategoriesCompanion.insert(
        name: 'Electronics',
        icon: '💻',
        color: 0xFF3B82F6,
      ),
    );
    final salaryCatId = await db.insertCategory(
      CategoriesCompanion.insert(
        name: 'Salary',
        icon: '💰',
        color: 0xFF2ECC71,
        isIncome: const Value(true),
      ),
    );

    // Seed test occasion
    final occasionId = await repository.addOccasion(
      name: 'Goa Holiday',
      icon: '🏖️',
      budget: 15000,
    );

    final now = DateTime.now();

    // 1. Food Expense in Goa
    await repository.addTransaction(
      type: 'expense',
      amount: 1200,
      categoryId: foodCatId,
      date: now,
      note: 'Seafood dinner on beach',
      occasionId: occasionId,
    );

    // 2. Shopping Expense without occasion
    await repository.addTransaction(
      type: 'expense',
      amount: 4500,
      categoryId: shoppingCatId,
      date: now.subtract(const Duration(days: 2)),
      note: 'Wireless headphones',
    );

    // 3. Salary Income
    await repository.addTransaction(
      type: 'income',
      amount: 50000,
      categoryId: salaryCatId,
      date: now.subtract(const Duration(days: 5)),
      note: 'Monthly salary payout',
    );

    cubit = TransactionCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  test('Initial state loads all transactions for current month', () async {
    // Wait for streams to populate
    await Future.delayed(const Duration(milliseconds: 100));
    expect(cubit.state.allTransactions.length, equals(3));
    expect(cubit.state.filteredTransactions.length, equals(3));
    expect(cubit.state.totalIncome, equals(50000.0));
    expect(cubit.state.totalExpense, equals(5700.0));
    expect(cubit.state.netBalance, equals(44300.0));
  });

  test('Filter by transaction type expense', () async {
    await Future.delayed(const Duration(milliseconds: 100));
    cubit.setFilterType('expense');

    expect(cubit.state.filteredTransactions.length, equals(2));
    expect(cubit.state.filteredTransactions.every((t) => t.transaction.type == 'expense'), isTrue);
  });

  test('Filter by transaction type income', () async {
    await Future.delayed(const Duration(milliseconds: 100));
    cubit.setFilterType('income');

    expect(cubit.state.filteredTransactions.length, equals(1));
    expect(cubit.state.filteredTransactions.first.transaction.amount, equals(50000.0));
  });

  test('Search by note keyword', () async {
    await Future.delayed(const Duration(milliseconds: 100));
    cubit.setSearchQuery('headphones');

    expect(cubit.state.filteredTransactions.length, equals(1));
    expect(cubit.state.filteredTransactions.first.transaction.note, contains('headphones'));
  });

  test('Search by amount', () async {
    await Future.delayed(const Duration(milliseconds: 100));
    cubit.setSearchQuery('1200');

    expect(cubit.state.filteredTransactions.length, equals(1));
    expect(cubit.state.filteredTransactions.first.transaction.amount, equals(1200.0));
  });

  test('Search by occasion title', () async {
    await Future.delayed(const Duration(milliseconds: 150));
    cubit.setSearchQuery('Goa');

    expect(cubit.state.filteredTransactions.length, equals(1));
    expect(cubit.state.filteredTransactions.first.transaction.amount, equals(1200.0));
  });

  test('Filter by amount range', () async {
    await Future.delayed(const Duration(milliseconds: 100));
    cubit.setFilter(cubit.state.filter.copyWith(minAmount: 1000, maxAmount: 3000));

    expect(cubit.state.filteredTransactions.length, equals(1));
    expect(cubit.state.filteredTransactions.first.transaction.amount, equals(1200.0));
  });

  test('Sort by amount descending', () async {
    await Future.delayed(const Duration(milliseconds: 100));
    cubit.setFilter(cubit.state.filter.copyWith(sortBy: SortOption.amountDesc));

    expect(cubit.state.filteredTransactions.first.transaction.amount, equals(50000.0));
    expect(cubit.state.filteredTransactions.last.transaction.amount, equals(1200.0));
  });
}
