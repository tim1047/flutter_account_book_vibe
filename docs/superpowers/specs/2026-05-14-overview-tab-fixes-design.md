# 개요 탭 3개 수정 설계

Date: 2026-05-14

## 1. 순자산 추이 차트 축 표시

### 변경 범위
`lib/features/dashboard/widgets/net_worth_line_chart.dart`

### 설계
- **Y축 (left)**: 3개 레이블, 만원 단위 (`₩5,000만`)
  - min / mid / max 3개 지점 계산
  - `reservedSize: 60` 확보
  - `1만` 미만은 `₩NNN원`, 1만 이상은 `₩NNN만` 형태
- **X축 (bottom)**: 월이 바뀌는 인덱스에만 `N월` 표시
  - history 데이터의 YYYYMMDD에서 월 추출
  - 연속된 같은 월이면 빈 문자열 반환
- **차트 height**: 120 → 170 (레이블 공간 확보)
- `titlesData`의 leftTitles, bottomTitles `showTitles: true`로 변경

### 성공 기준
- Y축 좌측에 3개의 금액 레이블이 표시됨
- X축 하단에 월이 바뀌는 지점마다 월 레이블이 표시됨

---

## 2. 지출 TOP5 이모지 + 카테고리명

### 변경 범위
`lib/features/dashboard/tabs/overview_tab.dart`

### 설계
- `MiniBarRow`의 `label` 파라미터를 `emoji` → `'$emoji ${e.categoryNm}'`으로 변경
- 1줄 변경

### 성공 기준
- 지출 TOP5 항목에 `🍔 식비`, `🚗 교통` 형태로 이모지 + 카테고리명 표시됨

---

## 3. 커스텀 기간 피커

### 변경 범위
`lib/features/dashboard/widgets/period_selector.dart`

### 설계
- `커스텀` 칩 탭 시 다른 기간과 분기 처리:
  ```
  if (p == DashboardPeriod.custom) {
    showDateRangePicker(context, ...) → vm.setCustomRange(start, end)
  } else {
    vm.select(p)
  }
  ```
- `showDateRangePicker` 옵션:
  - `firstDate`: 5년 전
  - `lastDate`: 오늘
  - `builder`: 앱 다크테마 오버라이드 (`colorScheme` teal 계열)
- 커스텀 선택 상태에서 칩 라벨: `1/1~3/31` 형태로 날짜 표시
  - `DashboardPeriodViewModel`에 `customLabel` getter 추가 (or `period_selector` 내에서 vm.range로 계산)

### DashboardPeriodViewModel 변경
- `customLabel` getter 추가:
  ```dart
  String get customLabel {
    if (_customStart == null || _customEnd == null) return '커스텀';
    return '${_customStart!.month}/${_customStart!.day}~${_customEnd!.month}/${_customEnd!.day}';
  }
  ```

### PeriodSelector 레이블 변경
- `_label(DashboardPeriod.custom)` → `커스텀`이 아닌 `vm.customLabel` 사용

### 성공 기준
- 커스텀 칩 탭 시 날짜 범위 선택 UI가 표시됨
- 날짜 선택 후 칩 라벨이 선택한 날짜로 업데이트됨
- 선택한 기간으로 대시보드 데이터가 갱신됨
