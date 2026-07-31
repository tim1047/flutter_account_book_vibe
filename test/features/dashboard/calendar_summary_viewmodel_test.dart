import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarSummaryViewModel.combine', () {
    test('income/expense/invest의 일별 금액을 day 기준으로 합친다', () {
      // sum-daily API는 dailyAmount(일별 금액)를 이미 계산해서 반환한다.
      final result = CalendarSummaryViewModel.combine(
        income: [const DailyChartEntry(day: 1, price: 100000)],
        expense: [
          const DailyChartEntry(day: 1, price: 30000),
          const DailyChartEntry(day: 3, price: 5000),
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

    test('여러 날짜의 항목이 각각 독립적으로 매핑된다', () {
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
      expect(result[2]!.expense, 10000);
      expect(result[3]!.expense, 15000);
    });

    test('데이터가 없는 날짜는 결과 맵에 포함되지 않는다', () {
      final result = CalendarSummaryViewModel.combine(
        income: const [],
        expense: [const DailyChartEntry(day: 5, price: 12000)],
        invest: const [],
      );

      expect(result[5]!.expense, 12000);
      expect(result.containsKey(4), false);
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
