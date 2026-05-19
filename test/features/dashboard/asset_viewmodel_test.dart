// test/features/dashboard/asset_viewmodel_test.dart
import 'package:account_book_vibe/data/models/my_asset_model.dart';
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
      final threeMonthsAgo = () {
        final totalMonths = now.year * 12 + (now.month - 1) - 3;
        final y = totalMonths ~/ 12;
        final m = totalMonths % 12 + 1;
        final lastDay = DateTime(y, m + 1, 0).day;
        return DateTime(y, m, now.day.clamp(1, lastDay));
      }();
      final expectedStart =
          '${threeMonthsAgo.year}${threeMonthsAgo.month.toString().padLeft(2, '0')}${threeMonthsAgo.day.toString().padLeft(2, '0')}';
      expect(vm.historyRange.strtDt, expectedStart);
    });

    test('historyRange sixMonths: 6개월 전 ~ 오늘', () {
      final vm = DashboardAssetViewModel();
      vm.selectHistoryPeriod(AssetHistoryPeriod.sixMonths);
      final now = DateTime.now();
      final sixMonthsAgo = () {
        final totalMonths = now.year * 12 + (now.month - 1) - 6;
        final y = totalMonths ~/ 12;
        final m = totalMonths % 12 + 1;
        final lastDay = DateTime(y, m + 1, 0).day;
        return DateTime(y, m, now.day.clamp(1, lastDay));
      }();
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

  group('DashboardAssetViewModel.buildAssetHistory', () {
    test('assetId 0과 6은 필터링됨', () {
      final sums = [
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '0', assetNm: '합계', sumPrice: 300),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '6', assetNm: '부채', sumPrice: 50),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '1', assetNm: '주식', sumPrice: 100),
      ];
      final result = DashboardAssetViewModel.buildAssetHistory(sums);
      expect(result.names, ['주식']);
      expect(result.history.length, 1);
      expect(result.history.first.byAsset.containsKey('합계'), false);
      expect(result.history.first.byAsset.containsKey('부채'), false);
    });

    test('자산명 순서는 첫 등장 순 유지', () {
      final sums = [
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '1', assetNm: '주식', sumPrice: 100),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '2', assetNm: '예금', sumPrice: 200),
        const MyAssetSumResponse(
            accumDt: '20250201', assetId: '2', assetNm: '예금', sumPrice: 210),
        const MyAssetSumResponse(
            accumDt: '20250201', assetId: '1', assetNm: '주식', sumPrice: 110),
      ];
      final result = DashboardAssetViewModel.buildAssetHistory(sums);
      expect(result.names, ['주식', '예금']);
    });

    test('날짜별 byAsset 그룹핑 + 날짜 정렬', () {
      final sums = [
        const MyAssetSumResponse(
            accumDt: '20250201', assetId: '1', assetNm: '주식', sumPrice: 150),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '1', assetNm: '주식', sumPrice: 100),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '2', assetNm: '예금', sumPrice: 200),
      ];
      final result = DashboardAssetViewModel.buildAssetHistory(sums);
      expect(result.history.length, 2);
      expect(result.history[0].date, '20250101');
      expect(result.history[0].byAsset['주식'], 100);
      expect(result.history[0].byAsset['예금'], 200);
      expect(result.history[1].date, '20250201');
      expect(result.history[1].byAsset['주식'], 150);
    });

    test('빈 입력 → 빈 결과', () {
      final result = DashboardAssetViewModel.buildAssetHistory([]);
      expect(result.names, isEmpty);
      expect(result.history, isEmpty);
    });
  });
}
