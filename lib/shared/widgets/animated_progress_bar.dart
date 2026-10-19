import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0+
  final double height;
  final Color? color;
  final bool autoColor;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.color,
    this.autoColor = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color barColor;
    if (color != null) {
      barColor = color!;
    } else if (autoColor) {
      if (progress > 0.90) {
        barColor = isDark ? AppColors.darkDanger : AppColors.lightDanger;
      } else if (progress > 0.70) {
        barColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
      } else {
        barColor = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      }
    } else {
      barColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    }

    final bg = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * clamped,
                height: height,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
