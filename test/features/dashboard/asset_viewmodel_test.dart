// test/features/dashboard/asset_viewmodel_test.dart
import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardAssetViewModel', () {
    test('기본 historyPeriod는 oneYear', () {
      final vm = DashboardAssetViewModel();
      expect(vm.historyPeriod, AssetHistoryPeriod.oneYear);
    });

    test('historyRange oneYear: 1년 전 ~ 오늘', () {
      final vm = DashboardAssetViewModel();
      final now = DateTime.now();
      final range = vm.historyRange;
      final expectedStart =
          '${now.year - 1}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final expectedEnd =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      expect(range.strtDt, expectedStart);
      expect(range.endDt, expectedEnd);
    });

    test('historyRange threeMonths: 3개월 전 ~ 오늘', () {
      final vm = DashboardAssetViewModel();
      vm.selectHistoryPeriod(AssetHistoryPeriod.threeMonths);
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      final expectedStart =
          '${threeMonthsAgo.year}${threeMonthsAgo.month.toString().padLeft(2, '0')}${threeMonthsAgo.day.toString().padLeft(2, '0')}';
      expect(vm.historyRange.strtDt, expectedStart);
    });

    test('historyRange sixMonths: 6개월 전 ~ 오늘', () {
      final vm = DashboardAssetViewModel();
      vm.selectHistoryPeriod(AssetHistoryPeriod.sixMonths);
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
      final expectedStart =
          '${sixMonthsAgo.year}${sixMonthsAgo.month.toString().padLeft(2, '0')}${sixMonthsAgo.day.toString().padLeft(2, '0')}';
      expect(vm.historyRange.strtDt, expectedStart);
    });

    test('selectHistoryPeriod 호출 시 notifyListeners 발생', () {
      final vm = DashboardAssetViewModel();
      var notified = false;
      vm.addListener(() => notified = true);
      vm.selectHistoryPeriod(AssetHistoryPeriod.threeMonths);
      expect(notified, true);
    });

    test('selectHistoryPeriod 호출 후 historyPeriod 갱신', () {
      final vm = DashboardAssetViewModel();
      vm.selectHistoryPeriod(AssetHistoryPeriod.sixMonths);
      expect(vm.historyPeriod, AssetHistoryPeriod.sixMonths);
    });
  });
}
