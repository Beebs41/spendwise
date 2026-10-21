import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/currency_service.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import '../security/lock_screen.dart';

class OnboardingSlide {
  final String icon;
  final String badge;
  final String title;
  final String description;
  final List<String> highlights;
  final Color accentColor;

  const OnboardingSlide({
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
    required this.highlights,
    required this.accentColor,
  });
}

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
  final PageController _slideController = PageController();

  int _currentSlideIndex = 0;
  bool _showPersonalization = false;

  String? _selectedImagePath;
  String _selectedCurrencyCode = 'INR';
  String _selectedCurrencySymbol = '₹';

  bool _isLockEnabled = false;
  String? _passcode;
  bool _useBiometrics = false;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      icon: '🛡️',
      badge: '100% LOCAL & PRIVATE',
      title: 'Your Finances, Solely Yours',
      description:
          'SpendWise keeps all your sensitive budgets, receipts, and loans safely on your local device. No third-party servers, no analytics selling, and zero ads.',
      highlights: [
        'Local SQLite database encryption & speed',
        'Optional PIN passcode & biometric fingerprint lock',
        'One-tap full JSON database backup & file restore',
      ],
      accentColor: Color(0xFF6C5CE7),
    ),
    OnboardingSlide(
      icon: '💱',
      badge: 'SMART TRACKING & RECEIPT PHOTOS',
      title: 'Effortless Multi-Currency Logging',
      description:
          'Record daily transactions in seconds. Attach camera receipt photos and seamlessly spend in 17 world currencies with transparent rate conversion.',
      highlights: [
        'Multi-currency support with custom exchange rates',
        'Camera & gallery receipt capture with pinch-to-zoom',
        'Advanced search and multi-facet transaction filters',
      ],
      accentColor: Color(0xFF00CEC9),
    ),
    OnboardingSlide(
      icon: '📊',
      badge: 'PROACTIVE BUDGETS & SPARKLINE',
      title: 'Visual Insights & Overspend Warnings',
      description:
          'Set category budget caps and receive proactive notifications before overspending. Discover your daily financial rhythm with trend sparklines.',
      highlights: [
        'Interactive daily spending sparkline & peak day marker',
        'Automated warning alerts at 80% & 100% budget thresholds',
        'Pacing indicators showing exactly how much you can spend per day',
      ],
      accentColor: Color(0xFFFD79A8),
    ),
    OnboardingSlide(
      icon: '🎯',
      badge: 'GOALS, WISHLISTS & TRIPS',
      title: 'Turn Intentions Into Reality',
      description:
          'Save for major milestones, link shopping wishlists to goals, and track group travel occasions with formatted WhatsApp reports for friends.',
      highlights: [
        'Savings goals with milestone celebration notifications',
        'Wishlist cart items that auto-convert to expenses when purchased',
        'Occasions & Trips tracker with custom travel currencies',
      ],
      accentColor: Color(0xFF00B894),
    ),
  ];

  @override
  void dispose() {
    _slideController.dispose();
    _nameController.dispose();
    super.dispose();
  }

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
        hasSeenAppTour: const drift.Value(false),
      ),
    );

    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showPersonalization
              ? _buildPersonalizationView(context, isDark)
              : _buildCarouselView(context, isDark),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Phase 1: Feature Showcase Carousel
  // -------------------------------------------------------------
  Widget _buildCarouselView(BuildContext context, bool isDark) {
    final slide = _slides[_currentSlideIndex];

    return Column(
      key: const ValueKey('carousel_view'),
      children: [
        // Top App Bar with Logo & Skip
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/spendwise-app-icon-512.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Text('💰', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SpendWise',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showPersonalization = true);
                },
                child: const Text('Skip Tour', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        // Carousel PageView
        Expanded(
          child: PageView.builder(
            controller: _slideController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() => _currentSlideIndex = index);
            },
            itemBuilder: (context, index) {
              final s = _slides[index];
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Visual Hero Card
                    Container(
                      width: 90,
                      height: 90,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.accentColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: s.accentColor.withValues(alpha: 0.25),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Text(s.icon, style: const TextStyle(fontSize: 44)),
                    ),
                    const SizedBox(height: 24),

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: s.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: s.accentColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        s.badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: s.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title & Description
                    Text(
                      s.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Highlight Points Card
                    CustomCard(
                      padding: const EdgeInsets.all(18),
                      borderColor: s.accentColor.withValues(alpha: 0.3),
                      child: Column(
                        children: s.highlights.map((h) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 18, color: s.accentColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    h,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Navigation Bar
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Progress Dots
              Row(
                children: List.generate(_slides.length, (i) {
                  final isCurrent = i == _currentSlideIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 6),
                    width: isCurrent ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? slide.accentColor
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              // Action button
              FilledButton.icon(
                icon: Icon(
                  _currentSlideIndex == _slides.length - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                ),
                label: Text(
                  _currentSlideIndex == _slides.length - 1 ? 'Start Setup' : 'Next',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: slide.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (_currentSlideIndex < _slides.length - 1) {
                    _slideController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                    );
                  } else {
                    setState(() => _showPersonalization = true);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Phase 2: Personalize Setup
  // -------------------------------------------------------------
  Widget _buildPersonalizationView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('personalization_view'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Tour'),
                onPressed: () => setState(() => _showPersonalization = false),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Profile Setup',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'Personalize Your Experience',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'SpendWise tailors currency, greetings, and security to your preferences.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

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
              'Select Primary Base Currency',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CurrencyService.supportedCurrencies.map((curr) {
                final isSel = curr.code == _selectedCurrencyCode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Text(curr.flagEmoji, style: const TextStyle(fontSize: 14)),
                    label: Text('${curr.symbol} ${curr.code}'),
                    selected: isSel,
                    selectedColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.2),
                    onSelected: (val) {
                      if (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCurrencyCode = curr.code;
                          _selectedCurrencySymbol = curr.symbol;
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
          Material(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
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
          ),

          const SizedBox(height: 32),

          CustomButton(
            label: 'Get Started with SpendWise',
            icon: Icons.check_circle_outline_rounded,
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
    );
  }
}
