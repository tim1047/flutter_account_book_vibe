# Net Worth Chart 2개 수정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 순자산 추이 차트의 Y축 단위를 천만원으로 변경하고, 미래 날짜의 0 데이터를 최근 값으로 carry-forward 처리한다.

**Architecture:** (1) `NetWorthLineChart` Y축 레이블 포맷 수정 → (2) `overview_viewmodel`과 `asset_viewmodel` 두 곳의 `_buildNetWorthHistory`에 carry-forward 로직 추가. 두 태스크는 독립적으로 컴파일·실행 가능하다.

**Tech Stack:** Flutter 3, Dart null safety, ChangeNotifier

---

### Task 1: Y축 단위 천만원으로 변경

**Files:**
- Modify: `lib/features/dashboard/widgets/net_worth_line_chart.dart`

현재 Y축 레이블은 `/10000` (만원 단위)로 계산. 천만원 단위(`/10000000`)로 변경.

- [ ] **Step 1: Y축 레이블 수정**

`lib/features/dashboard/widgets/net_worth_line_chart.dart` 의 `getTitlesWidget` 내부 86-93번째 줄:

기존:
```dart
getTitlesWidget: (value, _) {
  final inMan = (value / 10000).round();
  return Text(
    '₩${FormatUtil.formatPrice(inMan)}만',
    style: AppTextStyles.textBodyXs.copyWith(
      color: AppColors.colorTextSecondary,
    ),
  );
},
```

변경 후:
```dart
getTitlesWidget: (value, _) {
  final inCheomMan = (value / 10000000).round();
  return Text(
    '₩${FormatUtil.formatPrice(inCheomMan)}천만',
    style: AppTextStyles.textBodyXs.copyWith(
      color: AppColors.colorTextSecondary,
    ),
  );
},
```

- [ ] **Step 2: 빌드 확인**

```bash
flutter analyze lib/features/dashboard/widgets/net_worth_line_chart.dart
```

Expected: 오류 없음

- [ ] **Step 3: 커밋**

```bash
git add lib/features/dashboard/widgets/net_worth_line_chart.dart
git commit -m "fix(dashboard): change Y-axis unit to 천만원 in NetWorthLineChart"
```

---

### Task 2: 미래 월 0 → 최근 데이터 carry-forward

**Files:**
- Modify: `lib/features/dashboard/viewmodels/overview_viewmodel.dart`
- Modify: `lib/features/dashboard/viewmodels/asset_viewmodel.dart`

올해 기간 선택 시 미래 월(6~12월)은 API가 0을 반환. 이를 마지막으로 알려진 순자산 값으로 대체.

로직:
- 정렬된 history 리스트를 순서대로 순회
- `date <= today` 이고 `amount != 0` → `lastKnown = amount`로 업데이트
- `date > today` 이고 `amount == 0` → `lastKnown`으로 대체
- `lastKnown == 0` 이면 대체 안 함 (데이터 없음 상태 유지)

- [ ] **Step 1: overview_viewmodel.dart 수정**

`lib/features/dashboard/viewmodels/overview_viewmodel.dart` 의 `_buildNetWorthHistory` 메서드 175-179번째 줄 (`return allDates.map(...)`) 교체:

기존:
```dart
    return allDates.map((date) {
      final asset = byDateAsset[date] ?? 0;
      final debt = byDateDebt[date] ?? 0;
      return (date: date, amount: asset - debt);
    }).toList();
```

변경 후:
```dart
    final now = DateTime.now();
    final todayStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final raw = allDates.map((date) {
      final asset = byDateAsset[date] ?? 0;
      final debt = byDateDebt[date] ?? 0;
      return (date: date, amount: asset - debt);
    }).toList();

    var lastKnown = 0;
    return raw.map((e) {
      if (e.date <= todayStr && e.amount != 0) lastKnown = e.amount;
      if (e.date > todayStr && e.amount == 0 && lastKnown != 0) {
        return (date: e.date, amount: lastKnown);
      }
      return e;
    }).toList();
```

- [ ] **Step 2: asset_viewmodel.dart 수정**

`lib/features/dashboard/viewmodels/asset_viewmodel.dart` 의 `_buildNetWorthHistory` 메서드 160-164번째 줄 (`return allDates.map(...)`) 교체:

기존:
```dart
    return allDates.map((date) {
      final asset = byDateAsset[date] ?? 0;
      final debt = byDateDebt[date] ?? 0;
      return (date: date, amount: asset - debt);
    }).toList();
```

변경 후:
```dart
    final now = DateTime.now();
    final todayStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final raw = allDates.map((date) {
      final asset = byDateAsset[date] ?? 0;
      final debt = byDateDebt[date] ?? 0;
      return (date: date, amount: asset - debt);
    }).toList();

    var lastKnown = 0;
    return raw.map((e) {
      if (e.date <= todayStr && e.amount != 0) lastKnown = e.amount;
      if (e.date > todayStr && e.amount == 0 && lastKnown != 0) {
        return (date: e.date, amount: lastKnown);
      }
      return e;
    }).toList();
```

- [ ] **Step 3: 빌드 확인**

```bash
flutter analyze lib/features/dashboard/viewmodels/overview_viewmodel.dart lib/features/dashboard/viewmodels/asset_viewmodel.dart
```

Expected: 오류 없음

- [ ] **Step 4: 전체 테스트 통과 확인**

```bash
flutter test
```

Expected: 기존 통과하던 테스트 모두 PASS (insight_viewmodel_test.dart 3개는 기존부터 실패 중인 pre-existing 이슈)

- [ ] **Step 5: 커밋**

```bash
git add lib/features/dashboard/viewmodels/overview_viewmodel.dart \
        lib/features/dashboard/viewmodels/asset_viewmodel.dart
git commit -m "fix(dashboard): carry forward last known net worth for future zero entries"
```
