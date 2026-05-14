import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/foundation.dart';

enum DashboardPeriod { thisMonth, thisQuarter, thisHalfYear, thisYear, custom }

class DashboardPeriodViewModel extends ChangeNotifier {
  DashboardPeriod _period = DashboardPeriod.thisYear;
  DateTime? _customStart;
  DateTime? _customEnd;

  DashboardPeriod get period => _period;

  String get label => switch (_period) {
        DashboardPeriod.thisMonth => '이번 달',
        DashboardPeriod.thisQuarter => '이번 분기',
        DashboardPeriod.thisHalfYear => '이번 반기',
        DashboardPeriod.thisYear => '올해',
        DashboardPeriod.custom => '커스텀',
      };

  DateTime? get customStart => _customStart;
  DateTime? get customEnd => _customEnd;

  String get customLabel {
    final start = _customStart;
    final end = _customEnd;
    if (start == null || end == null) return '커스텀';
    return '${start.year}.${start.month.toString().padLeft(2, '0')}~${end.year}.${end.month.toString().padLeft(2, '0')}';
  }

  ({String strtDt, String endDt}) get range {
    final now = DateTime.now();
    return switch (_period) {
      DashboardPeriod.thisMonth => (
          strtDt: FormatUtil.toStrtDt(now.year, now.month),
          endDt: FormatUtil.toEndDt(now.year, now.month),
        ),
      DashboardPeriod.thisQuarter => _quarterRange(now),
      DashboardPeriod.thisHalfYear => _halfYearRange(now),
      DashboardPeriod.thisYear => (
          strtDt: FormatUtil.toStrtDt(now.year, 0),
          endDt: FormatUtil.toEndDt(now.year, 0),
        ),
      DashboardPeriod.custom => (
          strtDt: _customStart != null
              ? _fmt(_customStart!)
              : FormatUtil.toStrtDt(now.year, 0),
          endDt: _customEnd != null
              ? _fmtEndOfMonth(_customEnd!)
              : FormatUtil.toEndDt(now.year, 0),
        ),
    };
  }

  String get changeLabel => switch (_period) {
        DashboardPeriod.thisMonth => '전달 대비',
        DashboardPeriod.thisQuarter => '전 분기 대비',
        DashboardPeriod.thisHalfYear => '전 반기 대비',
        DashboardPeriod.thisYear => '전년 대비',
        DashboardPeriod.custom => _customChangeLabel(),
      };

  ({String strtDt, String endDt}) get prevRange {
    final now = DateTime.now();
    return switch (_period) {
      DashboardPeriod.thisMonth => _prevMonthRange(now),
      DashboardPeriod.thisQuarter => _prevQuarterRange(now),
      DashboardPeriod.thisHalfYear => _prevHalfYearRange(now),
      DashboardPeriod.thisYear => (
          strtDt: FormatUtil.toStrtDt(now.year - 1, 0),
          endDt: FormatUtil.toEndDt(now.year - 1, 0),
        ),
      DashboardPeriod.custom => _prevCustomRange(),
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

  ({String strtDt, String endDt}) _prevMonthRange(DateTime now) {
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    return (
      strtDt: FormatUtil.toStrtDt(prevMonth.year, prevMonth.month),
      endDt: FormatUtil.toEndDt(prevMonth.year, prevMonth.month),
    );
  }

  ({String strtDt, String endDt}) _prevQuarterRange(DateTime now) {
    final q = (now.month - 1) ~/ 3;
    if (q > 0) {
      final startMonth = (q - 1) * 3 + 1;
      return (
        strtDt: FormatUtil.toStrtDt(now.year, startMonth),
        endDt: FormatUtil.toEndDt(now.year, startMonth + 2),
      );
    }
    // Q1 → 전년 Q4 (10~12월)
    return (
      strtDt: FormatUtil.toStrtDt(now.year - 1, 10),
      endDt: FormatUtil.toEndDt(now.year - 1, 12),
    );
  }

  ({String strtDt, String endDt}) _halfYearRange(DateTime now) {
    final isH1 = now.month <= 6;
    return isH1
        ? (strtDt: FormatUtil.toStrtDt(now.year, 1), endDt: FormatUtil.toEndDt(now.year, 6))
        : (strtDt: FormatUtil.toStrtDt(now.year, 7), endDt: FormatUtil.toEndDt(now.year, 12));
  }

  ({String strtDt, String endDt}) _prevHalfYearRange(DateTime now) {
    final isH1 = now.month <= 6;
    return isH1
        // 상반기 → 전년 하반기
        ? (strtDt: FormatUtil.toStrtDt(now.year - 1, 7), endDt: FormatUtil.toEndDt(now.year - 1, 12))
        // 하반기 → 올해 상반기
        : (strtDt: FormatUtil.toStrtDt(now.year, 1), endDt: FormatUtil.toEndDt(now.year, 6));
  }

  ({String strtDt, String endDt}) _prevCustomRange() {
    final now = DateTime.now();
    final start = _customStart ?? DateTime(now.year, 1, 1);
    final end = _customEnd ?? now;
    final monthCount =
        (end.year - start.year) * 12 + end.month - start.month + 1;
    // 직전 기간 종료 = 시작월 바로 전달
    final prevEnd = DateTime(start.year, start.month - 1, 1);
    // 직전 기간 시작 = prevEnd에서 (monthCount-1)개월 이전
    final prevStart =
        DateTime(prevEnd.year, prevEnd.month - (monthCount - 1), 1);
    return (
      strtDt: FormatUtil.toStrtDt(prevStart.year, prevStart.month),
      endDt: FormatUtil.toEndDt(prevEnd.year, prevEnd.month),
    );
  }

  String _customChangeLabel() {
    final prev = prevRange;
    final sY = prev.strtDt.substring(0, 4);
    final sM = int.parse(prev.strtDt.substring(4, 6)).toString();
    final eY = prev.endDt.substring(0, 4);
    final eM = int.parse(prev.endDt.substring(4, 6)).toString();
    return '$sY.$sM~$eY.$eM 대비';
  }

  String _fmt(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  String _fmtEndOfMonth(DateTime dt) {
    final lastDay = DateTime(dt.year, dt.month + 1, 0);
    return '${lastDay.year}${lastDay.month.toString().padLeft(2, '0')}${lastDay.day.toString().padLeft(2, '0')}';
  }
}
