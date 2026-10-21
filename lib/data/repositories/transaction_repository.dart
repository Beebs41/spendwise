import 'dart:async';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../core/services/reminder_engine.dart';
import '../../core/services/widget_sync_service.dart';

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

  Future<List<TransactionWithCategory>> getTransactionsForMonth(int year, int month) {
    return _db.getTransactionsForMonth(year, month);
  }

  Stream<List<TransactionWithCategory>> watchAllTransactions() {
    return _db.watchAllTransactions();
  }

  Future<int> addTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required DateTime date,
    String? note,
    bool isRecurring = false,
    int? occasionId,
    String? receiptPath,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,
  }) async {
    final id = await _db.insertTransaction(
      TransactionsCompanion(
        type: Value(type),
        amount: Value(amount),
        categoryId: Value(categoryId),
        date: Value(date),
        note: Value(note),
        isRecurring: Value(isRecurring),
        occasionId: Value(occasionId),
        receiptPath: Value(receiptPath),
        originalAmount: Value(originalAmount),
        originalCurrency: Value(originalCurrency),
        exchangeRate: Value(exchangeRate),
      ),
    );

    if (type == 'expense') {
      _checkBudgetForCategory(categoryId, date);
    }

    unawaited(WidgetSyncService.syncWidget(this));
    return id;
  }

  Future<int> deleteTransaction(int id) async {
    final res = await _db.deleteTransaction(id);
    unawaited(WidgetSyncService.syncWidget(this));
    return res;
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
    String? receiptPath,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,
  }) async {
    final success = await _db.updateTransaction(
      TransactionsCompanion(
        id: Value(id),
        type: Value(type),
        amount: Value(amount),
        categoryId: Value(categoryId),
        date: Value(date),
        note: Value(note),
        isRecurring: Value(isRecurring),
        occasionId: Value(occasionId),
        receiptPath: Value(receiptPath),
        originalAmount: Value(originalAmount),
        originalCurrency: Value(originalCurrency),
        exchangeRate: Value(exchangeRate),
      ),
    );

    if (type == 'expense') {
      _checkBudgetForCategory(categoryId, date);
    }

    unawaited(WidgetSyncService.syncWidget(this));
    return success;
  }

  Future<void> _checkBudgetForCategory(int categoryId, DateTime date) async {
    try {
      final budgets = await _db.getBudgetsForMonth(date.year, date.month);
      final match = budgets.where((b) => b.budget.categoryId == categoryId).firstOrNull;
      if (match != null && match.budget.amount > 0) {
        final transactions = await _db.getTransactionsForMonth(date.year, date.month);
        final currentSpend = transactions
            .where((t) => t.transaction.categoryId == categoryId && t.transaction.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.transaction.amount);
        final settings = await getUserSettings();
        await ReminderEngine.checkBudgetAlerts(
          repository: this,
          categoryId: categoryId,
          currentSpend: currentSpend,
          budgetAmount: match.budget.amount,
          categoryName: match.category.name,
          currencySymbol: settings?.currencySymbol ?? '₹',
        );
      }
    } catch (_) {}
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

  Future<List<BudgetWithCategory>> getBudgetsForMonth(int year, int month) {
    return _db.getBudgetsForMonth(year, month);
  }

  Future<int> setBudget({
    required int categoryId,
    required double amount,
    required int year,
    required int month,
  }) async {
    final res = await _db.setBudget(
      BudgetsCompanion(
        categoryId: Value(categoryId),
        amount: Value(amount),
        year: Value(year),
        month: Value(month),
      ),
    );
    unawaited(WidgetSyncService.syncWidget(this));
    return res;
  }

  Future<int> deleteBudget(int id) async {
    final res = await _db.deleteBudget(id);
    unawaited(WidgetSyncService.syncWidget(this));
    return res;
  }

  // Savings Goals
  Stream<List<SavingsGoal>> watchSavingsGoals() => _db.watchSavingsGoals();
  Future<List<SavingsGoal>> getAllSavingsGoals() =>
      (_db.select(_db.savingsGoals)..orderBy([(s) => OrderingTerm.asc(s.title)])).get();

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
  }) async {
    final success = await _db.updateSavingsGoal(
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

    if (success) {
      _checkGoalMilestones(id);
    }

    return success;
  }

  Future<int> updateSavingsAmount(int id, double newAmount) async {
    final count = await _db.updateSavingsGoalAmount(id, newAmount);
    if (count > 0) {
      _checkGoalMilestones(id);
    }
    return count;
  }

  Future<void> _checkGoalMilestones(int goalId) async {
    try {
      final goals = await getAllSavingsGoals();
      final goal = goals.where((g) => g.id == goalId).firstOrNull;
      if (goal != null) {
        final settings = await getUserSettings();
        await ReminderEngine.checkSavingsMilestones(
          repository: this,
          goal: goal,
          currencySymbol: settings?.currencySymbol ?? '₹',
        );
      }
    } catch (_) {}
  }

  Future<int> deleteSavingsGoal(int id) => _db.deleteSavingsGoal(id);

  // Cart / Wishlist
  Stream<List<CartItem>> watchCartItems() => _db.watchCartItems();
  Stream<List<CartItemWithGoal>> watchCartItemsWithGoal() => _db.watchCartItemsWithGoal();
  Future<List<CartItemWithGoal>> getAllCartItemsWithGoal() => _db.getAllCartItemsWithGoal();

  Future<int> addCartItem({
    required String name,
    required double price,
    double savedAmount = 0.0,
    String priority = 'medium',
    String? note,
    int? savingsGoalId,
  }) {
    return _db.insertCartItem(
      CartItemsCompanion(
        name: Value(name),
        price: Value(price),
        savedAmount: Value(savedAmount),
        priority: Value(priority),
        note: Value(note),
        savingsGoalId: Value(savingsGoalId),
      ),
    );
  }

  Future<bool> updateCartItem({
    required int id,
    required String name,
    required double price,
    required double savedAmount,
    required String priority,
    bool isPurchased = false,
    String? note,
    int? savingsGoalId,
  }) {
    return _db.updateCartItem(
      CartItemsCompanion(
        id: Value(id),
        name: Value(name),
        price: Value(price),
        savedAmount: Value(savedAmount),
        priority: Value(priority),
        isPurchased: Value(isPurchased),
        note: Value(note),
        savingsGoalId: Value(savingsGoalId),
      ),
    );
  }

  Future<int> depositToCartItem({
    required int cartItemId,
    required double newSavedAmount,
    bool syncLinkedGoal = true,
  }) async {
    final item = await (_db.select(_db.cartItems)..where((c) => c.id.equals(cartItemId))).getSingleOrNull();
    if (item == null) return 0;

    final delta = newSavedAmount - item.savedAmount;
    final res = await _db.updateCartItemSavedAmount(cartItemId, newSavedAmount);

    if (syncLinkedGoal && item.savingsGoalId != null && delta != 0) {
      final goal = await (_db.select(_db.savingsGoals)..where((g) => g.id.equals(item.savingsGoalId!))).getSingleOrNull();
      if (goal != null) {
        final newGoalAmount = (goal.currentAmount + delta).clamp(0.0, double.infinity);
        await _db.updateSavingsGoalAmount(goal.id, newGoalAmount);
      }
    }
    return res;
  }

  Future<int> updateCartItemSaved(int id, double newSavedAmount) {
    return depositToCartItem(cartItemId: id, newSavedAmount: newSavedAmount);
  }

  Future<int?> markCartItemPurchased({
    required int cartItemId,
    required bool recordAsTransaction,
    double? actualPrice,
    int? categoryId,
    DateTime? date,
    String? note,
    bool markGoalCompleted = false,
  }) async {
    return _db.transaction(() async {
      final item = await (_db.select(_db.cartItems)..where((c) => c.id.equals(cartItemId))).getSingleOrNull();
      if (item == null) return null;

      final finalPrice = actualPrice ?? item.price;

      // Update cart item state to purchased
      await (_db.update(_db.cartItems)..where((c) => c.id.equals(cartItemId))).write(
        CartItemsCompanion(
          isPurchased: const Value(true),
          price: Value(finalPrice),
          savedAmount: Value(finalPrice),
        ),
      );

      // If linked to goal and requested, mark goal as reached
      if (item.savingsGoalId != null && markGoalCompleted) {
        final goal = await (_db.select(_db.savingsGoals)..where((g) => g.id.equals(item.savingsGoalId!))).getSingleOrNull();
        if (goal != null) {
          await (_db.update(_db.savingsGoals)..where((g) => g.id.equals(goal.id))).write(
            SavingsGoalsCompanion(
              currentAmount: Value(goal.targetAmount),
            ),
          );
        }
      }

      // Record transaction if requested
      if (recordAsTransaction && categoryId != null) {
        final txId = await _db.insertTransaction(
          TransactionsCompanion(
            type: const Value('expense'),
            amount: Value(finalPrice),
            categoryId: Value(categoryId),
            date: Value(date ?? DateTime.now()),
            note: Value(note ?? 'Purchased wishlist item: ${item.name}'),
          ),
        );
        return txId;
      }

      return null;
    });
  }

  Future<void> unmarkCartItemPurchased(int cartItemId) async {
    await (_db.update(_db.cartItems)..where((c) => c.id.equals(cartItemId))).write(
      const CartItemsCompanion(
        isPurchased: Value(false),
      ),
    );
  }

  Future<int> deleteCartItem(int id) => _db.deleteCartItem(id);

  // User Settings
  Stream<UserSetting?> watchUserSettings() => _db.watchUserSettings();
  Future<UserSetting?> getUserSettings() => _db.getUserSettings();
  Future<int> saveUserSettings(UserSettingsCompanion entry) async {
    final res = await _db.saveUserSettings(entry);
    unawaited(WidgetSyncService.syncWidget(this));
    return res;
  }

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
    String? currencyCode,
  }) {
    return _db.insertOccasion(
      OccasionsCompanion(
        name: Value(name),
        budget: Value(budget),
        icon: Value(icon),
        description: Value(description),
        startDate: Value(startDate),
        endDate: Value(endDate),
        currencyCode: Value(currencyCode),
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

  // Full Database Backup & Restore
  Future<Map<String, dynamic>> exportBackupPayload() => _db.exportBackupPayload();
  Future<void> restoreBackupPayload(Map<String, dynamic> payload, {bool wipeExisting = true}) =>
      _db.restoreBackupPayload(payload, wipeExisting: wipeExisting);

  // Recurring Transactions
  Stream<List<RecurringWithCategory>> watchAllRecurringTransactions() =>
      _db.watchAllRecurringTransactions();

  Future<List<RecurringWithCategory>> getAllRecurringTransactions() =>
      _db.getAllRecurringTransactions();

  Future<int> addRecurringTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required String frequency,
    required DateTime startDate,
    required DateTime nextDueDate,
    DateTime? lastGeneratedDate,
    String? note,
    bool isActive = true,
    int? occasionId,
    String? receiptPath,
  }) {
    return _db.insertRecurringTransaction(
      RecurringTransactionsCompanion(
        type: Value(type),
        amount: Value(amount),
        categoryId: Value(categoryId),
        frequency: Value(frequency),
        startDate: Value(startDate),
        nextDueDate: Value(nextDueDate),
        lastGeneratedDate: Value(lastGeneratedDate),
        note: Value(note),
        isActive: Value(isActive),
        occasionId: Value(occasionId),
        receiptPath: Value(receiptPath),
      ),
    );
  }

  Future<bool> updateRecurringTransaction(RecurringTransactionsCompanion companion) =>
      _db.updateRecurringTransaction(companion);

  Future<int> deleteRecurringTransaction(int id) =>
      _db.deleteRecurringTransaction(id);

  Future<int> toggleRecurringActive(int id, bool isActive) =>
      _db.toggleRecurringActive(id, isActive);

  // App Notifications
  Stream<List<AppNotification>> watchNotifications({bool? unreadOnly, int limit = 50}) =>
      _db.watchNotifications(unreadOnly: unreadOnly, limit: limit);

  Stream<int> watchUnreadNotificationCount() =>
      _db.watchUnreadNotificationCount();

  Future<List<AppNotification>> getAllNotifications({int limit = 50}) =>
      _db.getAllNotifications(limit: limit);

  Future<int> addNotification({
    required String type,
    required String title,
    required String message,
    String icon = '🔔',
    String? payload,
  }) {
    return _db.insertNotification(
      AppNotificationsCompanion(
        type: Value(type),
        title: Value(title),
        message: Value(message),
        icon: Value(icon),
        payload: Value(payload),
      ),
    );
  }

  Future<int> markNotificationAsRead(int id) => _db.markNotificationAsRead(id);
  Future<int> markAllNotificationsAsRead() => _db.markAllNotificationsAsRead();
  Future<int> deleteNotification(int id) => _db.deleteNotification(id);
  Future<int> clearAllNotifications() => _db.clearAllNotifications();
}



