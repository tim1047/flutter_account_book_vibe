# Asset Tab — 기간별 자산 현황 섹션 추가

## 목표

`asset_tab.dart`의 순자산 추이 라인차트 아래에 **기간별 자산 현황 & 증감률** 섹션을 추가한다.
`asset_accum_screen.dart`의 카드 패턴을 dashboard tab 안으로 가져오되, 별도 API 호출 없이 기존 period picker를 공유한다.

## 레이아웃

### asset_tab 전체 섹션 순서 (변경 후)

```
① 순자산 Hero 카드          (기존)
② 자산 구성 도넛             (기존)
③ 순자산 추이 라인차트        (기존, period picker 포함)
④ 기간별 자산 현황            ← 신규 (period picker 공유, 별도 UI 없음)
⑤ 부채 현황                  (기존, 부채 > 0일 때만)
```

### ④ 섹션 내부 구조

`_SectionCard(title: '기간별 자산 현황')` 안에 full-width 카드 세로 스택:

1. **순자산 카드** (`_NetWorthHistoryCard`)
2. **자산별 카드** × N (`_AssetHistoryCard`) — 자산 등록 순서

각 카드 행 레이아웃:
```
날짜(고정폭)  |  ₩금액(flex)  |  +증감액  |  (+증감%)
```

- 첫 번째 행은 증감 없음 (─ 표시)
- 증감 양수 → `AppColors.colorIncome` (기존 accum_screen 패턴 동일)
- 증감 음수 → `AppColors.colorExpense`

### 숫자 형식

`₩520,000,000` — `FormatUtil.formatPrice()` + `₩` prefix. `원` suffix 없음.

## 데이터 흐름

### 추가 API 호출: 없음

`DashboardAssetViewModel.load()`에서 이미 `sumHistory`를 fetch한다.
`_buildNetWorthHistory(sumHistory)`와 동일한 데이터를 재처리해 자산별 히스토리를 추출한다.

### `DashboardAssetData` 변경

```dart
// 기존
final List<({String date, int amount})> netWorthHistory;

// 추가
final List<String> assetHistoryNames;   // 자산 표시 순서
final List<({String date, Map<String, int> byAsset})> assetHistory;
```

### 신규 빌더 메서드 (`DashboardAssetViewModel`)

```dart
static ({
  List<String> names,
  List<({String date, Map<String, int> byAsset})> history,
}) _buildAssetHistory(List<MyAssetSumResponse> sums) {
  // assetId != '0', assetId != '6' 필터
  // accumDt 기준 정렬
  // 자산명 순서 보존 (첫 등장 순)
}
```

`DashboardAssetData` 생성 시 `_buildAssetHistory(sumHistory)` 결과를 주입.

## UI 컴포넌트 (`asset_tab.dart`)

### 신규 위젯

| 위젯 | 역할 |
|------|------|
| `_AssetHistorySection` | `_NetWorthHistoryCard` + `_AssetHistoryCard` 리스트 조합 |
| `_NetWorthHistoryCard` | `data.netWorthHistory` 렌더링 |
| `_AssetHistoryCard` | 자산명 + `data.assetHistory` 중 해당 자산 행 렌더링 |

`_AssetHistorySection`은 `_AssetContent._buildChildren()`에서 `_SectionCard` 안에 감싸 추가.

### 카드 헤더 색상 dot

- 순자산 카드: `AppColors.colorTextPrimary` (흰색 dot) — accum_screen `_TotalAssetDetailCard` 동일
- 자산별 카드: `AppColors.assetChartColors[index % length]` — accum_screen `_AssetDetailCard` 동일

## 변경 파일 목록

| 파일 | 변경 유형 |
|------|-----------|
| `lib/features/dashboard/viewmodels/asset_viewmodel.dart` | 수정 |
| `lib/features/dashboard/tabs/asset_tab.dart` | 수정 |

## 비변경 파일

- `asset_accum_screen.dart` — 독립 화면, 건드리지 않음
- `asset_accum_viewmodel.dart` — 재사용하지 않음
- `my_asset_service.dart` — API 변경 없음

## 엣지 케이스

| 케이스 | 처리 |
|--------|------|
| `assetHistory` 비어있음 | `_AssetHistorySection` 렌더링 스킵 |
| 자산 수 0 | `_AssetHistorySection` 렌더링 스킵 |
| 기간 변경 시 | 기존 `selectHistoryPeriod` / `selectCustomYears` 호출 → `load()` 재실행 → `notifyListeners()` → 자동 갱신 |
| 증감 계산 불가 (이전 값 0) | 증감/% 칸 ─ 표시 |
