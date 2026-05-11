// lib/features/insight/insight_viewmodel.dart
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/foundation.dart';

const double kCategoryAnomalyThreshold = 0.20;
const double kTransactionAnomalyMultiple = 3.0;
const int kMaxCategoryAnomalyItems = 5;
const int kMaxTransactionAnomalyItems = 10;
const int kComparisonMonths = 3;

class CategoryAnomalyItem {
  const CategoryAnomalyItem({
    required this.categoryId,
    required this.categorySeq,
    required this.categorySeqNm,
    required this.currentPrice,
    required this.avgPrice,
    required this.diffRate,
  });

  final String categoryId;
  final String categorySeq;
  final String categorySeqNm;
  final int currentPrice;
  final int avgPrice;
  final double diffRate; // 양수=증가, 음수=감소
}

class TransactionAnomalyItem {
  const TransactionAnomalyItem({
    required this.account,
    required this.multiple,
    required this.categoryAvgPrice,
  });

  final AccountListResponse account;
  final double multiple;
  final int categoryAvgPrice;
}

class InsightViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<CategoryAnomalyItem> categoryAnomalies = [];
  List<TransactionAnomalyItem> transactionAnomalies = [];

  // ── fetch ─────────────────────────────────────────────────────────────────
  Future<void> load(int year, int month) async {
    // month=0(전체)이면 현재 월로 대체
    final m = month == 0 ? DateTime.now().month : month;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final strtDt = FormatUtil.toStrtDt(year, m);
      final endDt = FormatUtil.toEndDt(year, m);
      final pastRanges = _pastMonthRanges(year, m);

      // 카테고리 합계: 현재 월 + 직전 3개월 병렬
      final catFuture = Future.wait<List<CategorySumResponse>>([
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense,
          strtDt: strtDt,
          endDt: endDt,
        ),
        ...pastRanges.map((r) => CategoryService.instance.getCategorySum(
              divisionId: Division.expense,
              strtDt: r.strtDt,
              endDt: r.endDt,
            )),
      ]);

      // 거래 목록: 현재 월 + 직전 3개월 병렬
      final txFuture = Future.wait<List<AccountListResponse>>([
        AccountService.instance.getAccounts(
          divisionId: Division.expense,
          strtDt: strtDt,
          endDt: endDt,
        ),
        ...pastRanges.map((r) => AccountService.instance.getAccounts(
              divisionId: Division.expense,
              strtDt: r.strtDt,
              endDt: r.endDt,
            )),
      ]);

      // 8개 요청 모두 진정한 병렬 실행
      final results = await Future.wait([catFuture, txFuture]);
      final catResults = results[0] as List<List<CategorySumResponse>>;
      final txResults = results[1] as List<List<AccountListResponse>>;

      final currentCatSums = catResults[0];
      final pastCatSums = catResults.sublist(1);
      final currentTxs = txResults[0];
      final pastTxs = txResults.sublist(1).expand((l) => l).toList();

      categoryAnomalies = computeCategoryAnomalies(currentCatSums, pastCatSums);
      transactionAnomalies = computeTransactionAnomalies(currentTxs, pastTxs);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── computation (static for testability) ─────────────────────────────────

  static List<CategoryAnomalyItem> computeCategoryAnomalies(
    List<CategorySumResponse> current,
    List<List<CategorySumResponse>> pastMonths,
  ) {
    // (categoryId + categorySeq) 복합키로 과거 가격 누적
    // categorySeq는 카테고리 내 로컬 ID이므로 단독 키 사용 시 다른 카테고리와 충돌
    final Map<String, List<int>> pastPrices = {};
    for (final monthData in pastMonths) {
      for (final cat in monthData) {
        for (final seqItem in cat.data) {
          final key = '${cat.categoryId}_${seqItem.categorySeq}';
          pastPrices.putIfAbsent(key, () => []).add(seqItem.sumPrice);
        }
      }
    }

    // 복합키별 평균 (0 제외)
    final Map<String, double> avgPrices = {};
    for (final entry in pastPrices.entries) {
      final nonZero = entry.value.where((p) => p > 0).toList();
      if (nonZero.isNotEmpty) {
        avgPrices[entry.key] =
            nonZero.reduce((a, b) => a + b) / nonZero.length;
      }
    }

    final results = <CategoryAnomalyItem>[];
    for (final cat in current) {
      for (final seqItem in cat.data) {
        if (seqItem.sumPrice == 0) continue; // 이번달 금액이 0이면 제외
        final key = '${cat.categoryId}_${seqItem.categorySeq}';
        final avg = avgPrices[key];
        if (avg == null || avg == 0) continue;
        final diffRate = (seqItem.sumPrice - avg) / avg;
        if (diffRate.abs() > kCategoryAnomalyThreshold) {
          results.add(CategoryAnomalyItem(
            categoryId: cat.categoryId,
            categorySeq: seqItem.categorySeq,
            categorySeqNm: seqItem.categorySeqNm,
            currentPrice: seqItem.sumPrice,
            avgPrice: avg.round(),
            diffRate: diffRate,
          ));
        }
      }
    }

    results.sort((a, b) => b.diffRate.abs().compareTo(a.diffRate.abs()));
    return results.take(kMaxCategoryAnomalyItems).toList();
  }

  static List<TransactionAnomalyItem> computeTransactionAnomalies(
    List<AccountListResponse> currentTxs,
    List<AccountListResponse> pastTxs,
  ) {
    // (categoryId + categorySeq) 복합키로 과거 거래 금액 누적
    final Map<String, List<int>> pastPricesByCategory = {};
    for (final tx in pastTxs) {
      final key = '${tx.categoryId}_${tx.categorySeq}';
      pastPricesByCategory.putIfAbsent(key, () => []).add(tx.price);
    }

    // 복합키별 평균 단가 (과거 거래 2건 이상인 경우만)
    final Map<String, double> categoryAvgPrices = {};
    for (final entry in pastPricesByCategory.entries) {
      if (entry.value.length >= 2) {
        categoryAvgPrices[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    final results = <TransactionAnomalyItem>[];
    for (final tx in currentTxs) {
      final avg = categoryAvgPrices['${tx.categoryId}_${tx.categorySeq}'];
      if (avg == null || avg == 0) continue;
      final multiple = tx.price / avg;
      if (multiple >= kTransactionAnomalyMultiple) {
        results.add(TransactionAnomalyItem(
          account: tx,
          multiple: multiple,
          categoryAvgPrice: avg.round(),
        ));
      }
    }

    results.sort((a, b) => b.multiple.compareTo(a.multiple));
    return results.take(kMaxTransactionAnomalyItems).toList();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  static List<({String strtDt, String endDt})> _pastMonthRanges(
    int year,
    int month,
  ) {
    return List.generate(kComparisonMonths, (i) {
      final dt = DateTime(year, month - (i + 1), 1);
      return (
        strtDt: FormatUtil.toStrtDt(dt.year, dt.month),
        endDt: FormatUtil.toEndDt(dt.year, dt.month),
      );
    });
  }
}
