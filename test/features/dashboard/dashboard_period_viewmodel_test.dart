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

    test('thisQuarter range는 분기 시작월~끝월', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisQuarter);
      final now = DateTime.now();
      final q = ((now.month - 1) ~/ 3);
      final startMonth = (q * 3 + 1).toString().padLeft(2, '0');
      expect(vm.range.strtDt.substring(4, 6), startMonth);
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
  });
}
