import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/custom_button.dart';

/// Standalone bottom sheet for quickly creating a new savings goal.
class AddSavingsGoalSheet extends StatefulWidget {
  final TransactionRepository repository;
  final SavingsGoal? existing;

  const AddSavingsGoalSheet({
    super.key,
    required this.repository,
    this.existing,
  });

  static Future<void> show(
    BuildContext context,
    TransactionRepository repository, {
    SavingsGoal? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddSavingsGoalSheet(
        repository: repository,
        existing: existing,
      ),
    );
  }

  @override
  State<AddSavingsGoalSheet> createState() => _AddSavingsGoalSheetState();
}

class _AddSavingsGoalSheetState extends State<AddSavingsGoalSheet> {
  static const List<String> _icons = [
    '🎯', '🏖️', '💻', '🚗', '🏠', '💍', '🎓', '🛡️', '⚡', '📱', '✈️', '💼'
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _currentController;
  String _selectedIcon = '🎯';

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _titleController = TextEditingController(text: g?.title ?? '');
    _targetController = TextEditingController(
      text: g != null
          ? (g.targetAmount % 1 == 0 ? g.targetAmount.toInt().toString() : g.targetAmount.toStringAsFixed(2))
          : '',
    );
    _currentController = TextEditingController(
      text: g != null
          ? (g.currentAmount % 1 == 0 ? g.currentAmount.toInt().toString() : g.currentAmount.toStringAsFixed(2))
          : '',
    );
    if (g != null) _selectedIcon = g.icon;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
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
                isEditing ? 'Edit Savings Goal' : 'Create Savings Goal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _titleController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  hintText: 'Goal Name (e.g. New Laptop, Vacation)',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetController,
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
                      controller: _currentController,
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
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final ic = _icons[idx];
                    final isSel = _selectedIcon == ic;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedIcon = ic);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel
                              ? (isDark
                                  ? AppColors.darkPrimary.withValues(alpha: 0.2)
                                  : AppColors.lightPrimary.withValues(alpha: 0.15))
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
                  final title = _titleController.text.trim();
                  final target = double.tryParse(_targetController.text) ?? 0.0;
                  final current = double.tryParse(_currentController.text) ?? 0.0;

                  if (title.isNotEmpty && target > 0) {
                    if (isEditing) {
                      await widget.repository.updateSavingsGoal(
                        id: widget.existing!.id,
                        title: title,
                        targetAmount: target,
                        currentAmount: current,
                        color: widget.existing!.color,
                        icon: _selectedIcon,
                        description: widget.existing!.description,
                        deadline: widget.existing!.deadline,
                      );
                    } else {
                      await widget.repository.addSavingsGoal(
                        title: title,
                        targetAmount: target,
                        currentAmount: current,
                        color: 0xFFF5A623,
                        icon: _selectedIcon,
                      );
                    }
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
