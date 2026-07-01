import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarSummaryViewModel.combine', () {
    test('API가 반환하는 누적값을 일별 증분(delta)으로 변환해 day 기준으로 합친다', () {
      // sum-daily API는 월 누적 합계를 반환한다 (예: 1일 30000원, 3일 35000원 = 3일에 실제 5000원 지출).
      final result = CalendarSummaryViewModel.combine(
        income: [const DailyChartEntry(day: 1, price: 100000)],
        expense: [
          const DailyChartEntry(day: 1, price: 30000),
          const DailyChartEntry(day: 3, price: 35000),
        ],
        invest: [const DailyChartEntry(day: 1, price: 20000)],
      );

      expect(result[1]!.income, 100000);
      expect(result[1]!.expense, 30000);
      expect(result[1]!.invest, 20000);
      expect(result[3]!.income, 0);
      expect(result[3]!.expense, 5000);
      expect(result[3]!.invest, 0);
    });

    test('매일 같은 금액이 누적돼도 일별로는 동일한 증분으로 분리된다', () {
      final result = CalendarSummaryViewModel.combine(
        income: const [],
        expense: [
          const DailyChartEntry(day: 1, price: 5000),
          const DailyChartEntry(day: 2, price: 10000),
          const DailyChartEntry(day: 3, price: 15000),
        ],
        invest: const [],
      );

      expect(result[1]!.expense, 5000);
      expect(result[2]!.expense, 5000);
      expect(result[3]!.expense, 5000);
    });

    test('중간 날짜가 누락돼도 다음 항목이 누적분을 흡수한다', () {
      final result = CalendarSummaryViewModel.combine(
        income: const [],
        expense: [const DailyChartEntry(day: 5, price: 12000)],
        invest: const [],
      );

      expect(result[5]!.expense, 12000);
    });

    test('세 리스트 모두 비어있으면 빈 맵 반환', () {
      final result = CalendarSummaryViewModel.combine(
        income: const [],
        expense: const [],
        invest: const [],
      );
      expect(result, isEmpty);
    });
  });

  group('CalendarSummaryViewModel.setMonth', () {
    test('연/월 갱신 및 리스너 알림', () {
      final vm = CalendarSummaryViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      vm.setMonth(2026, 3);

      expect(vm.year, 2026);
      expect(vm.month, 3);
      expect(notified, true);
    });
  });

  group('CalendarSummaryViewModel.summaryFor', () {
    test('데이터 없는 날짜는 기본값(0/0/0) 반환', () {
      final vm = CalendarSummaryViewModel();
      final summary = vm.summaryFor(DateTime(2026, 7, 15));
      expect(summary.income, 0);
      expect(summary.expense, 0);
      expect(summary.invest, 0);
    });
  });
}
