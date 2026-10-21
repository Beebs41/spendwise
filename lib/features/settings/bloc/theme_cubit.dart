import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final TransactionRepository? _repository;
  bool _userChangedTheme = false;

  ThemeCubit([this._repository, ThemeMode initialMode = ThemeMode.system]) : super(initialMode) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    if (_repository == null) return;
    try {
      final settings = await _repository.getUserSettings();
      if (settings != null && !_userChangedTheme) {
        final mode = parseThemeMode(settings.themeMode);
        if (state != mode) {
          emit(mode);
        }
      }
    } catch (_) {}
  }

  static ThemeMode parseThemeMode(String raw) {
    switch (raw.toLowerCase()) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    _userChangedTheme = true;
    emit(mode);
    if (_repository != null) {
      try {
        final settings = await _repository.getUserSettings();
        if (settings != null) {
          await _repository.saveUserSettings(
            settings.toCompanion(true).copyWith(
                  themeMode: drift.Value(themeModeToString(mode)),
                ),
          );
        } else {
          await _repository.saveUserSettings(
            UserSettingsCompanion(
              id: const drift.Value(1),
              themeMode: drift.Value(themeModeToString(mode)),
            ),
          );
        }
      } catch (_) {}
    }
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(next);
  }
}
