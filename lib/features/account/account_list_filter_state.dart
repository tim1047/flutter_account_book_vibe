class AccountFilterState {
  const AccountFilterState({
    this.divisionIds = const {},
    this.categoryIds = const {},
    this.categorySeqs = const {},
    this.memberIds = const {},
    this.searchText = '',
  });

  final Set<String> divisionIds;
  final Set<String> categoryIds;
  final Set<String> categorySeqs;
  final Set<String> memberIds;
  final String searchText;

  bool get isActive =>
      divisionIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      categorySeqs.isNotEmpty ||
      memberIds.isNotEmpty ||
      searchText.isNotEmpty;

  int get activeCount =>
      (divisionIds.isNotEmpty ? 1 : 0) +
      (categoryIds.isNotEmpty ? 1 : 0) +
      (categorySeqs.isNotEmpty ? 1 : 0) +
      (memberIds.isNotEmpty ? 1 : 0) +
      (searchText.isNotEmpty ? 1 : 0);

  AccountFilterState copyWith({
    Set<String>? divisionIds,
    Set<String>? categoryIds,
    Set<String>? categorySeqs,
    Set<String>? memberIds,
    String? searchText,
  }) =>
      AccountFilterState(
        divisionIds: divisionIds ?? this.divisionIds,
        categoryIds: categoryIds ?? this.categoryIds,
        categorySeqs: categorySeqs ?? this.categorySeqs,
        memberIds: memberIds ?? this.memberIds,
        searchText: searchText ?? this.searchText,
      );

  AccountFilterState get cleared => const AccountFilterState();
}
