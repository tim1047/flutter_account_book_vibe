# 달력 일자별 지출/수입/투자 요약 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 대시보드 개요 탭에 월간 달력 위젯을 추가해 날짜별 지출/수입/투자 합계를 색상 구분해 보여주고, 날짜 탭 시 그 날짜만 필터된 가계부 목록으로 이동한다.

**Architecture:** `table_calendar` 패키지로 달력 grid를 그리고, 독립 `ChangeNotifier`(`CalendarSummaryViewModel`)가 `DivisionService.getDivisionSumDaily`를 division별(수입/지출/투자) 3회 호출해 일자별 합계를 구성한다. 날짜 탭은 기존 `context.push('/accountList', extra: AccountListExtra(...))` 패턴을 재사용하되 `AccountListExtra`에 `date` 필드를 추가한다.

**Tech Stack:** Flutter/Dart, `ChangeNotifier` (Riverpod/Bloc/GetX 금지), `go_router`, `table_calendar` (신규), 기존 `DivisionService`/`FormatUtil`/`AppColors`/`AppTextStyles` 재사용.

## Global Constraints

- Dart SDK `>=3.2.3 <4.0.0` — `table_calendar`는 이 범위와 호환되는 최신 버전 사용 (`flutter pub add table_calendar`로 설치, 버전 하드코딩 금지)
- 상태관리는 `ChangeNotifier`만 사용, Riverpod/Bloc/GetX 사용 금지
- 색상은 `AppColors.colorIncome`/`colorExpense`/`colorInvest` 기존 토큰 재사용, 신규 색상 정의 금지
- 텍스트 스타일은 `AppTextStyles`의 기존 스타일 재사용, 신규 스타일 정의 금지
- 신규 API 엔드포인트 추가 금지 — `DivisionService.getDivisionSumDaily` 기존 메서드만 사용
- 달력 셀은 3줄 고정(지출/수입/투자), 원 단위 그대로 표시, 0원도 표시
- 날짜 필터는 `AccountListExtra.date` (`'YYYYMMDD'`, 기존 `strtDt`/`endDt`와 동일 포맷)로 전달
- 목록 화면에 "필터 해제" UI 추가 금지 — `DateFilterBar` 조작 시 자연스럽게 월 전체 보기로 전환되는 기존 로직 그대로 사용
- 이 프로젝트는 순수 로직(뷰모델의 정적/동기 메서드)만 단위 테스트하고, 네트워크 호출(`load()`)이나 화면 위젯은 테스트하지 않는 기존 컨벤션을 따른다 (`ExpenseChartViewModel`, `DashboardPeriodViewModel` 참고)

---

### Task 1: `table_calendar` 의존성 추가

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: `table_calendar` 패키지 import 가능 (`package:table_calendar/table_calendar.dart`)

- [ ] **Step 1: 패키지 추가**

```bash
flutter pub add table_calendar
```

- [ ] **Step 2: 설치 확인**

Run: `flutter pub get`
Expected: `Got dependencies!` 출력, `pubspec.yaml`의 `dependencies:` 아래 `table_calendar: ^<version>` 라인 추가됨

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add table_calendar dependency"
```

---

### Task 2: `CalendarSummaryViewModel` — 일자별 합계 모델 + 순수 로직

**Files:**
- Create: `lib/features/dashboard/viewmodels/calendar_summary_viewmodel.dart`
- Test: `test/features/dashboard/calendar_summary_viewmodel_test.dart`

**Interfaces:**
- Consumes: `DivisionService.instance.getDivisionSumDaily(String divisionId, {String? strtDt, String? endDt}) → Future<List<DailyChartEntry>>` (기존, `lib/data/services/division_service.dart`), `DailyChartEntry({required int day, required int price})` (기존, `lib/data/models/division_model.dart`), `Division.income='1'`/`Division.expense='3'`/`Division.invest='2'` (기존, `lib/core/constants/division.dart`), `FormatUtil.toStrtDt(int year, int month)`/`toEndDt(int year, int month) → String` (기존, `lib/core/utils/format_util.dart`)
- Produces: `CalendarDaySummary({int income, int expense, int invest})`, `CalendarSummaryViewModel` — `int get year`/`int get month`, `bool isLoading`, `String? errorMessage`, `void setMonth(int year, int month)`, `CalendarDaySummary summaryFor(DateTime day)`, `Future<void> load()`, `static Map<int, CalendarDaySummary> combine({required List<DailyChartEntry> income, required List<DailyChartEntry> expense, required List<DailyChartEntry> invest})`

- [ ] **Step 1: 실패하는 테스트 작성 — `combine`**

```dart
// test/features/dashboard/calendar_summary_viewmodel_test.dart
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarSummaryViewModel.combine', () {
    test('수입/지출/투자 일자별 합계를 day 기준으로 합친다', () {
      final result = CalendarSummaryViewModel.combine(
        income: [const DailyChartEntry(day: 1, price: 100000)],
        expense: [
          const DailyChartEntry(day: 1, price: 30000),
          const DailyChartEntry(day: 3, price: 5000),
        ],
        invest: [const DailyChartEntry(day: 1, price: 20000)],
      );

      expect(result[1]!.income, 100000);
      expect(result[1]!.expense, 30000);
      expect(result[1]!.invest, 20000);
      expect(result[3]!.income, 0);
      expect(result[3]!.expense, 5000);
      expect(result[3]!.invest, 0);
    });

    test('세 리스트 모두 비어있으면 빈 맵 반환', () {
      final result = CalendarSummaryViewModel.combine(
        income: const [],
        expense: const [],
        invest: const [],
      );
      expect(result, isEmpty);
    });
  });

  group('CalendarSummaryViewModel.setMonth', () {
    test('연/월 갱신 및 리스너 알림', () {
      final vm = CalendarSummaryViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      vm.setMonth(2026, 3);

      expect(vm.year, 2026);
      expect(vm.month, 3);
      expect(notified, true);
    });
  });

  group('CalendarSummaryViewModel.summaryFor', () {
    test('데이터 없는 날짜는 기본값(0/0/0) 반환', () {
      final vm = CalendarSummaryViewModel();
      final summary = vm.summaryFor(DateTime(2026, 7, 15));
      expect(summary.income, 0);
      expect(summary.expense, 0);
      expect(summary.invest, 0);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/features/dashboard/calendar_summary_viewmodel_test.dart`
Expected: FAIL — `calendar_summary_viewmodel.dart` 파일이 없어서 컴파일 에러

- [ ] **Step 3: 구현**

```dart
// lib/features/dashboard/viewmodels/calendar_summary_viewmodel.dart
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/data/services/division_service.dart';
import 'package:flutter/foundation.dart';

class CalendarDaySummary {
  const CalendarDaySummary({
    this.income = 0,
    this.expense = 0,
    this.invest = 0,
  });

  final int income;
  final int expense;
  final int invest;
}

class CalendarSummaryViewModel extends ChangeNotifier {
  CalendarSummaryViewModel()
      : _year = DateTime.now().year,
        _month = DateTime.now().month;

  int _year;
  int _month;
  Map<int, CalendarDaySummary> _byDay = {};

  bool isLoading = false;
  String? errorMessage;

  int get year => _year;
  int get month => _month;

  CalendarDaySummary summaryFor(DateTime day) =>
      _byDay[day.day] ?? const CalendarDaySummary();

  void setMonth(int year, int month) {
    _year = year;
    _month = month;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final strtDt = FormatUtil.toStrtDt(_year, _month);
      final endDt = FormatUtil.toEndDt(_year, _month);
      final results = await Future.wait([
        DivisionService.instance.getDivisionSumDaily(
          Division.income,
          strtDt: strtDt,
          endDt: endDt,
        ),
        DivisionService.instance.getDivisionSumDaily(
          Division.expense,
          strtDt: strtDt,
          endDt: endDt,
        ),
        DivisionService.instance.getDivisionSumDaily(
          Division.invest,
          strtDt: strtDt,
          endDt: endDt,
        ),
      ]);
      _byDay = combine(income: results[0], expense: results[1], invest: results[2]);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static Map<int, CalendarDaySummary> combine({
    required List<DailyChartEntry> income,
    required List<DailyChartEntry> expense,
    required List<DailyChartEntry> invest,
  }) {
    final incomeByDay = {for (final e in income) e.day: e.price};
    final expenseByDay = {for (final e in expense) e.day: e.price};
    final investByDay = {for (final e in invest) e.day: e.price};
    final days = {...incomeByDay.keys, ...expenseByDay.keys, ...investByDay.keys};
    return {
      for (final day in days)
        day: CalendarDaySummary(
          income: incomeByDay[day] ?? 0,
          expense: expenseByDay[day] ?? 0,
          invest: investByDay[day] ?? 0,
        ),
    };
  }
}
```

- [ ] **Step 4: 테스트 실행해서 통과 확인**

Run: `flutter test test/features/dashboard/calendar_summary_viewmodel_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/viewmodels/calendar_summary_viewmodel.dart test/features/dashboard/calendar_summary_viewmodel_test.dart
git commit -m "feat(dashboard): add CalendarSummaryViewModel for daily totals"
```

---

### Task 3: `AccountListExtra.date` 필드 + 파싱 헬퍼

**Files:**
- Modify: `lib/features/account/account_list_extra.dart`
- Test: `test/features/account/account_list_extra_test.dart`

**Interfaces:**
- Produces: `AccountListExtra({..., String? date})`, `static ({int year, int month}) AccountListExtra.parseDateYearMonth(String date)`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// test/features/account/account_list_extra_test.dart
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountListExtra.parseDateYearMonth', () {
    test('YYYYMMDD 문자열에서 연/월 추출', () {
      final result = AccountListExtra.parseDateYearMonth('20260715');
      expect(result.year, 2026);
      expect(result.month, 7);
    });

    test('12월도 올바르게 파싱', () {
      final result = AccountListExtra.parseDateYearMonth('20251231');
      expect(result.year, 2025);
      expect(result.month, 12);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/features/account/account_list_extra_test.dart`
Expected: FAIL — `parseDateYearMonth` 메서드 없음 (컴파일 에러)

- [ ] **Step 3: 구현**

```dart
// lib/features/account/account_list_extra.dart
class AccountListExtra {
  const AccountListExtra({
    this.divisionId,
    this.categoryId,
    this.categorySeq,
    this.memberId,
    this.date,
  });

  final String? divisionId;
  final String? categoryId;
  final String? categorySeq;
  final String? memberId;

  /// 'YYYYMMDD' — 특정 날짜만 필터링할 때 사용 (기존 strtDt/endDt와 동일 포맷)
  final String? date;

  static ({int year, int month}) parseDateYearMonth(String date) => (
        year: int.parse(date.substring(0, 4)),
        month: int.parse(date.substring(4, 6)),
      );
}
```

- [ ] **Step 4: 테스트 실행해서 통과 확인**

Run: `flutter test test/features/account/account_list_extra_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/account/account_list_extra.dart test/features/account/account_list_extra_test.dart
git commit -m "feat(account): add date field to AccountListExtra"
```

---

### Task 4: `account_list_screen.dart` — 날짜 필터로 진입 시 단일일 조회

**Files:**
- Modify: `lib/features/account/account_list_screen.dart:33-56` (`_AccountListScreenState.initState`)

**Interfaces:**
- Consumes: `AccountListExtra.date` (Task 3), `AccountListExtra.parseDateYearMonth` (Task 3), `DateFilterViewModel.setYear(int)`/`setMonth(int)` (기존), `AccountListViewModel.load(String strtDt, String endDt)` (기존)
- Produces: 없음 (화면 진입 동작 변경만)

- [ ] **Step 1: `initState` 수정**

`lib/features/account/account_list_screen.dart`의 기존 코드:

```dart
  @override
  void initState() {
    super.initState();
    _dateFilter = DateFilterViewModel();
    _vm = AccountListViewModel();
    if (widget.extra != null) {
      final e = widget.extra!;
      _vm.filterState = AccountFilterState(
        divisionIds: e.divisionId != null ? {e.divisionId!} : {},
        categoryIds: e.categoryId != null ? {e.categoryId!} : {},
        categorySeqs: e.categorySeq != null ? {e.categorySeq!} : {},
        memberIds: e.memberId != null ? {e.memberId!} : {},
      );
    }
    _load();
  }
```

다음으로 교체:

```dart
  @override
  void initState() {
    super.initState();
    _dateFilter = DateFilterViewModel();
    _vm = AccountListViewModel();
    if (widget.extra != null) {
      final e = widget.extra!;
      _vm.filterState = AccountFilterState(
        divisionIds: e.divisionId != null ? {e.divisionId!} : {},
        categoryIds: e.categoryId != null ? {e.categoryId!} : {},
        categorySeqs: e.categorySeq != null ? {e.categorySeq!} : {},
        memberIds: e.memberId != null ? {e.memberId!} : {},
      );
    }

    final selectedDate = widget.extra?.date;
    if (selectedDate != null) {
      final ym = AccountListExtra.parseDateYearMonth(selectedDate);
      _dateFilter.setYear(ym.year);
      _dateFilter.setMonth(ym.month);
      _vm.load(selectedDate, selectedDate);
    } else {
      _load();
    }
  }
```

- [ ] **Step 2: 정적 분석으로 검증**

Run: `flutter analyze lib/features/account/account_list_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: 전체 테스트 스위트 회귀 확인**

Run: `flutter test`
Expected: 기존 테스트 전부 PASS (이 파일은 위젯 테스트 대상이 아니므로 신규 테스트 없음 — 기존 컨벤션)

- [ ] **Step 4: Commit**

```bash
git add lib/features/account/account_list_screen.dart
git commit -m "feat(account): support single-day filter via AccountListExtra.date"
```

---

### Task 5: `CalendarSummaryCard` 위젯 — 달력 UI + 셀 렌더링 + 날짜 탭 라우팅

**Files:**
- Create: `lib/features/dashboard/widgets/calendar_summary_card.dart`

**Interfaces:**
- Consumes: `CalendarSummaryViewModel` (Task 2) — `year`/`month`/`setMonth`/`load`/`summaryFor`, `AccountListExtra` (Task 3) — `date` 필드, `FormatUtil.formatPrice(int)` (기존), `AppColors.colorIncome`/`colorExpense`/`colorInvest`/`colorBgCard`/`colorAccentTeal`/`colorTextPrimary` (기존), `AppTextStyles.textCaption`/`textHeadlineSm` (기존)
- Produces: `CalendarSummaryCard({required CalendarSummaryViewModel vm})` — 위젯

- [ ] **Step 1: 위젯 구현**

```dart
// lib/features/dashboard/widgets/calendar_summary_card.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarSummaryCard extends StatefulWidget {
  const CalendarSummaryCard({super.key, required this.vm});

  final CalendarSummaryViewModel vm;

  @override
  State<CalendarSummaryCard> createState() => _CalendarSummaryCardState();
}

class _CalendarSummaryCardState extends State<CalendarSummaryCard> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(widget.vm.year, widget.vm.month);
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() => _focusedDay = focusedDay);
    widget.vm.setMonth(focusedDay.year, focusedDay.month);
    widget.vm.load();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final date = '${selectedDay.year}${_pad(selectedDay.month)}${_pad(selectedDay.day)}';
    context.push('/accountList', extra: AccountListExtra(date: date));
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          return TableCalendar<void>(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focusedDay,
            rowHeight: 76,
            daysOfWeekHeight: 20,
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTextStyles.textHeadlineSm,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: AppColors.colorAccentTeal,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: AppColors.colorAccentTeal,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: AppTextStyles.textCaption,
              weekendStyle: AppTextStyles.textCaption,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _DayCell(day: day, summary: widget.vm.summaryFor(day)),
              todayBuilder: (context, day, focusedDay) => _DayCell(
                day: day,
                summary: widget.vm.summaryFor(day),
                isToday: true,
              ),
              outsideBuilder: (context, day, focusedDay) =>
                  const SizedBox.shrink(),
            ),
            onPageChanged: _onPageChanged,
            onDaySelected: _onDaySelected,
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.summary,
    this.isToday = false,
  });

  final DateTime day;
  final CalendarDaySummary summary;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: isToday
          ? BoxDecoration(
              border: Border.all(color: AppColors.colorAccentTeal),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: AppTextStyles.textCaption.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          _AmountLine(amount: summary.income, color: AppColors.colorIncome),
          _AmountLine(amount: summary.expense, color: AppColors.colorExpense),
          _AmountLine(amount: summary.invest, color: AppColors.colorInvest),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.amount, required this.color});

  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      FormatUtil.formatPrice(amount),
      style: AppTextStyles.textCaption.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
```

- [ ] **Step 2: 정적 분석으로 검증**

Run: `flutter analyze lib/features/dashboard/widgets/calendar_summary_card.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/widgets/calendar_summary_card.dart
git commit -m "feat(dashboard): add CalendarSummaryCard widget"
```

---

### Task 6: `overview_tab.dart` + `dashboard_screen.dart` 통합

**Files:**
- Modify: `lib/features/dashboard/tabs/overview_tab.dart`
- Modify: `lib/features/dashboard/dashboard_screen.dart`

**Interfaces:**
- Consumes: `CalendarSummaryViewModel` (Task 2), `CalendarSummaryCard` (Task 5)
- Produces: `OverviewTab({required DashboardOverviewViewModel vm, required CalendarSummaryViewModel calendarVm})` (시그니처 변경)

- [ ] **Step 1: `overview_tab.dart` — import 추가**

`lib/features/dashboard/tabs/overview_tab.dart` 최상단 import 목록에 추가:

```dart
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/calendar_summary_card.dart';
```

- [ ] **Step 2: `OverviewTab` 시그니처 변경**

기존:

```dart
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.vm});

  final DashboardOverviewViewModel vm;
```

교체:

```dart
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.vm, required this.calendarVm});

  final DashboardOverviewViewModel vm;
  final CalendarSummaryViewModel calendarVm;
```

같은 클래스 `build` 안의 `return _OverviewContent(data: data);`를 다음으로 교체:

```dart
        return _OverviewContent(data: data, calendarVm: calendarVm);
```

- [ ] **Step 3: `_OverviewContent`에 달력 삽입**

기존:

```dart
class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.data});

  final DashboardOverviewData data;
```

교체:

```dart
class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.data, required this.calendarVm});

  final DashboardOverviewData data;
  final CalendarSummaryViewModel calendarVm;
```

`build` 메서드에서 투자 `HeroMetricCard` 다음의 `const SizedBox(height: 16),`와 `// ② 지출 TOP 5` 주석 사이(기존 line 98~100)에 삽입:

```dart
        const SizedBox(height: 16),

        // ②-1 달력 요약
        CalendarSummaryCard(vm: calendarVm),
        const SizedBox(height: 16),

        // ② 지출 TOP 5
```

(기존 `const SizedBox(height: 16),` 한 줄을 지우지 않고, 그 아래에 달력 섹션을 새로 끼워 넣는 것 — 최종적으로 SizedBox 16 → CalendarSummaryCard → SizedBox 16 → 지출 TOP5 순서)

- [ ] **Step 4: `dashboard_screen.dart` — import 추가**

`lib/features/dashboard/dashboard_screen.dart` import 목록에 추가:

```dart
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
```

- [ ] **Step 5: 뷰모델 생성/dispose/전달**

`_DashboardScreenState`의 필드 선언부(`late final DashboardAssetViewModel _assetVm;` 다음 줄)에 추가:

```dart
  late final CalendarSummaryViewModel _calendarVm;
```

`initState`의 `_assetVm = DashboardAssetViewModel()..load();` 다음 줄에 추가:

```dart
    _calendarVm = CalendarSummaryViewModel()..load();
```

`dispose`의 `_assetVm.dispose();` 다음 줄에 추가:

```dart
    _calendarVm.dispose();
```

`build` 안 `OverviewTab(vm: _overviewVm),`를 다음으로 교체:

```dart
          OverviewTab(vm: _overviewVm, calendarVm: _calendarVm),
```

FAB `onPressed`의 `_expenseVm.load();` 다음 줄에 추가 (거래 추가 후 달력도 갱신):

```dart
          _calendarVm.load();
```

- [ ] **Step 6: 정적 분석 + 전체 테스트**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: 전체 테스트 PASS (기존 테스트 회귀 없음, Task 2/3 신규 테스트 포함)

- [ ] **Step 7: Commit**

```bash
git add lib/features/dashboard/tabs/overview_tab.dart lib/features/dashboard/dashboard_screen.dart
git commit -m "feat(dashboard): wire calendar summary into overview tab"
```

- [ ] **Step 8: 앱 실행해서 수동 확인**

Run: `flutter run` (시뮬레이터/실기기)
확인 항목:
- 대시보드 개요 탭에서 Hero 카드 4개 아래 달력이 3줄(지출/수입/투자, 색상 구분) 표시되는지
- 달력 헤더 좌우 화살표로 월 이동 시 데이터가 갱신되는지
- 날짜를 탭하면 `/accountList`로 이동하고 그 날짜 거래만 보이는지
- 목록 화면에서 뒤로가기 하면 달력으로 정상 복귀하는지

---

## Self-Review 결과

- **스펙 커버리지**: 달력 UI(Task 1, 5), 일자별 3색 합계(Task 2, 5), 날짜 탭 → 목록 이동(Task 3, 4, 5), 대시보드 배치(Task 6) — 스펙의 모든 섹션에 대응하는 태스크 있음
- **플레이스홀더 스캔**: 없음 — 모든 스텝에 전체 코드 포함
- **타입 일관성 확인**: `CalendarDaySummary`(Task 2) → `_DayCell.summary`(Task 5)에서 동일 타입 사용, `AccountListExtra.date`/`parseDateYearMonth`(Task 3) → `account_list_screen.dart`(Task 4) 및 `calendar_summary_card.dart`(Task 5)에서 동일 시그니처로 사용됨. `CalendarSummaryViewModel.year`/`month`/`setMonth`/`load`/`summaryFor` 네이밍이 Task 2 정의와 Task 5 사용처에서 일치함
