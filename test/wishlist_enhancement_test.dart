import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/database/app_database.dart';
import 'package:spendwise/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repository;
  late int shoppingCategoryId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);

    shoppingCategoryId = await db.insertCategory(
      CategoriesCompanion.insert(
        name: 'Shopping',
        icon: '🛍️',
        color: 0xFFFF8A5C,
        isIncome: const Value(false),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Add wishlist item with linked savings goal', () async {
    final goalId = await repository.addSavingsGoal(
      title: 'Sony Headphones Goal',
      targetAmount: 25000,
      currentAmount: 5000,
      color: 0xFF4ECDC4,
      icon: '🎧',
    );

    final itemId = await repository.addCartItem(
      name: 'Sony WH-1000XM5',
      price: 24999,
      savedAmount: 5000,
      priority: 'high',
      note: 'Wait for Black Friday deal',
      savingsGoalId: goalId,
    );

    final itemsWithGoal = await repository.getAllCartItemsWithGoal();
    expect(itemsWithGoal.length, equals(1));

    final itemWithGoal = itemsWithGoal.first;
    expect(itemWithGoal.cartItem.id, equals(itemId));
    expect(itemWithGoal.cartItem.name, equals('Sony WH-1000XM5'));
    expect(itemWithGoal.cartItem.price, equals(24999.0));
    expect(itemWithGoal.cartItem.priority, equals('high'));
    expect(itemWithGoal.cartItem.isPurchased, isFalse);
    expect(itemWithGoal.cartItem.savingsGoalId, equals(goalId));
    expect(itemWithGoal.savingsGoal, isNotNull);
    expect(itemWithGoal.savingsGoal!.title, equals('Sony Headphones Goal'));
  });

  test('Deposit to wishlist item syncs linked savings goal', () async {
    final goalId = await repository.addSavingsGoal(
      title: 'iPad Air Goal',
      targetAmount: 55000,
      currentAmount: 10000,
      color: 0xFF6366F1,
      icon: '📱',
    );

    final itemId = await repository.addCartItem(
      name: 'iPad Air M2',
      price: 54900,
      savedAmount: 10000,
      savingsGoalId: goalId,
    );

    // Deposit an additional 15,000 (total saved = 25,000)
    await repository.depositToCartItem(
      cartItemId: itemId,
      newSavedAmount: 25000,
      syncLinkedGoal: true,
    );

    // Verify cart item was updated
    final items = await repository.getAllCartItemsWithGoal();
    expect(items.first.cartItem.savedAmount, equals(25000.0));

    // Verify savings goal was synced by +15,000 (10,000 + 15,000 = 25,000)
    final goals = await repository.getAllSavingsGoals();
    final updatedGoal = goals.firstWhere((g) => g.id == goalId);
    expect(updatedGoal.currentAmount, equals(25000.0));
  });

  test('Mark cart item as purchased auto-converts to expense transaction', () async {
    final itemId = await repository.addCartItem(
      name: 'Ergonomic Desk Chair',
      price: 12000,
      savedAmount: 12000,
      priority: 'medium',
    );

    final purchaseDate = DateTime(2026, 10, 20);
    final txId = await repository.markCartItemPurchased(
      cartItemId: itemId,
      recordAsTransaction: true,
      actualPrice: 11500, // bought with discount
      categoryId: shoppingCategoryId,
      date: purchaseDate,
      note: 'Bought during festival sale',
    );

    expect(txId, isNotNull);

    // Verify cart item is now purchased
    final items = await repository.getAllCartItemsWithGoal();
    final item = items.first.cartItem;
    expect(item.isPurchased, isTrue);
    expect(item.price, equals(11500.0));
    expect(item.savedAmount, equals(11500.0));

    // Verify transaction was created
    final transactions = await repository.getAllTransactions();
    expect(transactions.length, equals(1));

    final tx = transactions.first;
    expect(tx.transaction.id, equals(txId));
    expect(tx.transaction.amount, equals(11500.0));
    expect(tx.transaction.type, equals('expense'));
    expect(tx.transaction.categoryId, equals(shoppingCategoryId));
    expect(tx.transaction.date, equals(purchaseDate));
    expect(tx.transaction.note, equals('Bought during festival sale'));
  });

  test('Mark cart item as purchased without creating transaction', () async {
    final itemId = await repository.addCartItem(
      name: 'Mechanical Keyboard',
      price: 6500,
      savedAmount: 6500,
    );

    final txId = await repository.markCartItemPurchased(
      cartItemId: itemId,
      recordAsTransaction: false,
    );

    expect(txId, isNull);

    final items = await repository.getAllCartItemsWithGoal();
    expect(items.first.cartItem.isPurchased, isTrue);

    final transactions = await repository.getAllTransactions();
    expect(transactions.isEmpty, isTrue);
  });

  test('Mark cart item as purchased and complete linked savings goal', () async {
    final goalId = await repository.addSavingsGoal(
      title: 'Watch Fund',
      targetAmount: 8000,
      currentAmount: 6000,
      color: 0xFFF5A623,
    );

    final itemId = await repository.addCartItem(
      name: 'Casio G-Shock',
      price: 7995,
      savedAmount: 6000,
      savingsGoalId: goalId,
    );

    await repository.markCartItemPurchased(
      cartItemId: itemId,
      recordAsTransaction: true,
      actualPrice: 7995,
      categoryId: shoppingCategoryId,
      markGoalCompleted: true,
    );

    // Verify savings goal is marked 100% completed
    final goals = await repository.getAllSavingsGoals();
    final updatedGoal = goals.firstWhere((g) => g.id == goalId);
    expect(updatedGoal.currentAmount, equals(updatedGoal.targetAmount));
  });

  test('Unmark purchased cart item', () async {
    final itemId = await repository.addCartItem(
      name: 'Coffee Grinder',
      price: 3500,
    );

    await repository.markCartItemPurchased(
      cartItemId: itemId,
      recordAsTransaction: false,
    );

    var items = await repository.getAllCartItemsWithGoal();
    expect(items.first.cartItem.isPurchased, isTrue);

    await repository.unmarkCartItemPurchased(itemId);

    items = await repository.getAllCartItemsWithGoal();
    expect(items.first.cartItem.isPurchased, isFalse);
  });

  test('Backup export and restore preserves wishlist savingsGoalId and isPurchased', () async {
    final goalId = await repository.addSavingsGoal(
      title: 'Espresso Machine',
      targetAmount: 40000,
      currentAmount: 40000,
      color: 0xFF2ECC71,
    );

    await repository.addCartItem(
      name: 'Breville Barista Touch',
      price: 38000,
      savedAmount: 38000,
      priority: 'high',
      note: 'Stainless steel edition',
      savingsGoalId: goalId,
    );

    final backupPayload = await repository.exportBackupPayload();
    final data = backupPayload['data'] as Map<String, dynamic>;
    final cartList = data['cartItems'] as List;

    expect(cartList.length, equals(1));
    final exportedItem = cartList.first as Map<String, dynamic>;
    expect(exportedItem['name'], equals('Breville Barista Touch'));
    expect(exportedItem['savingsGoalId'], equals(goalId));
    expect(exportedItem['priority'], equals('high'));

    // Create fresh database and restore
    final newDb = AppDatabase(NativeDatabase.memory());
    final newRepo = TransactionRepository(newDb);

    await newRepo.restoreBackupPayload(
      backupPayload,
      wipeExisting: true,
    );

    final restoredItems = await newRepo.getAllCartItemsWithGoal();
    expect(restoredItems.length, equals(1));
    expect(restoredItems.first.cartItem.name, equals('Breville Barista Touch'));
    expect(restoredItems.first.cartItem.savingsGoalId, equals(goalId));
    expect(restoredItems.first.savingsGoal, isNotNull);
    expect(restoredItems.first.savingsGoal!.title, equals('Espresso Machine'));

    await newDb.close();
  });
}
