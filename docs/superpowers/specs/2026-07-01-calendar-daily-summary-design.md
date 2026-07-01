# 대시보드 개요 탭 — 달력 일자별 지출/수입/투자 요약

## 목표

`overview_tab.dart`에 달력(월간 grid) 위젯을 추가해 날짜별 지출/수입/투자 합계를 색상 구분해 보여준다.
날짜를 탭하면 그 날짜만 필터된 가계부 목록(`AccountListScreen`)으로 이동한다.

## 레이아웃

### overview_tab 섹션 순서 (변경 후)

```
① 수입/지출/저축/투자 Hero 카드   (기존)
② 달력 요약                      ← 신규
③ 지출 TOP 5 카테고리             (기존)
④ 최근 거래                      (기존)
```

`② 달력 요약`은 `_SectionCard` 없이 자체 카드(`CalendarSummaryCard`)로 구현하고, 대시보드 상단 `PeriodSelector`(분기/반기/연도 등 선택 가능)와는 독립적으로 자체 월 이동(prev/next)을 가진다. `PeriodSelector`는 grid 형태와 맞지 않아 연동하지 않는다.

### 달력 셀 구조

- `table_calendar` 패키지 사용 (Dart SDK `>=3.2.3` 요구사항과 호환 확인함)
- 셀 높이를 키워 하루당 3줄 고정 표시: 지출(빨강) / 수입(청록) / 투자(주황), 원 단위 그대로(`FormatUtil.formatPrice`), 0원도 표시(빈 줄로 비지 않게 고정 레이아웃 유지)
- 색상: `AppColors.colorExpense` / `colorIncome` / `colorInvest` (기존 토큰 재사용, 신규 정의 없음)
- 요일 헤더, 월 이동 화살표는 `table_calendar` 기본 헤더 커스터마이징으로 처리

## 데이터 흐름

### 신규 API 호출: 없음 (기존 엔드포인트 재사용)

`CalendarSummaryViewModel`이 보이는 월이 바뀔 때마다 `DivisionService.instance.getDivisionSumDaily(divisionId, strtDt, endDt)`를 division별로 3번 호출한다 (`Division.income='1'`, `Division.expense='3'`, `Division.invest='2'`). `strtDt`/`endDt`는 `FormatUtil.toStrtDt(year, month)` / `toEndDt(year, month)`로 생성.

### 신규 모델

```dart
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
```

### `CalendarSummaryViewModel`

```dart
class CalendarSummaryViewModel extends ChangeNotifier {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month; // 0 미사용, 항상 1~12
  Map<int, CalendarDaySummary> _byDay = {};
  bool isLoading = false;
  String? errorMessage;

  Future<void> load(); // 현재 _year/_month 기준 3개 API 병렬 호출 → _byDay 구성
  void goPrevMonth();   // _month--/_year-- 처리 후 load()
  void goNextMonth();   // _month++/_year++ 처리 후 load()
}
```

3개 `List<DailyChartEntry>` 응답(day, price)을 day 기준으로 합쳐 `Map<int, CalendarDaySummary>` 생성. 응답에 없는 day는 0 처리(=`CalendarDaySummary()` 기본값).

## UI 컴포넌트

| 파일 | 역할 |
|------|------|
| `lib/features/dashboard/viewmodels/calendar_summary_viewmodel.dart` | 신규 — 위 뷰모델 |
| `lib/features/dashboard/widgets/calendar_summary_card.dart` | 신규 — `TableCalendar` 래핑, 셀 빌더로 3줄 요약 렌더링, `onDaySelected`에서 라우팅 |
| `lib/features/dashboard/tabs/overview_tab.dart` | 수정 — `CalendarSummaryCard` 삽입 (Hero 카드 아래) |
| `lib/features/dashboard/dashboard_screen.dart` | 수정 — `CalendarSummaryViewModel` 생성/dispose, `OverviewTab`에 주입 |

`CalendarSummaryViewModel`은 `DashboardOverviewViewModel`과 무관한 독립 뷰모델로, `dashboard_screen.dart`에서 다른 탭 뷰모델들과 동일한 패턴으로 생성·dispose한다.

## 라우팅 / 날짜 필터

### `AccountListExtra` 확장

```dart
class AccountListExtra {
  const AccountListExtra({
    this.divisionId,
    this.categoryId,
    this.categorySeq,
    this.memberId,
    this.date, // 신규: 'YYYYMMDD', strtDt/endDt와 동일 포맷
  });
  final String? date;
}
```

### 셀 탭 동작

`CalendarSummaryCard.onDaySelected` → `context.push('/accountList', extra: AccountListExtra(date: 'YYYYMMDD'))`

### `account_list_screen.dart` 변경

`initState`에서 `widget.extra?.date`가 있으면:
1. 해당 날짜의 year/month를 `DateFilterViewModel`(싱글톤)에 반영 — `DateFilterBar` 드롭다운이 그 달을 보여주기 위함(기존 "월 이동 시 필터 상태 유지" 패턴과 일관)
2. `_load()` 대신 `_vm.load(date, date)` 직접 호출 — 그 날짜만 조회

이후 사용자가 `DateFilterBar`(prev/next, 드롭다운, 새로고침)를 조작하면 기존 로직 그대로 `_dateFilter.strtDt/endDt`(월 범위)를 사용해 `_load()`가 호출되므로 자연스럽게 월 전체 보기로 전환된다. 별도의 "필터 해제" UI/상태는 추가하지 않는다. 뒤로가기는 기존 네비게이션 스택 pop 그대로 동작(대시보드 캘린더로 복귀).

## 변경 파일 목록

| 파일 | 변경 유형 |
|------|-----------|
| `pubspec.yaml` | 수정 — `table_calendar` 의존성 추가 |
| `lib/features/dashboard/viewmodels/calendar_summary_viewmodel.dart` | 신규 |
| `lib/features/dashboard/widgets/calendar_summary_card.dart` | 신규 |
| `lib/features/dashboard/tabs/overview_tab.dart` | 수정 |
| `lib/features/dashboard/dashboard_screen.dart` | 수정 |
| `lib/features/account/account_list_extra.dart` | 수정 — `date` 필드 추가 |
| `lib/features/account/account_list_screen.dart` | 수정 — `date` 있을 때 단일일 조회 |

## 비변경 파일

- `lib/data/services/division_service.dart` — 기존 `getDivisionSumDaily` 그대로 재사용, API 변경 없음
- `lib/shared/viewmodels/date_filter_viewmodel.dart` — 월 단위 구조 그대로 유지, day-level 개념 추가하지 않음
- `lib/features/account/account_list_viewmodel.dart` — `load(strtDt, endDt)` 시그니처 그대로 재사용

## 엣지 케이스

| 케이스 | 처리 |
|--------|------|
| 특정 날짜에 거래 3종 모두 없음 | 3줄 모두 0원 표시 (레이아웃 고정 유지) |
| API 호출 3개 중 일부 실패 | 전체 로딩 실패로 처리, `errorMessage` 표시 + 재시도 버튼 (기존 `ErrorView` 패턴) |
| 월 이동 중 빠르게 연타 | 최신 요청만 반영 — 로드 시작 시 요청 토큰/버전 증가시켜 이전 응답 무시 |
| 날짜 탭 후 뒤로가기 → 다시 같은 날짜 탭 | 매번 새로 `_vm.load(date, date)` 호출, 캐시 없음 (기존 화면 재사용 안 하고 매번 새 인스턴스라 문제 없음) |
| 미래 날짜 탭 (거래 없음) | 빈 목록(`EmptyView`) — 기존 목록 화면 동작 그대로 |
