import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_shared_viewmodel.dart';
import 'package:flutter/foundation.dart';

class ExpenseCategoryItem {
  const ExpenseCategoryItem({
    required this.categoryId,
    required this.categoryNm,
    required this.amount,
    required this.ratio,
    this.prevPeriodAmount = 0,
  });

  final String categoryId;
  final String categoryNm;
  final int amount;
  final double ratio;
  final int prevPeriodAmount;

  double get changeRate {
    if (prevPeriodAmount == 0) return 0;
    return (amount - prevPeriodAmount) / prevPeriodAmount;
  }
}

class ExpenseCategorySeqItem {
  const ExpenseCategorySeqItem({
    required this.categoryNm,
    required this.categorySeqNm,
    required this.amount,
    required this.ratio,
    this.prevPeriodAmount = 0,
  });

  final String categoryNm;
  final String categorySeqNm;
  final int amount;
  final double ratio;
  final int prevPeriodAmount;

  double get changeRate {
    if (prevPeriodAmount == 0) return 0;
    return (amount - prevPeriodAmount) / prevPeriodAmount;
  }
}

class DashboardExpenseData {
  const DashboardExpenseData({
    required this.totalExpense,
    required this.prevPeriodExpense,
    required this.monthlyExpenses,
    required this.categoryBreakdown,
    required this.categorySeqBreakdown,
    required this.topTransactions,
    required this.changeLabel,
  });

  final int totalExpense;
  final int prevPeriodExpense;
  final List<({String month, int amount})> monthlyExpenses;
  final List<ExpenseCategoryItem> categoryBreakdown;
  final List<ExpenseCategorySeqItem> categorySeqBreakdown;
  final List<AccountListResponse> topTransactions;
  final String changeLabel;

  double get changeRate {
    if (prevPeriodExpense == 0) return 0;
    return (totalExpense - prevPeriodExpense) / prevPeriodExpense;
  }
}

class DashboardExpenseViewModel extends ChangeNotifier {
  DashboardExpenseViewModel(this._shared) {
    _shared.addListener(_onSharedUpdated);
  }

  final DashboardSharedViewModel _shared;
  DashboardPeriodViewModel get _period => _shared.period;

  bool isLoading = false;
  String? errorMessage;
  DashboardExpenseData? data;

  bool _ownLoading = false;
  List<AccountListResponse>? _prevAccounts;
  List<CategorySumResponse>? _prevCatSums;
  bool _sharedWasLoading = false;

  /// Public entry point (called on init and when needed).
  Future<void> load() => _loadOwn();

  Future<void> _loadOwn() async {
    _ownLoading = true;
    _prevAccounts = null;
    _prevCatSums = null;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prevRange = _period.prevRange;

      final results = await Future.wait([
        AccountService.instance.getAccounts(
          strtDt: prevRange.strtDt,
          endDt: prevRange.endDt,
          divisionId: Division.expense,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense,
          strtDt: prevRange.strtDt,
          endDt: prevRange.endDt,
        ),
      ]);

      _prevAccounts = results[0] as List<AccountListResponse>;
      _prevCatSums = results[1] as List<CategorySumResponse>;
    } on AppException catch (e) {
      errorMessage = e.message;
      _ownLoading = false;
      isLoading = false;
      notifyListeners();
      return;
    }

    _ownLoading = false;
    _tryBuildData();
  }

  void _onSharedUpdated() {
    if (_shared.isLoading) {
      _sharedWasLoading = true;
      return;
    }
    if (_sharedWasLoading) {
      _sharedWasLoading = false;
      _loadOwn();
      return;
    }
    _tryBuildData();
  }

  void _tryBuildData() {
    if (_ownLoading || _shared.isLoading) return;
    if (_prevAccounts == null || _prevCatSums == null) return;

    if (_shared.errorMessage != null) {
      errorMessage = _shared.errorMessage;
      isLoading = false;
      notifyListeners();
      return;
    }

    // Current expense from shared (client-side filter)
    final current = _shared.accounts
        .where((tx) => tx.divisionId == Division.expense)
        .toList();

    final currentCats = _shared.catSums;
    final prevCats = _prevCatSums!;
    final prevAccounts = _prevAccounts!;

    final topTx = [...current]..sort((a, b) => b.price.compareTo(a.price));

    data = DashboardExpenseData(
      totalExpense: current.fold(0, (s, e) => s + e.price),
      prevPeriodExpense: prevAccounts.fold(0, (s, e) => s + e.price),
      monthlyExpenses: buildMonthlyTotals(
        current,
        _period.range.strtDt,
        _period.range.endDt,
      ),
      categoryBreakdown: buildCategoryBreakdown(currentCats, prevCats),
      categorySeqBreakdown: buildCategorySeqBreakdown(currentCats, prevCats),
      topTransactions: topTx.take(10).toList(),
      changeLabel: _period.changeLabel,
    );
    isLoading = false;
    notifyListeners();
  }

  static List<ExpenseCategorySeqItem> buildCategorySeqBreakdown(
    List<CategorySumResponse> current,
    List<CategorySumResponse> prev,
  ) {
    final total = current.fold(0, (s, e) => s + e.sumPrice);
    if (total == 0) return [];
    // prev: categoryId -> (categorySeq -> sumPrice)
    final prevMap = <String, Map<String, int>>{};
    for (final cat in prev) {
      prevMap[cat.categoryId] = {
        for (final seq in cat.data) seq.categorySeq: seq.sumPrice,
      };
    }
    final items = <ExpenseCategorySeqItem>[];
    for (final cat in current) {
      for (final seq in cat.data) {
        if (seq.sumPrice > 0) {
          items.add(ExpenseCategorySeqItem(
            categoryNm: cat.categoryNm,
            categorySeqNm: seq.categorySeqNm,
            amount: seq.sumPrice,
            ratio: seq.sumPrice / total,
            prevPeriodAmount:
                prevMap[cat.categoryId]?[seq.categorySeq] ?? 0,
          ));
        }
      }
    }
    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  static List<ExpenseCategoryItem> buildCategoryBreakdown(
    List<CategorySumResponse> current,
    List<CategorySumResponse> prev,
  ) {
    final total = current.fold(0, (s, e) => s + e.sumPrice);
    if (total == 0) return [];
    final prevMap = {for (final e in prev) e.categoryId: e.sumPrice};
    final sorted = [...current]
      ..sort((a, b) => b.sumPrice.compareTo(a.sumPrice));
    return sorted
        .map((e) => ExpenseCategoryItem(
              categoryId: e.categoryId,
              categoryNm: e.categoryNm,
              amount: e.sumPrice,
              ratio: e.sumPrice / total,
              prevPeriodAmount: prevMap[e.categoryId] ?? 0,
            ))
        .toList();
  }

  static List<({String month, int amount})> buildMonthlyTotals(
    List<dynamic> transactions,
    String strtDt,
    String endDt,
  ) {
    final byMonth = <String, int>{};
    for (final tx in transactions) {
      final String dt;
      final int price;
      if (tx is AccountListResponse) {
        dt = tx.accountDt;
        price = tx.price;
      } else {
        dt = (tx as dynamic).accountDt as String;
        price = (tx as dynamic).price as int;
      }
      if (dt.length >= 6) {
        final month = dt.substring(0, 6);
        byMonth[month] = (byMonth[month] ?? 0) + price;
      }
    }
    final sorted = byMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => (month: e.key, amount: e.value)).toList();
  }

  @override
  void dispose() {
    _shared.removeListener(_onSharedUpdated);
    super.dispose();
  }
}
