// lib/features/dashboard/viewmodels/asset_viewmodel.dart
import 'package:account_book_vibe/core/constants/asset_ids.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:flutter/foundation.dart';

enum AssetHistoryPeriod { threeMonths, sixMonths, oneYear }

class AssetCompositionItem {
  const AssetCompositionItem({
    required this.assetId,
    required this.assetNm,
    required this.amount,
    required this.ratio,
  });

  final String assetId;
  final String assetNm;
  final int amount;
  final double ratio;
}

class DebtItem {
  const DebtItem({required this.name, required this.amount});

  final String name;
  final int amount;
}

class DashboardAssetData {
  const DashboardAssetData({
    required this.totalAsset,
    required this.netWorth,
    required this.debt,
    required this.prevYearNetWorth,
    required this.prevMonthNetWorth,
    required this.assetComposition,
    required this.netWorthHistory,
    required this.assetHistoryNames,
    required this.assetHistory,
    required this.debtItems,
  });

  final int totalAsset;
  final int netWorth;
  final int debt;
  final int prevYearNetWorth;
  final int prevMonthNetWorth;
  final List<AssetCompositionItem> assetComposition;
  final List<({String date, int amount})> netWorthHistory;
  final List<({String id, String name})> assetHistoryNames;
  final List<({String date, Map<String, int> byAsset})> assetHistory;
  final List<DebtItem> debtItems;

  int get yearlyGrowth => netWorth - prevYearNetWorth;
  int get monthlyGrowth => netWorth - prevMonthNetWorth;
}

class DashboardAssetViewModel extends ChangeNotifier {
  DashboardAssetViewModel();

  AssetHistoryPeriod _historyPeriod = AssetHistoryPeriod.oneYear;
  int _customYears = 1;
  bool isLoading = false;
  String? errorMessage;
  DashboardAssetData? data;

  AssetHistoryPeriod get historyPeriod => _historyPeriod;
  int get customYears => _customYears;

  DateTime _subtractMonths(DateTime from, int months) {
    final totalMonths = from.year * 12 + (from.month - 1) - months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, from.day.clamp(1, lastDay));
  }

  ({String strtDt, String endDt}) get historyRange {
    final now = DateTime.now();
    final endDt = _fmt(now);
    return switch (_historyPeriod) {
      AssetHistoryPeriod.threeMonths => (
          strtDt: _fmt(_subtractMonths(now, 3)),
          endDt: endDt,
        ),
      AssetHistoryPeriod.sixMonths => (
          strtDt: _fmt(_subtractMonths(now, 6)),
          endDt: endDt,
        ),
      AssetHistoryPeriod.oneYear => (
          strtDt: _fmt(DateTime(now.year - _customYears, now.month, now.day)),
          endDt: endDt,
        ),
    };
  }

  void selectHistoryPeriod(AssetHistoryPeriod period) {
    if (_historyPeriod == period) return;
    _historyPeriod = period;
    notifyListeners();
    load();
  }

  void selectCustomYears(int years) {
    _customYears = years;
    _historyPeriod = AssetHistoryPeriod.oneYear;
    notifyListeners();
    load();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayDt = _fmt(now);
      final prevYearDt = _fmt(DateTime(now.year - 1, now.month, now.day));
      final range = historyRange;

      final sumResults = Future.wait([
        MyAssetService.instance.getMyAssetSum(strtDt: todayDt, endDt: todayDt),
        MyAssetService.instance
            .getMyAssetSum(strtDt: prevYearDt, endDt: prevYearDt),
        MyAssetService.instance
            .getMyAssetSum(strtDt: range.strtDt, endDt: range.endDt),
      ]);
      final myAssetsFuture = MyAssetService.instance
          .getMyAssets(strtDt: todayDt, endDt: todayDt);

      final results = await sumResults;
      final myAssets = await myAssetsFuture;

      final todaySum = results[0];
      final prevYearSum = results[1];
      final sumHistory = results[2];

      final totalAsset = _sumAssets(todaySum);
      final debt = _sumDebt(todaySum);
      final netWorth = _netWorth(todaySum);
      final prevYearNetWorth = _netWorth(prevYearSum);
      final prevMonthNetWorth =
          _nearestNetWorth(sumHistory, _subtractMonths(now, 1));

      final assetHist = buildAssetHistory(sumHistory);

      data = DashboardAssetData(
        totalAsset: totalAsset,
        netWorth: netWorth,
        debt: debt,
        prevYearNetWorth: prevYearNetWorth,
        prevMonthNetWorth: prevMonthNetWorth,
        assetComposition: _buildComposition(todaySum),
        netWorthHistory: _buildNetWorthHistory(sumHistory),
        assetHistoryNames: assetHist.names,
        assetHistory: assetHist.history,
        debtItems: _buildDebtItems(myAssets),
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static int _sumAssets(List<MyAssetSumResponse> sums) => sums
      .where((s) => s.assetId != AssetIds.total && s.assetId != AssetIds.loan)
      .fold(0, (acc, s) => acc + s.sumPrice);

  static int _sumDebt(List<MyAssetSumResponse> sums) => sums
      .where((s) => s.assetId == AssetIds.loan)
      .fold(0, (acc, s) => acc + s.sumPrice);

  static int _netWorth(List<MyAssetSumResponse> sums) => sums
      .where((s) => s.assetId == AssetIds.total)
      .fold(0, (acc, s) => acc + s.sumPrice);

  static DateTime _parseDt(String s) => DateTime(
        int.parse(s.substring(0, 4)),
        int.parse(s.substring(4, 6)),
        s.length >= 8 ? int.parse(s.substring(6, 8)) : 1,
      );

  static int _monthIndex(DateTime d) => d.year * 12 + d.month;

  static int _nearestNetWorth(List<MyAssetSumResponse> sums, DateTime target) {
    final totals = sums.where((s) => s.assetId == AssetIds.total).toList();
    if (totals.isEmpty) return 0;
    final targetIdx = _monthIndex(target);
    totals.sort((a, b) => (_monthIndex(_parseDt(a.accumDt)) - targetIdx)
        .abs()
        .compareTo((_monthIndex(_parseDt(b.accumDt)) - targetIdx).abs()));
    return totals.first.sumPrice;
  }

  static List<DebtItem> _buildDebtItems(MyAssetListResponse myAssets) {
    final items = myAssets.data.values
        .expand((group) => group.allItems)
        .where((item) => item.assetId == AssetIds.loan)
        .map((item) => DebtItem(name: item.myAssetNm, amount: item.sumPrice))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  static List<AssetCompositionItem> _buildComposition(
    List<MyAssetSumResponse> sums,
  ) {
    final assets = sums
        .where((s) =>
            s.assetId != AssetIds.total &&
            s.assetId != AssetIds.loan &&
            s.sumPrice > 0)
        .toList();
    final total = assets.fold(0, (acc, s) => acc + s.sumPrice);
    if (total == 0) return [];
    return assets
        .map((s) => AssetCompositionItem(
              assetId: s.assetId,
              assetNm: s.assetNm,
              amount: s.sumPrice,
              ratio: s.sumPrice / total,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static ({
    List<({String id, String name})> names,
    List<({String date, Map<String, int> byAsset})> history,
  }) buildAssetHistory(List<MyAssetSumResponse> sums) {
    final filtered = sums
        .where((s) => s.assetId != AssetIds.total && s.assetId != AssetIds.loan)
        .toList();

    final names = <({String id, String name})>[];
    for (final s in filtered) {
      if (!names.any((n) => n.name == s.assetNm)) {
        names.add((id: s.assetId, name: s.assetNm));
      }
    }

    final dates = filtered.map((s) => s.accumDt).toSet().toList()..sort();

    final history = dates.map((date) {
      final byAsset = <String, int>{};
      for (final s in filtered.where((s) => s.accumDt == date)) {
        byAsset[s.assetNm] = s.sumPrice;
      }
      return (date: date, byAsset: byAsset);
    }).toList();

    return (names: names, history: history);
  }

  static List<({String date, int amount})> _buildNetWorthHistory(
    List<MyAssetSumResponse> sums,
  ) {
    final byDateNetWorth = <String, int>{};
    for (final s in sums) {
      if (s.assetId == AssetIds.total) {
        byDateNetWorth[s.accumDt] = s.sumPrice;
      }
    }
    final dates = byDateNetWorth.keys.toList()..sort();
    final todayStr = _fmt(DateTime.now());

    var lastKnown = 0;
    final result = <({String date, int amount})>[];
    for (final date in dates) {
      final amount = byDateNetWorth[date]!;
      if (date.compareTo(todayStr) <= 0 && amount != 0) {
        lastKnown = amount;
        result.add((date: date, amount: amount));
      } else if (date.compareTo(todayStr) > 0 &&
          amount == 0 &&
          lastKnown != 0) {
        result.add((date: date, amount: lastKnown));
      } else {
        result.add((date: date, amount: amount));
      }
    }
    return result;
  }

  static String _fmt(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
}
