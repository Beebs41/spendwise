import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../categories/category_management_sheet.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionRepository repository;
  final Transaction? existingTransaction;
  final VoidCallback? onAdded;
  final VoidCallback? onDeleted;

  const AddTransactionSheet({
    super.key,
    required this.repository,
    this.existingTransaction,
    this.onAdded,
    this.onDeleted,
  });

  static Future<void> show(
    BuildContext context,
    TransactionRepository repository, {
    VoidCallback? onAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionSheet(
        repository: repository,
        onAdded: onAdded,
      ),
    );
  }

  static Future<void> showEdit(
    BuildContext context,
    TransactionRepository repository, {
    required Transaction transaction,
    VoidCallback? onUpdated,
    VoidCallback? onDeleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionSheet(
        repository: repository,
        existingTransaction: transaction,
        onAdded: onUpdated,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late String _type; // 'expense' or 'income'
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _otherSpecificController = TextEditingController();
  late DateTime _selectedDate;
  int? _selectedCategoryId;
  int? _selectedOccasionId;
  bool _isSaving = false;

  List<Category> _categories = [];
  List<Occasion> _occasions = [];
  bool _isLoadingCategories = true;

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    if (tx != null) {
      _type = tx.type;
      _amountController.text = tx.amount % 1 == 0 ? tx.amount.toInt().toString() : tx.amount.toStringAsFixed(2);
      _selectedDate = tx.date;
      _selectedCategoryId = tx.categoryId;
      _selectedOccasionId = tx.occasionId;
      _noteController.text = tx.note ?? '';
    } else {
      _type = 'expense';
      _selectedDate = DateTime.now();
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final all = await widget.repository.getAllCategories();
    final activeOccasions = await widget.repository.getActiveOccasions();
    if (mounted) {
      setState(() {
        _categories = all;
        _occasions = activeOccasions;
        _isLoadingCategories = false;
        if (_selectedCategoryId == null) {
          _setDefaultCategory();
        }
      });
    }
  }

  void _setDefaultCategory() {
    final filtered = _categories.where((c) => c.isIncome == (_type == 'income')).toList();
    if (filtered.isNotEmpty) {
      _selectedCategoryId = filtered.first.id;
    }
  }

  bool _isOtherCategorySelected() {
    if (_selectedCategoryId == null) return false;
    final cat = _categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    if (cat == null) return false;
    return cat.name.toLowerCase().contains('other');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _otherSpecificController.dispose();
    super.dispose();
  }

  void _handlePreset(double val) {
    HapticFeedback.lightImpact();
    final current = double.tryParse(_amountController.text) ?? 0.0;
    final total = current + val;
    _amountController.text = total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and category')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    String? note = _noteController.text.trim();
    if (_isOtherCategorySelected() && _otherSpecificController.text.trim().isNotEmpty) {
      final specific = _otherSpecificController.text.trim();
      note = note.isEmpty ? specific : '$specific • $note';
    }

    if (_isEditing) {
      await widget.repository.updateTransaction(
        id: widget.existingTransaction!.id,
        type: _type,
        amount: amount,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        occasionId: _type == 'expense' ? _selectedOccasionId : null,
      );
    } else {
      await widget.repository.addTransaction(
        type: _type,
        amount: amount,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        occasionId: _type == 'expense' ? _selectedOccasionId : null,
      );
    }

    if (mounted) {
      widget.onAdded?.call();
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('Are you sure you want to remove this record? This action cannot be undone.'),
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

    if (confirmed == true && widget.existingTransaction != null) {
      HapticFeedback.heavyImpact();
      await widget.repository.deleteTransaction(widget.existingTransaction!.id);
      if (mounted) {
        widget.onDeleted?.call();
        widget.onAdded?.call();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightCard;
    final filteredCategories = _categories.where((c) => c.isIncome == (_type == 'income')).toList();
    final curSymbol = CurrencyFormatter.activeSymbol;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Header Row (Edit title + Delete icon if editing)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Transaction' : 'Record Transaction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.darkDanger,
                        size: 22,
                      ),
                      tooltip: 'Delete transaction',
                      onPressed: _delete,
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Type Selector: Expense / Income
              Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _type = 'expense';
                            _setDefaultCategory();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _type == 'expense'
                                ? (isDark ? AppColors.darkDanger.withValues(alpha: 0.2) : AppColors.lightDanger.withValues(alpha: 0.12))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: _type == 'expense'
                                ? Border.all(
                                    color: isDark ? AppColors.darkDanger : AppColors.lightDanger,
                                    width: 1,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _type == 'expense'
                                  ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _type = 'income';
                            _setDefaultCategory();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _type == 'income'
                                ? (isDark ? AppColors.darkSuccess.withValues(alpha: 0.2) : AppColors.lightSuccess.withValues(alpha: 0.12))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: _type == 'income'
                                ? Border.all(
                                    color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                                    width: 1,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Income',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _type == 'income'
                                  ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Large Amount Input
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      curSymbol,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 80, maxWidth: 220),
                      child: TextField(
                        controller: _amountController,
                        autofocus: !_isEditing,
                        textAlign: TextAlign.start,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary).withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Quick preset chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [100, 500, 1000, 2000].map((preset) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text('+$curSymbol$preset'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onPressed: () => _handlePreset(preset.toDouble()),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Category Header + Manage Categories Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await CategoryManagementSheet.show(context, widget.repository);
                      _loadCategories();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 14,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 98,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
                          final isSelected = _selectedCategoryId == cat.id;
                          final color = Color(cat.color);

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategoryId = cat.id);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? color : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CategoryIcon(
                                    icon: cat.icon,
                                    color: color,
                                    size: 46,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 78,
                                  child: Text(
                                    cat.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.2,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 12),

              // Inline Specific Category Field if "Other" is chosen
              if (_isOtherCategorySelected()) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 16,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Specify "Other" Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otherSpecificController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Freelance project, Doctor clinic, Gift',
                          fillColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Date & Note Row
              Row(
                children: [
                  // Date Chip
                  Expanded(
                    flex: 4,
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormatter.formatRelative(_selectedDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Note Field
                  Expanded(
                    flex: 6,
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Note (optional)',
                        prefixIcon: Icon(
                          Icons.notes_rounded,
                          size: 20,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Occasion / Trip Selector (if active occasions exist and type is expense)
              if (_type == 'expense' && _occasions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedOccasionId,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
                      hint: Row(
                        children: [
                          Icon(
                            Icons.beach_access_rounded,
                            size: 18,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tag to Occasion / Trip (Optional)',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                              const SizedBox(width: 8),
                              const Text('No Occasion / Trip', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        ..._occasions.map((occ) {
                          return DropdownMenuItem<int?>(
                            value: occ.id,
                            child: Row(
                              children: [
                                Text(occ.icon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(occ.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedOccasionId = val);
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Save Action Button
              CustomButton(
                label: _isEditing
                    ? 'Save Changes'
                    : (_type == 'expense' ? 'Record Expense' : 'Record Income'),
                isLoading: _isSaving,
                icon: Icons.check_circle_rounded,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
