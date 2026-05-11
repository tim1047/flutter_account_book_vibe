# Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/dashboard` 라우트에 개요/지출/자산 3탭 대시보드 화면을 추가한다.

**Architecture:** 기존 MVVM + ChangeNotifier 패턴을 그대로 따른다. 새 백엔드 없이 기존 AccountService, CategoryService, MyAssetService 를 병렬 호출해 클라이언트에서 집계한다. 탭별 ViewModel은 `DashboardPeriodViewModel`을 생성자로 주입받아 기간이 바뀔 때 리로드한다.

**Tech Stack:** Flutter, ChangeNotifier, fl_chart, go_router, dio (기존 서비스 재사용)

---

## 파일 구조

### 신규 생성

```
lib/features/dashboard/
  dashboard_screen.dart                  # TabBar scaffold + PeriodSelector
  dashboard_period_viewmodel.dart        # 기간 선택기 VM (이번달/분기/올해/커스텀)
  tabs/
    overview_tab.dart                    # 개요 탭 (스크롤 뷰)
    expense_tab.dart                     # 지출 탭
    asset_tab.dart                       # 자산 탭
  viewmodels/
    overview_viewmodel.dart              # 개요 탭 데이터 집계
    expense_viewmodel.dart               # 지출 탭 데이터 집계
    asset_viewmodel.dart                 # 자산 탭 데이터 집계
  widgets/
    period_selector.dart                 # 기간 칩 선택기 위젯
    hero_metric_card.dart                # 순자산/지출/자산 헤더 카드
    mini_bar_row.dart                    # TOP5 미니 바 차트 한 행
    donut_legend_row.dart                # 도넛 차트 범례 행
    monthly_bar_chart.dart               # 월별 바 차트 (fl_chart)
    net_worth_line_chart.dart            # 순자산 라인 차트 (fl_chart)

test/features/dashboard/
  dashboard_period_viewmodel_test.dart
  overview_viewmodel_test.dart
  expense_viewmodel_test.dart
  asset_viewmodel_test.dart
```

### 수정

```
lib/core/router/app_router.dart          # /dashboard 라우트 추가
lib/shared/widgets/app_drawer.dart       # 📊 대시보드 항목 추가
```

---

## Task 1: DashboardPeriodViewModel

**Files:**
- Create: `lib/features/dashboard/dashboard_period_viewmodel.dart`
- Test: `test/features/dashboard/dashboard_period_viewmodel_test.dart`

- [ ] **Step 1: 테스트 파일 생성 및 실패 확인**

```dart
// test/features/dashboard/dashboard_period_viewmodel_test.dart
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardPeriodViewModel', () {
    test('기본값은 thisYear', () {
      final vm = DashboardPeriodViewModel();
      expect(vm.period, DashboardPeriod.thisYear);
    });

    test('thisMonth range는 이번달 첫날~마지막날', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisMonth);
      final now = DateTime.now();
      final y = now.year.toString();
      final m = now.month.toString().padLeft(2, '0');
      expect(vm.range.strtDt, '${y}${m}01');
      expect(vm.range.endDt.substring(0, 6), '$y$m');
    });

    test('thisYear range는 연도 0101 ~ 1231', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisYear);
      final y = DateTime.now().year.toString();
      expect(vm.range.strtDt, '${y}0101');
      expect(vm.range.endDt, '${y}1231');
    });

    test('thisQuarter range는 분기 시작월~끝월', () {
      final vm = DashboardPeriodViewModel();
      vm.select(DashboardPeriod.thisQuarter);
      final now = DateTime.now();
      final q = ((now.month - 1) ~/ 3);
      final startMonth = (q * 3 + 1).toString().padLeft(2, '0');
      expect(vm.range.strtDt.substring(4, 6), startMonth);
    });

    test('setCustomRange는 custom 기간으로 전환', () {
      final vm = DashboardPeriodViewModel();
      final start = DateTime(2025, 3, 1);
      final end = DateTime(2025, 5, 31);
      vm.setCustomRange(start, end);
      expect(vm.period, DashboardPeriod.custom);
      expect(vm.range.strtDt, '20250301');
      expect(vm.range.endDt, '20250531');
    });

    test('select 호출 시 notifyListeners 발생', () {
      final vm = DashboardPeriodViewModel();
      var notified = false;
      vm.addListener(() => notified = true);
      vm.select(DashboardPeriod.thisMonth);
      expect(notified, true);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
flutter test test/features/dashboard/dashboard_period_viewmodel_test.dart
```

Expected: compile error (파일 없음)

- [ ] **Step 3: DashboardPeriodViewModel 구현**

```dart
// lib/features/dashboard/dashboard_period_viewmodel.dart
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/foundation.dart';

enum DashboardPeriod { thisMonth, thisQuarter, thisYear, custom }

class DashboardPeriodViewModel extends ChangeNotifier {
  DashboardPeriod _period = DashboardPeriod.thisYear;
  DateTime? _customStart;
  DateTime? _customEnd;

  DashboardPeriod get period => _period;

  String get label => switch (_period) {
        DashboardPeriod.thisMonth => '이번 달',
        DashboardPeriod.thisQuarter => '이번 분기',
        DashboardPeriod.thisYear => '올해',
        DashboardPeriod.custom => '커스텀',
      };

  ({String strtDt, String endDt}) get range {
    final now = DateTime.now();
    return switch (_period) {
      DashboardPeriod.thisMonth => (
          strtDt: FormatUtil.toStrtDt(now.year, now.month),
          endDt: FormatUtil.toEndDt(now.year, now.month),
        ),
      DashboardPeriod.thisQuarter => _quarterRange(now),
      DashboardPeriod.thisYear => (
          strtDt: FormatUtil.toStrtDt(now.year, 0),
          endDt: FormatUtil.toEndDt(now.year, 0),
        ),
      DashboardPeriod.custom => (
          strtDt: _customStart != null
              ? _fmt(_customStart!)
              : FormatUtil.toStrtDt(now.year, 0),
          endDt: _customEnd != null
              ? _fmt(_customEnd!)
              : FormatUtil.toEndDt(now.year, 0),
        ),
    };
  }

  void select(DashboardPeriod period) {
    _period = period;
    notifyListeners();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _customStart = start;
    _customEnd = end;
    _period = DashboardPeriod.custom;
    notifyListeners();
  }

  ({String strtDt, String endDt}) _quarterRange(DateTime now) {
    final q = (now.month - 1) ~/ 3;
    final startMonth = q * 3 + 1;
    final endMonth = startMonth + 2;
    return (
      strtDt: FormatUtil.toStrtDt(now.year, startMonth),
      endDt: FormatUtil.toEndDt(now.year, endMonth),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/features/dashboard/dashboard_period_viewmodel_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: 커밋**

```bash
git add lib/features/dashboard/dashboard_period_viewmodel.dart test/features/dashboard/dashboard_period_viewmodel_test.dart
git commit -m "feat(dashboard): add DashboardPeriodViewModel with period range calculation"
```

---

## Task 2: 공통 데이터 모델

**Files:**
- Create: `lib/features/dashboard/viewmodels/overview_viewmodel.dart`
- Create: `lib/features/dashboard/viewmodels/expense_viewmodel.dart`
- Create: `lib/features/dashboard/viewmodels/asset_viewmodel.dart`

이 Task는 ViewModel 클래스의 데이터 클래스(순수 Dart) + 집계 static 메서드만 먼저 정의한다. API 호출은 Task 3~5에서 추가한다.

- [ ] **Step 1: 테스트 파일 생성**

```dart
// test/features/dashboard/overview_viewmodel_test.dart
import 'package:account_book_vibe/data/models/account_model.dart';
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
      expect(result.first.ratio, closeTo(0.526, 0.001));
    });
  });
}
```

```dart
// test/features/dashboard/expense_viewmodel_test.dart
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
      // accountDt 형식: 'YYYYMMDD'
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
  // AccountListResponse mock - uses copyWith pattern not available,
  // so construct minimal objects
  return data.map((e) => _FakeAccount(e.$1, e.$2)).toList();
}

class _FakeAccount {
  final String accountDt;
  final int price;
  const _FakeAccount(this.accountDt, this.price);
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
flutter test test/features/dashboard/
```

Expected: compile errors

- [ ] **Step 3: OverviewViewModel 데이터 클래스 + 집계 로직 구현**

```dart
// lib/features/dashboard/viewmodels/overview_viewmodel.dart
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

class CategoryExpenseItem {
  const CategoryExpenseItem({
    required this.categoryId,
    required this.categoryNm,
    required this.amount,
    required this.ratio,
  });

  final String categoryId;
  final String categoryNm;
  final int amount;
  final double ratio;
}

class DashboardOverviewData {
  const DashboardOverviewData({
    required this.netWorth,
    required this.prevMonthNetWorth,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalInvest,
    required this.topExpenseCategories,
    required this.recentTransactions,
    required this.netWorthHistory,
  });

  final int netWorth;
  final int prevMonthNetWorth;
  final int totalIncome;
  final int totalExpense;
  final int totalInvest;
  final List<CategoryExpenseItem> topExpenseCategories;
  final List<AccountListResponse> recentTransactions;
  final List<({String date, int amount})> netWorthHistory;

  int get savings => totalIncome - totalExpense;
  int get netWorthChange => netWorth - prevMonthNetWorth;
}

class DashboardOverviewViewModel extends ChangeNotifier {
  DashboardOverviewViewModel(this._period) {
    _period.addListener(load);
  }

  final DashboardPeriodViewModel _period;
  bool isLoading = false;
  String? errorMessage;
  DashboardOverviewData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = _period.range;
      final now = DateTime.now();
      final todayDt = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      // 전월 기준 (순자산 변화용)
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final prevDt = '${prevMonth.year}${prevMonth.month.toString().padLeft(2, '0')}01';

      final results = await Future.wait([
        // 현재 자산
        MyAssetService.instance.getMyAssets(strtDt: todayDt, endDt: todayDt),
        // 전월 자산
        MyAssetService.instance.getMyAssets(strtDt: prevDt, endDt: prevDt),
        // 수입
        AccountService.instance.getAccounts(
          divisionId: Division.income,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        // 지출
        AccountService.instance.getAccounts(
          divisionId: Division.expense,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        // 투자
        AccountService.instance.getAccounts(
          divisionId: Division.invest,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        // 지출 카테고리 합계
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        // 최근 거래
        AccountService.instance.getAccounts(
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        // 순자산 이력
        MyAssetService.instance.getMyAssetSum(
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
      ]);

      final currentAsset = results[0] as MyAssetListResponse;
      final prevAsset = results[1] as MyAssetListResponse;
      final incomeList = results[2] as List<AccountListResponse>;
      final expenseList = results[3] as List<AccountListResponse>;
      final investList = results[4] as List<AccountListResponse>;
      final catSums = results[5] as List<CategorySumResponse>;
      final allTxs = results[6] as List<AccountListResponse>;
      final assetSums = results[7] as List<MyAssetSumResponse>;

      final netWorthHistory = _buildNetWorthHistory(assetSums);

      data = DashboardOverviewData(
        netWorth: currentAsset.totNetWorthSumPrice,
        prevMonthNetWorth: prevAsset.totNetWorthSumPrice,
        totalIncome: incomeList.fold(0, (s, e) => s + e.price),
        totalExpense: expenseList.fold(0, (s, e) => s + e.price),
        totalInvest: investList.fold(0, (s, e) => s + e.price),
        topExpenseCategories: buildTopCategories(catSums),
        recentTransactions: (allTxs..sort((a, b) => b.accountDt.compareTo(a.accountDt))).take(5).toList(),
        netWorthHistory: netWorthHistory,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static List<CategoryExpenseItem> buildTopCategories(
    List<CategorySumResponse> sums,
  ) {
    final sorted = [...sums]..sort((a, b) => b.sumPrice.compareTo(a.sumPrice));
    final top = sorted.take(5).toList();
    final total = top.fold(0, (s, e) => s + e.sumPrice);
    if (total == 0) return [];
    return top.map((e) => CategoryExpenseItem(
          categoryId: e.categoryId,
          categoryNm: e.categoryNm,
          amount: e.sumPrice,
          ratio: e.sumPrice / total,
        )).toList();
  }

  static List<({String date, int amount})> _buildNetWorthHistory(
    List<MyAssetSumResponse> sums,
  ) {
    // assetId='0' 더미 제외, assetId='6' 는 부채 → 차감
    final byDateAsset = <String, int>{};
    final byDateDebt = <String, int>{};
    for (final s in sums) {
      if (s.assetId == '0') continue;
      if (s.assetId == '6') {
        byDateDebt[s.accumDt] = (byDateDebt[s.accumDt] ?? 0) + s.sumPrice;
      } else {
        byDateAsset[s.accumDt] = (byDateAsset[s.accumDt] ?? 0) + s.sumPrice;
      }
    }
    final allDates = {
      ...byDateAsset.keys,
      ...byDateDebt.keys,
    }.toList()..sort();
    return allDates.map((date) {
      final asset = byDateAsset[date] ?? 0;
      final debt = byDateDebt[date] ?? 0;
      return (date: date, amount: asset - debt);
    }).toList();
  }

  @override
  void dispose() {
    _period.removeListener(load);
    super.dispose();
  }
}
```

- [ ] **Step 4: ExpenseViewModel 구현**

```dart
// lib/features/dashboard/viewmodels/expense_viewmodel.dart
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

class ExpenseCategoryItem {
  const ExpenseCategoryItem({
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

class DashboardExpenseData {
  const DashboardExpenseData({
    required this.totalExpense,
    required this.prevPeriodExpense,
    required this.monthlyExpenses,
    required this.categoryBreakdown,
    required this.topTransactions,
  });

  final int totalExpense;
  final int prevPeriodExpense;
  final List<({String month, int amount})> monthlyExpenses;
  final List<ExpenseCategoryItem> categoryBreakdown;
  final List<AccountListResponse> topTransactions;

  double get changeRate {
    if (prevPeriodExpense == 0) return 0;
    return (totalExpense - prevPeriodExpense) / prevPeriodExpense;
  }
}

class DashboardExpenseViewModel extends ChangeNotifier {
  DashboardExpenseViewModel(this._period) {
    _period.addListener(load);
  }

  final DashboardPeriodViewModel _period;
  bool isLoading = false;
  String? errorMessage;
  DashboardExpenseData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = _period.range;
      // 전기간: 기간 길이만큼 이전
      final strt = _parseDate(range.strtDt);
      final end = _parseDate(range.endDt);
      final duration = end.difference(strt);
      final prevEnd = strt.subtract(const Duration(days: 1));
      final prevStrt = prevEnd.subtract(duration);

      final results = await Future.wait([
        AccountService.instance.getAccounts(
          divisionId: Division.expense,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        AccountService.instance.getAccounts(
          divisionId: Division.expense,
          strtDt: _fmtDate(prevStrt),
          endDt: _fmtDate(prevEnd),
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense,
          strtDt: _fmtDate(prevStrt),
          endDt: _fmtDate(prevEnd),
        ),
      ]);

      final current = results[0] as List<AccountListResponse>;
      final prev = results[1] as List<AccountListResponse>;
      final currentCats = results[2] as List<CategorySumResponse>;
      final prevCats = results[3] as List<CategorySumResponse>;

      final topTx = [...current]
        ..sort((a, b) => b.price.compareTo(a.price));

      data = DashboardExpenseData(
        totalExpense: current.fold(0, (s, e) => s + e.price),
        prevPeriodExpense: prev.fold(0, (s, e) => s + e.price),
        monthlyExpenses: buildMonthlyTotals(current, range.strtDt, range.endDt),
        categoryBreakdown: buildCategoryBreakdown(currentCats, prevCats),
        topTransactions: topTx.take(5).toList(),
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static List<ExpenseCategoryItem> buildCategoryBreakdown(
    List<CategorySumResponse> current,
    List<CategorySumResponse> prev,
  ) {
    final total = current.fold(0, (s, e) => s + e.sumPrice);
    if (total == 0) return [];
    final prevMap = {for (final e in prev) e.categoryId: e.sumPrice};
    final sorted = [...current]..sort((a, b) => b.sumPrice.compareTo(a.sumPrice));
    return sorted.map((e) => ExpenseCategoryItem(
          categoryId: e.categoryId,
          categoryNm: e.categoryNm,
          amount: e.sumPrice,
          ratio: e.sumPrice / total,
          prevPeriodAmount: prevMap[e.categoryId] ?? 0,
        )).toList();
  }

  static List<({String month, int amount})> buildMonthlyTotals(
    List<dynamic> transactions,
    String strtDt,
    String endDt,
  ) {
    final byMonth = <String, int>{};
    for (final tx in transactions) {
      final dt = (tx is AccountListResponse) ? tx.accountDt : (tx as dynamic).accountDt as String;
      if (dt.length >= 6) {
        final month = dt.substring(0, 6);
        byMonth[month] = (byMonth[month] ?? 0) + ((tx is AccountListResponse) ? tx.price : (tx as dynamic).price as int);
      }
    }
    final sorted = byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => (month: e.key, amount: e.value)).toList();
  }

  DateTime _parseDate(String yyyymmdd) => DateTime(
        int.parse(yyyymmdd.substring(0, 4)),
        int.parse(yyyymmdd.substring(4, 6)),
        int.parse(yyyymmdd.substring(6, 8)),
      );

  String _fmtDate(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _period.removeListener(load);
    super.dispose();
  }
}
```

- [ ] **Step 5: AssetViewModel 구현**

```dart
// lib/features/dashboard/viewmodels/asset_viewmodel.dart
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

class AssetCompositionItem {
  const AssetCompositionItem({
    required this.assetNm,
    required this.amount,
    required this.ratio,
  });

  final String assetNm;
  final int amount;
  final double ratio;
}

class DashboardAssetData {
  const DashboardAssetData({
    required this.totalAsset,
    required this.netWorth,
    required this.prevYearNetWorth,
    required this.assetComposition,
    required this.netWorthHistory,
    required this.assetGroups,
  });

  final int totalAsset;
  final int netWorth;
  final int prevYearNetWorth;
  final List<AssetCompositionItem> assetComposition;
  final List<({String date, int amount})> netWorthHistory;
  final List<MyAssetGroupResponse> assetGroups;

  int get debt => totalAsset - netWorth;
  int get yearlyGrowth => netWorth - prevYearNetWorth;
}

class DashboardAssetViewModel extends ChangeNotifier {
  DashboardAssetViewModel(this._period) {
    _period.addListener(load);
  }

  final DashboardPeriodViewModel _period;
  bool isLoading = false;
  String? errorMessage;
  DashboardAssetData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayDt = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final prevYearDt = '${now.year - 1}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final range = _period.range;

      final results = await Future.wait([
        MyAssetService.instance.getMyAssets(strtDt: todayDt, endDt: todayDt),
        MyAssetService.instance.getMyAssets(strtDt: prevYearDt, endDt: prevYearDt),
        MyAssetService.instance.getMyAssetSum(strtDt: range.strtDt, endDt: range.endDt),
      ]);

      final current = results[0] as MyAssetListResponse;
      final prevYear = results[1] as MyAssetListResponse;
      final sumHistory = results[2] as List<MyAssetSumResponse>;

      data = DashboardAssetData(
        totalAsset: current.totSumPrice,
        netWorth: current.totNetWorthSumPrice,
        prevYearNetWorth: prevYear.totNetWorthSumPrice,
        assetComposition: _buildComposition(current),
        netWorthHistory: _buildNetWorthHistory(sumHistory),
        assetGroups: current.data.values.toList(),
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static List<AssetCompositionItem> _buildComposition(MyAssetListResponse resp) {
    final total = resp.totSumPrice;
    if (total == 0) return [];
    return resp.data.values
        .where((g) => g.assetTotSumPrice > 0)
        .map((g) => AssetCompositionItem(
              assetNm: g.assetNm,
              amount: g.assetTotSumPrice,
              ratio: g.assetTotSumPrice / total,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static List<({String date, int amount})> _buildNetWorthHistory(
    List<MyAssetSumResponse> sums,
  ) {
    // assetId='0' 더미 제외, assetId='6' 는 부채 → 차감
    final byDateAsset = <String, int>{};
    final byDateDebt = <String, int>{};
    for (final s in sums) {
      if (s.assetId == '0') continue;
      if (s.assetId == '6') {
        byDateDebt[s.accumDt] = (byDateDebt[s.accumDt] ?? 0) + s.sumPrice;
      } else {
        byDateAsset[s.accumDt] = (byDateAsset[s.accumDt] ?? 0) + s.sumPrice;
      }
    }
    final allDates = {
      ...byDateAsset.keys,
      ...byDateDebt.keys,
    }.toList()..sort();
    return allDates.map((date) {
      final asset = byDateAsset[date] ?? 0;
      final debt = byDateDebt[date] ?? 0;
      return (date: date, amount: asset - debt);
    }).toList();
  }

  @override
  void dispose() {
    _period.removeListener(load);
    super.dispose();
  }
}
```

- [ ] **Step 6: 테스트 수정 — AccountListResponse mock 대신 buildMonthlyTotals 시그니처에 맞게 수정**

`expense_viewmodel_test.dart`의 `_makeAccounts` 부분을 실제 로직과 맞게 수정한다:

```dart
// test/features/dashboard/expense_viewmodel_test.dart 의 buildMonthlyTotals 테스트 부분
// _FakeAccount 대신 실제 AccountListResponse를 생성하려면 필드가 너무 많으므로
// buildMonthlyTotals 의 dynamic 접근 덕분에 _FakeAccount도 동작함
// 테스트 그대로 유지 가능
```

- [ ] **Step 7: 테스트 실행**

```bash
flutter test test/features/dashboard/
```

Expected: 모든 테스트 통과

- [ ] **Step 8: 커밋**

```bash
git add lib/features/dashboard/viewmodels/ test/features/dashboard/
git commit -m "feat(dashboard): add overview/expense/asset viewmodels with aggregation logic"
```

---

## Task 3: 공통 위젯

**Files:**
- Create: `lib/features/dashboard/widgets/period_selector.dart`
- Create: `lib/features/dashboard/widgets/hero_metric_card.dart`
- Create: `lib/features/dashboard/widgets/mini_bar_row.dart`
- Create: `lib/features/dashboard/widgets/donut_legend_row.dart`

- [ ] **Step 1: PeriodSelector 위젯 구현**

```dart
// lib/features/dashboard/widgets/period_selector.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key, required this.vm});

  final DashboardPeriodViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: DashboardPeriod.values.map((p) {
            final isSelected = vm.period == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => vm.select(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.colorAccentTeal
                        : AppColors.colorBgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.colorAccentTeal
                          : AppColors.colorDivider,
                    ),
                  ),
                  child: Text(
                    _label(p),
                    style: AppTextStyles.textBodySm.copyWith(
                      color: isSelected
                          ? AppColors.colorBgMain
                          : AppColors.colorTextSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _label(DashboardPeriod p) => switch (p) {
        DashboardPeriod.thisMonth => '이번 달',
        DashboardPeriod.thisQuarter => '이번 분기',
        DashboardPeriod.thisYear => '올해',
        DashboardPeriod.custom => '커스텀',
      };
}
```

- [ ] **Step 2: HeroMetricCard 위젯 구현**

```dart
// lib/features/dashboard/widgets/hero_metric_card.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/material.dart';

class HeroMetricCard extends StatelessWidget {
  const HeroMetricCard({
    super.key,
    required this.title,
    required this.amount,
    this.changeAmount,
    this.changeLabel,
    this.gradient,
    this.subtitle,
  });

  final String title;
  final int amount;
  final int? changeAmount;
  final String? changeLabel;
  final LinearGradient? gradient;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final change = changeAmount;
    final isPositive = change != null && change >= 0;
    final changeColor = isPositive ? AppColors.colorSuccess : AppColors.colorExpense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D2D50), Color(0xFF133B5C)],
            ),
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
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₩ ${FormatUtil.formatPrice(amount)}',
            style: AppTextStyles.textHeadingLg.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
          ],
          if (change != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${changeLabel ?? ''} ',
                  style: AppTextStyles.textBodySm.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: changeColor,
                  size: 14,
                ),
                Text(
                  '₩ ${FormatUtil.formatPrice(change.abs())}',
                  style: AppTextStyles.textBodySm.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: MiniBarRow 위젯 구현**

```dart
// lib/features/dashboard/widgets/mini_bar_row.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/material.dart';

class MiniBarRow extends StatelessWidget {
  const MiniBarRow({
    super.key,
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int amount;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: AppColors.colorBgElevated,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '${FormatUtil.formatPrice(amount ~/ 10000)}만',
              textAlign: TextAlign.end,
              style: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: DonutLegendRow 위젯 구현**

```dart
// lib/features/dashboard/widgets/donut_legend_row.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/material.dart';

class DonutLegendRow extends StatelessWidget {
  const DonutLegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.amount,
    required this.ratio,
    this.trailing,
  });

  final Color color;
  final String label;
  final int amount;
  final double ratio;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
          ),
          Text(
            '${(ratio * 100).toStringAsFixed(1)}%',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₩ ${FormatUtil.formatPrice(amount)}',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: 커밋**

```bash
git add lib/features/dashboard/widgets/
git commit -m "feat(dashboard): add shared dashboard widgets (period selector, hero card, mini bar, donut legend)"
```

---

## Task 4: 차트 위젯

**Files:**
- Create: `lib/features/dashboard/widgets/monthly_bar_chart.dart`
- Create: `lib/features/dashboard/widgets/net_worth_line_chart.dart`

- [ ] **Step 1: MonthlyBarChart 구현 (fl_chart BarChart)**

```dart
// lib/features/dashboard/widgets/monthly_bar_chart.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.data,
    required this.barColor,
    this.height = 120,
  });

  /// data: (month: 'YYYYMM', amount: int) 리스트, 월 오름차순
  final List<({String month, int amount})> data;
  final Color barColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('데이터 없음', style: AppTextStyles.textBodySm.copyWith(
            color: AppColors.colorTextSecondary,
          )),
        ),
      );
    }

    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final barGroups = data.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: maxAmount == 0 ? 0 : e.amount / maxAmount,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [barColor.withOpacity(0.6), barColor],
            ),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  final month = data[idx].month;
                  final m = month.length >= 6 ? month.substring(4, 6) : month;
                  return Text(
                    '${int.tryParse(m) ?? 0}월',
                    style: AppTextStyles.textBodyXs.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
          ),
          barTouchData: const BarTouchData(enabled: false),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: NetWorthLineChart 구현 (fl_chart LineChart)**

```dart
// lib/features/dashboard/widgets/net_worth_line_chart.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({
    super.key,
    required this.history,
    this.height = 120,
  });

  /// history: (date: 'YYYYMMDD', amount: int) 오름차순
  final List<({String date, int amount})> history;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('데이터 없음', style: AppTextStyles.textBodySm.copyWith(
            color: AppColors.colorTextSecondary,
          )),
        ),
      );
    }

    final amounts = history.map((e) => e.amount.toDouble()).toList();
    final minY = amounts.reduce((a, b) => a < b ? a : b);
    final maxY = amounts.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    final spots = history.asMap().entries.map((e) => FlSpot(
          e.key.toDouble(),
          e.value.amount.toDouble(),
        )).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.colorAccentTeal,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.colorAccentTeal.withOpacity(0.2),
                    AppColors.colorAccentTeal.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.colorDivider,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: AppTextStyles에 textBodyXs, textHeadingLg 존재 확인**

```bash
grep -n 'textBodyXs\|textHeadingLg\|textBodySm\|textBodyMd' lib/core/constants/app_text_styles.dart
```

없는 스타일이 있으면 `app_text_styles.dart`에 추가한다:

```dart
// 없는 경우만 추가
static const TextStyle textBodyXs = TextStyle(fontSize: 11, fontFamily: 'Pretendard');
static const TextStyle textHeadingLg = TextStyle(fontSize: 28, fontFamily: 'Pretendard');
```

- [ ] **Step 4: 커밋**

```bash
git add lib/features/dashboard/widgets/monthly_bar_chart.dart lib/features/dashboard/widgets/net_worth_line_chart.dart lib/core/constants/app_text_styles.dart
git commit -m "feat(dashboard): add monthly bar chart and net worth line chart widgets"
```

---

## Task 5: DashboardScreen 스캐폴드

**Files:**
- Create: `lib/features/dashboard/dashboard_screen.dart`

- [ ] **Step 1: DashboardScreen 구현**

```dart
// lib/features/dashboard/dashboard_screen.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/tabs/asset_tab.dart';
import 'package:account_book_vibe/features/dashboard/tabs/expense_tab.dart';
import 'package:account_book_vibe/features/dashboard/tabs/overview_tab.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/expense_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/period_selector.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final DashboardPeriodViewModel _period;
  late final DashboardOverviewViewModel _overviewVm;
  late final DashboardExpenseViewModel _expenseVm;
  late final DashboardAssetViewModel _assetVm;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _period = DashboardPeriodViewModel();
    _overviewVm = DashboardOverviewViewModel(_period)..load();
    _expenseVm = DashboardExpenseViewModel(_period)..load();
    _assetVm = DashboardAssetViewModel(_period)..load();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _period.dispose();
    _overviewVm.dispose();
    _expenseVm.dispose();
    _assetVm.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.colorBgMain,
        elevation: 0,
        title: Text(
          '📊 대시보드',
          style: AppTextStyles.textBodyLg.copyWith(
            color: AppColors.colorTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PeriodSelector(vm: _period),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.colorAccentTeal,
                labelColor: AppColors.colorAccentTeal,
                unselectedLabelColor: AppColors.colorTextSecondary,
                labelStyle: AppTextStyles.textBodySm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTextStyles.textBodySm,
                tabs: const [
                  Tab(text: '개요'),
                  Tab(text: '지출'),
                  Tab(text: '자산'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(vm: _overviewVm),
          ExpenseTab(vm: _expenseVm),
          AssetTab(vm: _assetVm),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: app_text_styles.dart에 textBodyLg 확인 후 없으면 추가**

```bash
grep -n 'textBodyLg' lib/core/constants/app_text_styles.dart
```

없으면:
```dart
static const TextStyle textBodyLg = TextStyle(fontSize: 18, fontFamily: 'Pretendard');
```

- [ ] **Step 3: 빈 탭 파일 생성 (컴파일 통과용)**

```dart
// lib/features/dashboard/tabs/overview_tab.dart
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:flutter/material.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.vm});
  final DashboardOverviewViewModel vm;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

```dart
// lib/features/dashboard/tabs/expense_tab.dart
import 'package:account_book_vibe/features/dashboard/viewmodels/expense_viewmodel.dart';
import 'package:flutter/material.dart';

class ExpenseTab extends StatelessWidget {
  const ExpenseTab({super.key, required this.vm});
  final DashboardExpenseViewModel vm;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

```dart
// lib/features/dashboard/tabs/asset_tab.dart
import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart';
import 'package:flutter/material.dart';

class AssetTab extends StatelessWidget {
  const AssetTab({super.key, required this.vm});
  final DashboardAssetViewModel vm;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

- [ ] **Step 4: 라우터 + 드로어 연결**

`lib/core/router/app_router.dart` 에 import와 라우트 추가:

```dart
// 추가할 import
import 'package:account_book_vibe/features/dashboard/dashboard_screen.dart';

// routes 리스트에 추가 (GoRoute 목록 안)
GoRoute(
  path: '/dashboard',
  pageBuilder: (c, s) => _slidePage(const DashboardScreen(), s),
),
```

`lib/shared/widgets/app_drawer.dart` 의 `_NavTile` 목록에 추가 (인사이트 아래):

```dart
_NavTile(
  emoji: '📊',
  label: '대시보드',
  path: '/dashboard',
  currentPath: currentPath,
),
```

- [ ] **Step 5: flutter analyze 실행**

```bash
flutter analyze lib/features/dashboard/ lib/core/router/app_router.dart lib/shared/widgets/app_drawer.dart
```

Expected: No errors

- [ ] **Step 6: 커밋**

```bash
git add lib/features/dashboard/dashboard_screen.dart lib/features/dashboard/tabs/ lib/core/router/app_router.dart lib/shared/widgets/app_drawer.dart lib/core/constants/app_text_styles.dart
git commit -m "feat(dashboard): add DashboardScreen scaffold with tab bar, period selector, router and drawer entry"
```

---

## Task 6: 개요 탭 UI

**Files:**
- Modify: `lib/features/dashboard/tabs/overview_tab.dart`

- [ ] **Step 1: OverviewTab 전체 구현**

```dart
// lib/features/dashboard/tabs/overview_tab.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/category_emojis.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/hero_metric_card.dart';
import 'package:account_book_vibe/features/dashboard/widgets/mini_bar_row.dart';
import 'package:account_book_vibe/features/dashboard/widgets/net_worth_line_chart.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.vm});

  final DashboardOverviewViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator(
            color: AppColors.colorAccentTeal,
          ));
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return _OverviewContent(data: data);
      },
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.data});

  final DashboardOverviewData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ① 순자산 히어로
        HeroMetricCard(
          title: '순자산 (Net Worth)',
          amount: data.netWorth,
          changeAmount: data.netWorthChange,
          changeLabel: '전월 대비',
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF312E81), Color(0xFF1E3A5F)],
          ),
        ),
        const SizedBox(height: 12),

        // ② 수지 + 투자 요약 2컬럼
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: '이번 달 수지',
                rows: [
                  ('수입', data.totalIncome, AppColors.colorIncome),
                  ('지출', data.totalExpense, AppColors.colorExpense),
                  ('저축', data.savings, AppColors.colorProfit),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: '투자 현황',
                rows: [
                  ('이번 기간', data.totalInvest, AppColors.colorInvest),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ③ 순자산 변화 차트
        _SectionCard(
          title: '순자산 변화',
          child: NetWorthLineChart(history: data.netWorthHistory),
        ),
        const SizedBox(height: 12),

        // ④ 지출 TOP 5
        _SectionCard(
          title: '지출 TOP 5 카테고리',
          child: Column(
            children: data.topExpenseCategories.map((e) {
              final emoji = CategoryEmojis.forCategory(e.categoryNm);
              return MiniBarRow(
                label: emoji,
                amount: e.amount,
                ratio: e.ratio,
                color: AppColors.colorExpense,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ⑤ 최근 거래
        _SectionCard(
          title: '최근 거래',
          trailing: TextButton(
            onPressed: () => context.go('/accountList'),
            child: Text('더보기', style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorAccentTeal,
            )),
          ),
          child: Column(
            children: data.recentTransactions.map((tx) {
              final isExpense = tx.divisionId == '3';
              final color = isExpense ? AppColors.colorExpense : AppColors.colorIncome;
              final sign = isExpense ? '-' : '+';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${tx.categorySeqNm}',
                        style: AppTextStyles.textBodySm.copyWith(
                          color: AppColors.colorTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$sign₩${FormatUtil.formatPrice(tx.price)}',
                      style: AppTextStyles.textBodySm.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorTextSecondary,
              )),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.rows});

  final String title;
  final List<(String, int, Color)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.textBodyXs.copyWith(
            color: AppColors.colorTextSecondary,
          )),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.$1, style: AppTextStyles.textBodySm.copyWith(
                  color: AppColors.colorTextSecondary,
                )),
                Text(
                  '₩${FormatUtil.formatPrice(r.$2)}',
                  style: AppTextStyles.textBodySm.copyWith(
                    color: r.$3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: CategoryEmojis.forCategory 메서드 확인 후 없으면 추가**

```bash
grep -n 'forCategory\|static' lib/core/constants/category_emojis.dart | head -20
```

없으면 `category_emojis.dart` 끝에 추가:
```dart
static String forCategory(String categoryNm) {
  // 카테고리명 기반 이모지 반환, 없으면 기본값
  return categoryEmojiMap[categoryNm] ?? '💸';
}
```
(기존 Map 변수명에 맞게 조정)

- [ ] **Step 3: flutter analyze**

```bash
flutter analyze lib/features/dashboard/tabs/overview_tab.dart
```

- [ ] **Step 4: 커밋**

```bash
git add lib/features/dashboard/tabs/overview_tab.dart lib/core/constants/category_emojis.dart
git commit -m "feat(dashboard): implement overview tab UI"
```

---

## Task 7: 지출 탭 UI

**Files:**
- Modify: `lib/features/dashboard/tabs/expense_tab.dart`

- [ ] **Step 1: ExpenseTab 전체 구현**

```dart
// lib/features/dashboard/tabs/expense_tab.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/expense_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/donut_legend_row.dart';
import 'package:account_book_vibe/features/dashboard/widgets/monthly_bar_chart.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpenseTab extends StatelessWidget {
  const ExpenseTab({super.key, required this.vm});

  final DashboardExpenseViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator(
            color: AppColors.colorExpense,
          ));
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return _ExpenseContent(data: data);
      },
    );
  }
}

class _ExpenseContent extends StatelessWidget {
  const _ExpenseContent({required this.data});

  final DashboardExpenseData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ① 총 지출 헤더
        _ExpenseHeroCard(data: data),
        const SizedBox(height: 12),

        // ② 카테고리 도넛 차트
        _SectionCard(
          title: '카테고리별 비중',
          child: _DonutSection(data: data),
        ),
        const SizedBox(height: 12),

        // ③ 월별 지출 바 차트
        _SectionCard(
          title: '월별 지출 추이',
          child: MonthlyBarChart(
            data: data.monthlyExpenses,
            barColor: AppColors.colorExpense,
          ),
        ),
        const SizedBox(height: 12),

        // ④ 카테고리 상세 리스트
        _SectionCard(
          title: '카테고리 상세',
          child: Column(
            children: data.categoryBreakdown.map((e) {
              final changeRate = e.changeRate;
              final hasChange = e.prevPeriodAmount > 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.categoryNm, style: AppTextStyles.textBodySm.copyWith(
                            color: AppColors.colorTextPrimary,
                          )),
                        ),
                        if (hasChange)
                          Text(
                            changeRate >= 0
                                ? '▲${(changeRate * 100).toStringAsFixed(1)}%'
                                : '▼${(changeRate.abs() * 100).toStringAsFixed(1)}%',
                            style: AppTextStyles.textBodySm.copyWith(
                              color: changeRate >= 0
                                  ? AppColors.colorExpense
                                  : AppColors.colorProfit,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          '₩${FormatUtil.formatPrice(e.amount)}',
                          style: AppTextStyles.textBodySm.copyWith(
                            color: AppColors.colorTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: e.ratio.clamp(0.0, 1.0),
                        backgroundColor: AppColors.colorBgElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.colorExpense,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ⑤ 최대 단건 지출 TOP 5
        _SectionCard(
          title: '최대 단건 지출 TOP 5',
          child: Column(
            children: data.topTransactions.map((tx) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tx.categorySeqNm,
                      style: AppTextStyles.textBodySm.copyWith(
                        color: AppColors.colorTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
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
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _ExpenseHeroCard extends StatelessWidget {
  const _ExpenseHeroCard({required this.data});
  final DashboardExpenseData data;

  @override
  Widget build(BuildContext context) {
    final change = data.changeRate;
    final isIncrease = change >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C0519), Color(0xFF7F1D1D)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.3),
          blurRadius: 12, offset: Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('총 지출', style: AppTextStyles.textBodySm.copyWith(
            color: AppColors.colorTextSecondary,
          )),
          const SizedBox(height: 6),
          Text('₩ ${FormatUtil.formatPrice(data.totalExpense)}',
            style: AppTextStyles.textHeadingLg.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w700,
            )),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isIncrease ? AppColors.colorExpense : AppColors.colorProfit,
              ),
              Text(
                '${(change.abs() * 100).toStringAsFixed(1)}% 전기 대비',
                style: AppTextStyles.textBodySm.copyWith(
                  color: isIncrease ? AppColors.colorExpense : AppColors.colorProfit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutSection extends StatelessWidget {
  const _DonutSection({required this.data});
  final DashboardExpenseData data;

  static const _colors = AppColors.assetChartColors;

  @override
  Widget build(BuildContext context) {
    if (data.categoryBreakdown.isEmpty) {
      return const SizedBox(height: 60, child: Center(child: Text('데이터 없음')));
    }
    final sections = data.categoryBreakdown.asMap().entries.map((e) {
      final color = _colors[e.key % _colors.length];
      return PieChartSectionData(
        value: e.value.ratio,
        color: color,
        radius: 40,
        title: '',
      );
    }).toList();

    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 28,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: data.categoryBreakdown.asMap().entries.map((e) {
              final color = _colors[e.key % _colors.length];
              return DonutLegendRow(
                color: color,
                label: e.value.categoryNm,
                amount: e.value.amount,
                ratio: e.value.ratio,
              );
            }).toList(),
          ),
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
          Text(title, style: AppTextStyles.textBodySm.copyWith(
            color: AppColors.colorTextSecondary,
          )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: flutter analyze**

```bash
flutter analyze lib/features/dashboard/tabs/expense_tab.dart
```

- [ ] **Step 3: 커밋**

```bash
git add lib/features/dashboard/tabs/expense_tab.dart
git commit -m "feat(dashboard): implement expense tab UI with donut chart and category breakdown"
```

---

## Task 8: 자산 탭 UI

**Files:**
- Modify: `lib/features/dashboard/tabs/asset_tab.dart`

- [ ] **Step 1: AssetTab 전체 구현**

```dart
// lib/features/dashboard/tabs/asset_tab.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/donut_legend_row.dart';
import 'package:account_book_vibe/features/dashboard/widgets/net_worth_line_chart.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AssetTab extends StatelessWidget {
  const AssetTab({super.key, required this.vm});

  final DashboardAssetViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator(
            color: AppColors.colorAccentIndigo,
          ));
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return _AssetContent(data: data);
      },
    );
  }
}

class _AssetContent extends StatelessWidget {
  const _AssetContent({required this.data});

  final DashboardAssetData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ① 순자산 헤더
        _AssetHeroCard(data: data),
        const SizedBox(height: 12),

        // ② 자산 구성 도넛
        _SectionCard(
          title: '자산 구성',
          child: _AssetDonutSection(data: data),
        ),
        const SizedBox(height: 12),

        // ③ 순자산 장기 라인 차트
        _SectionCard(
          title: '순자산 장기 추이',
          child: NetWorthLineChart(
            history: data.netWorthHistory,
            height: 140,
          ),
        ),
        const SizedBox(height: 12),

        // ④ 자산 항목별 리스트
        _SectionCard(
          title: '자산 항목',
          child: Column(
            children: data.assetGroups.map((g) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(g.assetNm, style: AppTextStyles.textBodySm.copyWith(
                      color: AppColors.colorTextPrimary,
                    )),
                  ),
                  Text(
                    '₩ ${FormatUtil.formatPrice(g.assetTotSumPrice)}',
                    style: AppTextStyles.textBodySm.copyWith(
                      color: AppColors.colorTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),

        // ⑤ 부채 현황 (부채 > 0 일 때만)
        if (data.debt > 0) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: '부채 현황',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('총 부채', style: AppTextStyles.textBodySm.copyWith(
                  color: AppColors.colorTextSecondary,
                )),
                Text(
                  '-₩ ${FormatUtil.formatPrice(data.debt)}',
                  style: AppTextStyles.textBodyMd.copyWith(
                    color: AppColors.colorExpense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AssetHeroCard extends StatelessWidget {
  const _AssetHeroCard({required this.data});
  final DashboardAssetData data;

  @override
  Widget build(BuildContext context) {
    final growth = data.yearlyGrowth;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.3),
          blurRadius: 12, offset: Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('순자산 (Net Worth)', style: AppTextStyles.textBodySm.copyWith(
            color: AppColors.colorTextSecondary,
          )),
          const SizedBox(height: 6),
          Text(
            '₩ ${FormatUtil.formatPrice(data.netWorth)}',
            style: AppTextStyles.textHeadingLg.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatChip(
                label: '총자산',
                value: '₩${FormatUtil.formatPrice(data.totalAsset)}',
                color: AppColors.colorProfit,
              )),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(
                label: '전년 대비',
                value: growth >= 0
                    ? '+₩${FormatUtil.formatPrice(growth)}'
                    : '-₩${FormatUtil.formatPrice(growth.abs())}',
                color: growth >= 0 ? AppColors.colorProfit : AppColors.colorExpense,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.textBodyXs.copyWith(
            color: AppColors.colorTextSecondary,
          )),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.textBodySm.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}

class _AssetDonutSection extends StatelessWidget {
  const _AssetDonutSection({required this.data});
  final DashboardAssetData data;

  static const _colors = AppColors.assetChartColors;

  @override
  Widget build(BuildContext context) {
    if (data.assetComposition.isEmpty) {
      return const SizedBox(height: 60, child: Center(child: Text('데이터 없음')));
    }
    final sections = data.assetComposition.asMap().entries.map((e) {
      final color = _colors[e.key % _colors.length];
      return PieChartSectionData(
        value: e.value.ratio,
        color: color,
        radius: 40,
        title: '',
      );
    }).toList();

    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 28,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: data.assetComposition.asMap().entries.map((e) {
              final color = _colors[e.key % _colors.length];
              return DonutLegendRow(
                color: color,
                label: e.value.assetNm,
                amount: e.value.amount,
                ratio: e.value.ratio,
              );
            }).toList(),
          ),
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
          Text(title, style: AppTextStyles.textBodySm.copyWith(
            color: AppColors.colorTextSecondary,
          )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: flutter analyze**

```bash
flutter analyze lib/features/dashboard/tabs/asset_tab.dart
```

- [ ] **Step 3: 전체 analyze**

```bash
flutter analyze lib/features/dashboard/
```

- [ ] **Step 4: 커밋**

```bash
git add lib/features/dashboard/tabs/asset_tab.dart
git commit -m "feat(dashboard): implement asset tab UI with net worth hero, donut chart, history line chart"
```

---

## Task 9: 최종 검증

- [ ] **Step 1: 전체 테스트 실행**

```bash
flutter test test/features/dashboard/
```

Expected: 모든 테스트 통과

- [ ] **Step 2: 전체 정적 분석**

```bash
flutter analyze
```

Expected: No errors (warning은 허용)

- [ ] **Step 3: 앱 빌드 확인**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: .superpowers 를 .gitignore에 추가**

```bash
grep -q '.superpowers' .gitignore || echo '.superpowers/' >> .gitignore
git add .gitignore
```

- [ ] **Step 5: 최종 커밋**

```bash
git add .gitignore
git commit -m "feat(dashboard): complete 3-tab dashboard (개요/지출/자산)"
```

---

## 체크리스트 (Spec vs Plan)

| 스펙 요구사항 | 구현 Task |
|---|---|
| 기간 선택기 (이번달/분기/올해/커스텀) | Task 1, 3 |
| 개요 탭: 순자산 히어로 + 전월 대비 | Task 6 |
| 개요 탭: 수지/투자 요약 2컬럼 | Task 6 |
| 개요 탭: 12개월 순자산 변화 차트 | Task 4, 6 |
| 개요 탭: 지출 TOP5 미니 바 | Task 3, 6 |
| 개요 탭: 최근 거래 5건 | Task 6 |
| 지출 탭: 총 지출 헤더 + 전기 대비 | Task 7 |
| 지출 탭: 카테고리 도넛 차트 | Task 7 |
| 지출 탭: 월별 지출 바 차트 | Task 4, 7 |
| 지출 탭: 카테고리 상세 리스트 + ▲▼ | Task 2, 7 |
| 지출 탭: 최대 단건 TOP5 | Task 7 |
| 자산 탭: 순자산 헤더 (총자산/부채/전년대비) | Task 8 |
| 자산 탭: 자산 구성 도넛 | Task 8 |
| 자산 탭: 순자산 장기 라인 차트 | Task 4, 8 |
| 자산 탭: 자산 항목별 리스트 | Task 8 |
| 자산 탭: 부채 현황 (있을 때만) | Task 8 |
| /dashboard 라우트 + 드로어 항목 | Task 5 |
| 새 백엔드 없이 기존 API 재사용 | Task 2 전체 |
