import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/models/member_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/data/services/member_service.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/analysis/division_summary_viewmodel.dart';
import 'package:account_book_vibe/features/analysis/expense_summary_data.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

class ExpenseSummaryViewModel extends ChangeNotifier {
  ExpenseSummaryViewModel(this.period) {
    period.addListener(load);
  }

  final DashboardPeriodViewModel period;

  bool isLoading = false;
  String? errorMessage;
  ExpenseSummaryData? data;

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
          strtDt: range.strtDt, endDt: range.endDt, divisionId: Division.expense,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense, strtDt: range.strtDt, endDt: range.endDt,
        ),
        AccountService.instance.getAccounts(
          strtDt: prevRange.strtDt, endDt: prevRange.endDt, divisionId: Division.expense,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense, strtDt: prevRange.strtDt, endDt: prevRange.endDt,
        ),
        MemberService.instance.getMemberSum(
          divisionId: Division.expense, strtDt: range.strtDt, endDt: range.endDt,
        ),
        if (needsChartFetch)
          AccountService.instance.getAccounts(
            strtDt: chartRange.strtDt, endDt: chartRange.endDt, divisionId: Division.expense,
          ),
      ]);

      final currentAccounts = results[0] as List<AccountListResponse>;
      final currentCatSums = results[1] as List<CategorySumResponse>;
      final prevAccounts = results[2] as List<AccountListResponse>;
      final prevCatSums = results[3] as List<CategorySumResponse>;
      final memberSums = results[4] as List<MemberSumResponse>;
      final chartAccounts =
          needsChartFetch ? results[5] as List<AccountListResponse> : currentAccounts;

      final topTx = [...currentAccounts]..sort((a, b) => b.price.compareTo(a.price));

      data = ExpenseSummaryData(
        summary: DivisionSummaryData(
          totalAmount: currentAccounts.fold(0, (s, e) => s + e.price),
          prevPeriodAmount: prevAccounts.fold(0, (s, e) => s + e.price),
          monthlyAmounts: DivisionSummaryViewModel.buildMonthlyTotals(
            chartAccounts, chartRange.strtDt, chartRange.endDt,
          ),
          categoryBreakdown:
              DivisionSummaryViewModel.buildCategoryBreakdown(currentCatSums, prevCatSums),
          changeLabel: period.changeLabel,
          chartHighlightMonth: period.chartHighlightMonth,
        ),
        categorySeqBreakdown: buildExpenseCategorySeqBreakdown(currentCatSums, prevCatSums),
        memberBreakdown: buildExpenseMemberBreakdown(memberSums),
        topTransactions: topTx.take(10).toList(),
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    period.removeListener(load);
    super.dispose();
  }
}
