# 인사이트 페이지 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 지출 카테고리 이상 감지와 단일 이상 거래 감지 인사이트를 보여주는 `/insight` 전용 페이지를 추가한다.

**Architecture:** InsightViewModel이 현재 월 + 직전 3개월 데이터를 병렬 fetch한 뒤 클라이언트에서 이상 감지 연산 수행. 기존 `CategoryService`, `AccountService`, `DateFilterViewModel` 싱글턴을 그대로 재사용. 백엔드 변경 없음.

**Tech Stack:** Flutter, Dart 3, ChangeNotifier, go_router 13, CategoryService, AccountService

---

## File Map

| 역할 | 파일 |
|------|------|
| Create | `lib/features/insight/insight_viewmodel.dart` |
| Create | `lib/features/insight/insight_screen.dart` |
| Create | `lib/shared/widgets/category_anomaly_card.dart` |
| Create | `lib/shared/widgets/transaction_anomaly_card.dart` |
| Create | `test/features/insight/insight_viewmodel_test.dart` |
| Modify | `lib/core/router/app_router.dart` |
| Modify | `lib/shared/widgets/app_drawer.dart` |

---

## 사전 확인

시작 전 다음 파일을 읽어 패턴을 파악해 둔다:
- `lib/features/home/home_viewmodel.dart` — ViewModel 패턴 참조
- `lib/features/home/home_screen.dart` — Screen 패턴 참조
- `lib/core/constants/app_colors.dart` — 색상 상수 확인

---

## Task 1: InsightViewModel — 데이터 모델 + 상수

**Files:**
- Create: `lib/features/insight/insight_viewmodel.dart`

- [ ] **Step 1: 파일 생성 — 모델 클래스 + 상수**

```dart
// lib/features/insight/insight_viewmodel.dart
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/foundation.dart';

const double kCategoryAnomalyThreshold = 0.20;
const double kTransactionAnomalyMultiple = 3.0;
const int kMaxAnomalyItems = 5;
const int kComparisonMonths = 3;
const String _expenseDivisionId = '3'; // Division.expense

class CategoryAnomalyItem {
  const CategoryAnomalyItem({
    required this.categoryId,
    required this.categoryNm,
    required this.currentPrice,
    required this.avgPrice,
    required this.diffRate,
  });

  final String categoryId;
  final String categoryNm;
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
          divisionId: _expenseDivisionId,
          strtDt: strtDt,
          endDt: endDt,
        ),
        ...pastRanges.map((r) => CategoryService.instance.getCategorySum(
              divisionId: _expenseDivisionId,
              strtDt: r.strtDt,
              endDt: r.endDt,
            )),
      ]);

      // 거래 목록: 현재 월 + 직전 3개월 병렬
      final txFuture = Future.wait<List<AccountListResponse>>([
        AccountService.instance.getAccounts(
          divisionId: _expenseDivisionId,
          strtDt: strtDt,
          endDt: endDt,
        ),
        ...pastRanges.map((r) => AccountService.instance.getAccounts(
              divisionId: _expenseDivisionId,
              strtDt: r.strtDt,
              endDt: r.endDt,
            )),
      ]);

      final catResults = await catFuture;
      final txResults = await txFuture;

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
    // 카테고리별 과거 가격 누적
    final Map<String, List<int>> pastPrices = {};
    for (final monthData in pastMonths) {
      for (final cat in monthData) {
        pastPrices.putIfAbsent(cat.categoryId, () => []).add(cat.sumPrice);
      }
    }

    // 카테고리별 평균 (0 제외)
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
      final avg = avgPrices[cat.categoryId];
      if (avg == null || avg == 0) continue;
      final diffRate = (cat.sumPrice - avg) / avg;
      if (diffRate.abs() > kCategoryAnomalyThreshold) {
        results.add(CategoryAnomalyItem(
          categoryId: cat.categoryId,
          categoryNm: cat.categoryNm,
          currentPrice: cat.sumPrice,
          avgPrice: avg.round(),
          diffRate: diffRate,
        ));
      }
    }

    results.sort((a, b) => b.diffRate.abs().compareTo(a.diffRate.abs()));
    return results.take(kMaxAnomalyItems).toList();
  }

  static List<TransactionAnomalyItem> computeTransactionAnomalies(
    List<AccountListResponse> currentTxs,
    List<AccountListResponse> pastTxs,
  ) {
    // 카테고리별 과거 거래 금액 누적
    final Map<String, List<int>> pastPricesByCategory = {};
    for (final tx in pastTxs) {
      pastPricesByCategory.putIfAbsent(tx.categoryId, () => []).add(tx.price);
    }

    // 카테고리별 평균 단가 (과거 거래 2건 이상인 경우만)
    final Map<String, double> categoryAvgPrices = {};
    for (final entry in pastPricesByCategory.entries) {
      if (entry.value.length >= 2) {
        categoryAvgPrices[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    final results = <TransactionAnomalyItem>[];
    for (final tx in currentTxs) {
      final avg = categoryAvgPrices[tx.categoryId];
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
    return results.take(kMaxAnomalyItems).toList();
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
```

- [ ] **Step 2: 빌드 확인**

```
flutter pub get
flutter build web --no-tree-shake-icons 2>&1 | head -30
```

오류 없으면 OK. import 오류가 있으면 경로 수정.

- [ ] **Step 3: 커밋**

```
git add lib/features/insight/insight_viewmodel.dart
git commit -m "feat(insight): add InsightViewModel with anomaly detection logic"
```

---

## Task 2: InsightViewModel 단위 테스트 작성 (실패 확인)

**Files:**
- Create: `test/features/insight/insight_viewmodel_test.dart`

- [ ] **Step 1: 테스트 파일 작성**

```dart
// test/features/insight/insight_viewmodel_test.dart
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/features/insight/insight_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

// 테스트용 CategorySumResponse 생성 헬퍼
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

      expect(result.length, lessThanOrEqualTo(kMaxAnomalyItems));
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
```

- [ ] **Step 2: 테스트 실행 — 실패 확인 (모델 생성자 확인)**

```
flutter test test/features/insight/insight_viewmodel_test.dart 2>&1
```

`CategorySumResponse`와 `AccountListResponse`의 실제 생성자 파라미터가 다르면 오류가 난다. 오류 메시지를 보고 `lib/data/models/category_model.dart`, `lib/data/models/account_model.dart`를 읽어 생성자를 맞춘다.

- [ ] **Step 3: 모델 생성자 수정 후 재실행**

생성자를 실제 코드에 맞게 수정하고 다시 실행:

```
flutter test test/features/insight/insight_viewmodel_test.dart 2>&1
```

모든 테스트 PASS 확인.

- [ ] **Step 4: 커밋**

```
git add test/features/insight/insight_viewmodel_test.dart
git commit -m "test(insight): add unit tests for anomaly detection logic"
```

---

## Task 3: CategoryAnomalyCard 위젯

**Files:**
- Create: `lib/shared/widgets/category_anomaly_card.dart`

- [ ] **Step 1: 위젯 파일 작성**

```dart
// lib/shared/widgets/category_anomaly_card.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/insight/insight_viewmodel.dart';
import 'package:flutter/material.dart';

class CategoryAnomalyCard extends StatelessWidget {
  const CategoryAnomalyCard({super.key, required this.item});

  final CategoryAnomalyItem item;

  bool get _isIncrease => item.diffRate > 0;

  Color get _accentColor =>
      _isIncrease ? AppColors.colorExpense : AppColors.colorProfit;

  @override
  Widget build(BuildContext context) {
    final pct = (item.diffRate * 100).abs();
    final diffLabel = _isIncrease
        ? '+${pct.toStringAsFixed(0)}%'
        : '−${pct.toStringAsFixed(0)}%';
    final diffAmount = item.currentPrice - item.avgPrice;
    final diffAmountLabel = _isIncrease
        ? '+${FormatUtil.formatPrice(diffAmount)}원'
        : '−${FormatUtil.formatPrice(diffAmount.abs())}원';

    // 진행률 바: 현재 금액 / (평균 × 2), 최대 1.0
    final barValue =
        (item.currentPrice / (item.avgPrice * 2)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _isIncrease
            ? const Color(0xFF1A0808)
            : const Color(0xFF081508),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: _accentColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_isIncrease ? '⚠' : '✓'} ${item.categoryNm} $diffLabel',
                style: AppTextStyles.textBodyMd.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isIncrease ? '증가' : '감소',
                  style: AppTextStyles.textLabelSm
                      .copyWith(color: _accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '이번달 ${FormatUtil.formatPrice(item.currentPrice)}원  ·  평균 ${FormatUtil.formatPrice(item.avgPrice)}원',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: barValue,
            backgroundColor: AppColors.colorBgInteractive,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            borderRadius: BorderRadius.circular(2),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            diffAmountLabel,
            style: AppTextStyles.textLabelSm.copyWith(
              color: AppColors.colorTextDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 빌드 확인**

```
flutter build web --no-tree-shake-icons 2>&1 | grep -E "error:|Error" | head -20
```

`AppTextStyles`에 `textLabelSm`이 없으면 `lib/core/constants/app_text_styles.dart`를 읽어 올바른 스타일 이름으로 교체. `AppColors.colorBgInteractive`가 없으면 `app_colors.dart`를 읽어 가장 가까운 어두운 배경 색으로 교체.

- [ ] **Step 3: 커밋**

```
git add lib/shared/widgets/category_anomaly_card.dart
git commit -m "feat(insight): add CategoryAnomalyCard widget"
```

---

## Task 4: TransactionAnomalyCard 위젯

**Files:**
- Create: `lib/shared/widgets/transaction_anomaly_card.dart`

- [ ] **Step 1: 위젯 파일 작성**

```dart
// lib/shared/widgets/transaction_anomaly_card.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/insight/insight_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TransactionAnomalyCard extends StatelessWidget {
  const TransactionAnomalyCard({super.key, required this.item});

  final TransactionAnomalyItem item;

  Color get _accentColor =>
      item.multiple >= 4.0 ? AppColors.colorExpense : AppColors.colorInvest;

  @override
  Widget build(BuildContext context) {
    final tx = item.account;
    final dateStr = tx.accountDt.length >= 10
        ? '${tx.accountDt.substring(5, 7)}.${tx.accountDt.substring(8, 10)}'
        : tx.accountDt;
    final desc =
        tx.remark?.isNotEmpty == true ? tx.remark! : tx.categorySeqNm;

    return GestureDetector(
      onTap: () => context.go('/account', extra: tx),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1008),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: _accentColor, width: 3),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tx.categoryNm}  ·  $dateStr',
                    style: AppTextStyles.textBodyMd.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$desc  ·  ${FormatUtil.formatPrice(tx.price)}원',
                    style: AppTextStyles.textBodySm.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '카테고리 평균 단가 ${FormatUtil.formatPrice(item.categoryAvgPrice)}원',
                    style: AppTextStyles.textLabelSm.copyWith(
                      color: AppColors.colorTextDisabled,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item.multiple.toStringAsFixed(1)}배',
                style: AppTextStyles.textLabelMd.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 빌드 확인**

```
flutter build web --no-tree-shake-icons 2>&1 | grep -E "error:|Error" | head -20
```

`AppColors.colorInvest`가 없으면 `app_colors.dart`를 읽어 주황색 계열 색상으로 교체.

- [ ] **Step 3: 커밋**

```
git add lib/shared/widgets/transaction_anomaly_card.dart
git commit -m "feat(insight): add TransactionAnomalyCard widget"
```

---

## Task 5: InsightScreen

**Files:**
- Create: `lib/features/insight/insight_screen.dart`

- [ ] **Step 1: 스크린 파일 작성**

```dart
// lib/features/insight/insight_screen.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/features/insight/insight_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/category_anomaly_card.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/transaction_anomaly_card.dart';
import 'package:flutter/material.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  late final InsightViewModel _vm;
  late final DateFilterViewModel _dateFilter;

  @override
  void initState() {
    super.initState();
    _dateFilter = DateFilterViewModel(); // 싱글턴 반환
    _vm = InsightViewModel();
    _load();
  }

  void _load() =>
      _vm.load(_dateFilter.selectedYear, _dateFilter.selectedMonth);

  @override
  void dispose() {
    _vm.dispose();
    // _dateFilter는 싱글턴이므로 dispose 하지 않음
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              DateFilterBar(viewModel: _dateFilter, onRefresh: _load),
              Expanded(
                child: ListenableBuilder(
                  listenable: _vm,
                  builder: (context, _) {
                    if (_vm.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.colorAccentTeal,
                        ),
                      );
                    }
                    if (_vm.errorMessage != null) {
                      return ErrorView(
                        message: _vm.errorMessage!,
                        onRetry: _load,
                      );
                    }
                    return _buildBody();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _SectionHeader(
          title: '📊 카테고리 이상 감지',
          subtitle: '최근 3개월 평균 대비',
        ),
        if (_vm.categoryAnomalies.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: EmptyView(message: '이번 달은 이상 지출이 없어요 👍'),
          )
        else
          ..._vm.categoryAnomalies
              .map((item) => CategoryAnomalyCard(item: item)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Divider(color: AppColors.colorDivider),
        ),
        _SectionHeader(
          title: '🔍 단일 이상 거래',
          subtitle: '카테고리 평균 단가 대비',
        ),
        if (_vm.transactionAnomalies.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: EmptyView(message: '이번 달은 이상 거래가 없어요 👍'),
          )
        else
          ..._vm.transactionAnomalies
              .map((item) => TransactionAnomalyCard(item: item)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.textBodyLg.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.colorTextPrimary,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 빌드 확인**

```
flutter build web --no-tree-shake-icons 2>&1 | grep -E "error:|Error" | head -20
```

오류 없으면 OK.

- [ ] **Step 3: 커밋**

```
git add lib/features/insight/insight_screen.dart
git commit -m "feat(insight): add InsightScreen UI"
```

---

## Task 6: 라우터 + 드로어 연결

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/shared/widgets/app_drawer.dart`

- [ ] **Step 1: app_router.dart에 /insight 라우트 추가**

`lib/core/router/app_router.dart` 파일을 읽고, import 목록 끝에 다음을 추가:

```dart
import 'package:account_book_vibe/features/insight/insight_screen.dart';
```

그리고 `routes: [` 배열에서 `/accountList` 라우트 바로 뒤에 추가:

```dart
GoRoute(
  path: '/insight',
  pageBuilder: (c, s) => _slidePage(const InsightScreen(), s),
),
```

- [ ] **Step 2: app_drawer.dart에 인사이트 메뉴 추가**

`lib/shared/widgets/app_drawer.dart`의 `ListView` 안에서 `/accountList` `_NavTile` 바로 뒤에 추가:

```dart
_NavTile(
  emoji: '💡',
  label: '인사이트',
  path: '/insight',
  currentPath: currentPath,
),
```

- [ ] **Step 3: 빌드 확인**

```
flutter build web --no-tree-shake-icons 2>&1 | grep -E "error:|Error" | head -20
```

- [ ] **Step 4: 동작 확인 — Chrome에서 직접 확인**

```
flutter run -d chrome --web-port 3000
```

1. 드로어를 열어 💡 인사이트 메뉴가 보이는지 확인
2. 메뉴 탭 → `/insight` 페이지 이동 확인
3. 날짜 필터를 변경하면 데이터가 다시 로드되는지 확인
4. 카드가 없을 때 EmptyView가 표시되는지 확인
5. 카드가 있으면 CategoryAnomalyCard / TransactionAnomalyCard가 표시되는지 확인
6. TransactionAnomalyCard 탭 → `/account` 페이지로 이동하는지 확인

- [ ] **Step 5: 커밋**

```
git add lib/core/router/app_router.dart lib/shared/widgets/app_drawer.dart
git commit -m "feat(insight): wire /insight route and drawer menu"
```

---

## 완료 기준

- [ ] `flutter test test/features/insight/` 전체 PASS
- [ ] `flutter build web` 오류 없음
- [ ] Chrome에서 인사이트 페이지 정상 렌더링
- [ ] 날짜 필터 변경 시 데이터 갱신
- [ ] 이상 없는 달에는 EmptyView 표시
- [ ] TransactionAnomalyCard 탭 시 거래 수정 페이지 이동
