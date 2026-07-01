import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardPeriodViewModel', () {
    test('기본값은 thisYear', () {
      final vm = DashboardPeriodViewModel();
      expect(vm.period, DashboardPeriod.thisYear);
    });

    test('thisMonth range는 이번달 첫날~마지막날', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisMonth);
      final now = DateTime.now();
      final y = now.year.toString();
      final m = now.month.toString().padLeft(2, '0');
      expect(vm.range.strtDt, '${y}${m}01');
      expect(vm.range.endDt.substring(0, 6), '$y$m');
    });

    test('thisYear range는 연도 0101 ~ 1231', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisYear);
      final y = DateTime.now().year.toString();
      expect(vm.range.strtDt, '${y}0101');
      expect(vm.range.endDt, '${y}1231');
    });

    test('thisQuarter label은 직전 3개월', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisQuarter);
      expect(vm.label, '직전 3개월');
    });

    test('thisQuarter range는 당월 포함 최근 3개월 rolling', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisQuarter);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month - 2, 1);
      expect(
        vm.range.strtDt,
        '${start.year}${start.month.toString().padLeft(2, '0')}01',
      );
      expect(
        vm.range.endDt.substring(0, 6),
        '${now.year}${now.month.toString().padLeft(2, '0')}',
      );
    });

    test('thisQuarter prevRange는 그 이전 3개월', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisQuarter);
      final now = DateTime.now();
      final prevEnd = DateTime(now.year, now.month - 3, 1);
      final prevStart = DateTime(now.year, now.month - 5, 1);
      final lastDay = DateTime(prevEnd.year, prevEnd.month + 1, 0).day;
      expect(
        vm.prevRange.strtDt,
        '${prevStart.year}${prevStart.month.toString().padLeft(2, '0')}01',
      );
      expect(
        vm.prevRange.endDt,
        '${prevEnd.year}${prevEnd.month.toString().padLeft(2, '0')}${lastDay.toString().padLeft(2, '0')}',
      );
    });

    test('thisQuarter changeLabel은 전 3개월 대비', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisQuarter);
      expect(vm.changeLabel, '전 3개월 대비');
    });

    test('thisHalfYear label은 직전 6개월', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisHalfYear);
      expect(vm.label, '직전 6개월');
    });

    test('thisHalfYear range는 당월 포함 최근 6개월 rolling', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisHalfYear);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month - 5, 1);
      expect(
        vm.range.strtDt,
        '${start.year}${start.month.toString().padLeft(2, '0')}01',
      );
      expect(
        vm.range.endDt.substring(0, 6),
        '${now.year}${now.month.toString().padLeft(2, '0')}',
      );
    });

    test('thisHalfYear prevRange는 그 이전 6개월', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisHalfYear);
      final now = DateTime.now();
      final prevEnd = DateTime(now.year, now.month - 6, 1);
      final prevStart = DateTime(now.year, now.month - 11, 1);
      final lastDay = DateTime(prevEnd.year, prevEnd.month + 1, 0).day;
      expect(
        vm.prevRange.strtDt,
        '${prevStart.year}${prevStart.month.toString().padLeft(2, '0')}01',
      );
      expect(
        vm.prevRange.endDt,
        '${prevEnd.year}${prevEnd.month.toString().padLeft(2, '0')}${lastDay.toString().padLeft(2, '0')}',
      );
    });

    test('thisHalfYear changeLabel은 전 6개월 대비', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisHalfYear);
      expect(vm.changeLabel, '전 6개월 대비');
    });

    test('setCustomRange는 custom 기간으로 전환', () {
      final vm = DashboardPeriodViewModel();
      final start = DateTime(2025, 3, 1);
      final end = DateTime(2025, 5, 31);
      vm.setCustomRange(start, end);
      expect(vm.period, DashboardPeriod.custom);
      expect(vm.range.strtDt, '20250301');
      expect(vm.range.endDt, '20250531');
    });

    test('select 호출 시 notifyListeners 발생', () {
      final vm = DashboardPeriodViewModel();
      var notified = false;
      vm.addListener(() => notified = true);
      vm.select(DashboardPeriod.thisMonth);
      expect(notified, true);
    });

    test('커스텀 날짜 미선택 시 customLabel은 커스텀', () {
      final vm = DashboardPeriodViewModel();
      expect(vm.customLabel, '커스텀');
    });

    test('setCustomRange 후 customLabel은 M/D~M/D 형식', () {
      final vm = DashboardPeriodViewModel();
      vm.setCustomRange(DateTime(2025, 3, 1), DateTime(2025, 5, 31));
      expect(vm.customLabel, '3/1~5/31');
    });
  });
}
