# 추이 차트 비주얼 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 지출/수입/투자 월별 추이 차트에 평균 기준선 + 이번달 강조를 적용하고, 지출 일별 추이
차트를 "이번달 강조 3개월 라인" + "이번달 누적 패널" 2개로 분리해 표현력을 높인다. API/라우팅/
ViewModel은 손대지 않는다.

**Architecture:** 3개 월별 화면(`expense`/`income`/`invest`)에 100% 복붙되어 있던
`_SummaryCard`/`_BarChartCard`를 `lib/shared/widgets/`의 공용 위젯(`TrendSummaryCard`,
`MonthlyTrendBarChart`)으로 추출한다. 일별 화면은 지출 전용이라 공용화 대상이 아니며, 파일
내부에서 순수 계산 함수(누적 계산)를 분리해 유닛 테스트로 검증한다.

**Tech Stack:** Flutter, fl_chart ^0.66.2 (`ExtraLinesData`/`HorizontalLine`,
`BarChartGroupData.showingTooltipIndicators` 확인 완료), flutter_test.

## Global Constraints

- `flutter_lints` 규칙 준수, `dart_format` 적용.
- 새 상태관리 라이브러리 금지 (`ChangeNotifier`/`ListenableBuilder`만 사용) — 이번 작업은
  상태관리 변경이 아예 없음.
- API 신규 호출 금지 — 이미 받아온 `SumGroupByMonthResponse`, `MonthDailyData` 데이터만 사용.
- `AppColors`에 신규 색상 상수 추가 금지 — 기존 `colorTextSecondary`, `colorChartCurrent` 등
  재사용.
- 파일 경로: 패키지명 `account_book_vibe` (import는 `package:account_book_vibe/...`).

---

## Task 1: `TrendSummaryCard` 공용 위젯 추출

**Files:**
- Create: `lib/shared/widgets/trend_summary_card.dart`
- Modify: `lib/features/expense/expense_monthly_chart_screen.dart:157-194` (private `_SummaryCard` 삭제 예정, Task 3에서 처리)

**Interfaces:**
- Produces: `class TrendSummaryCard extends StatelessWidget` — 생성자
  `TrendSummaryCard({required IconData icon, required String text, required Color color})`.
  기존 3개 화면의 `_SummaryCard`와 겉모습·구현 100% 동일 (단순 이동, 로직 변경 없음).

- [ ] **Step 1: 파일 생성**

```dart
// lib/shared/widgets/trend_summary_card.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 추이 화면 상단에 쓰이는 아이콘 + 한 줄 요약 카드.
class TrendSummaryCard extends StatelessWidget {
  const TrendSummaryCard({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.colorBgSub,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.colorTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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

- [ ] **Step 2: 정적 분석 확인**

Run: `dart analyze lib/shared/widgets/trend_summary_card.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/trend_summary_card.dart
git commit -m "refactor(shared): extract TrendSummaryCard widget"
```

---

## Task 2: `MonthlyTrendBarChart` 공용 위젯 (평균 기준선 + 이번달 강조)

**Files:**
- Create: `lib/shared/widgets/monthly_trend_bar_chart.dart`
- Test: `test/shared/widgets/monthly_trend_bar_chart_test.dart`

**Interfaces:**
- Consumes: 없음 (fl_chart, AppColors, FormatUtil만 사용)
- Produces: `class MonthlyTrendBarChart extends StatelessWidget`, 생성자
  `MonthlyTrendBarChart({required Map<int, int> monthMap, required List<int> orderedMonths, required int avgPrice, required int currentMonth})`.
  정적 순수 함수 `MonthlyTrendBarChart.computeMaxY(List<int> values, int avgPrice) -> double`
  (Task 3~5에서 다른 곳에서 재사용하지 않지만, 유닛 테스트 대상으로 static 유지).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// test/shared/widgets/monthly_trend_bar_chart_test.dart
import 'package:account_book_vibe/shared/widgets/monthly_trend_bar_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyTrendBarChart.computeMaxY', () {
    test('실제 최댓값의 1.25배 반환 (평균 포함해서 비교)', () {
      expect(MonthlyTrendBarChart.computeMaxY([100, 200], 50), 250.0);
    });

    test('평균이 막대 최댓값보다 크면 평균 기준으로 계산', () {
      expect(MonthlyTrendBarChart.computeMaxY([100, 200], 400), 500.0);
    });

    test('전부 0이면 기본값 1,000,000 반환', () {
      expect(MonthlyTrendBarChart.computeMaxY([0, 0], 0), 1000000.0);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/shared/widgets/monthly_trend_bar_chart_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'account_book_vibe' for 'monthly_trend_bar_chart.dart'` (파일이 아직 없음)

- [ ] **Step 3: 위젯 구현**

```dart
// lib/shared/widgets/monthly_trend_bar_chart.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 월별 합계를 막대로, 평균을 기준선으로 보여주는 차트.
/// 이번달 막대는 강조색 + 상시 노출 값 라벨로 표시된다.
class MonthlyTrendBarChart extends StatelessWidget {
  const MonthlyTrendBarChart({
    super.key,
    required this.monthMap,
    required this.orderedMonths,
    required this.avgPrice,
    required this.currentMonth,
  });

  final Map<int, int> monthMap;
  final List<int> orderedMonths;
  final int avgPrice;
  final int currentMonth;

  static double computeMaxY(List<int> values, int avgPrice) {
    final rawValues = [
      ...values.map((v) => v.toDouble()),
      avgPrice.toDouble(),
    ];
    final rawMax =
        rawValues.isEmpty ? 0.0 : rawValues.reduce((a, b) => a > b ? a : b);
    return rawMax == 0 ? 1000000.0 : rawMax * 1.25;
  }

  @override
  Widget build(BuildContext context) {
    final values = orderedMonths.map((m) => monthMap[m] ?? 0).toList();
    final maxY = computeMaxY(values, avgPrice);
    final minBarY = maxY * 0.02;

    final barGroups = <BarChartGroupData>[
      for (int i = 0; i < orderedMonths.length; i++)
        BarChartGroupData(
          x: i,
          showingTooltipIndicators:
              orderedMonths[i] == currentMonth ? const [0] : const [],
          barRods: [
            BarChartRodData(
              toY: values[i] == 0 ? minBarY : values[i].toDouble(),
              gradient: orderedMonths[i] == currentMonth
                  ? null
                  : AppColors.barChartGradient,
              color: orderedMonths[i] == currentMonth
                  ? AppColors.colorChartCurrent
                  : null,
              width: 14,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
    ];

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(4, 24, 16, 8),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: barGroups,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: avgPrice.toDouble(),
                color: AppColors.colorTextSecondary,
                strokeWidth: 1,
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(
                    color: AppColors.colorTextSecondary,
                    fontSize: 10,
                  ),
                  labelResolver: (_) =>
                      '평균 ${FormatUtil.formatPrice(avgPrice)}원',
                ),
              ),
            ],
          ),
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
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${(value / 10000).round()}만',
                      style: const TextStyle(
                        color: AppColors.colorTextSecondary,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= orderedMonths.length) {
                    return const SizedBox.shrink();
                  }
                  final isCurrent = orderedMonths[idx] == currentMonth;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${orderedMonths[idx]}',
                      style: TextStyle(
                        color: isCurrent
                            ? AppColors.colorChartCurrent
                            : AppColors.colorTextSecondary,
                        fontSize: 10,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.colorBgSub,
              getTooltipItem: (group, _, rod, __) {
                final idx = group.x;
                return BarTooltipItem(
                  '${orderedMonths[idx]}월\n${FormatUtil.formatPrice(values[idx])}원',
                  const TextStyle(
                    color: AppColors.colorTextPrimary,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 테스트 실행해서 통과 확인**

Run: `flutter test test/shared/widgets/monthly_trend_bar_chart_test.dart`
Expected: `All tests passed!` (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/monthly_trend_bar_chart.dart test/shared/widgets/monthly_trend_bar_chart_test.dart
git commit -m "feat(shared): add MonthlyTrendBarChart with average reference line"
```

---

## Task 3: `expense_monthly_chart_screen.dart`에 공용 위젯 적용

**Files:**
- Modify: `lib/features/expense/expense_monthly_chart_screen.dart` (전체 96~360행 교체 — `_MonthlyChartBody`부터 파일 끝까지)

**Interfaces:**
- Consumes: `TrendSummaryCard` (Task 1), `MonthlyTrendBarChart` (Task 2)

- [ ] **Step 1: import 교체**

`lib/features/expense/expense_monthly_chart_screen.dart` 1~12행을 다음으로 교체:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/expense/expense_chart_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/monthly_trend_bar_chart.dart';
import 'package:account_book_vibe/shared/widgets/trend_summary_card.dart';
import 'package:flutter/material.dart';
```

(`fl_chart` import 제거 — 이 파일은 이제 fl_chart를 직접 쓰지 않음)

- [ ] **Step 2: `_MonthlyChartBody`부터 파일 끝까지(기존 96~360행) 아래 코드로 전체 교체**

```dart
// ── Body ──────────────────────────────────────────────────────────────────────

class _MonthlyChartBody extends StatelessWidget {
  const _MonthlyChartBody({required this.data, required this.currentMonth});

  final SumGroupByMonthResponse data;
  final int currentMonth;

  Map<int, int> get _monthMap =>
      {for (final item in data.data) item.month: item.sumPrice};

  @override
  Widget build(BuildContext context) {
    final monthMap = _monthMap;
    final currentPrice = monthMap[currentMonth] ?? 0;
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevPrice = monthMap[prevMonth] ?? 0;
    final diff = currentPrice - prevPrice;

    final sortedItems = [...data.data]
      ..sort((a, b) {
        final keyA = (a.month - currentMonth - 1 + 12) % 12;
        final keyB = (b.month - currentMonth - 1 + 12) % 12;
        return keyA.compareTo(keyB);
      });
    final orderedMonths = sortedItems.map((e) => e.month).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TrendSummaryCard(
            icon: Icons.compare_arrows,
            text: diff == 0
                ? '저번달과 동일해요'
                : diff > 0
                    ? '저번달보다 ${FormatUtil.formatPrice(diff)}원 더 썼어요'
                    : '저번달보다 ${FormatUtil.formatPrice(-diff)}원 덜 썼어요',
            color: diff > 0 ? AppColors.colorExpense : AppColors.colorIncome,
          ),
          const SizedBox(height: 12),
          TrendSummaryCard(
            icon: Icons.bar_chart,
            text: '한달에 평균 ${FormatUtil.formatPrice(data.avgSumPrice)}원 지출중이에요',
            color: AppColors.colorInvest,
          ),
          const SizedBox(height: 24),
          MonthlyTrendBarChart(
            monthMap: monthMap,
            orderedMonths: orderedMonths,
            avgPrice: data.avgSumPrice,
            currentMonth: currentMonth,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 정적 분석**

Run: `dart analyze lib/features/expense/expense_monthly_chart_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/expense/expense_monthly_chart_screen.dart
git commit -m "refactor(expense): use shared trend chart widgets"
```

---

## Task 4: `income_monthly_chart_screen.dart`에 공용 위젯 적용

**Files:**
- Modify: `lib/features/income/income_monthly_chart_screen.dart` (전체 95~341행 교체)

- [ ] **Step 1: import 교체**

1~12행을 다음으로 교체 (income은 원래 `expense_chart_viewmodel`이 아니라 `income_chart_viewmodel` import — 나머지는 동일 패턴):

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/income/income_chart_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/monthly_trend_bar_chart.dart';
import 'package:account_book_vibe/shared/widgets/trend_summary_card.dart';
import 'package:flutter/material.dart';
```

- [ ] **Step 2: `_MonthlyChartBody`부터 파일 끝까지(기존 95~341행) 아래 코드로 전체 교체**

income은 원래 `_SummaryCard`가 1개(평균)뿐이고 전월 대비 diff 카드가 없었다 — 그 구조를 그대로
유지한다.

```dart
// ── Body ──────────────────────────────────────────────────────────────────────

class _MonthlyChartBody extends StatelessWidget {
  const _MonthlyChartBody({required this.data, required this.currentMonth});

  final SumGroupByMonthResponse data;
  final int currentMonth;

  @override
  Widget build(BuildContext context) {
    final monthMap = {for (final item in data.data) item.month: item.sumPrice};
    final sortedItems = [...data.data]
      ..sort((a, b) {
        final keyA = (a.month - currentMonth - 1 + 12) % 12;
        final keyB = (b.month - currentMonth - 1 + 12) % 12;
        return keyA.compareTo(keyB);
      });
    final orderedMonths = sortedItems.map((e) => e.month).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TrendSummaryCard(
            icon: Icons.bar_chart,
            text: '한달에 평균 ${FormatUtil.formatPrice(data.avgSumPrice)}원 수입이 있어요',
            color: AppColors.colorIncome,
          ),
          const SizedBox(height: 24),
          MonthlyTrendBarChart(
            monthMap: monthMap,
            orderedMonths: orderedMonths,
            avgPrice: data.avgSumPrice,
            currentMonth: currentMonth,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 정적 분석**

Run: `dart analyze lib/features/income/income_monthly_chart_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/income/income_monthly_chart_screen.dart
git commit -m "refactor(income): use shared trend chart widgets"
```

---

## Task 5: `invest_monthly_chart_screen.dart`에 공용 위젯 적용

**Files:**
- Modify: `lib/features/invest/invest_monthly_chart_screen.dart` (전체 95~359행 교체)

- [ ] **Step 1: import 교체**

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/invest/invest_chart_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/monthly_trend_bar_chart.dart';
import 'package:account_book_vibe/shared/widgets/trend_summary_card.dart';
import 'package:flutter/material.dart';
```

- [ ] **Step 2: `_MonthlyChartBody`부터 파일 끝까지(기존 95~359행) 아래 코드로 전체 교체**

invest는 expense와 같은 구조(diff 카드 + 평균 카드) — 문구/색상만 투자용.

```dart
// ── Body ──────────────────────────────────────────────────────────────────────

class _MonthlyChartBody extends StatelessWidget {
  const _MonthlyChartBody({required this.data, required this.currentMonth});

  final SumGroupByMonthResponse data;
  final int currentMonth;

  Map<int, int> get _monthMap =>
      {for (final item in data.data) item.month: item.sumPrice};

  @override
  Widget build(BuildContext context) {
    final monthMap = _monthMap;
    final currentPrice = monthMap[currentMonth] ?? 0;
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevPrice = monthMap[prevMonth] ?? 0;
    final diff = currentPrice - prevPrice;

    final sortedItems = [...data.data]
      ..sort((a, b) {
        final keyA = (a.month - currentMonth - 1 + 12) % 12;
        final keyB = (b.month - currentMonth - 1 + 12) % 12;
        return keyA.compareTo(keyB);
      });
    final orderedMonths = sortedItems.map((e) => e.month).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TrendSummaryCard(
            icon: Icons.compare_arrows,
            text: diff == 0
                ? '저번달과 동일해요'
                : diff > 0
                    ? '저번달보다 ${FormatUtil.formatPrice(diff)}원 더 투자했어요'
                    : '저번달보다 ${FormatUtil.formatPrice(-diff)}원 덜 투자했어요',
            color: diff > 0 ? AppColors.colorInvest : AppColors.colorIncome,
          ),
          const SizedBox(height: 12),
          TrendSummaryCard(
            icon: Icons.bar_chart,
            text: '한달에 평균 ${FormatUtil.formatPrice(data.avgSumPrice)}원 투자중이에요',
            color: AppColors.colorRate,
          ),
          const SizedBox(height: 24),
          MonthlyTrendBarChart(
            monthMap: monthMap,
            orderedMonths: orderedMonths,
            avgPrice: data.avgSumPrice,
            currentMonth: currentMonth,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 정적 분석**

Run: `dart analyze lib/features/invest/invest_monthly_chart_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/invest/invest_monthly_chart_screen.dart
git commit -m "refactor(invest): use shared trend chart widgets"
```

---

## Task 6: 지출 일별 차트 — 누적 계산 순수 함수 + 테스트

**Files:**
- Modify: `lib/features/expense/expense_daily_chart_screen.dart` (파일 끝에 public 클래스 추가 — 코드는 다음 Task에서 최종 위치로 정리)
- Test: `test/features/expense/daily_cumulative_calc_test.dart`

**Interfaces:**
- Produces: `class DailyCumulativeCalc` with static methods:
  - `int cumulativeUpTo(List<DailyChartEntry> entries, int day)`
  - `List<FlSpot> buildCumulativeSpots(List<DailyChartEntry> entries)`
  - `int referenceDay(int year, int month, {DateTime? now})`
  이 3개 함수는 Task 8에서 위젯이 그대로 사용한다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// test/features/expense/daily_cumulative_calc_test.dart
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/expense/expense_daily_chart_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const entries = [
    DailyChartEntry(day: 1, price: 1000),
    DailyChartEntry(day: 3, price: 2000),
    DailyChartEntry(day: 10, price: 500),
  ];

  group('DailyCumulativeCalc.cumulativeUpTo', () {
    test('특정 일자까지만 누적', () {
      expect(DailyCumulativeCalc.cumulativeUpTo(entries, 3), 3000);
    });

    test('데이터에 없는 날짜여도 그 이전까지 누적', () {
      expect(DailyCumulativeCalc.cumulativeUpTo(entries, 5), 3000);
    });

    test('전체 일수 이상을 넣으면 전체 합계와 같음', () {
      expect(DailyCumulativeCalc.cumulativeUpTo(entries, 31), 3500);
    });
  });

  group('DailyCumulativeCalc.buildCumulativeSpots', () {
    test('날짜순 누적 스팟 생성', () {
      final spots = DailyCumulativeCalc.buildCumulativeSpots(entries);
      expect(spots.map((s) => s.x), [1.0, 3.0, 10.0]);
      expect(spots.map((s) => s.y), [1000.0, 3000.0, 3500.0]);
    });
  });

  group('DailyCumulativeCalc.referenceDay', () {
    test('실제 이번달이면 오늘 날짜 반환', () {
      final now = DateTime(2026, 7, 21);
      expect(DailyCumulativeCalc.referenceDay(2026, 7, now: now), 21);
    });

    test('과거 월이면 그 달의 마지막 날 반환', () {
      final now = DateTime(2026, 7, 21);
      expect(DailyCumulativeCalc.referenceDay(2026, 5, now: now), 31);
    });

    test('12월처럼 달 경계를 넘어가도 마지막 날 정확히 계산 (연도 롤오버)', () {
      final now = DateTime(2026, 7, 21);
      expect(DailyCumulativeCalc.referenceDay(2026, 12, now: now), 31);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/features/expense/daily_cumulative_calc_test.dart`
Expected: FAIL — `DailyCumulativeCalc` 정의를 찾을 수 없음

- [ ] **Step 3: `expense_daily_chart_screen.dart` 파일 맨 끝에 추가**

기존 파일 끝(현재 305번째 줄, `_MultiMonthLineChart` 클래스 닫는 `}` 다음)에 아래 클래스를
추가한다. `fl_chart`의 `FlSpot`은 이미 이 파일에서 import 중이므로 추가 import 불필요.

```dart
// ── 누적 계산 (순수 함수, 테스트 대상) ──────────────────────────────────────────

/// 일별 데이터에서 누적 합계를 계산하는 순수 함수 모음.
class DailyCumulativeCalc {
  DailyCumulativeCalc._();

  static int cumulativeUpTo(List<DailyChartEntry> entries, int day) =>
      entries
          .where((e) => e.day <= day)
          .fold(0, (sum, e) => sum + e.price);

  static List<FlSpot> buildCumulativeSpots(List<DailyChartEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.day.compareTo(b.day));
    int running = 0;
    final spots = <FlSpot>[];
    for (final e in sorted) {
      running += e.price;
      spots.add(FlSpot(e.day.toDouble(), running.toDouble()));
    }
    return spots;
  }

  /// [year]/[month]가 실제 달력상 이번달이면 오늘까지, 아니면 그 달의 마지막 날까지를
  /// "누적 기준일"로 본다. 이번달인 경우 `today.day`는 정의상 그 달의 마지막 날을
  /// 넘을 수 없으므로 별도 clamp가 필요 없다.
  static int referenceDay(int year, int month, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final isCurrentCalendarMonth = year == today.year && month == today.month;
    if (isCurrentCalendarMonth) return today.day;
    return DateTime(year, month + 1, 0).day;
  }
}
```

- [ ] **Step 4: 테스트 실행해서 통과 확인**

Run: `flutter test test/features/expense/daily_cumulative_calc_test.dart`
Expected: `All tests passed!` (7 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/expense/expense_daily_chart_screen.dart test/features/expense/daily_cumulative_calc_test.dart
git commit -m "feat(expense): add DailyCumulativeCalc pure functions"
```

---

## Task 7: 지출 일별 차트 — 패널 A(강조/눌림) + 패널 B(누적) 재구성

**Files:**
- Modify: `lib/features/expense/expense_daily_chart_screen.dart:92-305` (`_DailyChartBody`부터
  `_MultiMonthLineChart`까지 전체 교체, `DailyCumulativeCalc`는 Task 6에서 추가한 것 그대로 유지)

**Interfaces:**
- Consumes: `DailyCumulativeCalc` (Task 6의 4개 static 메서드)
- Produces: 없음 (최종 화면 위젯)

`monthlyData`는 `ExpenseChartViewModel.loadDailyData`가 이미 오래된 달 → 최신 달 순으로 채우므로
`monthlyData.last`가 항상 "이번달(선택된 마지막 달)"이다.

- [ ] **Step 1: `_DailyChartBody`부터 `_MultiMonthLineChart` 끝까지(92~305행)를 아래 코드로 교체**

```dart
// ── Body ──────────────────────────────────────────────────────────────────────

class _DailyChartBody extends StatelessWidget {
  const _DailyChartBody({required this.monthlyData});

  final List<MonthDailyData> monthlyData;

  @override
  Widget build(BuildContext context) {
    final current = monthlyData.last;
    final previous =
        monthlyData.length >= 2 ? monthlyData[monthlyData.length - 2] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Legend(),
          const SizedBox(height: 12),
          _MultiMonthLineChart(monthlyData: monthlyData),
          const SizedBox(height: 16),
          _CumulativeMonthCard(current: current, previous: previous),
        ],
      ),
    );
  }
}

// ── 범례 (이번달 강조 / 지난달들 눌림, 2항목 고정) ─────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: AppColors.colorChartCurrent, label: '이번달'),
        SizedBox(width: 20),
        _LegendItem(color: AppColors.colorTextSecondary, label: '지난달들'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.colorTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── 패널 A: 3개월 겹침 라인 (이번달 강조, 지난달들 눌림) ────────────────────────

class _MultiMonthLineChart extends StatelessWidget {
  const _MultiMonthLineChart({required this.monthlyData});

  final List<MonthDailyData> monthlyData;

  static const double _yInterval = 500000;

  double _maxY() {
    double max = 0;
    for (final m in monthlyData) {
      for (final e in m.entries) {
        if (e.price > max) max = e.price.toDouble();
      }
    }
    if (max == 0) return _yInterval;
    final steps = (max / _yInterval).ceil();
    return (steps + 1) * _yInterval;
  }

  @override
  Widget build(BuildContext context) {
    final maxY = _maxY();
    final currentIndex = monthlyData.length - 1;

    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(4, 24, 16, 8),
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: 31,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            for (int i = 0; i < monthlyData.length; i++)
              _buildLine(i, i == currentIndex),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _yInterval,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.colorDivider,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: _yInterval,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${(value / 10000).round()}만',
                      style: const TextStyle(
                        color: AppColors.colorTextSecondary,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  if (day == 1 || day % 5 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$day',
                        style: const TextStyle(
                          color: AppColors.colorTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.colorBgCard,
              getTooltipItems: (spots) => spots.map((spot) {
                final idx = spot.barIndex;
                final month = monthlyData[idx].month;
                return LineTooltipItem(
                  '$month월 ${spot.x.toInt()}일\n'
                  '${FormatUtil.formatPrice(spot.y.round())}원',
                  TextStyle(
                    color: idx == currentIndex
                        ? AppColors.colorChartCurrent
                        : AppColors.colorTextSecondary,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildLine(int index, bool isCurrent) {
    final entries = monthlyData[index].entries;
    final spots =
        entries.map((e) => FlSpot(e.day.toDouble(), e.price.toDouble())).toList();
    final lastSpot = spots.isEmpty ? null : spots.last;

    return LineChartBarData(
      spots: spots,
      color: isCurrent ? AppColors.colorChartCurrent : AppColors.colorTextSecondary,
      isCurved: true,
      curveSmoothness: 0.25,
      barWidth: isCurrent ? 2 : 1,
      dotData: FlDotData(
        show: isCurrent,
        checkToShowDot: (spot, _) => lastSpot != null && spot == lastSpot,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4,
          color: AppColors.colorChartCurrent,
          strokeWidth: 2,
          strokeColor: AppColors.colorBgCard,
        ),
      ),
      belowBarData: BarAreaData(
        show: isCurrent,
        color: Color.fromRGBO(
          AppColors.colorChartCurrent.red,
          AppColors.colorChartCurrent.green,
          AppColors.colorChartCurrent.blue,
          0.1,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 정적 분석**

Run: `dart analyze lib/features/expense/expense_daily_chart_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/expense/expense_daily_chart_screen.dart
git commit -m "refactor(expense): emphasize current month in daily overlay chart"
```

---

## Task 8: 지출 일별 차트 — 패널 B(`_CumulativeMonthCard`) 추가

**Files:**
- Modify: `lib/features/expense/expense_daily_chart_screen.dart` (Task 7에서 참조만 해둔
  `_CumulativeMonthCard`를 파일 끝, `DailyCumulativeCalc` 클래스 앞에 추가)

**Interfaces:**
- Consumes: `DailyCumulativeCalc.cumulativeTotal/cumulativeUpTo/buildCumulativeSpots/referenceDay`
  (Task 6), `MonthDailyData` (`lib/data/models/division_model.dart`)

- [ ] **Step 1: `DailyCumulativeCalc` 클래스 바로 앞에 아래 위젯 추가**

```dart
// ── 패널 B: 이번달 누적 ─────────────────────────────────────────────────────────

class _CumulativeMonthCard extends StatelessWidget {
  const _CumulativeMonthCard({required this.current, required this.previous});

  final MonthDailyData current;
  final MonthDailyData? previous;

  @override
  Widget build(BuildContext context) {
    final asOfDay = DailyCumulativeCalc.referenceDay(current.year, current.month);
    final currentCumulative =
        DailyCumulativeCalc.cumulativeUpTo(current.entries, asOfDay);

    int? referenceCumulative;
    final prevMonth = previous;
    if (prevMonth != null) {
      final prevLastDay = _lastDay(prevMonth);
      final clampedDay = asOfDay > prevLastDay ? prevLastDay : asOfDay;
      referenceCumulative =
          DailyCumulativeCalc.cumulativeUpTo(prevMonth.entries, clampedDay);
    }
    final diff =
        referenceCumulative == null ? null : currentCumulative - referenceCumulative;

    final spots = DailyCumulativeCalc.buildCumulativeSpots(current.entries);
    final maxY = currentCumulative == 0 ? 100000.0 : currentCumulative * 1.2;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diff == null
                ? '이번달 누적 ${FormatUtil.formatPrice(currentCumulative)}원'
                : '이번달 누적 ${FormatUtil.formatPrice(currentCumulative)}원 '
                    '(지난달 동기간 대비 ${diff >= 0 ? '+' : ''}${FormatUtil.formatPrice(diff)}원)',
            style: const TextStyle(
              color: AppColors.colorTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: 31,
                minY: 0,
                maxY: maxY,
                extraLinesData: referenceCumulative == null
                    ? const ExtraLinesData()
                    : ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: referenceCumulative.toDouble(),
                            color: AppColors.colorTextSecondary,
                            strokeWidth: 1,
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: const TextStyle(
                                color: AppColors.colorTextSecondary,
                                fontSize: 10,
                              ),
                              labelResolver: (_) =>
                                  '지난달 동기간 ${FormatUtil.formatPrice(referenceCumulative)}원',
                            ),
                          ),
                        ],
                      ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: AppColors.colorChartCurrent,
                    isCurved: false,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Color.fromRGBO(
                        AppColors.colorChartCurrent.red,
                        AppColors.colorChartCurrent.green,
                        AppColors.colorChartCurrent.blue,
                        0.1,
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
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt();
                        if (day == 1 || day % 5 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$day',
                              style: const TextStyle(
                                color: AppColors.colorTextSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.colorBgSub,
                    getTooltipItems: (spots) => spots.map((spot) {
                      return LineTooltipItem(
                        '${spot.x.toInt()}일까지 누적\n'
                        '${FormatUtil.formatPrice(spot.y.round())}원',
                        const TextStyle(
                          color: AppColors.colorChartCurrent,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _lastDay(MonthDailyData month) =>
      DateTime(month.year, month.month + 1, 0).day;
}
```

- [ ] **Step 2: 정적 분석**

Run: `dart analyze lib/features/expense/expense_daily_chart_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/expense/expense_daily_chart_screen.dart
git commit -m "feat(expense): add cumulative-month panel to daily chart"
```

---

## Task 9: 죽은 색상 상수 제거 + 전체 검증

**Files:**
- Modify: `lib/core/constants/app_colors.dart:89-96`

**Interfaces:** 없음 (정리 작업)

- [ ] **Step 1: 잔여 참조 없는지 확인**

Run: `grep -rn "colorChartAverage\|chartLineColors" lib/`
Expected: 출력 없음 (Task 3~8에서 모든 사용처 제거 완료)

- [ ] **Step 2: `app_colors.dart`에서 89~96행 삭제**

```dart
  static const List<Color> chartLineColors = <Color>[
    Color(0xFF2DD4BF),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
  ];

  static const Color colorChartAverage = Color(0xFF30363D);
```

삭제 후 `colorChartCurrent` 선언만 "8. 차트 색상" 섹션에 남는다:

```dart
  // 8. 차트 색상
  static const List<Color> memberColors = <Color>[
    colorUser1,
    colorUser2,
    colorUser3,
    Color(0xFF818CF8),
  ];

  static const List<Color> assetChartColors = <Color>[
    Color(0xFF818CF8),
    Color(0xFFF472B6),
    Color(0xFF2DD4BF),
    Color(0xFF4ADE80),
    Color(0xFFF87171),
    Color(0xFFE6EDF3),
    Color(0xFFFB923C),
    Color(0xFFFACC15),
  ];

  static const Color colorChartCurrent = Color(0xFFF87171);
```

- [ ] **Step 3: 전체 정적 분석 + 전체 테스트**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: 모든 테스트 통과 (기존 `expense_viewmodel_test.dart` + 이번에 추가한
`monthly_trend_bar_chart_test.dart`, `daily_cumulative_calc_test.dart` 포함)

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/app_colors.dart
git commit -m "chore(colors): remove unused chart average/line color constants"
```

---

## Task 10: 수동 확인

**Files:** 없음 (코드 변경 없음, 검증만)

- [ ] **Step 1: 앱 실행**

Run: `flutter run` (또는 `run` 스킬로 기존 프로젝트 실행 방식 사용)

- [ ] **Step 2: 체크리스트**

- `/expense/chart`, `/income/chart`, `/invest/chart`: 평균 기준선이 다크 배경에서 잘 보이는지,
  이번달 막대에 값 라벨이 항상 떠 있는지, 탭 시 다른 달 툴팁이 정상 동작하는지.
- `/expense/dailyChart`: 이번달 라인이 강조되고 지난 2개월이 회색으로 눌려 보이는지, 이번달
  라인 끝에 마커가 있는지, 하단 누적 카드가 지난달 동기간 대비 문구와 참조선을 정상 표시하는지
  (특히 월말 근처: 이번달 일수가 지난달보다 많은 경우).
- 빈 데이터(`EmptyView`)·에러(`ErrorView`) 상태가 기존과 동일하게 동작하는지.

이 태스크는 자동화된 단언이 없다 — 실제 실행 결과를 육안으로 확인하고 보고한다.
