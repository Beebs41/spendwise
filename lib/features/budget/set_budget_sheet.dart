import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/custom_button.dart';

/// Standalone bottom sheet for setting or editing a category budget.
/// Can be invoked from the Speed Dial FAB or directly from BudgetScreen.
class SetBudgetSheet extends StatefulWidget {
  final TransactionRepository repository;
  final BudgetWithCategory? existing;
  final int? initialYear;
  final int? initialMonth;

  const SetBudgetSheet({
    super.key,
    required this.repository,
    this.existing,
    this.initialYear,
    this.initialMonth,
  });

  static Future<void> show(
    BuildContext context,
    TransactionRepository repository, {
    BudgetWithCategory? existing,
    int? year,
    int? month,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetBudgetSheet(
        repository: repository,
        existing: existing,
        initialYear: year,
        initialMonth: month,
      ),
    );
  }

  @override
  State<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<SetBudgetSheet> {
  late final TextEditingController _amountController;
  late int _selectedYear;
  late int _selectedMonth;
  int? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = widget.initialYear ?? now.year;
    _selectedMonth = widget.initialMonth ?? now.month;

    final existing = widget.existing;
    _amountController = TextEditingController(
      text: existing != null
          ? (existing.budget.amount % 1 == 0
              ? existing.budget.amount.toInt().toString()
              : existing.budget.amount.toString())
          : '',
    );
    _selectedCategoryId = existing?.category.id;
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final allCats = await widget.repository.getAllCategories();
    final expenseCats = allCats.where((c) => !c.isIncome).toList();
    if (mounted) {
      setState(() {
        _categories = expenseCats;
        if (_selectedCategoryId == null && expenseCats.isNotEmpty) {
          _selectedCategoryId = expenseCats.first.id;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existing != null;

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
              // Drag handle
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
                isEditing ? 'Edit Category Budget' : 'Set Category Budget',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
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
                      value: _selectedCategoryId,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                      items: _categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Row(
                            children: [
                              Text(c.icon, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Text(c.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: isEditing
                          ? null
                          : (val) {
                              if (val != null) setState(() => _selectedCategoryId = val);
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
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. 15000',
                  prefixText: '${CurrencyFormatter.activeSymbol} ',
                ),
              ),

              const SizedBox(height: 24),
              CustomButton(
                label: isEditing ? 'Update Budget' : 'Save Budget',
                onPressed: () async {
                  final amt = double.tryParse(_amountController.text);
                  if (amt != null && amt > 0 && _selectedCategoryId != null) {
                    await widget.repository.setBudget(
                      categoryId: _selectedCategoryId!,
                      amount: amt,
                      year: _selectedYear,
                      month: _selectedMonth,
                    );
                    HapticFeedback.lightImpact();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
