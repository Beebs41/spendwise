import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';

class TransactionState extends Equatable {
  final List<TransactionWithCategory> allTransactions;
  final List<TransactionWithCategory> filteredTransactions;
  final int selectedYear;
  final int selectedMonth;
  final DateTime? selectedDate;
  final String filterType; // 'all', 'expense', 'income'
  final String searchQuery;
  final bool isLoading;

  const TransactionState({
    this.allTransactions = const [],
    this.filteredTransactions = const [],
    required this.selectedYear,
    required this.selectedMonth,
    this.selectedDate,
    this.filterType = 'all',
    this.searchQuery = '',
    this.isLoading = false,
  });

  double get totalIncome {
    final list = selectedDate != null ? filteredTransactions : allTransactions;
    return list
        .where((t) => t.transaction.type == 'income')
        .fold(0.0, (sum, t) => sum + t.transaction.amount);
  }

  double get totalExpense {
    final list = selectedDate != null ? filteredTransactions : allTransactions;
    return list
        .where((t) => t.transaction.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.transaction.amount);
  }

  double get netBalance => totalIncome - totalExpense;

  TransactionState copyWith({
    List<TransactionWithCategory>? allTransactions,
    List<TransactionWithCategory>? filteredTransactions,
    int? selectedYear,
    int? selectedMonth,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    String? filterType,
    String? searchQuery,
    bool? isLoading,
  }) {
    return TransactionState(
      allTransactions: allTransactions ?? this.allTransactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedDate: clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      filterType: filterType ?? this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        allTransactions,
        filteredTransactions,
        selectedYear,
        selectedMonth,
        selectedDate,
        filterType,
        searchQuery,
        isLoading,
      ];
}

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;
  StreamSubscription? _subscription;

  TransactionCubit(this._repository)
      : super(TransactionState(
          selectedYear: DateTime.now().year,
          selectedMonth: DateTime.now().month,
        )) {
    _loadMonthTransactions();
  }

  void _loadMonthTransactions() {
    _subscription?.cancel();
    emit(state.copyWith(isLoading: true));

    _subscription = _repository
        .watchTransactionsForMonth(state.selectedYear, state.selectedMonth)
        .listen((transactions) {
      final filtered = _applyFilter(transactions, state.filterType, state.searchQuery, state.selectedDate);
      emit(state.copyWith(
        allTransactions: transactions,
        filteredTransactions: filtered,
        isLoading: false,
      ));
    });
  }

  List<TransactionWithCategory> _applyFilter(
    List<TransactionWithCategory> list,
    String type,
    String query,
    DateTime? date,
  ) {
    return list.where((item) {
      final matchesType = type == 'all' || item.transaction.type == type;
      final matchesQuery = query.isEmpty ||
          item.category.name.toLowerCase().contains(query.toLowerCase()) ||
          (item.transaction.note != null &&
              item.transaction.note!.toLowerCase().contains(query.toLowerCase()));
      final matchesDate = date == null ||
          (item.transaction.date.year == date.year &&
           item.transaction.date.month == date.month &&
           item.transaction.date.day == date.day);
      return matchesType && matchesQuery && matchesDate;
    }).toList();
  }

  void setFilterType(String type) {
    final filtered = _applyFilter(state.allTransactions, type, state.searchQuery, state.selectedDate);
    emit(state.copyWith(filterType: type, filteredTransactions: filtered));
  }

  void setSearchQuery(String query) {
    final filtered = _applyFilter(state.allTransactions, state.filterType, query, state.selectedDate);
    emit(state.copyWith(searchQuery: query, filteredTransactions: filtered));
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
        selectedDate: date,
      ));
      _loadMonthTransactions();
    } else {
      final filtered = _applyFilter(state.allTransactions, state.filterType, state.searchQuery, date);
      emit(state.copyWith(selectedDate: date, filteredTransactions: filtered));
    }
  }

  void clearDateFilter() {
    final filtered = _applyFilter(state.allTransactions, state.filterType, state.searchQuery, null);
    emit(state.copyWith(clearSelectedDate: true, filteredTransactions: filtered));
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
      clearSelectedDate: true,
    ));
    _loadMonthTransactions();
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required DateTime date,
    String? note,
    bool isRecurring = false,
  }) async {
    await _repository.addTransaction(
      type: type,
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
      isRecurring: isRecurring,
    );
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
