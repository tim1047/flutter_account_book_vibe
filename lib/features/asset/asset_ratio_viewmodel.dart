import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:flutter/foundation.dart';

class AssetRatioViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  MyAssetListResponse? data;

  Future<void> loadData() async {
    _begin();
    try {
      final now = DateTime.now();
      final dt =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      data = await MyAssetService.instance.getMyAssets(strtDt: dt, endDt: dt);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      _end();
    }
  }

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
