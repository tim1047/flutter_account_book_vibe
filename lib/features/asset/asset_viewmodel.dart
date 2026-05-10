import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:flutter/foundation.dart';

class AssetViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  MyAssetListResponse? assetData;

  String? _strtDt;
  String? _endDt;

  Future<void> loadAssets({String? strtDt, String? endDt}) async {
    if (strtDt != null) _strtDt = strtDt;
    if (endDt != null) _endDt = endDt;
    _begin();
    try {
      assetData = await MyAssetService.instance.getMyAssets(
        strtDt: _strtDt,
        endDt: _endDt,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      _end();
    }
  }

  Future<void> refreshAssets(String procDt) async {
    _begin();
    try {
      assetData = await MyAssetService.instance.refreshMyAsset(procDt);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      _end();
    }
  }

  Future<bool> deleteMyAsset(String myAssetId) async {
    try {
      await MyAssetService.instance.deleteMyAsset(myAssetId);
      await loadAssets();
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
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
