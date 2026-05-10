# 가계부 앱 디자인 전면 개편 계획

## Context

현재 앱은 Flutter + Material 3 다크 테마 기반으로 기능 구현은 완료된 상태.
기존 에이전트가 소스코드 기반으로 디자인을 분석·개선하다 보니 유사한 결과물이 반복됨.
이번에는 "코드가 아닌 외부 디자인 레퍼런스"에서 출발해 완전히 다른 수준의 비주얼을 목표로 함.

**목표 방향**: 모던 핀테크 스타일 (Toss·Robinhood 계열)
- 딥 다크 배경에 네온/그래디언트 강조색
- 숫자·금액이 주인공인 레이아웃
- 깔끔한 카드 + 마이크로 애니메이션

---

## 접근 방식 결정: 기존 소스 유지 vs 새로 시작

### 결론: 기존 소스 유지 + UI 레이어만 교체

| 항목 | 기존 소스 유지 | 새로 시작 |
|------|--------------|---------|
| 작업 범위 | UI 파일만 수정 (~24개 파일) | 전체 재작성 (~60개+ 파일) |
| 예상 소요 | Stage 4~7만 진행 | Stage 1~7 전부 + 기능 재구현 |
| API 연동 리스크 | 없음 (검증된 코드 그대로) | 높음 (재작성 시 새 버그 발생 가능) |
| 에이전트 실수 가능성 | 낮음 (범위 명확) | 높음 (기능 로직까지 건드릴 수 있음) |
| 디자인 자유도 | 충분함 (테마/위젯 전면 교체 가능) | 동일 (차이 없음) |

### 판단 근거

이 프로젝트는 MVVM 레이어 분리가 명확하게 되어 있음:

```
수정 안 함 (기능 로직)          수정 대상 (UI 레이어)
─────────────────────────────────────────────────
data/models/          ←→      core/constants/app_colors.dart
data/services/        ←→      core/theme/app_theme.dart
features/*/*_viewmodel.dart ←→ features/*/*_screen.dart
shared/viewmodels/    ←→      shared/widgets/*.dart
```

`*_viewmodel.dart`, `*_service.dart`, `*_model.dart` 파일은
이번 작업에서 **단 한 줄도 수정하지 않아도** 디자인 전면 교체가 가능함.

기존 접근에서 디자인이 유사하게 나온 이유는 "에이전트가 기존 코드를 읽고 비슷하게 수정했기 때문"이지,
기존 소스를 유지해서가 아님. Stage 1~3에서 **코드와 무관하게 디자인 스펙을 먼저 확정**하면
기존 코드의 관성 문제를 해결할 수 있음.

### Stage 4~7 에이전트 공통 규칙 (이 규칙을 모든 flutter-expert 에이전트에 전달)

> - `*_viewmodel.dart` 수정 금지
> - `*_service.dart` 수정 금지
> - `*_model.dart` / `*.g.dart` 수정 금지
> - `app_router.dart` 수정 금지
> - UI 파일에서 ViewModel 호출 방식 유지 (ListenableBuilder, ChangeNotifier 패턴 유지)

---

## 핵심 전략

> **기존 접근의 실패 원인**: 에이전트가 현재 코드를 읽고 "유사한 개선"을 반복
>
> **이번 전략**: 외부 디자인 레퍼런스 → 디자인 스펙 문서 → Flutter 구현 지침 → 코드 적용
> 코드를 보기 전에 디자인이 먼저 결정됨

---

## 작업 흐름 (7단계)

---

### Stage 1 — 디자인 레퍼런스 리서치 ✅ 완료 (2026-04-30)
**담당 에이전트**: `voltagent-biz:ux-researcher`

**목적**: 외부 앱에서 구체적인 디자인 언어를 가져오기

**작업 내용**:
- Toss, Robinhood, Revolut, Cash App의 UI 패턴 분석
- 모던 핀테크 다크 앱의 공통 디자인 요소 정리
- 개인 가계부(커플용)에 적합한 감성 요소 식별
- 색상 팔레트 레퍼런스 5가지 후보 제시

**출력물**: `docs/DESIGN_RESEARCH.md` ✅ 생성됨

**Stage 1 핵심 결과 요약**:
- 추천 팔레트: **Palette E "Teal Fusion"** (`#0D1117` 배경 + `#2DD4BF` Teal 강조색)
- 배경 계층: `#0D1117` / `#161B22` / `#21262D` (3단계)
- 강조 그래디언트: `#2DD4BF` → `#818CF8` (Teal to Indigo)
- 의미색: 수입=`#2DD4BF`, 지출=`#F87171`, 투자=`#FB923C`, 순수익=`#4ADE80`, 투자율=`#FACC15`
- 사용자 구분: 강원=`#2DD4BF` (Teal), 정윤=`#F472B6` (Pink)
- 폰트: Pretendard + Tabular Figures 필수
- 아이콘: Material Symbols Outlined, 24px

---

### Stage 2 — 디자인 시스템 설계 ✅ 완료 (2026-04-30)
**담당 에이전트**: `voltagent-core-dev:ui-designer`

**입력**: `docs/DESIGN_RESEARCH.md` + 현재 앱 16개 화면 목록

**목적**: Flutter 구현 가능한 완전한 디자인 스펙 생성

**작업 내용**:
- 색상 팔레트: 배경 2~3단계 + 강조색(그래디언트) + 텍스트 계층
- 타이포그래피 스케일: 금액 표시용 Display체 포함
- 스페이싱 시스템: 4px 기반 그리드
- 컴포넌트 스펙: 카드, 버튼, 배지, 진행률 바, 아코디언
- 주요 화면별 레이아웃 묘사 (홈 대시보드, 거래 목록, 차트 화면)
- 애니메이션 지침: 페이지 전환, 카드 인터랙션

**출력물**: `docs/DESIGN_SYSTEM.md` ✅ 생성됨 (1,451줄)

**Stage 2 핵심 결과 요약**:
- **색상 토큰**: 배경 4단계 + 강조색/의미색/오버레이/배지/사용자 구분 전체 정의
- **타이포그래피**: Pretendard, 15개 스케일 (Display 40px ~ Caption 11px), 금액 전용 6종
- **스페이싱**: 4px 기반 8단계 토큰 + BorderRadius 5종 (radiusFull=100)
- **컴포넌트**: 19개 (AppBar, Drawer, DateFilterBar, SummaryCard, TransactionCard, ProgressRow, AccordionTile, GradientButton, InputField, DropdownField, Badge, FAB, Toast, Dialog 등)
- **차트**: BarChart/LineChart/Stacked BarChart fl_chart 기준 상세 스펙
- **화면 레이아웃**: 7개 주요 화면 ASCII 다이어그램
- **애니메이션**: 7개 상황별 Widget + duration + Curve 수치 확정

---

### Stage 3 — Flutter 구현 가이드 변환 ✅ 완료 (2026-04-30)
**담당 에이전트**: `voltagent-core-dev:design-bridge`

**입력**: `docs/DESIGN_SYSTEM.md` + 현재 테마 파일 경로

**목적**: 디자인 스펙을 Flutter 코드로 변환 가능한 지침서로 전환

**작업 내용**:
- `ThemeData` 전체 설정값 명세
- `AppColors` 상수 목록 (HEX 코드 포함)
- 커스텀 위젯 명세 (글래스카드, 그래디언트 버튼 등)
- 위젯별 구현 가이드 (`summary_card.dart`, `progress_row.dart` 등)

**출력물**: `docs/FLUTTER_DESIGN_GUIDE.md` ✅ 생성됨 (1,484줄)

**Stage 3 핵심 결과 요약**:
- **섹션 1 — app_colors.dart**: 4단계 배경, Teal/Indigo 강조, 텍스트 4계층, 의미색 9개, 오버레이 `Color.fromRGBO`(const 호환), 배지 8종 Bg/Text 쌍, 사용자 3색, 차트 팔레트 3종, 그래디언트 4종, 기존 alias(divisionColor Map 유지) 포함 — **교체 즉시 사용 가능 완성 코드**
- **섹션 2 — app_text_styles.dart (신규)**: 14개 타이포 스케일 + 6개 money* 스타일 (모두 FontFeature.tabularFigures()), Pretendard → NotoSans fallback
- **섹션 3 — app_theme.dart**: ThemeData.dark(useMaterial3:true), primary `#2DD4BF`, AppBar elevation 0, Card elevation 0, InputDecoration radius 16, ExpansionTile 2단 배경, ProgressIndicator 4px — **교체 즉시 사용 가능 완성 코드**
- **섹션 4 — 커스텀 위젯 4종 완성 코드**: `GradientButton`+`DestructiveButton`, `AppBadge`(BadgeType enum 8종), `UserAvatar`(memberIndex 자동), `ThousandsSeparatorInputFormatter`
- **섹션 5 — 기존 위젯 10종 교체 가이드**: 변경 핵심만 정리 (main_app_bar, app_drawer, date_filter_bar, summary_card, progress_row, app_toast, app_dialogs, empty_view 등)
- **섹션 6 — pubspec.yaml**: Pretendard 4 weight 등록, intl/flutter_localizations 추가, google_fonts 제거 권장
- **섹션 7 — 구현 순서 및 주의사항**: Stage 4 10단계 절차, ViewModel/Service/Model 수정 금지, withOpacity const 함정, Flutter Web 600px 제약, flutter analyze 검증

---

### Stage 4 에이전트 전달 사항 (중요)

Stage 4 에이전트(`voltagent-lang:flutter-expert`)에게 반드시 전달할 규칙:

```
입력 파일: docs/FLUTTER_DESIGN_GUIDE.md (섹션 1~7 전체 참조)

수정 대상 파일 (3개):
  - lib/core/constants/app_colors.dart      ← 섹션 1 코드로 완전 교체
  - lib/core/constants/app_text_styles.dart ← 섹션 2 코드로 신규 생성
  - lib/core/theme/app_theme.dart           ← 섹션 3 코드로 완전 교체
  - pubspec.yaml                             ← 섹션 6 변경사항 반영
  - 섹션 4의 커스텀 위젯 4개 신규 생성:
      lib/shared/widgets/gradient_button.dart
      lib/shared/widgets/app_badge.dart
      lib/shared/widgets/user_avatar.dart
      lib/core/utils/thousands_formatter.dart

절대 수정 금지:
  - *_viewmodel.dart, *_service.dart, *_model.dart, app_router.dart

완료 검증:
  flutter analyze        # 오류 0개
  flutter run -d chrome  # 앱 실행 확인
```

---

### Stage 4 — 코어 테마 구현 ✅ 완료 (2026-05-01)
**담당 에이전트**: `voltagent-lang:flutter-expert`

**입력**: `docs/FLUTTER_DESIGN_GUIDE.md`

**수정/생성 파일**:
- `lib/core/constants/app_colors.dart` — Teal Fusion 팔레트 (이미 최신 상태였음)
- `lib/core/constants/app_text_styles.dart` — 신규 생성 (이미 최신 상태였음)
- `lib/core/theme/app_theme.dart` — deprecated `background`/`onBackground` 파라미터 제거 후 교체
- `lib/shared/widgets/gradient_button.dart` — 신규 생성 (이미 최신 상태였음)
- `lib/shared/widgets/app_badge.dart` — 신규 생성 (이미 최신 상태였음)
- `lib/shared/widgets/user_avatar.dart` — **신규 생성** (유일하게 없었던 파일)
- `lib/core/utils/thousands_formatter.dart` — 신규 생성 (이미 최신 상태였음)
- `pubspec.yaml` — intl `^0.18.1`(버전 충돌 해소), flutter_localizations, Pretendard 폰트 등록
- `lib/main.dart` — `initializeDateFormatting('ko_KR')` + localizationsDelegates 추가
- `assets/fonts/` 디렉토리 생성 (ttf 파일은 수동 배치 필요)

**Stage 4 핵심 결과 요약**:
- `flutter analyze` No issues found ✅
- `intl` 버전: SDK 번들 `flutter_localizations`와 충돌 방지를 위해 `^0.18.1` 사용
- `google_fonts` 패키지: 이미 제거된 상태였음
- `ColorScheme.dark(background:, onBackground:)` deprecated 파라미터 제거

**⚠️ Pretendard 폰트 파일 배치 필요**:
- [Pretendard GitHub](https://github.com/orioncactus/pretendard/releases)에서 ttf 4종 다운로드
- 경로: `assets/fonts/Pretendard-Regular.ttf`, `Pretendard-Medium.ttf`, `Pretendard-SemiBold.ttf`, `Pretendard-Bold.ttf`
- 배치 후 `flutter pub get` 재실행

---

### Stage 5 에이전트 전달 사항 (중요)

Stage 5 에이전트(`voltagent-lang:flutter-expert`)에게 반드시 전달할 규칙:

```
입력 파일: docs/FLUTTER_DESIGN_GUIDE.md (섹션 5 중심, 섹션 1~4 참조)

수정 대상 파일 (8개):
  lib/shared/widgets/main_app_bar.dart    ← 섹션 5-1 반영
  lib/shared/widgets/app_drawer.dart      ← 섹션 5-2 반영
  lib/shared/widgets/date_filter_bar.dart ← 섹션 5-3 반영
  lib/shared/widgets/summary_card.dart    ← 섹션 5-4 반영
  lib/shared/widgets/progress_row.dart    ← 섹션 5-5 반영
  lib/shared/widgets/app_toast.dart       ← 섹션 5-6 반영
  lib/shared/widgets/app_dialogs.dart     ← 섹션 5-7 반영
  lib/shared/widgets/empty_view.dart      ← 섹션 5-8 반영

Stage 4에서 생성된 참조 가능 위젯:
  lib/shared/widgets/gradient_button.dart (GradientButton, DestructiveButton)
  lib/shared/widgets/app_badge.dart       (AppBadge, BadgeType enum)
  lib/shared/widgets/user_avatar.dart     (UserAvatar)

절대 수정 금지:
  *_viewmodel.dart, *_service.dart, *_model.dart, app_router.dart

완료 검증:
  flutter analyze   # 오류 0개
  flutter run -d chrome  # 앱 실행 확인
```

---

### Stage 5 — 공통 위젯 재설계 ✅ 완료 (2026-05-01)
**담당 에이전트**: `voltagent-lang:flutter-expert`

**입력**: `docs/FLUTTER_DESIGN_GUIDE.md` + Stage 4 결과물

**수정 파일** (8개):
- `lib/shared/widgets/main_app_bar.dart`
- `lib/shared/widgets/app_drawer.dart`
- `lib/shared/widgets/date_filter_bar.dart`
- `lib/shared/widgets/summary_card.dart`
- `lib/shared/widgets/progress_row.dart`
- `lib/shared/widgets/app_toast.dart`
- `lib/shared/widgets/app_dialogs.dart`
- `lib/shared/widgets/empty_view.dart`

**Stage 5 핵심 결과 요약**:
- `flutter analyze` No issues found ✅
- `main_app_bar.dart`: `colorBgMain` seamless AppBar, elevation 0, `scrolledUnderElevation: 0`, shadowColor/surfaceTintColor transparent
- `app_drawer.dart`: 180px 헤더 + `drawerHeaderOverlay` 그래디언트, 활성 타일 Teal 3px 좌측 인디케이터 + `Color.fromRGBO(45,212,191,0.08)` 배경, `withOpacity` 전부 제거
- `date_filter_bar.dart`: `colorBgSub` 48px 컨테이너, Teal 화살표, `_DropdownContainer(colorBgCard, radius 8)` 드롭다운 래퍼
- `summary_card.dart`: flat `colorBgSub` 카드 (elevation 0), 50×50 원형 아이콘 박스(`colorIconBg*`), `moneyLarge` 금액, `InkWell` 탭 ripple
- `progress_row.dart`: `ClipRRect(radius 100)` + `LinearProgressIndicator(minHeight:4, track:colorProgressTrack)`, deprecated `borderRadius` 파라미터 제거
- `app_toast.dart`: `StatefulWidget` + 단일 `AnimationController` TweenSequence (250ms in → 2000ms hold → 300ms out), `colorBgCard + colorDivider 테두리 + radius 12`
- `app_dialogs.dart`: LoadingDialog `colorLoadingOverlay` barrier + `colorBgSub radius 16` 컨테이너 + 40×40 `colorAccentTeal` 스피너, AlertDialog `colorBgSub` 배경
- `empty_view.dart`: 64px `colorDivider` 아이콘, `textBodyLg + colorTextDisabled` 텍스트

---

### Stage 6 에이전트 전달 사항 (중요)

Stage 6 에이전트 3개(`voltagent-lang:flutter-expert`)에게 반드시 전달할 규칙:

```
입력 파일: docs/FLUTTER_DESIGN_GUIDE.md (전체 참조)

Stage 4~5에서 완성된 참조 위젯:
  lib/core/constants/app_colors.dart       (AppColors.* 전체)
  lib/core/constants/app_text_styles.dart  (AppTextStyles.* 전체)
  lib/shared/widgets/gradient_button.dart  (GradientButton, DestructiveButton)
  lib/shared/widgets/app_badge.dart        (AppBadge, BadgeType enum)
  lib/shared/widgets/user_avatar.dart      (UserAvatar)
  lib/shared/widgets/summary_card.dart     (SummaryCard — 이미 새 스타일)
  lib/shared/widgets/progress_row.dart     (ProgressRow — 이미 새 스타일)
  lib/shared/widgets/app_toast.dart        (AppToast — 이미 새 스타일)
  lib/shared/widgets/app_dialogs.dart      (AppDialogs — 이미 새 스타일)
  lib/shared/widgets/empty_view.dart       (EmptyView — 이미 새 스타일)
  lib/shared/widgets/date_filter_bar.dart  (DateFilterBar — 이미 새 스타일)
  lib/shared/widgets/main_app_bar.dart     (MainAppBar — 이미 새 스타일)
  lib/shared/widgets/app_drawer.dart       (AppDrawer — 이미 새 스타일)

절대 수정 금지:
  *_viewmodel.dart, *_service.dart, *_model.dart, app_router.dart

화면 공통 레이아웃 패턴 (Flutter Web 600px 제약):
  Scaffold
    appBar: MainAppBar(...)
    drawer: AppDrawer(...)
    body: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: [DateFilterBar + 본문 내용],
      ),
    )

완료 검증:
  flutter analyze   # 오류 0개
```

**화면별 디자인 핵심 포인트**:
- 모든 카드: `colorBgSub` 배경, `elevation: 0`, `BorderRadius.circular(12~16)`
- 모든 리스트 타일: `ListTile` tileColor `colorBgSub`, 아이콘 `colorTextSecondary`
- `ExpansionTile`: 펼침=`colorBgCard`, 접힘=`colorBgSub` (theme에서 자동 적용됨)
- 금액 텍스트: 수입=`colorIncome`, 지출=`colorExpense`, 투자=`colorInvest`
- 차트 막대: 일반=`AppColors.barChartGradient`, 현재 달=`AppColors.colorExpense`, 평균=`colorTextSecondary`
- FAB: 추가=56px `colorAccentTeal` 원형, 맨 위로=44px `colorBgCard + colorDivider 테두리`

---

### Stage 6 — 화면별 재설계 (3개 에이전트 병렬)
**담당 에이전트**: `voltagent-lang:flutter-expert` × 3개 동시 실행

**입력**: `docs/FLUTTER_DESIGN_GUIDE.md` + Stage 4~5 결과물

**Agent A — 핵심 화면** ✅ 완료 (2026-05-01):
- `lib/features/home/home_screen.dart` ✅
- `lib/features/account/account_list_screen.dart` ✅
- `lib/features/account/account_form_screen.dart` ✅

**Agent A 핵심 결과 요약**:
- `flutter analyze` No issues found ✅
- 모든 화면에 `Center > ConstrainedBox(maxWidth: 600)` Flutter Web 600px 제약 추가
- `home_screen.dart`: 카드 간격 8px, legacy color alias → canonical token (`colorIncome/Expense/Invest/Profit/Rate`)
- `account_list_screen.dart`: `Card(elevation:0, color:colorBgSub)`, `CircleAvatar` → `UserAvatar`, `_Badge` → `AppBadge(BadgeType.*)`, `_SortToggleBar`/`_DateHeader` 배경 `colorBgSub`, 금액 `moneySmall`, `withOpacity` 완전 제거
- `account_form_screen.dart`: AppBar Teal Fusion 스타일, `GradientButton`+`DestructiveButton` 버튼 교체, `_ThousandsSeparatorFormatter` 로컬 클래스 제거 → `ThousandsSeparatorInputFormatter()` import, `_FormRow` 아이콘/라벨 `colorTextSecondary`

**Agent B — 지출 분석 화면** ✅ 완료 (2026-05-03):
- `lib/features/expense/expense_category_screen.dart` ✅
- `lib/features/expense/expense_dtl_screen.dart` ✅
- `lib/features/expense/expense_member_screen.dart` ✅
- `lib/features/expense/expense_monthly_chart_screen.dart` ✅
- `lib/features/expense/expense_daily_chart_screen.dart` ✅

**Agent B 핵심 결과 요약**:
- 모든 화면에 `Center > ConstrainedBox(maxWidth: 600)` 적용
- `Card(elevation:0, color:colorBgSub)`, `ClipRRect` + `LinearProgressIndicator` deprecated `borderRadius` 제거
- `expense_member_screen.dart`: `CircleAvatar` → `UserAvatar(memberIndex:, imagePath:, name:, size:44)`, `withOpacity` 완전 제거
- `expense_monthly_chart_screen.dart`: 차트 bg=`colorBgCard`, 막대 그래디언트=`barChartGradient`, 현재달=`colorChartCurrent`, 평균=`colorChartAverage`, 그리드=`colorDivider`
- `expense_daily_chart_screen.dart`: `chartLineColors` 팔레트 적용, belowBarData `Color.fromRGBO` (withOpacity 대체), 툴팁=`colorBgCard`

**Agent C — 수입·투자·자산 화면** ✅ 완료 (2026-05-03):
- `lib/features/income/income_category_screen.dart` ✅
- `lib/features/income/income_monthly_chart_screen.dart` ✅
- `lib/features/invest/invest_category_screen.dart` ✅
- `lib/features/invest/invest_monthly_chart_screen.dart` ✅
- `lib/features/asset/asset_list_screen.dart` ✅
- `lib/features/asset/asset_ratio_screen.dart` ✅
- `lib/features/asset/asset_accum_screen.dart` ✅
- `lib/features/asset/my_asset_form_screen.dart` ✅

**Agent C 핵심 결과 요약**:
- 모든 화면에 `Center > ConstrainedBox(maxWidth: 600)` 적용
- `income/invest_category_screen.dart`: `colorIncome` / `colorInvest` 의미색, `ClipRRect` + `LinearProgressIndicator`
- `income/invest_monthly_chart_screen.dart`: 차트 구조 expense 차트와 동일, 색상 구분만 의미색으로 변경
- `asset_list_screen.dart`: 브래킷 오류(floatingActionButton 위치) 수정, 카드 elevation 0, canonical 색상 토큰 전체 적용
- `asset_ratio_screen.dart`: `ClipRRect` 진행률 바, `colorBgSub` 카드
- `asset_accum_screen.dart`: 브래킷 오류 수정 (ConstrainedBox + Center 클로징), 차트 bg=`colorBgCard`, 그리드=`colorDivider`, 툴팁=`colorBgSub`, 상세 카드 elevation 0
- `my_asset_form_screen.dart`: AppBar `colorBgMain` 배경, `GradientButton`+`DestructiveButton` 적용, `ThousandsSeparatorInputFormatter` import (로컬 클래스 제거), `colorDivider`/`colorBgSub`/`colorTextDisabled`/`colorTextSecondary` canonical 토큰 적용

**Stage 6 전체 완료**: `flutter analyze` No issues found ✅

---

### Stage 7 — 통합 점검 및 폴리시 ✅ 완료 (2026-05-05)
**목적**: Stage 6 결과물 시각적 일관성 최종 확보 + 미완성 디테일 보완

**수정 파일**:
- `lib/shared/widgets/error_view.dart` — `AppColors.error` → `AppColors.colorError`
- `lib/features/asset/asset_list_screen.dart` — `textSecondary/textHint/textPrimary/error/income/netIncome/invest/investRate` 전체 canonical 토큰으로 교체
- `lib/features/asset/asset_accum_screen.dart` — `AppColors.income/expense` → `colorIncome/colorExpense`
- `lib/features/expense/expense_monthly_chart_screen.dart` — `AppColors.expense/income/invest` → canonical
- `lib/features/invest/invest_monthly_chart_screen.dart` — `AppColors.invest/income/investRate` → canonical
- `lib/features/income/income_monthly_chart_screen.dart` — `AppColors.income` → `colorIncome`
- `lib/features/account/account_form_screen.dart` — `dropdownColor: AppColors.colorBgCard` 추가
- `lib/features/asset/my_asset_form_screen.dart` — `dropdownColor: AppColors.colorBgCard` 추가

**Stage 7 핵심 결과 요약**:
- `withOpacity()` 잔존 없음 ✅ (Stage 6에서 완전 제거됨)
- `expense_calendar_screen.dart` 미존재 → 스킵 ✅
- legacy alias 전체 제거: `textSecondary/textHint/textPrimary/surface/surfaceVariant/divider/income/expense/invest/netIncome/investRate/error` → 전부 `color*` canonical 토큰으로 완전 교체
- DropdownButton `dropdownColor: colorBgCard` 양쪽 폼 화면 적용
- InputDecoration: Theme 전역 설정(`filled:true, fillColor:colorBgCard, hintStyle:colorTextDisabled, focusedBorder:colorAccentTeal`)이 이미 모든 TextField에 적용 중 — 추가 변경 불필요
- `flutter analyze` **No issues found** ✅

**전체 디자인 개편 완료**: Stage 1~7 모두 완료, `flutter analyze` No issues found

---

## 에이전트 요약

| 순서 | 에이전트 | 병렬 가능 | 출력물 |
|------|---------|---------|-------|
| 1 | `voltagent-biz:ux-researcher` | 단독 | `docs/DESIGN_RESEARCH.md` |
| 2 | `voltagent-core-dev:ui-designer` | 단독 | `docs/DESIGN_SYSTEM.md` |
| 3 | `voltagent-core-dev:design-bridge` | 단독 | `docs/FLUTTER_DESIGN_GUIDE.md` |
| 4 | `voltagent-lang:flutter-expert` | 단독 (선행 필수) | 테마/색상 파일 |
| 5 | `voltagent-lang:flutter-expert` | 단독 (4 이후) | 공통 위젯 8개 |
| 6 | `voltagent-lang:flutter-expert` × 3 | **병렬** (5 이후) | 화면 16개 |
| 7 | `voltagent-lang:flutter-expert` | 단독 (6 이후) | 최종 일관성 |

---

## 검증 방법

각 Stage 완료 후:
```bash
flutter analyze          # 정적 분석 오류 없음 확인
flutter run -d chrome    # 브라우저에서 시각적 확인
```

최종 확인 체크리스트:
- [ ] 홈 대시보드: 금액 카드 5개가 새 디자인으로 표시
- [ ] 거래 목록: 날짜 그룹 헤더 + 카드 새 스타일
- [ ] 지출 분석: 아코디언 + 진행률 바 새 스타일
- [ ] 차트 화면: 배경색/막대색이 새 디자인 반영
- [ ] 드로어: 새 색상/타이포그래피 적용
- [ ] 폼 화면: 입력 필드/버튼 새 스타일
- [ ] 기능 정상 작동: API 연동, CRUD, 네비게이션 모두 이상 없음
