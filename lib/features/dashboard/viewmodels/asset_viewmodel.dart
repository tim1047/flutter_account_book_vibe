// lib/features/dashboard/viewmodels/asset_viewmodel.dart
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:flutter/foundation.dart';

enum AssetHistoryPeriod { threeMonths, sixMonths, oneYear }

class AssetCompositionItem {
  const AssetCompositionItem({
    required this.assetNm,
    required this.amount,
    required this.ratio,
  });

  final String assetNm;
  final int amount;
  final double ratio;
}

class DashboardAssetData {
  const DashboardAssetData({
    required this.totalAsset,
    required this.netWorth,
    required this.prevYearNetWorth,
    required this.assetComposition,
    required this.netWorthHistory,
    required this.assetHistoryNames,
    required this.assetHistory,
  });

  final int totalAsset;
  final int netWorth;
  final int prevYearNetWorth;
  final List<AssetCompositionItem> assetComposition;
  final List<({String date, int amount})> netWorthHistory;
  final List<String> assetHistoryNames;
  final List<({String date, Map<String, int> byAsset})> assetHistory;

  int get debt => totalAsset - netWorth;
  int get yearlyGrowth => netWorth - prevYearNetWorth;
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

      final results = await Future.wait([
        MyAssetService.instance.getMyAssetSum(strtDt: todayDt, endDt: todayDt),
        MyAssetService.instance
            .getMyAssetSum(strtDt: prevYearDt, endDt: prevYearDt),
        MyAssetService.instance
            .getMyAssetSum(strtDt: range.strtDt, endDt: range.endDt),
      ]);

      final todaySum = results[0];
      final prevYearSum = results[1];
      final sumHistory = results[2];

      final totalAsset = _sumAssets(todaySum);
      final debt = _sumDebt(todaySum);
      final netWorth = totalAsset - debt;

      final prevTotalAsset = _sumAssets(prevYearSum);
      final prevDebt = _sumDebt(prevYearSum);
      final prevYearNetWorth = prevTotalAsset - prevDebt;

      final assetHist = buildAssetHistory(sumHistory);

      data = DashboardAssetData(
        totalAsset: totalAsset,
        netWorth: netWorth,
        prevYearNetWorth: prevYearNetWorth,
        assetComposition: _buildComposition(todaySum),
        netWorthHistory: _buildNetWorthHistory(sumHistory),
        assetHistoryNames: assetHist.names,
        assetHistory: assetHist.history,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static int _sumAssets(List<MyAssetSumResponse> sums) => sums
      .where((s) => s.assetId != '0' && s.assetId != '6')
      .fold(0, (acc, s) => acc + s.sumPrice);

  static int _sumDebt(List<MyAssetSumResponse> sums) => sums
      .where((s) => s.assetId == '6')
      .fold(0, (acc, s) => acc + s.sumPrice);

  static List<AssetCompositionItem> _buildComposition(
    List<MyAssetSumResponse> sums,
  ) {
    final assets = sums
        .where((s) => s.assetId != '0' && s.assetId != '6' && s.sumPrice > 0)
        .toList();
    final total = assets.fold(0, (acc, s) => acc + s.sumPrice);
    if (total == 0) return [];
    return assets
        .map((s) => AssetCompositionItem(
              assetNm: s.assetNm,
              amount: s.sumPrice,
              ratio: s.sumPrice / total,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static ({
    List<String> names,
    List<({String date, Map<String, int> byAsset})> history,
  }) buildAssetHistory(List<MyAssetSumResponse> sums) {
    final filtered =
        sums.where((s) => s.assetId != '0' && s.assetId != '6').toList();

    final names = <String>[];
    for (final s in filtered) {
      if (!names.contains(s.assetNm)) names.add(s.assetNm);
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
    final todayStr = _fmt(DateTime.now());

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

  static String _fmt(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
}
