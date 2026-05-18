import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
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

class DashboardExpenseData {
  const DashboardExpenseData({
    required this.totalExpense,
    required this.prevPeriodExpense,
    required this.monthlyExpenses,
    required this.categoryBreakdown,
    required this.topTransactions,
    required this.changeLabel,
  });

  final int totalExpense;
  final int prevPeriodExpense;
  final List<({String month, int amount})> monthlyExpenses;
  final List<ExpenseCategoryItem> categoryBreakdown;
  final List<AccountListResponse> topTransactions;
  final String changeLabel;

  double get changeRate {
    if (prevPeriodExpense == 0) return 0;
    return (totalExpense - prevPeriodExpense) / prevPeriodExpense;
  }
}

class DashboardExpenseViewModel extends ChangeNotifier {
  DashboardExpenseViewModel(this._period) {
    _period.addListener(load);
  }

  final DashboardPeriodViewModel _period;
  bool isLoading = false;
  String? errorMessage;
  DashboardExpenseData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = _period.range;
      final prevRange = _period.prevRange;

      final results = await Future.wait([
        AccountService.instance.getAccounts(
          strtDt: range.strtDt,
          endDt: range.endDt,
          divisionId: Division.expense,
        ),
        AccountService.instance.getAccounts(
          strtDt: prevRange.strtDt,
          endDt: prevRange.endDt,
          divisionId: Division.expense,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense,
          strtDt: prevRange.strtDt,
          endDt: prevRange.endDt,
        ),
      ]);

      // 서버에서 이미 expense만 필터링해서 줌
      final current = results[0] as List<AccountListResponse>;
      final prevAccounts = results[1] as List<AccountListResponse>;
      final currentCats = results[2] as List<CategorySumResponse>;
      final prevCats = results[3] as List<CategorySumResponse>;

      final topTx = [...current]..sort((a, b) => b.price.compareTo(a.price));

      data = DashboardExpenseData(
        totalExpense: current.fold(0, (s, e) => s + e.price),
        prevPeriodExpense: prevAccounts.fold(0, (s, e) => s + e.price),
        monthlyExpenses: buildMonthlyTotals(current, range.strtDt, range.endDt),
        categoryBreakdown: buildCategoryBreakdown(currentCats, prevCats),
        topTransactions: topTx.take(10).toList(),
        changeLabel: _period.changeLabel,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
    _period.removeListener(load);
    super.dispose();
  }
}
