import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// A single action item in the Speed Dial.
class SpeedDialAction {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const SpeedDialAction({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });
}

/// An expandable Floating Action Button that fans out mini-actions
/// with smooth staggered animations, clean labels, and a frosted glass backdrop.
class SpeedDialFab extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final String tooltip;

  const SpeedDialFab({
    super.key,
    required this.actions,
    this.tooltip = 'Quick Add',
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _close(animate: false);
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    HapticFeedback.mediumImpact();
    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox = context.findRenderObject() as RenderBox?;
    final fabOffset = renderBox?.localToGlobal(Offset.zero) ?? const Offset(0, 0);
    final fabSize = renderBox?.size ?? const Size(56, 56);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _SpeedDialOverlay(
        controller: _controller,
        actions: widget.actions,
        fabOffset: fabOffset,
        fabSize: fabSize,
        onClose: _close,
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _controller.forward();
  }

  void _close({bool animate = true}) {
    if (!_isOpen && _overlayEntry == null) return;
    HapticFeedback.selectionClick();
    setState(() => _isOpen = false);

    if (animate) {
      _controller.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'speed_dial_main_trigger',
      tooltip: widget.tooltip,
      onPressed: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 0.785398, // 45 degrees in radians
            child: const Icon(Icons.add_rounded, size: 28),
          );
        },
      ),
    );
  }
}

class _SpeedDialOverlay extends StatelessWidget {
  final AnimationController controller;
  final List<SpeedDialAction> actions;
  final Offset fabOffset;
  final Size fabSize;
  final VoidCallback onClose;

  const _SpeedDialOverlay({
    required this.controller,
    required this.actions,
    required this.fabOffset,
    required this.fabSize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final bottomMargin = screenSize.height - (fabOffset.dy + fabSize.height);
    final rightMargin = screenSize.width - (fabOffset.dx + fabSize.width);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Frosted background barrier (tap to dismiss)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5.0 * controller.value,
                    sigmaY: 5.0 * controller.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45 * controller.value),
                  ),
                );
              },
            ),
          ),

          // Action buttons column anchored above the trigger FAB
          Positioned(
            right: rightMargin,
            bottom: bottomMargin,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ...List.generate(actions.length, (index) {
                  // Stagger order: bottom-most action appears first
                  final actionIndex = actions.length - 1 - index;
                  final action = actions[actionIndex];

                  final intervalStart = (0.08 * (actions.length - 1 - actionIndex)).clamp(0.0, 0.6);
                  final intervalEnd = (intervalStart + 0.45).clamp(0.0, 1.0);

                  final animation = CurvedAnimation(
                    parent: controller,
                    curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
                  );

                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 16 * (1 - animation.value)),
                        child: Opacity(
                          opacity: animation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Action label pill
                          GestureDetector(
                            onTap: () {
                              onClose();
                              action.onTap();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    action.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  if (action.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      action.subtitle!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Mini circular action button
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: FloatingActionButton(
                              heroTag: 'speed_dial_item_$actionIndex',
                              elevation: 4,
                              backgroundColor: action.color,
                              onPressed: () {
                                onClose();
                                action.onTap();
                              },
                              child: Icon(action.icon, size: 22, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // Mirrored close FAB on top of the original FAB position
                SizedBox(
                  width: fabSize.width,
                  height: fabSize.height,
                  child: FloatingActionButton(
                    heroTag: 'speed_dial_overlay_close',
                    onPressed: onClose,
                    child: const Icon(Icons.close_rounded, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
