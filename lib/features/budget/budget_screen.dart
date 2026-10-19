import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/animated_progress_bar.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';

class BudgetScreen extends StatefulWidget {
  final TransactionRepository repository;

  const BudgetScreen({super.key, required this.repository});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
  }

  Future<int?> _showCreateCategorySheet(BuildContext context) async {
    final nameController = TextEditingController();
    String selectedIcon = '🍕';
    int selectedColor = 0xFFFF6B6B;

    const availableIcons = [
      '🍕', '🛒', '🚗', '💡', '🎬', '🏥', '✈️', '🎓', '🎁', '🏋️',
      '🐾', '☕', '🏠', '⚡', '📱', '👕', '🍔', '🛍️', '📚', '🏖️'
    ];
    const availableColors = [
      0xFFFF6B6B, 0xFF4ECDC4, 0xFFF5A623, 0xFF3B82F6, 0xFFA855F7,
      0xFF10B981, 0xFFEC4899, 0xFF6366F1, 0xFFF97316, 0xFF64748B,
    ];

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        'New Expense Category',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g. Pet Care, Games',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Choose Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableIcons.map((ic) {
                          final isSel = ic == selectedIcon;
                          return InkWell(
                            onTap: () => setDialogState(() => selectedIcon = ic),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.25)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSel
                                      ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                      : Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(ic, style: const TextStyle(fontSize: 22)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Choose Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: availableColors.map((col) {
                          final isSel = col == selectedColor;
                          return InkWell(
                            onTap: () => setDialogState(() => selectedColor = col),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(col),
                              child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Create & Select Category',
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            final newId = await widget.repository.addCategory(
                              name: name,
                              icon: selectedIcon,
                              color: selectedColor,
                              isIncome: false,
                            );
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx, newId);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBudget(BuildContext context, BudgetWithCategory b) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text('Delete Budget?'),
          content: Text(
            'Are you sure you want to delete the spending limit for "${b.category.name}" for ${DateFormatter.formatMonthYear(DateTime(_selectedYear, _selectedMonth))}?\n\nExisting transactions will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.darkDanger,
              ),
              onPressed: () async {
                await widget.repository.deleteBudget(b.budget.id);
                if (dCtx.mounted) Navigator.pop(dCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Budget for ${b.category.name} deleted')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    List<Category> categories, {
    BudgetWithCategory? existing,
  }) {
    List<Category> expenseCategories = categories.where((c) => !c.isIncome).toList();
    int? selectedCategory = existing != null
        ? existing.category.id
        : (expenseCategories.isNotEmpty ? expenseCategories.first.id : null);
    final amountController = TextEditingController(
      text: existing != null
          ? (existing.budget.amount % 1 == 0
              ? existing.budget.amount.toInt().toString()
              : existing.budget.amount.toString())
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            existing != null ? 'Edit Budget' : 'Set Category Budget',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (existing != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.darkDanger),
                              tooltip: 'Delete Budget',
                              onPressed: () {
                                Navigator.pop(ctx);
                                _confirmDeleteBudget(context, existing);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Category',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                            label: const Text('New Category', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final createdId = await _showCreateCategorySheet(context);
                              if (createdId != null) {
                                final updatedCategories = await widget.repository.getAllCategories();
                                setSheetState(() {
                                  expenseCategories = updatedCategories.where((c) => !c.isIncome).toList();
                                  selectedCategory = createdId;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedCategory,
                            isExpanded: true,
                            dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                            items: expenseCategories.map((c) {
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Text(c.icon),
                                    const SizedBox(width: 10),
                                    Text(c.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: existing != null
                                ? null // In edit mode, category is locked to preserve tracking
                                : (val) {
                                    if (val != null) {
                                      setSheetState(() => selectedCategory = val);
                                    }
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Monthly Budget Amount (${CurrencyFormatter.activeSymbol})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'e.g. 15000',
                          prefixText: '${CurrencyFormatter.activeSymbol} ',
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: existing != null ? 'Update Budget' : 'Save Budget',
                        onPressed: () async {
                          final amt = double.tryParse(amountController.text);
                          if (amt != null && amt > 0 && selectedCategory != null) {
                            await widget.repository.setBudget(
                              categoryId: selectedCategory!,
                              amount: amt,
                              year: _selectedYear,
                              month: _selectedMonth,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthDate = DateTime(_selectedYear, _selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          StreamBuilder<List<Category>>(
            stream: widget.repository.watchCategories(isIncome: false),
            builder: (context, catSnap) {
              return IconButton(
                icon: const Icon(Icons.add_chart_rounded),
                tooltip: 'Set Budget',
                onPressed: () => _showSetBudgetDialog(context, catSnap.data ?? []),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionWithCategory>>(
        stream: widget.repository.watchTransactionsForMonth(_selectedYear, _selectedMonth),
        builder: (context, transSnap) {
          final transactions = transSnap.data ?? [];

          // Map expenses per category
          final Map<int, double> categorySpent = {};
          for (final t in transactions.where((t) => t.transaction.type == 'expense')) {
            categorySpent[t.category.id] = (categorySpent[t.category.id] ?? 0.0) + t.transaction.amount;
          }

          return StreamBuilder<List<BudgetWithCategory>>(
            stream: widget.repository.watchBudgetsForMonth(_selectedYear, _selectedMonth),
            builder: (context, budgetSnap) {
              final budgets = budgetSnap.data ?? [];

              final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
              final totalSpent = budgets.fold(0.0, (sum, b) => sum + (categorySpent[b.category.id] ?? 0.0));
              final totalProgress = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

              return Column(
                children: [
                  // Month Navigator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _changeMonth(-1);
                          },
                        ),
                        Text(
                          DateFormatter.formatMonthYear(monthDate),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _changeMonth(1);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Overall Monthly Budget Hero Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: CustomCard(
                      padding: const EdgeInsets.all(20),
                      borderColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL MONTHLY BUDGET',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                              Text(
                                '${(totalProgress * 100).toStringAsFixed(0)}% Spent',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: totalProgress > 0.90
                                      ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                                      : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spent',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(totalSpent),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Allocated',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(totalBudget),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AnimatedProgressBar(
                            progress: totalProgress,
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category Budgets Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category Limits (${budgets.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Budgets List
                  Expanded(
                    child: budgets.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.donut_small_rounded,
                                    size: 64,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Category Budgets Set',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Set spending caps on Food, Transit, Shopping to keep your savings on target.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  StreamBuilder<List<Category>>(
                                    stream: widget.repository.watchCategories(isIncome: false),
                                    builder: (context, catSnap) {
                                      return ElevatedButton.icon(
                                        onPressed: () => _showSetBudgetDialog(context, catSnap.data ?? []),
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('Set First Budget'),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                            itemCount: budgets.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final b = budgets[index];
                              final spent = categorySpent[b.category.id] ?? 0.0;
                              final pct = b.budget.amount > 0 ? (spent / b.budget.amount) : 0.0;
                              final isOver = spent > b.budget.amount;

                              return StreamBuilder<List<Category>>(
                                stream: widget.repository.watchCategories(isIncome: false),
                                builder: (context, catSnap) {
                                  final allExpenseCats = catSnap.data ?? [];
                                  return CustomCard(
                                    padding: const EdgeInsets.all(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        _showSetBudgetDialog(
                                          context,
                                          allExpenseCats,
                                          existing: b,
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CategoryIcon(
                                                icon: b.category.icon,
                                                color: Color(b.category.color),
                                                size: 40,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      b.category.name,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${(pct * 100).toStringAsFixed(0)}% used',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isOver
                                                            ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                                                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    CurrencyFormatter.format(spent),
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: isOver
                                                          ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                                                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                                    ),
                                                  ),
                                                  Text(
                                                    'of ${CurrencyFormatter.format(b.budget.amount)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  Icons.more_vert_rounded,
                                                  size: 20,
                                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                                ),
                                                padding: EdgeInsets.zero,
                                                onSelected: (val) {
                                                  if (val == 'edit') {
                                                    _showSetBudgetDialog(
                                                      context,
                                                      allExpenseCats,
                                                      existing: b,
                                                    );
                                                  } else if (val == 'delete') {
                                                    _confirmDeleteBudget(context, b);
                                                  }
                                                },
                                                itemBuilder: (ctx) => [
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined, size: 18),
                                                        SizedBox(width: 10),
                                                        Text('Edit Budget Limit'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.darkDanger),
                                                        SizedBox(width: 10),
                                                        Text('Delete Budget', style: TextStyle(color: AppColors.darkDanger)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          AnimatedProgressBar(
                                            progress: pct,
                                            height: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
