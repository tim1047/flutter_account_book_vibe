import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/models/member_model.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';

class ExpenseCategorySeqItem {
  const ExpenseCategorySeqItem({
    required this.categoryId,
    required this.categoryNm,
    required this.categorySeq,
    required this.categorySeqNm,
    required this.amount,
    required this.ratio,
    this.prevPeriodAmount = 0,
  });

  final String categoryId;
  final String categoryNm;
  final String categorySeq;
  final String categorySeqNm;
  final int amount;
  final double ratio;
  final int prevPeriodAmount;

  double get changeRate {
    if (prevPeriodAmount == 0) return 0;
    return (amount - prevPeriodAmount) / prevPeriodAmount;
  }
}

class ExpenseMemberItem {
  const ExpenseMemberItem({
    required this.memberId,
    required this.memberNm,
    required this.amount,
    required this.ratio,
  });

  final String memberId;
  final String memberNm;
  final int amount;
  final double ratio;
}

class ExpenseSummaryData {
  const ExpenseSummaryData({
    required this.summary,
    required this.categorySeqBreakdown,
    required this.memberBreakdown,
    required this.topTransactions,
  });

  final DivisionSummaryData summary;
  final List<ExpenseCategorySeqItem> categorySeqBreakdown;
  final List<ExpenseMemberItem> memberBreakdown;
  final List<AccountListResponse> topTransactions;
}

List<ExpenseCategorySeqItem> buildExpenseCategorySeqBreakdown(
  List<CategorySumResponse> current,
  List<CategorySumResponse> prev,
) {
  final total = current.fold(0, (s, e) => s + e.sumPrice);
  if (total == 0) return [];
  final prevMap = <String, Map<String, int>>{};
  for (final cat in prev) {
    prevMap[cat.categoryId] = {
      for (final seq in cat.data) seq.categorySeq: seq.sumPrice,
    };
  }
  final items = <ExpenseCategorySeqItem>[];
  for (final cat in current) {
    for (final seq in cat.data) {
      if (seq.sumPrice > 0) {
        items.add(ExpenseCategorySeqItem(
          categoryId: cat.categoryId,
          categoryNm: cat.categoryNm,
          categorySeq: seq.categorySeq,
          categorySeqNm: seq.categorySeqNm,
          amount: seq.sumPrice,
          ratio: seq.sumPrice / total,
          prevPeriodAmount: prevMap[cat.categoryId]?[seq.categorySeq] ?? 0,
        ));
      }
    }
  }
  items.sort((a, b) => b.amount.compareTo(a.amount));
  return items;
}

List<ExpenseMemberItem> buildExpenseMemberBreakdown(List<MemberSumResponse> members) {
  final total = members.fold(0, (s, e) => s + e.sumPrice);
  if (total == 0) return [];
  final sorted = [...members]..sort((a, b) => b.sumPrice.compareTo(a.sumPrice));
  return sorted
      .map((e) => ExpenseMemberItem(
            memberId: e.memberId,
            memberNm: e.memberNm,
            amount: e.sumPrice,
            ratio: e.sumPrice / total,
          ))
      .toList();
}
