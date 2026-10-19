import 'package:drift/drift.dart';
import '../database/app_database.dart';

class TransactionRepository {
  final AppDatabase _db;

  TransactionRepository(this._db);

  AppDatabase get db => _db;

  // Transactions
  Stream<List<TransactionWithCategory>> watchRecentTransactions({int limit = 20}) {
    return _db.watchRecentTransactions(limit: limit);
  }

  Stream<List<TransactionWithCategory>> watchTransactionsForMonth(int year, int month) {
    return _db.watchTransactionsForMonth(year, month);
  }

  Future<int> addTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required DateTime date,
    String? note,
    bool isRecurring = false,
    int? occasionId,
  }) {
    return _db.insertTransaction(
      TransactionsCompanion(
        type: Value(type),
        amount: Value(amount),
        categoryId: Value(categoryId),
        date: Value(date),
        note: Value(note),
        isRecurring: Value(isRecurring),
        occasionId: Value(occasionId),
      ),
    );
  }

  Future<int> deleteTransaction(int id) {
    return _db.deleteTransaction(id);
  }

  Future<bool> updateTransaction({
    required int id,
    required String type,
    required double amount,
    required int categoryId,
    required DateTime date,
    String? note,
    bool isRecurring = false,
    int? occasionId,
  }) {
    return _db.updateTransaction(
      TransactionsCompanion(
        id: Value(id),
        type: Value(type),
        amount: Value(amount),
        categoryId: Value(categoryId),
        date: Value(date),
        note: Value(note),
        isRecurring: Value(isRecurring),
        occasionId: Value(occasionId),
      ),
    );
  }

  Future<List<TransactionWithCategory>> getAllTransactions() => _db.getAllTransactions();

  // Categories
  Stream<List<Category>> watchCategories({bool? isIncome}) {
    if (isIncome != null) {
      return _db.watchCategoriesByType(isIncome: isIncome);
    }
    return _db.watchAllCategories();
  }

  Future<List<Category>> getAllCategories() => _db.getAllCategories();

  Future<int> addCategory({
    required String name,
    required String icon,
    required int color,
    required bool isIncome,
  }) {
    return _db.insertCategory(
      CategoriesCompanion(
        name: Value(name),
        icon: Value(icon),
        color: Value(color),
        isIncome: Value(isIncome),
        sortOrder: const Value(99),
        isDefault: const Value(false),
      ),
    );
  }

  Future<bool> updateCategory({
    required int id,
    required String name,
    required String icon,
    required int color,
    required bool isIncome,
  }) {
    return _db.updateCategory(
      CategoriesCompanion(
        id: Value(id),
        name: Value(name),
        icon: Value(icon),
        color: Value(color),
        isIncome: Value(isIncome),
      ),
    );
  }

  Future<int> deleteCategory(int id) => _db.deleteCategory(id);

  // Budgets
  Stream<List<BudgetWithCategory>> watchBudgetsForMonth(int year, int month) {
    return _db.watchBudgetsForMonth(year, month);
  }

  Future<int> setBudget({
    required int categoryId,
    required double amount,
    required int year,
    required int month,
  }) {
    return _db.setBudget(
      BudgetsCompanion(
        categoryId: Value(categoryId),
        amount: Value(amount),
        year: Value(year),
        month: Value(month),
      ),
    );
  }

  Future<int> deleteBudget(int id) => _db.deleteBudget(id);

  // Savings Goals
  Stream<List<SavingsGoal>> watchSavingsGoals() => _db.watchSavingsGoals();

  Future<int> addSavingsGoal({
    required String title,
    required double targetAmount,
    double currentAmount = 0.0,
    required int color,
    String icon = '🎯',
    String? description,
    DateTime? deadline,
  }) {
    return _db.insertSavingsGoal(
      SavingsGoalsCompanion(
        title: Value(title),
        targetAmount: Value(targetAmount),
        currentAmount: Value(currentAmount),
        color: Value(color),
        icon: Value(icon),
        description: Value(description),
        deadline: Value(deadline),
      ),
    );
  }

  Future<bool> updateSavingsGoal({
    required int id,
    required String title,
    required double targetAmount,
    required double currentAmount,
    required int color,
    required String icon,
    String? description,
    DateTime? deadline,
  }) {
    return _db.updateSavingsGoal(
      SavingsGoalsCompanion(
        id: Value(id),
        title: Value(title),
        targetAmount: Value(targetAmount),
        currentAmount: Value(currentAmount),
        color: Value(color),
        icon: Value(icon),
        description: Value(description),
        deadline: Value(deadline),
      ),
    );
  }

  Future<int> updateSavingsAmount(int id, double newAmount) {
    return _db.updateSavingsGoalAmount(id, newAmount);
  }

  Future<int> deleteSavingsGoal(int id) => _db.deleteSavingsGoal(id);

  // Cart / Wishlist
  Stream<List<CartItem>> watchCartItems() => _db.watchCartItems();

  Future<int> addCartItem({
    required String name,
    required double price,
    double savedAmount = 0.0,
    String priority = 'medium',
    String? note,
  }) {
    return _db.insertCartItem(
      CartItemsCompanion(
        name: Value(name),
        price: Value(price),
        savedAmount: Value(savedAmount),
        priority: Value(priority),
        note: Value(note),
      ),
    );
  }

  Future<bool> updateCartItem({
    required int id,
    required String name,
    required double price,
    required double savedAmount,
    required String priority,
    String? note,
  }) {
    return _db.updateCartItem(
      CartItemsCompanion(
        id: Value(id),
        name: Value(name),
        price: Value(price),
        savedAmount: Value(savedAmount),
        priority: Value(priority),
        note: Value(note),
      ),
    );
  }

  Future<int> updateCartItemSaved(int id, double newSavedAmount) {
    return _db.updateCartItemSavedAmount(id, newSavedAmount);
  }

  Future<int> deleteCartItem(int id) => _db.deleteCartItem(id);

  // User Settings
  Stream<UserSetting?> watchUserSettings() => _db.watchUserSettings();
  Future<UserSetting?> getUserSettings() => _db.getUserSettings();
  Future<int> saveUserSettings(UserSettingsCompanion entry) => _db.saveUserSettings(entry);

  // Occasions / Trips
  Stream<List<Occasion>> watchAllOccasions({bool includeCompleted = true}) =>
      _db.watchAllOccasions(includeCompleted: includeCompleted);
  Future<List<Occasion>> getAllOccasions() => _db.getAllOccasions();
  Future<List<Occasion>> getActiveOccasions() async {
    final all = await _db.getAllOccasions();
    return all.where((o) => !o.isCompleted).toList();
  }
  Future<int> addOccasion({
    required String name,
    required double budget,
    required String icon,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _db.insertOccasion(
      OccasionsCompanion(
        name: Value(name),
        budget: Value(budget),
        icon: Value(icon),
        description: Value(description),
        startDate: Value(startDate),
        endDate: Value(endDate),
      ),
    );
  }
  Future<bool> updateOccasion(OccasionsCompanion entry) => _db.updateOccasion(entry);
  Future<int> deleteOccasion(int id) => _db.deleteOccasion(id);
  Stream<List<TransactionWithCategory>> watchTransactionsForOccasion(int occasionId) =>
      _db.watchTransactionsForOccasion(occasionId);
  Future<List<TransactionWithCategory>> getTransactionsForOccasion(int occasionId) =>
      _db.getTransactionsForOccasion(occasionId);

  // Debts & Loans
  Stream<List<Debt>> watchAllDebts() => _db.watchAllDebts();
  Stream<List<Debt>> watchActiveDebts() => _db.watchActiveDebts();
  Future<List<Debt>> getAllDebts() => _db.getAllDebts();
  Future<Debt?> getDebtById(int id) => _db.getDebtById(id);
  Future<int> addDebt(DebtsCompanion entry) => _db.insertDebt(entry);
  Future<bool> updateDebt(Insertable<Debt> entry) => _db.updateDebt(entry);
  Future<int> deleteDebt(int id) => _db.deleteDebt(id);

  Stream<List<DebtPayment>> watchPaymentsForDebt(int debtId) => _db.watchPaymentsForDebt(debtId);
  Future<List<DebtPayment>> getPaymentsForDebt(int debtId) => _db.getPaymentsForDebt(debtId);

  Future<void> recordDebtPayment({
    required int debtId,
    required double amount,
    String? note,
    DateTime? paymentDate,
    bool recordAsTransaction = false,
    int? categoryId,
  }) async {
    final debt = await _db.getDebtById(debtId);
    if (debt == null) return;

    final date = paymentDate ?? DateTime.now();

    // 1. Record debt payment history
    await _db.insertDebtPayment(
      DebtPaymentsCompanion(
        debtId: Value(debtId),
        amount: Value(amount),
        paymentDate: Value(date),
        note: Value(note),
      ),
    );

    // 2. Update settled amount and status
    final newSettledAmount = (debt.settledAmount + amount).clamp(0.0, double.infinity);
    final isFullySettled = newSettledAmount >= debt.amount;

    await _db.updateDebt(
      debt.copyWith(
        settledAmount: newSettledAmount,
        isSettled: isFullySettled,
        settledAt: Value(isFullySettled ? (debt.settledAt ?? DateTime.now()) : null),
      ),
    );

    // 3. Optional linked transaction
    if (recordAsTransaction && categoryId != null) {
      // If lent money was received back -> income
      // If borrowed money was paid back -> expense
      final txType = debt.type == 'lent' ? 'income' : 'expense';
      final actionWord = debt.type == 'lent' ? 'Repayment received from' : 'Repayment paid to';

      await _db.insertTransaction(
        TransactionsCompanion.insert(
          type: txType,
          amount: amount,
          categoryId: categoryId,
          date: date,
          note: Value('Debt $actionWord ${debt.personName}${note != null ? ' ($note)' : ''}'),
        ),
      );
    }
  }

  Future<void> markDebtSettled(int debtId, {bool recordAsTransaction = false, int? categoryId}) async {
    final debt = await _db.getDebtById(debtId);
    if (debt == null) return;

    final remaining = (debt.amount - debt.settledAmount).clamp(0.0, double.infinity);
    if (remaining > 0) {
      await recordDebtPayment(
        debtId: debtId,
        amount: remaining,
        note: 'Full settlement',
        recordAsTransaction: recordAsTransaction,
        categoryId: categoryId,
      );
    } else {
      await _db.updateDebt(
        debt.copyWith(
          isSettled: true,
          settledAt: Value(DateTime.now()),
        ),
      );
    }
  }
}


