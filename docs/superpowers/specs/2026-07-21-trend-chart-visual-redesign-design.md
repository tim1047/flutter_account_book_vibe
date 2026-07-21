# 추이 차트 비주얼 개선 설계

## 배경

지출/수입/투자 추이 화면(`/expense/chart`, `/income/chart`, `/invest/chart`)의 월별 막대차트와,
지출 전용 일별 추이 화면(`/expense/dailyChart`)의 3개월 겹침 라인차트를 대상으로 시각 품질을
개선한다. 화면 구조(연/월 필터, API, 라우팅)는 그대로 두고 차트 표현만 바꾼다.

**범위 확인:** 드로어 기준으로 "추이" 3화면은 지출/수입/투자 월별 차트만 해당한다. 일별 겹침
라인차트는 지출에만 존재(`expense_daily_chart_screen.dart`)하며 수입/투자에는 대응 화면이
없다. 브레인스토밍 중 사용자 승인은 이 일별 화면도 포함해 진행한다.

## 발견된 기존 문제

1. `AppColors.colorChartAverage` (`0xFF30363D`)가 카드 배경 `colorBgCard` (`0xFF21262D`)와
   명도차가 거의 없어, 평균 막대가 사실상 안 보인다.
2. 일별 겹침 라인차트의 3색(`chartLineColors`: teal/pink/orange)을
   `dataviz` 팔레트 검증기로 돌려본 결과 teal↔pink 인접쌍 CVD ΔE 5.0으로 기준(6) 미달 —
   색약 사용자에게 두 선이 구분되지 않는다.

## 변경 1 — 월별 막대차트 (지출/수입/투자 3화면 공통)

대상 파일: `expense_monthly_chart_screen.dart`, `income_monthly_chart_screen.dart`,
`invest_monthly_chart_screen.dart` (각 파일의 `_BarChartCard`, `_MonthlyChartBody`)

- **제거:** 평균값을 별도 막대(그룹 마지막 x 위치, `colorChartAverage` 채움)로 그리던 로직 전체.
  안 보이는 막대를 없애는 것이므로 순수 제거.
- **추가:** `BarChartData.extraLinesData`에 평균가를 가로지르는 기준선(`HorizontalLine`) 1개.
  - 색상: `AppColors.colorTextSecondary`, 두께 1px, **실선** (점선은 그리드로 오인되므로 지양).
  - 라인 우측 끝에 작은 라벨 "평균 {금액}원" (`horizontalLine.label`).
- 막대 자체(월별 실제 지출/수입/투자액)는 유지: 이번달 강조색(`colorChartCurrent`), 나머지
  그래디언트, 폭/라운드 스펙 동일.
- **추가:** 이번달 막대 끝에 값 직접 라벨링(막대 위 텍스트, `colorTextPrimary`). 다른 달은
  기존처럼 탭 툴팁으로만 확인 — 모든 막대에 라벨을 달지 않는다.
- x축 카테고리 개수가 (평균 막대 제거로) 하나 줄어들므로 `orderedMonths.length` 기반 계산부(현재
  `평균` 분기 처리하던 titlesData/tooltip 콜백)도 단순화한다.

## 변경 2 — 일별 겹침 라인차트 (지출 전용, 2패널 분리)

대상 파일: `expense_daily_chart_screen.dart` (`_DailyChartBody`, `_MultiMonthLineChart`, `_Legend`)

원인: 누적값(원 단위지만 값이 일별 원시값보다 훨씬 큼)을 기존 라인과 같은 좌표축에 얹으면
스케일이 안 맞는 두 값을 억지로 한 축에 비교하게 되어 dual-axis 왜곡과 동일한 문제가 생긴다.
그래서 차트를 2개로 분리한다. API 추가 호출 없음 — 이미 3개월치 daily 데이터를 갖고 있으므로
누적합은 클라이언트에서 계산.

**패널 A — 기존 3개월 겹침 라인 (리터치, 유지)**
- 이번달 라인만 강조: `colorChartCurrent`, 두께 2px, 끝점에 8px 마커(2px surface ring).
- 지난 2개월 라인은 회색조로 눌러줌(`colorTextSecondary` 계열, 두께 1px, 영역 채움 없음)
  — 기존 `chartLineColors` 3색 순환 방식 제거. 이 방식이 teal/pink CVD 문제도 같이 해결한다
  (색 구분 대신 강조/눌림으로 시리즈 식별).
- 범례는 "이번달" 1개 + "지난달들"(회색) 1개로 단순화.

**패널 B — 이번달 누적 지출 (신규 카드)**
- 이번달 일별 데이터를 날짜순 누적합(area, ~10% opacity 채움)으로 표시, 자체 y축(0~이번달
  누적 최대치).
- 참조선 1개: "지난달 같은 날짜까지의 누적액" — 같은 단위(원)라 한 축에서 안전하게 비교 가능.
  지난달 일수가 부족하면(예: 이번달 31일, 지난달 30일) 지난달 마지막 날 값으로 고정.
- 상단에 "이번달 누적 {금액}원 (지난달 동기간 대비 {+/-}{금액}원)" 텍스트 1줄.

## 변경 3 — 색상 정리

- `AppColors.colorChartAverage`: 위 변경 1로 인해 사용처가 없어지므로 **완전 삭제**.
- `AppColors.chartLineColors`: 위 변경 2로 인해 사용처가 없어지므로 **완전 삭제**.
- `AppColors.colorChartCurrent`: 계속 사용 (막대/라인 강조색).
- 신규로 필요한 "de-emphasis 회색"은 기존 `colorTextSecondary`를 재사용 (새 색상 상수 추가 없음).

## 컴포넌트 구조 결정 (확정)

3개 월별 화면의 `_BarChartCard`/`_MonthlyChartBody`/`_SummaryCard`는 현재 100% 동일 코드가
파일마다 복붙되어 있다. `lib/shared/widgets/`에 공통 위젯(`MonthlyTrendBarChart`,
`TrendSummaryCard`)으로 추출하고, 3개 화면의 스크린 파일은 이를 호출하도록 교체한다.

이유: 지금도 100% 중복 코드가 3벌 존재하는 상태이고, 이번 변경으로 로직(평균선 계산, 현재월
라벨링)이 늘어나므로 중복을 그대로 3배로 늘리는 것보다 지금 걷어내는 편이 낫다.

- `_SummaryCard`의 텍스트 문구(예: "더 썼어요" vs "더 투자했어요")는 화면별로 다르므로 문구
  문자열은 공통 위젯의 파라미터로 받는다.
- 아이콘/색상(`colorExpense`/`colorInvest`/`colorIncome` 등 division별 강조색)도 파라미터로
  받는다.
- 기존 `_BarChartCard`/`_MonthlyChartBody`/`_SummaryCard` private 클래스 3벌은 삭제하고 공통
  위젯 호출로 교체한다 (남겨두지 않음).

## 영향받지 않는 부분

- `ExpenseChartViewModel`/`IncomeChartViewModel`/`InvestChartViewModel`의 API 호출 로직, 데이터
  모델(`SumGroupByMonthResponse`, `MonthDailyData` 등) — 변경 없음.
- `DateFilterBar`/`DateFilterViewModel` — 변경 없음.
- 라우팅, 드로어 진입점 — 변경 없음.

## 테스트

- `test/` 확인 결과 차트 화면 대상 위젯 테스트는 없음(`expense_viewmodel_test.dart`만 존재,
  이번 변경과 무관). 별도 테스트 갱신 불필요.
- 수동 확인: 3개 월별 화면에서 평균선 표시, 이번달 막대 라벨, 다크 배경에서 평균선 가시성.
  지출 일별 화면에서 패널 A 강조/눌림 대비, 패널 B 누적선 지난달 대비 정상 계산(월말 근처 edge
  case 포함).
