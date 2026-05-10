import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/data/services/division_service.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  DivisionSumResponse? data;

  Future<void> load(String strtDt, String endDt) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      data = await DivisionService.instance.getDivisionSum(
        strtDt: strtDt,
        endDt: endDt,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
