import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/core/services/widget_sync_service.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';
import 'package:spendwise/features/settings/widgets/home_screen_widget_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android Home Screen Widget & WidgetSyncService Tests', () {
    late AppDatabase db;
    late TransactionRepository repository;
    final List<MethodCall> methodCalls = [];

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = TransactionRepository(db);
      methodCalls.clear();

      // Mock MethodChannel for widget
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WidgetSyncService.channel, (call) async {
        methodCalls.add(call);
        if (call.method == 'updateWidget') {
          return true;
        } else if (call.method == 'getInitialRoute') {
          return '/add_transaction';
        }
        return null;
      });
    });

    tearDown(() async {
      await db.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WidgetSyncService.channel, null);
    });

    test('calculateWidgetData correctly computes today spend without budget', () async {
      final now = DateTime(2026, 10, 20, 14, 30);

      // Add category
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Food & Dining',
              icon: '🍔',
              color: 0xFF10B981,
            ),
          );

      // Add expense transaction today
      await repository.addTransaction(
        type: 'expense',
        amount: 250.0,
        categoryId: catId,
        date: now,
      );

      // Add income transaction today (should not count towards expense spend)
      await repository.addTransaction(
        type: 'income',
        amount: 5000.0,
        categoryId: catId,
        date: now,
      );

      // Add expense from yesterday (should count towards month, not today)
      await repository.addTransaction(
        type: 'expense',
        amount: 150.0,
        categoryId: catId,
        date: now.subtract(const Duration(days: 1)),
      );

      final data = await WidgetSyncService.calculateWidgetData(repository, now);

      expect(data.rawTodaySpend, 250.0);
      expect(data.todaySpend, contains('250'));
      expect(data.budgetStatus, 'No Budget');
      expect(data.statusColor, '#94A3B8');
      expect(data.budgetRemaining, 'Not Set');
    });

    test('calculateWidgetData evaluates On Track, Near Limit, and Over Budget', () async {
      final now = DateTime(2026, 10, 20, 12, 0);

      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Groceries',
              icon: '🛒',
              color: 0xFF10B981,
            ),
          );

      // Set monthly budget of 1,000
      await repository.setBudget(
        categoryId: catId,
        amount: 1000.0,
        year: now.year,
        month: now.month,
      );

      // Scenario 1: Spent 500 (50% -> On Track)
      await repository.addTransaction(
        type: 'expense',
        amount: 500.0,
        categoryId: catId,
        date: now,
      );

      var data = await WidgetSyncService.calculateWidgetData(repository, now);
      expect(data.budgetStatus, 'On Track');
      expect(data.statusColor, '#10B981');
      expect(data.rawBudgetRemaining, 500.0);
      expect(data.budgetPercent, 50);
      expect(data.budgetSpent, contains('500'));
      expect(data.budgetTotal, contains('1,000'));
      expect(data.footerText, contains('50% budget remaining'));

      // Scenario 2: Spent additional 350 (Total 850 / 85% -> Near Limit)
      await repository.addTransaction(
        type: 'expense',
        amount: 350.0,
        categoryId: catId,
        date: now,
      );

      data = await WidgetSyncService.calculateWidgetData(repository, now);
      expect(data.budgetStatus, 'Near Limit');
      expect(data.statusColor, '#F59E0B');
      expect(data.rawBudgetRemaining, 150.0);
      expect(data.budgetPercent, 85);
      expect(data.footerText, contains('15% budget remaining'));

      // Scenario 3: Spent additional 200 (Total 1,050 / 105% -> Over Budget)
      await repository.addTransaction(
        type: 'expense',
        amount: 200.0,
        categoryId: catId,
        date: now,
      );

      data = await WidgetSyncService.calculateWidgetData(repository, now);
      expect(data.budgetStatus, 'Over Budget');
      expect(data.statusColor, '#EF4444');
      expect(data.rawBudgetRemaining, -50.0);
      expect(data.budgetPercent, 105);
      expect(data.footerText, contains('5% over budget limit'));
    });

    test('syncWidget pushes payload to native Android MethodChannel', () async {
      final now = DateTime(2026, 10, 20, 18, 45);

      final result = await WidgetSyncService.syncWidget(repository, now);
      expect(result, isTrue);

      final updateCalls = methodCalls.where((c) => c.method == 'updateWidget').toList();
      expect(updateCalls, isNotEmpty);

      final args = updateCalls.last.arguments as Map<dynamic, dynamic>;
      expect(args.containsKey('todaySpend'), isTrue);
      expect(args.containsKey('budgetRemaining'), isTrue);
      expect(args.containsKey('budgetStatus'), isTrue);
      expect(args.containsKey('statusColor'), isTrue);
      expect(args.containsKey('lastUpdated'), isTrue);
      expect(args.containsKey('footerText'), isTrue);
      expect(args.containsKey('budgetSpent'), isTrue);
      expect(args.containsKey('budgetTotal'), isTrue);
      expect(args.containsKey('budgetPercent'), isTrue);
    });

    test('getInitialRoute returns deep link action route from native', () async {
      final route = await WidgetSyncService.getInitialRoute();
      expect(route, '/add_transaction');
    });

    testWidgets('HomeScreenWidgetCard renders live simulation and toggles setup steps', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeScreenWidgetCard(repository: repository),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and titles
      expect(find.text('Android Home Screen Widget'), findsOneWidget);
      expect(find.text("TODAY'S SPEND"), findsOneWidget);
      expect(find.text("BUDGET LEFT"), findsOneWidget);
      expect(find.text('SpendWise'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      // Check setup instructions toggle
      expect(find.text('How to place on your Android Home Screen'), findsOneWidget);
      expect(find.text('Long-press on any empty area of your Android Home Screen.'), findsNothing);

      // Tap instructions toggle
      await tester.tap(find.text('How to place on your Android Home Screen'));
      await tester.pumpAndSettle();

      expect(find.text('Hide Setup Steps'), findsOneWidget);
      expect(find.text('Long-press on any empty area of your Android Home Screen.'), findsOneWidget);

      // Tap Sync button
      await tester.ensureVisible(find.byKey(const Key('sync_widget_button')));
      await tester.tap(find.byKey(const Key('sync_widget_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(methodCalls.map((c) => c.method), contains('updateWidget'));
      expect(find.text('Home screen widget synchronized with live balances'), findsOneWidget);
    });
  });
}
