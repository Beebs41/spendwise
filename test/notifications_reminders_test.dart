import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/core/services/reminder_engine.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late TransactionRepository repository;
  late int foodCategoryId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);

    foodCategoryId = await db.insertCategory(
      CategoriesCompanion.insert(
        name: 'Food & Dining',
        icon: '🍔',
        color: 0xFFFF6B6B,
        isIncome: const Value(false),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Notifications & Reminders Tests', () {
    test('Budget alert triggers at 80% and 100% with deduplication', () async {
      final now = DateTime(2026, 10, 20);

      // Set budget of 10,000
      await repository.setBudget(
        categoryId: foodCategoryId,
        amount: 10000,
        year: now.year,
        month: now.month,
      );

      // 1. Spend 7,000 (70% - below threshold)
      await ReminderEngine.checkBudgetAlerts(
        repository: repository,
        categoryId: foodCategoryId,
        currentSpend: 7000,
        budgetAmount: 10000,
        categoryName: 'Food & Dining',
        currencySymbol: '₹',
        simulatedNow: now,
      );

      var notifications = await repository.getAllNotifications();
      expect(notifications.isEmpty, isTrue);

      // 2. Spend 8,500 (85% - 80% warning threshold)
      await ReminderEngine.checkBudgetAlerts(
        repository: repository,
        categoryId: foodCategoryId,
        currentSpend: 8500,
        budgetAmount: 10000,
        categoryName: 'Food & Dining',
        currencySymbol: '₹',
        simulatedNow: now,
      );

      notifications = await repository.getAllNotifications();
      expect(notifications.length, equals(1));
      expect(notifications.first.type, equals('budget_warning'));
      expect(notifications.first.title, contains('Budget Warning'));

      // 3. Duplicate check: another transaction still in 80% range does not create duplicate
      await ReminderEngine.checkBudgetAlerts(
        repository: repository,
        categoryId: foodCategoryId,
        currentSpend: 9000,
        budgetAmount: 10000,
        categoryName: 'Food & Dining',
        currencySymbol: '₹',
        simulatedNow: now,
      );

      notifications = await repository.getAllNotifications();
      expect(notifications.length, equals(1));

      // 4. Spend 10,500 (105% - 100% exceeded threshold)
      await ReminderEngine.checkBudgetAlerts(
        repository: repository,
        categoryId: foodCategoryId,
        currentSpend: 10500,
        budgetAmount: 10000,
        categoryName: 'Food & Dining',
        currencySymbol: '₹',
        simulatedNow: now,
      );

      notifications = await repository.getAllNotifications();
      expect(notifications.length, equals(2));
      expect(notifications.any((n) => n.type == 'budget_exceeded'), isTrue);
    });

    test('Budget alert respects enableBudgetAlerts = false', () async {
      final now = DateTime(2026, 10, 20);

      // Disable budget alerts
      await repository.saveUserSettings(
        const UserSettingsCompanion(
          enableBudgetAlerts: Value(false),
        ),
      );

      await ReminderEngine.checkBudgetAlerts(
        repository: repository,
        categoryId: foodCategoryId,
        currentSpend: 15000,
        budgetAmount: 10000,
        categoryName: 'Food & Dining',
        currencySymbol: '₹',
        simulatedNow: now,
      );

      final notifications = await repository.getAllNotifications();
      expect(notifications.isEmpty, isTrue);
    });

    test('Savings milestone celebrations trigger at 50%, 80%, and 100%', () async {
      final goalId = await repository.addSavingsGoal(
        title: 'New Laptop',
        targetAmount: 100000,
        currentAmount: 0,
        color: 0xFF4ECDC4,
        icon: '💻',
      );

      final allGoals = await repository.getAllSavingsGoals();
      final goal = allGoals.firstWhere((g) => g.id == goalId);

      // 1. At 50%
      await ReminderEngine.checkSavingsMilestones(
        repository: repository,
        goal: goal.copyWith(currentAmount: 50000),
        currencySymbol: '₹',
      );

      var notifications = await repository.getAllNotifications();
      expect(notifications.length, equals(1));
      expect(notifications.first.type, equals('goal_milestone'));
      expect(notifications.first.title, contains('Halfway There'));

      // 2. At 80%
      await ReminderEngine.checkSavingsMilestones(
        repository: repository,
        goal: goal.copyWith(currentAmount: 80000),
        currencySymbol: '₹',
      );

      notifications = await repository.getAllNotifications();
      expect(notifications.length, equals(2));
      expect(notifications.any((n) => n.title.contains('Almost There')), isTrue);

      // 3. At 100%
      await ReminderEngine.checkSavingsMilestones(
        repository: repository,
        goal: goal.copyWith(currentAmount: 100000),
        currencySymbol: '₹',
      );

      notifications = await repository.getAllNotifications();
      expect(notifications.length, equals(3));
      expect(notifications.any((n) => n.type == 'goal_completed'), isTrue);

      // 4. Duplicate prevention
      await ReminderEngine.checkSavingsMilestones(
        repository: repository,
        goal: goal.copyWith(currentAmount: 105000),
        currencySymbol: '₹',
      );

      notifications = await repository.getAllNotifications();
      expect(notifications.length, equals(3));
    });

    test('Debt due date reminders identify due today and upcoming in 1-3 days', () async {
      final now = DateTime(2026, 10, 20, 10, 0);

      // 1. Debt due today
      await repository.addDebt(
        DebtsCompanion.insert(
          personName: 'Rahul',
          amount: 5000,
          type: 'borrowed',
          dueDate: Value(DateTime(2026, 10, 20, 18, 0)),
        ),
      );

      // 2. Debt due in 2 days
      await repository.addDebt(
        DebtsCompanion.insert(
          personName: 'Priya',
          amount: 3000,
          type: 'lent',
          dueDate: Value(DateTime(2026, 10, 22)),
        ),
      );

      // 3. Debt due in 10 days (should be ignored)
      await repository.addDebt(
        DebtsCompanion.insert(
          personName: 'Farhan',
          amount: 10000,
          type: 'borrowed',
          dueDate: Value(DateTime(2026, 10, 30)),
        ),
      );

      // 4. Already settled debt (should be ignored)
      await repository.addDebt(
        DebtsCompanion.insert(
          personName: 'Settled Person',
          amount: 2000,
          type: 'lent',
          dueDate: Value(DateTime(2026, 10, 20)),
          isSettled: const Value(true),
        ),
      );

      final count = await ReminderEngine.checkDueDebts(
        repository: repository,
        currencySymbol: '₹',
        simulatedNow: now,
      );

      expect(count, equals(2));

      final notifications = await repository.getAllNotifications();
      expect(notifications.length, equals(2));
      expect(notifications.any((n) => n.title.contains('Due Today: Rahul')), isTrue);
      expect(notifications.any((n) => n.title.contains('Upcoming Debt Collection')), isTrue);
    });

    test('Notification CRUD, mark as read, unread count and clear all', () async {
      final id1 = await repository.addNotification(
        type: 'budget_warning',
        title: 'Budget Alert',
        message: 'Spending near limit',
      );

      final id2 = await repository.addNotification(
        type: 'goal_milestone',
        title: 'Milestone',
        message: 'Goal achieved',
      );

      var unreadCount = await repository.watchUnreadNotificationCount().first;
      expect(unreadCount, equals(2));

      // Mark one as read
      await repository.markNotificationAsRead(id1);
      unreadCount = await repository.watchUnreadNotificationCount().first;
      expect(unreadCount, equals(1));

      // Mark all as read
      await repository.markAllNotificationsAsRead();
      unreadCount = await repository.watchUnreadNotificationCount().first;
      expect(unreadCount, equals(0));

      // Delete one
      await repository.deleteNotification(id2);
      var all = await repository.getAllNotifications();
      expect(all.length, equals(1));

      // Clear all
      await repository.clearAllNotifications();
      all = await repository.getAllNotifications();
      expect(all.isEmpty, isTrue);
    });

    test('Backup export and restore preserves notifications and notification preferences', () async {
      // Setup customized settings
      await repository.saveUserSettings(
        const UserSettingsCompanion(
          enableBudgetAlerts: Value(false),
          enableDebtReminders: Value(true),
          enableSavingsAlerts: Value(false),
        ),
      );

      await repository.addNotification(
        type: 'goal_completed',
        title: 'Goal Reached',
        message: 'Done',
        icon: '🎉',
        payload: 'test_payload',
      );

      final payload = await repository.exportBackupPayload();
      expect(payload['data']['notifications'], isList);
      expect((payload['data']['notifications'] as List).length, equals(1));

      final userSettingsData = (payload['data']['userSettings'] as List).first as Map<String, dynamic>;
      expect(userSettingsData['enableBudgetAlerts'], equals(false));
      expect(userSettingsData['enableSavingsAlerts'], equals(false));

      // Restore into fresh db
      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRepo = TransactionRepository(freshDb);

      await freshRepo.restoreBackupPayload(payload, wipeExisting: true);

      final restoredNotifications = await freshRepo.getAllNotifications();
      expect(restoredNotifications.length, equals(1));
      expect(restoredNotifications.first.title, equals('Goal Reached'));

      final restoredSettings = await freshRepo.getUserSettings();
      expect(restoredSettings?.enableBudgetAlerts, equals(false));
      expect(restoredSettings?.enableSavingsAlerts, equals(false));
      expect(restoredSettings?.enableDebtReminders, equals(true));

      await freshDb.close();
    });
  });
}
