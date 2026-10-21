import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';
import 'package:spendwise/features/transactions/screens/quick_add_overlay_screen.dart';
import 'package:spendwise/features/transactions/screens/add_transaction_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late TransactionRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('QuickAddOverlayScreen renders translucent scaffold and AddTransactionSheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuickAddOverlayScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    // Verify QuickAddOverlayScreen is displayed
    expect(find.byType(QuickAddOverlayScreen), findsOneWidget);

    // Verify AddTransactionSheet is embedded directly
    expect(find.byType(AddTransactionSheet), findsOneWidget);

    // Verify record expense button is present
    expect(find.text('Record Expense'), findsOneWidget);
  });
}
