import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/features/account/account_list_filter_state.dart';
import 'package:flutter/foundation.dart';

class AccountListViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<AccountListResponse> _rawItems = [];
  AccountFilterState filterState = const AccountFilterState();

  Map<String, List<AccountListResponse>> get filteredGrouped {
    final state = filterState;
    final filtered = _rawItems.where((item) {
      if (state.divisionIds.isNotEmpty &&
          !state.divisionIds.contains(item.divisionId)) {
        return false;
      }
      if (state.categoryIds.isNotEmpty &&
          !state.categoryIds.contains(item.categoryId)) {
        return false;
      }
      if (state.categorySeqs.isNotEmpty &&
          !state.categorySeqs.contains(item.categorySeq)) {
        return false;
      }
      if (state.memberIds.isNotEmpty &&
          !state.memberIds.contains(item.memberId)) {
        return false;
      }
      if (state.searchText.isNotEmpty) {
        final q = state.searchText.toLowerCase();
        if (!item.categoryNm.toLowerCase().contains(q) &&
            !item.categorySeqNm.toLowerCase().contains(q) &&
            !(item.remark ?? '').toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    });
    return _groupByDate(filtered.toList());
  }

  List<({String id, String nm})> get availableDivisions => _rawItems
      .map((e) => (id: e.divisionId, nm: e.divisionNm))
      .toSet()
      .toList();

  List<({String id, String nm})> get availableCategories => _rawItems
      .map((e) => (id: e.categoryId, nm: e.categoryNm))
      .toSet()
      .toList();

  List<({String id, String seq, String nm})> get availableCategorySeqs {
    if (filterState.categoryIds.isEmpty) return [];
    return _rawItems
        .where((e) => filterState.categoryIds.contains(e.categoryId))
        .map((e) => (id: e.categoryId, seq: e.categorySeq, nm: e.categorySeqNm))
        .toSet()
        .toList();
  }

  List<({String id, String nm})> get availableMembers => _rawItems
      .map((e) => (id: e.memberId, nm: e.memberNm))
      .toSet()
      .toList();

  void updateFilter(AccountFilterState next) {
    final removedCategoryIds =
        filterState.categoryIds.difference(next.categoryIds);
    if (removedCategoryIds.isNotEmpty) {
      final invalidSeqs = _rawItems
          .where((e) => removedCategoryIds.contains(e.categoryId))
          .map((e) => e.categorySeq)
          .toSet();
      final cleanedSeqs = next.categorySeqs.difference(invalidSeqs);
      filterState = next.copyWith(categorySeqs: cleanedSeqs);
    } else {
      filterState = next;
    }
    notifyListeners();
  }

  void clearFilter() {
    filterState = const AccountFilterState();
    notifyListeners();
  }

  Future<void> load(String strtDt, String endDt) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _rawItems = await AccountService.instance.getAccounts(
        strtDt: strtDt,
        endDt: endDt,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(int accountId) async {
    await AccountService.instance.deleteAccount(accountId);
    _rawItems = _rawItems.where((e) => e.accountId != accountId).toList();
    notifyListeners();
  }

  @visibleForTesting
  void setItemsForTest(List<AccountListResponse> items) => _rawItems = items;

  Map<String, List<AccountListResponse>> _groupByDate(
    List<AccountListResponse> items,
  ) {
    final map = <String, List<AccountListResponse>>{};
    for (final item in items) {
      map.putIfAbsent(item.accountDt, () => []).add(item);
    }
    return map;
  }
}
