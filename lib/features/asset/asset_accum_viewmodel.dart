import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:flutter/foundation.dart';

class AssetAccumViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<String> sortedDates = [];
  List<String> assetNames = [];

  // [accumDt][assetNm] -> sumPrice
  Map<String, Map<String, int>> dateAssetMap = {};

  Future<void> loadData() async {
    _begin();
    try {
      final now = DateTime.now();
      final endDt = _fmt(now);
      final strtDt = _fmt(now.subtract(const Duration(days: 120)));
      final items = await MyAssetService.instance.getMyAssetSum(
        strtDt: strtDt,
        endDt: endDt,
      );
      _process(items);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      _end();
    }
  }

  void _process(List<MyAssetSumResponse> items) {
    final filtered = items.where((e) => e.assetId != '0').toList();
    sortedDates =
        filtered.map((e) => e.accumDt).toSet().toList()..sort();

    final order = <String>[];
    for (final date in sortedDates) {
      for (final item in filtered.where((e) => e.accumDt == date)) {
        if (!order.contains(item.assetNm)) order.add(item.assetNm);
      }
    }
    assetNames = order;

    dateAssetMap = {};
    for (final item in filtered) {
      (dateAssetMap[item.accumDt] ??= {})[item.assetNm] = item.sumPrice;
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  void _begin() {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
  }

  void _end() {
    isLoading = false;
    notifyListeners();
  }
}
