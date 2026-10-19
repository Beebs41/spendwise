import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/repositories/transaction_repository.dart';

enum ReportType {
  monthlySummary,
  categoryBreakdown,
  dailyActivity,
  tripsAndOccasions,
  savingsGoals,
  debtsAndLoans,
}

class WhatsAppReportsSheet extends StatefulWidget {
  final TransactionRepository repository;
  final int? initialYear;
  final int? initialMonth;
  final DateTime? initialDate;

  const WhatsAppReportsSheet({
    super.key,
    required this.repository,
    this.initialYear,
    this.initialMonth,
    this.initialDate,
  });

  static Future<void> show(
    BuildContext context,
    TransactionRepository repository, {
    int? year,
    int? month,
    DateTime? date,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatsAppReportsSheet(
        repository: repository,
        initialYear: year,
        initialMonth: month,
        initialDate: date,
      ),
    );
  }

  @override
  State<WhatsAppReportsSheet> createState() => _WhatsAppReportsSheetState();
}

class _WhatsAppReportsSheetState extends State<WhatsAppReportsSheet> {
  late int _selectedYear;
  late int _selectedMonth;
  DateTime? _selectedDate;
  ReportType _selectedReport = ReportType.monthlySummary;
  bool _isLoading = false;
  String _generatedReport = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = widget.initialYear ?? now.year;
    _selectedMonth = widget.initialMonth ?? now.month;
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _selectedReport = ReportType.dailyActivity;
    }
    _buildReport();
  }

  Future<void> _buildReport() async {
    setState(() => _isLoading = true);

    try {
      final user = await widget.repository.getUserSettings();
      final userName = user?.userName.trim().isNotEmpty == true ? user!.userName.trim() : 'SpendWise User';
      final currency = CurrencyFormatter.activeSymbol;

      final transactions = await widget.repository.watchTransactionsForMonth(_selectedYear, _selectedMonth).first;
      final budgets = await widget.repository.watchBudgetsForMonth(_selectedYear, _selectedMonth).first;
      final occasions = await widget.repository.getAllOccasions();
      final savings = await widget.repository.watchSavingsGoals().first;

      final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      final monthName = DateFormatter.formatMonthYear(DateTime(_selectedYear, _selectedMonth));

      final buffer = StringBuffer();

      switch (_selectedReport) {
        case ReportType.monthlySummary:
          final income = transactions
              .where((t) => t.transaction.type == 'income')
              .fold(0.0, (sum, t) => sum + t.transaction.amount);
          final expense = transactions
              .where((t) => t.transaction.type == 'expense')
              .fold(0.0, (sum, t) => sum + t.transaction.amount);
          final balance = income - expense;
          final savingsRate = income > 0 ? ((balance / income) * 100).clamp(0, 100).toStringAsFixed(1) : '0.0';

          // Top 3 expense categories
          final Map<String, double> catTotals = {};
          for (final t in transactions.where((t) => t.transaction.type == 'expense')) {
            catTotals[t.category.name] = (catTotals[t.category.name] ?? 0.0) + t.transaction.amount;
          }
          final topCats = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          buffer.writeln('╔══════════════════════════╗');
          buffer.writeln('║   📊 *SPENDWISE MONTHLY REPORT*  ║');
          buffer.writeln('║       *$monthName*       ║');
          buffer.writeln('╚══════════════════════════╝\n');
          buffer.writeln('👤 *Account:* $userName');
          buffer.writeln('🗓️ *Generated:* $nowFormatted\n');
          buffer.writeln('────────────────────────────');
          buffer.writeln('💵 *Total Income:*    $currency${CurrencyFormatter.formatCompact(income)}');
          buffer.writeln('💸 *Total Expenses:*  $currency${CurrencyFormatter.formatCompact(expense)}');
          buffer.writeln('────────────────────────────');
          buffer.writeln('${balance >= 0 ? '📈' : '📉'} *Net Savings:*     $currency${CurrencyFormatter.formatCompact(balance)}');
          buffer.writeln('🎯 *Savings Rate:*    $savingsRate%\n');

          if (topCats.isNotEmpty) {
            buffer.writeln('🏷️ *TOP SPENDING CATEGORIES:*');
            for (var i = 0; i < topCats.length && i < 3; i++) {
              final cat = topCats[i];
              final pct = expense > 0 ? ((cat.value / expense) * 100).toStringAsFixed(0) : '0';
              buffer.writeln('  • *${cat.key}:* $currency${CurrencyFormatter.formatCompact(cat.value)} ($pct%)');
            }
            buffer.writeln('');
          }

          if (budgets.isNotEmpty) {
            final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
            final budgetSpent = budgets.fold(0.0, (sum, b) => sum + (catTotals[b.category.name] ?? 0.0));
            final bPct = totalBudget > 0 ? ((budgetSpent / totalBudget) * 100).toStringAsFixed(0) : '0';
            buffer.writeln('📌 *BUDGET STATUS:*');
            buffer.writeln('  $currency${CurrencyFormatter.formatCompact(budgetSpent)} of $currency${CurrencyFormatter.formatCompact(totalBudget)} used ($bPct%)');
            buffer.writeln('');
          }
          break;

        case ReportType.categoryBreakdown:
          final expense = transactions
              .where((t) => t.transaction.type == 'expense')
              .fold(0.0, (sum, t) => sum + t.transaction.amount);

          final Map<String, ({double amount, String icon})> catMap = {};
          for (final t in transactions.where((t) => t.transaction.type == 'expense')) {
            final prev = catMap[t.category.name]?.amount ?? 0.0;
            catMap[t.category.name] = (amount: prev + t.transaction.amount, icon: t.category.icon);
          }
          final sorted = catMap.entries.toList()..sort((a, b) => b.value.amount.compareTo(a.value.amount));

          buffer.writeln('╔══════════════════════════╗');
          buffer.writeln('║  🏷️ *CATEGORY BREAKDOWN*  ║');
          buffer.writeln('║       *$monthName*       ║');
          buffer.writeln('╚══════════════════════════╝\n');
          buffer.writeln('👤 *Account:* $userName');
          buffer.writeln('💸 *Total Expenses:* $currency${CurrencyFormatter.format(expense)}\n');
          buffer.writeln('────────────────────────────');

          if (sorted.isEmpty) {
            buffer.writeln('No expenses recorded for this month.');
          } else {
            for (final entry in sorted) {
              final pct = expense > 0 ? (entry.value.amount / expense) : 0.0;
              final bars = (pct * 10).round().clamp(0, 10);
              final barStr = '${'█' * bars}${'░' * (10 - bars)}';
              buffer.writeln('${entry.value.icon} *${entry.key}*');
              buffer.writeln('   [$barStr] ${(pct * 100).toStringAsFixed(0)}%');
              buffer.writeln('   $currency${CurrencyFormatter.format(entry.value.amount)}\n');
            }
          }
          break;

        case ReportType.dailyActivity:
          final targetDate = _selectedDate ?? DateTime.now();
          final dayFormatted = DateFormatter.formatDate(targetDate);

          final dayItems = transactions.where((t) =>
              t.transaction.date.year == targetDate.year &&
              t.transaction.date.month == targetDate.month &&
              t.transaction.date.day == targetDate.day).toList();

          final dayIncome = dayItems
              .where((t) => t.transaction.type == 'income')
              .fold(0.0, (sum, t) => sum + t.transaction.amount);
          final dayExpense = dayItems
              .where((t) => t.transaction.type == 'expense')
              .fold(0.0, (sum, t) => sum + t.transaction.amount);

          buffer.writeln('╔══════════════════════════╗');
          buffer.writeln('║    🗓️ *DAILY EXPENSE LOG*    ║');
          buffer.writeln('║   *$dayFormatted*   ║');
          buffer.writeln('╚══════════════════════════╝\n');
          buffer.writeln('👤 *Account:* $userName');
          buffer.writeln('────────────────────────────');
          buffer.writeln('📈 *Day Income:*   $currency${CurrencyFormatter.format(dayIncome)}');
          buffer.writeln('📉 *Day Expenses:* $currency${CurrencyFormatter.format(dayExpense)}');
          buffer.writeln('────────────────────────────\n');

          if (dayItems.isEmpty) {
            buffer.writeln('✨ No transactions logged on this day.');
          } else {
            buffer.writeln('📋 *TRANSACTION DETAILS:*');
            for (final item in dayItems) {
              final isInc = item.transaction.type == 'income';
              final sign = isInc ? '+' : '-';
              final note = item.transaction.note != null && item.transaction.note!.isNotEmpty
                  ? ' ("${item.transaction.note}")'
                  : '';
              buffer.writeln('${item.category.icon} *${item.category.name}*$note');
              buffer.writeln('   `$sign$currency${CurrencyFormatter.format(item.transaction.amount)}`');
            }
          }
          break;

        case ReportType.tripsAndOccasions:
          buffer.writeln('╔══════════════════════════╗');
          buffer.writeln('║  ✈️ *TRIPS & OCCASIONS*   ║');
          buffer.writeln('╚══════════════════════════╝\n');
          buffer.writeln('👤 *Account:* $userName');
          buffer.writeln('🗓️ *Generated:* $nowFormatted\n');

          if (occasions.isEmpty) {
            buffer.writeln('No trips or occasion trackers created yet.');
          } else {
            for (final occ in occasions) {
              final occTx = await widget.repository.getTransactionsForOccasion(occ.id);
              final occSpent = occTx.fold(0.0, (sum, t) => sum + t.transaction.amount);
              buffer.writeln('────────────────────────────');
              buffer.writeln('${occ.icon} *${occ.name.toUpperCase()}*');
              if (occ.startDate != null) {
                buffer.writeln('🗓️ ${DateFormatter.formatShortDate(occ.startDate!)}${occ.endDate != null ? ' - ${DateFormatter.formatShortDate(occ.endDate!)}' : ''}');
              }
              buffer.writeln('💰 *Total Spent:* $currency${CurrencyFormatter.format(occSpent)}');
              if (occ.budget > 0) {
                final bPct = ((occSpent / occ.budget) * 100).toStringAsFixed(0);
                buffer.writeln('🎯 *Budget:* $currency${CurrencyFormatter.format(occ.budget)} ($bPct% used)');
              }
              buffer.writeln('📝 *Transactions:* ${occTx.length} items logged');
            }
          }
          break;

        case ReportType.savingsGoals:
          buffer.writeln('╔══════════════════════════╗');
          buffer.writeln('║   🎯 *SAVINGS GOALS*     ║');
          buffer.writeln('╚══════════════════════════╝\n');
          buffer.writeln('👤 *Account:* $userName');
          buffer.writeln('🗓️ *Generated:* $nowFormatted\n');

          if (savings.isEmpty) {
            buffer.writeln('No savings goals set yet.');
          } else {
            for (final s in savings) {
              final pct = s.targetAmount > 0 ? ((s.currentAmount / s.targetAmount) * 100).clamp(0, 100).toStringAsFixed(0) : '0';
              buffer.writeln('────────────────────────────');
              buffer.writeln('${s.icon} *${s.title}*');
              buffer.writeln('  Saved:  $currency${CurrencyFormatter.format(s.currentAmount)}');
              buffer.writeln('  Target: $currency${CurrencyFormatter.format(s.targetAmount)} ($pct%)');
              if (s.deadline != null) {
                buffer.writeln('  Target Date: ${DateFormatter.formatDate(s.deadline!)}');
              }
            }
          }
          break;

        case ReportType.debtsAndLoans:
          final allDebts = await widget.repository.getAllDebts();
          final activeDebts = allDebts.where((d) => !d.isSettled).toList();
          final lent = activeDebts.where((d) => d.type == 'lent').toList();
          final borrowed = activeDebts.where((d) => d.type == 'borrowed').toList();

          final totalLent = lent.fold(0.0, (sum, d) => sum + (d.amount - d.settledAmount).clamp(0.0, double.infinity));
          final totalBorrowed = borrowed.fold(0.0, (sum, d) => sum + (d.amount - d.settledAmount).clamp(0.0, double.infinity));
          final net = totalLent - totalBorrowed;

          buffer.writeln('╔══════════════════════════╗');
          buffer.writeln('║   🤝 *DEBTS & LOANS REPORT* ║');
          buffer.writeln('╚══════════════════════════╝\n');
          buffer.writeln('👤 *Account:* $userName');
          buffer.writeln('🗓️ *Generated:* $nowFormatted\n');
          buffer.writeln('────────────────────────────');
          buffer.writeln('🟢 *You\'ll Get (Lent):*   $currency${CurrencyFormatter.format(totalLent)}');
          buffer.writeln('🔴 *You Owe (Borrowed):* $currency${CurrencyFormatter.format(totalBorrowed)}');
          buffer.writeln('⚖️ *Net Position:*       $currency${CurrencyFormatter.format(net)}\n');

          if (lent.isNotEmpty) {
            buffer.writeln('📋 *PEOPLE WHO OWE YOU:*');
            for (final d in lent) {
              final rem = (d.amount - d.settledAmount).clamp(0.0, double.infinity);
              buffer.writeln('  • *${d.personName}:* $currency${CurrencyFormatter.format(rem)} (of $currency${CurrencyFormatter.format(d.amount)})');
              if (d.dueDate != null) {
                buffer.writeln('    Due Date: ${DateFormat('dd MMM yyyy').format(d.dueDate!)}');
              }
            }
            buffer.writeln('');
          }

          if (borrowed.isNotEmpty) {
            buffer.writeln('📋 *PEOPLE YOU OWE:*');
            for (final d in borrowed) {
              final rem = (d.amount - d.settledAmount).clamp(0.0, double.infinity);
              buffer.writeln('  • *${d.personName}:* $currency${CurrencyFormatter.format(rem)} (of $currency${CurrencyFormatter.format(d.amount)})');
              if (d.dueDate != null) {
                buffer.writeln('    Target: ${DateFormat('dd MMM yyyy').format(d.dueDate!)}');
              }
            }
            buffer.writeln('');
          }

          if (activeDebts.isEmpty) {
            buffer.writeln('✅ All debts are settled! No pending balances.');
          }
          break;
      }

      buffer.writeln('\n────────────────────────────');
      buffer.writeln('🔒 _100% Private, Local-First Finance_');
      buffer.writeln('⚡ _Tracked with SpendWise_');

      setState(() {
        _generatedReport = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _generatedReport = 'Error generating report: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: _generatedReport));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Report copied! Open WhatsApp to paste and share.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareToWhatsApp() async {
    HapticFeedback.mediumImpact();
    await SharePlus.instance.share(
      ShareParams(
        text: _generatedReport,
        subject: 'SpendWise Financial Report',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('💬', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WhatsApp Reports',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Formatted with emojis & alignment',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Report Type Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _TypeChip(
                  label: '📊 Monthly Overview',
                  isSelected: _selectedReport == ReportType.monthlySummary,
                  onTap: () {
                    setState(() => _selectedReport = ReportType.monthlySummary);
                    _buildReport();
                  },
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '🏷️ Category Breakdown',
                  isSelected: _selectedReport == ReportType.categoryBreakdown,
                  onTap: () {
                    setState(() => _selectedReport = ReportType.categoryBreakdown);
                    _buildReport();
                  },
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '🗓️ Daily Log',
                  isSelected: _selectedReport == ReportType.dailyActivity,
                  onTap: () {
                    setState(() => _selectedReport = ReportType.dailyActivity);
                    _buildReport();
                  },
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '✈️ Trips & Events',
                  isSelected: _selectedReport == ReportType.tripsAndOccasions,
                  onTap: () {
                    setState(() => _selectedReport = ReportType.tripsAndOccasions);
                    _buildReport();
                  },
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '🎯 Savings Goals',
                  isSelected: _selectedReport == ReportType.savingsGoals,
                  onTap: () {
                    setState(() => _selectedReport = ReportType.savingsGoals);
                    _buildReport();
                  },
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '🤝 Debts & Loans',
                  isSelected: _selectedReport == ReportType.debtsAndLoans,
                  onTap: () {
                    setState(() => _selectedReport = ReportType.debtsAndLoans);
                    _buildReport();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Report Live Preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF25D366).withValues(alpha: 0.3),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: SelectableText(
                          _generatedReport,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.45,
                            color: isDark ? Colors.white70 : const Color(0xFF0F5132),
                          ),
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Report'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareToWhatsApp,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share to WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF25D366).withValues(alpha: 0.2)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF25D366) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF25D366) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
