import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/models/member_model.dart';
import 'package:account_book_vibe/features/analysis/expense_summary_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseCategorySeqItem.changeRate', () {
    test('전기간 데이터 없으면 0', () {
      const item = ExpenseCategorySeqItem(
        categoryId: 'C1', categoryNm: '식비', categorySeq: 'S1',
        categorySeqNm: '외식', amount: 600, ratio: 0.6,
      );
      expect(item.changeRate, 0.0);
    });

    test('전기간 대비 증가율 계산', () {
      const item = ExpenseCategorySeqItem(
        categoryId: 'C1', categoryNm: '식비', categorySeq: 'S1',
        categorySeqNm: '외식', amount: 1200, ratio: 1.0, prevPeriodAmount: 1000,
      );
      expect(item.changeRate, closeTo(0.2, 0.001));
    });
  });

  group('buildCategorySeqBreakdown', () {
    test('categoryId/categorySeq가 원본 데이터에서 그대로 전달된다', () {
      const current = [
        CategorySumResponse(
          categoryId: 'C1', categoryNm: '식비', divisionId: '3',
          sumPrice: 1000, totalSumPrice: 1000,
          data: [CategorySeqItem(categorySeq: 'S1', categorySeqNm: '외식', sumPrice: 1000)],
        ),
      ];
      final result = buildExpenseCategorySeqBreakdown(current, const []);
      expect(result.single.categoryId, 'C1');
      expect(result.single.categorySeq, 'S1');
      expect(result.single.ratio, 1.0);
    });

    test('sumPrice가 0인 항목은 제외된다', () {
      const current = [
        CategorySumResponse(
          categoryId: 'C1', categoryNm: '식비', divisionId: '3',
          sumPrice: 1000, totalSumPrice: 1000,
          data: [
            CategorySeqItem(categorySeq: 'S1', categorySeqNm: '외식', sumPrice: 1000),
            CategorySeqItem(categorySeq: 'S2', categorySeqNm: '배달', sumPrice: 0),
          ],
        ),
      ];
      final result = buildExpenseCategorySeqBreakdown(current, const []);
      expect(result.length, 1);
      expect(result.single.categorySeq, 'S1');
    });
  });

  group('buildExpenseMemberBreakdown', () {
    test('sumPrice 내림차순 정렬 + ratio 합계 1.0', () {
      const members = [
        MemberSumResponse(memberId: 'm1', memberNm: '강원', sumPrice: 300),
        MemberSumResponse(memberId: 'm2', memberNm: '정윤', sumPrice: 700),
      ];
      final result = buildExpenseMemberBreakdown(members);
      expect(result.first.memberId, 'm2');
      expect(result.fold(0.0, (s, e) => s + e.ratio), closeTo(1.0, 0.001));
    });

    test('총합 0이면 빈 리스트', () {
      const members = [MemberSumResponse(memberId: 'm1', memberNm: '강원', sumPrice: 0)];
      expect(buildExpenseMemberBreakdown(members), isEmpty);
    });
  });
}
