import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/custom_card.dart';
import '../debts/debts_screen.dart';
import '../occasions/occasions_screen.dart';
import '../reports/whatsapp_reports_sheet.dart';
import '../transactions/screens/add_transaction_sheet.dart';

class DashboardScreen extends StatelessWidget {
  final TransactionRepository repository;
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onNavigateToBudget;

  const DashboardScreen({
    super.key,
    required this.repository,
    required this.onNavigateToTransactions,
    required this.onNavigateToBudget,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      body: StreamBuilder<List<TransactionWithCategory>>(
        stream: repository.watchTransactionsForMonth(now.year, now.month),
        builder: (context, snapshot) {
          final transactions = snapshot.data ?? [];
          final income = transactions
              .where((t) => t.transaction.type == 'income')
              .fold(0.0, (sum, t) => sum + t.transaction.amount);
          final expense = transactions
              .where((t) => t.transaction.type == 'expense')
              .fold(0.0, (sum, t) => sum + t.transaction.amount);
          final balance = income - expense;

          // Compute category breakdown
          final Map<String, ({double amount, Color color, String icon})> categoryExpenses = {};
          for (final t in transactions.where((t) => t.transaction.type == 'expense')) {
            final catName = t.category.name;
            final current = categoryExpenses[catName]?.amount ?? 0.0;
            categoryExpenses[catName] = (
              amount: current + t.transaction.amount,
              color: Color(t.category.color),
              icon: t.category.icon,
            );
          }

          final sortedCategories = categoryExpenses.entries.toList()
            ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

          return CustomScrollView(
            slivers: [
              // Custom Header Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamBuilder<UserSetting?>(
                        stream: repository.watchUserSettings(),
                        builder: (context, userSnap) {
                          final settings = userSnap.data;
                          final name = settings?.userName.trim().split(' ').first ?? 'Shabeeb';
                          final hasPhoto = settings?.profileImagePath != null && File(settings!.profileImagePath!).existsSync();
                          final initials = settings?.userName != null && settings!.userName.isNotEmpty
                              ? (settings.userName.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase())
                              : 'SW';

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                backgroundImage: hasPhoto ? FileImage(File(settings.profileImagePath!)) : null,
                                child: hasPhoto
                                    ? null
                                    : Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF25D366)),
                              tooltip: 'Share WhatsApp Report',
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                WhatsAppReportsSheet.show(context, repository);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add_rounded, size: 24),
                              tooltip: 'Quick Add',
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                AddTransactionSheet.show(context, repository);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Hero Balance Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: CustomCard(
                    padding: const EdgeInsets.all(24),
                    borderColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1E2333),
                              const Color(0xFF141724),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFFBF8F2),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL BALANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                DateFormatter.formatMonthYear(now),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          CurrencyFormatter.format(balance),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Income / Expense Pills
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 18,
                                      color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Income',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.formatCompact(income),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.darkDanger : AppColors.lightDanger).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 18,
                                      color: isDark ? AppColors.darkDanger : AppColors.lightDanger,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Expense',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.formatCompact(expense),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkDanger : AppColors.lightDanger,
                                          ),
                                        ),
                                      ],
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
                ),
              ),

              // Quick Action Shortcuts Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickChip(
                          icon: '🏖️',
                          label: 'Trips & Occasions',
                          onTap: () => OccasionsScreen.show(context, repository),
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          icon: '🤝',
                          label: 'Debts & Loans',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DebtsScreen(repository: repository)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          icon: '📊',
                          label: 'WhatsApp Reports',
                          onTap: () => WhatsAppReportsSheet.show(context, repository),
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          icon: '🎯',
                          label: 'Monthly Budgets',
                          onTap: onNavigateToBudget,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Active Debts Snapshot Card (if any active debts exist)
              SliverToBoxAdapter(
                child: StreamBuilder<List<Debt>>(
                  stream: repository.watchActiveDebts(),
                  builder: (context, debtSnap) {
                    final activeDebts = debtSnap.data ?? [];
                    if (activeDebts.isEmpty) return const SizedBox.shrink();

                    final totalLent = activeDebts
                        .where((d) => d.type == 'lent')
                        .fold(0.0, (sum, d) => sum + (d.amount - d.settledAmount).clamp(0.0, double.infinity));
                    final totalBorrowed = activeDebts
                        .where((d) => d.type == 'borrowed')
                        .fold(0.0, (sum, d) => sum + (d.amount - d.settledAmount).clamp(0.0, double.infinity));

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: CustomCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DebtsScreen(repository: repository)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.handshake_outlined, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Debts & Loans',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        '${activeDebts.length} active',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (totalLent > 0)
                                        Text(
                                          'Get: ${CurrencyFormatter.formatCompact(totalLent)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.income,
                                          ),
                                        ),
                                      if (totalLent > 0 && totalBorrowed > 0)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text('•', style: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
                                        ),
                                      if (totalBorrowed > 0)
                                        Text(
                                          'Owe: ${CurrencyFormatter.formatCompact(totalBorrowed)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.expense,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Category Breakdown Chart Section
              if (sortedCategories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Spending Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 44,
                                sections: sortedCategories.take(5).map((entry) {
                                  final pct = (entry.value.amount / (expense > 0 ? expense : 1)) * 100;
                                  return PieChartSectionData(
                                    color: entry.value.color,
                                    value: entry.value.amount,
                                    title: '${pct.toStringAsFixed(0)}%',
                                    radius: 36,
                                    titleStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...sortedCategories.take(4).map((entry) {
                            final pct = (entry.value.amount / (expense > 0 ? expense : 1)) * 100;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: entry.value.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${entry.value.icon} ${entry.key}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${CurrencyFormatter.format(entry.value.amount)} (${pct.toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Recent Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      TextButton(
                        onPressed: onNavigateToTransactions,
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Transactions Mini-List
              if (transactions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No transactions recorded this month.',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = transactions[index];
                        final isIncome = item.transaction.type == 'income';
                        final amountColor = isIncome
                            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                            : (isDark ? AppColors.darkDanger : AppColors.lightDanger);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CustomCard(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              AddTransactionSheet.showEdit(
                                context,
                                repository,
                                transaction: item.transaction,
                              );
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                                children: [
                                  CategoryIcon(
                                    icon: item.category.icon,
                                    color: Color(item.category.color),
                                    size: 42,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.category.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          DateFormatter.formatRelative(item.transaction.date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isIncome ? '+' : '-'}${CurrencyFormatter.format(item.transaction.amount)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: amountColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                      },

                      childCount: transactions.length > 5 ? 5 : transactions.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

