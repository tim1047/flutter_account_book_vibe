import 'package:account_book_vibe/features/dashboard/viewmodels/expense_viewmodel.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardExpenseViewModel.buildCategoryBreakdown', () {
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
      final result = DashboardExpenseViewModel.buildCategoryBreakdown(current, []);
      final totalRatio = result.fold(0.0, (sum, e) => sum + e.ratio);
      expect(totalRatio, closeTo(1.0, 0.001));
    });

    test('전월 데이터 없으면 changeRate = 0', () {
      final current = [
        const CategorySumResponse(
          categoryId: 'C1', categoryNm: '식비', divisionId: '3',
          sumPrice: 600, totalSumPrice: 600, data: [],
        ),
      ];
      final result = DashboardExpenseViewModel.buildCategoryBreakdown(current, []);
      expect(result.first.changeRate, 0.0);
    });

    test('전월 대비 증가율 계산', () {
      final current = [
        const CategorySumResponse(
          categoryId: 'C1', categoryNm: '식비', divisionId: '3',
          sumPrice: 1200, totalSumPrice: 1200, data: [],
        ),
      ];
      final prev = [
        const CategorySumResponse(
          categoryId: 'C1', categoryNm: '식비', divisionId: '3',
          sumPrice: 1000, totalSumPrice: 1000, data: [],
        ),
      ];
      final result = DashboardExpenseViewModel.buildCategoryBreakdown(current, prev);
      expect(result.first.changeRate, closeTo(0.2, 0.001));
    });
  });

  group('DashboardExpenseViewModel.buildMonthlyTotals', () {
    test('accountDt 기준으로 월별 합산', () {
      final transactions = _makeAccounts([
        ('20250101', 100),
        ('20250115', 200),
        ('20250201', 150),
      ]);
      final result = DashboardExpenseViewModel.buildMonthlyTotals(
        transactions, '20250101', '20250228',
      );
      expect(result.length, 2);
      expect(result.firstWhere((e) => e.month == '202501').amount, 300);
      expect(result.firstWhere((e) => e.month == '202502').amount, 150);
    });
  });
}

List<dynamic> _makeAccounts(List<(String, int)> data) {
  return data.map((e) => _FakeAccount(e.$1, e.$2)).toList();
}

class _FakeAccount {
  final String accountDt;
  final int price;
  const _FakeAccount(this.accountDt, this.price);
}
