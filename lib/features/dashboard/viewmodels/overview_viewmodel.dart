import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

class CategoryExpenseItem {
  const CategoryExpenseItem({
    required this.categoryId,
    required this.categoryNm,
    required this.amount,
    required this.ratio,
  });

  final String categoryId;
  final String categoryNm;
  final int amount;
  final double ratio;
}

class DashboardOverviewData {
  const DashboardOverviewData({
    required this.netWorth,
    required this.prevMonthNetWorth,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalInvest,
    required this.topExpenseCategories,
    required this.recentTransactions,
    required this.netWorthHistory,
  });

  final int netWorth;
  final int prevMonthNetWorth;
  final int totalIncome;
  final int totalExpense;
  final int totalInvest;
  final List<CategoryExpenseItem> topExpenseCategories;
  final List<AccountListResponse> recentTransactions;
  final List<({String date, int amount})> netWorthHistory;

  int get savings => totalIncome - totalExpense;
  int get netWorthChange => netWorth - prevMonthNetWorth;
}

class DashboardOverviewViewModel extends ChangeNotifier {
  DashboardOverviewViewModel(this._period) {
    _period.addListener(load);
  }

  final DashboardPeriodViewModel _period;
  bool isLoading = false;
  String? errorMessage;
  DashboardOverviewData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = _period.range;
      final now = DateTime.now();
      final todayDt =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final prevDt =
          '${prevMonth.year}${prevMonth.month.toString().padLeft(2, '0')}01';

      final results = await Future.wait([
        MyAssetService.instance.getMyAssets(strtDt: todayDt, endDt: todayDt),
        MyAssetService.instance.getMyAssets(strtDt: prevDt, endDt: prevDt),
        AccountService.instance.getAccounts(
          divisionId: Division.income,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        AccountService.instance.getAccounts(
          divisionId: Division.expense,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        AccountService.instance.getAccounts(
          divisionId: Division.invest,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        AccountService.instance.getAccounts(
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        MyAssetService.instance.getMyAssetSum(
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
      ]);

      final currentAsset = results[0] as MyAssetListResponse;
      final prevAsset = results[1] as MyAssetListResponse;
      final incomeList = results[2] as List<AccountListResponse>;
      final expenseList = results[3] as List<AccountListResponse>;
      final investList = results[4] as List<AccountListResponse>;
      final catSums = results[5] as List<CategorySumResponse>;
      final allTxs = results[6] as List<AccountListResponse>;
      final assetSums = results[7] as List<MyAssetSumResponse>;

      data = DashboardOverviewData(
        netWorth: currentAsset.totNetWorthSumPrice,
        prevMonthNetWorth: prevAsset.totNetWorthSumPrice,
        totalIncome: incomeList.fold(0, (s, e) => s + e.price),
        totalExpense: expenseList.fold(0, (s, e) => s + e.price),
        totalInvest: investList.fold(0, (s, e) => s + e.price),
        topExpenseCategories: buildTopCategories(catSums),
        recentTransactions:
            (allTxs..sort((a, b) => b.accountDt.compareTo(a.accountDt)))
                .take(5)
                .toList(),
        netWorthHistory: _buildNetWorthHistory(assetSums),
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static List<CategoryExpenseItem> buildTopCategories(
    List<CategorySumResponse> sums,
  ) {
    final sorted = [...sums]..sort((a, b) => b.sumPrice.compareTo(a.sumPrice));
    final top = sorted.take(5).toList();
    final total = top.fold(0, (s, e) => s + e.sumPrice);
    if (total == 0) return [];
    return top
        .map((e) => CategoryExpenseItem(
              categoryId: e.categoryId,
              categoryNm: e.categoryNm,
              amount: e.sumPrice,
              ratio: e.sumPrice / total,
            ))
        .toList();
  }

  static List<({String date, int amount})> _buildNetWorthHistory(
    List<MyAssetSumResponse> sums,
  ) {
    final byDateAsset = <String, int>{};
    final byDateDebt = <String, int>{};
    for (final s in sums) {
      if (s.assetId == '0') continue;
      if (s.assetId == '6') {
        byDateDebt[s.accumDt] = (byDateDebt[s.accumDt] ?? 0) + s.sumPrice;
      } else {
        byDateAsset[s.accumDt] =
            (byDateAsset[s.accumDt] ?? 0) + s.sumPrice;
      }
    }
    final allDates = {
      ...byDateAsset.keys,
      ...byDateDebt.keys,
    }.toList()
      ..sort();
    return allDates.map((date) {
      final asset = byDateAsset[date] ?? 0;
      final debt = byDateDebt[date] ?? 0;
      return (date: date, amount: asset - debt);
    }).toList();
  }

  @override
  void dispose() {
    _period.removeListener(load);
    super.dispose();
  }
}
