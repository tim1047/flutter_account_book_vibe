import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/data/services/division_service.dart';
import 'package:flutter/foundation.dart';

class IncomeChartViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  SumGroupByMonthResponse? monthlyData;

  Future<void> loadMonthlyData(String procDt) async {
    _begin();
    try {
      monthlyData = await DivisionService.instance.getDivisionSumGroupByMonth(
        Division.income,
        procDt: procDt,
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
