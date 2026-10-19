import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()(); // Emoji or icon name
  IntColumn get color => integer()(); // 0xAARRGGBB hex value
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

class Occasions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().withDefault(const Constant('🏖️'))(); // Emoji
  RealColumn get budget => real().withDefault(const Constant(0.0))(); // Trip budget limit
  TextColumn get description => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'expense' or 'income'
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  IntColumn get occasionId => integer().nullable().references(Occasions, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get amount => real()();
  IntColumn get month => integer()(); // 1 to 12
  IntColumn get year => integer()();
}

class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  TextColumn get icon => text().withDefault(const Constant('🎯'))();
  IntColumn get color => integer()();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CartItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get price => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0.0))();
  TextColumn get priority => text().withDefault(const Constant('medium'))(); // 'low', 'medium', 'high'
  BoolColumn get isPurchased => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userName => text().withDefault(const Constant(''))();
  TextColumn get profileImagePath => text().nullable()();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  TextColumn get currencySymbol => text().withDefault(const Constant('₹'))();
  BoolColumn get isLockEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get passcode => text().nullable()(); // 4-digit PIN
  BoolColumn get useBiometrics => boolean().withDefault(const Constant(false))();
  BoolColumn get isOnboarded => boolean().withDefault(const Constant(false))();
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get personName => text().withLength(min: 1, max: 100)();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get type => text()(); // 'lent' (receivable) or 'borrowed' (payable)
  RealColumn get amount => real()();
  RealColumn get settledAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get settledAt => dateTime().nullable()();
}

class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId => integer().references(Debts, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
}
