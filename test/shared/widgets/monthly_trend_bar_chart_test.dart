import 'package:account_book_vibe/shared/widgets/monthly_trend_bar_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyTrendBarChart.computeMaxY', () {
    test('실제 최댓값의 1.25배 반환 (평균 포함해서 비교)', () {
      expect(MonthlyTrendBarChart.computeMaxY([100, 200], 50), 250.0);
    });

    test('평균이 막대 최댓값보다 크면 평균 기준으로 계산', () {
      expect(MonthlyTrendBarChart.computeMaxY([100, 200], 400), 500.0);
    });

    test('전부 0이면 기본값 1,000,000 반환', () {
      expect(MonthlyTrendBarChart.computeMaxY([0, 0], 0), 1000000.0);
    });
  });
}
