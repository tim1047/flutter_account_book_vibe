# 드로어 → 바텀 네비게이션 재구성 — 설계

## 배경

현재 전체 내비게이션은 좌측 드로어(`app_drawer.dart`) 기반이며, 대시보드(`/`)만 내부적으로 `TabController`(개요/지출/자산 3탭)를 갖고 있다 ([dashboard_screen.dart:27-146](../../../lib/features/dashboard/dashboard_screen.dart)).

이를 바텀 네비게이션 4개 + 그룹별 내부 탭 구조로 재구성한다:

1. **가계부 목록** — 기존 `/accountList` 그대로
2. **분석** — 지출/수입/투자 3개 서브탭. 공통 템플릿(총액/카테고리 비중/월별 추이) + 지출 전용 추가 섹션(카테고리 상세/주체별 지출/TOP10)
3. **홈** — 기존 대시보드 개요 탭(`OverviewTab`)
4. **자산** — 현황(기존 `AssetTab`)/목록(기존 `AssetListScreen`) 2개 서브탭

이번 스펙은 신규 셸 구조 추가에 집중한다. 구 드로어 라우트(`/expenseDtl`, `/expense/chart`, `/income/chart`, `/invest/chart`, `/asset/chart`, `/asset/accum`, `/expense/member`)와 `AppDrawer` 자체의 삭제는 다음 단계 작업이며 이번 범위에서 제외한다.

## 목표

- `StatefulShellRoute.indexedStack` 기반 4-브랜치 바텀 네비게이션 셸 도입
- 지출 전용이던 대시보드 분석 로직을 division 파라미터 기반으로 일반화해 수입/투자에도 재사용
- 지출 탭에 주체별 지출 섹션 추가
- 새 4개 화면에서 햄버거 메뉴(드로어) 숨김
- 카테고리 비중/카테고리 상세/주체별 지출 항목 탭 시 필터된 가계부 목록으로 이동

## 비목표

- 구 드로어 라우트/위젯 삭제 (다음 단계)
- 백엔드 API 변경 (모든 관련 API가 이미 `divisionId` 파라미터를 받음 — [division.dart](../../../lib/core/constants/division.dart))
- 카드/차트 등 기존 위젯의 시각 디자인 변경 (배치만 재구성, 스타일은 그대로 재사용)

## 라우팅 아키텍처

`go_router: ^13.2.0`은 `StatefulShellRoute.indexedStack`을 지원한다. 브랜치별로 독립된 `Navigator`를 유지하므로 탭 전환 시 스크롤/서브탭 상태가 보존된다.

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => MainShellScreen(navigationShell: shell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/accountList', ...)]),  // 목록
    StatefulShellBranch(routes: [GoRoute(path: '/analysis', ...)]),     // 분석
    StatefulShellBranch(routes: [GoRoute(path: '/', ...)]),             // 홈
    StatefulShellBranch(routes: [GoRoute(path: '/asset', ...)]),        // 자산
  ],
)
```

- `initialLocation`은 `/` (홈) 유지.
- `/account`, `/myAsset` 폼 라우트는 셸 **밖**(top-level `GoRoute`)에 그대로 둔다 — 어느 브랜치에서 FAB을 눌러도 지금처럼 전체화면으로 push되고, 바텀 네비 바 자체도 덮는 현재 동작을 그대로 재현한다. 셸 안으로 옮기지 않는다.
- `MainShellScreen`은 `Scaffold(bottomNavigationBar: ..., body: navigationShell)` 하나만 담당. 각 브랜치 루트 화면은 지금처럼 **자신의 Scaffold(AppBar 포함)를 계속 소유**한다 — go_router 바텀 네비 예제의 표준 패턴(중첩 Scaffold)이며, `AccountListScreen`/`AssetListScreen`을 Scaffold 없는 형태로 뜯어고칠 필요가 없다. 이전 보고 때 언급한 "Scaffold 탈피"는 자산 화면 한 곳(아래 참고)에만 좁게 적용된다.

### 바텀 네비게이션 아이템

| index | 라벨 | 아이콘(이모지) | 경로 |
|---|---|---|---|
| 0 | 목록 | 📋 | `/accountList` |
| 1 | 분석 | 📊 | `/analysis` |
| 2 | 홈 | 🏠 | `/` |
| 3 | 자산 | 🏢 | `/asset` |

## 화면별 매핑

| 신규 위치 | 기존 소스 | 비고 |
|---|---|---|
| 목록 브랜치 루트 | `AccountListScreen` | 변경 없음. `drawer:` prop만 제거 |
| 분석 브랜치 루트 | 신설 `AnalysisScreen` | 아래 참고 |
| 홈 브랜치 루트 | 신설 `HomeScreen` (구 `DashboardScreen`의 개요 탭 부분 승격) | 아래 참고 |
| 자산 브랜치 루트 | 신설 `AssetHubScreen` | 아래 참고 |

## 분석 브랜치 (`AnalysisScreen`)

구 `DashboardScreen`의 AppBar+PeriodSelector+TabBar+FAB 골격을 유지하되, 탭을 개요/지출/자산 3개에서 지출/수입/투자 3개로 교체한다.

### Division 데이터 일반화

`DashboardExpenseViewModel`/`DashboardExpenseData` ([dashboard/viewmodels/expense_viewmodel.dart](../../../lib/features/dashboard/viewmodels/expense_viewmodel.dart))가 `Division.expense`에 하드코딩돼 있다. 정적 헬퍼 `buildCategoryBreakdown`/`buildCategorySeqBreakdown`/`buildMonthlyTotals`는 이미 division 무관이므로 그대로 재사용 가능. 변경 지점은 division을 주입받는 부분뿐이다.

```dart
class DivisionSummaryData {
  final int totalAmount, prevPeriodAmount;
  final List<({String month, int amount})> monthlyAmounts;
  final List<DivisionCategoryItem> categoryBreakdown;
  final String changeLabel;
  final String? chartHighlightMonth;
}

class DivisionSummaryViewModel extends ChangeNotifier {
  DivisionSummaryViewModel(this.divisionId, this._period);
  final String divisionId; // Division.income / expense / invest
  ...
}
```

- `DashboardSharedViewModel`은 지금 "전체 계정 1회 fetch + 지출 catSum" 조합이라 지출에만 최적화돼 있다 ([dashboard_shared_viewmodel.dart:23-50](../../../lib/features/dashboard/dashboard_shared_viewmodel.dart)). 분석 브랜치에서는 이 shared 패턴을 버리고, `DivisionSummaryViewModel`이 각자 `AccountService.getAccounts(divisionId: ...)` + `CategoryService.getCategorySum(divisionId: ...)`를 독립적으로 호출한다 (지금 `DashboardExpenseViewModel._loadOwn()`이 prev/chart 데이터를 이미 독립 호출하는 것과 동일한 패턴을 current 데이터에도 적용). division 3개 × API 호출이 늘지만 구조가 단순해지고 수입/투자 재사용이 쉬워진다.
- `PeriodSelector`/`DashboardPeriodViewModel`은 분석 브랜치가 자체 인스턴스를 소유 (홈 브랜치와 공유하지 않음 — 각 브랜치가 독립 lifecycle을 갖는 `StatefulShellRoute` 취지에 맞음).

### 지출 탭 전용 확장

`ExpenseSummaryData extends DivisionSummaryData`에 `categorySeqBreakdown`(카테고리 상세), `memberBreakdown`(주체별 지출, `MemberService.getMemberSum` — 이미 division 파라미터를 받음, [expense_viewmodel.dart:47-60](../../../lib/features/expense/expense_viewmodel.dart)), `topTransactions`(TOP10)를 추가. `ExpenseAnalysisTab`은 공통 `DivisionSummaryTab` 콘텐츠(현재 `_ExpenseContent`의 ①~③) 뒤에 ④카테고리 상세 ⑤주체별 지출(신규, `expense_member_screen.dart`의 카드형 리스트를 섹션으로 이식) ⑥TOP10 순으로 붙인다.

수입/투자 탭(`DivisionSummaryTab(divisionId: Division.income/invest)`)은 공통 3섹션만 렌더링.

### 인터랙션

카테고리별 비중 항목, 카테고리 상세 항목, 주체별 지출 항목 탭 시 → `context.push('/accountList', extra: AccountListExtra(...))`. 이 push는 분석 브랜치의 로컬 Navigator에서 일어나므로(별도 브랜치 전환 아님), 오늘 `OverviewTab`이 하는 것과 동일한 방식 — 분석 탭이 선택된 채로 그 위에 필터된 목록이 풀스크린으로 뜨고, 뒤로가기로 복귀한다.

### FAB

구 `DashboardScreen`은 개요/지출/자산 3탭 전체에서 동일한 "거래 추가" FAB(`GradientFAB`, `/account` push)을 공유했다 ([dashboard_screen.dart:129-143](../../../lib/features/dashboard/dashboard_screen.dart)). 분석 브랜치도 이 FAB을 그대로 유지 (지출/수입/투자 서브탭 공통, 조건 분기 없음).

## 홈 브랜치 (`HomeScreen`)

구 `DashboardScreen`에서 `_period`/`_shared`/`_overviewVm`/`_calendarVm` 소유권과 동일한 "거래 추가" FAB을 그대로 옮긴다. `TabController`/`TabBar`는 탭이 1개뿐이므로 제거하고 `OverviewTab`을 바로 렌더링. `AppBar.bottom`도 `PeriodSelector` 하나만 남긴다.

## 자산 브랜치 (`AssetHubScreen`)

내부 `TabController(length: 2)`로 현황/목록 전환. 구 `DashboardScreen`이 `_isAssetTab` bool로 AppBar 높이를 조건 분기하던 패턴을 그대로 차용해, 여기서는 **FAB을 서브탭에 따라 조건 분기**한다 (현황: FAB 없음, 목록: "자산 추가" FAB).

- 현황 서브탭: `AssetTab`(`DashboardAssetViewModel`) 그대로, 무변경.
- 목록 서브탭: `AssetListScreen`에서 `Scaffold`/`MainAppBar`/`AppDrawer`/FAB을 걷어낸 body 콘텐츠만 재사용. 이 화면은 다른 화면의 `TabBarView` 자식으로 들어가야 해서 자체 AppBar를 가질 수 없는 유일한 케이스이므로, 여기서만 "Scaffold 탈피"가 필요하다. `AssetListScreen`의 `ListenableBuilder` 이하 로직(`_vm`, `_onRefresh` 등)을 `AssetListBody` 위젯으로 추출하고, `AssetListScreen`은 당분간(구 라우트 정리 전까지) 이 `AssetListBody`를 감싸는 thin wrapper로 남긴다.

## 드로어 처리

`MainAppBar`([main_app_bar.dart](../../../lib/shared/widgets/main_app_bar.dart))는 지금 `leading`에 햄버거 버튼을 무조건 그리고 `Scaffold.of(ctx).openDrawer()`를 호출한다. 새 4개 브랜치 루트 화면은 `drawer:`를 아예 지정하지 않을 것이므로, `MainAppBar`에 `showMenuButton` 파라미터(기본값 `true`)를 추가해 `false`일 때 `leading`을 `null`로 둔다. 기존 화면(구 라우트들)은 값을 안 넘기면 지금과 동일하게 동작 — 회귀 없음.

`AppDrawer` 위젯 파일 자체는 삭제하지 않는다.

## 에러 처리

기존 각 뷰모델의 `try/catch AppException` + `errorMessage` 패턴을 그대로 유지. `DivisionSummaryViewModel`도 `DashboardExpenseViewModel`과 동일한 로딩/에러 상태 관리 구조를 따른다.

## 테스트

- `DivisionSummaryViewModel.buildCategoryBreakdown`/`buildMonthlyTotals` 등 정적 헬퍼는 division 무관 순수 함수이므로 기존 지출 관련 단위 테스트가 있다면 그대로 통과해야 함 (로직 변경 없음, 호출부만 일반화).
- `MainAppBar(showMenuButton: false)`일 때 `leading`이 렌더되지 않는지 위젯 테스트로 확인.
- 수동 확인: 4개 브랜치 전환 시 스크롤/탭 상태 유지, 분석 3서브탭 각각 로딩/에러/데이터 케이스, 자산 목록 탭에서 FAB으로 자산 추가 → 목록 갱신, 지출 탭 카테고리/주체별 항목 탭 → 필터된 목록 이동 후 back으로 복귀.

## 후속 작업 (이번 범위 제외)

- 구 드로어 라우트(`/expenseDtl`, `/expense/chart`, `/income/chart`, `/invest/chart`, `/asset/chart`, `/asset/accum`, `/expense/member`) 및 대응 화면/뷰모델 삭제
- `AppDrawer` 위젯 삭제
- `app_router.dart`에서 위 라우트 정의 제거
