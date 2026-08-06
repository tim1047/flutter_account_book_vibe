import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/features/analysis/division_summary_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

AccountListResponse _tx(String accountDt, int price) => AccountListResponse(
      seq: 1,
      accountId: 1,
      accountDt: accountDt,
      divisionId: '3',
      divisionNm: '',
      memberId: 'm1',
      memberNm: '',
      paymentId: 'p1',
      paymentNm: '',
      paymentType: '',
      categoryId: 'c1',
      categoryNm: '',
      categorySeq: '1',
      categorySeqNm: '',
      price: price,
      impulseYn: 'N',
      pointPrice: 0,
    );

void main() {
  group('DivisionSummaryViewModel.buildCategoryBreakdown', () {
    test('카테고리 비중 합계는 1.0 이하', () {
      final current = [
        const CategorySumResponse(
          categoryId: 'C1', categoryNm: '식비', divisionId: '3',
          sumPrice: 600, totalSumPrice: 1000, data: [],
        ),
        const CategorySumResponse(
          categoryId: 'C2', categoryNm: '교통', divisionId: '3',
          sumPrice: 400, totalSumPrice: 1000, data: [],
        ),
      ];
      final result = DivisionSummaryViewModel.buildCategoryBreakdown(current, []);
      final totalRatio = result.fold(0.0, (sum, e) => sum + e.ratio);
      expect(totalRatio, closeTo(1.0, 0.001));
    });

    test('전기간 대비 증가율 계산', () {
      final current = [
        const CategorySumResponse(
          categoryId: 'C1', categoryNm: '식비', divisionId: '1',
          sumPrice: 1200, totalSumPrice: 1200, data: [],
        ),
      ];
      final prev = [
        const CategorySumResponse(
          categoryId: 'C1', categoryNm: '식비', divisionId: '1',
          sumPrice: 1000, totalSumPrice: 1000, data: [],
        ),
      ];
      final result = DivisionSummaryViewModel.buildCategoryBreakdown(current, prev);
      expect(result.first.changeRate, closeTo(0.2, 0.001));
    });
  });

  group('DivisionSummaryViewModel.buildMonthlyTotals', () {
    test('accountDt 기준으로 월별 합산', () {
      final transactions = [
        _tx('20250101', 100),
        _tx('20250115', 200),
        _tx('20250201', 150),
      ];
      final result = DivisionSummaryViewModel.buildMonthlyTotals(
        transactions, '20250101', '20250228',
      );
      expect(result.length, 2);
      expect(result.firstWhere((e) => e.month == '202501').amount, 300);
      expect(result.firstWhere((e) => e.month == '202502').amount, 150);
    });
  });
}
