import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/custom_card.dart';
import '../bloc/transaction_cubit.dart';
import 'add_transaction_sheet.dart';
import '../../reports/whatsapp_reports_sheet.dart';

class TransactionsScreen extends StatelessWidget {
  final TransactionRepository repository;

  const TransactionsScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionCubit(repository),
      child: _TransactionsView(repository: repository),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  final TransactionRepository repository;

  const _TransactionsView({required this.repository});

  Future<void> _pickSpecificDate(
    BuildContext context,
    TransactionCubit cubit,
    TransactionState state,
  ) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initialDate = state.selectedDate ??
        DateTime(
          state.selectedYear,
          state.selectedMonth,
          (state.selectedYear == now.year && state.selectedMonth == now.month)
              ? now.day
              : 1,
        );

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select Specific Date to Inspect Expenses',
    );

    if (picked != null) {
      cubit.setDateFilter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<TransactionCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, state) {
              final hasActiveDate = state.selectedDate != null;
              return IconButton(
                icon: Badge(
                  isLabelVisible: hasActiveDate,
                  child: Icon(
                    hasActiveDate
                        ? Icons.event_available_rounded
                        : Icons.calendar_month_rounded,
                    color: hasActiveDate
                        ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        : null,
                  ),
                ),
                tooltip: hasActiveDate ? 'Change Date Filter' : 'Filter by Specific Date',
                onPressed: () => _pickSpecificDate(context, cubit, state),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share WhatsApp Report',
            onPressed: () => WhatsAppReportsSheet.show(context, repository),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Transaction',
            onPressed: () => AddTransactionSheet.show(context, repository),
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final monthDate = DateTime(state.selectedYear, state.selectedMonth);

          return Column(
            children: [
              // Month Selector Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        cubit.changeMonth(-1);
                      },
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _pickSpecificDate(context, cubit, state),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormatter.formatMonthYear(monthDate),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_drop_down_rounded, size: 24),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        cubit.changeMonth(1);
                      },
                    ),
                  ],
                ),
              ),

              // Active Specific Date Banner
              if (state.selectedDate != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        size: 20,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing: ${DateFormatter.formatDate(state.selectedDate!)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          cubit.clearDateFilter();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View All Month',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.close_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Summary Stats Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Income',
                        amount: state.totalIncome,
                        color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                        prefix: '+',
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      _StatColumn(
                        label: 'Expenses',
                        amount: state.totalExpense,
                        color: isDark ? AppColors.darkDanger : AppColors.lightDanger,
                        prefix: '-',
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      _StatColumn(
                        label: 'Net Balance',
                        amount: state.netBalance,
                        color: state.netBalance < 0
                            ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                            : (state.netBalance > 0
                                ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Filter Tabs & Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: state.filterType == 'all',
                      onTap: () => cubit.setFilterType('all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Expenses',
                      isSelected: state.filterType == 'expense',
                      onTap: () => cubit.setFilterType('expense'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Income',
                      isSelected: state.filterType == 'income',
                      onTap: () => cubit.setFilterType('income'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (q) => cubit.setSearchQuery(q),
                  decoration: const InputDecoration(
                    hintText: 'Search notes, categories...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Transaction List
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.filteredTransactions.isEmpty
                        ? _EmptyTransactionsView(
                            onAdd: () => AddTransactionSheet.show(context, repository),
                            isDateFiltered: state.selectedDate != null,
                            onClearDate: () => cubit.clearDateFilter(),
                          )
                        : _GroupedTransactionList(
                            transactions: state.filteredTransactions,
                            onDelete: (id) => cubit.deleteTransaction(id),
                            onEdit: (item) => AddTransactionSheet.showEdit(
                              context,
                              repository,
                              transaction: item.transaction,
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

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String? prefix;

  const _StatColumn({
    required this.label,
    required this.amount,
    required this.color,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    String formatted;
    if (prefix != null) {
      formatted = '$prefix${CurrencyFormatter.formatCompact(amount.abs())}';
    } else {
      if (amount < 0) {
        formatted = '-${CurrencyFormatter.formatCompact(amount.abs())}';
      } else if (amount > 0) {
        formatted = '+${CurrencyFormatter.formatCompact(amount.abs())}';
      } else {
        formatted = CurrencyFormatter.formatCompact(0);
      }
    }

    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          formatted,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.18) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

class _GroupedTransactionList extends StatelessWidget {
  final List<TransactionWithCategory> transactions;
  final Function(int) onDelete;
  final Function(TransactionWithCategory)? onEdit;

  const _GroupedTransactionList({
    required this.transactions,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group by Date String (YYYY-MM-DD)
    final Map<String, List<TransactionWithCategory>> grouped = {};
    for (final item in transactions) {
      final key = DateFormatter.formatShortDate(item.transaction.date);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dayTransactions = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ),
            CustomCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayTransactions.length,
                separatorBuilder: (_, _) => Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  height: 1,
                ),
                itemBuilder: (context, itemIdx) {
                  final item = dayTransactions[itemIdx];
                  final isIncome = item.transaction.type == 'income';
                  final amountColor = isIncome
                      ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                      : (isDark ? AppColors.darkDanger : AppColors.lightDanger);

                  return Dismissible(
                    key: ValueKey(item.transaction.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: isDark ? AppColors.darkDanger : AppColors.lightDanger,
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      HapticFeedback.heavyImpact();
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Transaction?'),
                          content: const Text('Are you sure you want to remove this record?'),
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
                    },
                    onDismissed: (_) => onDelete(item.transaction.id),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onEdit?.call(item);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            CategoryIcon(
                              icon: item.category.icon,
                              color: Color(item.category.color),
                              size: 44,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.category.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (item.transaction.note != null &&
                                      item.transaction.note!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.transaction.note!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(item.transaction.amount)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: amountColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}


class _EmptyTransactionsView extends StatelessWidget {
  final VoidCallback onAdd;
  final bool isDateFiltered;
  final VoidCallback? onClearDate;

  const _EmptyTransactionsView({
    required this.onAdd,
    this.isDateFiltered = false,
    this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDateFiltered ? Icons.event_busy_rounded : Icons.receipt_long_rounded,
                size: 40,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isDateFiltered ? 'No Records on this Date' : 'No Transactions Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isDateFiltered
                  ? 'No expenses or incomes were recorded on this selected day.'
                  : 'Keep your finances on track by logging your first expense or income.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isDateFiltered && onClearDate != null) ...[
                  OutlinedButton(
                    onPressed: onClearDate,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('All Month'),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
