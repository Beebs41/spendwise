import 'package:drift/drift.dart';
import 'tables.dart';
import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Transactions, Budgets, SavingsGoals, CartItems, UserSettings, Occasions, Debts, DebtPayments])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.connect());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedDefaultCategories();
      await _seedDefaultSettings();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(userSettings);
        await _seedDefaultSettings();
      }
      if (from < 3) {
        await m.createTable(occasions);
        await m.addColumn(transactions, transactions.occasionId);
        await m.addColumn(userSettings, userSettings.profileImagePath);
        await m.addColumn(userSettings, userSettings.isOnboarded);
        // Preserve onboarding state for existing installed users
        await (update(userSettings)).write(
          const UserSettingsCompanion(
            isOnboarded: Value(true),
          ),
        );
      }
      if (from < 4) {
        await m.createTable(debts);
        await m.createTable(debtPayments);
      }
    },
  );

  Future<void> _seedDefaultCategories() async {
    final defaultCategories = [
      // Expense Categories
      CategoriesCompanion.insert(
        name: 'Food & Dining',
        icon: '🍔',
        color: 0xFFFF6B6B,
        isIncome: const Value(false),
        sortOrder: const Value(1),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Transportation',
        icon: '🚗',
        color: 0xFF4ECDC4,
        isIncome: const Value(false),
        sortOrder: const Value(2),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Housing & Rent',
        icon: '🏠',
        color: 0xFFF5A623,
        isIncome: const Value(false),
        sortOrder: const Value(3),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Utilities',
        icon: '💡',
        color: 0xFF45B7D1,
        isIncome: const Value(false),
        sortOrder: const Value(4),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Shopping',
        icon: '🛍️',
        color: 0xFFFF8A5C,
        isIncome: const Value(false),
        sortOrder: const Value(5),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Healthcare',
        icon: '🏥',
        color: 0xFF2ECC71,
        isIncome: const Value(false),
        sortOrder: const Value(6),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Entertainment',
        icon: '🎬',
        color: 0xFFA855F7,
        isIncome: const Value(false),
        sortOrder: const Value(7),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Education',
        icon: '📚',
        color: 0xFF3B82F6,
        isIncome: const Value(false),
        sortOrder: const Value(8),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Travel',
        icon: '✈️',
        color: 0xFFEC4899,
        isIncome: const Value(false),
        sortOrder: const Value(9),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Subscriptions',
        icon: '📱',
        color: 0xFF6366F1,
        isIncome: const Value(false),
        sortOrder: const Value(10),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Gifts & Donations',
        icon: '🎁',
        color: 0xFFF472B6,
        isIncome: const Value(false),
        sortOrder: const Value(11),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Other Expense',
        icon: '❓',
        color: 0xFF8E8E9A,
        isIncome: const Value(false),
        sortOrder: const Value(12),
        isDefault: const Value(true),
      ),

      // Income Categories
      CategoriesCompanion.insert(
        name: 'Salary',
        icon: '💼',
        color: 0xFF2ECC71,
        isIncome: const Value(true),
        sortOrder: const Value(1),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Freelance',
        icon: '💻',
        color: 0xFF4ECDC4,
        isIncome: const Value(true),
        sortOrder: const Value(2),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Investments',
        icon: '📈',
        color: 0xFFF5A623,
        isIncome: const Value(true),
        sortOrder: const Value(3),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Gifts Received',
        icon: '🎀',
        color: 0xFFA855F7,
        isIncome: const Value(true),
        sortOrder: const Value(4),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Other Income',
        icon: '💵',
        color: 0xFF3B82F6,
        isIncome: const Value(true),
        sortOrder: const Value(5),
        isDefault: const Value(true),
      ),
    ];

    await batch((b) {
      b.insertAll(categories, defaultCategories);
    });
  }

  // Reactive Streams & Queries

  // Transactions
  Stream<List<TransactionWithCategory>> watchRecentTransactions({int limit = 20}) {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..orderBy([OrderingTerm.desc(transactions.date), OrderingTerm.desc(transactions.id)])
      ..limit(limit);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          transaction: row.readTable(transactions),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Stream<List<TransactionWithCategory>> watchTransactionsForMonth(int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..where(transactions.date.isBiggerOrEqualValue(startDate) &
          transactions.date.isSmallerThanValue(endDate))
      ..orderBy([OrderingTerm.desc(transactions.date), OrderingTerm.desc(transactions.id)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          transaction: row.readTable(transactions),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Future<int> insertTransaction(TransactionsCompanion entry) => into(transactions).insert(entry);
  Future<bool> updateTransaction(TransactionsCompanion entry) => update(transactions).replace(entry);
  Future<int> deleteTransaction(int id) => (delete(transactions)..where((t) => t.id.equals(id))).go();

  // Categories
  Stream<List<Category>> watchAllCategories() => select(categories).watch();
  Stream<List<Category>> watchCategoriesByType({required bool isIncome}) {
    return (select(categories)..where((c) => c.isIncome.equals(isIncome))).watch();
  }
  Future<List<Category>> getAllCategories() => select(categories).get();
  Future<int> insertCategory(CategoriesCompanion entry) => into(categories).insert(entry);
  Future<bool> updateCategory(CategoriesCompanion entry) => update(categories).replace(entry);
  Future<int> deleteCategory(int id) => (delete(categories)..where((c) => c.id.equals(id))).go();

  // Budgets
  Stream<List<BudgetWithCategory>> watchBudgetsForMonth(int year, int month) {
    final query = select(budgets).join([
      innerJoin(categories, categories.id.equalsExp(budgets.categoryId)),
    ])..where(budgets.year.equals(year) & budgets.month.equals(month));

    return query.watch().map((rows) {
      return rows.map((row) {
        return BudgetWithCategory(
          budget: row.readTable(budgets),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Future<int> setBudget(BudgetsCompanion entry) => into(budgets).insertOnConflictUpdate(entry);
  Future<int> deleteBudget(int id) => (delete(budgets)..where((b) => b.id.equals(id))).go();

  // Savings Goals
  Stream<List<SavingsGoal>> watchSavingsGoals() =>
      (select(savingsGoals)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  Future<int> insertSavingsGoal(SavingsGoalsCompanion entry) => into(savingsGoals).insert(entry);
  Future<int> updateSavingsGoalAmount(int id, double newAmount) =>
      (update(savingsGoals)..where((s) => s.id.equals(id)))
          .write(SavingsGoalsCompanion(currentAmount: Value(newAmount)));
  Future<bool> updateSavingsGoal(SavingsGoalsCompanion entry) => update(savingsGoals).replace(entry);
  Future<int> deleteSavingsGoal(int id) => (delete(savingsGoals)..where((s) => s.id.equals(id))).go();

  // Cart / Wishlist Items
  Stream<List<CartItem>> watchCartItems() =>
      (select(cartItems)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  Future<int> insertCartItem(CartItemsCompanion entry) => into(cartItems).insert(entry);
  Future<int> updateCartItemSavedAmount(int id, double newSavedAmount) =>
      (update(cartItems)..where((c) => c.id.equals(id)))
          .write(CartItemsCompanion(savedAmount: Value(newSavedAmount)));
  Future<bool> updateCartItem(CartItemsCompanion entry) => update(cartItems).replace(entry);
  Future<int> deleteCartItem(int id) => (delete(cartItems)..where((c) => c.id.equals(id))).go();

  Future<List<TransactionWithCategory>> getAllTransactions() async {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])..orderBy([OrderingTerm.desc(transactions.date), OrderingTerm.desc(transactions.id)]);

    final rows = await query.get();
    return rows.map((row) {
      return TransactionWithCategory(
        transaction: row.readTable(transactions),
        category: row.readTable(categories),
      );
    }).toList();
  }

  // Occasions / Trips
  Stream<List<Occasion>> watchAllOccasions({bool includeCompleted = true}) {
    final q = select(occasions);
    if (!includeCompleted) {
      q.where((o) => o.isCompleted.equals(false));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch();
  }

  Future<List<Occasion>> getAllOccasions() =>
      (select(occasions)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<int> insertOccasion(OccasionsCompanion entry) => into(occasions).insert(entry);
  Future<bool> updateOccasion(OccasionsCompanion entry) => update(occasions).replace(entry);
  Future<int> deleteOccasion(int id) async {
    // Unlink transactions before deleting occasion
    await (update(transactions)..where((t) => t.occasionId.equals(id)))
        .write(const TransactionsCompanion(occasionId: Value(null)));
    return (delete(occasions)..where((o) => o.id.equals(id))).go();
  }

  Stream<List<TransactionWithCategory>> watchTransactionsForOccasion(int occasionId) {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..where(transactions.occasionId.equals(occasionId))
      ..orderBy([OrderingTerm.desc(transactions.date), OrderingTerm.desc(transactions.id)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          transaction: row.readTable(transactions),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Future<List<TransactionWithCategory>> getTransactionsForOccasion(int occasionId) async {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..where(transactions.occasionId.equals(occasionId))
      ..orderBy([OrderingTerm.desc(transactions.date), OrderingTerm.desc(transactions.id)]);

    final rows = await query.get();
    return rows.map((row) {
      return TransactionWithCategory(
        transaction: row.readTable(transactions),
        category: row.readTable(categories),
      );
    }).toList();
  }

  // User Settings
  Future<void> _seedDefaultSettings() async {
    final existing = await select(userSettings).getSingleOrNull();
    if (existing == null) {
      await into(userSettings).insert(
        const UserSettingsCompanion(
          userName: Value(''),
          currencyCode: Value('INR'),
          currencySymbol: Value('₹'),
          isLockEnabled: Value(false),
          useBiometrics: Value(false),
          isOnboarded: Value(false),
        ),
      );
    }
  }

  Stream<UserSetting?> watchUserSettings() => select(userSettings).watchSingleOrNull();
  Future<UserSetting?> getUserSettings() => select(userSettings).getSingleOrNull();
  Future<int> saveUserSettings(UserSettingsCompanion entry) => into(userSettings).insertOnConflictUpdate(entry);

  // Debts & Loans
  Stream<List<Debt>> watchAllDebts() {
    return (select(debts)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Stream<List<Debt>> watchActiveDebts() {
    return (select(debts)
          ..where((t) => t.isSettled.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate), (t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<Debt>> getAllDebts() {
    return (select(debts)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<Debt?> getDebtById(int id) {
    return (select(debts)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertDebt(DebtsCompanion entry) => into(debts).insert(entry);
  Future<bool> updateDebt(Insertable<Debt> entry) => update(debts).replace(entry);
  Future<int> deleteDebt(int id) async {
    await (delete(debtPayments)..where((p) => p.debtId.equals(id))).go();
    return (delete(debts)..where((t) => t.id.equals(id))).go();
  }

  // Debt Payments
  Stream<List<DebtPayment>> watchPaymentsForDebt(int debtId) {
    return (select(debtPayments)
          ..where((t) => t.debtId.equals(debtId))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .watch();
  }

  Future<List<DebtPayment>> getPaymentsForDebt(int debtId) {
    return (select(debtPayments)
          ..where((t) => t.debtId.equals(debtId))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .get();
  }

  Future<int> insertDebtPayment(DebtPaymentsCompanion payment) => into(debtPayments).insert(payment);
  Future<int> deleteDebtPayment(int id) => (delete(debtPayments)..where((t) => t.id.equals(id))).go();
}

class TransactionWithCategory {
  final Transaction transaction;
  final Category category;

  TransactionWithCategory({required this.transaction, required this.category});
}

class BudgetWithCategory {
  final Budget budget;
  final Category category;

  BudgetWithCategory({required this.budget, required this.category});
}
