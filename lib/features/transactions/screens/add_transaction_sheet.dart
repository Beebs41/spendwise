import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../categories/category_management_sheet.dart';
import '../widgets/receipt_viewer_dialog.dart';
import '../../../core/services/recurring_transaction_service.dart';
import '../../../core/services/currency_service.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionRepository repository;
  final Transaction? existingTransaction;
  final String initialType;
  final int? initialOccasionId;
  final VoidCallback? onAdded;
  final VoidCallback? onDeleted;

  const AddTransactionSheet({
    super.key,
    required this.repository,
    this.existingTransaction,
    this.initialType = 'expense',
    this.initialOccasionId,
    this.onAdded,
    this.onDeleted,
  });

  static Future<void> show(
    BuildContext context,
    TransactionRepository repository, {
    VoidCallback? onAdded,
    String initialType = 'expense',
    int? initialOccasionId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionSheet(
        repository: repository,
        initialType: initialType,
        initialOccasionId: initialOccasionId,
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
  String? _receiptPath;
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  bool _isSaving = false;

  late String _selectedCurrency;
  late double _exchangeRate;

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
      _selectedCurrency = tx.originalCurrency ?? CurrencyFormatter.activeCode;
      _exchangeRate = tx.exchangeRate ?? CurrencyService.getApproxExchangeRate(_selectedCurrency, CurrencyFormatter.activeCode);
      if (tx.originalAmount != null && tx.originalCurrency != null && tx.originalCurrency != CurrencyFormatter.activeCode) {
        _amountController.text = tx.originalAmount! % 1 == 0
            ? tx.originalAmount!.toInt().toString()
            : tx.originalAmount!.toStringAsFixed(2);
      } else {
        _amountController.text = tx.amount % 1 == 0 ? tx.amount.toInt().toString() : tx.amount.toStringAsFixed(2);
      }
      _selectedDate = tx.date;
      _selectedCategoryId = tx.categoryId;
      _selectedOccasionId = tx.occasionId;
      _receiptPath = tx.receiptPath;
      _isRecurring = tx.isRecurring;
      _noteController.text = tx.note ?? '';
    } else {
      _type = widget.initialType;
      _selectedDate = DateTime.now();
      _selectedOccasionId = widget.initialOccasionId;
      _selectedCurrency = CurrencyFormatter.activeCode;
      _exchangeRate = 1.0;
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
        if (_selectedOccasionId != null && _selectedCurrency == CurrencyFormatter.activeCode) {
          final matchedOcc = _occasions.where((o) => o.id == _selectedOccasionId).firstOrNull;
          if (matchedOcc != null && matchedOcc.currencyCode != null && matchedOcc.currencyCode!.isNotEmpty) {
            _selectedCurrency = matchedOcc.currencyCode!;
            _exchangeRate = CurrencyService.getApproxExchangeRate(_selectedCurrency, CurrencyFormatter.activeCode);
          }
        }
      });
    }
  }

  void _showCurrencyPicker() {
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
                      'Select Transaction Currency',
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
                    final isSelected = curr.code == _selectedCurrency;
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
                        setState(() {
                          _selectedCurrency = curr.code;
                          _exchangeRate = CurrencyService.getApproxExchangeRate(
                            _selectedCurrency,
                            CurrencyFormatter.activeCode,
                          );
                        });
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

  void _showAdjustRateDialog() {
    final rateCtrl = TextEditingController(
      text: _exchangeRate % 1 == 0 ? _exchangeRate.toInt().toString() : _exchangeRate.toStringAsFixed(4),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Adjust Exchange Rate',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1 $_selectedCurrency = X ${CurrencyFormatter.activeCode} (${CurrencyFormatter.activeSymbol})',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Exchange Rate',
                hintText: 'e.g. 84.25',
                prefixIcon: const Icon(Icons.currency_exchange_rounded),
                suffixText: CurrencyFormatter.activeCode,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customize the exact rate used for this transaction if your bank or card applied a specific conversion rate.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final defaultRate = CurrencyService.getApproxExchangeRate(
                _selectedCurrency,
                CurrencyFormatter.activeCode,
              );
              rateCtrl.text = defaultRate % 1 == 0 ? defaultRate.toInt().toString() : defaultRate.toStringAsFixed(4);
            },
            child: const Text('Reset Default'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newRate = double.tryParse(rateCtrl.text.trim());
              if (newRate != null && newRate > 0) {
                HapticFeedback.selectionClick();
                setState(() => _exchangeRate = newRate);
                Navigator.pop(dialogCtx);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
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
    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and category')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final isForeign = _selectedCurrency != CurrencyFormatter.activeCode;
    final baseAmount = isForeign ? enteredAmount * _exchangeRate : enteredAmount;
    final origAmount = isForeign ? enteredAmount : null;
    final origCurr = isForeign ? _selectedCurrency : null;
    final rate = isForeign ? _exchangeRate : null;

    String? note = _noteController.text.trim();
    if (_isOtherCategorySelected() && _otherSpecificController.text.trim().isNotEmpty) {
      final specific = _otherSpecificController.text.trim();
      note = note.isEmpty ? specific : '$specific • $note';
    }

    if (_isEditing) {
      await widget.repository.updateTransaction(
        id: widget.existingTransaction!.id,
        type: _type,
        amount: baseAmount,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        isRecurring: _isRecurring,
        occasionId: _type == 'expense' ? _selectedOccasionId : null,
        receiptPath: _receiptPath,
        originalAmount: origAmount,
        originalCurrency: origCurr,
        exchangeRate: rate,
      );
    } else {
      await widget.repository.addTransaction(
        type: _type,
        amount: baseAmount,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        isRecurring: _isRecurring,
        occasionId: _type == 'expense' ? _selectedOccasionId : null,
        receiptPath: _receiptPath,
        originalAmount: origAmount,
        originalCurrency: origCurr,
        exchangeRate: rate,
      );

      if (_isRecurring) {
        final nextDue = RecurringTransactionService.calculateNextDueDate(_selectedDate, _recurringFrequency);
        await widget.repository.addRecurringTransaction(
          type: _type,
          amount: baseAmount,
          categoryId: _selectedCategoryId!,
          frequency: _recurringFrequency,
          startDate: _selectedDate,
          nextDueDate: nextDue,
          lastGeneratedDate: _selectedDate,
          note: note.isEmpty ? null : note,
          occasionId: _type == 'expense' ? _selectedOccasionId : null,
          receiptPath: _receiptPath,
        );
      }
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

  Future<void> _pickReceipt(ImageSource source) async {
    HapticFeedback.selectionClick();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }
      final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
      final uniqueName = 'receipt_${DateTime.now().millisecondsSinceEpoch}$ext';
      final savedFile = await File(picked.path).copy(p.join(receiptsDir.path, uniqueName));

      setState(() {
        _receiptPath = savedFile.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach receipt: $e')),
        );
      }
    }
  }

  void _removeReceipt() {
    HapticFeedback.lightImpact();
    setState(() {
      _receiptPath = null;
    });
  }

  Widget _buildReceiptAttachmentSection(bool isDark) {
    final hasReceipt = _receiptPath != null && _receiptPath!.isNotEmpty;
    final file = hasReceipt ? File(_receiptPath!) : null;
    final fileExists = file?.existsSync() ?? false;

    if (!hasReceipt || !fileExists) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Receipt / Bill',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Attach photo for records',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Camera Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _pickReceipt(ImageSource.camera),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Camera',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Gallery Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _pickReceipt(ImageSource.gallery),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 16,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Gallery',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail Preview
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ReceiptViewerDialog.show(
                context,
                imagePath: _receiptPath!,
                title: 'Attached Receipt',
                subtitle: _noteController.text.isNotEmpty ? _noteController.text : null,
              );
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    file!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: GestureDetector(
              onTap: () {
                ReceiptViewerDialog.show(
                  context,
                  imagePath: _receiptPath!,
                  title: 'Attached Receipt',
                  subtitle: _noteController.text.isNotEmpty ? _noteController.text : null,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Receipt Attached',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to view in full screen',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Options popup
          PopupMenuButton<ImageSource>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            tooltip: 'Receipt Options',
            color: isDark ? AppColors.darkSurface : AppColors.lightCard,
            onSelected: _pickReceipt,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: ImageSource.camera,
                child: Row(
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Retake with Camera', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ImageSource.gallery,
                child: Row(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Choose from Gallery', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.darkDanger,
            ),
            tooltip: 'Remove Receipt',
            onPressed: _removeReceipt,
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.autorenew_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recurring Transaction',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isRecurring
                          ? 'Repeats ${RecurringTransactionService.formatFrequency(_recurringFrequency).toLowerCase()}'
                          : 'Auto-generate on schedule',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _isRecurring = val);
                },
                activeThumbColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 10),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildFrequencyChip('daily', 'Daily', isDark),
                const SizedBox(width: 8),
                _buildFrequencyChip('weekly', 'Weekly', isDark),
                const SizedBox(width: 8),
                _buildFrequencyChip('monthly', 'Monthly', isDark),
                const SizedBox(width: 8),
                _buildFrequencyChip('yearly', 'Yearly', isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequencyChip(String value, String label, bool isDark) {
    final isSelected = _recurringFrequency == value;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _recurringFrequency = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.black
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightCard;
    final filteredCategories = _categories.where((c) => c.isIncome == (_type == 'income')).toList();
    final currInfo = CurrencyService.getByCodeOrDefault(_selectedCurrency, defaultCode: CurrencyFormatter.activeCode);
    final curSymbol = currInfo.symbol;
    final isForeign = _selectedCurrency != CurrencyFormatter.activeCode;
    final enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    final convertedBaseAmount = enteredAmount * _exchangeRate;

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
              const SizedBox(height: 18),

              // Currency Pill & Large Amount Input
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Currency Selection Pill
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showCurrencyPicker();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isForeign
                              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.18)
                              : (isDark ? AppColors.darkCard : AppColors.lightSurface),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isForeign
                                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isForeign ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currInfo.flagEmoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              '${currInfo.code} (${currInfo.symbol})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isForeign
                                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: isForeign
                                  ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
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
                    if (isForeign) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _showAdjustRateDialog();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '≈ ${CurrencyFormatter.format(convertedBaseAmount)} (1 $_selectedCurrency = ${CurrencyFormatter.activeSymbol}${_exchangeRate.toStringAsFixed(2)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.edit_outlined,
                                size: 13,
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                        setState(() {
                          _selectedOccasionId = val;
                          if (val != null) {
                            final occ = _occasions.where((o) => o.id == val).firstOrNull;
                            if (occ != null && occ.currencyCode != null && occ.currencyCode!.isNotEmpty && _selectedCurrency == CurrencyFormatter.activeCode) {
                              _selectedCurrency = occ.currencyCode!;
                              _exchangeRate = CurrencyService.getApproxExchangeRate(_selectedCurrency, CurrencyFormatter.activeCode);
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],

              // Receipt Photo / Attachment
              const SizedBox(height: 12),
              _buildReceiptAttachmentSection(isDark),

              // Recurring Transaction Section
              const SizedBox(height: 12),
              _buildRecurringSection(isDark),
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
