import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_shared_viewmodel.dart';
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
    required this.prevPeriodNetWorth,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalInvest,
    required this.topExpenseCategories,
    required this.recentTransactions,
    required this.netWorthHistory,
    required this.changeLabel,
  });

  final int netWorth;
  final int prevPeriodNetWorth;
  final int totalIncome;
  final int totalExpense;
  final int totalInvest;
  final List<CategoryExpenseItem> topExpenseCategories;
  final List<AccountListResponse> recentTransactions;
  final List<({String date, int amount})> netWorthHistory;
  final String changeLabel;

  int get savings => totalIncome - totalExpense;
  int get netWorthChange => netWorth - prevPeriodNetWorth;
}

class DashboardOverviewViewModel extends ChangeNotifier {
  DashboardOverviewViewModel(this._shared) {
    _shared.addListener(_onSharedUpdated);
  }

  final DashboardSharedViewModel _shared;
  DashboardPeriodViewModel get _period => _shared.period;

  bool isLoading = false;
  String? errorMessage;
  DashboardOverviewData? data;

  // Internal state for own data
  bool _ownLoading = false;
  MyAssetListResponse? _currentAsset;
  List<MyAssetSumResponse>? _prevSums;
  List<MyAssetSumResponse>? _assetSums;
  bool _sharedWasLoading = false;

  /// Public entry point (called on init and when needed).
  Future<void> load() => _loadOwn();

  Future<void> _loadOwn() async {
    _ownLoading = true;
    _currentAsset = null;
    _prevSums = null;
    _assetSums = null;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayDt =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final prevDt = _period.prevRange.endDt;
      final range = _period.range;

      final results = await Future.wait([
        MyAssetService.instance.getMyAssets(strtDt: todayDt, endDt: todayDt),
        MyAssetService.instance.getMyAssetSum(strtDt: prevDt, endDt: prevDt),
        MyAssetService.instance.getMyAssetSum(
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
      ]);

      _currentAsset = results[0] as MyAssetListResponse;
      _prevSums = results[1] as List<MyAssetSumResponse>;
      _assetSums = results[2] as List<MyAssetSumResponse>;
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
    if (_currentAsset == null || _prevSums == null || _assetSums == null) return;

    if (_shared.errorMessage != null) {
      errorMessage = _shared.errorMessage;
      isLoading = false;
      notifyListeners();
      return;
    }

    final allAccounts = _shared.accounts;
    final catSums = _shared.catSums;

    final incomeList =
        allAccounts.where((tx) => tx.divisionId == Division.income).toList();
    final expenseList =
        allAccounts.where((tx) => tx.divisionId == Division.expense).toList();
    final investList =
        allAccounts.where((tx) => tx.divisionId == Division.invest).toList();

    final allTxs = [...allAccounts]
      ..sort((a, b) => b.accountDt.compareTo(a.accountDt));

    data = DashboardOverviewData(
      netWorth: _currentAsset!.totNetWorthSumPrice,
      prevPeriodNetWorth: _calcNetWorth(_prevSums!),
      changeLabel: _period.changeLabel,
      totalIncome: incomeList.fold(0, (s, e) => s + e.price),
      totalExpense: expenseList.fold(0, (s, e) => s + e.price),
      totalInvest: investList.fold(0, (s, e) => s + e.price),
      topExpenseCategories: buildTopCategories(catSums),
      recentTransactions: allTxs.take(5).toList(),
      netWorthHistory: _buildNetWorthHistory(_assetSums!),
    );
    isLoading = false;
    notifyListeners();
  }

  static int _calcNetWorth(List<MyAssetSumResponse> sums) {
    int assets = 0;
    int debt = 0;
    for (final s in sums) {
      if (s.assetId == '0') continue;
      if (s.assetId == '6') {
        debt += s.sumPrice;
      } else {
        assets += s.sumPrice;
      }
    }
    return assets - debt;
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
    final now = DateTime.now();
    final todayStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final raw = allDates.map((date) {
      final asset = byDateAsset[date] ?? 0;
      final debt = byDateDebt[date] ?? 0;
      return (date: date, amount: asset - debt);
    }).toList();

    var lastKnown = 0;
    final result = <({String date, int amount})>[];
    for (final entry in raw) {
      if (entry.date.compareTo(todayStr) <= 0 && entry.amount != 0) {
        lastKnown = entry.amount;
        result.add(entry);
      } else if (entry.date.compareTo(todayStr) > 0 &&
          entry.amount == 0 &&
          lastKnown != 0) {
        result.add((date: entry.date, amount: lastKnown));
      } else {
        result.add(entry);
      }
    }
    return result;
  }

  @override
  void dispose() {
    _shared.removeListener(_onSharedUpdated);
    super.dispose();
  }
}
