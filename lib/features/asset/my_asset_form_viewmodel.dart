import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/asset_model.dart';
import 'package:account_book_vibe/data/services/asset_service.dart';
import 'package:flutter/foundation.dart';

class MyAssetFormViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<AssetListResponse> assets = [];

  String? selectedAssetId;
  String priceDivCd = 'MANUAL';
  String exchangeRateYn = 'N';
  String cashableYn = 'N';

  bool get isAuto => priceDivCd == 'AUTO';

  Future<void> init({
    String? assetId,
    String? priceDivCd,
    String? exchangeRateYn,
    String? cashableYn,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      assets = await AssetService.instance.getAssets();
      if (assetId != null) {
        selectedAssetId = assetId;
        this.priceDivCd = priceDivCd ?? 'MANUAL';
        this.exchangeRateYn = exchangeRateYn ?? 'N';
        this.cashableYn = cashableYn ?? 'N';
      }
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void onAssetChanged(String assetId) {
    selectedAssetId = assetId;
    notifyListeners();
  }

  void onPriceDivCdChanged(String value) {
    priceDivCd = value;
    notifyListeners();
  }

  void onExchangeRateYnChanged(String value) {
    exchangeRateYn = value;
    notifyListeners();
  }

  void onCashableYnChanged(String value) {
    cashableYn = value;
    notifyListeners();
  }
}
