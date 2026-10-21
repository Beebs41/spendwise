import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../bloc/transaction_cubit.dart';
import '../models/transaction_filter.dart';
import 'add_transaction_sheet.dart';
import 'transaction_filter_sheet.dart';
import '../widgets/receipt_viewer_dialog.dart';
import '../../reports/whatsapp_reports_sheet.dart';
import '../../recurring/screens/recurring_transactions_screen.dart';

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

class _TransactionsView extends StatefulWidget {
  final TransactionRepository repository;

  const _TransactionsView({required this.repository});

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  String _getDatePresetLabel(TransactionFilter filter) {
    if (filter.specificDate != null) {
      return DateFormatter.formatDate(filter.specificDate!);
    }
    switch (filter.datePreset) {
      case DateFilterPreset.today:
        return 'Today';
      case DateFilterPreset.thisWeek:
        return 'This Week';
      case DateFilterPreset.last30Days:
        return 'Last 30 Days';
      case DateFilterPreset.thisYear:
        return 'This Year';
      case DateFilterPreset.allTime:
        return 'All Time';
      case DateFilterPreset.custom:
        if (filter.customStartDate != null && filter.customEndDate != null) {
          return '${DateFormatter.formatShortDate(filter.customStartDate!)} - ${DateFormatter.formatShortDate(filter.customEndDate!)}';
        }
        return 'Custom Range';
      case DateFilterPreset.month:
        return 'Month';
    }
  }

  String _getSortLabel(SortOption sort) {
    switch (sort) {
      case SortOption.dateDesc:
        return 'Newest First';
      case SortOption.dateAsc:
        return 'Oldest First';
      case SortOption.amountDesc:
        return 'Highest Amount';
      case SortOption.amountAsc:
        return 'Lowest Amount';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
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
                    color: hasActiveDate ? primary : null,
                  ),
                ),
                tooltip: hasActiveDate ? 'Change Date Filter' : 'Filter by Specific Date',
                onPressed: () => _pickSpecificDate(context, cubit, state),
              );
            },
          ),
          NotificationBellButton(repository: widget.repository),
          IconButton(
            icon: const Icon(Icons.autorenew_rounded),
            tooltip: 'Recurring Transactions & Subscriptions',
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecurringTransactionsScreen(repository: widget.repository),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share WhatsApp Report',
            onPressed: () => WhatsAppReportsSheet.show(context, widget.repository),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Transaction',
            onPressed: () => AddTransactionSheet.show(context, widget.repository),
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final monthDate = DateTime(state.selectedYear, state.selectedMonth);
          final isScopeAllTime = state.filter.datePreset == DateFilterPreset.allTime ||
              state.filter.searchAllTime;

          return Column(
            children: [
              // Month Selector Bar (hidden when viewing custom range or all-time)
              if (!isScopeAllTime && state.filter.datePreset == DateFilterPreset.month)
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

              // Active Scope / Date Banner
              if (state.selectedDate != null || isScopeAllTime || state.filter.datePreset != DateFilterPreset.month)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isScopeAllTime ? Icons.history_rounded : Icons.event_note_rounded,
                        size: 20,
                        color: primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isScopeAllTime
                              ? 'Scope: All Time (${state.filteredTransactions.length} records)'
                              : 'Showing: ${_getDatePresetLabel(state.filter)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primary,
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
                                'View Month',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
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

              // Summary Stats Card (Dynamically reflects filtered subset)
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

              const SizedBox(height: 10),

              // Filter Type Tabs & All-Time Toggle
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
                    const Spacer(),
                    // Quick All-Time Toggle Pill
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        cubit.toggleSearchAllTime();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: state.filter.searchAllTime
                              ? primary.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: state.filter.searchAllTime
                                ? primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 14,
                              color: state.filter.searchAllTime ? primary : null,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'All-Time',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: state.filter.searchAllTime
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: state.filter.searchAllTime ? primary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Search Bar + Filter Sheet Trigger
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (q) => cubit.setSearchQuery(q),
                        decoration: InputDecoration(
                          hintText: 'Search note, category, amount, trip...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    cubit.setSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      isLabelVisible: state.filter.hasActiveAdvancedFilters,
                      label: Text('${state.filter.activeFilterCount}'),
                      backgroundColor: primary,
                      textColor: isDark ? Colors.black : Colors.white,
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        tooltip: 'Filter & Sort Options',
                        onPressed: () => TransactionFilterSheet.show(context, cubit),
                      ),
                    ),
                  ],
                ),
              ),

              // Active Filters Ribbon (dismissible pills)
              if (!state.filter.isDefault)
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Active Categories
                      for (final catId in state.filter.categoryIds) ...[
                        _buildActiveFilterChip(
                          context,
                          label: state.allCategories
                              .firstWhere(
                                (c) => c.id == catId,
                                orElse: () => Category(
                                  id: catId,
                                  name: 'Category',
                                  icon: '🏷️',
                                  color: 0xFF888888,
                                  isIncome: false,
                                  sortOrder: 0,
                                  isDefault: false,
                                ),
                              )
                              .name,
                          icon: state.allCategories
                              .firstWhere(
                                (c) => c.id == catId,
                                orElse: () => Category(
                                  id: catId,
                                  name: 'Category',
                                  icon: '🏷️',
                                  color: 0xFF888888,
                                  isIncome: false,
                                  sortOrder: 0,
                                  isDefault: false,
                                ),
                              )
                              .icon,
                          onDelete: () => cubit.removeCategoryFilter(catId),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Active Occasion
                      if (state.filter.occasionId != null) ...[
                        _buildActiveFilterChip(
                          context,
                          label: state.filter.occasionId == -1
                              ? 'No Occasion'
                              : (state.occasionsMap[state.filter.occasionId]?.name ?? 'Trip'),
                          icon: state.filter.occasionId == -1
                              ? '🏷️'
                              : (state.occasionsMap[state.filter.occasionId]?.icon ?? '🏖️'),
                          onDelete: () => cubit.clearOccasionFilter(),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Active Amount Range
                      if (state.filter.minAmount != null || state.filter.maxAmount != null) ...[
                        _buildActiveFilterChip(
                          context,
                          label: '₹${state.filter.minAmount?.toStringAsFixed(0) ?? '0'} - ₹${state.filter.maxAmount?.toStringAsFixed(0) ?? '∞'}',
                          icon: '💵',
                          onDelete: () => cubit.clearAmountFilter(),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Active Sort
                      if (state.filter.sortBy != SortOption.dateDesc) ...[
                        _buildActiveFilterChip(
                          context,
                          label: _getSortLabel(state.filter.sortBy),
                          icon: '↕️',
                          onDelete: () => cubit.setFilter(state.filter.copyWith(sortBy: SortOption.dateDesc)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Clear All Action
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _searchController.clear();
                            cubit.resetFilter();
                          },
                          icon: const Icon(Icons.close_rounded, size: 14),
                          label: const Text('Clear All', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.darkDanger,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Transaction List
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.filteredTransactions.isEmpty
                        ? _EmptyTransactionsView(
                            onAdd: () => AddTransactionSheet.show(context, widget.repository),
                            isFiltered: !state.filter.isDefault,
                            onClearFilters: () {
                              _searchController.clear();
                              cubit.resetFilter();
                            },
                          )
                        : _GroupedTransactionList(
                            transactions: state.filteredTransactions,
                            occasionsMap: state.occasionsMap,
                            onDelete: (id) => cubit.deleteTransaction(id),
                            onEdit: (item) => AddTransactionSheet.showEdit(
                              context,
                              widget.repository,
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

  Widget _buildActiveFilterChip(
    BuildContext context, {
    required String label,
    required String icon,
    required VoidCallback onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onDelete();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 14, color: primary),
            ),
          ),
        ],
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
  final Map<int, Occasion> occasionsMap;
  final Function(int) onDelete;
  final Function(TransactionWithCategory)? onEdit;

  const _GroupedTransactionList({
    required this.transactions,
    required this.occasionsMap,
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

                  final occasion = item.transaction.occasionId != null
                      ? occasionsMap[item.transaction.occasionId]
                      : null;

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
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.category.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (occasion != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(occasion.icon, style: const TextStyle(fontSize: 10)),
                                              const SizedBox(width: 4),
                                              Text(
                                                occasion.name,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (item.transaction.receiptPath != null &&
                                          item.transaction.receiptPath!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            ReceiptViewerDialog.show(
                                              context,
                                              imagePath: item.transaction.receiptPath!,
                                              title: '${item.category.name} Receipt',
                                              subtitle:
                                                  '${item.category.icon} ${CurrencyFormatter.format(item.transaction.amount)} • ${DateFormatter.formatDate(item.transaction.date)}',
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.receipt_long_rounded,
                                                  size: 11,
                                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Receipt',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(item.transaction.amount)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: amountColor,
                                  ),
                                ),
                                if (item.transaction.originalCurrency != null &&
                                    item.transaction.originalCurrency != CurrencyFormatter.activeCode &&
                                    item.transaction.originalAmount != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${CurrencyService.findByCode(item.transaction.originalCurrency!)?.symbol ?? ''}${item.transaction.originalAmount!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                    ),
                                  ),
                                ],
                              ],
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
  final bool isFiltered;
  final VoidCallback? onClearFilters;

  const _EmptyTransactionsView({
    required this.onAdd,
    this.isFiltered = false,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

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
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? Icons.search_off_rounded : Icons.receipt_long_rounded,
                size: 40,
                color: primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No Matching Transactions' : 'No Transactions Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'No records match your active search or filters. Try adjusting criteria or clearing filters.'
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
                if (isFiltered && onClearFilters != null) ...[
                  OutlinedButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Clear Filters'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
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
