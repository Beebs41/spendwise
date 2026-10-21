import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';
import 'package:spendwise/features/onboarding/onboarding_screen.dart';
import 'package:spendwise/features/onboarding/widgets/app_tour_sheet.dart';
import 'package:spendwise/features/onboarding/widgets/contextual_hint_card.dart';

void main() {
  group('Onboarding & App Tour Tests', () {
    late AppDatabase db;
    late TransactionRepository repository;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = TransactionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('OnboardingScreen displays feature carousel and transitions to personalization', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            repository: repository,
            onCompleted: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check first slide content
      expect(find.text('Your Finances, Solely Yours'), findsOneWidget);
      expect(find.text('Skip Tour'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next to advance
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Effortless Multi-Currency Logging'), findsOneWidget);

      // Tap Skip Tour to jump directly to personalization setup
      await tester.tap(find.text('Skip Tour'));
      await tester.pumpAndSettle();

      // Verify Personalization screen appears
      expect(find.text('Personalize Your Experience'), findsOneWidget);
      expect(find.text('Your Name *'), findsOneWidget);
      expect(find.text('Select Primary Base Currency'), findsOneWidget);
      expect(find.text('Get Started with SpendWise'), findsOneWidget);

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'John Doe');
      await tester.pumpAndSettle();

      // Ensure button is visible and tap Get Started
      await tester.ensureVisible(find.text('Get Started with SpendWise'));
      await tester.tap(find.text('Get Started with SpendWise'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);

      final settings = await repository.getUserSettings();
      expect(settings, isNotNull);
      expect(settings!.userName, 'John Doe');
      expect(settings.isOnboarded, isTrue);
      expect(settings.hasSeenAppTour, isFalse);
    });

    testWidgets('AppTourSheet walks through 5 steps and marks tour completed', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      int? switchedTab;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTourSheet(
              repository: repository,
              onSwitchTab: (index) => switchedTab = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Home Dashboard
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Home Dashboard'), findsOneWidget);
      expect(find.text('Open Home Tab'), findsOneWidget);

      // Test tab switch callback
      await tester.ensureVisible(find.text('Open Home Tab'));
      await tester.tap(find.text('Open Home Tab'));
      await tester.pumpAndSettle();
      expect(switchedTab, 0);

      // Next to Step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.text('Activity & Transactions'), findsOneWidget);

      // Next to Step 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.text('Monthly Budgets'), findsOneWidget);

      // Next to Step 4
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 5'), findsOneWidget);
      expect(find.text('Savings & Wishlists'), findsOneWidget);

      // Next to Step 5
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 5 of 5'), findsOneWidget);
      expect(find.text('Trips, Occasions & Backups'), findsOneWidget);
      expect(find.text('Finish Tour'), findsOneWidget);

      // Finish Tour
      await tester.tap(find.text('Finish Tour'));
      await tester.pumpAndSettle();

      final settings = await repository.getUserSettings();
      expect(settings?.hasSeenAppTour, isTrue);
    });

    testWidgets('ContextualHintCard renders message and handles action and dismissal', (tester) async {
      bool actionTapped = false;
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextualHintCard(
              title: 'Pro-Tip',
              message: 'Check your daily spending trend.',
              actionLabel: 'Learn More',
              onAction: () => actionTapped = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pro-Tip'), findsOneWidget);
      expect(find.text('Check your daily spending trend.'), findsOneWidget);
      expect(find.text('Learn More'), findsOneWidget);

      // Tap action
      await tester.tap(find.text('Learn More'));
      await tester.pumpAndSettle();
      expect(actionTapped, isTrue);

      // Tap dismiss (close button)
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);

      // After dismissal, card content is gone
      expect(find.text('Check your daily spending trend.'), findsNothing);
    });

    test('Backup export and restore preserves hasSeenAppTour', () async {
      // Seed settings with hasSeenAppTour: true
      final current = await repository.getUserSettings();
      expect(current, isNotNull);

      await repository.saveUserSettings(
        current!.toCompanion(true).copyWith(
              userName: const Value('Alice'),
              hasSeenAppTour: const Value(true),
            ),
      );

      final payload = await db.exportBackupPayload();
      final data = payload['data'] as Map<String, dynamic>;
      expect(data['userSettings'], isNotEmpty);
      expect(data['userSettings'].first['hasSeenAppTour'], isTrue);

      // Restore into fresh database
      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRepo = TransactionRepository(freshDb);

      await freshDb.restoreBackupPayload(payload);

      final restored = await freshRepo.getUserSettings();
      expect(restored, isNotNull);
      expect(restored!.userName, 'Alice');
      expect(restored.hasSeenAppTour, isTrue);

      await freshDb.close();
    });
  });
}
