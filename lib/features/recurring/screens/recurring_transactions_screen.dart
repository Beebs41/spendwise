import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/recurring_transaction_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../transactions/screens/add_transaction_sheet.dart';
import '../../transactions/widgets/receipt_viewer_dialog.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  final TransactionRepository repository;

  const RecurringTransactionsScreen({super.key, required this.repository});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  bool _isChecking = false;

  Future<void> _checkDueTransactions() async {
    HapticFeedback.mediumImpact();
    setState(() => _isChecking = true);

    try {
      final generated = await RecurringTransactionService.checkAndGenerateDueTransactions(
        widget.repository,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  generated > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    generated > 0
                        ? '$generated recurring transaction${generated > 1 ? 's' : ''} auto-generated!'
                        : 'All recurring transactions are up to date.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check recurring rules: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _deleteRule(RecurringTransaction rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recurring Rule?'),
        content: const Text(
          'Future transactions will no longer be auto-generated. Existing past transactions will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.darkDanger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      await widget.repository.deleteRecurringTransaction(rule.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Recurring Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.autorenew_rounded),
            tooltip: 'Check Due Transactions Now',
            onPressed: _isChecking ? null : _checkDueTransactions,
          ),
        ],
      ),
      body: StreamBuilder<List<RecurringWithCategory>>(
        stream: widget.repository.watchAllRecurringTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rules = snapshot.data ?? [];
          if (rules.isEmpty) {
            return _buildEmptyState(isDark);
          }

          final activeRules = rules.where((r) => r.recurring.isActive).toList();
          final pausedRules = rules.where((r) => !r.recurring.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top info banner
              _buildInfoBanner(isDark, activeRules.length),
              const SizedBox(height: 16),

              if (activeRules.isNotEmpty) ...[
                _buildSectionHeader('ACTIVE RULES (${activeRules.length})', isDark),
                const SizedBox(height: 8),
                ...activeRules.map((r) => _buildRuleCard(r, isDark)),
                const SizedBox(height: 16),
              ],

              if (pausedRules.isNotEmpty) ...[
                _buildSectionHeader('PAUSED RULES (${pausedRules.length})', isDark),
                const SizedBox(height: 8),
                ...pausedRules.map((r) => _buildRuleCard(r, isDark)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Recurring',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          HapticFeedback.selectionClick();
          AddTransactionSheet.show(
            context,
            widget.repository,
            initialType: 'expense',
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark, int activeCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              size: 22,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-Generation Active',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SpendWise scans recurring rules on app launch and automatically creates due transactions.',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
      ),
    );
  }

  Widget _buildRuleCard(RecurringWithCategory item, bool isDark) {
    final rule = item.recurring;
    final cat = item.category;
    final isIncome = rule.type == 'income';
    final amountColor = isIncome
        ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
        : (isDark ? AppColors.darkDanger : AppColors.lightDanger);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CategoryIcon(
                  icon: cat.icon,
                  color: Color(cat.color),
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              RecurringTransactionService.formatFrequency(rule.frequency),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (rule.note != null && rule.note!.isNotEmpty)
                        Text(
                          rule.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${CurrencyFormatter.format(rule.amount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Switch(
                      value: rule.isActive,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        widget.repository.toggleRecurringActive(rule.id, val);
                      },
                      activeThumbColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Next due: ${DateFormatter.formatDate(rule.nextDueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                if (rule.receiptPath != null && rule.receiptPath!.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ReceiptViewerDialog.show(
                        context,
                        imagePath: rule.receiptPath!,
                        title: '${cat.name} Template Receipt',
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 13,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Receipt',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: AppColors.darkDanger,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete Rule',
                  onPressed: () => _deleteRule(rule),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.autorenew_rounded,
                size: 64,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Recurring Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set recurring rules for rent, subscriptions, bills, or salary. SpendWise will automatically generate them on schedule.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Recurring Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                AddTransactionSheet.show(
                  context,
                  widget.repository,
                  initialType: 'expense',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
