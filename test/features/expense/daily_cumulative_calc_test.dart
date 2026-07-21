import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/expense/expense_daily_chart_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const entries = [
    DailyChartEntry(day: 1, price: 1000),
    DailyChartEntry(day: 3, price: 2000),
    DailyChartEntry(day: 10, price: 500),
  ];

  group('DailyCumulativeCalc.cumulativeUpTo', () {
    test('특정 일자까지만 누적', () {
      expect(DailyCumulativeCalc.cumulativeUpTo(entries, 3), 3000);
    });

    test('데이터에 없는 날짜여도 그 이전까지 누적', () {
      expect(DailyCumulativeCalc.cumulativeUpTo(entries, 5), 3000);
    });

    test('전체 일수 이상을 넣으면 전체 합계와 같음', () {
      expect(DailyCumulativeCalc.cumulativeUpTo(entries, 31), 3500);
    });
  });

  group('DailyCumulativeCalc.buildCumulativeSpots', () {
    test('날짜순 누적 스팟 생성', () {
      final spots = DailyCumulativeCalc.buildCumulativeSpots(entries);
      expect(spots.map((s) => s.x), [1.0, 3.0, 10.0]);
      expect(spots.map((s) => s.y), [1000.0, 3000.0, 3500.0]);
    });
  });

  group('DailyCumulativeCalc.referenceDay', () {
    test('실제 이번달이면 오늘 날짜 반환', () {
      final now = DateTime(2026, 7, 21);
      expect(DailyCumulativeCalc.referenceDay(2026, 7, now: now), 21);
    });

    test('과거 월이면 그 달의 마지막 날 반환', () {
      final now = DateTime(2026, 7, 21);
      expect(DailyCumulativeCalc.referenceDay(2026, 5, now: now), 31);
    });

    test('12월처럼 달 경계를 넘어가도 마지막 날 정확히 계산 (연도 롤오버)', () {
      final now = DateTime(2026, 7, 21);
      expect(DailyCumulativeCalc.referenceDay(2026, 12, now: now), 31);
    });
  });
}
