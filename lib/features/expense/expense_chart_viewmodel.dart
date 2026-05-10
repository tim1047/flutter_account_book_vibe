import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/data/services/division_service.dart';
import 'package:flutter/foundation.dart';

class ExpenseChartViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  SumGroupByMonthResponse? monthlyData;

  /// 직전 3개월 일별 지출 데이터 (월 순서대로, 가장 오래된 달이 [0])
  List<MonthDailyData> monthlyDailyData = [];

  Future<void> loadMonthlyData(String procDt) async {
    _begin();
    try {
      monthlyData = await DivisionService.instance.getDivisionSumGroupByMonth(
        Division.expense,
        procDt: procDt,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      _end();
    }
  }

  /// [year]/[month]를 기준으로 직전 3개월 데이터를 병렬 조회합니다.
  Future<void> loadDailyData(int year, int month) async {
    _begin();
    try {
      final months = _buildThreeMonths(year, month);

      final results = await Future.wait(
        months.map(
          (ym) => DivisionService.instance.getDivisionSumDaily(
            Division.expense,
            strtDt: FormatUtil.toStrtDt(ym.$1, ym.$2),
            endDt: FormatUtil.toEndDt(ym.$1, ym.$2),
          ),
        ),
      );

      monthlyDailyData = [
        for (int i = 0; i < months.length; i++)
          MonthDailyData(
            year: months[i].$1,
            month: months[i].$2,
            entries: results[i],
          ),
      ];
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      _end();
    }
  }

  static List<(int, int)> _buildThreeMonths(int year, int month) {
    final result = <(int, int)>[];
    for (int i = 2; i >= 0; i--) {
      var m = month - i;
      var y = year;
      while (m <= 0) {
        m += 12;
        y--;
      }
      result.add((y, m));
    }
    return result;
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
