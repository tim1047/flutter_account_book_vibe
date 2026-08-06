import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

/// 지출/수입/투자 공통 요약(총액·카테고리 비중·월별 추이)을 로드하는 뷰모델.
/// [divisionId]로 어느 division을 볼지 결정하며, 자기 데이터를 독립적으로 fetch한다.
class DivisionSummaryViewModel extends ChangeNotifier {
  DivisionSummaryViewModel(this.divisionId, this.period) {
    period.addListener(load);
  }

  final String divisionId;
  final DashboardPeriodViewModel period;

  bool isLoading = false;
  String? errorMessage;
  DivisionSummaryData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = period.range;
      final prevRange = period.prevRange;
      final chartRange = period.chartRange;
      final needsChartFetch = chartRange != range;

      final results = await Future.wait([
        AccountService.instance.getAccounts(
          strtDt: range.strtDt,
          endDt: range.endDt,
          divisionId: divisionId,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: divisionId,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        AccountService.instance.getAccounts(
          strtDt: prevRange.strtDt,
          endDt: prevRange.endDt,
          divisionId: divisionId,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: divisionId,
          strtDt: prevRange.strtDt,
          endDt: prevRange.endDt,
        ),
        if (needsChartFetch)
          AccountService.instance.getAccounts(
            strtDt: chartRange.strtDt,
            endDt: chartRange.endDt,
            divisionId: divisionId,
          ),
      ]);

      final currentAccounts = results[0] as List<AccountListResponse>;
      final currentCatSums = results[1] as List<CategorySumResponse>;
      final prevAccounts = results[2] as List<AccountListResponse>;
      final prevCatSums = results[3] as List<CategorySumResponse>;
      final chartAccounts =
          needsChartFetch ? results[4] as List<AccountListResponse> : currentAccounts;

      data = DivisionSummaryData(
        totalAmount: currentAccounts.fold(0, (s, e) => s + e.price),
        prevPeriodAmount: prevAccounts.fold(0, (s, e) => s + e.price),
        monthlyAmounts: buildMonthlyTotals(
          chartAccounts,
          chartRange.strtDt,
          chartRange.endDt,
        ),
        categoryBreakdown: buildCategoryBreakdown(currentCatSums, prevCatSums),
        changeLabel: period.changeLabel,
        chartHighlightMonth: period.chartHighlightMonth,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static List<DivisionCategoryItem> buildCategoryBreakdown(
    List<CategorySumResponse> current,
    List<CategorySumResponse> prev,
  ) {
    final total = current.fold(0, (s, e) => s + e.sumPrice);
    if (total == 0) return [];
    final prevMap = {for (final e in prev) e.categoryId: e.sumPrice};
    final sorted = [...current]..sort((a, b) => b.sumPrice.compareTo(a.sumPrice));
    return sorted
        .map((e) => DivisionCategoryItem(
              categoryId: e.categoryId,
              categoryNm: e.categoryNm,
              amount: e.sumPrice,
              ratio: e.sumPrice / total,
              prevPeriodAmount: prevMap[e.categoryId] ?? 0,
            ))
        .toList();
  }

  static List<({String month, int amount})> buildMonthlyTotals(
    List<AccountListResponse> transactions,
    String strtDt,
    String endDt,
  ) {
    final byMonth = <String, int>{};
    for (final tx in transactions) {
      final dt = tx.accountDt;
      if (dt.length >= 6) {
        final month = dt.substring(0, 6);
        byMonth[month] = (byMonth[month] ?? 0) + tx.price;
      }
    }
    final sorted = byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => (month: e.key, amount: e.value)).toList();
  }

  @override
  void dispose() {
    period.removeListener(load);
    super.dispose();
  }
}
