import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/data/services/division_service.dart';
import 'package:flutter/foundation.dart';

class CalendarDaySummary {
  const CalendarDaySummary({
    this.income = 0,
    this.expense = 0,
    this.invest = 0,
  });

  final int income;
  final int expense;
  final int invest;
}

class CalendarSummaryViewModel extends ChangeNotifier {
  CalendarSummaryViewModel()
      : _year = DateTime.now().year,
        _month = DateTime.now().month;

  int _year;
  int _month;
  Map<int, CalendarDaySummary> _byDay = {};

  bool isLoading = false;
  String? errorMessage;

  int get year => _year;
  int get month => _month;

  CalendarDaySummary summaryFor(DateTime day) =>
      _byDay[day.day] ?? const CalendarDaySummary();

  void setMonth(int year, int month) {
    _year = year;
    _month = month;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final strtDt = FormatUtil.toStrtDt(_year, _month);
      final endDt = FormatUtil.toEndDt(_year, _month);
      final results = await Future.wait([
        DivisionService.instance.getDivisionSumDaily(
          Division.income,
          strtDt: strtDt,
          endDt: endDt,
        ),
        DivisionService.instance.getDivisionSumDaily(
          Division.expense,
          strtDt: strtDt,
          endDt: endDt,
        ),
        DivisionService.instance.getDivisionSumDaily(
          Division.invest,
          strtDt: strtDt,
          endDt: endDt,
        ),
      ]);
      _byDay = combine(income: results[0], expense: results[1], invest: results[2]);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static Map<int, CalendarDaySummary> combine({
    required List<DailyChartEntry> income,
    required List<DailyChartEntry> expense,
    required List<DailyChartEntry> invest,
  }) {
    final incomeByDay = _dailyDeltas(income);
    final expenseByDay = _dailyDeltas(expense);
    final investByDay = _dailyDeltas(invest);
    final days = {...incomeByDay.keys, ...expenseByDay.keys, ...investByDay.keys};
    return {
      for (final day in days)
        day: CalendarDaySummary(
          income: incomeByDay[day] ?? 0,
          expense: expenseByDay[day] ?? 0,
          invest: investByDay[day] ?? 0,
        ),
    };
  }

  /// sum-daily API는 월 누적 합계를 반환하므로, 이전 항목과의 차이로 그날 하루치 금액을 구한다.
  static Map<int, int> _dailyDeltas(List<DailyChartEntry> cumulative) {
    final sorted = [...cumulative]..sort((a, b) => a.day.compareTo(b.day));
    final deltas = <int, int>{};
    var prevPrice = 0;
    for (final entry in sorted) {
      deltas[entry.day] = entry.price - prevPrice;
      prevPrice = entry.price;
    }
    return deltas;
  }
}
