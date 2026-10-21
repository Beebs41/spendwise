import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/transaction_repository.dart';
import 'features/settings/bloc/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final repository = TransactionRepository(database);

  ThemeMode initialThemeMode = ThemeMode.system;
  try {
    final settings = await repository.getUserSettings();
    if (settings != null) {
      initialThemeMode = ThemeCubit.parseThemeMode(settings.themeMode);
    }
  } catch (_) {}

  runApp(SpendWiseApp(
    repository: repository,
    initialThemeMode: initialThemeMode,
  ));
}

class SpendWiseApp extends StatelessWidget {
  final TransactionRepository repository;
  final ThemeMode initialThemeMode;

  const SpendWiseApp({
    super.key,
    required this.repository,
    this.initialThemeMode = ThemeMode.system,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(repository, initialThemeMode),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'SpendWise',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MainShell(repository: repository),
          );
        },
      ),
    );
  }
}
