import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

AccountListResponse _tx({required String divisionId, required int price}) =>
    AccountListResponse(
      seq: 1,
      accountId: 1,
      accountDt: '20260101',
      divisionId: divisionId,
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
  group('DashboardOverviewViewModel.aggregate', () {
    test('저축액 = 수입 - 지출', () {
      const data = DashboardOverviewData(
        totalIncome: 4000000,
        totalExpense: 3160000,
        totalInvest: 500000,
        prevTotalIncome: 0,
        prevTotalExpense: 0,
        prevTotalInvest: 0,
        topExpenseCategories: [],
        recentTransactions: [],
        changeLabel: '전달 대비',
      );
      expect(data.savings, 840000);
    });

    test('수입/지출/저축/투자 변화 = 현재 - 전기간', () {
      const data = DashboardOverviewData(
        totalIncome: 4000000,
        totalExpense: 3000000,
        totalInvest: 500000,
        prevTotalIncome: 3500000,
        prevTotalExpense: 3200000,
        prevTotalInvest: 300000,
        topExpenseCategories: [],
        recentTransactions: [],
        changeLabel: '전달 대비',
      );
      expect(data.incomeChange, 500000);
      expect(data.expenseChange, -200000);
      expect(data.savingsChange, 700000);
      expect(data.investChange, 200000);
    });

    test('sumsByDivision: division별 합계 집계', () {
      final accounts = [
        _tx(divisionId: '1', price: 3000000),
        _tx(divisionId: '1', price: 1000000),
        _tx(divisionId: '3', price: 500000),
        _tx(divisionId: '2', price: 200000),
      ];
      final sums = DashboardOverviewViewModel.sumsByDivision(accounts);
      expect(sums.income, 4000000);
      expect(sums.expense, 500000);
      expect(sums.invest, 200000);
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
