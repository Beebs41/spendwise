import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';
import 'package:spendwise/features/settings/bloc/theme_cubit.dart';
import 'package:spendwise/features/settings/settings_screen.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('ThemeCubit parse and toString helpers work accurately', () {
    expect(ThemeCubit.parseThemeMode('dark'), equals(ThemeMode.dark));
    expect(ThemeCubit.parseThemeMode('light'), equals(ThemeMode.light));
    expect(ThemeCubit.parseThemeMode('system'), equals(ThemeMode.system));
    expect(ThemeCubit.parseThemeMode('unknown'), equals(ThemeMode.system));

    expect(ThemeCubit.themeModeToString(ThemeMode.dark), equals('dark'));
    expect(ThemeCubit.themeModeToString(ThemeMode.light), equals('light'));
    expect(ThemeCubit.themeModeToString(ThemeMode.system), equals('system'));
  });

  test('ThemeCubit persists theme change to database', () async {
    final cubit = ThemeCubit(repository, ThemeMode.system);

    await cubit.setTheme(ThemeMode.light);
    expect(cubit.state, equals(ThemeMode.light));

    final settings = await repository.getUserSettings();
    expect(settings?.themeMode, equals('light'));

    await cubit.setTheme(ThemeMode.dark);
    expect(cubit.state, equals(ThemeMode.dark));

    final updated = await repository.getUserSettings();
    expect(updated?.themeMode, equals('dark'));

    await cubit.close();
  });

  test('ThemeCubit loads saved theme on initialization', () async {
    // Seed database with light theme
    await repository.saveUserSettings(
      const UserSettingsCompanion(
        id: Value(1),
        themeMode: Value('light'),
      ),
    );

    final cubit = ThemeCubit(repository);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state, equals(ThemeMode.light));
    await cubit.close();
  });

  test('Database backup export and restore preserves themeMode', () async {
    await repository.saveUserSettings(
      const UserSettingsCompanion(
        id: Value(1),
        themeMode: Value('light'),
      ),
    );

    final payload = await repository.exportBackupPayload();
    final data = payload['data'] as Map<String, dynamic>;
    final settingsList = data['userSettings'] as List;
    expect(settingsList.isNotEmpty, isTrue);
    expect(settingsList.first['themeMode'], equals('light'));

    // Open second clean database to restore
    final db2 = AppDatabase(NativeDatabase.memory());
    final repo2 = TransactionRepository(db2);
    await repo2.restoreBackupPayload(payload, wipeExisting: true);

    final restored = await repo2.getUserSettings();
    expect(restored?.themeMode, equals('light'));
    await db2.close();
  });

  testWidgets('SettingsScreen displays 3-way theme options and switches theme', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final cubit = ThemeCubit(repository, ThemeMode.system);

    await tester.pumpWidget(
      BlocProvider<ThemeCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: SettingsScreen(repository: repository),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('System Auto'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);

    // Tap Light option
    await tester.ensureVisible(find.text('Light'));
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(cubit.state, equals(ThemeMode.light));

    // Tap Dark option
    await tester.ensureVisible(find.text('Dark'));
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(cubit.state, equals(ThemeMode.dark));

    await cubit.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
