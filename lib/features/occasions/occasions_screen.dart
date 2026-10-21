import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/currency_service.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/custom_card.dart';
import '../transactions/screens/add_transaction_sheet.dart';

class OccasionsScreen extends StatefulWidget {
  final TransactionRepository repository;

  const OccasionsScreen({super.key, required this.repository});

  static Future<void> show(BuildContext context, TransactionRepository repository) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => OccasionsScreen(repository: repository),
      ),
    );
  }

  @override
  State<OccasionsScreen> createState() => _OccasionsScreenState();
}

class _OccasionsScreenState extends State<OccasionsScreen> {
  String _filter = 'active'; // 'active', 'all', 'completed'

  static const List<String> _popularEmojis = [
    '🏖️', '✈️', '🏕️', '🚗', '🍽️', '💍', '🎉', '🎂', '🏠', '🎁', '🎬', '🏔️', '🎒', '🚆', '🌴', '💼'
  ];

  void _showCreateOrEditDialog({Occasion? occasion}) {
    final isEditing = occasion != null;
    final nameController = TextEditingController(text: occasion?.name ?? '');
    final budgetController = TextEditingController(
      text: occasion != null
          ? (occasion.budget % 1 == 0 ? occasion.budget.toInt().toString() : occasion.budget.toStringAsFixed(2))
          : '',
    );
    final descController = TextEditingController(text: occasion?.description ?? '');
    String selectedEmoji = occasion?.icon ?? '🏖️';
    String selectedCurrencyCode = occasion?.currencyCode ?? CurrencyFormatter.activeCode;
    DateTime? startDate = occasion?.startDate ?? DateTime.now();
    DateTime? endDate = occasion?.endDate ?? DateTime.now().add(const Duration(days: 3));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 16),
                      Text(
                        isEditing ? 'Edit Occasion / Trip' : 'New Occasion / Trip',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track dedicated expenses for vacations, outings, weddings, or projects.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Emoji Selector
                      const Text(
                        'Choose Icon',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _popularEmojis.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final emoji = _popularEmojis[idx];
                            final isSelected = selectedEmoji == emoji;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setModalState(() => selectedEmoji = emoji);
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.25) : AppColors.lightPrimary.withValues(alpha: 0.15))
                                      : (isDark ? AppColors.darkCard : AppColors.lightSurface),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Text(emoji, style: const TextStyle(fontSize: 22)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      TextField(
                        controller: nameController,
                        autofocus: !isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Occasion / Trip Title',
                          hintText: 'e.g. Goa Vacation, Sister\'s Wedding',
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Trip Currency Selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                CurrencyService.findByCode(selectedCurrencyCode)?.flagEmoji ?? '🌐',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Trip Currency',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${CurrencyService.findByCode(selectedCurrencyCode)?.name ?? selectedCurrencyCode} ($selectedCurrencyCode)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.arrow_drop_down_rounded),
                              label: Text(
                                selectedCurrencyCode,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                ),
                              ),
                              onPressed: () {
                                _showOccasionCurrencyPicker(ctx, selectedCurrencyCode, (newCode) {
                                  setModalState(() => selectedCurrencyCode = newCode);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Budget
                      TextField(
                        controller: budgetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Allocated Budget (${CurrencyService.findByCode(selectedCurrencyCode)?.symbol ?? CurrencyFormatter.activeSymbol})',
                          hintText: 'e.g. 25000',
                          prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today_rounded, size: 16),
                              label: Text(
                                startDate != null ? DateFormat('dd MMM yyyy').format(startDate!) : 'Start Date',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setModalState(() => startDate = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event_available_rounded, size: 16),
                              label: Text(
                                endDate != null ? DateFormat('dd MMM yyyy').format(endDate!) : 'End Date',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: endDate ?? (startDate ?? DateTime.now()),
                                  firstDate: startDate ?? DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setModalState(() => endDate = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notes / Description
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Location (Optional)',
                          hintText: 'e.g. North Goa beach resort with friends',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit
                      FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final budget = double.tryParse(budgetController.text.trim()) ?? 0.0;
                          if (name.isEmpty || budget <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid title and budget amount')),
                            );
                            return;
                          }

                          if (isEditing) {
                            await widget.repository.updateOccasion(
                              occasion.toCompanion(true).copyWith(
                                    name: drift.Value(name),
                                    budget: drift.Value(budget),
                                    icon: drift.Value(selectedEmoji),
                                    description: drift.Value(descController.text.trim().isEmpty ? null : descController.text.trim()),
                                    startDate: drift.Value(startDate),
                                    endDate: drift.Value(endDate),
                                    currencyCode: drift.Value(selectedCurrencyCode),
                                  ),
                            );
                          } else {
                            await widget.repository.addOccasion(
                              name: name,
                              budget: budget,
                              icon: selectedEmoji,
                              description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                              startDate: startDate,
                              endDate: endDate,
                              currencyCode: selectedCurrencyCode,
                            );
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Create Occasion Tracker',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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

  void _showOccasionCurrencyPicker(
    BuildContext context,
    String currentCode,
    ValueChanged<String> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Trip / Occasion Currency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: CurrencyService.supportedCurrencies.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  itemBuilder: (context, index) {
                    final curr = CurrencyService.supportedCurrencies[index];
                    final isSelected = curr.code == currentCode;
                    final isBase = curr.code == CurrencyFormatter.activeCode;

                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          curr.flagEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(curr.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (isBase) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'BASE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text('${curr.code} (${curr.symbol})'),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(curr.code);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareTripWhatsAppReport(Occasion occasion, List<TransactionWithCategory> transactions) async {
    HapticFeedback.mediumImpact();
    final cur = CurrencyFormatter.activeSymbol;
    final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.transaction.amount);
    final remaining = occasion.budget - totalSpent;
    final percent = occasion.budget > 0 ? (totalSpent / occasion.budget) * 100 : 0.0;

    final dateRange = (occasion.startDate != null && occasion.endDate != null)
        ? '${DateFormat('dd MMM yyyy').format(occasion.startDate!)} – ${DateFormat('dd MMM yyyy').format(occasion.endDate!)}'
        : 'Ongoing Trip';

    final buffer = StringBuffer();
    buffer.writeln('${occasion.icon} *${occasion.name.toUpperCase()} — EXPENSE REPORT*');
    buffer.writeln('📅 $dateRange');
    if (occasion.description != null && occasion.description!.isNotEmpty) {
      buffer.writeln('📍 ${occasion.description}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💵 *Trip Budget:* $cur${occasion.budget.toStringAsFixed(2)}');
    buffer.writeln('💸 *Total Spent:* $cur${totalSpent.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}%)');
    if (remaining >= 0) {
      buffer.writeln('💰 *Remaining Allowance:* $cur${remaining.toStringAsFixed(2)}');
    } else {
      buffer.writeln('⚠️ *Over Budget by:* $cur${(-remaining).toStringAsFixed(2)}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Category breakdown
    final Map<String, double> byCategory = {};
    for (var t in transactions) {
      byCategory[t.category.name] = (byCategory[t.category.name] ?? 0) + t.transaction.amount;
    }

    if (byCategory.isNotEmpty) {
      buffer.writeln('📂 *Category Breakdown:*');
      final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (var entry in sorted) {
        buffer.writeln('  • ${entry.key}: $cur${entry.value.toStringAsFixed(2)}');
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    // List of expenses
    if (transactions.isNotEmpty) {
      buffer.writeln('📝 *Logged Transactions (${transactions.length}):*');
      for (var t in transactions) {
        final dStr = DateFormat('dd MMM').format(t.transaction.date);
        final note = t.transaction.note != null && t.transaction.note!.isNotEmpty ? ' (${t.transaction.note})' : '';
        buffer.writeln('  • $dStr: $cur${t.transaction.amount.toStringAsFixed(2)} - ${t.category.name}$note');
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    buffer.writeln('_Generated with SpendWise — 100% Private Offline Finance_');

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: '${occasion.name} Expense Report',
      ),
    );
  }

  void _showTripDetails(BuildContext context, Occasion occasion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StreamBuilder<List<TransactionWithCategory>>(
          stream: widget.repository.watchTransactionsForOccasion(occasion.id),
          builder: (context, snapshot) {
            final transactions = snapshot.data ?? [];
            final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.transaction.amount);
            final remaining = occasion.budget - totalSpent;
            final percent = occasion.budget > 0 ? (totalSpent / occasion.budget).clamp(0.0, 1.0) : 0.0;

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
                  const SizedBox(height: 16),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(occasion.icon, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      occasion.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (occasion.currencyCode != null && occasion.currencyCode != CurrencyFormatter.activeCode) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        '${CurrencyService.findByCode(occasion.currencyCode!)?.flagEmoji ?? '🌐'} ${occasion.currencyCode}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (occasion.description != null)
                                Text(
                                  occasion.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Color(0xFF25D366)),
                          tooltip: 'Share WhatsApp Report',
                          onPressed: () => _shareTripWhatsAppReport(occasion, transactions),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Spent',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(totalSpent),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: totalSpent > occasion.budget ? AppColors.darkDanger : null,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Budget Limit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(occasion.budget),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                totalSpent > occasion.budget
                                    ? AppColors.darkDanger
                                    : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(percent * 100).toStringAsFixed(1)}% of budget',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                remaining >= 0
                                    ? '${CurrencyFormatter.format(remaining)} left'
                                    : '${CurrencyFormatter.format(-remaining)} over budget',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: remaining >= 0 ? AppColors.darkSuccess : AppColors.darkDanger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions row: Add Expense to this trip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Expense to Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              AddTransactionSheet.show(
                                context,
                                widget.repository,
                                initialOccasionId: occasion.id,
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Transactions in this Occasion',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Transaction list
                  Expanded(
                    child: transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🏕️', style: TextStyle(fontSize: 36)),
                                const SizedBox(height: 8),
                                const Text('No expenses recorded for this trip yet.'),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap "+ Add Expense to Trip" to tag expenses here',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: transactions.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = transactions[index];
                              return CustomCard(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(item.category.color).withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.receipt_rounded,
                                        size: 18,
                                        color: Color(item.category.color),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.category.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            DateFormat('dd MMM yyyy').format(item.transaction.date),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          if (item.transaction.note != null && item.transaction.note!.isNotEmpty)
                                            Text(
                                              item.transaction.note!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(item.transaction.amount),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDark ? AppColors.darkDanger : AppColors.lightDanger,
                                          ),
                                        ),
                                        if (item.transaction.originalCurrency != null &&
                                            item.transaction.originalCurrency != CurrencyFormatter.activeCode &&
                                            item.transaction.originalAmount != null)
                                          Text(
                                            '(${CurrencyService.findByCode(item.transaction.originalCurrency!)?.symbol ?? ''}${item.transaction.originalAmount!.toStringAsFixed(2)})',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
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
        title: const Text('Occasions & Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Occasion',
            onPressed: () => _showCreateOrEditDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                _buildFilterChip('active', 'Active Trips'),
                const SizedBox(width: 8),
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed'),
              ],
            ),
          ),

          // Occasions Stream
          Expanded(
            child: StreamBuilder<List<Occasion>>(
              stream: widget.repository.watchAllOccasions(includeCompleted: true),
              builder: (context, snapshot) {
                final allOccasions = snapshot.data ?? [];
                final occasions = allOccasions.where((o) {
                  if (_filter == 'active') return !o.isCompleted;
                  if (_filter == 'completed') return o.isCompleted;
                  return true;
                }).toList();

                if (occasions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                            ),
                            child: const Text('🏖️', style: TextStyle(fontSize: 44)),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _filter == 'completed'
                                ? 'No Completed Occasions'
                                : 'No Occasions or Trips Yet',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track budget & spending for specific events like Goa Vacation, Weekend Outings, Weddings, or Projects.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Plan an Occasion / Trip'),
                            onPressed: () => _showCreateOrEditDialog(),
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: occasions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final occasion = occasions[index];
                    return StreamBuilder<List<TransactionWithCategory>>(
                      stream: widget.repository.watchTransactionsForOccasion(occasion.id),
                      builder: (context, txSnap) {
                        final txs = txSnap.data ?? [];
                        final totalSpent = txs.fold(0.0, (sum, t) => sum + t.transaction.amount);
                        final remaining = occasion.budget - totalSpent;
                        final percent = occasion.budget > 0 ? (totalSpent / occasion.budget).clamp(0.0, 1.0) : 0.0;
                        final isOver = totalSpent > occasion.budget;

                        return CustomCard(
                          padding: const EdgeInsets.all(18),
                          onTap: () => _showTripDetails(context, occasion),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Emoji, Name, Menu
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(occasion.icon, style: const TextStyle(fontSize: 22)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                occasion.name,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (occasion.currencyCode != null && occasion.currencyCode != CurrencyFormatter.activeCode) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.35),
                                                  ),
                                                ),
                                                child: Text(
                                                  '${CurrencyService.findByCode(occasion.currencyCode!)?.flagEmoji ?? '🌐'} ${occasion.currencyCode}',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (occasion.isCompleted) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('COMPLETED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (occasion.startDate != null)
                                          Text(
                                            occasion.endDate != null
                                                ? '${DateFormat('dd MMM').format(occasion.startDate!)} – ${DateFormat('dd MMM yyyy').format(occasion.endDate!)}'
                                                : DateFormat('dd MMM yyyy').format(occasion.startDate!),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded),
                                    onSelected: (val) async {
                                      if (val == 'edit') {
                                        _showCreateOrEditDialog(occasion: occasion);
                                      } else if (val == 'toggle_complete') {
                                        await widget.repository.updateOccasion(
                                          occasion.toCompanion(true).copyWith(
                                                isCompleted: drift.Value(!occasion.isCompleted),
                                              ),
                                        );
                                      } else if (val == 'delete') {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Occasion?'),
                                            content: Text('Delete "${occasion.name}"? Transactions logged under this occasion will be unlinked but not deleted.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: TextButton.styleFrom(foregroundColor: AppColors.darkDanger),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await widget.repository.deleteOccasion(occasion.id);
                                        }
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle_complete',
                                        child: Row(
                                          children: [
                                            Icon(occasion.isCompleted ? Icons.replay_rounded : Icons.check_circle_outline_rounded, size: 18),
                                            SizedBox(width: 8),
                                            Text(occasion.isCompleted ? 'Mark Active' : 'Mark Completed'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Budget progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 7,
                                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOver
                                        ? AppColors.darkDanger
                                        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Amounts row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Spent: ${CurrencyFormatter.format(totalSpent)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isOver ? AppColors.darkDanger : null,
                                    ),
                                  ),
                                  Text(
                                    remaining >= 0
                                        ? '${CurrencyFormatter.format(remaining)} left'
                                        : '${CurrencyFormatter.format(-remaining)} over',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: remaining >= 0 ? AppColors.darkSuccess : AppColors.darkDanger,
                                    ),
                                  ),
                                  Text(
                                    'Budget: ${CurrencyFormatter.format(occasion.budget)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Actions: WhatsApp share & Details
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF25D366)),
                                    label: const Text('WhatsApp Report', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _shareTripWhatsAppReport(occasion, txs),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                    label: Text('${txs.length} Expenses', style: const TextStyle(fontSize: 11)),
                                    onPressed: () => _showTripDetails(context, occasion),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = key),
      selectedColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.25),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      ),
      side: BorderSide(
        color: isSelected
            ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
    );
  }
}
