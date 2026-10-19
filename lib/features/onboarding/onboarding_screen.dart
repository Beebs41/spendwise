import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/custom_button.dart';
import '../security/lock_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final TransactionRepository repository;
  final VoidCallback onCompleted;

  const OnboardingScreen({
    super.key,
    required this.repository,
    required this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  String? _selectedImagePath;
  String _selectedCurrencyCode = 'INR';
  String _selectedCurrencySymbol = '₹';

  bool _isLockEnabled = false;
  String? _passcode;
  bool _useBiometrics = false;

  static const List<Map<String, String>> _currencies = [
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 600, maxHeight: 600, imageQuality: 85);
      if (picked != null) {
        final dir = await getApplicationDocumentsDirectory();
        final ext = picked.path.split('.').last;
        final targetPath = '${dir.path}/profile_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final saved = await File(picked.path).copy(targetPath);
        setState(() {
          _selectedImagePath = saved.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not set image: $e')),
        );
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profile Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.darkDanger),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.darkDanger)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedImagePath = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _setupPasscode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return LockScreen(
          mode: LockScreenMode.setup,
          onPasscodeSet: (pin) {
            setState(() {
              _passcode = pin;
              _isLockEnabled = true;
            });
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN configured!')),
            );
          },
        );
      },
    );
  }

  Future<void> _completeSetup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name to personalize SpendWise.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    CurrencyFormatter.activeSymbol = _selectedCurrencySymbol;
    CurrencyFormatter.activeCode = _selectedCurrencyCode;

    await widget.repository.saveUserSettings(
      UserSettingsCompanion(
        id: const drift.Value(1),
        userName: drift.Value(name),
        profileImagePath: drift.Value(_selectedImagePath),
        currencyCode: drift.Value(_selectedCurrencyCode),
        currencySymbol: drift.Value(_selectedCurrencySymbol),
        isLockEnabled: drift.Value(_isLockEnabled),
        passcode: drift.Value(_passcode),
        useBiometrics: drift.Value(_useBiometrics),
        isOnboarded: const drift.Value(true),
      ),
    );

    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // App Brand Logo
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/spendwise-app-icon-512.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      child: const Center(
                        child: Text('💰', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Welcome to SpendWise',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Your private, local-first finance companion.\nLet’s customize your experience.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Profile Photo Selector
              GestureDetector(
                onTap: _showImagePickerModal,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.2),
                      backgroundImage: _selectedImagePath != null && File(_selectedImagePath!).existsSync()
                          ? FileImage(File(_selectedImagePath!))
                          : null,
                      child: _selectedImagePath == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 46,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _showImagePickerModal,
                child: const Text('Add Profile Picture', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),

              const SizedBox(height: 16),

              // Name Input
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your Name *',
                  hintText: 'e.g. Alex Johnson',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),

              const SizedBox(height: 24),

              // Currency Selection
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Primary Currency',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _currencies.map((curr) {
                    final isSel = curr['code'] == _selectedCurrencyCode;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${curr['symbol']} ${curr['code']}'),
                        selected: isSel,
                        selectedColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.2),
                        onSelected: (val) {
                          if (val) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCurrencyCode = curr['code']!;
                              _selectedCurrencySymbol = curr['symbol']!;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // App Protection
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'App Protection & Security',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.lock_outline_rounded),
                      title: const Text('PIN Passcode Lock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        _isLockEnabled && _passcode != null
                            ? '4-digit PIN configured'
                            : 'Protect your financial logs with a PIN',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _isLockEnabled,
                      activeTrackColor: AppColors.darkPrimary,
                      onChanged: (val) {
                        if (val) {
                          _setupPasscode();
                        } else {
                          setState(() {
                            _isLockEnabled = false;
                            _passcode = null;
                          });
                        }
                      },
                    ),
                    if (_isLockEnabled) ...[
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.fingerprint_rounded),
                        title: const Text('Biometric Unlock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Unlock with Fingerprint or Face', style: TextStyle(fontSize: 12)),
                        value: _useBiometrics,
                        activeTrackColor: AppColors.darkPrimary,
                        onChanged: (val) async {
                          if (val) {
                            final auth = LocalAuthentication();
                            final canAuth = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                            if (!canAuth) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Biometrics not supported on this device')),
                                );
                              }
                              return;
                            }
                            try {
                              final ok = await auth.authenticate(localizedReason: 'Verify to enable biometric unlock');
                              if (ok) setState(() => _useBiometrics = true);
                            } catch (_) {}
                          } else {
                            setState(() => _useBiometrics = false);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              CustomButton(
                label: 'Get Started with SpendWise',
                icon: Icons.arrow_forward_rounded,
                onPressed: _completeSetup,
              ),

              const SizedBox(height: 16),
              Text(
                '🔒 All your financial data stays 100% offline on your device.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
