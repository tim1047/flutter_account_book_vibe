# 가계부/자산 카드 통합 (AppListCard) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `_AccountCard`(가계부)와 `_AssetItemTile`(자산)을 공용 위젯 `AppListCard`로 통합해서 두 목록 화면의 카드 디자인(라운드, 마진, 탭 피드백)을 일치시킨다.

**Architecture:** `shared/widgets/app_list_card.dart`에 leading/title/subtitle/badges/trailing 슬롯을 받는 순수 UI 컴포넌트 `AppListCard`를 신설한다. 기존 `_AccountCard`, `_AssetItemTile`은 모델과 비즈니스 로직(가격 계산, 뱃지 조건)을 그대로 유지한 채 `AppListCard`를 감싸는 thin wrapper로 바뀐다. 자산 그룹 섹션의 이중 padding도 함께 정리한다.

**Tech Stack:** Flutter/Dart, `flutter_test` (widget test), 기존 `AppColors`/`AppTextStyles`/`AppBadge`/`UserAvatar` 그대로 재사용.

## Global Constraints

- 카드 시각 스타일은 가계부 쪽으로 통일: `Card` + `InkWell`, `elevation: 0`, `color: AppColors.colorBgSub`, `borderRadius: BorderRadius.circular(12)`, `margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4)`, 내부 `Padding: EdgeInsets.all(12)`.
- outer `Row`는 `crossAxisAlignment.center` 하나로 통일 (leading/trailing 둘 다 title+subtitle+badges 전체 블록 기준 세로 중앙 정렬).
- `AppListCard`는 모델을 몰라야 한다 (순수 UI 컴포넌트). 가격 계산/뱃지 조건 등 로직은 wrapper(`_AccountCard`, `_AssetItemTile`) 안에 남는다.
- 표시 항목(콘텐츠) 추가/삭제 없음 — 리팩터링만.
- Dart 파일 import는 `package:account_book_vibe/...` 형태의 절대 경로 사용 (기존 코드 컨벤션).

---

## File Structure

- Create: `lib/shared/widgets/app_list_card.dart` — 공용 카드 컴포넌트.
- Create: `test/shared/widgets/app_list_card_test.dart` — 위 컴포넌트의 위젯 테스트.
- Modify: `lib/features/account/account_list_screen.dart` — `_AccountCard.build()`를 `AppListCard` 사용으로 교체.
- Modify: `lib/features/asset/asset_list_screen.dart` — `_AssetItemTile.build()`를 `AppListCard` 사용으로 교체, `_AssetGroupSection`/`_AssetSubGroupSection`의 아이템 리스트 padding 조정.

---

### Task 1: `AppListCard` 공용 위젯 생성

**Files:**
- Create: `lib/shared/widgets/app_list_card.dart`
- Test: `test/shared/widgets/app_list_card_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class AppListCard extends StatelessWidget {
    const AppListCard({
      super.key,
      this.leading,
      required this.title,
      this.subtitle,
      this.badges = const [],
      this.trailing,
      required this.onTap,
      this.onLongPress,
    });

    final Widget? leading;
    final Widget title;
    final Widget? subtitle;
    final List<Widget> badges;
    final Widget? trailing;
    final VoidCallback onTap;
    final VoidCallback? onLongPress;
  }
  ```
  Task 2와 Task 3이 이 시그니처를 그대로 소비한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`test/shared/widgets/app_list_card_test.dart` 새로 생성:

```dart
import 'package:account_book_vibe/shared/widgets/app_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('leading/subtitle/badges/trailing 없이도 title만으로 렌더된다', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목만'),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('제목만'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leading이 주어지면 렌더된다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          leading: const Icon(Icons.person),
          title: const Text('제목'),
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('trailing이 주어지면 title 옆에 렌더된다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목'),
          trailing: const Text('10,000원'),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('10,000원'), findsOneWidget);
  });

  testWidgets('badges가 비어있으면 Wrap을 렌더하지 않는다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목'),
          onTap: () {},
        ),
      ),
    );

    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets('badges가 있으면 Wrap 안에 렌더된다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목'),
          badges: const [Text('뱃지1'), Text('뱃지2')],
          onTap: () {},
        ),
      ),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.text('뱃지1'), findsOneWidget);
    expect(find.text('뱃지2'), findsOneWidget);
  });

  testWidgets('onTap과 onLongPress가 호출된다', (tester) async {
    var tapped = false;
    var longPressed = false;

    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목'),
          onTap: () => tapped = true,
          onLongPress: () => longPressed = true,
        ),
      ),
    );

    await tester.tap(find.byType(AppListCard));
    expect(tapped, isTrue);

    await tester.longPress(find.byType(AppListCard));
    expect(longPressed, isTrue);
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/shared/widgets/app_list_card_test.dart`
Expected: FAIL — `app_list_card.dart`가 없어서 컴파일 에러 (`Target of URI doesn't exist`).

- [ ] **Step 3: `AppListCard` 구현**

`lib/shared/widgets/app_list_card.dart` 새로 생성:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 가계부/자산 목록에서 공용으로 쓰는 리스트 카드.
///
/// leading(아바타/아이콘), title, subtitle, badges, trailing 슬롯으로
/// 내용을 주입받는 순수 UI 컴포넌트. 모델이나 비즈니스 로직은 모른다.
class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.badges = const [],
    this.trailing,
    required this.onTap,
    this.onLongPress,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final List<Widget> badges;
  final Widget? trailing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: AppColors.colorBgSub,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: title),
                        if (trailing != null) ...[
                          const SizedBox(width: 12),
                          trailing!,
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      subtitle!,
                    ],
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: badges,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 테스트 실행해서 통과 확인**

Run: `flutter test test/shared/widgets/app_list_card_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: 커밋**

```bash
git add lib/shared/widgets/app_list_card.dart test/shared/widgets/app_list_card_test.dart
git commit -m "feat(shared): add AppListCard shared list card widget"
```

---

### Task 2: `_AccountCard`를 `AppListCard`로 리팩터링

**Files:**
- Modify: `lib/features/account/account_list_screen.dart:241-376` (`_AccountCard` 클래스)

**Interfaces:**
- Consumes: `AppListCard({leading, required title, subtitle, badges, trailing, required onTap, onLongPress})` (Task 1에서 생성)

- [ ] **Step 1: import 추가**

`lib/features/account/account_list_screen.dart` 상단 import 목록에 추가 (알파벳 순서 유지):

```dart
import 'package:account_book_vibe/shared/widgets/app_list_card.dart';
```

- [ ] **Step 2: `_AccountCard.build()`를 `AppListCard` 사용으로 교체**

기존 (`account_list_screen.dart:267-306`):

```dart
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: AppColors.colorBgSub,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                memberIndex: _memberIndex,
                imagePath: _memberImagePath,
                name: item.memberNm,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceRow(),
                    const SizedBox(height: 4),
                    _buildCategoryRow(),
                    const SizedBox(height: 6),
                    _buildBadgeRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

교체 후:

```dart
  @override
  Widget build(BuildContext context) {
    return AppListCard(
      leading: UserAvatar(
        memberIndex: _memberIndex,
        imagePath: _memberImagePath,
        name: item.memberNm,
        size: 44,
      ),
      title: _buildPriceRow(),
      subtitle: _buildCategoryRow(),
      badges: _buildBadgeList(),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
```

- [ ] **Step 3: `_buildBadgeRow()`를 `_buildBadgeList()`로 변경 (Wrap 제거, List 반환)**

기존 (`account_list_screen.dart:347-362`):

```dart
  Widget _buildBadgeRow() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (_isSeoulLove)
          const AppBadge(type: BadgeType.seoulLove, label: '서울사랑'),
        if (_isFirstMeeting)
          const AppBadge(type: BadgeType.firstMeeting, label: '첫만남'),
        if (_hasPoint) const AppBadge(type: BadgeType.point, label: '포인트'),
        if (item.impulseYn == 'Y')
          const AppBadge(type: BadgeType.impulse, label: '충동'),
        _buildDivisionBadge(),
      ],
    );
  }
```

교체 후 (`Wrap`은 `AppListCard`가 이미 담당하므로 리스트만 반환):

```dart
  List<Widget> _buildBadgeList() {
    return [
      if (_isSeoulLove)
        const AppBadge(type: BadgeType.seoulLove, label: '서울사랑'),
      if (_isFirstMeeting)
        const AppBadge(type: BadgeType.firstMeeting, label: '첫만남'),
      if (_hasPoint) const AppBadge(type: BadgeType.point, label: '포인트'),
      if (item.impulseYn == 'Y')
        const AppBadge(type: BadgeType.impulse, label: '충동'),
      _buildDivisionBadge(),
    ];
  }
```

- [ ] **Step 4: 정적 분석 + 전체 테스트 실행**

Run: `flutter analyze lib/features/account/account_list_screen.dart`
Expected: `No issues found!`

Run: `flutter test`
Expected: 기존 테스트 전부 PASS (회귀 없음)

- [ ] **Step 5: 커밋**

```bash
git add lib/features/account/account_list_screen.dart
git commit -m "refactor(account): use shared AppListCard for account card"
```

---

### Task 3: `_AssetItemTile`을 `AppListCard`로 리팩터링

**Files:**
- Modify: `lib/features/asset/asset_list_screen.dart:375-454` (`_AssetItemTile` 클래스)

**Interfaces:**
- Consumes: `AppListCard({leading, required title, subtitle, badges, trailing, required onTap, onLongPress})` (Task 1)

- [ ] **Step 1: import 추가**

`lib/features/asset/asset_list_screen.dart` 상단 import 목록에 추가:

```dart
import 'package:account_book_vibe/shared/widgets/app_list_card.dart';
```

- [ ] **Step 2: `_AssetItemTile.build()`를 `AppListCard` 사용으로 교체**

기존 (`asset_list_screen.dart:381-453`):

```dart
  @override
  Widget build(BuildContext context) {
    final isCashable = item.cashableYn == 'Y';
    final qtyStr = item.qty == item.qty.roundToDouble()
        ? item.qty.toInt().toString()
        : item.qty.toStringAsFixed(4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.colorBgSub,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.myAssetNm,
                          style: AppTextStyles.textTitleMd.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isCashable)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(250, 204, 21, 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '현금성',
                            style: AppTextStyles.textLabelSm.copyWith(
                              color: AppColors.colorRate,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$qtyStr개',
                    style: AppTextStyles.textBodyMd.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${FormatUtil.formatPrice(item.sumPrice)}원',
              style: AppTextStyles.moneySmall,
            ),
          ],
        ),
      ),
    );
  }
```

교체 후:

```dart
  @override
  Widget build(BuildContext context) {
    final isCashable = item.cashableYn == 'Y';
    final qtyStr = item.qty == item.qty.roundToDouble()
        ? item.qty.toInt().toString()
        : item.qty.toStringAsFixed(4);

    return AppListCard(
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.myAssetNm,
              style: AppTextStyles.textTitleMd.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isCashable)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(250, 204, 21, 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '현금성',
                style: AppTextStyles.textLabelSm.copyWith(
                  color: AppColors.colorRate,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '$qtyStr개',
        style: AppTextStyles.textBodyMd.copyWith(
          color: AppColors.colorTextSecondary,
        ),
      ),
      trailing: Text(
        '${FormatUtil.formatPrice(item.sumPrice)}원',
        style: AppTextStyles.moneySmall,
      ),
      onTap: onTap,
    );
  }
```

- [ ] **Step 3: 정적 분석 실행**

Run: `flutter analyze lib/features/asset/asset_list_screen.dart`
Expected: `No issues found!` (아직 `_AssetGroupSection`의 padding은 안 건드렸으니 이 시점엔 인셋이 16+12=28px로 겹쳐 있음 — Task 4에서 정리)

- [ ] **Step 4: 커밋**

```bash
git add lib/features/asset/asset_list_screen.dart
git commit -m "refactor(asset): use shared AppListCard for asset item tile"
```

---

### Task 4: 자산 그룹 섹션 padding 겹침 정리

**Files:**
- Modify: `lib/features/asset/asset_list_screen.dart:271-371` (`_AssetGroupSection`, `_AssetSubGroupSection`)

**Interfaces:**
- Consumes: 없음 (레이아웃 padding 조정만)

- [ ] **Step 1: `_AssetGroupSection.build()`에서 헤더에만 horizontal 16을 남기고, 아이템 리스트는 `AppListCard`의 margin h12만 인셋으로 쓰게 분리**

기존 (`asset_list_screen.dart:280-316`):

```dart
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  group.assetNm,
                  style: AppTextStyles.textHeadlineSm,
                ),
                const Spacer(),
                Text(
                  '${FormatUtil.formatPrice(group.assetTotSumPrice)}원',
                  style: AppTextStyles.textBodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorAccentTeal,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          ...group.items.map(
            (item) => _AssetItemTile(item: item, onTap: () => onEdit(item)),
          ),
          ...group.subGroups.map(
            (sub) => _AssetSubGroupSection(subGroup: sub, onEdit: onEdit),
          ),
        ],
      ),
    );
  }
```

교체 후 (바깥 `Padding`의 `horizontal: 16`을 제거해서 `vertical: 4`만 남기고, 그 16을 헤더 `Row`의 `Padding`으로 옮긴다. 아이템/서브그룹 목록은 이 Column 레벨에서 좌우 padding을 전혀 받지 않는다):

```dart
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  group.assetNm,
                  style: AppTextStyles.textHeadlineSm,
                ),
                const Spacer(),
                Text(
                  '${FormatUtil.formatPrice(group.assetTotSumPrice)}원',
                  style: AppTextStyles.textBodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorAccentTeal,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          ...group.items.map(
            (item) => _AssetItemTile(item: item, onTap: () => onEdit(item)),
          ),
          ...group.subGroups.map(
            (sub) => _AssetSubGroupSection(subGroup: sub, onEdit: onEdit),
          ),
        ],
      ),
    );
  }
```

이렇게 하면 `_AssetItemTile`(→ `AppListCard`)은 자기 `margin: symmetric(h12, v4)`만으로 좌우 인셋을 만들어서 가계부 카드(12px)와 동일해진다. 헤더 텍스트의 상하 여백(위/아래 4+8=12)은 원본과 동일하게 유지된다.

- [ ] **Step 2: `_AssetSubGroupSection`의 `ExpansionTile` 타이틀(폴더 아이콘+서브그룹명) 인셋은 16으로 유지**

서브그룹 타이틀 행(폴더 아이콘, 서브그룹명, 합계금액)은 아이템 카드가 아니라 그룹 헤더와 같은 역할이라, Step 1에서 제거한 16px 인셋을 잃으면 안 된다. `tilePadding`을 2 → 16으로 올려서 보정한다.

기존 (`asset_list_screen.dart:332-337`):

```dart
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 2),
        childrenPadding: EdgeInsets.zero,
        minTileHeight: 36,
```

교체 후:

```dart
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.zero,
        minTileHeight: 36,
```

`childrenPadding: EdgeInsets.zero`는 그대로 둔다 — 서브그룹 안의 `_AssetItemTile`들도 그룹 직속 아이템과 마찬가지로 `AppListCard`의 margin h12만 인셋으로 쓰게 된다.

- [ ] **Step 3: 정적 분석 실행**

Run: `flutter analyze lib/features/asset/asset_list_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: 전체 테스트 실행**

Run: `flutter test`
Expected: 전부 PASS

- [ ] **Step 5: 커밋**

```bash
git add lib/features/asset/asset_list_screen.dart
git commit -m "fix(asset): remove double horizontal padding around asset item cards"
```

---

### Task 5: 최종 검증

**Files:** 없음 (검증만)

**Interfaces:** 없음

- [ ] **Step 1: 전체 정적 분석**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: 전체 테스트 스위트 실행**

Run: `flutter test`
Expected: 전부 PASS

- [ ] **Step 3: 실제 화면 확인 (가능한 경우)**

`run` 스킬 또는 `flutter run`으로 앱을 띄워서 가계부 목록/자산 목록 화면을 열고 다음을 눈으로 확인:
- 두 화면 카드의 radius/margin/탭 ripple이 동일하게 보이는지
- 가계부 카드: 아바타, 가격(포인트 있는 항목 포함), 카테고리, 뱃지들이 전부 그대로 보이는지
- 자산 카드: 자산명, 현금성 뱃지, 수량, 합계금액이 전부 그대로 보이는지, 그룹 헤더와 카드 좌우 인셋이 가계부와 비슷하게 맞는지

에뮬레이터/시뮬레이터를 이 환경에서 띄울 수 없다면, 이 단계는 사람이 직접 확인해야 함을 보고서에 명시한다.

- [ ] **Step 4: 최종 커밋 (필요 시)**

검증 중 발견된 사소한 수정이 있다면 커밋:

```bash
git add -A
git commit -m "fix: address visual issues found during final verification"
```

(문제 없으면 이 단계는 생략)
