import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:flutter/foundation.dart';

class IncomeViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<CategorySumResponse> categorySumList = [];

  Future<void> loadCategorySum(String strtDt, String endDt) async {
    _begin();
    try {
      categorySumList = await CategoryService.instance.getCategorySum(
        divisionId: Division.income,
        strtDt: strtDt,
        endDt: endDt,
      );
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
