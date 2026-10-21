import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/custom_card.dart';

class TourStep {
  final String title;
  final String tag;
  final String icon;
  final String headline;
  final String description;
  final List<String> bulletPoints;
  final int? relatedTabIndex;
  final String? tabLabel;
  final Color accentColor;

  const TourStep({
    required this.title,
    required this.tag,
    required this.icon,
    required this.headline,
    required this.description,
    required this.bulletPoints,
    this.relatedTabIndex,
    this.tabLabel,
    required this.accentColor,
  });
}

class AppTourSheet extends StatefulWidget {
  final TransactionRepository repository;
  final Function(int tabIndex)? onSwitchTab;

  const AppTourSheet({
    super.key,
    required this.repository,
    this.onSwitchTab,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionRepository repository,
    Function(int tabIndex)? onSwitchTab,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppTourSheet(
        repository: repository,
        onSwitchTab: onSwitchTab,
      ),
    );
  }

  @override
  State<AppTourSheet> createState() => _AppTourSheetState();
}

class _AppTourSheetState extends State<AppTourSheet> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<TourStep> _steps = [
    TourStep(
      title: 'Home Dashboard',
      tag: 'FINANCIAL COCKPIT',
      icon: '📊',
      headline: 'Real-time balance, budgets & intelligent daily trends',
      description:
          'Your central command center for daily finances. See your net cash flow, monthly pacing, and interactive sparkline spending trends.',
      bulletPoints: [
        'Total balance & monthly income/expense summary cards',
        'Interactive sparkline with daily spending pace & peak highlight',
        'Quick actions for fast access to analytics, trips, debts & categories',
      ],
      relatedTabIndex: 0,
      tabLabel: 'Open Home Tab',
      accentColor: Color(0xFF6C5CE7),
    ),
    TourStep(
      title: 'Activity & Transactions',
      tag: 'ADVANCED SEARCH & RECEIPTS',
      icon: '🧾',
      headline: 'Multi-facet filtering, receipt photos & foreign currency',
      description:
          'A powerful searchable ledger for all your financial activity with receipt photo attachments and multi-currency tracking.',
      bulletPoints: [
        'Filter by category, income/expense, date range & receipt status',
        'Capture receipts with camera or gallery; full pinch-to-zoom viewer',
        'Multi-currency logging (USD, EUR, AED, etc.) with transparent conversion',
      ],
      relatedTabIndex: 1,
      tabLabel: 'Open Activity Tab',
      accentColor: Color(0xFF00CEC9),
    ),
    TourStep(
      title: 'Monthly Budgets',
      tag: 'PROACTIVE OVERSPEEND CONTROL',
      icon: '🎯',
      headline: 'Visual category limits with automated warning alerts',
      description:
          'Keep your spending under control before month-end surprises occur. Set specific category allocations and monitor real-time progress.',
      bulletPoints: [
        'Color-coded progress indicators showing remaining budget',
        'Automated notification warnings at 80% and 100% budget thresholds',
        'Month-to-month comparison to identify spending drift',
      ],
      relatedTabIndex: 2,
      tabLabel: 'Open Budgets Tab',
      accentColor: Color(0xFFFD79A8),
    ),
    TourStep(
      title: 'Savings & Wishlists',
      tag: 'GOALS & PURCHASE CONVERSION',
      icon: '💎',
      headline: 'Turn shopping desires into reached financial milestones',
      description:
          'Track long-term goals like vacations, emergency funds, or gadgets, and link wishlist cart items directly to your progress.',
      bulletPoints: [
        'Set target amounts, deadlines, and celebration milestones',
        'Link shopping wishlist items to goals with live deposit sync',
        '1-Tap "Mark as Purchased" auto-converts wishlist items into expenses',
      ],
      relatedTabIndex: 3,
      tabLabel: 'Open Savings Tab',
      accentColor: Color(0xFF00B894),
    ),
    TourStep(
      title: 'Trips, Occasions & Backups',
      tag: 'TRAVEL & COMPLETE PRIVACY',
      icon: '🏖️',
      headline: 'Travel budgets, WhatsApp reports & full JSON backups',
      description:
          'Never lose track of group vacation expenses or debts. Plus, export your entire SQLite database to JSON or CSV anytime.',
      bulletPoints: [
        'Occasions & Trips with custom travel currencies (e.g. AED, EUR)',
        'Formatted 1-tap WhatsApp digest generation to share with friends',
        '100% offline local privacy with PIN lock and JSON backup/restore',
      ],
      relatedTabIndex: 4,
      tabLabel: 'Open Settings Tab',
      accentColor: Color(0xFFF39C12),
    ),
  ];

  Future<void> _markTourCompleted() async {
    try {
      final current = await widget.repository.getUserSettings();
      if (current != null) {
        await widget.repository.saveUserSettings(
          current.toCompanion(true).copyWith(
                hasSeenAppTour: const drift.Value(true),
              ),
        );
      }
    } catch (_) {}
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _markTourCompleted();
      Navigator.pop(context);
    }
  }

  void _prevPage() {
    HapticFeedback.selectionClick();
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = _steps[_currentIndex];

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
          const SizedBox(height: 12),

          // Header with Tour Pill and Skip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: step.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: step.accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: step.accentColor),
                          const SizedBox(width: 6),
                          Text(
                            'Step ${_currentIndex + 1} of ${_steps.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: step.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    _markTourCompleted();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Skip Tour',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PageView content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _steps.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final s = _steps[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Feature Hero Card
                      CustomCard(
                        padding: const EdgeInsets.all(22),
                        borderColor: s.accentColor.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: s.accentColor.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(s.icon, style: const TextStyle(fontSize: 30)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.tag,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: s.accentColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        s.title,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.headline,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.description,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bullet Highlights
                      Text(
                        'KEY CAPABILITIES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...s.bulletPoints.map((bullet) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: s.accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),

                      if (s.relatedTabIndex != null && widget.onSwitchTab != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.touch_app_outlined, size: 16),
                          label: Text(s.tabLabel ?? 'Jump to Screen', style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: s.accentColor,
                            side: BorderSide(color: s.accentColor.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            widget.onSwitchTab!(s.relatedTabIndex!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Switched to "${s.title}" tab behind tour.'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Bar with Progress Dots and Navigation Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightCard,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Step Indicator Dots
                Row(
                  children: List.generate(_steps.length, (i) {
                    final isCurrent = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isCurrent ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? step.accentColor
                            : (isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Back & Next Buttons
                Row(
                  children: [
                    if (_currentIndex > 0)
                      TextButton(
                        onPressed: _prevPage,
                        child: const Text('Previous'),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: Icon(
                        _currentIndex == _steps.length - 1
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _currentIndex == _steps.length - 1 ? 'Finish Tour' : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: step.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: _nextPage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
