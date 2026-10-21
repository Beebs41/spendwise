import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/transaction_repository.dart';
import 'features/settings/bloc/theme_cubit.dart';
import 'features/transactions/screens/quick_add_overlay_screen.dart';

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
            onGenerateRoute: (settings) {
              final uri = Uri.tryParse(settings.name ?? '') ?? Uri();
              if (uri.path == '/quick_add') {
                final type = uri.queryParameters['type'] ?? 'expense';
                return PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (context, _, _) => QuickAddOverlayScreen(
                    repository: repository,
                    initialType: type,
                  ),
                  transitionsBuilder: (context, animation, _, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                );
              }
              return MaterialPageRoute(
                builder: (context) => MainShell(repository: repository),
              );
            },
            home: MainShell(repository: repository),
          );
        },
      ),
    );
  }
}
