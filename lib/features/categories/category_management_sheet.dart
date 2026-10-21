import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/custom_button.dart';

class CategoryManagementSheet extends StatefulWidget {
  final TransactionRepository repository;

  const CategoryManagementSheet({super.key, required this.repository});

  static Future<void> show(BuildContext context, TransactionRepository repository) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryManagementSheet(repository: repository),
    );
  }

  @override
  State<CategoryManagementSheet> createState() => _CategoryManagementSheetState();
}

class _CategoryManagementSheetState extends State<CategoryManagementSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _availableIcons = [
    '🍕', '🛒', '🚗', '💡', '🎬', '🏥', '✈️', '🎓', '🎁', '🏋️',
    '🐾', '☕', '💼', '💻', '📈', '🎀', '💵', '💰', '🏠', '⚡', '📱', '👕'
  ];

  static const List<int> _availableColors = [
    0xFFF5A623, // Gold
    0xFFFF6B6B, // Coral
    0xFF4ECDC4, // Teal
    0xFF3B82F6, // Blue
    0xFFA855F7, // Purple
    0xFF10B981, // Emerald
    0xFFEC4899, // Pink
    0xFF6366F1, // Indigo
    0xFFF97316, // Orange
    0xFF64748B, // Slate
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddEditCategoryDialog({Category? categoryToEdit, required bool defaultIsIncome}) {
    final isEditing = categoryToEdit != null;
    final nameController = TextEditingController(text: isEditing ? categoryToEdit.name : '');
    String selectedIcon = isEditing ? categoryToEdit.icon : (defaultIsIncome ? '💵' : '🍕');
    int selectedColor = isEditing ? categoryToEdit.color : _availableColors.first;
    bool isIncome = isEditing ? categoryToEdit.isIncome : defaultIsIncome;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                        isEditing ? 'Edit Category' : 'Create New Category',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Category Name
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Category Name (e.g. Freelance, Gym, Pets)',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(10),
                            child: CategoryIcon(
                              icon: selectedIcon,
                              color: Color(selectedColor),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Type toggle (Expense vs Income)
                      if (!isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Expense')),
                                selected: !isIncome,
                                onSelected: (val) {
                                  if (val) setDialogState(() => isIncome = false);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Income')),
                                selected: isIncome,
                                onSelected: (val) {
                                  if (val) setDialogState(() => isIncome = true);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Icon Picker
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
                          itemCount: _availableIcons.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final icon = _availableIcons[idx];
                            final isSel = selectedIcon == icon;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setDialogState(() => selectedIcon = icon);
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
                                child: Text(icon, style: const TextStyle(fontSize: 22)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color Picker
                      Text(
                        'Choose Color',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableColors.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final colorInt = _availableColors[idx];
                            final isSel = selectedColor == colorInt;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setDialogState(() => selectedColor = colorInt);
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Color(colorInt),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? Colors.white : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSel
                                      ? [BoxShadow(color: Color(colorInt).withValues(alpha: 0.5), blurRadius: 8)]
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      CustomButton(
                        label: isEditing ? 'Save Changes' : 'Create Category',
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          if (isEditing) {
                            await widget.repository.updateCategory(
                              id: categoryToEdit.id,
                              name: name,
                              icon: selectedIcon,
                              color: selectedColor,
                              isIncome: categoryToEdit.isIncome,
                            );
                          } else {
                            await widget.repository.addCategory(
                              name: name,
                              icon: selectedIcon,
                              color: selectedColor,
                              isIncome: isIncome,
                            );
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
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

  Future<void> _confirmDeleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"? Past transactions under this category will remain recorded.'),
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
      await widget.repository.deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
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

          // Title & Add Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Categories',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: () => _openAddEditCategoryDialog(
                    defaultIsIncome: _tabController.index == 1,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.black,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Expenses'),
                  Tab(text: 'Income'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category List Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(isIncome: false),
                _buildCategoryList(isIncome: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList({required bool isIncome}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Category>>(
      stream: widget.repository.watchCategories(isIncome: isIncome),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No categories found.',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final cat = list[index];
            final color = Color(cat.color);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  CategoryIcon(
                    icon: cat.icon,
                    color: color,
                    size: 40,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (cat.isDefault)
                          Text(
                            'Default System Category',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    onPressed: () => _openAddEditCategoryDialog(
                      categoryToEdit: cat,
                      defaultIsIncome: isIncome,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.darkDanger,
                    ),
                    onPressed: () => _confirmDeleteCategory(cat),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
