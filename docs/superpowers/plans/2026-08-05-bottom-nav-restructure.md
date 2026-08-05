# 바텀 네비게이션 재구성 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 드로어 내비게이션을 4-브랜치 바텀 네비게이션(목록/분석/홈/자산)으로 교체하고, 지출 전용이던 대시보드 분석 로직을 division 파라미터 기반으로 일반화해 수입/투자에도 재사용한다.

**Architecture:** `go_router`의 `StatefulShellRoute.indexedStack`으로 4개 브랜치를 만들고, 각 브랜치 루트가 자신의 `Scaffold`(AppBar 포함, `MainAppBar`는 새 `showMenuButton: false`로 드로어 숨김)를 계속 소유하는 중첩 Scaffold 패턴을 쓴다. 지출 전용 `DashboardExpenseViewModel`/`ExpenseTab`은 공통 `DivisionSummaryViewModel`/`DivisionSummaryContent`(총액·카테고리 비중·월별 추이)로 일반화하고, 지출만 갖는 카테고리 상세/주체별 지출/TOP10은 `ExpenseSummaryViewModel`/`ExpenseAnalysisTab`이 별도로 소유한다(상속 대신 조합).

**Tech Stack:** Flutter, `go_router ^13.2.0` (`StatefulShellRoute` 지원), `flutter_test` (단위/위젯 테스트, 네트워크 mocking 없음 — 기존 컨벤션과 동일하게 순수 로직·순수 위젯만 테스트).

**참조 스펙:** [docs/superpowers/specs/2026-08-05-bottom-nav-restructure-design.md](../specs/2026-08-05-bottom-nav-restructure-design.md)

**중요 — Hero 태그 충돌 주의:** `StatefulShellRoute.indexedStack`은 4개 브랜치를 전부 동시에 마운트 상태로 유지한다(오프스크린이어도 dispose되지 않음). 기존 `DashboardScreen`과 `AccountListScreen`이 둘 다 `heroTag: 'addAccount'`를 썼는데(오늘은 동시에 마운트될 일이 없어 문제없었음), 이제는 동시에 살아있는 여러 브랜치의 FAB가 같은 `heroTag`를 쓰면 `FloatingActionButton` Hero 애니메이션 충돌로 런타임 assertion 에러가 난다. 이 계획의 모든 새 FAB는 브랜치별로 고유한 `heroTag`를 쓴다: 목록=`addAccount`(기존 그대로), 분석=`addAccountAnalysis`, 홈=`addAccountHome`, 자산=`addAsset`(기존 `AssetListScreen`의 태그를 그대로 재사용 — 그 파일은 Task 14에서 삭제되므로 충돌 없음).

---

### Task 1: `MainAppBar`에 `showMenuButton` 옵션 추가

**Files:**
- Modify: `lib/shared/widgets/main_app_bar.dart`
- Test: `test/shared/widgets/main_app_bar_test.dart` (신규)

- [ ] **Step 1: 실패하는 위젯 테스트 작성**

```dart
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showMenuButton: false면 메뉴 아이콘이 렌더되지 않는다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: MainAppBar(showMenuButton: false)),
      ),
    );

    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('showMenuButton 생략(기본값 true)이면 메뉴 아이콘이 렌더된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: MainAppBar()),
      ),
    );

    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/shared/widgets/main_app_bar_test.dart`
Expected: 컴파일 에러 또는 `showMenuButton` named parameter 없음 에러 (첫 번째 테스트가 아직 `false`를 받을 수 없음).

- [ ] **Step 3: `MainAppBar`에 파라미터 추가**

`lib/shared/widgets/main_app_bar.dart` 전체를 다음으로 교체:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    this.bottom,
    this.showMenuButton = true,
  });

  final PreferredSizeWidget? bottom;

  /// false면 좌측 햄버거(드로어 열기) 버튼을 렌더하지 않는다.
  /// 바텀 네비게이션 셸 화면들(목록/분석/홈/자산)에서 사용.
  final bool showMenuButton;

  @override
  Size get preferredSize => Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.colorBgMain,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 56,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Text(
        '강원 🧡 정윤 가계부',
        style: AppTextStyles.textHeadlineMd.copyWith(
          color: AppColors.colorTextPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.colorTextPrimary,
        size: 24,
      ),
      leading: showMenuButton
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      bottom: bottom,
    );
  }
}
```

- [ ] **Step 4: 테스트 실행해서 통과 확인**

Run: `flutter test test/shared/widgets/main_app_bar_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: 커밋**

```bash
git add lib/shared/widgets/main_app_bar.dart test/shared/widgets/main_app_bar_test.dart
git commit -m "feat(app-bar): add showMenuButton option to hide hamburger menu"
```

---

### Task 2: Division 공통 데이터 모델

**Files:**
- Create: `lib/features/analysis/division_summary_data.dart`
- Test: `test/features/analysis/division_summary_data_test.dart`

- [ ] **Step 1: 실패하는 단위 테스트 작성**

```dart
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
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/features/analysis/division_summary_data_test.dart`
Expected: FAIL — `division_summary_data.dart`를 찾을 수 없음.

- [ ] **Step 3: 데이터 모델 작성**

```dart
class DivisionCategoryItem {
  const DivisionCategoryItem({
    required this.categoryId,
    required this.categoryNm,
    required this.amount,
    required this.ratio,
    this.prevPeriodAmount = 0,
  });

  final String categoryId;
  final String categoryNm;
  final int amount;
  final double ratio;
  final int prevPeriodAmount;

  double get changeRate {
    if (prevPeriodAmount == 0) return 0;
    return (amount - prevPeriodAmount) / prevPeriodAmount;
  }
}

class DivisionSummaryData {
  const DivisionSummaryData({
    required this.totalAmount,
    required this.prevPeriodAmount,
    required this.monthlyAmounts,
    required this.categoryBreakdown,
    required this.changeLabel,
    this.chartHighlightMonth,
  });

  final int totalAmount;
  final int prevPeriodAmount;
  final List<({String month, int amount})> monthlyAmounts;
  final List<DivisionCategoryItem> categoryBreakdown;
  final String changeLabel;
  final String? chartHighlightMonth;

  double get changeRate {
    if (prevPeriodAmount == 0) return 0;
    return (totalAmount - prevPeriodAmount) / prevPeriodAmount;
  }
}
```

Save to `lib/features/analysis/division_summary_data.dart`.

- [ ] **Step 4: 테스트 실행해서 통과 확인**

Run: `flutter test test/features/analysis/division_summary_data_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: 커밋**

```bash
git add lib/features/analysis/division_summary_data.dart test/features/analysis/division_summary_data_test.dart
git commit -m "feat(analysis): add division-agnostic summary data model"
```

---

### Task 3: `DivisionSummaryViewModel`

기존 `DashboardExpenseViewModel`([lib/features/dashboard/viewmodels/expense_viewmodel.dart](../../../lib/features/dashboard/viewmodels/expense_viewmodel.dart))의 `buildCategoryBreakdown`/`buildMonthlyTotals` 로직을 division 무관 형태로 옮긴다. `_shared`(전체 계정 1회 fetch + 지출 전용 catSum) 의존을 버리고, 각 인스턴스가 자기 division의 계정/카테고리 합계를 독립적으로 fetch한다.

**Files:**
- Create: `lib/features/analysis/division_summary_viewmodel.dart`
- Test: `test/features/analysis/division_summary_viewmodel_test.dart`

- [ ] **Step 1: 실패하는 단위 테스트 작성 (정적 헬퍼만 — 네트워크 fetch는 기존 컨벤션대로 테스트하지 않음)**

```dart
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
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/features/analysis/division_summary_viewmodel_test.dart`
Expected: FAIL — `division_summary_viewmodel.dart`를 찾을 수 없음.

- [ ] **Step 3: 뷰모델 작성**

```dart
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

/// 지출/수입/투자 공통 요약(총액·카테고리 비중·월별 추이)을 로드하는 뷰모델.
/// [divisionId]로 어느 division을 볼지 결정하며, 자기 데이터를 독립적으로 fetch한다.
class DivisionSummaryViewModel extends ChangeNotifier {
  DivisionSummaryViewModel(this.divisionId, this.period) {
    period.addListener(load);
  }

  final String divisionId;
  final DashboardPeriodViewModel period;

  bool isLoading = false;
  String? errorMessage;
  DivisionSummaryData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = period.range;
      final prevRange = period.prevRange;
      final chartRange = period.chartRange;
      final needsChartFetch = chartRange != range;

      final results = await Future.wait([
        AccountService.instance.getAccounts(
          strtDt: range.strtDt,
          endDt: range.endDt,
          divisionId: divisionId,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: divisionId,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        AccountService.instance.getAccounts(
          strtDt: prevRange.strtDt,
          endDt: prevRange.endDt,
          divisionId: divisionId,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: divisionId,
          strtDt: prevRange.strtDt,
          endDt: prevRange.endDt,
        ),
        if (needsChartFetch)
          AccountService.instance.getAccounts(
            strtDt: chartRange.strtDt,
            endDt: chartRange.endDt,
            divisionId: divisionId,
          ),
      ]);

      final currentAccounts = results[0] as List<AccountListResponse>;
      final currentCatSums = results[1] as List<CategorySumResponse>;
      final prevAccounts = results[2] as List<AccountListResponse>;
      final prevCatSums = results[3] as List<CategorySumResponse>;
      final chartAccounts =
          needsChartFetch ? results[4] as List<AccountListResponse> : currentAccounts;

      data = DivisionSummaryData(
        totalAmount: currentAccounts.fold(0, (s, e) => s + e.price),
        prevPeriodAmount: prevAccounts.fold(0, (s, e) => s + e.price),
        monthlyAmounts: buildMonthlyTotals(
          chartAccounts,
          chartRange.strtDt,
          chartRange.endDt,
        ),
        categoryBreakdown: buildCategoryBreakdown(currentCatSums, prevCatSums),
        changeLabel: period.changeLabel,
        chartHighlightMonth: period.chartHighlightMonth,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static List<DivisionCategoryItem> buildCategoryBreakdown(
    List<CategorySumResponse> current,
    List<CategorySumResponse> prev,
  ) {
    final total = current.fold(0, (s, e) => s + e.sumPrice);
    if (total == 0) return [];
    final prevMap = {for (final e in prev) e.categoryId: e.sumPrice};
    final sorted = [...current]..sort((a, b) => b.sumPrice.compareTo(a.sumPrice));
    return sorted
        .map((e) => DivisionCategoryItem(
              categoryId: e.categoryId,
              categoryNm: e.categoryNm,
              amount: e.sumPrice,
              ratio: e.sumPrice / total,
              prevPeriodAmount: prevMap[e.categoryId] ?? 0,
            ))
        .toList();
  }

  static List<({String month, int amount})> buildMonthlyTotals(
    List<AccountListResponse> transactions,
    String strtDt,
    String endDt,
  ) {
    final byMonth = <String, int>{};
    for (final tx in transactions) {
      final dt = tx.accountDt;
      if (dt.length >= 6) {
        final month = dt.substring(0, 6);
        byMonth[month] = (byMonth[month] ?? 0) + tx.price;
      }
    }
    final sorted = byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => (month: e.key, amount: e.value)).toList();
  }

  @override
  void dispose() {
    period.removeListener(load);
    super.dispose();
  }
}
```

Save to `lib/features/analysis/division_summary_viewmodel.dart`.

- [ ] **Step 4: 테스트 실행해서 통과 확인**

Run: `flutter test test/features/analysis/division_summary_viewmodel_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: 커밋**

```bash
git add lib/features/analysis/division_summary_viewmodel.dart test/features/analysis/division_summary_viewmodel_test.dart
git commit -m "feat(analysis): add division-parameterized summary viewmodel"
```

---

### Task 4: `DivisionSummaryContent` / `DivisionSummaryTab` 위젯

기존 `ExpenseTab`의 ①~③ 섹션(총액 히어로 카드/카테고리별 비중/월별 추이, [lib/features/dashboard/tabs/expense_tab.dart:41-70](../../../lib/features/dashboard/tabs/expense_tab.dart))을 division 무관 재사용 위젯으로 뽑는다. `DivisionSummaryContent`는 스크롤 없는 순수 콘텐츠(다른 화면이 `ListView`로 감싸 재사용 가능), `DivisionSummaryTab`은 로딩/에러 처리를 포함한 완결된 탭.

**Files:**
- Create: `lib/features/analysis/division_summary_content.dart`
- Create: `lib/features/analysis/division_summary_tab.dart`

- [ ] **Step 1: `DivisionSummaryContent` 작성**

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/category_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/dashboard/widgets/category_legend_row.dart';
import 'package:account_book_vibe/features/dashboard/widgets/category_share_bar.dart';
import 'package:account_book_vibe/features/dashboard/widgets/monthly_bar_chart.dart';
import 'package:flutter/material.dart';

/// 지출/수입/투자 공통 3섹션(총액/카테고리 비중/월별 추이). 스크롤을 갖지 않으므로
/// 호출부가 ListView 등으로 감싸야 한다.
class DivisionSummaryContent extends StatelessWidget {
  const DivisionSummaryContent({
    super.key,
    required this.data,
    required this.title,
    required this.accentColor,
    required this.heroGradient,
    this.onCategoryTap,
  });

  final DivisionSummaryData data;
  final String title;
  final Color accentColor;
  final Gradient heroGradient;
  final void Function(DivisionCategoryItem item)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroCard(data: data, title: title, gradient: heroGradient, accentColor: accentColor),
        const SizedBox(height: 12),
        _SectionCard(
          title: '카테고리별 비중',
          child: _CategoryShareSection(data: data, onTap: onCategoryTap),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '월별 추이',
          child: MonthlyBarChart(
            data: data.monthlyAmounts,
            barColor: accentColor,
            highlightMonth: data.chartHighlightMonth,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.data,
    required this.title,
    required this.gradient,
    required this.accentColor,
  });

  final DivisionSummaryData data;
  final String title;
  final Gradient gradient;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final change = data.changeRate;
    final isIncrease = change >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.textBodySm.copyWith(color: AppColors.colorTextSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            '₩ ${FormatUtil.formatPrice(data.totalAmount)}',
            style: AppTextStyles.textHeadingLg.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 14,
                color: isIncrease ? accentColor : AppColors.colorProfit,
              ),
              Text(
                '${(change.abs() * 100).toStringAsFixed(1)}% ${data.changeLabel}',
                style: AppTextStyles.textBodySm.copyWith(
                  color: isIncrease ? accentColor : AppColors.colorProfit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryShareSection extends StatelessWidget {
  const _CategoryShareSection({required this.data, this.onTap});

  final DivisionSummaryData data;
  final void Function(DivisionCategoryItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    if (data.categoryBreakdown.isEmpty) {
      return const SizedBox(height: 60, child: Center(child: Text('데이터 없음')));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryShareBar(
          segments: data.categoryBreakdown
              .map((e) => (color: CategoryColors.of(e.categoryId), ratio: e.ratio))
              .toList(),
        ),
        const SizedBox(height: 12),
        Column(
          children: data.categoryBreakdown.map((e) {
            final row = CategoryLegendRow(
              color: CategoryColors.of(e.categoryId),
              label: e.categoryNm,
              amount: e.amount,
              ratio: e.ratio,
            );
            if (onTap == null) return row;
            return InkWell(onTap: () => onTap!(e), child: row);
          }).toList(),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.textBodySm.copyWith(color: AppColors.colorTextSecondary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
```

Save to `lib/features/analysis/division_summary_content.dart`.

- [ ] **Step 2: `DivisionSummaryTab` 작성 (수입/투자 탭에서 그대로 사용)**

```dart
import 'package:account_book_vibe/features/analysis/division_summary_content.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/analysis/division_summary_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';

class DivisionSummaryTab extends StatelessWidget {
  const DivisionSummaryTab({
    super.key,
    required this.vm,
    required this.title,
    required this.accentColor,
    required this.heroGradient,
    this.onCategoryTap,
  });

  final DivisionSummaryViewModel vm;
  final String title;
  final Color accentColor;
  final Gradient heroGradient;
  final void Function(DivisionCategoryItem item)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DivisionSummaryContent(
              data: data,
              title: title,
              accentColor: accentColor,
              heroGradient: heroGradient,
              onCategoryTap: onCategoryTap,
            ),
          ],
        );
      },
    );
  }
}
```

Save to `lib/features/analysis/division_summary_tab.dart`.

- [ ] **Step 3: 정적 분석으로 컴파일 확인**

Run: `flutter analyze lib/features/analysis`
Expected: `No issues found!`

- [ ] **Step 4: 커밋**

```bash
git add lib/features/analysis/division_summary_content.dart lib/features/analysis/division_summary_tab.dart
git commit -m "feat(analysis): add reusable division summary content and tab widgets"
```

---

### Task 5: 지출 전용 확장 데이터 모델

`ExpenseCategorySeqItem`(카테고리 상세)에 `categoryId`/`categorySeq`를 추가한다 — 기존 `ExpenseCategorySeqItem`([lib/features/dashboard/viewmodels/expense_viewmodel.dart:32-51](../../../lib/features/dashboard/viewmodels/expense_viewmodel.dart))은 이름만 갖고 있어 필터 이동에 쓸 ID가 없었다. 원본 데이터(`CategorySumResponse.data` 안의 `CategorySeqItem`)에는 `categorySeq` ID가 이미 있으므로 이번에 같이 담는다. `ExpenseMemberItem`(주체별 지출)은 신규.

**Files:**
- Create: `lib/features/analysis/expense_summary_data.dart`
- Test: `test/features/analysis/expense_summary_data_test.dart`

- [ ] **Step 1: 실패하는 단위 테스트 작성**

```dart
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
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/features/analysis/expense_summary_data_test.dart`
Expected: FAIL — `expense_summary_data.dart`를 찾을 수 없음.

- [ ] **Step 3: 데이터 모델 + 빌더 함수 작성**

```dart
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
```

Save to `lib/features/analysis/expense_summary_data.dart`.

- [ ] **Step 4: 테스트 실행해서 통과 확인**

Run: `flutter test test/features/analysis/expense_summary_data_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: 커밋**

```bash
git add lib/features/analysis/expense_summary_data.dart test/features/analysis/expense_summary_data_test.dart
git commit -m "feat(analysis): add expense-only breakdown models (category detail, member)"
```

---

### Task 6: `ExpenseSummaryViewModel`

`DivisionSummaryViewModel`을 상속하지 않고(정적 헬퍼만 재사용하는 조합 방식 — 주체별 지출을 위해 `MemberService` 호출이 추가로 필요해서 `load()`를 통째로 새로 써야 하기 때문), 지출 데이터를 전부 fetch한다.

**Files:**
- Create: `lib/features/analysis/expense_summary_viewmodel.dart`

- [ ] **Step 1: 뷰모델 작성**

```dart
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/models/member_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/data/services/member_service.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/analysis/division_summary_viewmodel.dart';
import 'package:account_book_vibe/features/analysis/expense_summary_data.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

class ExpenseSummaryViewModel extends ChangeNotifier {
  ExpenseSummaryViewModel(this.period) {
    period.addListener(load);
  }

  final DashboardPeriodViewModel period;

  bool isLoading = false;
  String? errorMessage;
  ExpenseSummaryData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = period.range;
      final prevRange = period.prevRange;
      final chartRange = period.chartRange;
      final needsChartFetch = chartRange != range;

      final results = await Future.wait([
        AccountService.instance.getAccounts(
          strtDt: range.strtDt, endDt: range.endDt, divisionId: Division.expense,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense, strtDt: range.strtDt, endDt: range.endDt,
        ),
        AccountService.instance.getAccounts(
          strtDt: prevRange.strtDt, endDt: prevRange.endDt, divisionId: Division.expense,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense, strtDt: prevRange.strtDt, endDt: prevRange.endDt,
        ),
        MemberService.instance.getMemberSum(
          divisionId: Division.expense, strtDt: range.strtDt, endDt: range.endDt,
        ),
        if (needsChartFetch)
          AccountService.instance.getAccounts(
            strtDt: chartRange.strtDt, endDt: chartRange.endDt, divisionId: Division.expense,
          ),
      ]);

      final currentAccounts = results[0] as List<AccountListResponse>;
      final currentCatSums = results[1] as List<CategorySumResponse>;
      final prevAccounts = results[2] as List<AccountListResponse>;
      final prevCatSums = results[3] as List<CategorySumResponse>;
      final memberSums = results[4] as List<MemberSumResponse>;
      final chartAccounts =
          needsChartFetch ? results[5] as List<AccountListResponse> : currentAccounts;

      final topTx = [...currentAccounts]..sort((a, b) => b.price.compareTo(a.price));

      data = ExpenseSummaryData(
        summary: DivisionSummaryData(
          totalAmount: currentAccounts.fold(0, (s, e) => s + e.price),
          prevPeriodAmount: prevAccounts.fold(0, (s, e) => s + e.price),
          monthlyAmounts: DivisionSummaryViewModel.buildMonthlyTotals(
            chartAccounts, chartRange.strtDt, chartRange.endDt,
          ),
          categoryBreakdown:
              DivisionSummaryViewModel.buildCategoryBreakdown(currentCatSums, prevCatSums),
          changeLabel: period.changeLabel,
          chartHighlightMonth: period.chartHighlightMonth,
        ),
        categorySeqBreakdown: buildExpenseCategorySeqBreakdown(currentCatSums, prevCatSums),
        memberBreakdown: buildExpenseMemberBreakdown(memberSums),
        topTransactions: topTx.take(10).toList(),
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    period.removeListener(load);
    super.dispose();
  }
}
```

Save to `lib/features/analysis/expense_summary_viewmodel.dart`.

- [ ] **Step 2: 정적 분석 확인**

Run: `flutter analyze lib/features/analysis`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/analysis/expense_summary_viewmodel.dart
git commit -m "feat(analysis): add expense summary viewmodel with member breakdown"
```

---

### Task 7: `ExpenseAnalysisTab` 위젯

`DivisionSummaryContent` + 카테고리 상세 + 주체별 지출(신규, [lib/features/expense/expense_member_screen.dart:130-178](../../../lib/features/expense/expense_member_screen.dart)의 `UserAvatar`+`ProgressRow` 조합을 이식) + TOP10을 조합한다.

**Files:**
- Create: `lib/features/analysis/expense_analysis_tab.dart`

- [ ] **Step 1: 위젯 작성**

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/category_emojis.dart';
import 'package:account_book_vibe/core/constants/member.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/analysis/division_summary_content.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/analysis/expense_summary_data.dart';
import 'package:account_book_vibe/features/analysis/expense_summary_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/progress_row.dart';
import 'package:account_book_vibe/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

const _expenseHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4C0519), Color(0xFF7F1D1D)],
);

class ExpenseAnalysisTab extends StatelessWidget {
  const ExpenseAnalysisTab({
    super.key,
    required this.vm,
    this.onCategoryTap,
    this.onCategorySeqTap,
    this.onMemberTap,
  });

  final ExpenseSummaryViewModel vm;
  final void Function(DivisionCategoryItem item)? onCategoryTap;
  final void Function(ExpenseCategorySeqItem item)? onCategorySeqTap;
  final void Function(ExpenseMemberItem item)? onMemberTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.colorExpense),
          );
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DivisionSummaryContent(
              data: data.summary,
              title: '총 지출',
              accentColor: AppColors.colorExpense,
              heroGradient: _expenseHeroGradient,
              onCategoryTap: onCategoryTap,
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '카테고리 상세',
              child: Column(
                children: data.categorySeqBreakdown
                    .map((e) => _CategorySeqRow(item: e, onTap: onCategorySeqTap))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '주체별 지출',
              child: Column(
                children: data.memberBreakdown
                    .asMap()
                    .entries
                    .map((entry) => _MemberRow(
                          item: entry.value,
                          colorIndex: entry.key,
                          onTap: onMemberTap,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '최대 단건 지출 TOP 10',
              child: Column(
                children: data.topTransactions
                    .map((tx) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              UserAvatar(
                                memberIndex: tx.memberId.codeUnits.fold(0, (a, b) => a + b) %
                                    AppColors.memberColors.length,
                                imagePath: Member.images[tx.memberId],
                                name: tx.memberNm,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      FormatUtil.formatCategoryDesc(
                                          tx.categoryNm, tx.categorySeqNm, remark: tx.remark),
                                      style: AppTextStyles.textBodySm
                                          .copyWith(color: AppColors.colorTextPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      FormatUtil.formatDateShort(tx.accountDt),
                                      style: AppTextStyles.textCaption
                                          .copyWith(color: AppColors.colorTextDisabled),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-₩${FormatUtil.formatPrice(tx.price)}',
                                style: AppTextStyles.textBodySm.copyWith(
                                  color: AppColors.colorExpense,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategorySeqRow extends StatelessWidget {
  const _CategorySeqRow({required this.item, this.onTap});

  final ExpenseCategorySeqItem item;
  final void Function(ExpenseCategorySeqItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    final changeRate = item.changeRate;
    final hasChange = item.prevPeriodAmount > 0;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Row(
              children: [
                Text(CategoryEmojis.getEmoji(item.categoryNm), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.categorySeqNm,
                          style: AppTextStyles.textBodySm.copyWith(color: AppColors.colorTextPrimary)),
                      Text(item.categoryNm,
                          style: AppTextStyles.textCaption.copyWith(color: AppColors.colorTextDisabled)),
                    ],
                  ),
                ),
                if (hasChange)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        changeRate >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 16,
                        color: changeRate >= 0 ? AppColors.colorExpense : AppColors.colorProfit,
                      ),
                      Text(
                        '${(changeRate.abs() * 100).toStringAsFixed(1)}%',
                        style: AppTextStyles.textBodySm.copyWith(
                          color: changeRate >= 0 ? AppColors.colorExpense : AppColors.colorProfit,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                Text(
                  '₩${FormatUtil.formatPrice(item.amount)}',
                  style: AppTextStyles.textBodySm
                      .copyWith(color: AppColors.colorTextPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: item.ratio.clamp(0.0, 1.0),
                backgroundColor: AppColors.colorBgElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.colorExpense),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.item, required this.colorIndex, this.onTap});

  final ExpenseMemberItem item;
  final int colorIndex;
  final void Function(ExpenseMemberItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.memberColors[colorIndex % AppColors.memberColors.length];
    final memberIndex =
        item.memberId.codeUnits.fold(0, (a, b) => a + b) % AppColors.memberColors.length;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(item),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            UserAvatar(
              memberIndex: memberIndex,
              imagePath: Member.images[item.memberId],
              name: item.memberNm,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProgressRow(
                label: item.memberNm,
                value: '₩${FormatUtil.formatPrice(item.amount)} (${(item.ratio * 100).toStringAsFixed(1)}%)',
                percentage: item.ratio,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.colorBgCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.textBodySm.copyWith(color: AppColors.colorTextSecondary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
```

Save to `lib/features/analysis/expense_analysis_tab.dart`.

**주의:** `AccountListResponse`에 `remark` 필드가 있는지 확인 필요 — [lib/data/models/account_model.dart](../../../lib/data/models/account_model.dart)를 열어 필드명을 확인하고, 다르면(예: `remark` 대신 다른 이름) 위 TOP10 섹션의 `remark: tx.remark` 부분을 실제 필드명으로 고친다 (기존 `_ExpenseContent`의 TOP10 섹션 코드를 그대로 옮긴 것이므로 원본에서 이미 검증된 필드명이면 수정 불필요).

- [ ] **Step 2: 정적 분석 확인**

Run: `flutter analyze lib/features/analysis`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/analysis/expense_analysis_tab.dart
git commit -m "feat(analysis): add expense analysis tab with category detail, member, top10 sections"
```

---

### Task 8: `AnalysisScreen`

**Files:**
- Create: `lib/features/analysis/analysis_screen.dart`

- [ ] **Step 1: 화면 작성**

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/analysis/division_summary_tab.dart';
import 'package:account_book_vibe/features/analysis/division_summary_viewmodel.dart';
import 'package:account_book_vibe/features/analysis/expense_analysis_tab.dart';
import 'package:account_book_vibe/features/analysis/expense_summary_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/period_selector.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _incomeHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF042F2E), Color(0xFF115E59)],
);

const _investHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF431407), Color(0xFF9A3412)],
);

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late final DashboardPeriodViewModel _period;
  late final ExpenseSummaryViewModel _expenseVm;
  late final DivisionSummaryViewModel _incomeVm;
  late final DivisionSummaryViewModel _investVm;
  late final TabController _tabController;
  bool _periodExpanded = false;

  @override
  void initState() {
    super.initState();
    _period = DashboardPeriodViewModel();
    _expenseVm = ExpenseSummaryViewModel(_period)..load();
    _incomeVm = DivisionSummaryViewModel(Division.income, _period)..load();
    _investVm = DivisionSummaryViewModel(Division.invest, _period)..load();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _period.dispose();
    _expenseVm.dispose();
    _incomeVm.dispose();
    _investVm.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 카드 클릭으로 가계부 목록 이동이 가능한 기간(단일 월)인지 여부.
  bool get _canNavigateToList =>
      _period.period == DashboardPeriod.singleMonth ||
      _period.period == DashboardPeriod.thisMonth;

  int get _navYear =>
      _period.period == DashboardPeriod.singleMonth ? _period.selectedYear : DateTime.now().year;
  int get _navMonth =>
      _period.period == DashboardPeriod.singleMonth ? _period.selectedMonth : DateTime.now().month;

  void _goToAccountList(AccountListExtra extra) {
    context.push('/accountList', extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: MainAppBar(
        showMenuButton: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(88 + (_periodExpanded ? 48 : 0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PeriodSelector(
                  vm: _period,
                  onExpandedChanged: (expanded) => setState(() => _periodExpanded = expanded),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.colorAccentTeal,
                labelColor: AppColors.colorAccentTeal,
                unselectedLabelColor: AppColors.colorTextSecondary,
                labelStyle: AppTextStyles.textBodySm.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.textBodySm,
                tabs: const [Tab(text: '지출'), Tab(text: '수입'), Tab(text: '투자')],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExpenseAnalysisTab(
            vm: _expenseVm,
            onCategoryTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.expense,
                      categoryId: item.categoryId,
                      year: _navYear,
                      month: _navMonth,
                    )),
            onCategorySeqTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.expense,
                      categoryId: item.categoryId,
                      categorySeq: item.categorySeq,
                      year: _navYear,
                      month: _navMonth,
                    )),
            onMemberTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.expense,
                      memberId: item.memberId,
                      year: _navYear,
                      month: _navMonth,
                    )),
          ),
          DivisionSummaryTab(
            vm: _incomeVm,
            title: '총 수입',
            accentColor: AppColors.colorIncome,
            heroGradient: _incomeHeroGradient,
            onCategoryTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.income,
                      categoryId: item.categoryId,
                      year: _navYear,
                      month: _navMonth,
                    )),
          ),
          DivisionSummaryTab(
            vm: _investVm,
            title: '총 투자',
            accentColor: AppColors.colorInvest,
            heroGradient: _investHeroGradient,
            onCategoryTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.invest,
                      categoryId: item.categoryId,
                      year: _navYear,
                      month: _navMonth,
                    )),
          ),
        ],
      ),
      floatingActionButton: GradientFAB(
        heroTag: 'addAccountAnalysis',
        icon: Icons.add,
        onPressed: () async {
          final result = await context.push<String>('/account');
          if (!context.mounted) return;
          _expenseVm.load();
          _incomeVm.load();
          _investVm.load();
          if (result != null) {
            AppToast.show(context, '$result 완료!!!', type: ToastType.success);
          }
        },
      ),
    );
  }
}
```

Save to `lib/features/analysis/analysis_screen.dart`.

- [ ] **Step 2: 정적 분석 확인**

Run: `flutter analyze lib/features/analysis`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/analysis/analysis_screen.dart
git commit -m "feat(analysis): add analysis screen with expense/income/invest sub-tabs"
```

---

### Task 9: `HomeScreen`

구 `DashboardScreen`의 개요 탭 부분만 승격한다. `OverviewTab`, `DashboardSharedViewModel`, `DashboardOverviewViewModel`, `CalendarSummaryViewModel`은 변경 없이 재사용.

**Files:**
- Create: `lib/features/home/home_screen.dart`

- [ ] **Step 1: 화면 작성**

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_shared_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/tabs/overview_tab.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/period_selector.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DashboardPeriodViewModel _period;
  late final DashboardSharedViewModel _shared;
  late final DashboardOverviewViewModel _overviewVm;
  late final CalendarSummaryViewModel _calendarVm;
  bool _periodExpanded = false;

  @override
  void initState() {
    super.initState();
    _period = DashboardPeriodViewModel();
    _shared = DashboardSharedViewModel(_period)..load();
    _overviewVm = DashboardOverviewViewModel(_shared)..load();
    _calendarVm = CalendarSummaryViewModel()..load();
  }

  @override
  void dispose() {
    _period.dispose();
    _shared.dispose();
    _overviewVm.dispose();
    _calendarVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: MainAppBar(
        showMenuButton: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40 + (_periodExpanded ? 48 : 0)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PeriodSelector(
              vm: _period,
              onExpandedChanged: (expanded) => setState(() => _periodExpanded = expanded),
            ),
          ),
        ),
      ),
      body: OverviewTab(vm: _overviewVm, calendarVm: _calendarVm, periodVm: _period),
      floatingActionButton: GradientFAB(
        heroTag: 'addAccountHome',
        icon: Icons.add,
        onPressed: () async {
          final result = await context.push<String>('/account');
          if (!context.mounted) return;
          _shared.load();
          _overviewVm.load();
          _calendarVm.load();
          if (result != null) {
            AppToast.show(context, '$result 완료!!!', type: ToastType.success);
          }
        },
      ),
    );
  }
}
```

Save to `lib/features/home/home_screen.dart`.

- [ ] **Step 2: 정적 분석 확인**

Run: `flutter analyze lib/features/home`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/home/home_screen.dart
git commit -m "feat(home): add home screen (promoted from dashboard overview tab)"
```

---

### Task 10: `AssetListBody` 추출

`AssetListScreen`([lib/features/asset/asset_list_screen.dart](../../../lib/features/asset/asset_list_screen.dart), 총 430줄)의 `Scaffold`/`AppBar`/`Drawer`/FAB을 제외한 본문 렌더링 로직을 `AssetListBody`로 뽑는다. `AssetListScreen`은 당장은 이 위젯을 감싸는 thin wrapper로 남긴다 — 아직 `app_router.dart`가 `/asset` → `AssetListScreen`을 가리키고 있어서(Task 13에서 바뀜), 지금 완전히 지우면 라우터가 깨진다.

**Files:**
- Create: `lib/features/asset/asset_list_body.dart`
- Modify: `lib/features/asset/asset_list_screen.dart`

- [ ] **Step 1: `AssetListBody` 작성**

기존 파일의 119번째 줄(`// ── Body ──` 주석) 부터 430번째 줄(EOF)까지의 모든 private 위젯(`_AssetBody`, `_SummaryCard`, `_StatCell`, `_AssetGroupSection` 등 전부)을 **그대로, 한 글자도 바꾸지 않고** 새 파일로 옮긴다. 그 위에 로딩/에러/빈 상태 분기(원본 63-116줄의 `ListenableBuilder` 부분)를 감싸는 공개 위젯을 추가한다:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/features/asset/asset_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_badge.dart';
import 'package:account_book_vibe/shared/widgets/app_list_card.dart';
import 'package:account_book_vibe/shared/widgets/asset_avatar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';

/// 자산 목록 본문(요약/그룹/아이템). Scaffold/AppBar/FAB은 호출부(AssetHubScreen)가 소유.
class AssetListBody extends StatelessWidget {
  const AssetListBody({
    super.key,
    required this.vm,
    required this.onRefresh,
    required this.onEdit,
  });

  final AssetViewModel vm;
  final Future<void> Function() onRefresh;
  final Future<void> Function(MyAssetItemResponse item) onEdit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.colorAccentTeal),
          );
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: onRefresh);
        }
        final data = vm.assetData;
        if (data == null) return const EmptyView();
        return _AssetBody(data: data, onRefresh: onRefresh, onEdit: onEdit);
      },
    );
  }
}

// ↓↓↓ 여기부터 lib/features/asset/asset_list_screen.dart의 119~430줄
//     (_AssetBody, _SummaryCard, _StatCell, _AssetGroupSection 등)을
//     변경 없이 그대로 붙여넣는다. import는 위 목록으로 충분한지 확인하고
//     원본 파일 상단(1~17줄)의 import 중 여기서 쓰는 것만 가져온다
//     (MainAppBar/AppDrawer/AppToast/GradientButton/go_router는 불필요).
```

원본 파일에서 `context.push<String>('/myAsset', extra: item)` 같은 네비게이션 호출이 이 영역 안에 있다면(`onEdit` 콜백 내부), 그 부분은 호출부(`AssetHubScreen`, Task 11)로 옮겨지고 여기서는 `onEdit`/`onRefresh` 콜백만 호출하는 형태여야 한다 — 원본 63-116줄을 보면 이미 `onEdit`이 콜백으로 분리되어 있으므로 추가 변경 없이 그대로 옮기면 된다.

Save to `lib/features/asset/asset_list_body.dart`.

- [ ] **Step 2: `AssetListScreen`을 thin wrapper로 축소**

`lib/features/asset/asset_list_screen.dart`를 다음으로 교체 (기존 `_AssetListScreenState`의 `_vm`/`initState`/`didChangeDependencies`/`dispose`/`_onRefresh`는 유지, `build()`만 `AssetListBody` 사용으로 축소, 아래로 옮긴 private 위젯들은 전부 제거):

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/features/asset/asset_list_body.dart';
import 'package:account_book_vibe/features/asset/asset_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssetListScreen extends StatefulWidget {
  final String? toastMessage;

  const AssetListScreen({super.key, this.toastMessage});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  late final AssetViewModel _vm;

  String get _todayDt {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _vm = AssetViewModel();
    _vm.loadAssets(strtDt: _todayDt, endDt: _todayDt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.toastMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppToast.show(context, widget.toastMessage!);
      });
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _vm.refreshAssets(_todayDt);
  }

  Future<void> _onEdit(item) async {
    final result = await context.push<String>('/myAsset', extra: item);
    if (result != null && context.mounted) {
      AppToast.show(context, result);
      await _vm.loadAssets(strtDt: _todayDt, endDt: _todayDt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AssetListBody(vm: _vm, onRefresh: _onRefresh, onEdit: _onEdit),
        ),
      ),
      floatingActionButton: GradientFAB(
        heroTag: 'addAsset',
        icon: Icons.add,
        onPressed: () async {
          final result = await context.push<String>('/myAsset');
          if (result != null && context.mounted) {
            AppToast.show(context, result);
            await _vm.loadAssets(strtDt: _todayDt, endDt: _todayDt);
          }
        },
      ),
    );
  }
}
```

(`_onEdit`의 `item` 파라미터 타입은 `AssetListBody.onEdit`이 요구하는 `MyAssetItemResponse`로 명시 — `import 'package:account_book_vibe/data/models/my_asset_model.dart';` 추가하고 `Future<void> _onEdit(MyAssetItemResponse item) async {`로 고친다.)

`ErrorView` import는 이제 `asset_list_screen.dart`에서 안 쓰므로 제거 대상이지만, 위 코드에는 이미 안 넣었다 — `flutter analyze`가 unused import를 잡아주면 그때 지운다.

- [ ] **Step 3: 정적 분석 + 기존 테스트 확인**

Run: `flutter analyze lib/features/asset`
Expected: `No issues found!` (unused import 경고 있으면 제거)

Run: `flutter test`
Expected: 기존 테스트 전부 PASS (동작 변경 없는 순수 리팩터링이므로 회귀 없어야 함)

- [ ] **Step 4: 커밋**

```bash
git add lib/features/asset/asset_list_body.dart lib/features/asset/asset_list_screen.dart
git commit -m "refactor(asset): extract AssetListBody from AssetListScreen"
```

---

### Task 11: `AssetHubScreen`

**Files:**
- Create: `lib/features/asset/asset_hub_screen.dart`

- [ ] **Step 1: 화면 작성**

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/features/asset/asset_list_body.dart';
import 'package:account_book_vibe/features/asset/asset_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/tabs/asset_tab.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart' as dashboard;
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssetHubScreen extends StatefulWidget {
  const AssetHubScreen({super.key});

  @override
  State<AssetHubScreen> createState() => _AssetHubScreenState();
}

class _AssetHubScreenState extends State<AssetHubScreen> with SingleTickerProviderStateMixin {
  late final dashboard.DashboardAssetViewModel _overviewVm;
  late final AssetViewModel _listVm;
  late final TabController _tabController;

  String get _todayDt {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _overviewVm = dashboard.DashboardAssetViewModel()..load();
    _listVm = AssetViewModel()..loadAssets(strtDt: _todayDt, endDt: _todayDt);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _overviewVm.dispose();
    _listVm.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _isListTab => _tabController.index == 1;

  Future<void> _refreshList() => _listVm.refreshAssets(_todayDt);

  Future<void> _editAsset(MyAssetItemResponse item) async {
    final result = await context.push<String>('/myAsset', extra: item);
    if (result != null && context.mounted) {
      AppToast.show(context, result);
      await _listVm.loadAssets(strtDt: _todayDt, endDt: _todayDt);
    }
  }

  Future<void> _addAsset() async {
    final result = await context.push<String>('/myAsset');
    if (result != null && context.mounted) {
      AppToast.show(context, result);
      await _listVm.loadAssets(strtDt: _todayDt, endDt: _todayDt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: MainAppBar(
        showMenuButton: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.colorAccentTeal,
            labelColor: AppColors.colorAccentTeal,
            unselectedLabelColor: AppColors.colorTextSecondary,
            labelStyle: AppTextStyles.textBodySm.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.textBodySm,
            tabs: const [Tab(text: '현황'), Tab(text: '목록')],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AssetTab(vm: _overviewVm),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AssetListBody(vm: _listVm, onRefresh: _refreshList, onEdit: _editAsset),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _isListTab ? GradientFAB(heroTag: 'addAsset', icon: Icons.add, onPressed: _addAsset) : null,
    );
  }
}
```

Save to `lib/features/asset/asset_hub_screen.dart`.

- [ ] **Step 2: 정적 분석 확인**

Run: `flutter analyze lib/features/asset`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/asset/asset_hub_screen.dart
git commit -m "feat(asset): add asset hub screen with overview/list sub-tabs"
```

---

### Task 12: `MainShellScreen` (바텀 네비게이션 셸)

**Files:**
- Create: `lib/features/shell/main_shell_screen.dart`

- [ ] **Step 1: 셸 위젯 작성**

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <({String emoji, String label})>[
    (emoji: '📋', label: '목록'),
    (emoji: '📊', label: '분석'),
    (emoji: '🏠', label: '홈'),
    (emoji: '🏢', label: '자산'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.colorBgSub,
          border: Border(top: BorderSide(color: AppColors.colorDivider)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      emoji: _items[i].emoji,
                      label: _items[i].label,
                      isActive: navigationShell.currentIndex == i,
                      onTap: () => navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.emoji,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.colorAccentTeal : AppColors.colorTextSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.textBodyXs.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
```

Save to `lib/features/shell/main_shell_screen.dart`.

- [ ] **Step 2: 정적 분석 확인**

Run: `flutter analyze lib/features/shell`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/shell/main_shell_screen.dart
git commit -m "feat(shell): add bottom navigation shell scaffold"
```

---

### Task 13: `app_router.dart`를 `StatefulShellRoute`로 재작성

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/account/account_list_screen.dart` (드로어 제거)

- [ ] **Step 1: `AccountListScreen`에서 드로어 제거**

`lib/features/account/account_list_screen.dart:86-87`:

```dart
      appBar: const MainAppBar(),
      drawer: const AppDrawer(),
```

를 다음으로 교체:

```dart
      appBar: const MainAppBar(showMenuButton: false),
```

그리고 이제 안 쓰는 `import 'package:account_book_vibe/shared/widgets/app_drawer.dart';` 줄을 삭제.

- [ ] **Step 2: `app_router.dart` 재작성**

```dart
import 'package:account_book_vibe/features/account/account_form_screen.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/account/account_list_screen.dart';
import 'package:account_book_vibe/features/analysis/analysis_screen.dart';
import 'package:account_book_vibe/features/asset/asset_accum_screen.dart';
import 'package:account_book_vibe/features/asset/asset_hub_screen.dart';
import 'package:account_book_vibe/features/asset/asset_ratio_screen.dart';
import 'package:account_book_vibe/features/asset/my_asset_form_screen.dart';
import 'package:account_book_vibe/features/expense/expense_category_screen.dart';
import 'package:account_book_vibe/features/expense/expense_dtl_screen.dart';
import 'package:account_book_vibe/features/expense/expense_member_screen.dart';
import 'package:account_book_vibe/features/expense/expense_monthly_chart_screen.dart';
import 'package:account_book_vibe/features/home/home_screen.dart';
import 'package:account_book_vibe/features/income/income_category_screen.dart';
import 'package:account_book_vibe/features/income/income_monthly_chart_screen.dart';
import 'package:account_book_vibe/features/invest/invest_category_screen.dart';
import 'package:account_book_vibe/features/invest/invest_monthly_chart_screen.dart';
import 'package:account_book_vibe/features/shell/main_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Page<T> _slidePage<T>(Widget child, GoRouterState state) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShellScreen(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/accountList',
            pageBuilder: (c, s) =>
                _slidePage(AccountListScreen(extra: s.extra as AccountListExtra?), s),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/analysis',
            pageBuilder: (c, s) => _slidePage(const AnalysisScreen(), s),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            pageBuilder: (c, s) => _slidePage(const HomeScreen(), s),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/asset',
            pageBuilder: (c, s) => _slidePage(const AssetHubScreen(), s),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/account',
      pageBuilder: (c, s) => _slidePage(AccountFormScreen(extra: s.extra), s),
    ),
    GoRoute(
      path: '/myAsset',
      pageBuilder: (c, s) => _slidePage(MyAssetFormScreen(extra: s.extra), s),
    ),
    // ── 구 드로어 라우트 (미사용 상태로 잠정 유지 — 후속 정리 작업에서 삭제 예정) ──
    GoRoute(
      path: '/expense',
      pageBuilder: (c, s) => _slidePage(const ExpenseCategoryScreen(), s),
    ),
    GoRoute(
      path: '/expenseDtl',
      pageBuilder: (c, s) => _slidePage(const ExpenseDtlScreen(), s),
    ),
    GoRoute(
      path: '/expense/member',
      pageBuilder: (c, s) => _slidePage(const ExpenseMemberScreen(), s),
    ),
    GoRoute(
      path: '/expense/chart',
      pageBuilder: (c, s) => _slidePage(const ExpenseMonthlyChartScreen(), s),
    ),
    GoRoute(
      path: '/income',
      pageBuilder: (c, s) => _slidePage(const IncomeCategoryScreen(), s),
    ),
    GoRoute(
      path: '/income/chart',
      pageBuilder: (c, s) => _slidePage(const IncomeMonthlyChartScreen(), s),
    ),
    GoRoute(
      path: '/invest',
      pageBuilder: (c, s) => _slidePage(const InvestCategoryScreen(), s),
    ),
    GoRoute(
      path: '/invest/chart',
      pageBuilder: (c, s) => _slidePage(const InvestMonthlyChartScreen(), s),
    ),
    GoRoute(
      path: '/asset/chart',
      pageBuilder: (c, s) => _slidePage(const AssetRatioScreen(), s),
    ),
    GoRoute(
      path: '/asset/accum',
      pageBuilder: (c, s) => _slidePage(const AssetAccumScreen(), s),
    ),
  ],
);
```

Save to `lib/core/router/app_router.dart` (전체 교체).

- [ ] **Step 3: 정적 분석 + 전체 테스트**

Run: `flutter analyze`
Expected: `No issues found!` — 특히 이제 `dashboard_screen.dart`/`dashboard/tabs/expense_tab.dart`/`dashboard/viewmodels/expense_viewmodel.dart`를 참조하는 코드가 없는지 확인 (다음 Task에서 삭제).

Run: `flutter test`
Expected: 전체 PASS

- [ ] **Step 4: 앱 실행해서 수동 확인**

Run: `flutter run -d chrome`

확인 항목:
- 바텀 네비게이션 4개 아이템(목록/분석/홈/자산)이 뜨고 탭 전환이 됨
- 각 브랜치에 햄버거 메뉴가 안 보임
- 분석 탭 안에서 지출/수입/투자 서브탭 전환, 카테고리 항목 탭 시 필터된 목록으로 이동 후 뒤로가기 정상
- 자산 탭 안에서 현황/목록 서브탭 전환, 목록 탭에서만 FAB이 보이고 자산 추가 후 목록 갱신
- 홈/분석 양쪽에서 FAB으로 거래 추가 — Hero 태그 충돌 에러(콘솔에 "There are multiple heroes" 메시지) 없는지 확인

- [ ] **Step 5: 커밋**

```bash
git add lib/core/router/app_router.dart lib/features/account/account_list_screen.dart
git commit -m "feat(router): switch to StatefulShellRoute bottom navigation"
```

---

### Task 14: 죽은 코드 정리

`/` 라우트가 더 이상 `DashboardScreen`을 쓰지 않으므로, 그 구현체(`DashboardScreen` 자체와 지출 탭 전용 로직)는 완전히 대체됐다. `AssetListScreen`도 `/asset` 라우트에서 빠졌으므로 마찬가지.

**Files:**
- Delete: `lib/features/dashboard/dashboard_screen.dart`
- Delete: `lib/features/dashboard/tabs/expense_tab.dart`
- Delete: `lib/features/dashboard/viewmodels/expense_viewmodel.dart`
- Delete: `test/features/dashboard/expense_viewmodel_test.dart`
- Delete: `lib/features/asset/asset_list_screen.dart`

- [ ] **Step 1: 삭제 전 참조 없음 확인**

```bash
grep -rn "DashboardScreen\b" lib/ --include="*.dart"
grep -rn "dashboard/tabs/expense_tab" lib/ --include="*.dart"
grep -rn "dashboard/viewmodels/expense_viewmodel" lib/ --include="*.dart"
grep -rn "AssetListScreen\b" lib/ --include="*.dart"
```

Expected: 각 명령의 결과가 비어있거나(삭제 대상 파일 자기 자신 제외) 참조가 전혀 없음. 뭔가 걸리면 그 참조부터 먼저 정리하고 이 태스크를 진행한다.

- [ ] **Step 2: 파일 삭제**

```bash
git rm lib/features/dashboard/dashboard_screen.dart
git rm lib/features/dashboard/tabs/expense_tab.dart
git rm lib/features/dashboard/viewmodels/expense_viewmodel.dart
git rm test/features/dashboard/expense_viewmodel_test.dart
git rm lib/features/asset/asset_list_screen.dart
```

- [ ] **Step 3: 정적 분석 + 전체 테스트**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: 전체 PASS

- [ ] **Step 4: 커밋**

```bash
git commit -m "chore: remove dead code superseded by analysis/home/asset-hub screens"
```

---

### Task 15: 최종 검증

**Files:** 없음 (검증만)

- [ ] **Step 1: 전체 테스트 스위트 실행**

Run: `flutter test`
Expected: 전체 PASS, 0 실패

- [ ] **Step 2: 정적 분석**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: 앱 실행 후 골든 패스 + 엣지 케이스 수동 확인**

Run: `flutter run -d chrome`

- 4개 바텀 네비 탭 전환 시 스크롤 위치/서브탭 선택이 유지되는지 (예: 자산→목록 탭에서 아래로 스크롤 → 다른 탭 갔다가 복귀 → 스크롤 위치 유지)
- 분석 탭: 지출/수입/투자 각각 로딩 → 데이터 정상 표시, 강제로 네트워크 끊어서(dev tools offline) 에러 뷰 + 재시도 확인
- 지출 탭의 카테고리별 비중/카테고리 상세/주체별 지출 항목 탭 → 필터된 가계부 목록으로 이동 → 뒤로가기 → 분석 탭 상태 유지 확인
- 기간을 "직전 3개월" 등 다월 기간으로 바꾼 뒤 카테고리 항목 탭 → 이동하지 않음(비활성) 확인
- 자산 탭: 목록 서브탭에서만 FAB 보임, 자산 추가 후 목록 갱신
- 드로어 관련 화면(예: 직접 URL로 `/expense` 접근) 여전히 동작하는지 (아직 안 지웠으므로)

- [ ] **Step 4: 결과 보고**

이상 없으면 완료. 문제 발견 시 해당 Task로 돌아가 수정 후 재검증.

---

## 후속 작업 (이 계획의 범위 밖)

- 구 드로어 라우트(`/expenseDtl`, `/expense/chart`, `/income/chart`, `/invest/chart`, `/asset/chart`, `/asset/accum`, `/expense/member`, `/expense`, `/income`, `/invest`) 및 대응 화면/뷰모델 삭제
- `AppDrawer`(`lib/shared/widgets/app_drawer.dart`) 위젯 삭제
- `app_router.dart`에서 위 라우트 정의 제거
