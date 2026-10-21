import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/transaction_repository.dart';

class BackupInspection {
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final DateTime exportedAt;
  final int version;
  final String app;
  final int totalTransactions;
  final int totalCategories;
  final int totalBudgets;
  final int totalSavingsGoals;
  final int totalDebts;
  final int totalDebtPayments;
  final int totalOccasions;
  final int totalCartItems;
  final Map<String, dynamic> rawPayload;

  const BackupInspection({
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.exportedAt,
    required this.version,
    required this.app,
    required this.totalTransactions,
    required this.totalCategories,
    required this.totalBudgets,
    required this.totalSavingsGoals,
    required this.totalDebts,
    required this.totalDebtPayments,
    required this.totalOccasions,
    required this.totalCartItems,
    required this.rawPayload,
  });
}

class BackupRestoreService {
  static Future<File> createBackupFile(TransactionRepository repository) async {
    final payload = await repository.exportBackupPayload();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'SpendWise_Backup_$timestamp.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonStr);

    return file;
  }

  static Future<void> shareBackupFile(
    BuildContext context,
    TransactionRepository repository,
  ) async {
    final file = await createBackupFile(repository);
    final timestamp = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/json',
            name: file.uri.pathSegments.last,
          ),
        ],
        subject: 'SpendWise Complete Data Backup ($timestamp)',
        text: 'SpendWise encrypted/clean complete JSON database backup generated on $timestamp.',
      ),
    );
  }

  static Future<BackupInspection?> pickAndInspectBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty || result.files.single.path == null) {
      return null;
    }

    final filePath = result.files.single.path!;
    final file = File(filePath);
    final content = await file.readAsString();

    final dynamic decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Selected file is not a valid JSON document.');
    }

    final app = decoded['app'] as String? ?? '';
    final data = decoded['data'] as Map<String, dynamic>?;

    if (app != 'SpendWise' && data == null) {
      throw const FormatException('The file is not a recognized SpendWise backup.');
    }

    final metadata = decoded['metadata'] as Map<String, dynamic>? ?? {};
    final exportedAtStr = decoded['exportedAt'] as String?;
    final exportedAt = exportedAtStr != null
        ? (DateTime.tryParse(exportedAtStr) ?? DateTime.now())
        : DateTime.now();

    final txList = (data?['transactions'] as List?)?.length ??
        (metadata['totalTransactions'] as int? ?? 0);
    final catList = (data?['categories'] as List?)?.length ??
        (metadata['totalCategories'] as int? ?? 0);
    final budgetList = (data?['budgets'] as List?)?.length ??
        (metadata['totalBudgets'] as int? ?? 0);
    final goalList = (data?['savingsGoals'] as List?)?.length ??
        (metadata['totalSavingsGoals'] as int? ?? 0);
    final debtList = (data?['debts'] as List?)?.length ??
        (metadata['totalDebts'] as int? ?? 0);
    final paymentList = (data?['debtPayments'] as List?)?.length ??
        (metadata['totalDebtPayments'] as int? ?? 0);
    final occList = (data?['occasions'] as List?)?.length ??
        (metadata['totalOccasions'] as int? ?? 0);
    final cartList = (data?['cartItems'] as List?)?.length ??
        (metadata['totalCartItems'] as int? ?? 0);

    return BackupInspection(
      fileName: result.files.single.name,
      filePath: filePath,
      fileSizeBytes: await file.length(),
      exportedAt: exportedAt,
      version: decoded['version'] as int? ?? 1,
      app: app.isNotEmpty ? app : 'SpendWise',
      totalTransactions: txList,
      totalCategories: catList,
      totalBudgets: budgetList,
      totalSavingsGoals: goalList,
      totalDebts: debtList,
      totalDebtPayments: paymentList,
      totalOccasions: occList,
      totalCartItems: cartList,
      rawPayload: decoded,
    );
  }

  static Future<void> restore(
    TransactionRepository repository,
    BackupInspection inspection, {
    bool wipeExisting = true,
  }) async {
    await repository.restoreBackupPayload(
      inspection.rawPayload,
      wipeExisting: wipeExisting,
    );
  }
}
