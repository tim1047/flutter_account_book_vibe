# Dashboard Asset Period Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 자산 탭의 기간 선택기를 전역에서 분리해 인라인 히스토리 기간 피커(3개월/6개월/1년)로 대체하고, 앱바의 전역 기간 선택기는 개요/지출 탭에서만 표시한다.

**Architecture:** `DashboardAssetViewModel`에서 `DashboardPeriodViewModel` 의존성을 제거하고 `AssetHistoryPeriod` 열거형을 자체 관리한다. `DashboardScreen`은 `TabController` 리스너를 통해 현재 탭에 따라 `preferredSize`를 동적으로 조정해 기간 선택기를 숨긴다. `AssetTab` 내부의 순자산 추이 섹션 헤더에 인라인 피커 위젯을 삽입한다.

**Tech Stack:** Flutter, ChangeNotifier, fl_chart, go_router (기존 구조 유지)

---

## 파일 구조

### 수정

```
lib/features/dashboard/viewmodels/asset_viewmodel.dart   # AssetHistoryPeriod 추가, 전역 period 의존 제거
lib/features/dashboard/dashboard_screen.dart              # 탭별 기간선택기 표시 제어
lib/features/dashboard/tabs/asset_tab.dart                # 인라인 히스토리 피커, _SectionCard trailing 추가
```

### 신규 생성

```
test/features/dashboard/asset_viewmodel_test.dart         # AssetHistoryPeriod 및 historyRange 테스트
```

---

## Task 1: AssetViewModel 리팩터링

**Files:**
- Modify: `lib/features/dashboard/viewmodels/asset_viewmodel.dart`
- Create: `test/features/dashboard/asset_viewmodel_test.dart`

### 변경 내용 요약

- `AssetHistoryPeriod` 열거형 추가 (`threeMonths` / `sixMonths` / `oneYear`)
- `DashboardAssetViewModel` 생성자에서 `DashboardPeriodViewModel` 파라미터 제거
- `_historyPeriod` 상태 + `selectHistoryPeriod()` 메서드 추가
- `historyRange` getter 추가 (테스트 가능하도록 public)
- `load()` 는 스냅샷(항상 오늘) + 히스토리(현재 `_historyPeriod`) 동시 로드
- `selectHistoryPeriod()` 는 피리어드 변경 후 `load()` 재호출

- [ ] **Step 1: 테스트 파일 생성 및 실패 확인**

```dart
// test/features/dashboard/asset_viewmodel_test.dart
import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardAssetViewModel', () {
    test('기본 historyPeriod는 oneYear', () {
      final vm = DashboardAssetViewModel();
      expect(vm.historyPeriod, AssetHistoryPeriod.oneYear);
    });

    test('historyRange oneYear: 1년 전 ~ 오늘', () {
      final vm = DashboardAssetViewModel();
      final now = DateTime.now();
      final range = vm.historyRange;
      final expectedStart =
          '${now.year - 1}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final expectedEnd =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      expect(range.strtDt, expectedStart);
      expect(range.endDt, expectedEnd);
    });

    test('historyRange threeMonths: 3개월 전 ~ 오늘', () {
      final vm = DashboardAssetViewModel();
      vm.selectHistoryPeriod(AssetHistoryPeriod.threeMonths);
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      final expectedStart =
          '${threeMonthsAgo.year}${threeMonthsAgo.month.toString().padLeft(2, '0')}${threeMonthsAgo.day.toString().padLeft(2, '0')}';
      expect(vm.historyRange.strtDt, expectedStart);
    });

    test('historyRange sixMonths: 6개월 전 ~ 오늘', () {
      final vm = DashboardAssetViewModel();
      vm.selectHistoryPeriod(AssetHistoryPeriod.sixMonths);
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
      final expectedStart =
          '${sixMonthsAgo.year}${sixMonthsAgo.month.toString().padLeft(2, '0')}${sixMonthsAgo.day.toString().padLeft(2, '0')}';
      expect(vm.historyRange.strtDt, expectedStart);
    });

    test('selectHistoryPeriod 호출 시 notifyListeners 발생', () {
      final vm = DashboardAssetViewModel();
      var notified = false;
      vm.addListener(() => notified = true);
      vm.selectHistoryPeriod(AssetHistoryPeriod.threeMonths);
      expect(notified, true);
    });

    test('selectHistoryPeriod 호출 후 historyPeriod 갱신', () {
      final vm = DashboardAssetViewModel();
      vm.selectHistoryPeriod(AssetHistoryPeriod.sixMonths);
      expect(vm.historyPeriod, AssetHistoryPeriod.sixMonths);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
cd /Users/kangwonseo/Desktop/workspace/flutter_account_book_vibe
flutter test test/features/dashboard/asset_viewmodel_test.dart
```

Expected: compile error (AssetHistoryPeriod not defined)

- [ ] **Step 3: `asset_viewmodel.dart` 전체 교체**

```dart
// lib/features/dashboard/viewmodels/asset_viewmodel.dart
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:flutter/foundation.dart';

enum AssetHistoryPeriod { threeMonths, sixMonths, oneYear }

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
  DashboardAssetViewModel();

  AssetHistoryPeriod _historyPeriod = AssetHistoryPeriod.oneYear;
  bool isLoading = false;
  String? errorMessage;
  DashboardAssetData? data;

  AssetHistoryPeriod get historyPeriod => _historyPeriod;

  ({String strtDt, String endDt}) get historyRange {
    final now = DateTime.now();
    final endDt = _fmt(now);
    return switch (_historyPeriod) {
      AssetHistoryPeriod.threeMonths => (
          strtDt: _fmt(DateTime(now.year, now.month - 3, now.day)),
          endDt: endDt,
        ),
      AssetHistoryPeriod.sixMonths => (
          strtDt: _fmt(DateTime(now.year, now.month - 6, now.day)),
          endDt: endDt,
        ),
      AssetHistoryPeriod.oneYear => (
          strtDt: _fmt(DateTime(now.year - 1, now.month, now.day)),
          endDt: endDt,
        ),
    };
  }

  void selectHistoryPeriod(AssetHistoryPeriod period) {
    _historyPeriod = period;
    notifyListeners();
    load();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayDt = _fmt(now);
      final prevYearDt = _fmt(DateTime(now.year - 1, now.month, now.day));
      final range = historyRange;

      final results = await Future.wait([
        MyAssetService.instance.getMyAssets(strtDt: todayDt, endDt: todayDt),
        MyAssetService.instance
            .getMyAssets(strtDt: prevYearDt, endDt: prevYearDt),
        MyAssetService.instance
            .getMyAssetSum(strtDt: range.strtDt, endDt: range.endDt),
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

  static List<AssetCompositionItem> _buildComposition(
    MyAssetListResponse resp,
  ) {
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
    final byDateAsset = <String, int>{};
    final byDateDebt = <String, int>{};
    for (final s in sums) {
      if (s.assetId == '0') continue;
      if (s.assetId == '6') {
        byDateDebt[s.accumDt] = (byDateDebt[s.accumDt] ?? 0) + s.sumPrice;
      } else {
        byDateAsset[s.accumDt] =
            (byDateAsset[s.accumDt] ?? 0) + s.sumPrice;
      }
    }
    final allDates = {
      ...byDateAsset.keys,
      ...byDateDebt.keys,
    }.toList()
      ..sort();
    return allDates.map((date) {
      final asset = byDateAsset[date] ?? 0;
      final debt = byDateDebt[date] ?? 0;
      return (date: date, amount: asset - debt);
    }).toList();
  }

  String _fmt(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/features/dashboard/asset_viewmodel_test.dart
```

Expected: All 6 tests pass.

- [ ] **Step 5: analyze 확인**

```bash
flutter analyze lib/features/dashboard/viewmodels/asset_viewmodel.dart
```

Expected: No errors.

- [ ] **Step 6: 커밋**

```bash
git add lib/features/dashboard/viewmodels/asset_viewmodel.dart test/features/dashboard/asset_viewmodel_test.dart
git commit -m "refactor(dashboard): decouple AssetViewModel from global period, add AssetHistoryPeriod"
```

---

## Task 2: DashboardScreen — 탭별 기간선택기 표시 제어

**Files:**
- Modify: `lib/features/dashboard/dashboard_screen.dart`

### 변경 내용 요약

- `_tabController.addListener(_onTabChanged)` 추가 → `setState` 로 appBar 재빌드
- 자산 탭(index 2)일 때 `preferredSize` 를 44px로 축소하고 `PeriodSelector` 숨김
- `_assetVm = DashboardAssetViewModel()` — 더 이상 `_period` 불필요

- [ ] **Step 1: `dashboard_screen.dart` 전체 교체**

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
    _assetVm = DashboardAssetViewModel()..load();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _period.dispose();
    _overviewVm.dispose();
    _expenseVm.dispose();
    _assetVm.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _isAssetTab => _tabController.index == 2;

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
          preferredSize: Size.fromHeight(_isAssetTab ? 44 : 88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isAssetTab)
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

- [ ] **Step 2: analyze 확인**

```bash
flutter analyze lib/features/dashboard/dashboard_screen.dart
```

Expected: No errors.

- [ ] **Step 3: 커밋**

```bash
git add lib/features/dashboard/dashboard_screen.dart
git commit -m "feat(dashboard): hide period selector on asset tab, dynamic appbar height"
```

---

## Task 3: AssetTab — 인라인 히스토리 기간 피커

**Files:**
- Modify: `lib/features/dashboard/tabs/asset_tab.dart`

### 변경 내용 요약

- `_SectionCard`에 `trailing` 파라미터 추가
- `_AssetContent`가 `DashboardAssetData` 대신 `DashboardAssetViewModel` 을 받도록 변경 → 피커에서 `vm.selectHistoryPeriod()` 호출 가능
- `_HistoryPeriodPicker` 위젯 추가: `AssetHistoryPeriod.values` 3개를 chip 형태로 표시
- 순자산 추이 섹션 헤더에 `_HistoryPeriodPicker` 를 `trailing`으로 삽입

- [ ] **Step 1: `asset_tab.dart` 전체 교체**

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
          return const Center(
            child: CircularProgressIndicator(color: AppColors.colorAccentIndigo),
          );
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return _AssetContent(vm: vm, data: data);
      },
    );
  }
}

class _AssetContent extends StatelessWidget {
  const _AssetContent({required this.vm, required this.data});

  final DashboardAssetViewModel vm;
  final DashboardAssetData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ① 순자산 헤더 (항상 오늘 스냅샷)
        _AssetHeroCard(data: data),
        const SizedBox(height: 12),

        // ② 자산 구성 도넛 (항상 오늘 스냅샷)
        _SectionCard(
          title: '자산 구성',
          child: _AssetDonutSection(data: data),
        ),
        const SizedBox(height: 12),

        // ③ 순자산 추이 (히스토리 기간 선택 가능)
        _SectionCard(
          title: '순자산 추이',
          trailing: _HistoryPeriodPicker(vm: vm),
          child: NetWorthLineChart(
            history: data.netWorthHistory,
            height: 140,
          ),
        ),
        const SizedBox(height: 12),

        // ④ 자산 항목별 리스트 (항상 오늘 스냅샷)
        _SectionCard(
          title: '자산 항목',
          child: Column(
            children: data.assetGroups
                .map((g) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.assetNm,
                              style: AppTextStyles.textBodySm.copyWith(
                                color: AppColors.colorTextPrimary,
                              ),
                            ),
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
                    ))
                .toList(),
          ),
        ),

        // ⑤ 부채 현황 (부채 > 0 일 때만, 항상 오늘 스냅샷)
        if (data.debt > 0) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: '부채 현황',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 부채',
                  style: AppTextStyles.textBodySm.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
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

class _HistoryPeriodPicker extends StatelessWidget {
  const _HistoryPeriodPicker({required this.vm});

  final DashboardAssetViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: AssetHistoryPeriod.values.map((p) {
          final isSelected = vm.historyPeriod == p;
          return GestureDetector(
            onTap: () => vm.selectHistoryPeriod(p),
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.colorAccentTeal
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.colorAccentTeal
                      : AppColors.colorDivider,
                ),
              ),
              child: Text(
                _label(p),
                style: AppTextStyles.textBodyXs.copyWith(
                  color: isSelected
                      ? AppColors.colorBgMain
                      : AppColors.colorTextSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(AssetHistoryPeriod p) => switch (p) {
        AssetHistoryPeriod.threeMonths => '3개월',
        AssetHistoryPeriod.sixMonths => '6개월',
        AssetHistoryPeriod.oneYear => '1년',
      };
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
            '순자산 (Net Worth)',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
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
              Expanded(
                child: _StatChip(
                  label: '총자산',
                  value: '₩${FormatUtil.formatPrice(data.totalAsset)}',
                  color: AppColors.colorProfit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: '전년 대비',
                  value: growth >= 0
                      ? '+₩${FormatUtil.formatPrice(growth)}'
                      : '-₩${FormatUtil.formatPrice(growth.abs())}',
                  color: growth >= 0
                      ? AppColors.colorProfit
                      : AppColors.colorExpense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
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
          Text(
            label,
            style: AppTextStyles.textBodyXs.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.textBodySm.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
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
      return const SizedBox(
        height: 60,
        child: Center(child: Text('데이터 없음')),
      );
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
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });
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
              Text(
                title,
                style: AppTextStyles.textBodySm.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
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
```

- [ ] **Step 2: analyze 확인**

```bash
flutter analyze lib/features/dashboard/tabs/asset_tab.dart
```

Expected: No errors.

- [ ] **Step 3: 전체 대시보드 analyze**

```bash
flutter analyze lib/features/dashboard/
```

Expected: No errors.

- [ ] **Step 4: 전체 테스트 실행**

```bash
flutter test test/features/dashboard/
```

Expected: All tests pass.

- [ ] **Step 5: 커밋**

```bash
git add lib/features/dashboard/tabs/asset_tab.dart
git commit -m "feat(dashboard): add inline history period picker to asset tab"
```
