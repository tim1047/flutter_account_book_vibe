# 가계부/자산 카드 통합 (AppListCard) — 설계

## 배경

가계부 목록(`AccountListScreen`)과 자산 목록(`AssetListScreen`)이 각각 다른 카드 위젯을 씀:

- `_AccountCard` ([account_list_screen.dart:241](../../../lib/features/account/account_list_screen.dart)) — `Card` + `InkWell`, radius 12, margin `symmetric(h12, v4)`, 탭 시 ripple 있음.
- `_AssetItemTile` ([asset_list_screen.dart:375](../../../lib/features/asset/asset_list_screen.dart)) — `GestureDetector` + `Container`, radius 10, margin `bottom: 6`만, 탭 시 ripple 없음.

두 위젯이 서로 다른 스타일로 발전해서 디자인 일관성이 떨어짐. 공용 카드 위젯 하나로 통합.

## 목표

- `shared/widgets/app_list_card.dart`에 순수 UI 컴포넌트 `AppListCard` 신설.
- `_AccountCard`, `_AssetItemTile`을 `AppListCard`를 감싸는 thin wrapper로 리팩터링. 기존 모델(`AccountListResponse`, `MyAssetItemResponse`)과 비즈니스 로직(가격 계산, 뱃지 조건 등)은 그대로 유지.
- 시각 스타일은 가계부 쪽(`Card`+`InkWell`, radius 12, margin `symmetric(h12, v4)`, elevation 0, color `colorBgSub`)으로 통일.

## 비목표

- 카드 콘텐츠(표시 항목) 자체의 변경/추가 없음 — 순수 리팩터링.
- 다른 화면(대시보드 등)의 카드는 범위 밖.

## AppListCard 컴포넌트

```dart
class AppListCard extends StatelessWidget {
  const AppListCard({
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

### 레이아웃

```
Card(margin: symmetric(h12, v4), elevation: 0, color: colorBgSub)
  InkWell(borderRadius: circular(12), onTap, onLongPress)
    Padding(all(12))
      Row(crossAxisAlignment: center)
        leading?                      // null이면 렌더 안 함, 공백도 없음
        SizedBox(width: 12)           // leading 있을 때만
        Expanded(
          Column(crossAxisAlignment: start)
            Row(children: [Expanded(title), trailing?])
            SizedBox(height:4) + subtitle?
            SizedBox(height:6) + Wrap(badges)   // badges.isNotEmpty일 때만
        )
```

- outer `Row`는 `crossAxisAlignment.center` 하나로 통일. leading(아바타)과 trailing(자산 금액)이 둘 다 title+subtitle+badges 전체 블록 높이 기준 세로 중앙 정렬됨.
  - 가계부: 아바타가 기존 `start`(위쪽 정렬)에서 `center`로 바뀜 — 콘텐츠가 3줄(가격/카테고리/뱃지)이라 아바타(44px)보다 길어서 아바타가 지금보다 살짝 아래로 이동. 허용된 변화.
  - 자산: `trailing`(합계 금액)이 title+subtitle 전체 높이 기준 중앙 정렬 — 기존 동작과 동일하게 유지됨.
- `title` 옆 `trailing`은 `Row` 안에서 title과 나란히 배치하되, 전체를 감싸는 outer Row의 center 정렬 덕분에 시각적으로 2줄 블록 중앙에 위치.

## 화면별 매핑

### `_AccountCard` (가계부)

| 슬롯 | 내용 |
|---|---|
| `leading` | `UserAvatar(memberIndex, imagePath, name, size: 44)` |
| `title` | `_buildPriceRow()` (포인트 있으면 strikethrough + 할인가, 없으면 단일가) |
| `subtitle` | `_buildCategoryRow()` (categoryNm/categorySeqNm/remark) |
| `badges` | `_buildBadgeRow()`의 children (seoulLove/firstMeeting/point/impulse/division 뱃지) |
| `trailing` | 미사용 (null) |

기존 로직(`_pricePrefix`, `_divisionColor`, `_memberIndex`, `_hasPoint`, `_isSeoulLove`, `_isFirstMeeting`, `_buildDivisionBadge`, `_FallbackBadge`)은 wrapper 내부에 그대로 남고 결과 위젯만 슬롯에 전달.

### `_AssetItemTile` (자산)

| 슬롯 | 내용 |
|---|---|
| `leading` | 미사용 (null) |
| `title` | `Row[Expanded(Text(myAssetNm)), if (isCashable) 현금성뱃지]` |
| `subtitle` | qty 텍스트 (`'$qtyStr개'`) |
| `badges` | 미사용 (빈 리스트) |
| `trailing` | `Text('${sumPrice}원', style: moneySmall)` |

기존 로직(`isCashable`, `qtyStr` 계산)은 wrapper 내부 유지.

## 자산 그룹 섹션 padding 조정

현재 `_AssetGroupSection`/`_AssetSubGroupSection`이 아이템 리스트에 좌우 padding 16을 이미 깔고 있고, `_AssetItemTile`은 margin bottom 6만 씀. `AppListCard`의 margin h12를 그대로 적용하면 16+12=28px로 가계부(12px)보다 인셋이 커짐.

- 그룹 헤더(자산 그룹명 + 합계금액 표시 줄)는 기존 padding 16 유지.
- 아이템 리스트(`group.items.map(...)`, `subGroup.items.map(...)`) 부분만 별도로 padding 0 컨테이너로 감싸서, `AppListCard`의 margin h12가 유일한 좌우 인셋이 되게 함. 결과적으로 가계부와 동일한 12px 인셋.

## 데이터 흐름

`AppListCard`는 모델을 모르는 순수 UI 컴포넌트. `_AccountCard`/`_AssetItemTile`이 각자 모델(`AccountListResponse`/`MyAssetItemResponse`)을 받아 내부에서 위젯을 조립한 뒤 슬롯에 전달하는 구조는 유지.

## 에러 처리

해당 없음 — 순수 표시용 위젯. 데이터 로딩/에러는 상위 화면(`AccountListScreen`/`AssetListScreen`)에서 기존 방식대로 처리.

## 테스트

- 위젯 테스트: `AppListCard`가 leading null / trailing null / badges 빈 리스트 케이스에서 레이아웃 깨지지 않는지 확인.
- 기존 `_AccountCard`, `_AssetItemTile` 관련 골든/위젯 테스트가 있다면 리팩터링 후에도 통과하는지 확인 (표시 내용 동일해야 함).
