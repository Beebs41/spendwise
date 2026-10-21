import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/animated_progress_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';

class SavingsScreen extends StatefulWidget {
  final TransactionRepository repository;

  const SavingsScreen({super.key, required this.repository});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _wishlistFilter = 'active'; // 'active', 'purchased', 'all'

  static const List<String> _goalIcons = ['🎯', '🏖️', '💻', '🚗', '🏠', '💍', '🎓', '🛡️', '⚡', '📱', '✈️', '💼'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditGoalDialog({SavingsGoal? goalToEdit}) {
    final isEditing = goalToEdit != null;
    final titleController = TextEditingController(text: isEditing ? goalToEdit.title : '');
    final targetController = TextEditingController(
      text: isEditing
          ? (goalToEdit.targetAmount % 1 == 0 ? goalToEdit.targetAmount.toInt().toString() : goalToEdit.targetAmount.toStringAsFixed(2))
          : '',
    );
    final currentController = TextEditingController(
      text: isEditing
          ? (goalToEdit.currentAmount % 1 == 0 ? goalToEdit.currentAmount.toInt().toString() : goalToEdit.currentAmount.toStringAsFixed(2))
          : '',
    );
    String selectedIcon = isEditing ? goalToEdit.icon : '🎯';
    final curSymbol = CurrencyFormatter.activeSymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
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
                        isEditing ? 'Edit Savings Goal' : 'Create Savings Goal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        autofocus: !isEditing,
                        decoration: const InputDecoration(
                          hintText: 'Goal Name (e.g. Vacation in Bali, New Car)',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: targetController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Target ($curSymbol)',
                                prefixText: '$curSymbol ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: currentController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Saved So Far ($curSymbol)',
                                prefixText: '$curSymbol ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Choose Icon',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _goalIcons.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final ic = _goalIcons[idx];
                            final isSel = selectedIcon == ic;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(() => selectedIcon = ic);
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : AppColors.lightPrimary.withValues(alpha: 0.15))
                                      : (isDark ? AppColors.darkCard : AppColors.lightSurface),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel ? AppColors.darkPrimary : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(ic, style: const TextStyle(fontSize: 22)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: isEditing ? 'Save Changes' : 'Create Goal',
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final target = double.tryParse(targetController.text) ?? 0.0;
                          final current = double.tryParse(currentController.text) ?? 0.0;

                          if (title.isNotEmpty && target > 0) {
                            if (isEditing) {
                              await widget.repository.updateSavingsGoal(
                                id: goalToEdit.id,
                                title: title,
                                targetAmount: target,
                                currentAmount: current,
                                color: goalToEdit.color,
                                icon: selectedIcon,
                                description: goalToEdit.description,
                                deadline: goalToEdit.deadline,
                              );
                            } else {
                              await widget.repository.addSavingsGoal(
                                title: title,
                                targetAmount: target,
                                currentAmount: current,
                                color: 0xFFF5A623,
                                icon: selectedIcon,
                              );
                            }
                            if (modalCtx.mounted) Navigator.pop(modalCtx);
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

  Future<void> _confirmDeleteGoal(SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
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
      await widget.repository.deleteSavingsGoal(goal.id);
    }
  }

  void _showAddEditCartItemDialog({CartItem? itemToEdit}) async {
    final isEditing = itemToEdit != null;
    final nameController = TextEditingController(text: isEditing ? itemToEdit.name : '');
    final priceController = TextEditingController(
      text: isEditing
          ? (itemToEdit.price % 1 == 0 ? itemToEdit.price.toInt().toString() : itemToEdit.price.toStringAsFixed(2))
          : '',
    );
    final savedController = TextEditingController(
      text: isEditing
          ? (itemToEdit.savedAmount % 1 == 0 ? itemToEdit.savedAmount.toInt().toString() : itemToEdit.savedAmount.toStringAsFixed(2))
          : '',
    );
    final noteController = TextEditingController(text: isEditing ? (itemToEdit.note ?? '') : '');
    String selectedPriority = isEditing ? itemToEdit.priority : 'medium';
    int? selectedGoalId = isEditing ? itemToEdit.savingsGoalId : null;
    final curSymbol = CurrencyFormatter.activeSymbol;

    final availableGoals = await widget.repository.getAllSavingsGoals();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
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
                        isEditing ? 'Edit Wishlist Item' : 'Add Wishlist / Cart Item',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Plan and allocate savings for your desired purchases before buying.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        autofocus: !isEditing,
                        decoration: const InputDecoration(
                          hintText: 'Item Name (e.g. Sony WH-1000XM5)',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Price ($curSymbol)',
                                prefixText: '$curSymbol ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: savedController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Saved ($curSymbol)',
                                prefixText: '$curSymbol ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Priority selection
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPriorityChip('low', '🟢 Low', selectedPriority, isDark, (p) {
                            setSheetState(() => selectedPriority = p);
                          }),
                          const SizedBox(width: 8),
                          _buildPriorityChip('medium', '🟡 Medium', selectedPriority, isDark, (p) {
                            setSheetState(() => selectedPriority = p);
                          }),
                          const SizedBox(width: 8),
                          _buildPriorityChip('high', '🔴 High', selectedPriority, isDark, (p) {
                            setSheetState(() => selectedPriority = p);
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Link to Savings Goal
                      if (availableGoals.isNotEmpty) ...[
                        DropdownButtonFormField<int?>(
                          initialValue: selectedGoalId,
                          decoration: const InputDecoration(
                            labelText: 'Link to Savings Goal (Optional)',
                            prefixIcon: Icon(Icons.flag_outlined),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('None (Independent Item)'),
                            ),
                            ...availableGoals.map((g) {
                              return DropdownMenuItem<int?>(
                                value: g.id,
                                child: Text(
                                  '${g.icon} ${g.title} (${CurrencyFormatter.format(g.currentAmount)} / ${CurrencyFormatter.format(g.targetAmount)})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setSheetState(() => selectedGoalId = val);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          hintText: 'Note or Link (Optional)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: isEditing ? 'Save Changes' : 'Add to Wishlist',
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final price = double.tryParse(priceController.text) ?? 0.0;
                          final saved = double.tryParse(savedController.text) ?? 0.0;
                          final note = noteController.text.trim();

                          if (name.isNotEmpty && price > 0) {
                            if (isEditing) {
                              await widget.repository.updateCartItem(
                                id: itemToEdit.id,
                                name: name,
                                price: price,
                                savedAmount: saved,
                                priority: selectedPriority,
                                isPurchased: itemToEdit.isPurchased,
                                note: note.isEmpty ? null : note,
                                savingsGoalId: selectedGoalId,
                              );
                            } else {
                              await widget.repository.addCartItem(
                                name: name,
                                price: price,
                                savedAmount: saved,
                                priority: selectedPriority,
                                note: note.isEmpty ? null : note,
                                savingsGoalId: selectedGoalId,
                              );
                            }
                            if (modalCtx.mounted) Navigator.pop(modalCtx);
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

  void _showPurchaseConfirmationSheet(CartItemWithGoal itemWithGoal) async {
    final item = itemWithGoal.cartItem;
    final goal = itemWithGoal.savingsGoal;
    final curSymbol = CurrencyFormatter.activeSymbol;

    final categories = await widget.repository.getAllCategories();
    final expenseCategories = categories.where((c) => !c.isIncome).toList();
    if (expenseCategories.isEmpty && categories.isNotEmpty) {
      expenseCategories.addAll(categories);
    }

    final defaultCat = expenseCategories.firstWhere(
      (c) => c.name.toLowerCase().contains('shop'),
      orElse: () => expenseCategories.isNotEmpty ? expenseCategories.first : categories.first,
    );

    int selectedCategoryId = defaultCat.id;
    DateTime selectedDate = DateTime.now();
    bool recordAsExpense = true;
    bool markGoalCompleted = goal != null && (item.savedAmount >= goal.targetAmount || item.price >= goal.targetAmount);

    final priceController = TextEditingController(
      text: item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toStringAsFixed(2),
    );
    final noteController = TextEditingController(
      text: 'Purchased wishlist item: ${item.name}',
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text('🎉', style: TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mark as Purchased',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.name} (${CurrencyFormatter.format(item.price)})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Actual Purchase Price',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixText: '$curSymbol ',
                          hintText: 'Final amount paid',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              value: recordAsExpense,
                              activeThumbColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Record as Expense Transaction',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: const Text(
                                'Auto-create a transaction with category and date',
                                style: TextStyle(fontSize: 12),
                              ),
                              onChanged: (val) {
                                setSheetState(() {
                                  recordAsExpense = val;
                                });
                              },
                            ),
                            if (recordAsExpense) ...[
                              const Divider(height: 16),
                              DropdownButtonFormField<int>(
                                initialValue: selectedCategoryId,
                                decoration: const InputDecoration(
                                  labelText: 'Expense Category',
                                  prefixIcon: Icon(Icons.category_outlined),
                                  isDense: true,
                                ),
                                items: expenseCategories.map((c) {
                                  return DropdownMenuItem<int>(
                                    value: c.id,
                                    child: Row(
                                      children: [
                                        Text(c.icon),
                                        const SizedBox(width: 8),
                                        Text(c.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() {
                                      selectedCategoryId = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: sheetCtx,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          DateFormat.yMMMd().format(selectedDate),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: noteController,
                                decoration: const InputDecoration(
                                  labelText: 'Note',
                                  prefixIcon: Icon(Icons.edit_note_rounded),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (goal != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(goal.color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(goal.color).withValues(alpha: 0.3),
                            ),
                          ),
                          child: SwitchListTile.adaptive(
                            value: markGoalCompleted,
                            activeThumbColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Complete Goal "${goal.title}"',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              'Mark linked savings goal as 100% reached',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            onChanged: (val) {
                              setSheetState(() {
                                markGoalCompleted = val;
                              });
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      CustomButton(
                        label: recordAsExpense ? 'Confirm & Record Expense' : 'Mark as Purchased',
                        onPressed: () async {
                          final actualPrice = double.tryParse(priceController.text) ?? item.price;
                          await widget.repository.markCartItemPurchased(
                            cartItemId: item.id,
                            recordAsTransaction: recordAsExpense,
                            actualPrice: actualPrice,
                            categoryId: selectedCategoryId,
                            date: selectedDate,
                            note: noteController.text.trim(),
                            markGoalCompleted: markGoalCompleted,
                          );

                          HapticFeedback.mediumImpact();
                          if (modalCtx.mounted) Navigator.pop(modalCtx);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  recordAsExpense
                                      ? '🎉 Purchased "${item.name}" & recorded ${CurrencyFormatter.format(actualPrice)} expense!'
                                      : '🎉 Purchased "${item.name}"!',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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

  Widget _buildPriorityChip(String key, String label, String current, bool isDark, Function(String) onSelect) {
    final isSelected = current.toLowerCase() == key.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? _getPriorityColor(key, isDark).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? _getPriorityColor(key, isDark)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? _getPriorityColor(key, isDark)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority, bool isDark) {
    switch (priority.toLowerCase()) {
      case 'high':
        return isDark ? AppColors.darkDanger : AppColors.lightDanger;
      case 'low':
        return isDark ? AppColors.darkAccent : AppColors.lightAccent;
      case 'medium':
      default:
        return isDark ? AppColors.darkWarning : AppColors.lightWarning;
    }
  }

  Future<void> _confirmDeleteCartItem(CartItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Wishlist Item?'),
        content: Text('Are you sure you want to remove "${item.name}" from your wishlist?'),
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
      await widget.repository.deleteCartItem(item.id);
    }
  }

  void _showDepositDialog({
    required BuildContext context,
    required String title,
    required double current,
    required double target,
    required Function(double) onDeposit,
  }) {
    final depositController = TextEditingController();
    final curSymbol = CurrencyFormatter.activeSymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (sheetCtx, _) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
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
                        'Add Funds to "$title"',
                        style: Theme.of(modalCtx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Current: ${CurrencyFormatter.format(current)} / Target: ${CurrencyFormatter.format(target)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: depositController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Deposit Amount ($curSymbol)',
                          prefixText: '$curSymbol ',
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Add Savings',
                        onPressed: () {
                          final amt = double.tryParse(depositController.text);
                          if (amt != null && amt > 0) {
                            onDeposit(current + amt);
                            Navigator.pop(modalCtx);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Planner'),
        actions: [
          IconButton(
            tooltip: _tabController.index == 0 ? 'New Goal' : 'New Item',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (_tabController.index == 0) {
                _showAddEditGoalDialog();
              } else {
                _showAddEditCartItemDialog();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          indicatorColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          tabs: const [
            Tab(text: 'Goals'),
            Tab(text: 'Cart & Wishlist'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Goals Tab
          StreamBuilder<List<SavingsGoal>>(
            stream: widget.repository.watchSavingsGoals(),
            builder: (context, snapshot) {
              final goals = snapshot.data ?? [];
              if (goals.isEmpty) {
                return _EmptySavingsView(
                  title: 'No Goals Created',
                  subtitle: 'Create a savings goal for your vacation, emergency fund, or next big milestone.',
                  buttonText: 'Create Goal',
                  onPressed: () => _showAddEditGoalDialog(),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                itemCount: goals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final g = goals[index];
                  final pct = g.targetAmount > 0 ? (g.currentAmount / g.targetAmount) : 0.0;
                  final isDone = g.currentAmount >= g.targetAmount;

                  return CustomCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(g.icon, style: const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isDone
                                        ? '🎉 Goal Reached!'
                                        : '${CurrencyFormatter.format(g.currentAmount)} of ${CurrencyFormatter.format(g.targetAmount)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDone
                                          ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                      fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              tooltip: 'Add funds',
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              onPressed: () {
                                _showDepositDialog(
                                  context: context,
                                  title: g.title,
                                  current: g.currentAmount,
                                  target: g.targetAmount,
                                  onDeposit: (newAmt) => widget.repository.updateSavingsAmount(g.id, newAmt),
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showAddEditGoalDialog(goalToEdit: g);
                                } else if (val == 'delete') {
                                  _confirmDeleteGoal(g);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit Goal'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.darkDanger),
                                      const SizedBox(width: 8),
                                      Text('Delete Goal', style: TextStyle(color: AppColors.darkDanger)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AnimatedProgressBar(
                          progress: pct,
                          height: 8,
                          color: isDone ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess) : null,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // Cart & Wishlist Tab
          StreamBuilder<List<CartItemWithGoal>>(
            stream: widget.repository.watchCartItemsWithGoal(),
            builder: (context, snapshot) {
              final allItems = snapshot.data ?? [];
              final activeCount = allItems.where((i) => !i.cartItem.isPurchased).length;
              final purchasedCount = allItems.where((i) => i.cartItem.isPurchased).length;

              final items = allItems.where((i) {
                if (_wishlistFilter == 'active') return !i.cartItem.isPurchased;
                if (_wishlistFilter == 'purchased') return i.cartItem.isPurchased;
                return true;
              }).toList();

              if (allItems.isEmpty) {
                return _EmptySavingsView(
                  title: 'No Wishlist Items',
                  subtitle: 'Save up for items in your shopping cart before pulling the trigger.',
                  buttonText: 'Add Wishlist Item',
                  onPressed: () => _showAddEditCartItemDialog(),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Row(
                      children: [
                        _buildFilterChip('active', 'Active ($activeCount)', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('purchased', 'Purchased ($purchasedCount)', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('all', 'All (${allItems.length})', isDark),
                      ],
                    ),
                  ),
                  if (items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _wishlistFilter == 'purchased'
                                ? 'No purchased items yet. Items you purchase will appear here!'
                                : 'No active wishlist items found.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final itemWithGoal = items[index];
                          final item = itemWithGoal.cartItem;
                          final goal = itemWithGoal.savingsGoal;
                          final isPurchased = item.isPurchased;
                          final pct = item.price > 0 ? (item.savedAmount / item.price).clamp(0.0, 1.0) : 0.0;
                          final ready = item.savedAmount >= item.price;

                          return CustomCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isPurchased
                                            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.15)
                                            : (isDark ? AppColors.darkAccent : AppColors.lightAccent).withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isPurchased ? Icons.check_circle_rounded : Icons.shopping_bag_outlined,
                                        color: isPurchased
                                            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                            : (isDark ? AppColors.darkAccent : AppColors.lightAccent),
                                        size: 24,
                                      ),
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
                                                  item.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: isPurchased ? TextDecoration.lineThrough : null,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!isPurchased) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getPriorityColor(item.priority, isDark).withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    item.priority.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _getPriorityColor(item.priority, isDark),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isPurchased
                                                ? '🎉 Purchased for ${CurrencyFormatter.format(item.price)}'
                                                : ready
                                                    ? '✅ 100% Funded (${CurrencyFormatter.format(item.price)})'
                                                    : '${CurrencyFormatter.format(item.savedAmount)} saved / ${CurrencyFormatter.format(item.price)}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: (isPurchased || ready)
                                                  ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                              fontWeight: (isPurchased || ready) ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        size: 20,
                                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                      ),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showAddEditCartItemDialog(itemToEdit: item);
                                        } else if (val == 'unpurchase') {
                                          widget.repository.unmarkCartItemPurchased(item.id);
                                        } else if (val == 'delete') {
                                          _confirmDeleteCartItem(item);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit Item'),
                                            ],
                                          ),
                                        ),
                                        if (isPurchased)
                                          const PopupMenuItem(
                                            value: 'unpurchase',
                                            child: Row(
                                              children: [
                                                Icon(Icons.replay_rounded, size: 18),
                                                SizedBox(width: 8),
                                                Text('Mark as Unpurchased'),
                                              ],
                                            ),
                                          ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.darkDanger),
                                              SizedBox(width: 8),
                                              Text('Delete Item', style: TextStyle(color: AppColors.darkDanger)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (goal != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Color(goal.color).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Color(goal.color).withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(goal.icon, style: const TextStyle(fontSize: 13)),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Linked Goal: ${goal.title} (${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)})',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (item.note != null && item.note!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.note!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                AnimatedProgressBar(
                                  progress: pct,
                                  height: 8,
                                  color: (isPurchased || ready)
                                      ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                      : (isDark ? AppColors.darkAccent : AppColors.lightAccent),
                                ),
                                if (!isPurchased) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                          label: const Text('Deposit'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            _showDepositDialog(
                                              context: context,
                                              title: item.name,
                                              current: item.savedAmount,
                                              target: item.price,
                                              onDeposit: (newAmt) => widget.repository.depositToCartItem(
                                                cartItemId: item.id,
                                                newSavedAmount: newAmt,
                                                syncLinkedGoal: true,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                                          label: const Text('Buy / Purchased'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ready
                                                ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                                : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            _showPurchaseConfirmationSheet(itemWithGoal);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSelected = _wishlistFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _wishlistFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
              : (isDark ? AppColors.darkSurface : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

class _EmptySavingsView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _EmptySavingsView({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Text('🎯', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: buttonText,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
