import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:local_auth/local_auth.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/custom_card.dart';
import '../categories/category_management_sheet.dart';
import '../debts/debts_screen.dart';
import '../occasions/occasions_screen.dart';
import '../reports/whatsapp_reports_sheet.dart';
import '../security/lock_screen.dart';
import 'bloc/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  final TransactionRepository repository;

  const SettingsScreen({super.key, required this.repository});

  static const List<Map<String, String>> _supportedCurrencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'SAR', 'symbol': '﷼', 'name': 'Saudi Riyal'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CHF', 'symbol': 'CHF', 'name': 'Swiss Franc'},
  ];

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'SW';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  void _showEditProfileDialog(BuildContext context, UserSetting settings) {
    final nameController = TextEditingController(text: settings.userName);
    String? pickedImagePath = settings.profileImagePath;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            final hasPhoto = pickedImagePath != null && File(pickedImagePath!).existsSync();

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Edit Profile',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Avatar Preview
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            backgroundImage: hasPhoto ? FileImage(File(pickedImagePath!)) : null,
                            child: hasPhoto
                                ? null
                                : Text(
                                    _getInitials(nameController.text.isNotEmpty ? nameController.text : settings.userName),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Photo Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final img = await picker.pickImage(source: ImageSource.gallery);
                              if (img != null) {
                                setModalState(() => pickedImagePath = img.path);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text('Camera', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final img = await picker.pickImage(source: ImageSource.camera);
                              if (img != null) {
                                setModalState(() => pickedImagePath = img.path);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          if (hasPhoto) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                              label: const Text('Remove', style: TextStyle(fontSize: 12, color: Colors.red)),
                              onPressed: () {
                                setModalState(() => pickedImagePath = null);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      TextField(
                        controller: nameController,
                        onChanged: (_) => setModalState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Your Name',
                          hintText: 'e.g. Shabeeb Aslam',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      FilledButton(
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          if (newName.isNotEmpty) {
                            await repository.saveUserSettings(
                              settings.toCompanion(true).copyWith(
                                    userName: drift.Value(newName),
                                    profileImagePath: drift.Value(pickedImagePath),
                                  ),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context, UserSetting settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Default Currency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _supportedCurrencies.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  itemBuilder: (context, index) {
                    final curr = _supportedCurrencies[index];
                    final isSelected = curr['code'] == settings.currencyCode;

                    return ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          curr['symbol']!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ),
                        ),
                      ),
                      title: Text(curr['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(curr['code']!),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                          : null,
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        CurrencyFormatter.activeSymbol = curr['symbol']!;
                        CurrencyFormatter.activeCode = curr['code']!;

                        await repository.saveUserSettings(
                          settings.toCompanion(true).copyWith(
                                currencyCode: drift.Value(curr['code']!),
                                currencySymbol: drift.Value(curr['symbol']!),
                              ),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPasscodeSetup(BuildContext context, UserSetting settings, {bool isChanging = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return LockScreen(
          mode: isChanging ? LockScreenMode.change : LockScreenMode.setup,
          onPasscodeSet: (pin) async {
            await repository.saveUserSettings(
              settings.toCompanion(true).copyWith(
                    passcode: drift.Value(pin),
                    isLockEnabled: const drift.Value(true),
                  ),
            );
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Passcode lock configured successfully!')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _shareApk(BuildContext context) async {
    HapticFeedback.mediumImpact();
    try {
      if (Platform.isAndroid) {
        const channel = MethodChannel('com.shabeeb.spendwise/apk');
        final String? apkPath = await channel.invokeMethod<String>('getApkPath');

        if (apkPath != null && await File(apkPath).exists()) {
          await SharePlus.instance.share(
            ShareParams(
              files: [
                XFile(
                  apkPath,
                  mimeType: 'application/vnd.android.package-archive',
                  name: 'SpendWise.apk',
                ),
              ],
              subject: 'SpendWise APK — Private Expense Tracker',
              text: 'Here is the SpendWise Android APK. Install and enjoy 100% private, offline budgeting!',
            ),
          );
          return;
        }
      }
    } catch (_) {}

    SharePlus.instance.share(
      ShareParams(
        text: 'SpendWise — A private, local-first expense tracker and budgeting app with no subscriptions or tracking.',
        subject: 'SpendWise App',
      ),
    );
  }

  Future<void> _exportCSV(BuildContext context) async {
    HapticFeedback.mediumImpact();
    try {
      final categories = await repository.getAllCategories();
      final catMap = {for (var c in categories) c.id: c.name};

      final occasions = await repository.getAllOccasions();
      final occMap = {for (var o in occasions) o.id: o.name};

      final userSettings = await repository.getUserSettings();
      final currency = userSettings?.currencyCode ?? 'INR';

      final transactions = await repository.getAllTransactions();

      List<List<dynamic>> rows = [
        [
          'Transaction ID',
          'Date',
          'Time',
          'Type',
          'Category',
          'Amount',
          'Currency',
          'Occasion / Trip',
          'Note',
          'Recurring',
          'Recorded At'
        ],
      ];

      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm:ss');

      for (var t in transactions) {
        rows.add([
          t.transaction.id,
          dateFormat.format(t.transaction.date),
          timeFormat.format(t.transaction.date),
          t.transaction.type.toUpperCase(),
          catMap[t.transaction.categoryId] ?? t.category.name,
          t.transaction.amount,
          currency,
          t.transaction.occasionId != null ? (occMap[t.transaction.occasionId] ?? 'Occasion #${t.transaction.occasionId}') : 'None',
          t.transaction.note ?? '',
          t.transaction.isRecurring ? 'YES' : 'NO',
          dateFormat.format(t.transaction.createdAt),
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'SpendWise_Export_$timestamp.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvData);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'text/csv',
              name: fileName,
            ),
          ],
          subject: 'SpendWise Full Financial Data Export ($timestamp)',
          text: 'Attached is your complete SpendWise transaction history exported in CSV format.',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    }
  }

  void _showDetailedAboutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  children: [
                    // Brand Logo & Name
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/spendwise-app-icon-512.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'SpendWise',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Version 2.0.0 • Build 2026.1',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Private Wealth Architect & Smart Expense Tracker',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Privacy Manifesto Section
                    _buildAboutInfoCard(
                      ctx,
                      icon: Icons.shield_outlined,
                      title: '100% Local-First & Zero Telemetry',
                      description:
                          'Your financial records belong exclusively to you. SpendWise operates on an embedded SQLite database located inside your device sandbox. There are no analytics trackers, no advertising SDKs, and zero external servers.',
                    ),
                    const SizedBox(height: 12),

                    // Feature Highlights
                    _buildAboutInfoCard(
                      ctx,
                      icon: Icons.auto_graph_rounded,
                      title: 'Financial Intelligence Engine',
                      description:
                          '• Dynamic Activities Calendar: Filter records by exact date or month.\n• Multi-Category Budgets: In-place category creation with smart alerts.\n• Occasional Trip Tracker: Dedicated budgets for vacations and outings.\n• Instant WhatsApp Digests: 1-tap beautifully aligned financial summaries.\n• Passcode & Biometric Guard: Defense-in-depth app lock.\n• Authentic CSV Export: Full database export ready for spreadsheets.',
                    ),
                    const SizedBox(height: 12),

                    // Tech Stack
                    _buildAboutInfoCard(
                      ctx,
                      icon: Icons.code_rounded,
                      title: 'Architecture & Framework',
                      description:
                          'Engineered with Google Flutter 3.x, Drift Reactive SQLite ORM, BLoC/Cubit state orchestration, fl_chart high-performance vector charts, and Material Design 3 luxury aesthetics.',
                    ),
                    const SizedBox(height: 12),

                    // Developer Credits
                    _buildAboutInfoCard(
                      ctx,
                      icon: Icons.favorite_rounded,
                      title: 'Creator & Developer',
                      description:
                          'Designed, engineered, and maintained with ❤️ by Shabeeb Aslam.\nFor suggestions, feedback, or inquiries, reach out via the app settings or project repository.',
                    ),
                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutInfoCard(BuildContext context, {required IconData icon, required String title, required String description}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeCubit = context.watch<ThemeCubit>();

    return StreamBuilder<UserSetting?>(
      stream: repository.watchUserSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ??
            const UserSetting(
              id: 1,
              userName: 'Shabeeb Aslam',
              currencyCode: 'INR',
              currencySymbol: '₹',
              isLockEnabled: false,
              useBiometrics: false,
              isOnboarded: true,
            );

        // Keep CurrencyFormatter in sync
        CurrencyFormatter.activeSymbol = settings.currencySymbol;
        CurrencyFormatter.activeCode = settings.currencyCode;

        final hasCustomPhoto = settings.profileImagePath != null && File(settings.profileImagePath!).existsSync();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings & Profile'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              // Profile Card
              CustomCard(
                padding: const EdgeInsets.all(20),
                borderColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
                onTap: () => _showEditProfileDialog(context, settings),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      backgroundImage: hasCustomPhoto ? FileImage(File(settings.profileImagePath!)) : null,
                      child: hasCustomPhoto
                          ? null
                          : Text(
                              _getInitials(settings.userName),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Local Storage • Private & Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit Profile & Photo',
                      onPressed: () => _showEditProfileDialog(context, settings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Features & Tools
              _SectionHeader(title: 'FEATURES & TOOLS'),
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Add, edit, or customize income & expense categories', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => CategoryManagementSheet.show(context, repository),
                    ),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.beach_access_rounded),
                      title: const Text('Occasions & Trips Tracker', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Track budgets for vacations, outings, weddings, or events', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => OccasionsScreen.show(context, repository),
                    ),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.handshake_outlined),
                      title: const Text('Debts & Loans Tracker', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Manage money you lent or borrowed with contact sync and reminders', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DebtsScreen(repository: repository)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Appearance Section
              _SectionHeader(title: 'APPEARANCE'),
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      secondary: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                      title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        isDark ? 'Luxury Dark Theme' : 'Clean Warm Light Theme',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      value: themeCubit.state == ThemeMode.dark,
                      activeTrackColor: AppColors.darkPrimary,
                      onChanged: (isDarkTheme) {
                        HapticFeedback.selectionClick();
                        themeCubit.toggleTheme();
                      },
                    ),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.currency_exchange_rounded),
                      title: const Text('Default Currency', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${settings.currencyCode} (${settings.currencySymbol})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showCurrencyPicker(context, settings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security & Protection
              _SectionHeader(title: 'SECURITY & PRIVACY'),
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.lock_outline_rounded),
                      title: const Text('Passcode App Lock', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        settings.isLockEnabled ? 'App is protected by 4-digit PIN' : 'Disabled',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: settings.isLockEnabled,
                      activeTrackColor: AppColors.darkPrimary,
                      onChanged: (enabled) async {
                        HapticFeedback.selectionClick();
                        if (enabled) {
                          if (settings.passcode == null || settings.passcode!.length != 4) {
                            _showPasscodeSetup(context, settings);
                          } else {
                            await repository.saveUserSettings(
                              settings.toCompanion(true).copyWith(
                                    isLockEnabled: const drift.Value(true),
                                  ),
                            );
                          }
                        } else {
                          await repository.saveUserSettings(
                            settings.toCompanion(true).copyWith(
                                  isLockEnabled: const drift.Value(false),
                                ),
                          );
                        }
                      },
                    ),
                    if (settings.isLockEnabled) ...[
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                      ListTile(
                        leading: const Icon(Icons.pin_rounded),
                        title: const Text('Change Passcode', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Update your 4-digit PIN', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showPasscodeSetup(context, settings, isChanging: true),
                      ),
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.fingerprint_rounded),
                        title: const Text('Biometric Unlock', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Use fingerprint or face recognition', style: TextStyle(fontSize: 12)),
                        value: settings.useBiometrics,
                        activeTrackColor: AppColors.darkPrimary,
                        onChanged: (enabled) async {
                          HapticFeedback.selectionClick();
                          if (enabled) {
                            final auth = LocalAuthentication();
                            final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                            if (!canCheck) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Biometrics not available on this device')),
                                );
                              }
                              return;
                            }
                            try {
                              final didAuth = await auth.authenticate(
                                localizedReason: 'Verify biometrics to enable biometric unlock',
                              );
                              if (didAuth) {
                                await repository.saveUserSettings(
                                  settings.toCompanion(true).copyWith(
                                        useBiometrics: const drift.Value(true),
                                      ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Biometric authentication failed: $e')),
                                );
                              }
                            }
                          } else {
                            await repository.saveUserSettings(
                              settings.toCompanion(true).copyWith(
                                    useBiometrics: const drift.Value(false),
                                  ),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data & Sharing
              _SectionHeader(title: 'DATA & SHARING'),
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.mark_chat_read_outlined, color: Color(0xFF25D366)),
                      title: const Text('Share Financial Report (WhatsApp)', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Share formatted monthly, category, or trip digests', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => WhatsAppReportsSheet.show(context, repository),
                    ),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Export Data (CSV File)', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Export complete transaction history as spreadsheet CSV', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _exportCSV(context),
                    ),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.android_rounded),
                      title: const Text('Share SpendWise (APK)', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Send app installer APK directly to friends', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.share_rounded),
                      onTap: () => _shareApk(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Detailed About Section
              _SectionHeader(title: 'ABOUT & MANIFESTO'),
              CustomCard(
                padding: const EdgeInsets.all(18),
                onTap: () => _showDetailedAboutDialog(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/spendwise-app-icon-512.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SpendWise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                'v2.0.0 • Local-First Architecture',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.info_outline_rounded),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SpendWise guarantees 100% data ownership. All budgets, records, and preferences remain permanently on your local SQLite storage. Crafted with passion by Shabeeb Aslam.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _showDetailedAboutDialog(context),
                      child: Text(
                        'Read Full Privacy Manifesto & Credits →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
      ),
    );
  }
}
