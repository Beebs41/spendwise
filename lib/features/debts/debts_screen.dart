import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/widgets/custom_card.dart';

class DebtsScreen extends StatefulWidget {
  final TransactionRepository repository;

  const DebtsScreen({super.key, required this.repository});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  // 0: All Active, 1: You'll Get (Lent), 2: You Owe (Borrowed), 3: Settled
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts & Loans'),
        actions: [
          IconButton(
            tooltip: 'Add Debt or Loan',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditDebtSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Debt>>(
        stream: widget.repository.watchAllDebts(),
        builder: (context, snapshot) {
          final allDebts = snapshot.data ?? [];

          // Compute Metrics
          final activeDebts = allDebts.where((d) => !d.isSettled).toList();
          final settledDebts = allDebts.where((d) => d.isSettled).toList();

          final totalLentActive = activeDebts
              .where((d) => d.type == 'lent')
              .fold(0.0, (sum, d) => sum + (d.amount - d.settledAmount).clamp(0.0, double.infinity));

          final totalBorrowedActive = activeDebts
              .where((d) => d.type == 'borrowed')
              .fold(0.0, (sum, d) => sum + (d.amount - d.settledAmount).clamp(0.0, double.infinity));

          final netBalance = totalLentActive - totalBorrowedActive;

          // Apply Filter
          List<Debt> displayedDebts;
          switch (_selectedFilterIndex) {
            case 1:
              displayedDebts = activeDebts.where((d) => d.type == 'lent').toList();
              break;
            case 2:
              displayedDebts = activeDebts.where((d) => d.type == 'borrowed').toList();
              break;
            case 3:
              displayedDebts = settledDebts;
              break;
            default:
              displayedDebts = activeDebts;
          }

          return CustomScrollView(
            slivers: [
              // Summary Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: "YOU'LL GET",
                              subtitle: 'Money Lent',
                              amount: totalLentActive,
                              color: AppColors.income,
                              icon: Icons.arrow_downward_rounded,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'YOU OWE',
                              subtitle: 'Money Borrowed',
                              amount: totalBorrowedActive,
                              color: AppColors.expense,
                              icon: Icons.arrow_upward_rounded,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Net Position Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 18,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Net Debt Position',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${netBalance >= 0 ? '+' : ''}${CurrencyFormatter.format(netBalance)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: netBalance >= 0 ? AppColors.income : AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Tabs
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      _buildFilterChip('All Active (${activeDebts.length})', 0, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "You'll Get (${activeDebts.where((d) => d.type == 'lent').length})",
                        1,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'You Owe (${activeDebts.where((d) => d.type == 'borrowed').length})',
                        2,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Settled (${settledDebts.length})', 3, isDark),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Debts List
              if (displayedDebts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedFilterIndex == 3
                                ? Icons.task_alt_rounded
                                : Icons.handshake_outlined,
                            size: 64,
                            color: (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilterIndex == 3
                                ? 'No settled debts yet'
                                : 'No active debts found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedFilterIndex == 3
                                ? 'Completed repayments will be archived here.'
                                : 'Tap "+" to track money you lent or borrowed from friends.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedFilterIndex != 3) ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => _showAddEditDebtSheet(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Debt or Loan'),
                              style: FilledButton.styleFrom(
                                backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final debt = displayedDebts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DebtCard(
                            debt: debt,
                            repository: widget.repository,
                            onEdit: () => _showAddEditDebtSheet(context, debt: debt),
                            onRecordPayment: () => _showRecordPaymentSheet(context, debt),
                            onViewHistory: () => _showPaymentHistorySheet(context, debt),
                            onSendReminder: () => _showReminderSheet(context, debt),
                          ),
                        );
                      },
                      childCount: displayedDebts.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilterIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.black
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Add / Edit Debt Sheet with Native Contact Picker Integration
  // -------------------------------------------------------------
  void _showAddEditDebtSheet(BuildContext context, {Debt? debt}) {
    final isEditing = debt != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: debt?.personName ?? '');
    final phoneCtrl = TextEditingController(text: debt?.phoneNumber ?? '');
    final amountCtrl = TextEditingController(
      text: debt != null ? debt.amount.toStringAsFixed(0) : '',
    );
    final notesCtrl = TextEditingController(text: debt?.notes ?? '');

    String debtType = debt?.type ?? 'lent'; // 'lent' vs 'borrowed'
    DateTime? dueDate = debt?.dueDate;

    final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              margin: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 20),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                      isEditing ? 'Edit Debt Record' : 'Record New Debt',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep track of money lent or borrowed with optional contact sync',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Debt Type Selector (Lent vs Borrowed)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
                                setModalState(() => debtType = 'lent');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: debtType == 'lent'
                                      ? AppColors.income
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 16,
                                      color: debtType == 'lent' ? Colors.black : AppColors.income,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'I Lent (They Owe Me)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: debtType == 'lent'
                                            ? Colors.black
                                            : (isDark ? Colors.white : Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setModalState(() => debtType = 'borrowed');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: debtType == 'borrowed'
                                      ? AppColors.expense
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 16,
                                      color: debtType == 'borrowed' ? Colors.white : AppColors.expense,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'I Borrowed (I Owe)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: debtType == 'borrowed'
                                            ? Colors.white
                                            : (isDark ? Colors.white : Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Person Name & Contact Picker Button
                    Text(
                      'PERSON / CONTACT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: "Enter person's name",
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                              filled: true,
                              fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Native Contact Picker Trigger
                        IconButton.filledTonal(
                          tooltip: 'Pick from Contacts',
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.contacts_rounded),
                          onPressed: () async {
                            try {
                              HapticFeedback.selectionClick();
                              final contact = await contactPicker.selectContact();
                              if (contact != null) {
                                setModalState(() {
                                  nameCtrl.text = contact.fullName ?? '';
                                  if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
                                    phoneCtrl.text = contact.phoneNumbers!.first;
                                  }
                                });
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Contact picker error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Phone Number (Optional)
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Optional for WhatsApp reminder)',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Total Principal Amount
                    Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            widthFactor: 0,
                            child: Text(
                              CurrencyFormatter.activeSymbol,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        hintText: '0.00',
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Due Date Picker (Optional)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            icon: const Icon(Icons.calendar_month_rounded, size: 18),
                            label: Text(
                              dueDate != null
                                  ? 'Due: ${DateFormat('dd MMM yyyy').format(dueDate!)}'
                                  : 'Set Repayment Due Date',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (picked != null) {
                                setModalState(() => dueDate = picked);
                              }
                            },
                          ),
                        ),
                        if (dueDate != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear due date',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setModalState(() => dueDate = null),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Notes / Description
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes (e.g. Goa trip shared expense, dinner bill)',
                        prefixIcon: const Icon(Icons.notes_rounded),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text("Please enter or select a contact's name")),
                            );
                            return;
                          }
                          if (amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount greater than 0')),
                            );
                            return;
                          }

                          if (isEditing) {
                            await widget.repository.updateDebt(
                              debt.copyWith(
                                personName: name,
                                phoneNumber: drift.Value(phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim()),
                                type: debtType,
                                amount: amount,
                                dueDate: drift.Value(dueDate),
                                notes: drift.Value(notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim()),
                              ),
                            );
                          } else {
                            await widget.repository.addDebt(
                              DebtsCompanion(
                                personName: drift.Value(name),
                                phoneNumber: drift.Value(phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim()),
                                type: drift.Value(debtType),
                                amount: drift.Value(amount),
                                dueDate: drift.Value(dueDate),
                                notes: drift.Value(notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim()),
                              ),
                            );
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(
                          isEditing ? 'Update Debt Record' : 'Save Debt Record',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // Record Partial or Full Payment Sheet
  // -------------------------------------------------------------
  void _showRecordPaymentSheet(BuildContext context, Debt debt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = (debt.amount - debt.settledAmount).clamp(0.0, double.infinity);
    final amountCtrl = TextEditingController(text: remaining.toStringAsFixed(0));
    final noteCtrl = TextEditingController();
    DateTime paymentDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                    'Record Repayment: ${debt.personName}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining Balance: ${CurrencyFormatter.format(remaining)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: debt.type == 'lent' ? AppColors.income : AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          widthFactor: 0,
                          child: Text(
                            CurrencyFormatter.activeSymbol,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      labelText: 'Repayment Amount',
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date Picker
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: Text('Payment Date: ${DateFormat('dd MMM yyyy').format(paymentDate)}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: paymentDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => paymentDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Payment Note
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Note (Optional, e.g. GPay, Bank transfer, Cash)',
                      prefixIcon: const Icon(Icons.payment_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter an amount greater than 0')),
                          );
                          return;
                        }

                        await widget.repository.recordDebtPayment(
                          debtId: debt.id,
                          amount: amt,
                          paymentDate: paymentDate,
                          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // -------------------------------------------------------------
  // Payment History Sheet
  // -------------------------------------------------------------
  void _showPaymentHistorySheet(BuildContext context, Debt debt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 30),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
                'Payment History: ${debt.personName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Original: ${CurrencyFormatter.format(debt.amount)} • Settled: ${CurrencyFormatter.format(debt.settledAmount)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<DebtPayment>>(
                  stream: widget.repository.watchPaymentsForDebt(debt.id),
                  builder: (ctx, snap) {
                    final payments = snap.data ?? [];
                    if (payments.isEmpty) {
                      return Center(
                        child: Text(
                          'No partial payments recorded yet.',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: payments.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      itemBuilder: (ctx, i) {
                        final p = payments[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.income.withValues(alpha: 0.15),
                            child: const Icon(Icons.check_rounded, color: AppColors.income, size: 20),
                          ),
                          title: Text(
                            CurrencyFormatter.format(p.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${DateFormat('dd MMM yyyy').format(p.paymentDate)}${p.note != null ? ' • ${p.note}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        );
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

  // -------------------------------------------------------------
  // WhatsApp Reminder Sheet
  // -------------------------------------------------------------
  void _showReminderSheet(BuildContext context, Debt debt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = (debt.amount - debt.settledAmount).clamp(0.0, double.infinity);

    final message = debt.type == 'lent'
        ? '''👋 Hi ${debt.personName},

Hope you are doing well!
Just a friendly reminder regarding the pending balance of ${CurrencyFormatter.format(remaining)}${debt.notes != null ? ' (${debt.notes})' : ''}.

💰 Total Debt: ${CurrencyFormatter.format(debt.amount)}
✅ Settled: ${CurrencyFormatter.format(debt.settledAmount)}
⏳ Remaining: ${CurrencyFormatter.format(remaining)}${debt.dueDate != null ? '\n📅 Due Date: ${DateFormat('dd MMM yyyy').format(debt.dueDate!)}' : ''}

Whenever convenient, please settle it. Thank you! 🙏
— SpendWise Finance Tracker'''
        : '''👋 Hi ${debt.personName},

Regarding the ${CurrencyFormatter.format(debt.amount)} I borrowed from you${debt.notes != null ? ' (${debt.notes})' : ''}:

✅ Paid So Far: ${CurrencyFormatter.format(debt.settledAmount)}
⏳ Remaining Balance: ${CurrencyFormatter.format(remaining)}${debt.dueDate != null ? '\n📅 Target Date: ${DateFormat('dd MMM yyyy').format(debt.dueDate!)}' : ''}

I will settle this balance soon. Thank you for your support! 🙏
— SpendWise Finance Tracker''';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_chat_read_rounded, color: Color(0xFF25D366), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'WhatsApp Debt Reminder',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Preview container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    fontFamily: 'monospace',
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Text'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Reminder copied to clipboard!')),
                        );
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Open WhatsApp'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final rawPhone = debt.phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '');
                        if (rawPhone != null && rawPhone.isNotEmpty) {
                          final uri = Uri.parse(
                            'https://wa.me/$rawPhone?text=${Uri.encodeComponent(message)}',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                            return;
                          }
                        }

                        // Fallback to native share
                        SharePlus.instance.share(
                          ShareParams(
                            text: message,
                            subject: 'SpendWise Debt Reminder',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// Interactive Debt Card Component
// -------------------------------------------------------------
class _DebtCard extends StatelessWidget {
  final Debt debt;
  final TransactionRepository repository;
  final VoidCallback onEdit;
  final VoidCallback onRecordPayment;
  final VoidCallback onViewHistory;
  final VoidCallback onSendReminder;

  const _DebtCard({
    required this.debt,
    required this.repository,
    required this.onEdit,
    required this.onRecordPayment,
    required this.onViewHistory,
    required this.onSendReminder,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.map((e) => e[0]).take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLent = debt.type == 'lent';
    final remaining = (debt.amount - debt.settledAmount).clamp(0.0, double.infinity);
    final percent = debt.amount > 0 ? (debt.settledAmount / debt.amount).clamp(0.0, 1.0) : 0.0;

    // Check overdue
    final isOverdue = !debt.isSettled &&
        debt.dueDate != null &&
        DateTime.now().isAfter(debt.dueDate!.add(const Duration(days: 1)));

    return CustomCard(
      padding: const EdgeInsets.all(16),
      borderColor: debt.isSettled
          ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          : (isLent ? AppColors.income : AppColors.expense).withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: (isLent ? AppColors.income : AppColors.expense).withValues(alpha: 0.15),
                child: Text(
                  _getInitials(debt.personName),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isLent ? AppColors.income : AppColors.expense,
                  ),
                ),
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
                            debt.personName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (debt.isSettled) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.income.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SETTLED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.income),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isLent ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isLent ? 'Lent (Receivable)' : 'Borrowed (Payable)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLent ? AppColors.income : AppColors.expense,
                            ),
                          ),
                        ),
                        if (debt.phoneNumber != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            debt.phoneNumber!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) {
                  if (val == 'history') {
                    onViewHistory();
                  } else if (val == 'edit') {
                    onEdit();
                  } else if (val == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Payment History'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit Record'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Amounts & Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL DEBT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(debt.amount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    debt.isSettled ? 'FULLY SETTLED' : 'REMAINING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    debt.isSettled ? CurrencyFormatter.format(debt.amount) : CurrencyFormatter.format(remaining),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: debt.isSettled ? AppColors.income : (isLent ? AppColors.income : AppColors.expense),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                debt.isSettled ? AppColors.income : (isLent ? AppColors.income : AppColors.expense),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: ${CurrencyFormatter.format(debt.settledAmount)} (${(percent * 100).toInt()}%)',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              if (debt.dueDate != null)
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
                      size: 12,
                      color: isOverdue ? AppColors.expense : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? 'Overdue (${DateFormat('dd MMM').format(debt.dueDate!)})'
                          : 'Due: ${DateFormat('dd MMM yyyy').format(debt.dueDate!)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        color: isOverdue ? AppColors.expense : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (debt.notes != null && debt.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              debt.notes!,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons
          if (!debt.isSettled)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    icon: const Icon(Icons.add_card_rounded, size: 16),
                    label: const Text('Add Payment', style: TextStyle(fontSize: 12)),
                    onPressed: onRecordPayment,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: (isLent ? AppColors.income : AppColors.expense).withValues(alpha: 0.18),
                      foregroundColor: isLent ? AppColors.income : AppColors.expense,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Settle Up', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _confirmSettle(context),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'WhatsApp Reminder',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  onPressed: onSendReminder,
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settled on ${DateFormatter.formatDate(debt.settledAt ?? debt.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('View Payments', style: TextStyle(fontSize: 12)),
                  onPressed: onViewHistory,
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _confirmSettle(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle Entire Debt?'),
        content: Text(
          'Mark "${debt.personName}" as fully settled for the remaining ${CurrencyFormatter.format((debt.amount - debt.settledAmount).clamp(0.0, double.infinity))}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.income,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              await repository.markDebtSettled(debt.id);
            },
            child: const Text('Settle Up', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Debt Record?'),
        content: Text('Are you sure you want to delete the debt record for "${debt.personName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await repository.deleteDebt(debt.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
