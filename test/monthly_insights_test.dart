import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/features/dashboard/widgets/monthly_insights_card.dart';

void main() {
  Category createCategory({
    required int id,
    required String name,
    required String icon,
    required int color,
    bool isIncome = false,
  }) {
    return Category(
      id: id,
      name: name,
      icon: icon,
      color: color,
      isIncome: isIncome,
      sortOrder: 0,
      isDefault: false,
    );
  }

  Transaction createTransaction({
    required int id,
    required double amount,
    required String type,
    required int categoryId,
    required DateTime date,
  }) {
    return Transaction(
      id: id,
      amount: amount,
      type: type,
      categoryId: categoryId,
      date: date,
      note: 'Test note',
      isRecurring: false,
      createdAt: date,
    );
  }

  testWidgets('MonthlyInsightsCard displays first month banner when no previous transactions', (tester) async {
    final catFood = createCategory(id: 1, name: 'Food', icon: '🍔', color: 0xFFFF5722);
    final now = DateTime(2026, 10, 20);

    final currentTransactions = [
      TransactionWithCategory(
        transaction: createTransaction(id: 1, amount: 500, type: 'expense', categoryId: 1, date: DateTime(2026, 10, 5)),
        category: catFood,
      ),
      TransactionWithCategory(
        transaction: createTransaction(id: 2, amount: 2000, type: 'income', categoryId: 1, date: DateTime(2026, 10, 1)),
        category: catFood,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthlyInsightsCard(
              currentTransactions: currentTransactions,
              previousTransactions: const [],
              currentDate: now,
            ),
          ),
        ),
      ),
    );

    expect(find.text('FINANCIAL INTELLIGENCE'), findsOneWidget);
    expect(find.text('Monthly Insights & Trends'), findsOneWidget);
    expect(find.textContaining('First recorded month!'), findsOneWidget);
    expect(find.textContaining('Top Category: Food'), findsOneWidget);
    // Daily average over 20 days: 500 / 20 = 25/day
    expect(find.textContaining('/day'), findsOneWidget);
  });

  testWidgets('MonthlyInsightsCard displays MoM spend increase when current > previous', (tester) async {
    final catFood = createCategory(id: 1, name: 'Food', icon: '🍔', color: 0xFFFF5722);
    final now = DateTime(2026, 10, 15);

    // Prev month: 1000 expense
    final prevTransactions = [
      TransactionWithCategory(
        transaction: createTransaction(id: 1, amount: 1000, type: 'expense', categoryId: 1, date: DateTime(2026, 9, 10)),
        category: catFood,
      ),
    ];

    // Current month: 1500 expense (+50%)
    final currentTransactions = [
      TransactionWithCategory(
        transaction: createTransaction(id: 2, amount: 1500, type: 'expense', categoryId: 1, date: DateTime(2026, 10, 5)),
        category: catFood,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthlyInsightsCard(
              currentTransactions: currentTransactions,
              previousTransactions: prevTransactions,
              currentDate: now,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('50% more'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
  });

  testWidgets('MonthlyInsightsCard displays MoM spend decrease when current < previous', (tester) async {
    final catFood = createCategory(id: 1, name: 'Food', icon: '🍔', color: 0xFFFF5722);
    final now = DateTime(2026, 10, 15);

    // Prev month: 2000 expense
    final prevTransactions = [
      TransactionWithCategory(
        transaction: createTransaction(id: 1, amount: 2000, type: 'expense', categoryId: 1, date: DateTime(2026, 9, 10)),
        category: catFood,
      ),
    ];

    // Current month: 1500 expense (-25%)
    final currentTransactions = [
      TransactionWithCategory(
        transaction: createTransaction(id: 2, amount: 1500, type: 'expense', categoryId: 1, date: DateTime(2026, 10, 5)),
        category: catFood,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthlyInsightsCard(
              currentTransactions: currentTransactions,
              previousTransactions: prevTransactions,
              currentDate: now,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('25% less'), findsOneWidget);
    expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
  });

  testWidgets('MonthlyInsightsCard switches tabs between Overview and Trend', (tester) async {
    final catFood = createCategory(id: 1, name: 'Food', icon: '🍔', color: 0xFFFF5722);
    final now = DateTime(2026, 10, 10);

    final currentTransactions = [
      TransactionWithCategory(
        transaction: createTransaction(id: 1, amount: 300, type: 'expense', categoryId: 1, date: DateTime(2026, 10, 2)),
        category: catFood,
      ),
      TransactionWithCategory(
        transaction: createTransaction(id: 2, amount: 800, type: 'expense', categoryId: 1, date: DateTime(2026, 10, 6)),
        category: catFood,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthlyInsightsCard(
              currentTransactions: currentTransactions,
              previousTransactions: const [],
              currentDate: now,
            ),
          ),
        ),
      ),
    );

    // Initially Overview tab is active
    expect(find.text('DAILY AVERAGE'), findsOneWidget);
    expect(find.text('DAILY SPENDING TREND'), findsNothing);

    // Tap Trend tab
    await tester.tap(find.text('Trend'));
    await tester.pumpAndSettle();

    // Now Trend tab is active
    expect(find.text('DAILY SPENDING TREND'), findsOneWidget);
    expect(find.textContaining('Peak Day: Day 6'), findsOneWidget);
    expect(find.text('DAILY AVERAGE'), findsNothing);

    // Switch back to Overview
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    expect(find.text('DAILY AVERAGE'), findsOneWidget);
  });
}
