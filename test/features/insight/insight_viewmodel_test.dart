// test/features/insight/insight_viewmodel_test.dart
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/features/insight/insight_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

// 테스트용 CategorySumResponse 생성 헬퍼
// CategorySumResponse 실제 필드: categoryId, categoryNm, divisionId,
//   sumPrice, totalSumPrice, data (divisionNm 없음)
CategorySumResponse _cat(String id, String nm, int price) =>
    CategorySumResponse(
      categoryId: id,
      categoryNm: nm,
      divisionId: '3',
      sumPrice: price,
      totalSumPrice: price,
      data: [],
    );

// 테스트용 AccountListResponse 생성 헬퍼
AccountListResponse _tx(String categoryId, int price) => AccountListResponse(
      seq: 1,
      accountId: 1,
      accountDt: '2025-05-01',
      divisionId: '3',
      divisionNm: '지출',
      memberId: '1',
      memberNm: '강원',
      paymentId: '1',
      paymentNm: '카드',
      paymentType: 'CARD',
      categoryId: categoryId,
      categoryNm: '외식',
      categorySeq: '1',
      categorySeqNm: '레스토랑',
      price: price,
      remark: null,
      impulseYn: 'N',
      pointPrice: 0,
    );

void main() {
  group('computeCategoryAnomalies', () {
    test('20% 초과 증가 카테고리를 감지한다', () {
      final current = [_cat('1', '외식', 387000)];
      final past = [
        [_cat('1', '외식', 270000)],
        [_cat('1', '외식', 280000)],
        [_cat('1', '외식', 266000)],
      ];

      final result = InsightViewModel.computeCategoryAnomalies(current, past);

      expect(result.length, 1);
      expect(result.first.categoryId, '1');
      expect(result.first.diffRate, greaterThan(0.20));
    });

    test('20% 초과 감소 카테고리를 감지한다', () {
      final current = [_cat('1', '교통', 54000)];
      final past = [
        [_cat('1', '교통', 89000)],
        [_cat('1', '교통', 91000)],
        [_cat('1', '교통', 85000)],
      ];

      final result = InsightViewModel.computeCategoryAnomalies(current, past);

      expect(result.length, 1);
      expect(result.first.diffRate, lessThan(-0.20));
    });

    test('20% 이하 차이는 무시한다', () {
      final current = [_cat('1', '마트', 110000)];
      final past = [
        [_cat('1', '마트', 100000)],
        [_cat('1', '마트', 100000)],
        [_cat('1', '마트', 100000)],
      ];

      final result = InsightViewModel.computeCategoryAnomalies(current, past);

      expect(result.isEmpty, true);
    });

    test('과거 데이터 없는 카테고리는 제외한다', () {
      final current = [_cat('99', '신규카테고리', 50000)];
      final past = [
        [_cat('1', '외식', 100000)],
        [_cat('1', '외식', 100000)],
        [_cat('1', '외식', 100000)],
      ];

      final result = InsightViewModel.computeCategoryAnomalies(current, past);

      expect(result.isEmpty, true);
    });

    test('최대 kMaxAnomalyItems개까지만 반환한다', () {
      final current = List.generate(
        10,
        (i) => _cat('$i', 'cat$i', 500000),
      );
      final past = List.generate(
        3,
        (_) => List.generate(10, (i) => _cat('$i', 'cat$i', 100000)),
      );

      final result = InsightViewModel.computeCategoryAnomalies(current, past);

      expect(result.length, lessThanOrEqualTo(kMaxCategoryAnomalyItems));
    });

    test('|diffRate| 내림차순으로 정렬된다', () {
      final current = [
        _cat('1', '외식', 200000), // +100%
        _cat('2', '카페', 160000), // +60%
      ];
      final past = [
        [_cat('1', '외식', 100000), _cat('2', '카페', 100000)],
        [_cat('1', '외식', 100000), _cat('2', '카페', 100000)],
        [_cat('1', '외식', 100000), _cat('2', '카페', 100000)],
      ];

      final result = InsightViewModel.computeCategoryAnomalies(current, past);

      expect(result.first.categoryId, '1');
    });
  });

  group('computeTransactionAnomalies', () {
    test('평균 단가의 3배 이상 거래를 감지한다', () {
      final pastTxs = List.generate(5, (_) => _tx('1', 38000));
      final currentTxs = [_tx('1', 142000)]; // 142000 / 38000 = 3.74배

      final result =
          InsightViewModel.computeTransactionAnomalies(currentTxs, pastTxs);

      expect(result.length, 1);
      expect(result.first.multiple, greaterThanOrEqualTo(3.0));
    });

    test('3배 미만 거래는 무시한다', () {
      final pastTxs = List.generate(5, (_) => _tx('1', 50000));
      final currentTxs = [_tx('1', 100000)]; // 2배

      final result =
          InsightViewModel.computeTransactionAnomalies(currentTxs, pastTxs);

      expect(result.isEmpty, true);
    });

    test('과거 거래가 1건뿐인 카테고리는 제외한다', () {
      final pastTxs = [_tx('1', 10000)]; // 1건만
      final currentTxs = [_tx('1', 100000)];

      final result =
          InsightViewModel.computeTransactionAnomalies(currentTxs, pastTxs);

      expect(result.isEmpty, true);
    });

    test('multiple 내림차순으로 정렬된다', () {
      final pastTxs = List.generate(4, (_) => _tx('1', 10000));
      final currentTxs = [
        _tx('1', 50000), // 5배
        _tx('1', 40000), // 4배
      ];

      final result =
          InsightViewModel.computeTransactionAnomalies(currentTxs, pastTxs);

      expect(result.first.multiple, greaterThan(result.last.multiple));
    });
  });
}
