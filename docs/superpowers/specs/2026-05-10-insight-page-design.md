# 인사이트 페이지 설계 스펙

**날짜**: 2026-05-10  
**스코프**: 인사이트 전용 페이지 신규 추가 (백엔드 변경 없음)

---

## 1. 개요

가계부 데이터를 기반으로 "이번 달 주목할 지출 패턴"을 자동으로 도출해 보여주는 전용 페이지.  
기존 API를 그대로 사용하며, 비교·연산은 Flutter 클라이언트에서 수행한다.

### 스코프아웃 항목
- DateFilterBar 기간 선택 모드 (추후 별도 기획)
- 기간별 리포트 페이지 (기존 페이지들로 대체 가능하다고 판단)

---

## 2. 네비게이션

### 라우터 (`app_router.dart`)
```
/insight  →  InsightScreen
```

### 드로어 메뉴 (`app_drawer.dart`)
기존 메뉴 순서에서 `가계부 목록` 바로 아래에 삽입:

```
가계부 홈       (/)
가계부 목록     (/accountList)
💡 인사이트     (/insight)      ← 신규
지출 (아코디언)
수입 (아코디언)
투자 (아코디언)
...
```

---

## 3. 파일 구조

```
lib/features/insight/
├── insight_screen.dart
└── insight_viewmodel.dart
```

기존 `features/home`, `features/expense` 등과 동일한 패턴을 따른다.

---

## 4. 화면 레이아웃

```
AppBar ("인사이트")
DateFilterBar (기존 공용 위젯, 월 단위 선택)
────────────────────────────────────────
ScrollView
  ┌─ 섹션 헤더: "📊 카테고리 이상 감지"
  │   부제목: "최근 3개월 평균 대비"
  │   이상 카드 목록 (증가 → 감소 순)
  │   데이터 없을 때: EmptyView("이번 달은 이상 지출이 없어요 👍")
  │
  ├─ Divider
  │
  └─ 섹션 헤더: "🔍 단일 이상 거래"
      부제목: "카테고리 평균 단가 대비"
      이상 거래 카드 목록 (배수 높은 순)
      데이터 없을 때: EmptyView("이번 달은 이상 거래가 없어요 👍")
```

로딩 중: 기존 `CircularProgressIndicator` 중앙 표시  
에러 시: 기존 `ErrorView` 위젯 재사용

---

## 5. InsightViewModel

### 상태

```dart
bool isLoading
String? errorMessage
List<CategoryAnomalyItem> categoryAnomalies
List<TransactionAnomalyItem> transactionAnomalies
```

### 데이터 fetch 흐름

DateFilterBar에서 연월 변경 시 `load(year, month)` 호출.

**Step 1 — 현재 월 카테고리 합계**
```
GET /category/sum?divisionId=expense&strtDt=YYYY-MM-01&endDt=YYYY-MM-31
```

**Step 2 — 직전 3개월 카테고리 합계** (3회 병렬 호출)
```
GET /category/sum?divisionId=expense&strtDt=...&endDt=...  (M-1)
GET /category/sum?divisionId=expense&strtDt=...&endDt=...  (M-2)
GET /category/sum?divisionId=expense&strtDt=...&endDt=...  (M-3)
```

**Step 3 — 현재 월 거래 목록**
```
GET /account?divisionId=expense&strtDt=YYYY-MM-01&endDt=YYYY-MM-31
```

**Step 4 — 직전 3개월 거래 목록** (3회 병렬 호출, 평균 단가 계산용)
```
GET /account?divisionId=expense&strtDt=...&endDt=...  (M-1, M-2, M-3)
```

Step 1·2·3·4는 모두 병렬로 fetch. 완료 후 클라이언트에서 연산.

### 연산 로직

**카테고리 이상 감지:**
1. 직전 3개월 카테고리별 평균 계산: `avg = (M-1 + M-2 + M-3) / 3`
2. `diff_rate = (현재 - avg) / avg`
3. `|diff_rate| > 0.20` (20%) 조건 만족 시 이상으로 판정
4. 증가(diff_rate > 0): 빨간색 카드
5. 감소(diff_rate < 0): 초록색 카드
6. `|diff_rate|` 내림차순 정렬, 최대 5개 표시

**단일 이상 거래 감지:**
1. 직전 3개월 거래를 카테고리별로 묶어 `평균 단가 = 총 금액 / 건수` 계산
2. 현재 월 각 거래에 대해 `multiple = 거래금액 / 카테고리 평균 단가` 계산
3. `multiple >= 3.0` 조건 만족 시 이상으로 판정
4. `multiple` 내림차순 정렬, 최대 5개 표시
5. 직전 3개월에 해당 카테고리 거래가 없으면 판정 제외

---

## 6. UI 컴포넌트

### CategoryAnomalyCard

```
┌─────────────────────────────────────────────────┐
│ ⚠ 외식비 +42%                    [증가 배지]    │  ← 좌측 border: 빨간색(증가) / 초록색(감소)
│ 이번달 387,000원  ·  평균 272,000원              │
│ ████████████░░░░  +115,000원                    │  ← LinearProgressIndicator
└─────────────────────────────────────────────────┘
```

- 증가: `border-left` 빨간색, 배지 "증가", 배경 어두운 빨간 그라데이션
- 감소: `border-left` 초록색, 배지 "감소", 배경 어두운 초록 그라데이션
- 진행률 바: 현재 금액 / (평균 × 2) 비율로 표시 (200%를 100%로 간주)

### TransactionAnomalyCard

```
┌─────────────────────────────────────────────────┐
│ 외식 · 05.07                       [3.7배 배지] │  ← 좌측 border: 주황색
│ 레스토랑 · 142,000원                             │
│ 카테고리 평균 단가 38,700원                       │
└─────────────────────────────────────────────────┘
```

- 배수 3.0~3.9: 주황색, 4.0~: 빨간색
- 터치 시: 해당 거래 수정 페이지(`/account`)로 이동

---

## 7. 데이터 모델 (로컬)

```dart
class CategoryAnomalyItem {
  final String categoryId;
  final String categoryNm;
  final int currentPrice;
  final int avgPrice;
  final double diffRate;       // 양수: 증가, 음수: 감소
}

class TransactionAnomalyItem {
  final AccountListResponse account;
  final double multiple;       // 평균 단가 대비 배수
  final int categoryAvgPrice;
}
```

---

## 8. 임계값 상수 (`app_config.dart` 또는 `insight_viewmodel.dart` 상단)

```dart
const double kCategoryAnomalyThreshold = 0.20;   // 20% 이상 차이
const double kTransactionAnomalyMultiple = 3.0;   // 평균 단가의 3배 이상
const int kMaxAnomalyItems = 5;                   // 최대 표시 개수
const int kComparisonMonths = 3;                  // 비교 기준 개월 수
```

---

## 9. 엣지 케이스

| 상황 | 처리 |
|------|------|
| 직전 3개월 중 데이터 없는 달 존재 | 있는 달만으로 평균 계산 (0 제외) |
| 직전 3개월 모두 데이터 없음 | 해당 카테고리 이상 감지 제외 |
| 단일 거래만 있는 카테고리 (건수=1) | 평균 = 해당 금액이므로 multiple=1.0, 감지 제외 |
| 현재 월 데이터 없음 | 두 섹션 모두 EmptyView |

---

## 10. 사용 에이전트 계획

모든 작업이 Flutter 코드이므로 `voltagent-lang:flutter-expert` 단일 에이전트로 진행.  
독립적인 작업은 병렬 실행 가능.

| 작업 | 병렬 여부 |
|------|---------|
| InsightViewModel 구현 (상태, fetch, 연산 로직) | 1단계 |
| 카드 컴포넌트 구현 (`CategoryAnomalyCard`, `TransactionAnomalyCard`) | 1단계 (병렬) |
| InsightScreen UI 구현 (viewmodel + 카드 조립) | 2단계 (위 완료 후) |
| 드로어 · 라우터 수정 | 2단계 (병렬) |
