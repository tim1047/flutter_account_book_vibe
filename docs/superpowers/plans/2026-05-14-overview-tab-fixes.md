# Overview Tab 3개 수정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 개요 탭의 순자산 차트 축 표시, 지출 TOP5 카테고리명 추가, 커스텀 기간 피커 UI 연결을 완성한다.

**Architecture:** (1) `DashboardPeriodViewModel`에 `customLabel` getter 추가 → (2) `MiniBarRow` label 영역 확장 → (3) overview_tab 카테고리명 1줄 수정 → (4) `NetWorthLineChart` Y/X 축 레이블 활성화 → (5) `PeriodSelector`에 `showDateRangePicker` 연결. 각 태스크는 독립적으로 컴파일·실행 가능하다.

**Tech Stack:** Flutter 3, fl_chart 0.66.2, ChangeNotifier/ListenableBuilder

---

### Task 1: DashboardPeriodViewModel.customLabel getter 추가

**Files:**
- Modify: `lib/features/dashboard/dashboard_period_viewmodel.dart`
- Test: `test/features/dashboard/dashboard_period_viewmodel_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/dashboard/dashboard_period_viewmodel_test.dart` 파일의 기존 `group('DashboardPeriodViewModel', () {` 블록 안 마지막 테스트 뒤에 아래 두 테스트를 추가한다.

```dart
    test('커스텀 날짜 미선택 시 customLabel은 커스텀', () {
      final vm = DashboardPeriodViewModel();
      expect(vm.customLabel, '커스텀');
    });

    test('setCustomRange 후 customLabel은 M/D~M/D 형식', () {
      final vm = DashboardPeriodViewModel();
      vm.setCustomRange(DateTime(2025, 3, 1), DateTime(2025, 5, 31));
      expect(vm.customLabel, '3/1~5/31');
    });
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
cd /Users/kangwonseo/Desktop/workspace/flutter_account_book_vibe
flutter test test/features/dashboard/dashboard_period_viewmodel_test.dart
```

Expected: FAIL — `The getter 'customLabel' isn't defined`

- [ ] **Step 3: customLabel getter 구현**

`lib/features/dashboard/dashboard_period_viewmodel.dart` 의 `label` getter 바로 아래에 추가:

```dart
  String get customLabel {
    if (_customStart == null || _customEnd == null) return '커스텀';
    return '${_customStart!.month}/${_customStart!.day}~${_customEnd!.month}/${_customEnd!.day}';
  }
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/features/dashboard/dashboard_period_viewmodel_test.dart
```

Expected: 모든 테스트 PASS

- [ ] **Step 5: 커밋**

```bash
git add lib/features/dashboard/dashboard_period_viewmodel.dart \
        test/features/dashboard/dashboard_period_viewmodel_test.dart
git commit -m "feat(dashboard): add customLabel getter to DashboardPeriodViewModel"
```

---

### Task 2: MiniBarRow label 영역 확장

**Files:**
- Modify: `lib/features/dashboard/widgets/mini_bar_row.dart`

현재 `SizedBox(width: 24)` 으로 이모지 1개만 들어갈 공간. `'🍔 식비'` 같은 텍스트가 들어오면 넘친다. 90으로 늘리고 overflow 처리.

- [ ] **Step 1: label SizedBox width 변경**

`lib/features/dashboard/widgets/mini_bar_row.dart` 의 25-28번째 줄:

기존:
```dart
          SizedBox(
            width: 24,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
```

변경 후:
```dart
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
```

- [ ] **Step 2: 빌드 확인**

```bash
flutter analyze lib/features/dashboard/widgets/mini_bar_row.dart
```

Expected: 오류 없음

- [ ] **Step 3: 커밋**

```bash
git add lib/features/dashboard/widgets/mini_bar_row.dart
git commit -m "fix(dashboard): widen MiniBarRow label area for emoji + text"
```

---

### Task 3: 지출 TOP5 카테고리명 표시

**Files:**
- Modify: `lib/features/dashboard/tabs/overview_tab.dart`

- [ ] **Step 1: label 파라미터 변경**

`lib/features/dashboard/tabs/overview_tab.dart` 100-106번째 줄:

기존:
```dart
            children: data.topExpenseCategories.map((e) {
              final emoji = CategoryEmojis.forCategory(e.categoryNm);
              return MiniBarRow(
                label: emoji,
```

변경 후:
```dart
            children: data.topExpenseCategories.map((e) {
              final emoji = CategoryEmojis.forCategory(e.categoryNm);
              return MiniBarRow(
                label: '$emoji ${e.categoryNm}',
```

- [ ] **Step 2: 빌드 확인**

```bash
flutter analyze lib/features/dashboard/tabs/overview_tab.dart
```

Expected: 오류 없음

- [ ] **Step 3: 커밋**

```bash
git add lib/features/dashboard/tabs/overview_tab.dart
git commit -m "fix(dashboard): show emoji + category name in TOP5 expense list"
```

---

### Task 4: 순자산 추이 차트 Y/X 축 레이블 추가

**Files:**
- Modify: `lib/features/dashboard/widgets/net_worth_line_chart.dart`

- [ ] **Step 1: format_util import 추가 및 축 레이블 활성화**

`lib/features/dashboard/widgets/net_worth_line_chart.dart` 전체를 아래로 교체:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({
    super.key,
    required this.history,
    this.height = 170,
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
    final yRange = (maxY - minY).abs();
    final yInterval = yRange < 10 ? 1.0 : yRange / 2;

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
                    AppColors.colorAccentTeal.withValues(alpha: 0.2),
                    AppColors.colorAccentTeal.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.colorDivider,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                interval: yInterval,
                getTitlesWidget: (value, _) {
                  final inMan = (value / 10000).round();
                  return Text(
                    '₩${FormatUtil.formatPrice(inMan)}만',
                    style: AppTextStyles.textBodyXs.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= history.length) {
                    return const SizedBox.shrink();
                  }
                  final currentMonth = history[idx].date.substring(4, 6);
                  if (idx > 0 &&
                      currentMonth == history[idx - 1].date.substring(4, 6)) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${int.parse(currentMonth)}월',
                    style: AppTextStyles.textBodyXs.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
flutter analyze lib/features/dashboard/widgets/net_worth_line_chart.dart
```

Expected: 오류 없음

- [ ] **Step 3: 커밋**

```bash
git add lib/features/dashboard/widgets/net_worth_line_chart.dart
git commit -m "feat(dashboard): add Y/X axis labels to NetWorthLineChart"
```

---

### Task 5: PeriodSelector 커스텀 날짜 피커 연결

**Files:**
- Modify: `lib/features/dashboard/widgets/period_selector.dart`

커스텀 칩 탭 시 `showDateRangePicker` 호출. 선택 완료 후 `vm.setCustomRange`. 칩 라벨은 `vm.customLabel` 사용.

- [ ] **Step 1: period_selector.dart 수정**

`lib/features/dashboard/widgets/period_selector.dart` 전체를 아래로 교체:

```dart
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
                onTap: () => _onTap(context, p),
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

  Future<void> _onTap(BuildContext context, DashboardPeriod p) async {
    if (p != DashboardPeriod.custom) {
      vm.select(p);
      return;
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.colorAccentTeal,
            onPrimary: AppColors.colorBgMain,
            surface: AppColors.colorBgCard,
            onSurface: AppColors.colorTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      vm.setCustomRange(picked.start, picked.end);
    }
  }

  String _label(DashboardPeriod p) => switch (p) {
        DashboardPeriod.thisMonth => '이번 달',
        DashboardPeriod.thisQuarter => '이번 분기',
        DashboardPeriod.thisYear => '올해',
        DashboardPeriod.custom => vm.customLabel,
      };
}
```

- [ ] **Step 2: 빌드 및 분석 확인**

```bash
flutter analyze lib/features/dashboard/widgets/period_selector.dart
```

Expected: 오류 없음

- [ ] **Step 3: 전체 테스트 통과 확인**

```bash
flutter test
```

Expected: 모든 테스트 PASS

- [ ] **Step 4: 커밋**

```bash
git add lib/features/dashboard/widgets/period_selector.dart
git commit -m "feat(dashboard): wire custom date range picker in PeriodSelector"
```
