import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:flutter/foundation.dart';

class AccountListViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  Map<String, List<AccountListResponse>> grouped = {};

  String? divisionId;
  String? categoryId;
  String? categorySeq;
  String? memberId;

  void setFilter({
    String? divisionId,
    String? categoryId,
    String? categorySeq,
    String? memberId,
  }) {
    this.divisionId = divisionId;
    this.categoryId = categoryId;
    this.categorySeq = categorySeq;
    this.memberId = memberId;
  }

  Future<void> load(String strtDt, String endDt) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final items = await AccountService.instance.getAccounts(
        strtDt: strtDt,
        endDt: endDt,
        divisionId: divisionId,
        categoryId: categoryId,
        categorySeq: categorySeq,
        memberId: memberId,
      );
      grouped = _groupByDate(items);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(int accountId) async {
    await AccountService.instance.deleteAccount(accountId);
    final updated = <String, List<AccountListResponse>>{};
    for (final entry in grouped.entries) {
      final items = entry.value.where((e) => e.accountId != accountId).toList();
      if (items.isNotEmpty) updated[entry.key] = items;
    }
    grouped = updated;
    notifyListeners();
  }

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
