# Asset Tab 기간별 자산 현황 섹션 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `asset_tab.dart`의 순자산 추이 라인차트 아래에 기간별 자산 현황(순자산 + 자산별) 카드를 추가한다.

**Architecture:** `DashboardAssetViewModel`이 이미 fetch한 `sumHistory` 응답을 재처리해 `assetHistoryNames`와 `assetHistory` 필드를 `DashboardAssetData`에 추가한다. API 추가 호출 없음. UI는 `_AssetHistorySection` (순자산 + 자산별 full-width 카드) 를 `_AssetContent` ListView에 삽입한다. 기간 picker는 기존 것을 그대로 공유한다.

**Tech Stack:** Flutter, Dart, ChangeNotifier, `AppColors`, `FormatUtil`, `MyAssetSumResponse`

---

## File Map

| 파일 | 변경 유형 | 담당 |
|------|-----------|------|
| `lib/features/dashboard/viewmodels/asset_viewmodel.dart` | 수정 | 데이터 모델 + 빌더 |
| `lib/features/dashboard/tabs/asset_tab.dart` | 수정 | UI 위젯 |
| `test/features/dashboard/asset_viewmodel_test.dart` | 수정 | 빌더 단위 테스트 |

---

## Task 1: DashboardAssetData 확장 + buildAssetHistory 빌더

**Files:**
- Modify: `lib/features/dashboard/viewmodels/asset_viewmodel.dart`
- Modify: `test/features/dashboard/asset_viewmodel_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

`test/features/dashboard/asset_viewmodel_test.dart` 파일 끝 `main()` 중괄호 닫기 전에 다음 group 추가:

```dart
  group('DashboardAssetViewModel.buildAssetHistory', () {
    test('assetId 0과 6은 필터링됨', () {
      final sums = [
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '0', assetNm: '합계', sumPrice: 300),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '6', assetNm: '부채', sumPrice: 50),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '1', assetNm: '주식', sumPrice: 100),
      ];
      final result = DashboardAssetViewModel.buildAssetHistory(sums);
      expect(result.names, ['주식']);
      expect(result.history.length, 1);
      expect(result.history.first.byAsset.containsKey('합계'), false);
      expect(result.history.first.byAsset.containsKey('부채'), false);
    });

    test('자산명 순서는 첫 등장 순 유지', () {
      final sums = [
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '1', assetNm: '주식', sumPrice: 100),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '2', assetNm: '예금', sumPrice: 200),
        const MyAssetSumResponse(
            accumDt: '20250201', assetId: '2', assetNm: '예금', sumPrice: 210),
        const MyAssetSumResponse(
            accumDt: '20250201', assetId: '1', assetNm: '주식', sumPrice: 110),
      ];
      final result = DashboardAssetViewModel.buildAssetHistory(sums);
      expect(result.names, ['주식', '예금']);
    });

    test('날짜별 byAsset 그룹핑 + 날짜 정렬', () {
      final sums = [
        const MyAssetSumResponse(
            accumDt: '20250201', assetId: '1', assetNm: '주식', sumPrice: 150),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '1', assetNm: '주식', sumPrice: 100),
        const MyAssetSumResponse(
            accumDt: '20250101', assetId: '2', assetNm: '예금', sumPrice: 200),
      ];
      final result = DashboardAssetViewModel.buildAssetHistory(sums);
      expect(result.history.length, 2);
      expect(result.history[0].date, '20250101');
      expect(result.history[0].byAsset['주식'], 100);
      expect(result.history[0].byAsset['예금'], 200);
      expect(result.history[1].date, '20250201');
      expect(result.history[1].byAsset['주식'], 150);
    });

    test('빈 입력 → 빈 결과', () {
      final result = DashboardAssetViewModel.buildAssetHistory([]);
      expect(result.names, isEmpty);
      expect(result.history, isEmpty);
    });
  });
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
cd /Users/kangwonseo/Desktop/workspace/flutter_account_book_vibe
flutter test test/features/dashboard/asset_viewmodel_test.dart
```

Expected: `buildAssetHistory` 없다는 컴파일 오류 또는 `NoSuchMethodError`

- [ ] **Step 3: DashboardAssetData 필드 추가**

`lib/features/dashboard/viewmodels/asset_viewmodel.dart`의 `DashboardAssetData` 클래스를 아래와 같이 수정:

```dart
class DashboardAssetData {
  const DashboardAssetData({
    required this.totalAsset,
    required this.netWorth,
    required this.prevYearNetWorth,
    required this.assetComposition,
    required this.netWorthHistory,
    required this.assetHistoryNames,
    required this.assetHistory,
  });

  final int totalAsset;
  final int netWorth;
  final int prevYearNetWorth;
  final List<AssetCompositionItem> assetComposition;
  final List<({String date, int amount})> netWorthHistory;
  final List<String> assetHistoryNames;
  final List<({String date, Map<String, int> byAsset})> assetHistory;

  int get debt => totalAsset - netWorth;
  int get yearlyGrowth => netWorth - prevYearNetWorth;
}
```

- [ ] **Step 4: buildAssetHistory 정적 메서드 추가**

`DashboardAssetViewModel` 클래스 안, `_sumAssets` 위에 추가:

```dart
  static ({
    List<String> names,
    List<({String date, Map<String, int> byAsset})> history,
  }) buildAssetHistory(List<MyAssetSumResponse> sums) {
    final filtered =
        sums.where((s) => s.assetId != '0' && s.assetId != '6').toList();

    final names = <String>[];
    for (final s in filtered) {
      if (!names.contains(s.assetNm)) names.add(s.assetNm);
    }

    final dates = filtered.map((s) => s.accumDt).toSet().toList()..sort();

    final history = dates.map((date) {
      final byAsset = <String, int>{};
      for (final s in filtered.where((s) => s.accumDt == date)) {
        byAsset[s.assetNm] = s.sumPrice;
      }
      return (date: date, byAsset: byAsset);
    }).toList();

    return (names: names, history: history);
  }
```

- [ ] **Step 5: load()의 DashboardAssetData 생성 부분 수정**

`load()` 메서드 안, `data = DashboardAssetData(...)` 블록을 아래로 교체:

```dart
      final assetHist = buildAssetHistory(sumHistory);

      data = DashboardAssetData(
        totalAsset: totalAsset,
        netWorth: netWorth,
        prevYearNetWorth: prevYearNetWorth,
        assetComposition: _buildComposition(todaySum),
        netWorthHistory: _buildNetWorthHistory(sumHistory),
        assetHistoryNames: assetHist.names,
        assetHistory: assetHist.history,
      );
```

- [ ] **Step 6: 테스트 통과 확인**

```bash
flutter test test/features/dashboard/asset_viewmodel_test.dart
```

Expected: 전체 통과 (기존 테스트 + 신규 4개)

- [ ] **Step 7: 정적 분석 확인**

```bash
flutter analyze lib/features/dashboard/viewmodels/asset_viewmodel.dart
```

Expected: `No issues found!`

- [ ] **Step 8: 커밋**

```bash
git add lib/features/dashboard/viewmodels/asset_viewmodel.dart \
        test/features/dashboard/asset_viewmodel_test.dart
git commit -m "feat(asset-vm): add assetHistory fields and buildAssetHistory builder"
```

---

## Task 2: _AssetHistorySection UI 위젯 추가

**Files:**
- Modify: `lib/features/dashboard/tabs/asset_tab.dart`

- [ ] **Step 1: 파일 끝에 _HistoryRow 헬퍼 클래스 추가**

`asset_tab.dart` 파일 맨 끝에 추가:

```dart
// ── Asset History Section ─────────────────────────────────────────────────────

class _AssetHistorySection extends StatelessWidget {
  const _AssetHistorySection({required this.data});

  final DashboardAssetData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HistoryCard(
          label: '순자산',
          dotColor: AppColors.colorTextPrimary,
          rows: _buildNetWorthRows(data.netWorthHistory),
        ),
        ...data.assetHistoryNames.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _HistoryCard(
              label: e.value,
              dotColor: AppColors.assetChartColors[
                  e.key % AppColors.assetChartColors.length],
              rows: _buildAssetRows(e.value, data.assetHistory),
            ),
          ),
        ),
      ],
    );
  }

  List<_HistoryRowData> _buildNetWorthRows(
    List<({String date, int amount})> history,
  ) {
    final rows = <_HistoryRowData>[];
    for (int i = 0; i < history.length; i++) {
      final entry = history[i];
      int? change;
      double? pct;
      if (i > 0) {
        final prev = history[i - 1].amount;
        if (prev > 0) {
          change = entry.amount - prev;
          pct = change / prev * 100;
        } else if (entry.amount == 0) {
          change = 0;
          pct = 0.0;
        }
      }
      rows.add(_HistoryRowData(
          date: entry.date, amount: entry.amount, change: change, pct: pct));
    }
    return rows;
  }

  List<_HistoryRowData> _buildAssetRows(
    String assetNm,
    List<({String date, Map<String, int> byAsset})> history,
  ) {
    final rows = <_HistoryRowData>[];
    for (int i = 0; i < history.length; i++) {
      final entry = history[i];
      final amount = entry.byAsset[assetNm] ?? 0;
      int? change;
      double? pct;
      if (i > 0) {
        final prev = history[i - 1].byAsset[assetNm] ?? 0;
        if (prev > 0) {
          change = amount - prev;
          pct = change / prev * 100;
        } else if (amount == 0) {
          change = 0;
          pct = 0.0;
        }
      }
      rows.add(_HistoryRowData(
          date: entry.date, amount: amount, change: change, pct: pct));
    }
    return rows;
  }
}

class _HistoryRowData {
  const _HistoryRowData({
    required this.date,
    required this.amount,
    this.change,
    this.pct,
  });

  final String date;
  final int amount;
  final int? change;
  final double? pct;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.label,
    required this.dotColor,
    required this.rows,
  });

  final String label;
  final Color dotColor;
  final List<_HistoryRowData> rows;

  String _fmtDt(String dt) {
    if (dt.length < 8) return dt;
    return '${dt.substring(0, 4)}.${dt.substring(4, 6)}.${dt.substring(6)}';
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      color: AppColors.colorBgSub,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.colorTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.colorDivider),
            ...rows.map(_buildRow),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_HistoryRowData row) {
    final isPositive = (row.change ?? 0) >= 0;
    final changeColor =
        isPositive ? AppColors.colorIncome : AppColors.colorExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              _fmtDt(row.date),
              style: const TextStyle(
                color: AppColors.colorTextSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '₩${FormatUtil.formatPrice(row.amount)}',
              style: const TextStyle(
                color: AppColors.colorTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (row.change != null && row.pct != null) ...[
            Text(
              '${isPositive ? '+' : ''}₩${FormatUtil.formatPrice(row.change!)}',
              style: TextStyle(color: changeColor, fontSize: 11),
            ),
            const SizedBox(width: 4),
            Text(
              '(${isPositive ? '+' : ''}${row.pct!.toStringAsFixed(1)}%)',
              style: TextStyle(color: changeColor, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: _AssetContent에 섹션 삽입**

`_AssetContent.build()` 안 `ListView` children 리스트에서 `if (data.debt > 0)` 블록 **바로 앞**에 추가:

```dart
        // ④ 기간별 자산 현황
        if (data.assetHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: '기간별 자산 현황',
            child: _AssetHistorySection(data: data),
          ),
        ],
```

전체 `ListView` children은 이렇게 됨:

```dart
      children: [
        _AssetHeroCard(data: data),
        const SizedBox(height: 12),
        _SectionCard(
          title: '자산 구성',
          child: _AssetDonutSection(data: data),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '순자산 추이',
          trailing: _HistoryPeriodPicker(vm: vm),
          child: NetWorthLineChart(
            history: data.netWorthHistory,
            height: 140,
          ),
        ),
        // ④ 기간별 자산 현황 (신규)
        if (data.assetHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: '기간별 자산 현황',
            child: _AssetHistorySection(data: data),
          ),
        ],
        if (data.debt > 0) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: '부채 현황',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 부채',
                  style: AppTextStyles.textBodySm.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                Text(
                  '-₩ ${FormatUtil.formatPrice(data.debt)}',
                  style: AppTextStyles.textBodyMd.copyWith(
                    color: AppColors.colorExpense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
```

- [ ] **Step 3: 정적 분석**

```bash
flutter analyze lib/features/dashboard/tabs/asset_tab.dart
```

Expected: `No issues found!`

- [ ] **Step 4: 전체 테스트**

```bash
flutter test
```

Expected: 전체 통과

- [ ] **Step 5: 커밋**

```bash
git add lib/features/dashboard/tabs/asset_tab.dart
git commit -m "feat(asset-tab): add 기간별 자산 현황 section below net worth chart"
```
