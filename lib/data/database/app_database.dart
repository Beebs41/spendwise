import 'package:drift/drift.dart';
import 'tables.dart';
import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Transactions, Budgets, SavingsGoals, CartItems, UserSettings, Occasions, Debts, DebtPayments, RecurringTransactions, AppNotifications])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.connect());

  @override
  int get schemaVersion => 11;

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
      if (from < 5) {
        await m.addColumn(transactions, transactions.receiptPath);
      }
      if (from < 6) {
        await m.createTable(recurringTransactions);
      }
      if (from < 7) {
        await m.addColumn(cartItems, cartItems.savingsGoalId);
      }
      if (from < 8) {
        await m.createTable(appNotifications);
        await m.addColumn(userSettings, userSettings.enableBudgetAlerts);
        await m.addColumn(userSettings, userSettings.enableDebtReminders);
        await m.addColumn(userSettings, userSettings.enableSavingsAlerts);
      }
      if (from < 9) {
        await m.addColumn(userSettings, userSettings.themeMode);
      }
      if (from < 10) {
        await m.addColumn(transactions, transactions.originalAmount);
        await m.addColumn(transactions, transactions.originalCurrency);
        await m.addColumn(transactions, transactions.exchangeRate);
        await m.addColumn(occasions, occasions.currencyCode);
      }
      if (from < 11) {
        await m.addColumn(userSettings, userSettings.hasSeenAppTour);
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

  Future<List<TransactionWithCategory>> getTransactionsForMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..where(transactions.date.isBiggerOrEqualValue(startDate) &
          transactions.date.isSmallerThanValue(endDate))
      ..orderBy([OrderingTerm.desc(transactions.date), OrderingTerm.desc(transactions.id)]);

    final rows = await query.get();
    return rows.map((row) {
      return TransactionWithCategory(
        transaction: row.readTable(transactions),
        category: row.readTable(categories),
      );
    }).toList();
  }

  Stream<List<TransactionWithCategory>> watchAllTransactions() {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])..orderBy([OrderingTerm.desc(transactions.date), OrderingTerm.desc(transactions.id)]);

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

  Future<List<BudgetWithCategory>> getBudgetsForMonth(int year, int month) async {
    final query = select(budgets).join([
      innerJoin(categories, categories.id.equalsExp(budgets.categoryId)),
    ])..where(budgets.year.equals(year) & budgets.month.equals(month));

    final rows = await query.get();
    return rows.map((row) {
      return BudgetWithCategory(
        budget: row.readTable(budgets),
        category: row.readTable(categories),
      );
    }).toList();
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
  Stream<List<CartItemWithGoal>> watchCartItemsWithGoal() {
    final query = select(cartItems).join([
      leftOuterJoin(savingsGoals, savingsGoals.id.equalsExp(cartItems.savingsGoalId)),
    ])..orderBy([OrderingTerm.desc(cartItems.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CartItemWithGoal(
          cartItem: row.readTable(cartItems),
          savingsGoal: row.readTableOrNull(savingsGoals),
        );
      }).toList();
    });
  }
  Future<List<CartItemWithGoal>> getAllCartItemsWithGoal() async {
    final query = select(cartItems).join([
      leftOuterJoin(savingsGoals, savingsGoals.id.equalsExp(cartItems.savingsGoalId)),
    ])..orderBy([OrderingTerm.desc(cartItems.createdAt)]);

    final rows = await query.get();
    return rows.map((row) {
      return CartItemWithGoal(
        cartItem: row.readTable(cartItems),
        savingsGoal: row.readTableOrNull(savingsGoals),
      );
    }).toList();
  }
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
          themeMode: Value('system'),
          isLockEnabled: Value(false),
          useBiometrics: Value(false),
          isOnboarded: Value(false),
        ),
      );
    }
  }

  Stream<UserSetting?> watchUserSettings() => (select(userSettings)..limit(1)).watchSingleOrNull();
  Future<UserSetting?> getUserSettings() => (select(userSettings)..limit(1)).getSingleOrNull();
  Future<int> saveUserSettings(UserSettingsCompanion entry) {
    final withId = entry.id.present ? entry : entry.copyWith(id: const Value(1));
    return into(userSettings).insertOnConflictUpdate(withId);
  }

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

  // Full Database Backup & Restore
  Future<Map<String, dynamic>> exportBackupPayload() async {
    final catRows = await select(categories).get();
    final occRows = await select(occasions).get();
    final txRows = await select(transactions).get();
    final budgetRows = await select(budgets).get();
    final goalRows = await select(savingsGoals).get();
    final cartRows = await select(cartItems).get();
    final debtRows = await select(debts).get();
    final paymentRows = await select(debtPayments).get();
    final settingsRows = await select(userSettings).get();
    final recurringRows = await select(recurringTransactions).get();
    final notificationRows = await select(appNotifications).get();

    return {
      'version': 1,
      'app': 'SpendWise',
      'exportedAt': DateTime.now().toIso8601String(),
      'metadata': {
        'totalTransactions': txRows.length,
        'totalCategories': catRows.length,
        'totalBudgets': budgetRows.length,
        'totalSavingsGoals': goalRows.length,
        'totalCartItems': cartRows.length,
        'totalDebts': debtRows.length,
        'totalDebtPayments': paymentRows.length,
        'totalOccasions': occRows.length,
        'totalRecurringTransactions': recurringRows.length,
        'totalNotifications': notificationRows.length,
      },
      'data': {
        'categories': catRows.map((c) => {
          'id': c.id,
          'name': c.name,
          'icon': c.icon,
          'color': c.color,
          'isIncome': c.isIncome,
          'sortOrder': c.sortOrder,
          'isDefault': c.isDefault,
        }).toList(),
        'occasions': occRows.map((o) => {
          'id': o.id,
          'name': o.name,
          'icon': o.icon,
          'budget': o.budget,
          'description': o.description,
          'startDate': o.startDate?.toIso8601String(),
          'endDate': o.endDate?.toIso8601String(),
          'isCompleted': o.isCompleted,
          'currencyCode': o.currencyCode,
          'createdAt': o.createdAt.toIso8601String(),
        }).toList(),
        'transactions': txRows.map((t) => {
          'id': t.id,
          'type': t.type,
          'amount': t.amount,
          'categoryId': t.categoryId,
          'date': t.date.toIso8601String(),
          'note': t.note,
          'isRecurring': t.isRecurring,
          'occasionId': t.occasionId,
          'receiptPath': t.receiptPath,
          'originalAmount': t.originalAmount,
          'originalCurrency': t.originalCurrency,
          'exchangeRate': t.exchangeRate,
          'createdAt': t.createdAt.toIso8601String(),
        }).toList(),
        'budgets': budgetRows.map((b) => {
          'id': b.id,
          'categoryId': b.categoryId,
          'amount': b.amount,
          'month': b.month,
          'year': b.year,
        }).toList(),
        'savingsGoals': goalRows.map((s) => {
          'id': s.id,
          'title': s.title,
          'description': s.description,
          'targetAmount': s.targetAmount,
          'currentAmount': s.currentAmount,
          'icon': s.icon,
          'color': s.color,
          'deadline': s.deadline?.toIso8601String(),
          'createdAt': s.createdAt.toIso8601String(),
        }).toList(),
        'cartItems': cartRows.map((c) => {
          'id': c.id,
          'name': c.name,
          'price': c.price,
          'savedAmount': c.savedAmount,
          'priority': c.priority,
          'isPurchased': c.isPurchased,
          'note': c.note,
          'savingsGoalId': c.savingsGoalId,
          'createdAt': c.createdAt.toIso8601String(),
        }).toList(),
        'debts': debtRows.map((d) => {
          'id': d.id,
          'personName': d.personName,
          'phoneNumber': d.phoneNumber,
          'type': d.type,
          'amount': d.amount,
          'settledAmount': d.settledAmount,
          'dueDate': d.dueDate?.toIso8601String(),
          'notes': d.notes,
          'isSettled': d.isSettled,
          'createdAt': d.createdAt.toIso8601String(),
          'settledAt': d.settledAt?.toIso8601String(),
        }).toList(),
        'debtPayments': paymentRows.map((p) => {
          'id': p.id,
          'debtId': p.debtId,
          'amount': p.amount,
          'paymentDate': p.paymentDate.toIso8601String(),
          'note': p.note,
        }).toList(),
        'userSettings': settingsRows.map((u) => {
          'id': u.id,
          'userName': u.userName,
          'profileImagePath': u.profileImagePath,
          'currencyCode': u.currencyCode,
          'currencySymbol': u.currencySymbol,
          'isLockEnabled': u.isLockEnabled,
          'passcode': u.passcode,
          'useBiometrics': u.useBiometrics,
          'isOnboarded': u.isOnboarded,
          'themeMode': u.themeMode,
          'enableBudgetAlerts': u.enableBudgetAlerts,
          'enableDebtReminders': u.enableDebtReminders,
          'enableSavingsAlerts': u.enableSavingsAlerts,
          'hasSeenAppTour': u.hasSeenAppTour,
        }).toList(),
        'recurringTransactions': recurringRows.map((r) => {
          'id': r.id,
          'type': r.type,
          'amount': r.amount,
          'categoryId': r.categoryId,
          'frequency': r.frequency,
          'startDate': r.startDate.toIso8601String(),
          'nextDueDate': r.nextDueDate.toIso8601String(),
          'lastGeneratedDate': r.lastGeneratedDate?.toIso8601String(),
          'note': r.note,
          'isActive': r.isActive,
          'occasionId': r.occasionId,
          'receiptPath': r.receiptPath,
          'createdAt': r.createdAt.toIso8601String(),
        }).toList(),
        'notifications': notificationRows.map((n) => {
          'id': n.id,
          'type': n.type,
          'title': n.title,
          'message': n.message,
          'icon': n.icon,
          'isRead': n.isRead,
          'payload': n.payload,
          'createdAt': n.createdAt.toIso8601String(),
        }).toList(),
      },
    };
  }

  Future<void> restoreBackupPayload(Map<String, dynamic> payload, {bool wipeExisting = true}) async {
    final data = payload['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Invalid backup file: missing "data" key');
    }

    await transaction(() async {
      if (wipeExisting) {
        // Clear in reverse dependency order
        await delete(appNotifications).go();
        await delete(recurringTransactions).go();
        await delete(debtPayments).go();
        await delete(debts).go();
        await delete(transactions).go();
        await delete(budgets).go();
        await delete(cartItems).go();
        await delete(savingsGoals).go();
        await delete(occasions).go();
        await delete(categories).go();
      }

      // 1. Categories
      if (data['categories'] is List) {
        for (final item in data['categories']) {
          final c = item as Map<String, dynamic>;
          await into(categories).insertOnConflictUpdate(
            CategoriesCompanion(
              id: Value(c['id'] as int),
              name: Value(c['name'] as String),
              icon: Value(c['icon'] as String? ?? '🏷️'),
              color: Value(c['color'] as int? ?? 0xFF4ECDC4),
              isIncome: Value(c['isIncome'] as bool? ?? false),
              sortOrder: Value(c['sortOrder'] as int? ?? 0),
              isDefault: Value(c['isDefault'] as bool? ?? false),
            ),
          );
        }
      }

      // 2. Occasions
      if (data['occasions'] is List) {
        for (final item in data['occasions']) {
          final o = item as Map<String, dynamic>;
          await into(occasions).insertOnConflictUpdate(
            OccasionsCompanion(
              id: Value(o['id'] as int),
              name: Value(o['name'] as String),
              icon: Value(o['icon'] as String? ?? '🏖️'),
              budget: Value((o['budget'] as num?)?.toDouble() ?? 0.0),
              description: Value(o['description'] as String?),
              startDate: Value(o['startDate'] != null ? DateTime.tryParse(o['startDate'] as String) : null),
              endDate: Value(o['endDate'] != null ? DateTime.tryParse(o['endDate'] as String) : null),
              isCompleted: Value(o['isCompleted'] as bool? ?? false),
              currencyCode: Value(o['currencyCode'] as String?),
              createdAt: Value(o['createdAt'] != null ? DateTime.parse(o['createdAt'] as String) : DateTime.now()),
            ),
          );
        }
      }

      // 3. Transactions
      if (data['transactions'] is List) {
        for (final item in data['transactions']) {
          final t = item as Map<String, dynamic>;
          await into(transactions).insertOnConflictUpdate(
            TransactionsCompanion(
              id: Value(t['id'] as int),
              type: Value(t['type'] as String),
              amount: Value((t['amount'] as num).toDouble()),
              categoryId: Value(t['categoryId'] as int),
              date: Value(DateTime.parse(t['date'] as String)),
              note: Value(t['note'] as String?),
              isRecurring: Value(t['isRecurring'] as bool? ?? false),
              occasionId: Value(t['occasionId'] as int?),
              receiptPath: Value(t['receiptPath'] as String?),
              originalAmount: Value((t['originalAmount'] as num?)?.toDouble()),
              originalCurrency: Value(t['originalCurrency'] as String?),
              exchangeRate: Value((t['exchangeRate'] as num?)?.toDouble()),
              createdAt: Value(t['createdAt'] != null ? DateTime.parse(t['createdAt'] as String) : DateTime.now()),
            ),
          );
        }
      }

      // 4. Budgets
      if (data['budgets'] is List) {
        for (final item in data['budgets']) {
          final b = item as Map<String, dynamic>;
          await into(budgets).insertOnConflictUpdate(
            BudgetsCompanion(
              id: Value(b['id'] as int),
              categoryId: Value(b['categoryId'] as int),
              amount: Value((b['amount'] as num).toDouble()),
              month: Value(b['month'] as int),
              year: Value(b['year'] as int),
            ),
          );
        }
      }

      // 5. Savings Goals
      if (data['savingsGoals'] is List) {
        for (final item in data['savingsGoals']) {
          final s = item as Map<String, dynamic>;
          await into(savingsGoals).insertOnConflictUpdate(
            SavingsGoalsCompanion(
              id: Value(s['id'] as int),
              title: Value(s['title'] as String),
              description: Value(s['description'] as String?),
              targetAmount: Value((s['targetAmount'] as num).toDouble()),
              currentAmount: Value((s['currentAmount'] as num?)?.toDouble() ?? 0.0),
              icon: Value(s['icon'] as String? ?? '🎯'),
              color: Value(s['color'] as int? ?? 0xFFF5A623),
              deadline: Value(s['deadline'] != null ? DateTime.tryParse(s['deadline'] as String) : null),
              createdAt: Value(s['createdAt'] != null ? DateTime.parse(s['createdAt'] as String) : DateTime.now()),
            ),
          );
        }
      }

      // 6. Cart Items
      if (data['cartItems'] is List) {
        for (final item in data['cartItems']) {
          final c = item as Map<String, dynamic>;
          await into(cartItems).insertOnConflictUpdate(
            CartItemsCompanion(
              id: Value(c['id'] as int),
              name: Value(c['name'] as String),
              price: Value((c['price'] as num).toDouble()),
              savedAmount: Value((c['savedAmount'] as num?)?.toDouble() ?? 0.0),
              priority: Value(c['priority'] as String? ?? 'medium'),
              isPurchased: Value(c['isPurchased'] as bool? ?? false),
              note: Value(c['note'] as String?),
              savingsGoalId: Value(c['savingsGoalId'] as int?),
              createdAt: Value(c['createdAt'] != null ? DateTime.parse(c['createdAt'] as String) : DateTime.now()),
            ),
          );
        }
      }

      // 7. Debts
      if (data['debts'] is List) {
        for (final item in data['debts']) {
          final d = item as Map<String, dynamic>;
          await into(debts).insertOnConflictUpdate(
            DebtsCompanion(
              id: Value(d['id'] as int),
              personName: Value(d['personName'] as String),
              phoneNumber: Value(d['phoneNumber'] as String?),
              type: Value(d['type'] as String),
              amount: Value((d['amount'] as num).toDouble()),
              settledAmount: Value((d['settledAmount'] as num?)?.toDouble() ?? 0.0),
              dueDate: Value(d['dueDate'] != null ? DateTime.tryParse(d['dueDate'] as String) : null),
              notes: Value(d['notes'] as String?),
              isSettled: Value(d['isSettled'] as bool? ?? false),
              createdAt: Value(d['createdAt'] != null ? DateTime.parse(d['createdAt'] as String) : DateTime.now()),
              settledAt: Value(d['settledAt'] != null ? DateTime.tryParse(d['settledAt'] as String) : null),
            ),
          );
        }
      }

      // 8. Debt Payments
      if (data['debtPayments'] is List) {
        for (final item in data['debtPayments']) {
          final p = item as Map<String, dynamic>;
          await into(debtPayments).insertOnConflictUpdate(
            DebtPaymentsCompanion(
              id: Value(p['id'] as int),
              debtId: Value(p['debtId'] as int),
              amount: Value((p['amount'] as num).toDouble()),
              paymentDate: Value(DateTime.parse(p['paymentDate'] as String)),
              note: Value(p['note'] as String?),
            ),
          );
        }
      }

      // 9. User Settings (restore preferences if wipeExisting was selected)
      if (wipeExisting && data['userSettings'] is List && (data['userSettings'] as List).isNotEmpty) {
        final u = (data['userSettings'] as List).first as Map<String, dynamic>;
        await into(userSettings).insertOnConflictUpdate(
          UserSettingsCompanion(
            id: Value(u['id'] as int? ?? 1),
            userName: Value(u['userName'] as String? ?? ''),
            profileImagePath: Value(u['profileImagePath'] as String?),
            currencyCode: Value(u['currencyCode'] as String? ?? 'INR'),
            currencySymbol: Value(u['currencySymbol'] as String? ?? '₹'),
            isLockEnabled: Value(u['isLockEnabled'] as bool? ?? false),
            passcode: Value(u['passcode'] as String?),
            useBiometrics: Value(u['useBiometrics'] as bool? ?? false),
            isOnboarded: Value(u['isOnboarded'] as bool? ?? true),
            themeMode: Value(u['themeMode'] as String? ?? 'system'),
            enableBudgetAlerts: Value(u['enableBudgetAlerts'] as bool? ?? true),
            enableDebtReminders: Value(u['enableDebtReminders'] as bool? ?? true),
            enableSavingsAlerts: Value(u['enableSavingsAlerts'] as bool? ?? true),
            hasSeenAppTour: Value(u['hasSeenAppTour'] as bool? ?? true),
          ),
        );
      }

      // 10. Recurring Transactions
      if (data['recurringTransactions'] is List) {
        for (final item in data['recurringTransactions']) {
          final r = item as Map<String, dynamic>;
          await into(recurringTransactions).insertOnConflictUpdate(
            RecurringTransactionsCompanion(
              id: Value(r['id'] as int),
              type: Value(r['type'] as String),
              amount: Value((r['amount'] as num).toDouble()),
              categoryId: Value(r['categoryId'] as int),
              frequency: Value(r['frequency'] as String? ?? 'monthly'),
              startDate: Value(DateTime.parse(r['startDate'] as String)),
              nextDueDate: Value(DateTime.parse(r['nextDueDate'] as String)),
              lastGeneratedDate: Value(r['lastGeneratedDate'] != null ? DateTime.tryParse(r['lastGeneratedDate'] as String) : null),
              note: Value(r['note'] as String?),
              isActive: Value(r['isActive'] as bool? ?? true),
              occasionId: Value(r['occasionId'] as int?),
              receiptPath: Value(r['receiptPath'] as String?),
              createdAt: Value(r['createdAt'] != null ? DateTime.parse(r['createdAt'] as String) : DateTime.now()),
            ),
          );
        }
      }

      // 11. Notifications
      if (data['notifications'] is List) {
        for (final item in data['notifications']) {
          final n = item as Map<String, dynamic>;
          await into(appNotifications).insertOnConflictUpdate(
            AppNotificationsCompanion(
              id: Value(n['id'] as int),
              type: Value(n['type'] as String),
              title: Value(n['title'] as String),
              message: Value(n['message'] as String),
              icon: Value(n['icon'] as String? ?? '🔔'),
              isRead: Value(n['isRead'] as bool? ?? false),
              payload: Value(n['payload'] as String?),
              createdAt: Value(n['createdAt'] != null ? DateTime.parse(n['createdAt'] as String) : DateTime.now()),
            ),
          );
        }
      }
    });
  }

  // Recurring Transactions Methods
  Stream<List<RecurringWithCategory>> watchAllRecurringTransactions() {
    final query = select(recurringTransactions).join([
      innerJoin(categories, categories.id.equalsExp(recurringTransactions.categoryId)),
    ])
      ..orderBy([
        OrderingTerm.asc(recurringTransactions.nextDueDate),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return RecurringWithCategory(
          recurring: row.readTable(recurringTransactions),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Future<List<RecurringWithCategory>> getAllRecurringTransactions() async {
    final query = select(recurringTransactions).join([
      innerJoin(categories, categories.id.equalsExp(recurringTransactions.categoryId)),
    ])
      ..orderBy([
        OrderingTerm.asc(recurringTransactions.nextDueDate),
      ]);

    final rows = await query.get();
    return rows.map((row) {
      return RecurringWithCategory(
        recurring: row.readTable(recurringTransactions),
        category: row.readTable(categories),
      );
    }).toList();
  }

  Future<int> insertRecurringTransaction(RecurringTransactionsCompanion companion) {
    return into(recurringTransactions).insert(companion);
  }

  Future<bool> updateRecurringTransaction(RecurringTransactionsCompanion companion) {
    return update(recurringTransactions).replace(companion);
  }

  Future<int> deleteRecurringTransaction(int id) {
    return (delete(recurringTransactions)..where((t) => t.id.equals(id))).go();
  }

  Future<int> toggleRecurringActive(int id, bool isActive) {
    return (update(recurringTransactions)..where((t) => t.id.equals(id))).write(
      RecurringTransactionsCompanion(
        isActive: Value(isActive),
      ),
    );
  }

  // App Notifications Methods
  Stream<List<AppNotification>> watchNotifications({bool? unreadOnly, int limit = 50}) {
    final query = select(appNotifications)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    if (unreadOnly == true) {
      query.where((t) => t.isRead.equals(false));
    }
    return query.watch();
  }

  Stream<int> watchUnreadNotificationCount() {
    final countExp = appNotifications.id.count();
    final query = selectOnly(appNotifications)
      ..addColumns([countExp])
      ..where(appNotifications.isRead.equals(false));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  Future<List<AppNotification>> getAllNotifications({int limit = 50}) {
    return (select(appNotifications)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<int> insertNotification(AppNotificationsCompanion entry) =>
      into(appNotifications).insert(entry);

  Future<int> markNotificationAsRead(int id) {
    return (update(appNotifications)..where((t) => t.id.equals(id))).write(
      const AppNotificationsCompanion(isRead: Value(true)),
    );
  }

  Future<int> markAllNotificationsAsRead() {
    return update(appNotifications).write(
      const AppNotificationsCompanion(isRead: Value(true)),
    );
  }

  Future<int> deleteNotification(int id) {
    return (delete(appNotifications)..where((t) => t.id.equals(id))).go();
  }

  Future<int> clearAllNotifications() {
    return delete(appNotifications).go();
  }
}

class RecurringWithCategory {
  final RecurringTransaction recurring;
  final Category category;

  RecurringWithCategory({required this.recurring, required this.category});
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

class CartItemWithGoal {
  final CartItem cartItem;
  final SavingsGoal? savingsGoal;

  CartItemWithGoal({required this.cartItem, this.savingsGoal});
}
