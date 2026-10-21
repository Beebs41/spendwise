import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/core/services/currency_service.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';

void main() {
  group('CurrencyService', () {
    test('provides comprehensive list of supported world currencies', () {
      final currencies = CurrencyService.supportedCurrencies;
      expect(currencies.isNotEmpty, isTrue);

      final inr = CurrencyService.findByCode('INR');
      expect(inr, isNotNull);
      expect(inr!.symbol, '₹');
      expect(inr.flagEmoji, '🇮🇳');

      final usd = CurrencyService.findByCode('USD');
      expect(usd, isNotNull);
      expect(usd!.symbol, '\$');
      expect(usd.flagEmoji, '🇺🇸');

      final aed = CurrencyService.findByCode('AED');
      expect(aed, isNotNull);
      expect(aed!.flagEmoji, '🇦🇪');

      final eur = CurrencyService.findByCode('EUR');
      expect(eur, isNotNull);
      expect(eur!.symbol, '€');
    });

    test('getByCodeOrDefault falls back gracefully on unknown currency code', () {
      final fallback = CurrencyService.getByCodeOrDefault('XYZ');
      expect(fallback.code, 'INR');

      final known = CurrencyService.getByCodeOrDefault('USD');
      expect(known.code, 'USD');
    });

    test('calculates approximate exchange rates correctly', () {
      // 1 USD in INR should be approximately 84
      final usdToInr = CurrencyService.getApproxExchangeRate('USD', 'INR');
      expect(usdToInr, closeTo(84.0, 5.0));

      // Same currency rate should be exactly 1.0
      final inrToInr = CurrencyService.getApproxExchangeRate('INR', 'INR');
      expect(inrToInr, 1.0);

      // 100 USD converted to INR
      final inrAmount = CurrencyService.convert(100, fromCode: 'USD', toCode: 'INR');
      expect(inrAmount, closeTo(8400.0, 500.0));
    });

    test('formats currency amounts accurately', () {
      final formattedUsd = CurrencyService.formatAmount(1234.56, 'USD');
      expect(formattedUsd, contains('\$'));
      expect(formattedUsd, contains('1,234.56'));
    });
  });

  group('Multi-Currency Database & Repository Integration', () {
    late AppDatabase db;
    late TransactionRepository repository;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = TransactionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('creates and retrieves occasion with custom trip currency', () async {
      final occasionId = await repository.addOccasion(
        name: 'Dubai Shopping Trip',
        icon: '✈️',
        budget: 50000,
        currencyCode: 'AED',
        description: 'Annual shopping festival',
      );

      final occasions = await repository.getAllOccasions();
      expect(occasions.length, 1);
      final trip = occasions.first;
      expect(trip.id, occasionId);
      expect(trip.name, 'Dubai Shopping Trip');
      expect(trip.currencyCode, 'AED');
    });

    test('stores foreign currency and base currency amounts for transactions', () async {
      final catId = await db.insertCategory(
        CategoriesCompanion.insert(
          name: 'Travel & Dining',
          icon: '✈️',
          color: 0xFF3498DB,
        ),
      );

      final occasionId = await repository.addOccasion(
        name: 'Dubai Trip',
        icon: '🏙️',
        budget: 100000,
        currencyCode: 'AED',
      );

      // Suppose user spent 250 AED at a restaurant.
      // Exchange rate: 1 AED = 23.0 INR.
      // Base amount in INR = 250 * 23.0 = 5750.0 INR.
      final txId = await repository.addTransaction(
        type: 'expense',
        amount: 5750.0,
        categoryId: catId,
        date: DateTime(2026, 10, 20),
        note: 'Dinner at Burj Khalifa lounge',
        occasionId: occasionId,
        originalAmount: 250.0,
        originalCurrency: 'AED',
        exchangeRate: 23.0,
      );

      final transactions = await repository.getAllTransactions();
      expect(transactions.length, 1);
      final tx = transactions.first.transaction;
      expect(tx.id, txId);
      expect(tx.amount, 5750.0); // Base currency for financial reporting
      expect(tx.originalAmount, 250.0);
      expect(tx.originalCurrency, 'AED');
      expect(tx.exchangeRate, 23.0);
      expect(tx.occasionId, occasionId);

      // Verify occasion expense aggregation uses base amount
      final occasionTxs = await repository.getTransactionsForOccasion(occasionId);
      expect(occasionTxs.length, 1);
      final totalSpent = occasionTxs.fold(0.0, (sum, t) => sum + t.transaction.amount);
      expect(totalSpent, 5750.0);
    });

    test('updates multi-currency fields on existing transactions', () async {
      final catId = await db.insertCategory(
        CategoriesCompanion.insert(
          name: 'Shopping',
          icon: '🛍️',
          color: 0xFF9B59B6,
        ),
      );

      final txId = await repository.addTransaction(
        type: 'expense',
        amount: 8400.0,
        categoryId: catId,
        date: DateTime(2026, 10, 20),
        note: 'Online gadget purchase',
        originalAmount: 100.0,
        originalCurrency: 'USD',
        exchangeRate: 84.0,
      );

      // Update rate and foreign amount
      final updated = await repository.updateTransaction(
        id: txId,
        type: 'expense',
        amount: 8500.0,
        categoryId: catId,
        date: DateTime(2026, 10, 20),
        note: 'Online gadget purchase (revised rate)',
        originalAmount: 100.0,
        originalCurrency: 'USD',
        exchangeRate: 85.0,
      );

      expect(updated, isTrue);

      final transactions = await repository.getAllTransactions();
      final tx = transactions.first.transaction;
      expect(tx.amount, 8500.0);
      expect(tx.originalAmount, 100.0);
      expect(tx.exchangeRate, 85.0);
    });

    test('exports and restores multi-currency data in backup payload', () async {
      final catId = await db.insertCategory(
        CategoriesCompanion.insert(
          name: 'Sightseeing',
          icon: '🏛️',
          color: 0xFFE67E22,
        ),
      );

      final occasionId = await repository.addOccasion(
        name: 'Paris Vacation',
        icon: '🗼',
        budget: 150000,
        currencyCode: 'EUR',
      );

      await repository.addTransaction(
        type: 'expense',
        amount: 9200.0,
        categoryId: catId,
        date: DateTime(2026, 10, 18),
        note: 'Louvre tickets & guide',
        occasionId: occasionId,
        originalAmount: 100.0,
        originalCurrency: 'EUR',
        exchangeRate: 92.0,
      );

      // Export backup payload
      final payload = await db.exportBackupPayload();
      final data = payload['data'] as Map<String, dynamic>;
      expect(data['occasions'], isNotEmpty);
      expect(data['occasions'].first['currencyCode'], 'EUR');
      expect(data['transactions'], isNotEmpty);
      expect(data['transactions'].first['originalAmount'], 100.0);
      expect(data['transactions'].first['originalCurrency'], 'EUR');
      expect(data['transactions'].first['exchangeRate'], 92.0);

      // Create a fresh clean database and restore
      final newDb = AppDatabase(NativeDatabase.memory());
      final newRepo = TransactionRepository(newDb);

      await newDb.restoreBackupPayload(payload);

      final restoredOccasions = await newRepo.getAllOccasions();
      expect(restoredOccasions.length, 1);
      expect(restoredOccasions.first.currencyCode, 'EUR');

      final restoredTxs = await newRepo.getAllTransactions();
      expect(restoredTxs.length, 1);
      final restoredTx = restoredTxs.first.transaction;
      expect(restoredTx.amount, 9200.0);
      expect(restoredTx.originalAmount, 100.0);
      expect(restoredTx.originalCurrency, 'EUR');
      expect(restoredTx.exchangeRate, 92.0);

      await newDb.close();
    });
  });
}
