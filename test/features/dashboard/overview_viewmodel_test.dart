import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardOverviewViewModel.aggregate', () {
    test('저축액 = 수입 - 지출', () {
      const data = DashboardOverviewData(
        netWorth: 100000000,
        prevMonthNetWorth: 99000000,
        totalIncome: 4000000,
        totalExpense: 3160000,
        totalInvest: 500000,
        topExpenseCategories: [],
        recentTransactions: [],
        netWorthHistory: [],
      );
      expect(data.savings, 840000);
    });

    test('순자산 변화 = 현재 - 전월', () {
      const data = DashboardOverviewData(
        netWorth: 100000000,
        prevMonthNetWorth: 99000000,
        totalIncome: 0,
        totalExpense: 0,
        totalInvest: 0,
        topExpenseCategories: [],
        recentTransactions: [],
        netWorthHistory: [],
      );
      expect(data.netWorthChange, 1000000);
    });

    test('buildTopCategories: 합계 기준 내림차순 TOP 5', () {
      final sums = [
        const CategorySumResponse(
          categoryId: 'C1', categoryNm: '식비', divisionId: '3',
          sumPrice: 1000, totalSumPrice: 1000, data: [],
        ),
        const CategorySumResponse(
          categoryId: 'C2', categoryNm: '교통', divisionId: '3',
          sumPrice: 500, totalSumPrice: 500, data: [],
        ),
        const CategorySumResponse(
          categoryId: 'C3', categoryNm: '쇼핑', divisionId: '3',
          sumPrice: 800, totalSumPrice: 800, data: [],
        ),
      ];
      final result = DashboardOverviewViewModel.buildTopCategories(sums);
      expect(result.length, 3);
      expect(result.first.categoryNm, '식비');
      expect(result.first.ratio, closeTo(0.435, 0.001));
    });
  });
}
