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
    final incomeByDay = {for (final e in income) e.day: e.price};
    final expenseByDay = {for (final e in expense) e.day: e.price};
    final investByDay = {for (final e in invest) e.day: e.price};
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
}
