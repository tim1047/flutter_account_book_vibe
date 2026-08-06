import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DivisionCategoryItem.changeRate', () {
    test('전기간 데이터 없으면 0', () {
      const item = DivisionCategoryItem(
        categoryId: 'C1', categoryNm: '식비', amount: 600, ratio: 0.6,
      );
      expect(item.changeRate, 0.0);
    });

    test('전기간 대비 증가율 계산', () {
      const item = DivisionCategoryItem(
        categoryId: 'C1', categoryNm: '식비', amount: 1200, ratio: 1.0,
        prevPeriodAmount: 1000,
      );
      expect(item.changeRate, closeTo(0.2, 0.001));
    });
  });

  group('DivisionSummaryData.changeRate', () {
    test('전기간 금액 0이면 0', () {
      const data = DivisionSummaryData(
        totalAmount: 500, prevPeriodAmount: 0, monthlyAmounts: [],
        categoryBreakdown: [], changeLabel: '전달 대비',
      );
      expect(data.changeRate, 0.0);
    });

    test('전기간 대비 증가율 계산', () {
      const data = DivisionSummaryData(
        totalAmount: 1200, prevPeriodAmount: 1000, monthlyAmounts: [],
        categoryBreakdown: [], changeLabel: '전달 대비',
      );
      expect(data.changeRate, closeTo(0.2, 0.001));
    });
  });
}
