import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../bloc/transaction_cubit.dart';
import '../models/transaction_filter.dart';

class TransactionFilterSheet extends StatefulWidget {
  final TransactionCubit cubit;
  final TransactionState state;

  const TransactionFilterSheet({
    super.key,
    required this.cubit,
    required this.state,
  });

  static Future<void> show(BuildContext context, TransactionCubit cubit) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionFilterSheet(
        cubit: cubit,
        state: cubit.state,
      ),
    );
  }

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilter _filter;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    _filter = widget.state.filter;
    _minAmountController = TextEditingController(
      text: _filter.minAmount != null ? _filter.minAmount!.toStringAsFixed(0) : '',
    );
    _maxAmountController = TextEditingController(
      text: _filter.maxAmount != null ? _filter.maxAmount!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    HapticFeedback.mediumImpact();
    // Parse amounts
    final min = double.tryParse(_minAmountController.text.trim());
    final max = double.tryParse(_maxAmountController.text.trim());

    final updated = _filter.copyWith(
      minAmount: min,
      maxAmount: max,
      clearAmountRange: min == null && max == null,
    );

    widget.cubit.setFilter(updated);
    Navigator.pop(context);
  }

  void _resetFilter() {
    HapticFeedback.lightImpact();
    setState(() {
      _filter = const TransactionFilter();
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _filter.customStartDate ?? now.subtract(const Duration(days: 7)),
      end: _filter.customEndDate ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select Custom Date Range',
    );

    if (picked != null) {
      setState(() {
        _filter = _filter.copyWith(
          datePreset: DateFilterPreset.custom,
          customStartDate: picked.start,
          customEndDate: picked.end,
          clearSpecificDate: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, size: 20, color: primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'Filter & Sort',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                if (!_filter.isDefault)
                  TextButton.icon(
                    onPressed: _resetFilter,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.darkDanger,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                // 1. Transaction Type
                _buildSectionHeader('Transaction Type'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'All Types',
                        isSelected: _filter.type == 'all',
                        icon: Icons.all_inclusive_rounded,
                        onTap: () => setState(() => _filter = _filter.copyWith(type: 'all')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'Expenses',
                        isSelected: _filter.type == 'expense',
                        icon: Icons.arrow_upward_rounded,
                        activeColor: isDark ? AppColors.darkDanger : AppColors.lightDanger,
                        onTap: () => setState(() => _filter = _filter.copyWith(type: 'expense')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'Income',
                        isSelected: _filter.type == 'income',
                        icon: Icons.arrow_downward_rounded,
                        activeColor: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                        onTap: () => setState(() => _filter = _filter.copyWith(type: 'income')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 2. Date Range
                _buildSectionHeader('Date Filter'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'This Month (${DateFormatter.formatMonthYear(DateTime(widget.state.selectedYear, widget.state.selectedMonth))})',
                      isSelected: _filter.datePreset == DateFilterPreset.month &&
                          _filter.specificDate == null &&
                          !_filter.searchAllTime,
                      onTap: () => setState(() => _filter = _filter.copyWith(
                            datePreset: DateFilterPreset.month,
                            clearSpecificDate: true,
                            clearCustomDates: true,
                            searchAllTime: false,
                          )),
                    ),
                    _buildChoiceChip(
                      label: 'All Time',
                      isSelected: _filter.datePreset == DateFilterPreset.allTime || _filter.searchAllTime,
                      icon: Icons.history_rounded,
                      onTap: () => setState(() => _filter = _filter.copyWith(
                            datePreset: DateFilterPreset.allTime,
                            clearSpecificDate: true,
                            clearCustomDates: true,
                            searchAllTime: true,
                          )),
                    ),
                    _buildChoiceChip(
                      label: 'Today',
                      isSelected: _filter.datePreset == DateFilterPreset.today,
                      onTap: () => setState(() => _filter = _filter.copyWith(
                            datePreset: DateFilterPreset.today,
                            clearSpecificDate: true,
                            clearCustomDates: true,
                            searchAllTime: false,
                          )),
                    ),
                    _buildChoiceChip(
                      label: 'This Week',
                      isSelected: _filter.datePreset == DateFilterPreset.thisWeek,
                      onTap: () => setState(() => _filter = _filter.copyWith(
                            datePreset: DateFilterPreset.thisWeek,
                            clearSpecificDate: true,
                            clearCustomDates: true,
                            searchAllTime: false,
                          )),
                    ),
                    _buildChoiceChip(
                      label: 'Last 30 Days',
                      isSelected: _filter.datePreset == DateFilterPreset.last30Days,
                      onTap: () => setState(() => _filter = _filter.copyWith(
                            datePreset: DateFilterPreset.last30Days,
                            clearSpecificDate: true,
                            clearCustomDates: true,
                            searchAllTime: false,
                          )),
                    ),
                    _buildChoiceChip(
                      label: 'This Year',
                      isSelected: _filter.datePreset == DateFilterPreset.thisYear,
                      onTap: () => setState(() => _filter = _filter.copyWith(
                            datePreset: DateFilterPreset.thisYear,
                            clearSpecificDate: true,
                            clearCustomDates: true,
                            searchAllTime: false,
                          )),
                    ),
                    _buildChoiceChip(
                      label: _filter.datePreset == DateFilterPreset.custom &&
                              _filter.customStartDate != null &&
                              _filter.customEndDate != null
                          ? '${DateFormatter.formatShortDate(_filter.customStartDate!)} - ${DateFormatter.formatShortDate(_filter.customEndDate!)}'
                          : 'Custom Range...',
                      isSelected: _filter.datePreset == DateFilterPreset.custom,
                      icon: Icons.date_range_rounded,
                      onTap: _pickDateRange,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 3. Category Filter
                _buildSectionHeader(
                  'Categories',
                  subtitle: _filter.categoryIds.isNotEmpty
                      ? '${_filter.categoryIds.length} selected'
                      : 'All categories included',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'All Categories',
                      isSelected: _filter.categoryIds.isEmpty,
                      onTap: () => setState(() => _filter = _filter.copyWith(categoryIds: const {})),
                    ),
                    ...widget.state.allCategories.map((cat) {
                      final isSelected = _filter.categoryIds.contains(cat.id);
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(cat.name),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: primary.withValues(alpha: 0.2),
                        checkmarkColor: primary,
                        backgroundColor: cardBg,
                        side: BorderSide(
                          color: isSelected ? primary : borderCol,
                          width: isSelected ? 1.5 : 1,
                        ),
                        onSelected: (selected) {
                          HapticFeedback.selectionClick();
                          final updated = Set<int>.from(_filter.categoryIds);
                          if (selected) {
                            updated.add(cat.id);
                          } else {
                            updated.remove(cat.id);
                          }
                          setState(() => _filter = _filter.copyWith(categoryIds: updated));
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 22),

                // 4. Occasions / Trips Filter (if occasions exist)
                if (widget.state.occasionsMap.isNotEmpty) ...[
                  _buildSectionHeader('Occasion / Trip Tag'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChoiceChip(
                        label: 'All Occasions',
                        isSelected: _filter.occasionId == null,
                        onTap: () => setState(() => _filter = _filter.copyWith(clearOccasionId: true)),
                      ),
                      _buildChoiceChip(
                        label: 'No Occasion Only',
                        isSelected: _filter.occasionId == -1,
                        onTap: () => setState(() => _filter = _filter.copyWith(occasionId: -1)),
                      ),
                      ...widget.state.occasionsMap.values.map((occ) {
                        final isSelected = _filter.occasionId == occ.id;
                        return _buildChoiceChip(
                          label: '${occ.icon} ${occ.name}',
                          isSelected: isSelected,
                          onTap: () => setState(() => _filter = _filter.copyWith(occasionId: occ.id)),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],

                // 5. Amount Range
                _buildSectionHeader('Amount Range'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Min Amount',
                          prefixText: '₹ ',
                          filled: true,
                          fillColor: cardBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('to', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _maxAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Amount',
                          prefixText: '₹ ',
                          filled: true,
                          fillColor: cardBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAmountPresetChip('< ₹500', null, 500),
                    _buildAmountPresetChip('₹500 - ₹2,000', 500, 2000),
                    _buildAmountPresetChip('₹2,000 - ₹10,000', 2000, 10000),
                    _buildAmountPresetChip('> ₹10,000', 10000, null),
                  ],
                ),
                const SizedBox(height: 22),

                // 6. Sort By
                _buildSectionHeader('Sort By'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Date: Newest First',
                      icon: Icons.calendar_today_rounded,
                      isSelected: _filter.sortBy == SortOption.dateDesc,
                      onTap: () => setState(() => _filter = _filter.copyWith(sortBy: SortOption.dateDesc)),
                    ),
                    _buildChoiceChip(
                      label: 'Date: Oldest First',
                      icon: Icons.history_toggle_off_rounded,
                      isSelected: _filter.sortBy == SortOption.dateAsc,
                      onTap: () => setState(() => _filter = _filter.copyWith(sortBy: SortOption.dateAsc)),
                    ),
                    _buildChoiceChip(
                      label: 'Amount: High to Low',
                      icon: Icons.trending_up_rounded,
                      isSelected: _filter.sortBy == SortOption.amountDesc,
                      onTap: () => setState(() => _filter = _filter.copyWith(sortBy: SortOption.amountDesc)),
                    ),
                    _buildChoiceChip(
                      label: 'Amount: Low to High',
                      icon: Icons.trending_down_rounded,
                      isSelected: _filter.sortBy == SortOption.amountAsc,
                      onTap: () => setState(() => _filter = _filter.copyWith(sortBy: SortOption.amountAsc)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(top: BorderSide(color: borderCol)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _applyFilter,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? activeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = activeColor ?? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.18) : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : borderCol,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? primary : null),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? primary
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountPresetChip(String label, double? min, double? max) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() {
          _minAmountController.text = min != null ? min.toStringAsFixed(0) : '';
          _maxAmountController.text = max != null ? max.toStringAsFixed(0) : '';
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
