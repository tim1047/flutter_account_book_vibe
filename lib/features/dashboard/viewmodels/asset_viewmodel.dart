import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

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
    required this.assetGroups,
  });

  final int totalAsset;
  final int netWorth;
  final int prevYearNetWorth;
  final List<AssetCompositionItem> assetComposition;
  final List<({String date, int amount})> netWorthHistory;
  final List<MyAssetGroupResponse> assetGroups;

  int get debt => totalAsset - netWorth;
  int get yearlyGrowth => netWorth - prevYearNetWorth;
}

class DashboardAssetViewModel extends ChangeNotifier {
  DashboardAssetViewModel(this._period) {
    _period.addListener(load);
  }

  final DashboardPeriodViewModel _period;
  bool isLoading = false;
  String? errorMessage;
  DashboardAssetData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayDt =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final prevYearDt =
          '${now.year - 1}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final range = _period.range;

      final results = await Future.wait([
        MyAssetService.instance.getMyAssets(strtDt: todayDt, endDt: todayDt),
        MyAssetService.instance
            .getMyAssets(strtDt: prevYearDt, endDt: prevYearDt),
        MyAssetService.instance
            .getMyAssetSum(strtDt: range.strtDt, endDt: range.endDt),
      ]);

      final current = results[0] as MyAssetListResponse;
      final prevYear = results[1] as MyAssetListResponse;
      final sumHistory = results[2] as List<MyAssetSumResponse>;

      data = DashboardAssetData(
        totalAsset: current.totSumPrice,
        netWorth: current.totNetWorthSumPrice,
        prevYearNetWorth: prevYear.totNetWorthSumPrice,
        assetComposition: _buildComposition(current),
        netWorthHistory: _buildNetWorthHistory(sumHistory),
        assetGroups: current.data.values.toList(),
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static List<AssetCompositionItem> _buildComposition(
    MyAssetListResponse resp,
  ) {
    final total = resp.totSumPrice;
    if (total == 0) return [];
    return resp.data.values
        .where((g) => g.assetTotSumPrice > 0)
        .map((g) => AssetCompositionItem(
              assetNm: g.assetNm,
              amount: g.assetTotSumPrice,
              ratio: g.assetTotSumPrice / total,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
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
