import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/widget_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../transactions/screens/add_transaction_sheet.dart';

/// Interactive preview card and manager for the Android Home Screen Widget.
class HomeScreenWidgetCard extends StatefulWidget {
  final TransactionRepository repository;

  const HomeScreenWidgetCard({super.key, required this.repository});

  @override
  State<HomeScreenWidgetCard> createState() => _HomeScreenWidgetCardState();
}

class _HomeScreenWidgetCardState extends State<HomeScreenWidgetCard> {
  bool _isSyncing = false;
  bool _showInstructions = false;
  WidgetData? _cachedData;

  @override
  void initState() {
    super.initState();
    _loadPreviewData();
  }

  Future<void> _loadPreviewData() async {
    try {
      final data = await WidgetSyncService.calculateWidgetData(widget.repository);
      if (mounted) {
        setState(() => _cachedData = data);
      }
    } catch (_) {}
  }

  Future<void> _manualSync() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSyncing = true);

    final success = await WidgetSyncService.syncWidget(widget.repository);
    await _loadPreviewData();

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? 'Home screen widget synchronized with live balances'
                      : 'Widget sync complete',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final todaySpend = _cachedData?.todaySpend ?? CurrencyFormatter.format(0);
    final budgetRemaining = _cachedData?.budgetRemaining ?? 'Not Set';
    final budgetStatus = _cachedData?.budgetStatus ?? 'On Track';
    final footerText = _cachedData?.footerText ?? 'Tap to view breakdown';
    final lastUpdated = _cachedData?.lastUpdated ?? 'Live';

    Color statusBadgeColor = AppColors.darkSuccess;
    if (budgetStatus == 'Over Budget') {
      statusBadgeColor = AppColors.darkDanger;
    } else if (budgetStatus == 'Near Limit') {
      statusBadgeColor = AppColors.darkWarning;
    } else if (budgetStatus == 'No Budget') {
      statusBadgeColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.widgets_rounded, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Android Home Screen Widget',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quick-glance balances & 1-tap expense logging',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('sync_widget_button'),
                tooltip: 'Sync Widget Now',
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.sync_rounded, color: primaryColor),
                onPressed: _isSyncing ? null : _manualSync,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Interactive Widget Simulation Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161922) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF2A2F3D) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Widget Top Bar
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'SpendWise',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBadgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        budgetStatus,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusBadgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lastUpdated,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Metrics Row
                Row(
                  children: [
                    // Today Spend Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2430) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TODAY'S SPEND",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              todaySpend,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Budget Remaining Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2430) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BUDGET LEFT",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              budgetRemaining,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Widget Bottom Bar
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        footerText,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => AddTransactionSheet(repository: widget.repository),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Setup Instructions Toggle
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showInstructions = !_showInstructions);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _showInstructions ? Icons.keyboard_arrow_up_rounded : Icons.help_outline_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showInstructions ? 'Hide Setup Steps' : 'How to place on your Android Home Screen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showInstructions ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),

          if (_showInstructions) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionStep(
                    number: '1',
                    text: 'Long-press on any empty area of your Android Home Screen.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionStep(
                    number: '2',
                    text: 'Tap the Widgets option from the popup menu.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionStep(
                    number: '3',
                    text: 'Scroll down to SpendWise and select Quick-Glance.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionStep(
                    number: '4',
                    text: 'Drag it onto your screen. You can also resize it horizontally or vertically!',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String text,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          child: Text(
            number,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
