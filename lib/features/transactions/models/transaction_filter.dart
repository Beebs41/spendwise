import 'package:equatable/equatable.dart';

enum DateFilterPreset {
  month,
  today,
  thisWeek,
  last30Days,
  thisYear,
  allTime,
  custom,
}

enum SortOption {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
}

class TransactionFilter extends Equatable {
  final DateFilterPreset datePreset;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final DateTime? specificDate;
  final String type; // 'all', 'expense', 'income'
  final Set<int> categoryIds; // Empty = all
  final int? occasionId; // null = all, -1 = no occasion, >0 = specific occasion
  final double? minAmount;
  final double? maxAmount;
  final SortOption sortBy;
  final String searchQuery;
  final bool searchAllTime;

  const TransactionFilter({
    this.datePreset = DateFilterPreset.month,
    this.customStartDate,
    this.customEndDate,
    this.specificDate,
    this.type = 'all',
    this.categoryIds = const {},
    this.occasionId,
    this.minAmount,
    this.maxAmount,
    this.sortBy = SortOption.dateDesc,
    this.searchQuery = '',
    this.searchAllTime = false,
  });

  bool get isDefault =>
      datePreset == DateFilterPreset.month &&
      specificDate == null &&
      type == 'all' &&
      categoryIds.isEmpty &&
      occasionId == null &&
      minAmount == null &&
      maxAmount == null &&
      sortBy == SortOption.dateDesc &&
      searchQuery.isEmpty &&
      !searchAllTime;

  /// Returns count of filters active beyond the default month & type='all'
  int get activeFilterCount {
    int count = 0;
    if (datePreset != DateFilterPreset.month || specificDate != null) count++;
    if (categoryIds.isNotEmpty) count++;
    if (occasionId != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (sortBy != SortOption.dateDesc) count++;
    if (searchAllTime) count++;
    return count;
  }

  bool get hasActiveAdvancedFilters => activeFilterCount > 0;

  TransactionFilter copyWith({
    DateFilterPreset? datePreset,
    DateTime? customStartDate,
    DateTime? customEndDate,
    DateTime? specificDate,
    bool clearSpecificDate = false,
    bool clearCustomDates = false,
    String? type,
    Set<int>? categoryIds,
    int? occasionId,
    bool clearOccasionId = false,
    double? minAmount,
    double? maxAmount,
    bool clearAmountRange = false,
    SortOption? sortBy,
    String? searchQuery,
    bool? searchAllTime,
  }) {
    return TransactionFilter(
      datePreset: datePreset ?? this.datePreset,
      customStartDate: clearCustomDates ? null : (customStartDate ?? this.customStartDate),
      customEndDate: clearCustomDates ? null : (customEndDate ?? this.customEndDate),
      specificDate: clearSpecificDate ? null : (specificDate ?? this.specificDate),
      type: type ?? this.type,
      categoryIds: categoryIds ?? this.categoryIds,
      occasionId: clearOccasionId ? null : (occasionId ?? this.occasionId),
      minAmount: clearAmountRange ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmountRange ? null : (maxAmount ?? this.maxAmount),
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
      searchAllTime: searchAllTime ?? this.searchAllTime,
    );
  }

  TransactionFilter reset() {
    return const TransactionFilter();
  }

  @override
  List<Object?> get props => [
        datePreset,
        customStartDate,
        customEndDate,
        specificDate,
        type,
        categoryIds,
        occasionId,
        minAmount,
        maxAmount,
        sortBy,
        searchQuery,
        searchAllTime,
      ];
}
