import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../models/transaction_filter.dart';

class TransactionState extends Equatable {
  final List<TransactionWithCategory> allTransactions;
  final List<TransactionWithCategory> filteredTransactions;
  final List<Category> allCategories;
  final Map<int, Occasion> occasionsMap;
  final int selectedYear;
  final int selectedMonth;
  final TransactionFilter filter;
  final bool isLoading;

  const TransactionState({
    this.allTransactions = const [],
    this.filteredTransactions = const [],
    this.allCategories = const [],
    this.occasionsMap = const {},
    required this.selectedYear,
    required this.selectedMonth,
    this.filter = const TransactionFilter(),
    this.isLoading = false,
  });

  // Backward compatibility getters
  DateTime? get selectedDate => filter.specificDate;
  String get filterType => filter.type;
  String get searchQuery => filter.searchQuery;

  double get totalIncome {
    return filteredTransactions
        .where((t) => t.transaction.type == 'income')
        .fold(0.0, (sum, t) => sum + t.transaction.amount);
  }

  double get totalExpense {
    return filteredTransactions
        .where((t) => t.transaction.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.transaction.amount);
  }

  double get netBalance => totalIncome - totalExpense;

  TransactionState copyWith({
    List<TransactionWithCategory>? allTransactions,
    List<TransactionWithCategory>? filteredTransactions,
    List<Category>? allCategories,
    Map<int, Occasion>? occasionsMap,
    int? selectedYear,
    int? selectedMonth,
    TransactionFilter? filter,
    bool? isLoading,
  }) {
    return TransactionState(
      allTransactions: allTransactions ?? this.allTransactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      allCategories: allCategories ?? this.allCategories,
      occasionsMap: occasionsMap ?? this.occasionsMap,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        allTransactions,
        filteredTransactions,
        allCategories,
        occasionsMap,
        selectedYear,
        selectedMonth,
        filter,
        isLoading,
      ];
}

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;
  StreamSubscription? _txSubscription;
  StreamSubscription? _catSubscription;
  StreamSubscription? _occSubscription;

  TransactionCubit(this._repository)
      : super(TransactionState(
          selectedYear: DateTime.now().year,
          selectedMonth: DateTime.now().month,
        )) {
    _initStreams();
  }

  void _initStreams() {
    // Watch categories for instant filtering options
    _catSubscription = _repository.watchCategories().listen((categories) {
      emit(state.copyWith(allCategories: categories));
    });

    // Watch occasions for trip/occasion tags and search matching
    _occSubscription = _repository.watchAllOccasions().listen((occasions) {
      final occMap = {for (final o in occasions) o.id: o};
      emit(state.copyWith(occasionsMap: occMap));
    });

    _loadTransactions();
  }

  bool get _shouldWatchAllTransactions =>
      state.filter.datePreset != DateFilterPreset.month ||
      state.filter.searchAllTime ||
      state.filter.customStartDate != null;

  void _loadTransactions() {
    _txSubscription?.cancel();
    emit(state.copyWith(isLoading: true));

    final stream = _shouldWatchAllTransactions
        ? _repository.watchAllTransactions()
        : _repository.watchTransactionsForMonth(state.selectedYear, state.selectedMonth);

    _txSubscription = stream.listen((transactions) {
      final filtered = _applyFilter(transactions, state.filter, state.occasionsMap);
      emit(state.copyWith(
        allTransactions: transactions,
        filteredTransactions: filtered,
        isLoading: false,
      ));
    });
  }

  List<TransactionWithCategory> _applyFilter(
    List<TransactionWithCategory> list,
    TransactionFilter filter,
    Map<int, Occasion> occasions,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = list.where((item) {
      final tx = item.transaction;

      // 1. Transaction Type (Expense vs Income vs All)
      if (filter.type != 'all' && tx.type != filter.type) {
        return false;
      }

      // 2. Date Filtering
      if (filter.specificDate != null) {
        if (tx.date.year != filter.specificDate!.year ||
            tx.date.month != filter.specificDate!.month ||
            tx.date.day != filter.specificDate!.day) {
          return false;
        }
      } else {
        switch (filter.datePreset) {
          case DateFilterPreset.month:
            if (!filter.searchAllTime) {
              if (tx.date.year != state.selectedYear || tx.date.month != state.selectedMonth) {
                return false;
              }
            }
            break;
          case DateFilterPreset.today:
            if (tx.date.year != today.year ||
                tx.date.month != today.month ||
                tx.date.day != today.day) {
              return false;
            }
            break;
          case DateFilterPreset.thisWeek:
            final monday = today.subtract(Duration(days: today.weekday - 1));
            final sundayEnd = monday.add(const Duration(days: 7));
            if (tx.date.isBefore(monday) || tx.date.isAfter(sundayEnd)) {
              return false;
            }
            break;
          case DateFilterPreset.last30Days:
            final thirtyDaysAgo = today.subtract(const Duration(days: 30));
            final tomorrow = today.add(const Duration(days: 1));
            if (tx.date.isBefore(thirtyDaysAgo) || tx.date.isAfter(tomorrow)) {
              return false;
            }
            break;
          case DateFilterPreset.thisYear:
            if (tx.date.year != now.year) {
              return false;
            }
            break;
          case DateFilterPreset.custom:
            if (filter.customStartDate != null) {
              final startOfDay = DateTime(
                filter.customStartDate!.year,
                filter.customStartDate!.month,
                filter.customStartDate!.day,
              );
              if (tx.date.isBefore(startOfDay)) return false;
            }
            if (filter.customEndDate != null) {
              final endOfDay = DateTime(
                filter.customEndDate!.year,
                filter.customEndDate!.month,
                filter.customEndDate!.day,
                23, 59, 59, 999,
              );
              if (tx.date.isAfter(endOfDay)) return false;
            }
            break;
          case DateFilterPreset.allTime:
            break;
        }
      }

      // 3. Category Filter (multi-select)
      if (filter.categoryIds.isNotEmpty && !filter.categoryIds.contains(item.category.id)) {
        return false;
      }

      // 4. Occasion Filter
      if (filter.occasionId != null) {
        if (filter.occasionId == -1) {
          if (tx.occasionId != null) return false;
        } else {
          if (tx.occasionId != filter.occasionId) return false;
        }
      }

      // 5. Amount Range
      if (filter.minAmount != null && tx.amount < filter.minAmount!) {
        return false;
      }
      if (filter.maxAmount != null && tx.amount > filter.maxAmount!) {
        return false;
      }

      // 6. Search Query (note, category, amount, occasion)
      if (filter.searchQuery.trim().isNotEmpty) {
        final q = filter.searchQuery.trim().toLowerCase();
        final matchesCat = item.category.name.toLowerCase().contains(q);
        final matchesNote = tx.note != null && tx.note!.toLowerCase().contains(q);
        final matchesAmount = tx.amount.toString().contains(q) ||
            tx.amount.toStringAsFixed(0).contains(q);
        final matchesOccasion = tx.occasionId != null &&
            (occasions[tx.occasionId]?.name.toLowerCase().contains(q) ?? false);

        if (!matchesCat && !matchesNote && !matchesAmount && !matchesOccasion) {
          return false;
        }
      }

      return true;
    }).toList();

    // 7. Sort Order
    switch (filter.sortBy) {
      case SortOption.dateDesc:
        filtered.sort((a, b) {
          final cmp = b.transaction.date.compareTo(a.transaction.date);
          return cmp != 0 ? cmp : b.transaction.id.compareTo(a.transaction.id);
        });
        break;
      case SortOption.dateAsc:
        filtered.sort((a, b) {
          final cmp = a.transaction.date.compareTo(b.transaction.date);
          return cmp != 0 ? cmp : a.transaction.id.compareTo(b.transaction.id);
        });
        break;
      case SortOption.amountDesc:
        filtered.sort((a, b) {
          final cmp = b.transaction.amount.compareTo(a.transaction.amount);
          return cmp != 0 ? cmp : b.transaction.date.compareTo(a.transaction.date);
        });
        break;
      case SortOption.amountAsc:
        filtered.sort((a, b) {
          final cmp = a.transaction.amount.compareTo(b.transaction.amount);
          return cmp != 0 ? cmp : a.transaction.date.compareTo(b.transaction.date);
        });
        break;
    }

    return filtered;
  }

  void setFilter(TransactionFilter newFilter) {
    final wasWatchingAll = _shouldWatchAllTransactions;
    emit(state.copyWith(filter: newFilter));

    if (wasWatchingAll != _shouldWatchAllTransactions) {
      _loadTransactions();
    } else {
      final filtered = _applyFilter(state.allTransactions, newFilter, state.occasionsMap);
      emit(state.copyWith(filteredTransactions: filtered));
    }
  }

  void setFilterType(String type) {
    setFilter(state.filter.copyWith(type: type));
  }

  void setSearchQuery(String query) {
    setFilter(state.filter.copyWith(searchQuery: query));
  }

  void toggleSearchAllTime() {
    setFilter(state.filter.copyWith(searchAllTime: !state.filter.searchAllTime));
  }

  void setDateFilter(DateTime? date) {
    if (date == null) {
      clearDateFilter();
      return;
    }

    if (date.year != state.selectedYear || date.month != state.selectedMonth) {
      emit(state.copyWith(
        selectedYear: date.year,
        selectedMonth: date.month,
        filter: state.filter.copyWith(
          datePreset: DateFilterPreset.month,
          specificDate: date,
        ),
      ));
      _loadTransactions();
    } else {
      setFilter(state.filter.copyWith(
        datePreset: DateFilterPreset.month,
        specificDate: date,
      ));
    }
  }

  void clearDateFilter() {
    setFilter(state.filter.copyWith(
      clearSpecificDate: true,
      clearCustomDates: true,
      datePreset: DateFilterPreset.month,
    ));
  }

  void removeCategoryFilter(int categoryId) {
    final next = Set<int>.from(state.filter.categoryIds)..remove(categoryId);
    setFilter(state.filter.copyWith(categoryIds: next));
  }

  void clearOccasionFilter() {
    setFilter(state.filter.copyWith(clearOccasionId: true));
  }

  void clearAmountFilter() {
    setFilter(state.filter.copyWith(clearAmountRange: true));
  }

  void resetFilter() {
    setFilter(const TransactionFilter());
  }

  void changeMonth(int delta) {
    var newMonth = state.selectedMonth + delta;
    var newYear = state.selectedYear;

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }

    emit(state.copyWith(
      selectedMonth: newMonth,
      selectedYear: newYear,
      filter: state.filter.copyWith(
        clearSpecificDate: true,
        datePreset: DateFilterPreset.month,
      ),
    ));
    _loadTransactions();
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required DateTime date,
    String? note,
    bool isRecurring = false,
    int? occasionId,
    String? receiptPath,
  }) async {
    await _repository.addTransaction(
      type: type,
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
      isRecurring: isRecurring,
      occasionId: occasionId,
      receiptPath: receiptPath,
    );
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
  }

  @override
  Future<void> close() {
    _txSubscription?.cancel();
    _catSubscription?.cancel();
    _occSubscription?.cancel();
    return super.close();
  }
}
