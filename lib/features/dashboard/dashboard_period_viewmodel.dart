import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/foundation.dart';

enum DashboardPeriod { thisMonth, thisQuarter, thisYear, custom }

class DashboardPeriodViewModel extends ChangeNotifier {
  DashboardPeriod _period = DashboardPeriod.thisYear;
  DateTime? _customStart;
  DateTime? _customEnd;

  DashboardPeriod get period => _period;

  String get label => switch (_period) {
        DashboardPeriod.thisMonth => '이번 달',
        DashboardPeriod.thisQuarter => '이번 분기',
        DashboardPeriod.thisYear => '올해',
        DashboardPeriod.custom => '커스텀',
      };

  ({String strtDt, String endDt}) get range {
    final now = DateTime.now();
    return switch (_period) {
      DashboardPeriod.thisMonth => (
          strtDt: FormatUtil.toStrtDt(now.year, now.month),
          endDt: FormatUtil.toEndDt(now.year, now.month),
        ),
      DashboardPeriod.thisQuarter => _quarterRange(now),
      DashboardPeriod.thisYear => (
          strtDt: FormatUtil.toStrtDt(now.year, 0),
          endDt: FormatUtil.toEndDt(now.year, 0),
        ),
      DashboardPeriod.custom => (
          strtDt: _customStart != null
              ? _fmt(_customStart!)
              : FormatUtil.toStrtDt(now.year, 0),
          endDt: _customEnd != null
              ? _fmt(_customEnd!)
              : FormatUtil.toEndDt(now.year, 0),
        ),
    };
  }

  void select(DashboardPeriod period) {
    _period = period;
    notifyListeners();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _customStart = start;
    _customEnd = end;
    _period = DashboardPeriod.custom;
    notifyListeners();
  }

  ({String strtDt, String endDt}) _quarterRange(DateTime now) {
    final q = (now.month - 1) ~/ 3;
    final startMonth = q * 3 + 1;
    final endMonth = startMonth + 2;
    return (
      strtDt: FormatUtil.toStrtDt(now.year, startMonth),
      endDt: FormatUtil.toEndDt(now.year, endMonth),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
}
