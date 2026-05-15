# 가계부 목록 필터 & 검색 기능 설계

**날짜:** 2026-05-15  
**대상 파일:** `lib/features/account/`

---

## 1. 요구사항 요약

- 가계부 목록 화면(`AccountListScreen`)에 **접기/펼치기 가능한 상세 검색 패널** 추가
- 위치: 기존 `_SortToggleBar`와 같은 레이어에 통합
- 기본 상태: **접힌 상태(collapsed)**. 사용자가 토글하면 펼침.

### 필터 항목 (각 복수 선택 가능)

| 항목 | 설명 |
|------|------|
| 구분 | 수입 / 지출 / 투자 |
| 카테고리 | 로드된 데이터에서 추출한 전체 카테고리 |
| 카테고리 상세 | **카테고리가 선택된 경우에만 표시**. 선택된 카테고리에 속한 상세 항목만 노출 |
| 멤버 | 로드된 데이터에서 추출한 멤버 목록 |

### 텍스트 검색

- 검색 대상 필드: `categoryNm`, `categorySeqNm`, `remark`
- 방식: `contains` (대소문자 무시)
- 적용 타이밍: **입력 즉시 실시간 반영** (debounce 없음)

### 필터 적용 타이밍

- 칩 선택/해제 즉시 실시간 반영 (별도 "적용" 버튼 없음)

---

## 2. 구현 방식 결정

**클라이언트 사이드 필터링** 채택.

- API는 날짜 파라미터(`strtDt`, `endDt`)만 전송
- 기존 서버 단일값 필터 파라미터(`divisionId`, `categoryId`, `categorySeq`, `memberId`) 제거
- 전체 데이터를 메모리에 로드 후 클라이언트에서 필터링
- 필터 옵션 목록은 **별도 API 호출 없이 로드된 데이터에서 추출**

### 선택 이유

- 가계부 특성상 월 단위 데이터가 수십~수백 건 수준 → 메모리 필터링 충분
- 추가 API 호출 없음 → 로딩 상태 관리 단순
- 실제 데이터에 존재하는 값만 필터 옵션으로 노출 (유효하지 않은 선택 방지)

---

## 3. 파일 구조

```
lib/features/account/
  account_list_screen.dart         기존 수정 — _SortToggleBar를 _FilterSortBar로 교체
  account_list_viewmodel.dart      기존 수정 — 필터 상태 및 computed getter 추가
  account_list_filter_state.dart   신규 — 필터 선택 상태 데이터 클래스
  account_list_filter_bar.dart     신규 — 확장형 필터 패널 위젯
  account_list_extra.dart          변경 없음
```

---

## 4. AccountFilterState (신규)

```dart
// lib/features/account/account_list_filter_state.dart

class AccountFilterState {
  const AccountFilterState({
    this.divisionIds = const {},
    this.categoryIds = const {},
    this.categorySeqs = const {},
    this.memberIds = const {},
    this.searchText = '',
  });

  final Set<String> divisionIds;
  final Set<String> categoryIds;
  final Set<String> categorySeqs;
  final Set<String> memberIds;
  final String searchText;

  bool get isActive =>
      divisionIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      categorySeqs.isNotEmpty ||
      memberIds.isNotEmpty ||
      searchText.isNotEmpty;

  // 활성 필터 그룹 수 (토글 바 배지용)
  int get activeCount => [
        divisionIds.isNotEmpty,
        categoryIds.isNotEmpty,
        categorySeqs.isNotEmpty,
        memberIds.isNotEmpty,
        searchText.isNotEmpty,
      ].where((v) => v).length;

  AccountFilterState copyWith({
    Set<String>? divisionIds,
    Set<String>? categoryIds,
    Set<String>? categorySeqs,
    Set<String>? memberIds,
    String? searchText,
  }) => AccountFilterState(
    divisionIds: divisionIds ?? this.divisionIds,
    categoryIds: categoryIds ?? this.categoryIds,
    categorySeqs: categorySeqs ?? this.categorySeqs,
    memberIds: memberIds ?? this.memberIds,
    searchText: searchText ?? this.searchText,
  );

  AccountFilterState get cleared => const AccountFilterState();
}
```

---

## 5. AccountListViewModel 변경

### 추가 필드

```dart
List<AccountListResponse> _rawItems = [];
AccountFilterState filterState = const AccountFilterState();
```

### 기존 단일값 필터 필드 제거

```dart
// 제거: String? divisionId, categoryId, categorySeq, memberId
// 제거: void setFilter(...)
// AccountListExtra 초기 진입 처리는 아래 참고
```

### computed — filteredGrouped

```dart
Map<String, List<AccountListResponse>> get filteredGrouped {
  final state = filterState;
  final filtered = _rawItems.where((item) {
    if (state.divisionIds.isNotEmpty &&
        !state.divisionIds.contains(item.divisionId)) return false;
    if (state.categoryIds.isNotEmpty &&
        !state.categoryIds.contains(item.categoryId)) return false;
    if (state.categorySeqs.isNotEmpty &&
        !state.categorySeqs.contains(item.categorySeq)) return false;
    if (state.memberIds.isNotEmpty &&
        !state.memberIds.contains(item.memberId)) return false;
    if (state.searchText.isNotEmpty) {
      final q = state.searchText.toLowerCase();
      return item.categoryNm.toLowerCase().contains(q) ||
          item.categorySeqNm.toLowerCase().contains(q) ||
          (item.remark ?? '').toLowerCase().contains(q);
    }
    return true;
  });
  return _groupByDate(filtered.toList());
}
```

### computed — 필터 옵션 추출

```dart
List<({String id, String nm})> get availableDivisions =>
    _rawItems.map((e) => (id: e.divisionId, nm: e.divisionNm))
        .toSet().toList();

List<({String id, String nm})> get availableCategories =>
    _rawItems.map((e) => (id: e.categoryId, nm: e.categoryNm))
        .toSet().toList();

// 선택된 카테고리 없으면 빈 리스트 → 패널에서 섹션 숨김
List<({String id, String seq, String nm})> get availableCategorySeqs {
  if (filterState.categoryIds.isEmpty) return [];
  return _rawItems
      .where((e) => filterState.categoryIds.contains(e.categoryId))
      .map((e) => (id: e.categoryId, seq: e.categorySeq, nm: e.categorySeqNm))
      .toSet()
      .toList();
}

List<({String id, String nm})> get availableMembers =>
    _rawItems.map((e) => (id: e.memberId, nm: e.memberNm))
        .toSet().toList();
```

### 필터 업데이트

카테고리 선택 해제 시 해당 카테고리 상세 선택 자동 제거를 `updateFilter` 내부에서 처리:

```dart
void updateFilter(AccountFilterState next) {
  // 카테고리가 변경됐을 때, 선택 해제된 카테고리의 상세 선택 제거
  final removedCategoryIds = filterState.categoryIds.difference(next.categoryIds);
  if (removedCategoryIds.isNotEmpty) {
    final invalidSeqs = _rawItems
        .where((e) => removedCategoryIds.contains(e.categoryId))
        .map((e) => e.categorySeq)
        .toSet();
    final cleanedSeqs = next.categorySeqs.difference(invalidSeqs);
    filterState = next.copyWith(categorySeqs: cleanedSeqs);
  } else {
    filterState = next;
  }
  notifyListeners();
}

void clearFilter() {
  filterState = const AccountFilterState();
  notifyListeners();
}
```

### load() 변경

`load()` 자체는 `filterState`를 건드리지 않음.  
날짜 변경 시 필터 초기화는 **호출부(`_AccountListScreenState`)에서 명시적으로** 처리.

```dart
Future<void> load(String strtDt, String endDt) async {
  isLoading = true;
  errorMessage = null;
  notifyListeners();
  try {
    _rawItems = await AccountService.instance.getAccounts(
      strtDt: strtDt,
      endDt: endDt,
      // 단일값 파라미터 제거됨
    );
  } on AppException catch (e) {
    errorMessage = e.message;
  } finally {
    isLoading = false;
    notifyListeners();
  }
}
```

`_AccountListScreenState._load()`는 날짜 변경 시 필터를 먼저 초기화:

```dart
// DateFilterBar의 onRefresh 콜백 — 날짜 변경 시
void _loadWithReset() {
  _vm.clearFilter();
  _vm.load(_dateFilter.strtDt, _dateFilter.endDt);
}

// 초기 로드 (initState) — 필터 초기화 없이 그대로
void _load() => _vm.load(_dateFilter.strtDt, _dateFilter.endDt);
```

`DateFilterBar(onRefresh: _loadWithReset)`, 초기 `_load()`는 `_loadWithReset` 사용 안 함 → `AccountListExtra` 초기 필터 보존.

### AccountListExtra 초기 진입 처리

`initState()`에서 `setFilter()` 대신 `filterState`를 직접 초기화:

```dart
if (widget.extra != null) {
  final e = widget.extra!;
  _vm.filterState = AccountFilterState(
    divisionIds: e.divisionId != null ? {e.divisionId!} : {},
    categoryIds: e.categoryId != null ? {e.categoryId!} : {},
    categorySeqs: e.categorySeq != null ? {e.categorySeq!} : {},
    memberIds: e.memberId != null ? {e.memberId!} : {},
  );
}
```

---

## 6. _FilterSortBar 위젯 (기존 _SortToggleBar 대체)

### 상태

- `_expanded`: 패널 펼침 여부 (`setState`)
- `_searchController`: `TextEditingController`

### 토글 바 (항상 표시)

```
[ ⚗ 상세 검색  [배지N] ]          [ ↓ 최신순 ]
                          [초기화]  (펼쳐진 경우만)
```

- 필터 활성 시: 아이콘·라벨 색 `colorAccentTeal`, 배지(활성 그룹 수) 표시
- 비활성 시: `colorTextDisabled`
- "초기화" 버튼: 펼쳐진 상태 + `filterState.isActive`일 때만 표시, `colorError`

### 확장 패널 (`AnimatedContainer`)

순서:

1. **텍스트 검색** — `TextField`, `onChanged`에서 즉시 `updateFilter` 호출
2. **구분** — `Wrap` + 필터 칩 (수입/지출/투자)
3. **카테고리** — `Wrap` + 필터 칩
4. **카테고리 상세** — `availableCategorySeqs` 비어있으면 섹션 전체 숨김
5. **멤버** — `UserAvatar` 기반 원형 아바타 토글

### 필터 칩 스타일

| 상태 | 배경 | 텍스트 |
|------|------|--------|
| 미선택 | `colorBgCard` | `colorTextSecondary` |
| 선택됨 (구분) | `divisionColor` 20% 투명 | `divisionColor` |
| 선택됨 (카테고리/상세) | `colorAccentIndigo` 20% 투명 | `colorAccentIndigo` |
| 선택됨 (멤버) | 아바타 테두리 `colorAccentTeal` | — |

---

## 7. grouped → filteredGrouped 참조 교체

`account_list_screen.dart`의 `_buildList()`에서:

```dart
// 변경 전
final sortedDates = _vm.grouped.keys.toList()...
if (_vm.grouped.isEmpty) return const EmptyView();

// 변경 후
final sortedDates = _vm.filteredGrouped.keys.toList()...
if (_vm.filteredGrouped.isEmpty) return const EmptyView();
```

---

## 8. 엣지 케이스

| 상황 | 처리 |
|------|------|
| 날짜 변경 | `_loadWithReset()` 호출 → `clearFilter()` 후 `load()`. 초기 로드는 `_load()`로 필터 보존 |
| 카테고리 선택 해제 | `updateFilter()` 내부에서 해제된 카테고리의 상세 선택 자동 제거 |
| 카테고리 상세 섹션 | `availableCategorySeqs` 빈 배열이면 섹션 숨김 |
| 필터 후 결과 0건 | 기존 `EmptyView` 재사용 |
| AccountListExtra 초기값 | `filterState` 초기화로 변환, 이후 `load()` 시 초기화됨 |
| 텍스트 검색 | debounce 없이 즉시 반영 (`onChanged` 직접 연결) |

---

## 9. AccountService 변경

`getAccounts()`에서 단일값 필터 파라미터 제거:

```dart
// 제거 대상 파라미터
// divisionId, categoryId, categorySeq, memberId
```

---

## 10. 변경이 없는 것

- `AccountListExtra` — 구조 변경 없음
- `AccountService.getAccounts()` 시그니처 — 파라미터 제거만 (하위 호환 불필요, 내부 전용)
- `DateFilterBar` — 변경 없음
- `AppBadge`, `UserAvatar` 등 공유 위젯 — 재사용
- 삭제/수정/추가 플로우 — 변경 없음
