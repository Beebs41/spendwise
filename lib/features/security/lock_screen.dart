import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/app_colors.dart';

enum LockScreenMode { unlock, setup, change }

class LockScreen extends StatefulWidget {
  final String? savedPasscode;
  final bool useBiometrics;
  final LockScreenMode mode;
  final VoidCallback? onUnlocked;
  final Function(String newPasscode)? onPasscodeSet;

  const LockScreen({
    super.key,
    this.savedPasscode,
    this.useBiometrics = true,
    this.mode = LockScreenMode.unlock,
    this.onUnlocked,
    this.onPasscodeSet,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _enteredPin = '';
  String? _firstPinForSetup;
  bool _isError = false;
  String _message = 'Enter your 4-digit Passcode';
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.mode == LockScreenMode.setup || widget.mode == LockScreenMode.change) {
      _message = 'Create a 4-Digit Passcode';
    } else {
      _message = 'Enter your 4-digit Passcode';
      if (widget.useBiometrics) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _authenticateWithBiometrics();
        });
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) return;

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Unlock SpendWise with your fingerprint or face',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuth && mounted) {
        HapticFeedback.mediumImpact();
        widget.onUnlocked?.call();
      }
    } catch (_) {
      // If biometrics fail or are cancelled, user uses PIN
    }
  }

  void _onKeypadTap(String value) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.selectionClick();

    setState(() {
      _isError = false;
      _enteredPin += value;
    });

    if (_enteredPin.length == 4) {
      _handleCompletedPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _isError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _handleCompletedPin() async {
    if (widget.mode == LockScreenMode.unlock) {
      if (_enteredPin == widget.savedPasscode) {
        HapticFeedback.mediumImpact();
        widget.onUnlocked?.call();
      } else {
        HapticFeedback.heavyImpact();
        _shakeController.forward(from: 0.0);
        setState(() {
          _isError = true;
          _message = 'Incorrect Passcode. Try again.';
          _enteredPin = '';
        });
      }
    } else {
      // Setup or Change mode
      if (_firstPinForSetup == null) {
        setState(() {
          _firstPinForSetup = _enteredPin;
          _enteredPin = '';
          _message = 'Confirm your 4-Digit Passcode';
        });
      } else {
        if (_enteredPin == _firstPinForSetup) {
          HapticFeedback.mediumImpact();
          widget.onPasscodeSet?.call(_enteredPin);
        } else {
          HapticFeedback.heavyImpact();
          _shakeController.forward(from: 0.0);
          setState(() {
            _isError = true;
            _message = 'Passcodes did not match. Start over.';
            _firstPinForSetup = null;
            _enteredPin = '';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // SpendWise Logo
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text('💰', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'SpendWise',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isError
                    ? AppColors.darkDanger
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              child: Text(_message),
            ),
            const SizedBox(height: 32),

            // 4 PIN Dots
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final offset = _shakeController.value == 0
                    ? 0.0
                    : (10.0 * (1.0 - _shakeController.value) * (2.0 * (_enteredPin.length % 2 == 0 ? 1 : -1)));
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? (_isError ? AppColors.darkDanger : primary)
                              : Colors.transparent,
                          border: Border.all(
                            color: _isError
                                ? AppColors.darkDanger
                                : (isFilled
                                    ? primary
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                            width: 2,
                          ),
                          boxShadow: isFilled && !_isError
                              ? [BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 8)]
                              : null,
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            const Spacer(),

            // Custom Luxury Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['1', '2', '3'].map((d) => _buildKeypadButton(d, primary, isDark)).toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['4', '5', '6'].map((d) => _buildKeypadButton(d, primary, isDark)).toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['7', '8', '9'].map((d) => _buildKeypadButton(d, primary, isDark)).toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button (or empty if setup)
                      widget.mode == LockScreenMode.unlock && widget.useBiometrics
                          ? _buildActionButton(
                              icon: Icons.fingerprint_rounded,
                              color: primary,
                              isDark: isDark,
                              onTap: _authenticateWithBiometrics,
                            )
                          : const SizedBox(width: 72, height: 72),
                      _buildKeypadButton('0', primary, isDark),
                      _buildActionButton(
                        icon: Icons.backspace_outlined,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        isDark: isDark,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit, Color primary, bool isDark) {
    return GestureDetector(
      onTap: () => _onKeypadTap(digit),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          digit,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
