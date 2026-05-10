import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/foundation.dart';

class DateFilterViewModel extends ChangeNotifier {
  static final DateFilterViewModel instance = DateFilterViewModel._();

  factory DateFilterViewModel() => instance;

  DateFilterViewModel._()
      : _year = DateTime.now().year,
        _month = DateTime.now().month;

  int _year;
  int _month; // 0 = 전체

  int get selectedYear => _year;
  int get selectedMonth => _month;

  String get strtDt => FormatUtil.toStrtDt(_year, _month);
  String get endDt => FormatUtil.toEndDt(_year, _month);

  void setYear(int year) {
    _year = year;
    notifyListeners();
  }

  void setMonth(int month) {
    _month = month;
    notifyListeners();
  }

  void goPrev() {
    if (_month == 0) {
      _year--;
    } else if (_month == 1) {
      _year--;
      _month = 12;
    } else {
      _month--;
    }
    notifyListeners();
  }

  void goNext() {
    if (_month == 0) {
      _year++;
    } else if (_month == 12) {
      _year++;
      _month = 1;
    } else {
      _month++;
    }
    notifyListeners();
  }

  void setToday() {
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    notifyListeners();
  }

  @override
  void dispose() {} // ignore: must_call_super
}
