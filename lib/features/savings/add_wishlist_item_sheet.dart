import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/custom_button.dart';

/// Standalone bottom sheet for adding or editing a Wishlist / Cart item.
class AddWishlistItemSheet extends StatefulWidget {
  final TransactionRepository repository;
  final CartItem? existing;

  const AddWishlistItemSheet({
    super.key,
    required this.repository,
    this.existing,
  });

  static Future<void> show(
    BuildContext context,
    TransactionRepository repository, {
    CartItem? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddWishlistItemSheet(
        repository: repository,
        existing: existing,
      ),
    );
  }

  @override
  State<AddWishlistItemSheet> createState() => _AddWishlistItemSheetState();
}

class _AddWishlistItemSheetState extends State<AddWishlistItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _savedController;
  late final TextEditingController _noteController;

  String _selectedPriority = 'medium';
  int? _selectedGoalId;
  List<SavingsGoal> _availableGoals = [];
  bool _isLoadingGoals = true;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null
          ? (item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toStringAsFixed(2))
          : '',
    );
    _savedController = TextEditingController(
      text: item != null
          ? (item.savedAmount % 1 == 0 ? item.savedAmount.toInt().toString() : item.savedAmount.toStringAsFixed(2))
          : '',
    );
    _noteController = TextEditingController(text: item?.note ?? '');
    if (item != null) {
      _selectedPriority = item.priority;
      _selectedGoalId = item.savingsGoalId;
    }
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    try {
      final goals = await widget.repository.getAllSavingsGoals();
      if (mounted) {
        setState(() {
          _availableGoals = goals;
          _isLoadingGoals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGoals = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _savedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildPriorityChip(String level, String label, bool isDark) {
    final isSelected = _selectedPriority == level;
    final color = _getPriorityColor(level, isDark);

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPriority = level);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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
        return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      default:
        return isDark ? AppColors.darkWarning : AppColors.lightWarning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existing != null;
    final curSymbol = CurrencyFormatter.activeSymbol;

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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF8B5CF6), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Wishlist Item' : 'Add Wishlist Item',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track desired items and allocate savings over time.',
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
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g. Sony Headphones, New Shoes',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target Price',
                        hintText: '0.00',
                        prefixText: '$curSymbol ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _savedController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Already Saved',
                        hintText: '0.00',
                        prefixText: '$curSymbol ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                  _buildPriorityChip('low', '🟢 Low', isDark),
                  const SizedBox(width: 8),
                  _buildPriorityChip('medium', '🟡 Medium', isDark),
                  const SizedBox(width: 8),
                  _buildPriorityChip('high', '🔴 High', isDark),
                ],
              ),
              const SizedBox(height: 16),
              if (!_isLoadingGoals && _availableGoals.isNotEmpty) ...[
                DropdownButtonFormField<int?>(
                  initialValue: _selectedGoalId,
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
                    ..._availableGoals.map((g) {
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
                    setState(() => _selectedGoalId = val);
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note or Store Link (Optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: isEditing ? 'Save Changes' : 'Add to Wishlist',
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final price = double.tryParse(_priceController.text) ?? 0.0;
                  final saved = double.tryParse(_savedController.text) ?? 0.0;
                  final note = _noteController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an item name')),
                    );
                    return;
                  }
                  if (price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid price')),
                    );
                    return;
                  }

                  HapticFeedback.mediumImpact();
                  if (isEditing) {
                    await widget.repository.updateCartItem(
                      id: widget.existing!.id,
                      name: name,
                      price: price,
                      savedAmount: saved,
                      priority: _selectedPriority,
                      isPurchased: widget.existing!.isPurchased,
                      note: note.isEmpty ? null : note,
                      savingsGoalId: _selectedGoalId,
                    );
                  } else {
                    await widget.repository.addCartItem(
                      name: name,
                      price: price,
                      savedAmount: saved,
                      priority: _selectedPriority,
                      note: note.isEmpty ? null : note,
                      savingsGoalId: _selectedGoalId,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
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
