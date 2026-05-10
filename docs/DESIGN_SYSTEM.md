# 강원 정윤 가계부 — 디자인 시스템 스펙

**버전**: 1.0  
**작성일**: 2026-04-30  
**팔레트**: Palette E "Teal Fusion"  
**대상**: Flutter Web (Stage 3 구현 가이드, Stage 4~6 코딩의 직접 참조 문서)

---

## 목차

1. [색상 시스템 (Color System)](#1-색상-시스템)
2. [타이포그래피 (Typography)](#2-타이포그래피)
3. [스페이싱 & 그리드 (Spacing)](#3-스페이싱--그리드)
4. [컴포넌트 스펙 (Components)](#4-컴포넌트-스펙)
5. [차트 스펙 (Charts)](#5-차트-스펙)
6. [화면별 레이아웃 (Screens)](#6-화면별-레이아웃)
7. [애니메이션 지침 (Animation)](#7-애니메이션-지침)
8. [공통 UX 패턴 (UX Patterns)](#8-공통-ux-패턴)

---

## 1. 색상 시스템

### 1-1. 배경 계층 토큰 (Background Layers)

배경은 반드시 3단계 계층 구조를 준수한다. 그림자(elevation/shadow) 없이 배경색 차이만으로 깊이감을 표현한다.

| 토큰명 | HEX | 사용처 |
|--------|-----|--------|
| `colorBgMain` | `#0D1117` | 앱 최상위 Scaffold 배경, AppBar 배경 |
| `colorBgSub` | `#161B22` | 카드 배경, Drawer 배경, DateFilterBar 배경, SummaryCard |
| `colorBgCard` | `#21262D` | 카드 위 인터랙티브 요소, InputField 배경, DropdownField 팝업 배경, AccordionTile 펼침 영역 |
| `colorBgElevated` | `#30363D` | 최상위 팝업 배경, Tooltip 배경, 선택된 메뉴 아이템 배경 |

### 1-2. 강조색 토큰 (Accent Colors)

강조색(Teal)은 CTA 버튼, 수입 표시, 활성 상태에만 제한적으로 사용한다. 남용 시 강조 효과가 희석된다.

| 토큰명 | HEX | 사용처 |
|--------|-----|--------|
| `colorAccentTeal` | `#2DD4BF` | GradientButton 시작점, 수입 표시, 포커스 테두리, FAB 배경, DateFilterBar 화살표, Drawer 활성 아이템 텍스트, LineChart 사용자1 |
| `colorAccentIndigo` | `#818CF8` | GradientButton 끝점, Drawer 아코디언 헤더 아이콘, 보조 강조 |
| `colorGradientStart` | `#2DD4BF` | 그래디언트 시작 (LinearGradient) |
| `colorGradientEnd` | `#818CF8` | 그래디언트 끝 (LinearGradient) |

**그래디언트 정의** (Flutter 코드):
```
LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF2DD4BF), Color(0xFF818CF8)],
)
```

### 1-3. 텍스트 계층 토큰 (Text Colors)

| 토큰명 | HEX | 사용처 |
|--------|-----|--------|
| `colorTextPrimary` | `#E6EDF3` | 메인 텍스트, 금액 숫자, 카드 제목 |
| `colorTextSecondary` | `#8B949E` | 보조 설명, 날짜, 카테고리 부제목, 비활성 아이콘 |
| `colorTextDisabled` | `#484F58` | 비활성 입력 필드 텍스트, EmptyView 텍스트 |
| `colorDivider` | `#30363D` | Divider, 테두리 기본값, ProgressBar 트랙 배경 |

### 1-4. 의미론적 색상 (Semantic Colors)

앱 전반에서 의미를 가진 색상. 동일 의미에는 반드시 동일 색상을 사용한다.

| 토큰명 | HEX | 의미 | 사용처 |
|--------|-----|------|--------|
| `colorIncome` | `#2DD4BF` | 수입/소득 | 소득 배지, ProgressBar 채움, 소득 카드 아이콘 배경 |
| `colorExpense` | `#F87171` | 지출 | 지출 배지, ProgressBar 채움, 지출 카드 아이콘 배경, 현재 달 BarChart 막대 |
| `colorInvest` | `#FB923C` | 투자 | 투자 배지, ProgressBar 채움, 투자 카드 아이콘 배경 |
| `colorProfit` | `#4ADE80` | 순수익 | 순수익 카드 아이콘 배경, 긍정 수치 표시 |
| `colorRate` | `#FACC15` | 투자율 | 투자율 카드 아이콘 배경, 고정지출 배지 |
| `colorSuccess` | `#4ADE80` | 성공/완료 | Toast 성공 아이콘, 검증 통과 상태 |
| `colorError` | `#F87171` | 오류/경고 | Toast 오류 아이콘, DestructiveButton, AlertDialog 오류 표시 |
| `colorWarning` | `#FACC15` | 경고 | 주의 메시지, 충동지출 배지 |
| `colorInfo` | `#818CF8` | 정보 | 정보 Toast, 힌트 텍스트 |

### 1-5. 오버레이 & 상태 색상 (Overlay & State Colors)

Flutter에서 `withOpacity()` 또는 `Color.fromRGBO()`로 구현한다.

| 토큰명 | 값 | 사용처 |
|--------|-----|--------|
| `colorHoverTeal` | `rgba(45, 212, 191, 0.10)` | InkWell splashColor, 카드 hover 상태 |
| `colorPressedTeal` | `rgba(45, 212, 191, 0.05)` | InkWell highlightColor |
| `colorDisabledOverlay` | `rgba(72, 79, 88, 0.40)` | 비활성 버튼 오버레이 |
| `colorProgressTrack` | `rgba(255, 255, 255, 0.08)` | ProgressBar 트랙 (배경) |
| `colorIconBgIncome` | `rgba(45, 212, 191, 0.15)` | 소득 아이콘 원형 배경 |
| `colorIconBgExpense` | `rgba(248, 113, 113, 0.15)` | 지출 아이콘 원형 배경 |
| `colorIconBgInvest` | `rgba(251, 146, 60, 0.15)` | 투자 아이콘 원형 배경 |
| `colorIconBgProfit` | `rgba(74, 222, 128, 0.15)` | 순수익 아이콘 원형 배경 |
| `colorIconBgRate` | `rgba(250, 204, 21, 0.15)` | 투자율 아이콘 원형 배경 |
| `colorLoadingOverlay` | `rgba(13, 17, 23, 0.85)` | LoadingDialog 전체 오버레이 |

### 1-6. 배지 색상 시스템 (Badge Colors)

한국 특화 결제수단 배지 포함 전체 배지 스펙. 배경은 불투명 다크 색상, 텍스트는 밝은 색상으로 대비를 확보한다.

| 배지 종류 | 배경 HEX | 텍스트 HEX | 표시 조건 |
|----------|----------|-----------|---------|
| 소득 | `rgba(45, 212, 191, 0.20)` | `#2DD4BF` | 거래 구분 = 소득 |
| 지출 | `rgba(248, 113, 113, 0.20)` | `#F87171` | 거래 구분 = 지출 |
| 투자 | `rgba(251, 146, 60, 0.20)` | `#FB923C` | 거래 구분 = 투자 |
| 서울사랑 | `#1F2937` | `#E6EDF3` | 서울사랑상품권 결제 |
| 첫만남 | `#312E81` | `#A5B4FC` | 첫만남이용권 결제 |
| 포인트 | `#92400E` | `#FCD34D` | 포인트 차감 내역 있을 때 |
| 충동 | `#4C1D95` | `#C4B5FD` | 충동지출 여부 = Y |
| 고정지출 | `#713F12` | `#FDE68A` | 고정지출 여부 = Y |

### 1-7. 사용자 구분 색상 (User Identity Colors)

커플/가족 공동 가계부이므로 사용자별 시각적 구분이 필수다. 사용자 아바타, 차트 라인, ProgressBar에 일관 적용한다.

| 사용자 | 토큰명 | HEX | 적용 위치 |
|--------|--------|-----|---------|
| 강원 (사용자1) | `colorUser1` | `#2DD4BF` | CircleAvatar 테두리, 주체별 ProgressBar, 일별 차트 라인 |
| 정윤 (사용자2) | `colorUser2` | `#F472B6` | CircleAvatar 테두리, 주체별 ProgressBar, 일별 차트 라인 |
| 추가 사용자3 | `colorUser3` | `#FB923C` | CircleAvatar 테두리, 주체별 ProgressBar, 일별 차트 라인 |

### 1-8. 차트 색상 팔레트 (Chart Color Palettes)

#### BarChart (월별 추이) 막대 색상
| 역할 | 색상 |
|------|------|
| 일반 달 막대 (그래디언트) | `#2DD4BF` → `#818CF8` (하→상 LinearGradient) |
| 현재 달 막대 (단색 강조) | `#F87171` |
| 평균 막대 (단색) | `#30363D` |
| 차트 배경 | `#0D1117` |
| 차트 영역 배경 | `#161B22` |
| GridLine | `rgba(255, 255, 255, 0.05)` |
| 축 레이블 텍스트 | `#8B949E` |

#### LineChart (일별 추이) 라인 색상
| 역할 | 색상 |
|------|------|
| 사용자1 라인 | `#2DD4BF` |
| 사용자1 Fill | `rgba(45, 212, 191, 0.10)` |
| 사용자2 라인 | `#F472B6` |
| 사용자2 Fill | `rgba(244, 114, 182, 0.10)` |
| 사용자3 라인 | `#FB923C` |
| 사용자3 Fill | `rgba(251, 146, 60, 0.10)` |
| 차트 배경 (Gradient) | `#0D1117` → `#161B22` (상→하) |
| Tooltip 배경 | `#21262D` |
| Dot 색상 | 각 라인 색상과 동일 |

#### Stacked BarChart (자산 누적) 자산 종류별 색상
순서는 서버에서 내려오는 자산 종류 인덱스 기준으로 순환 적용한다.

| 인덱스 | HEX | 색상명 |
|--------|-----|--------|
| 1번 | `#818CF8` | Indigo |
| 2번 | `#F472B6` | Pink |
| 3번 | `#2DD4BF` | Teal |
| 4번 | `#4ADE80` | Green |
| 5번 | `#F87171` | Red |
| 6번 | `#E6EDF3` | White |
| 7번 | `#FB923C` | Orange |
| 8번 | `#FACC15` | Yellow |

---

## 2. 타이포그래피

### 2-1. 폰트 패밀리

```
Primary Font  : Pretendard (한국어 최적화, Variable Weight 지원)
Fallback      : -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif
Monospace     : 'Pretendard'에 fontFeatures Tabular Figures 적용 (금액 숫자)
```

Flutter 설정:
```dart
fontFamily: 'Pretendard',
fontFeatures: [FontFeature.tabularFigures()],  // 금액 숫자에 필수
```

pubspec.yaml에 Pretendard 폰트 등록 필요. 미등록 시 Noto Sans KR을 fallback으로 사용한다.

### 2-2. 타이포그래피 스케일

| 레벨 | 토큰명 | fontSize | fontWeight | lineHeight | letterSpacing | 사용처 |
|------|--------|----------|------------|-----------|---------------|--------|
| Display Large | `textDisplayLg` | 40px | w700 | 1.2 | -0.5 | 대시보드 메인 금액 (향후 확장용) |
| Display Medium | `textDisplayMd` | 32px | w700 | 1.25 | -0.3 | SummaryCard 금액 |
| Headline Large | `textHeadlineLg` | 24px | w600 | 1.3 | -0.2 | 페이지 제목 |
| Headline Medium | `textHeadlineMd` | 20px | w600 | 1.35 | -0.1 | AppBar 제목, 섹션 제목 |
| Headline Small | `textHeadlineSm` | 18px | w600 | 1.4 | 0 | AlertDialog 제목, 카드 제목 |
| Title Large | `textTitleLg` | 17px | w600 | 1.4 | 0 | 그룹 헤더, 아코디언 헤더 |
| Title Medium | `textTitleMd` | 16px | w500 | 1.5 | 0 | InputField 텍스트, 거래 금액 |
| Title Small | `textTitleSm` | 15px | w500 | 1.5 | 0 | 버튼 텍스트 |
| Body Large | `textBodyLg` | 16px | w400 | 1.6 | 0 | 폼 설명, AlertDialog 내용 |
| Body Medium | `textBodyMd` | 14px | w400 | 1.6 | 0 | 일반 본문, 메뉴 아이템 |
| Body Small | `textBodySm` | 13px | w400 | 1.6 | 0 | 카드 부제목, 카테고리명 |
| Label Medium | `textLabelMd` | 14px | w600 | 1.4 | 0 | DateFilterBar 텍스트, 날짜 헤더 |
| Label Small | `textLabelSm` | 13px | w500 | 1.4 | 0 | FloatingLabel, 입력 필드 레이블 |
| Caption | `textCaption` | 11px | w400 | 1.4 | 0.2 | 차트 축 레이블, 비율 표시 |

### 2-3. 금액 표시 전용 스타일

금액 숫자는 반드시 `fontFeatures: [FontFeature.tabularFigures()]`를 적용하여 자릿수 변경 시 레이아웃 밀림을 방지한다.

| 스타일명 | fontSize | fontWeight | color | 적용처 |
|---------|----------|------------|-------|--------|
| `moneyDisplay` | 40px | w700 | `#E6EDF3` | 대시보드 대형 금액 |
| `moneyLarge` | 32px | w700 | `#E6EDF3` | SummaryCard 금액 |
| `moneyMedium` | 20px | w600 | `#E6EDF3` | 자산 목록 금액 |
| `moneySmall` | 18px | w600 | `#E6EDF3` | TransactionCard 금액 |
| `moneyStrikethrough` | 16px | w400 | `#484F58` | 포인트 적용 전 원래 금액 (취소선) |
| `moneyUnit` | 14px | w500 | `#8B949E` | "원", "%" 단위 텍스트 |

**단위 분리 원칙**: 금액 숫자와 "원"/"%" 단위는 별도 Text 위젯으로 분리하여 크기와 색상을 다르게 표시한다.

```
┌ 금액 숫자 (moneyLarge, #E6EDF3) ─ "5,280,000"
└ 단위 텍스트 (moneyUnit, #8B949E) ─ "원"
```

### 2-4. 한국어 텍스트 처리

- 날짜: `"YYYY.MM.DD (요일)"` 형식 — DateFormat('yyyy.MM.dd (E)', 'ko_KR')
- 연월 필터: `"YYYY년"`, `"MM월"`, `"전체"` — DateFilterBar 드롭다운 레이블
- 금액: `NumberFormat("#,##0", "ko_KR").format(amount)` — 천단위 콤마
- 비율: `"${value.toStringAsFixed(1)}%"` — 소수점 1자리

---

## 3. 스페이싱 & 그리드

### 3-1. 기본 스페이싱 토큰 (4px 기반)

| 토큰명 | 값 | 사용처 |
|--------|----|----|
| `spacing2` | 2px | 미세 간격, 배지 내부 수직 패딩 |
| `spacing4` | 4px | 배지 내부 패딩, 아이콘-텍스트 간격 |
| `spacing8` | 8px | 카드 간 간격, 버튼 내부 아이콘-텍스트 간격 |
| `spacing12` | 12px | TransactionCard 내부 패딩 (수직), Toast 패딩 (수직) |
| `spacing16` | 16px | 화면 좌우 패딩, 메뉴 아이템 수평 패딩, InputField 내부 패딩 |
| `spacing20` | 20px | SummaryCard 내부 패딩, 폼 상하 패딩 |
| `spacing24` | 24px | 섹션 간 간격, AccordionTile 하위 들여쓰기 |
| `spacing32` | 32px | LoadingDialog 내부 패딩, Toast 하단 위치 offset |

### 3-2. 레이아웃 그리드

| 항목 | 값 | 비고 |
|------|----|----|
| 화면 좌우 패딩 | 16px | 모든 화면 공통 |
| 카드 내부 패딩 수직 | 16px | TransactionCard, ProgressRow |
| 카드 내부 패딩 수평 | 20px | SummaryCard |
| 카드 간 간격 | 8px | ListView itemExtent 기준 |
| 날짜 그룹 헤더 상단 패딩 | 16px | DateGroupHeader |
| 날짜 그룹 헤더 하단 패딩 | 8px | DateGroupHeader |
| 섹션 간 간격 | 24px | 차트 화면 섹션 분리 |

### 3-3. BorderRadius 토큰

| 토큰명 | 값 | 사용처 |
|--------|----|----|
| `radius4` | 4px | Badge, BarChart 막대 상단 |
| `radius8` | 8px | DateFilterBar 버튼, 소형 버튼 |
| `radius12` | 12px | TransactionCard, AccordionTile, AlertDialog, Toast, DropdownField 팝업, FAB 배경 컨테이너 |
| `radius16` | 16px | SummaryCard, GradientButton, OutlinedButton, DestructiveButton, InputField, AlertDialog, LoadingDialog 컨테이너 |
| `radiusFull` | 100px | ProgressBar, CircleAvatar, FAB 추가 버튼 |

---

## 4. 컴포넌트 스펙

---

### 4-1. AppBar

**Flutter Widget**: `AppBar` (PreferredSizeWidget)

```
┌─────────────────────────────────────────┐  height: 56px
│ ☰   강원 정윤 가계부                     │
└─────────────────────────────────────────┘
```

| 속성 | 값 |
|------|-----|
| 배경색 | `#0D1117` (colorBgMain — 화면 배경과 seamless) |
| 높이 | 56px (toolbarHeight) |
| 제목 | "강원 🧡 정윤 가계부" |
| 제목 스타일 | textHeadlineMd (20px w600), 색상 `#E6EDF3` |
| 햄버거 아이콘 | Icons.menu, 색상 `#8B949E`, 크기 24px |
| 하단 구분선 | 없음 (elevation: 0, 배경과 동일) |
| 스크롤 동작 | pinned (항상 표시) |

**상태 정의**:
- Default: 위 스펙 그대로
- 드로어 열린 상태: 앱바 변화 없음 (오버레이 방식)

---

### 4-2. Drawer (사이드 네비게이션)

**Flutter Widget**: `Drawer` + `DrawerHeader` + `ListView`

```
┌────────────────────┐
│  [가족 사진 배경]    │  height: 180px, BoxFit.cover
│  + 그래디언트 오버레이│
├────────────────────┤
│  ▣  가계부 홈        │  ← 활성 아이템 (Teal 텍스트 + 좌측 인디케이터)
│  ≡  가계부 목록      │
│  ▼  지출           │  ← 아코디언 헤더 (Indigo 아이콘)
│     └ 지출          │  ← 하위 메뉴 (24px 들여쓰기)
│     └ 지출 상세      │
│     └ 주체별 지출    │
│     └ 지출 추이      │
│     └ 일별 지출 추이  │
│  ▼  수입           │
│  ▼  투자           │
│  📅 CALENDAR 보기  │
│  ▼  자산           │
└────────────────────┘
```

| 속성 | 값 |
|------|-----|
| Drawer 배경 | `#161B22` |
| Drawer 너비 | 280px (Flutter 기본값 유지) |

**DrawerHeader**:
| 속성 | 값 |
|------|-----|
| 높이 | 180px |
| 배경 이미지 | `assets/images/family.png`, BoxFit.cover |
| 그래디언트 오버레이 | `rgba(13,17,23,0)` → `rgba(13,17,23,0.7)` (상→하) |

**메뉴 아이템 (비활성)**:
| 속성 | 값 |
|------|-----|
| 높이 | 48px |
| 수평 패딩 | 16px |
| 아이콘 색상 | `#8B949E` |
| 텍스트 색상 | `#8B949E` |
| 텍스트 스타일 | textBodyMd (14px w400) |
| 탭 피드백 | InkWell, splashColor `colorHoverTeal` |

**메뉴 아이템 (활성)**:
| 속성 | 값 |
|------|-----|
| 텍스트 색상 | `#2DD4BF` |
| 아이콘 색상 | `#2DD4BF` |
| 좌측 인디케이터 | 3px 너비, 높이 24px, 색상 `#2DD4BF`, BorderRadius 2px |
| 배경 | `rgba(45, 212, 191, 0.08)` |

**아코디언 헤더 (지출/수입/투자/자산)**:
| 속성 | 값 |
|------|-----|
| 아이콘 색상 | `#818CF8` (Indigo) |
| 텍스트 색상 | `#E6EDF3` |
| 텍스트 스타일 | textBodyMd (14px w400) |
| 펼침 아이콘 | Icons.expand_more, `#8B949E`, 회전 애니메이션 200ms |

**하위 메뉴 아이템**:
| 속성 | 값 |
|------|-----|
| 좌측 들여쓰기 | 24px (추가) |
| 아이콘 크기 | 20px (메인보다 소형) |
| 텍스트 스타일 | textBodySm (13px w400) |

---

### 4-3. DateFilterBar (날짜 필터 바)

**Flutter Widget**: `Container` + `Row`

```
┌─────────────────────────────────────────────────┐  height: 48px
│  [<]  [2024년 ▼]  [01월 ▼]  [>]  [↺]           │
└─────────────────────────────────────────────────┘
```

| 속성 | 값 |
|------|-----|
| 컨테이너 배경 | `#161B22` |
| 높이 | 48px |
| 수평 패딩 | 16px |
| 전체 Row 정렬 | MainAxisAlignment.center |
| 아이템 간격 | 8px |

**이전/다음 버튼 ([<] [>])**:
| 속성 | 값 |
|------|-----|
| 아이콘 | Icons.chevron_left / Icons.chevron_right |
| 아이콘 색상 | `#2DD4BF` |
| 크기 | 24px |
| 탭 영역 | 40px x 40px |

**연도/월 드롭다운 버튼**:
| 속성 | 값 |
|------|-----|
| 배경 | `#21262D` |
| BorderRadius | 8px |
| 내부 패딩 | 수직 6px, 수평 12px |
| 텍스트 | textLabelMd (14px w600), `#E6EDF3` |
| 드롭다운 아이콘 | Icons.arrow_drop_down, `#8B949E` |

**새로고침 버튼**:
| 속성 | 값 |
|------|-----|
| 아이콘 | Icons.refresh |
| 아이콘 색상 | `#8B949E` |
| 크기 | 24px |

---

### 4-4. SummaryCard (홈 대시보드 요약 카드)

**Flutter Widget**: `Card` 또는 `Container` + `InkWell`

```
┌────────────────────────────────────┐  BorderRadius: 16px
│  ┌────────┐                        │  배경: #161B22
│  │ 아이콘  │  5,280,000원           │  ← moneyLarge (32px w700)
│  │(50px원형)│  소득                 │  ← Caption (11px #8B949E)
│  └────────┘                        │
└────────────────────────────────────┘
```

| 속성 | 값 |
|------|-----|
| 배경색 | `#161B22` |
| BorderRadius | 16px |
| 내부 패딩 | 20px (사방) |
| elevation | 0 (그림자 없음) |

**아이콘 컨테이너**:
| 속성 | 값 |
|------|-----|
| 크기 | 50px x 50px |
| 형태 | CircleShape (BoxDecoration, shape: BoxShape.circle) |
| 배경색 | 항목별 `colorIconBg*` 토큰 적용 (15% 불투명도) |
| 아이콘 | Material Symbols Outlined, 28px |
| 아이콘 색상 | 항목별 의미 색상 (colorIncome / colorExpense / colorInvest / colorProfit / colorRate) |

**항목별 색상 매핑**:
| 항목 | 아이콘 | 아이콘 색상 | 배경색 |
|------|--------|-----------|--------|
| 소득 | attach_money | `#2DD4BF` | `rgba(45,212,191,0.15)` |
| 지출 | shopping_cart | `#F87171` | `rgba(248,113,113,0.15)` |
| 투자 | currency_bitcoin | `#FB923C` | `rgba(251,146,60,0.15)` |
| 순수익 | account_balance_wallet | `#4ADE80` | `rgba(74,222,128,0.15)` |
| 투자율 | percent | `#FACC15` | `rgba(250,204,21,0.15)` |

**텍스트 영역**:
| 속성 | 값 |
|------|-----|
| 금액 | moneyLarge (32px w700), `#E6EDF3`, Tabular Figures |
| 단위 "원" | moneyUnit (14px w500), `#8B949E` |
| 항목명 | textCaption (11px w400), `#8B949E` |
| 금액-항목명 간격 | 4px |

**상태**:
| 상태 | 표현 |
|------|------|
| Default | 위 스펙 그대로 |
| Hover/Pressed | InkWell splashColor `rgba(45,212,191,0.10)`, highlightColor `rgba(45,212,191,0.05)` |

---

### 4-5. TransactionCard (거래 카드)

**Flutter Widget**: `Card` 또는 `Container` + `InkWell`

```
┌────────────────────────────────────────────────┐  BorderRadius: 12px
│  ┌────┐  ├─ 3,500원              [지출][서울사랑]│  ← 금액 + 배지
│  │ 👤 │  └─ 식비 | 점심 (김밥천국)              │  ← 카테고리 + 비고
│  └────┘                                        │
└────────────────────────────────────────────────┘
```

포인트 적용 시:
```
│  ┌────┐  ├─ ~~5,000원~~  3,500원    [포인트]   │
│  │ 👤 │  └─ 식비 | 점심                         │
│  └────┘                                        │
```

| 속성 | 값 |
|------|-----|
| 배경색 | `#161B22` |
| BorderRadius | 12px |
| 내부 패딩 | 수직 12px, 수평 16px |
| elevation | 0 (그림자 없음) |
| 탭 피드백 | InkWell, splashColor `rgba(45,212,191,0.10)` |

**CircleAvatar (사용자 프로필)**:
| 속성 | 값 |
|------|-----|
| 크기 | 40px (radius: 20) |
| 테두리 | 2px, 사용자별 colorUser* 토큰 색상 |

**금액 영역**:
| 속성 | 값 |
|------|-----|
| 일반 금액 | moneySmall (18px w600), `#E6EDF3` |
| 취소선 금액 | moneyStrikethrough (16px w400), `#484F58`, TextDecoration.lineThrough |
| 할인 금액 | moneySmall (18px w600), `#E6EDF3` |
| 취소선-할인 금액 간격 | 6px |

**카테고리 텍스트**:
| 속성 | 값 |
|------|-----|
| 형식 | "대분류 | 소분류 (비고)" |
| 스타일 | textBodySm (13px w400), `#8B949E` |

**배지 영역**:
| 속성 | 값 |
|------|-----|
| 배치 | Row, 우측 정렬, gap 4px |
| 패딩 | 수직 3px, 수평 8px |
| BorderRadius | 4px |
| 텍스트 | 11px w500 |
| 색상 | 1-6 배지 색상 시스템 참조 |

---

### 4-6. DateGroupHeader (날짜 그룹 헤더)

**Flutter Widget**: `Padding` + `Row`

```
┌────────────────────────────────────┐
│  2024.01.15 (월)          [정렬 ↕] │
└────────────────────────────────────┘
```

| 속성 | 값 |
|------|-----|
| 배경 | 투명 (Scaffold 배경과 동일) |
| 상단 패딩 | 16px |
| 하단 패딩 | 8px |
| 좌우 패딩 | 16px |

**날짜 텍스트**:
| 속성 | 값 |
|------|-----|
| 형식 | "YYYY.MM.DD (요일)" |
| 스타일 | textLabelMd (14px w600), `#E6EDF3` |

**정렬 토글 버튼**:
| 속성 | 값 |
|------|-----|
| 아이콘 | Icons.swap_vert |
| 색상 | `#8B949E` |
| 크기 | 20px |

---

### 4-7. ProgressRow (진행률 바 행)

**Flutter Widget**: `Column` + `Row` + `LinearProgressIndicator`

```
┌────────────────────────────────────────┐
│  [아이콘] 식비                800,000원(32%) │
│  ███████████████████░░░░░░░░░          │  ← 높이 4px, BorderRadius 100
└────────────────────────────────────────┘
```

| 속성 | 값 |
|------|-----|
| 컨테이너 | Column, CrossAxisAlignment.start |
| 상단 Row 간격 | MainAxisAlignment.spaceBetween |
| 진행률 바 상단 패딩 | 8px |
| 진행률 바 높이 | 4px |
| 진행률 바 BorderRadius | 100px (완전 원형) |
| 트랙 배경색 | `rgba(255,255,255,0.08)` |

**진행률 바 채움색 (의미별)**:
| 컨텍스트 | 채움색 |
|---------|--------|
| 지출 대분류 | `#F87171` |
| 지출 소분류 | `#FB923C` |
| 수입 | `#2DD4BF` |
| 투자 | `#FB923C` |
| 자산 비율 | 자산 종류별 Stacked Chart 색상 팔레트 순환 |
| 주체별 지출 | 사용자별 colorUser* 토큰 |

**텍스트 스타일**:
| 요소 | 스타일 |
|------|--------|
| 카테고리명 | textBodySm (13px w400), `#E6EDF3` |
| 금액 | textBodySm (13px w500), `#E6EDF3` |
| 비율 "(XX%)" | textCaption (11px w400), `#8B949E` |

---

### 4-8. AccordionTile (아코디언)

**Flutter Widget**: `ExpansionTile`

```
┌────────────────────────────────────┐
│ [아이콘] 식비    1,200,000원 (45%) ▼│  ← 헤더 (접힘)
│ █████████████████░░░░░░            │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ [아이콘] 식비    1,200,000원 (45%) ▲│  ← 헤더 (펼침)
│ █████████████████░░░░░░            │
├────────────────────────────────────┤  ← 배경 전환
│   [아이콘] 외식  800,000원 (67%)   │  ← 소분류 아이템
│   ████████████░░░░░░               │
│   [아이콘] 배달  400,000원 (33%)   │
│   ████████░░░░░░░░░                │
└────────────────────────────────────┘
```

| 속성 | 값 |
|------|-----|
| 헤더 배경 | `#161B22` |
| 펼침 영역 배경 | `#21262D` |
| BorderRadius (헤더) | 12px |
| 펼침/접힘 아이콘 | Icons.expand_more, `#8B949E` |
| 아이콘 회전 애니메이션 | 180도, 200ms |
| 헤더 내부 패딩 | 수직 16px, 수평 16px |
| 소분류 아이템 좌측 들여쓰기 | 16px |

---

### 4-9. GradientButton (그래디언트 CTA 버튼)

**Flutter Widget**: `GestureDetector` + `AnimatedScale` + `Container` (LinearGradient) + `Text`

```
┌────────────────────────────────────┐  height: 52px, width: double.infinity
│           등록 / 수정              │  ← 15px w600, #0D1117
└────────────────────────────────────┘
  배경: LinearGradient #2DD4BF → #818CF8 (좌→우)
```

| 속성 | 값 |
|------|-----|
| 높이 | 52px |
| 너비 | double.infinity (전체 폭) |
| BorderRadius | 16px |
| 배경 | LinearGradient: `#2DD4BF` → `#818CF8`, 좌→우 |
| 텍스트 | textTitleSm (15px w600), `#0D1117` (다크 텍스트) |
| 탭 스케일 | AnimatedScale 0.97, 200ms, Curves.easeInOut |

**상태**:
| 상태 | 표현 |
|------|------|
| Default | 위 스펙 |
| Pressed | scale: 0.97 |
| Disabled | 배경 `rgba(45,212,191,0.30)`, 텍스트 `rgba(13,17,23,0.50)` |

---

### 4-10. OutlinedButton (보조 버튼)

**Flutter Widget**: `OutlinedButton`

| 속성 | 값 |
|------|-----|
| 높이 | 52px |
| 너비 | 가변 (폼 상황에 따라 결정) |
| BorderRadius | 16px |
| 배경 | 투명 |
| 테두리 | 1px solid `#30363D` |
| 텍스트 | textTitleSm (15px w500), `#E6EDF3` |

**상태**:
| 상태 | 표현 |
|------|------|
| Hover | 테두리 `#818CF8`, 텍스트 `#818CF8` |
| Pressed | 배경 `rgba(130,140,248,0.10)` |
| Disabled | 테두리 `#30363D`, 텍스트 `#484F58` |

---

### 4-11. DestructiveButton (삭제 버튼)

**Flutter Widget**: `OutlinedButton` 커스텀 스타일

| 속성 | 값 |
|------|-----|
| 높이 | 52px |
| 너비 | 가변 |
| BorderRadius | 16px |
| 배경 | `rgba(248,113,113,0.15)` |
| 테두리 | 1px solid `#F87171` |
| 텍스트 | textTitleSm (15px w500), `#F87171` |

**상태**:
| 상태 | 표현 |
|------|------|
| Pressed | 배경 `rgba(248,113,113,0.25)` |
| Disabled | 배경 투명, 테두리 `#484F58`, 텍스트 `#484F58` |

---

### 4-12. InputField (입력 필드)

**Flutter Widget**: `TextField` + `InputDecoration`

```
┌────────────────────────────────────┐  BorderRadius: 16px
│ 날짜                               │  ← Floating Label (13px #8B949E)
│ 2024.01.15                         │  ← 입력 텍스트 (16px #E6EDF3)
└────────────────────────────────────┘
```

| 속성 | 값 |
|------|-----|
| 배경색 | `#21262D` |
| 테두리 기본 | 1px solid `#30363D`, BorderRadius 16px |
| 테두리 포커스 | 2px solid `#2DD4BF`, BorderRadius 16px |
| 테두리 오류 | 1px solid `#F87171`, BorderRadius 16px |
| 내부 패딩 | 16px (사방) |
| Floating Label | textLabelSm (13px w500), `#8B949E` |
| 포커스 Label | `#2DD4BF` |
| 입력 텍스트 | textBodyLg (16px w400), `#E6EDF3` |
| Hint 텍스트 | textBodyLg, `#484F58` |

**비활성(Disabled) 상태**:
| 속성 | 값 |
|------|-----|
| 배경색 | `#161B22` |
| 테두리 | 1px solid `#21262D` |
| 텍스트 | `#484F58` |
| 아이콘 | `#484F58` |

**금액 입력 필드 전용**:
- `keyboardType: TextInputType.numberWithOptions(decimal: false)`
- `inputFormatters: [ThousandsSeparatorInputFormatter]` (천단위 콤마 자동 포맷)
- `fontFeatures: [FontFeature.tabularFigures()]`

---

### 4-13. DropdownField (드롭다운 필드)

**Flutter Widget**: `DropdownButtonFormField` 또는 커스텀 `GestureDetector` + `OverlayEntry`

InputField와 동일한 시각 스타일 기반에 다음을 추가한다.

| 속성 | 값 |
|------|-----|
| 우측 아이콘 | Icons.expand_more, `#8B949E`, 24px |
| 팝업 배경 | `#21262D` |
| 팝업 BorderRadius | 12px |
| 팝업 elevation | 8 |
| 팝업 아이템 높이 | 48px |
| 아이템 텍스트 기본 | textBodyMd (14px w400), `#E6EDF3` |
| 선택된 아이템 | `#2DD4BF` 텍스트, 배경 `rgba(45,212,191,0.10)` |

---

### 4-14. Badge (배지)

**Flutter Widget**: `Container` + `Text`

```
┌──────────┐  패딩: 3px 8px, BorderRadius: 4px
│  서울사랑  │  11px w500
└──────────┘
```

전체 배지 스펙은 1-6 배지 색상 시스템 참조.

**배지 배치 원칙**:
- TransactionCard에서 배지는 Row 안에 gap 4px로 나열
- 우선순위: 구분 배지(소득/지출/투자) → 서울사랑 → 첫만남 → 포인트 → 충동 → 고정지출
- 한 카드에 최대 4개 배지까지 표시 (그 이상은 생략)

---

### 4-15. FAB (플로팅 액션 버튼)

**Flutter Widget**: `FloatingActionButton` + `FloatingActionButton.small`

```
화면 우측 하단:
┌───┐  ← 맨 위로 버튼 (44px, #21262D 배경)
│ ↑ │
└───┘
┌───┐  ← 추가 버튼 (56px, #2DD4BF 배경)
│ + │
└───┘
```

**추가(+) 버튼**:
| 속성 | 값 |
|------|-----|
| 크기 | 56px x 56px |
| 형태 | 원형 (radiusFull) |
| 배경색 | `#2DD4BF` |
| 아이콘 | Icons.add, `#0D1117`, 24px |
| 하단 여백 | 16px |

**맨 위로(↑) 버튼**:
| 속성 | 값 |
|------|-----|
| 크기 | 44px x 44px |
| 형태 | 원형 |
| 배경색 | `#21262D` |
| 테두리 | 1px solid `#30363D` |
| 아이콘 | Icons.keyboard_arrow_up, `#8B949E`, 24px |
| 하단 여백 (추가 버튼 위) | 8px |
| 표시 조건 | ScrollController offset > 200px 시 AnimatedOpacity 출현 |

---

### 4-16. Toast 메시지

**Flutter Widget**: `OverlayEntry` + `AnimatedSlide` + `AnimatedOpacity`

```
         ┌─────────────────────────────────┐  ← 화면 하단 중앙
         │ ✓  등록 완료!!!                  │
         └─────────────────────────────────┘
           bottom: 32px from screen bottom
```

| 속성 | 값 |
|------|-----|
| 배경색 | `#21262D` |
| 테두리 | 1px solid `#30363D` |
| BorderRadius | 12px |
| 패딩 | 수직 12px, 수평 16px |
| 아이콘 | 16px, 메시지 유형별 색상 |
| 아이콘-텍스트 간격 | 8px |
| 텍스트 | textBodyMd (14px w500), `#E6EDF3` |
| 위치 | 화면 하단 중앙, bottom 32px |
| 최대 너비 | 320px |
| 출현 애니메이션 | SlideTransition 하단→위 + FadeTransition, 250ms |
| 사라짐 | FadeTransition, 300ms (2초 노출 후) |

**메시지 유형별 아이콘**:
| 메시지 | 아이콘 | 색상 |
|--------|--------|------|
| 등록 완료 | Icons.check_circle_outline | `#4ADE80` |
| 수정 완료 | Icons.edit_outlined | `#818CF8` |
| 삭제 완료 | Icons.delete_outline | `#F87171` |
| API 오류 | Icons.error_outline | `#F87171` |

---

### 4-17. LoadingDialog

**Flutter Widget**: `Stack` + `ModalBarrier` + `Center` + `Container`

```
████████████████████████████████████  ← rgba(13,17,23,0.85) 오버레이 (전체 화면)
           ┌──────────┐
           │          │  ← #161B22 컨테이너, BorderRadius 16px, 패딩 32px
           │    ( )   │  ← CircularProgressIndicator, #2DD4BF
           │          │
           └──────────┘
```

| 속성 | 값 |
|------|-----|
| 오버레이 배경 | `rgba(13,17,23,0.85)` |
| 컨테이너 배경 | `#161B22` |
| 컨테이너 BorderRadius | 16px |
| 컨테이너 패딩 | 32px (사방) |
| 스피너 | CircularProgressIndicator, strokeWidth 3px |
| 스피너 색상 | `#2DD4BF` |
| 스피너 크기 | 40px x 40px |
| 배리어 | WillPopScope로 뒤로가기 차단 |

---

### 4-18. AlertDialog

**Flutter Widget**: `AlertDialog` + `showDialog`

```
┌──────────────────────────────────┐  ← #161B22, BorderRadius 16px
│  입력 오류                        │  ← 18px w600, #E6EDF3
│                                  │
│  날짜를 선택해주세요.               │  ← 15px w400, #8B949E
│                                  │
│                         [  확인  ]│  ← #2DD4BF 텍스트 버튼
└──────────────────────────────────┘
```

| 속성 | 값 |
|------|-----|
| 배경색 | `#161B22` |
| BorderRadius | 16px |
| 외부 패딩 | 24px |
| 제목 | textHeadlineSm (18px w600), `#E6EDF3` |
| 내용 | textBodyLg (15px w400), `#8B949E` |
| 확인 버튼 텍스트 | textTitleSm (15px w600), `#2DD4BF` |
| 버튼 정렬 | 우측 |

---

### 4-19. EmptyView (빈 상태)

**Flutter Widget**: `Center` + `Column`

```
         [  아이콘 64px  ]
         데이터가 없습니다
```

| 속성 | 값 |
|------|-----|
| 정렬 | Center, Column |
| 아이콘 크기 | 64px |
| 아이콘 색상 | `#30363D` |
| 아이콘-텍스트 간격 | 16px |
| 텍스트 | textTitleMd (16px w500), `#484F58` |

---

## 5. 차트 스펙

**패키지**: fl_chart (Flutter 공식 차트 패키지)

---

### 5-1. BarChart (월별 추이 — 지출/수입/투자)

**fl_chart Widget**: `BarChart`

```
┌─────────────────────────────────────────────────┐  ← #161B22, BorderRadius 16px
│                                                 │
│   ▌  ▌  ▌  ▌  ▌  ▌  ▌  ▌  ▌  █  ▌  ▌  │평균│  │
│   1  2  3  4  5  6  7  8  9  10 11 12  평균    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**BarChartData 설정**:

| 속성 | 값 |
|------|-----|
| backgroundColor | `#0D1117` |
| 차트 컨테이너 배경 | `#161B22`, BorderRadius 16px |
| barWidth | 12px |
| borderRadius 막대 상단 | `radius4` (4px, 상단만 적용) |
| 일반 달 막대 | LinearGradient 하→상: `#2DD4BF` → `#818CF8` |
| 현재 달 막대 | `#F87171` 단색 |
| 평균 막대 | `#30363D` 단색 |
| X축 (BottomTitles) | 월 번호 + "평균", textCaption (11px), `#8B949E` |
| Y축 | 없음 (숨김) |
| GridLine | 수평선 1px, `rgba(255,255,255,0.05)` |
| 터치 인터랙션 | 비활성화 (touchExtraSensitivity: 0) |
| 차트 여백 | 상 16px, 하 8px, 좌 8px, 우 8px |

**요약 카드 (차트 위에 1~2개 표시)**:

```
┌──────────────────┐  ┌──────────────────┐
│ 저번달보다        │  │ 한달에 평균        │
│ 50,000원 덜 썼어요│  │ 1,200,000원 지출중 │
└──────────────────┘  └──────────────────┘
```

| 속성 | 값 |
|------|-----|
| 배경 | `#161B22` |
| BorderRadius | 12px |
| 내부 패딩 | 수직 12px, 수평 16px |
| 레이블 텍스트 | textCaption (11px w400), `#8B949E` |
| 금액 텍스트 | moneyMedium (20px w600), `#E6EDF3` |
| 비교 설명 텍스트 | textBodySm (13px w400), `#8B949E` |

---

### 5-2. LineChart (일별 추이)

**fl_chart Widget**: `LineChart`

```
┌───────────────────────────────────────────┐
│ ■ 강원    ■ 정윤    ■ 추가               │  ← 범례 Row
├───────────────────────────────────────────┤
│                                           │  ← 배경: #0D1117 → #161B22 (상→하)
│   / 강원(Teal)                            │
│  /                                        │
│ /    정윤(Pink)~~~~                        │
│ 1  5  10  15  20  25  31                  │  ← X축
└───────────────────────────────────────────┘
```

**LineChartData 설정**:

| 속성 | 값 |
|------|-----|
| 차트 배경 | LinearGradient 상→하: `#0D1117` → `#161B22` |
| lineBarsData 수 | 사용자 수 (최대 3개) |
| 라인 두께 | 2px |
| 점(dot) 크기 | 반지름 4px |
| 라인 하단 Fill | 각 색상 10% 불투명도 |
| X축 | 날짜 번호 1~31, textCaption (11px), `#8B949E` |
| Y축 | 50만 단위 간격, textCaption (11px), `#8B949E` |
| GridLine 수평 | 1px, `rgba(255,255,255,0.05)` |
| GridLine 수직 | 없음 |
| 터치 툴팁 배경 | `#21262D` |
| 터치 툴팁 텍스트 | textBodySm (13px), `#E6EDF3` |
| 터치 인터랙션 | 활성화 (날짜별 사용자 금액 표시) |

**범례 Row**:
| 속성 | 값 |
|------|-----|
| 색상 박스 | 12px x 12px, BorderRadius 2px |
| 박스-텍스트 간격 | 6px |
| 아이템 간 간격 | 16px |
| 텍스트 | textBodySm (13px w400), `#E6EDF3` |
| 하단 간격 (차트까지) | 12px |

---

### 5-3. Stacked BarChart (자산 누적 추이)

**fl_chart Widget**: `BarChart` (각 BarGroup에 복수 BarChartRodStackItem)

```
┌───────────────────────────────────────────┐
│ ■ 주식(Indigo) ■ 예금(Pink) ■ 현금(Teal) │  ← 범례
├───────────────────────────────────────────┤
│                                           │
│   ██  ██  ██  ██  ██                     │  ← 누적 막대
│   ██  ██  ██  ██  ██                     │
│   2024.01 02 03 04 ...                    │  ← X축 YYYY.MM
└───────────────────────────────────────────┘
```

**BarChartData 설정**:

| 속성 | 값 |
|------|-----|
| 각 섹션 색상 | Stacked Chart 색상 팔레트 (1-8번, 순환) |
| 섹션 간 간격 | 1px (배경색 `#0D1117`로 구분) |
| X축 | "YYYY.MM" 형식, textCaption (11px), `#8B949E` |
| Y축 | 단위 생략, 레이블만 표시 |
| barWidth | 20px |
| borderRadius | 상단 4px (스택 최상단만) |
| 터치 인터랙션 | 비활성화 |

**자산별 상세 카드 (차트 하단)**:

```
┌────────────────────────────────────┐  ← 자산 종류별 카드
│  ■ 주식                             │
│  2024.01: 50,000,000원              │
│  2024.02: 52,000,000원  ↑ +2,000,000원(+4.0%)│
└────────────────────────────────────┘
```

| 속성 | 값 |
|------|-----|
| 카드 배경 | `#161B22` |
| BorderRadius | 12px |
| 패딩 | 16px |
| 자산명 | textTitleMd (16px w500), 자산 색상 |
| 월별 금액 | moneySmall (18px w600), `#E6EDF3` |
| 전월 대비 증가 | textBodySm (13px), `#4ADE80` |
| 전월 대비 감소 | textBodySm (13px), `#F87171` |

---

## 6. 화면별 레이아웃

---

### 6-1. 홈 대시보드 (`/`)

```
┌─────────────────────────────────┐  ← AppBar (#0D1117, 56px)
│ ☰   강원 🧡 정윤 가계부          │
├─────────────────────────────────┤  ← DateFilterBar (#161B22, 48px)
│  [<]  [2024년▼]  [01월▼]  [>] [↺] │
├─────────────────────────────────┤
│  ┌──────────────────────────┐   │  ← SummaryCard (소득)
│  │  [💙원형아이콘]  소득      │   │    배경: #161B22, BorderRadius 16px
│  │  5,280,000원              │   │    moneyLarge (32px w700)
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │  ← SummaryCard (지출), 카드간 8px
│  │  [🔴원형아이콘]  지출      │   │
│  │  2,450,000원              │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │  ← SummaryCard (투자)
│  │  [🟠원형아이콘]  투자      │   │
│  │  500,000원                │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │  ← SummaryCard (순수익)
│  │  [🟢원형아이콘]  순수익    │   │
│  │  2,330,000원              │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │  ← SummaryCard (투자율)
│  │  [🟡원형아이콘]  투자율    │   │
│  │  9.5%                    │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

- 배경: `#0D1117`
- 좌우 패딩: 16px
- 카드 간 간격: 8px
- 상단 패딩 (DateFilterBar 아래): 16px
- 하단 패딩: 16px

---

### 6-2. 가계부 목록 (`/accountList`)

```
┌─────────────────────────────────┐  ← AppBar
│ ☰   강원 🧡 정윤 가계부          │
├─────────────────────────────────┤  ← DateFilterBar
│  [<]  [2024년▼]  [01월▼]  [>] [↺] │
├─────────────────────────────────┤
│                                 │
│  2024.01.15 (월)       [정렬 ↕] │  ← DateGroupHeader (상단 16px, 하단 8px)
│  ┌───────────────────────────┐  │  ← TransactionCard
│  │ [강원] 3,500원  [지출][서울사랑]│  │    배경: #161B22, BorderRadius 12px
│  │        식비 | 점심 (김밥천국)│  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ [정윤] ~~5,000원~~ 3,800원 [포인트]│
│  │        카페 | 커피          │  │
│  └───────────────────────────┘  │
│                                 │
│  2024.01.14 (일)       [정렬 ↕] │
│  ┌───────────────────────────┐  │
│  │ [강원] 45,000원    [투자]  │  │
│  │        투자 | 주식          │  │
│  └───────────────────────────┘  │
│                                 │
│                      [↑] [+]   │  ← FAB (↑: 44px, +: 56px)
└─────────────────────────────────┘
```

- ListView.builder로 성능 최적화
- SliverAppBar 사용 권장 (스크롤 시 DateFilterBar도 숨김)
- FAB는 Stack으로 고정 배치

---

### 6-3. 지출 카테고리별 (`/expense`)

```
┌─────────────────────────────────┐
│ AppBar + DateFilterBar          │
├─────────────────────────────────┤
│  ┌───────────────────────────┐  │  ← AccordionTile (접힘)
│  │ [🛒] 식비  1,200,000(45%) ▼│  │    배경: #161B22, BorderRadius 12px
│  │ ████████████████░░░░░░░   │  │    ProgressBar 4px, #F87171
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │  ← AccordionTile (펼침)
│  │ [🏠] 주거  800,000(30%)   ▲│  │
│  │ █████████████░░░░░░░░░    │  │
│  ├───────────────────────────┤  │    ← 펼침 영역 배경 #21262D
│  │  [아이콘] 월세  600,000(75%)│  │
│  │  █████████████░░░          │  │    ProgressBar #FB923C (소분류)
│  │  [아이콘] 관리비 200,000(25%)│  │
│  │  ████░░░░░░░░░░             │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

---

### 6-4. 차트 화면 공통 (`/expense/chart`, `/income/chart`, `/invest/chart`)

```
┌─────────────────────────────────┐
│ AppBar + DateFilterBar          │
├─────────────────────────────────┤
│  ┌────────────┐ ┌────────────┐  │  ← 요약 카드 Row
│  │ 저번달 비교 │ │   월 평균   │  │    배경: #161B22, BorderRadius 12px
│  │ -50,000원  │ │1,200,000원 │  │
│  └────────────┘ └────────────┘  │
│                                 │  ← 섹션 간 간격 24px
│  ┌─────────────────────────────┐│  ← BarChart 영역
│  │       차트 타이틀            ││    배경: #161B22, BorderRadius 16px
│  │                             ││
│  │   ▌  ▌  ▌  █  ▌  ▌  ▌    ││  ← 현재 달 빨간색 막대
│  │   1  2  3  4  5  6  7  평균 ││  ← X축 레이블 #8B949E 11px
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

---

### 6-5. 가계부 추가/수정 (`/account`)

```
┌─────────────────────────────────┐
│ AppBar                          │
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │  ← InputField (날짜)
│  │ 📅 날짜   2024.01.15    │   │    배경: #21262D, BorderRadius 16px
│  └─────────────────────────┘   │
│  ──────────────────────────    │  ← Divider (#30363D)
│  ┌─────────────────────────┐   │  ← DropdownField (구분)
│  │ 📊 구분   지출       ▼  │   │
│  └─────────────────────────┘   │
│  ──────────────────────────    │
│  ┌─────────────────────────┐   │
│  │ 👤 주체   강원       ▼  │   │
│  └─────────────────────────┘   │
│  ──────────────────────────    │
│  ┌─────────────────────────┐   │  ← DropdownField (결제수단)
│  │ 💳 결제수단  카드     ▼  │   │
│  └─────────────────────────┘   │
│  ──────────────────────────    │
│  ┌─────────────────────────┐   │  ← DropdownField (대분류)
│  │ 📂 대분류  식비       ▼  │   │
│  └─────────────────────────┘   │
│  ── (소분류, 가격, 비고 반복) ──    │
│                                 │
│  ┌──────────┐ ┌──────────────┐ │  ← 수정 모드 버튼 Row
│  │   삭제   │ │    수정      │ │    DestructiveBtn + GradientBtn
│  └──────────┘ └──────────────┘ │
└─────────────────────────────────┘
```

- 폼 상하 패딩: 20px
- 항목 간 Divider: `#30363D` 1px
- 하단 버튼 Row 상단 여백: 24px

---

### 6-6. 자산 목록 (`/asset`)

```
┌─────────────────────────────────┐
│ AppBar + DateFilterBar          │
├─────────────────────────────────┤
│  총 자산        순 자산  현금성  [↺] │  ← 자산 통계 요약 Row
│  45,000만원  30,000만원 5,000만원   │    배경: #161B22, 패딩 16px
├─────────────────────────────────┤
│  환율($)    환율(¥)    기준일    │  ← 환율 정보 Row
│  1,320원    8.8원     2024.01.01│    텍스트 #8B949E, 11px
├─────────────────────────────────┤
│                                 │
│  📈 주식              1억 2천만 │  ← 자산 그룹 헤더
│  ┌───────────────────────────┐  │
│  │ [아이콘] 삼성전자 5,000만 100주 ▼│  ← AccordionTile
│  │   [아이콘] 보통주  5,000만     │
│  └───────────────────────────┘  │
│                                 │
│  🏦 예금              8,000만  │
│  ┌───────────────────────────┐  │
│  │ [아이콘] KB저축 8,000만  1개 │  ← ListTile (하위 없음)
│  │                   [현금성] │  │
│  └───────────────────────────┘  │
│                            [+]  │  ← FAB (+)
└─────────────────────────────────┘
```

---

### 6-7. 자산 추가/수정 (`/myAsset`)

```
┌─────────────────────────────────┐
│ AppBar                          │
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │
│  │ 자산 분류   주식     ▼  │   │  ← DropdownField
│  └─────────────────────────┘   │
│  ──────────────────────────    │
│  ┌─────────────────────────┐   │
│  │ 자산 이름   삼성전자      │   │  ← InputField
│  └─────────────────────────┘   │
│  ──────────────────────────    │
│  ┌─────────────────────────┐   │
│  │ 티커       005930        │   │  ← InputField
│  └─────────────────────────┘   │
│  ──────────────────────────    │
│  ┌─────────────────────────┐   │
│  │ 가격 세팅  AUTO      ▼  │   │  ← DropdownField
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │  ← AUTO 선택 시: 배경 #161B22, 비활성
│  │ 가격       (자동 조회)   │   │    MANUAL 선택 시: 배경 #21262D, 활성
│  └─────────────────────────┘   │
│  ── (개수, 환율 적용, 현금성) ──    │
│                                 │
│  ┌──────────┐ ┌──────────────┐ │
│  │   삭제   │ │    수정      │ │
│  └──────────┘ └──────────────┘ │
└─────────────────────────────────┘
```

---

## 7. 애니메이션 지침

### 7-1. 페이지 전환

| 전환 유형 | 위젯 | 설정값 |
|---------|------|--------|
| 기본 화면 이동 | `SlideTransition` | 우→좌 (Offset(1.0, 0.0) → Offset(0.0, 0.0)) |
| 이동 시간 | `duration` | 300ms |
| 커브 | `Curves` | `Curves.easeInOut` |
| 드로어 | Flutter 기본 Drawer 슬라이드 | 좌측 슬라이드, 300ms |

### 7-2. 카드 인터랙션

| 상황 | 위젯 | 설정값 |
|------|------|--------|
| 탭 | `InkWell` | splashColor `rgba(45,212,191,0.10)`, highlightColor `rgba(45,212,191,0.05)` |
| CTA 버튼 탭 | `GestureDetector` + `AnimatedScale` | scale: 0.97, duration 200ms, Curves.easeInOut |

### 7-3. 아코디언

| 상황 | 위젯 | 설정값 |
|------|------|--------|
| 펼침/접힘 | `ExpansionTile` 내장 | duration 200ms |
| 커브 | `AnimatedContainer` | `Curves.easeOut` |
| 아이콘 회전 | `AnimatedRotation` | 180도, duration 200ms |

### 7-4. FAB & 스크롤

| 상황 | 위젯 | 설정값 |
|------|------|--------|
| 맨 위로 버튼 표시 | `AnimatedOpacity` | offset > 200px 시 opacity 0→1, duration 300ms |
| 스크롤 상단 이동 | `ScrollController.animateTo` | duration 300ms, Curves.easeOut |

### 7-5. Toast & 모달

| 상황 | 위젯 | 설정값 |
|------|------|--------|
| Toast 출현 | `SlideTransition` + `FadeTransition` | 하단→위, 250ms |
| Toast 사라짐 | `FadeTransition` | 300ms (2초 노출 후) |
| Dialog 진입 | `FadeTransition` | 200ms |
| 로딩 표시 | `FadeTransition` | 200ms |

### 7-6. 데이터 & 숫자

| 상황 | 위젯 | 설정값 |
|------|------|--------|
| 금액 변경 시 | `AnimatedSwitcher` | FadeTransition out→in, 150ms |
| 화면 최초 로드 | `FadeTransition` | 200ms, Curves.easeIn |

### 7-7. 공통 커브 기준

| 커브 | 사용처 |
|------|--------|
| `Curves.easeInOut` | 페이지 전환, 버튼 탭 |
| `Curves.easeOut` | 아코디언 펼침, 스크롤 이동 |
| `Curves.easeIn` | Toast 사라짐, 오버레이 제거 |

---

## 8. 공통 UX 패턴

### 8-1. 로딩 상태

| 상황 | 처리 방식 |
|------|---------|
| API 호출 중 (화면 블로킹) | LoadingDialog (4-17 스펙 참조) |
| 화면 최초 데이터 로드 | Scaffold 내 Center + CircularProgressIndicator (`#2DD4BF`) |
| Shimmer 스켈레톤 | 미적용 (구현 복잡도 대비 효과 낮음) |

### 8-2. 오류 처리

| 오류 유형 | 처리 방식 |
|---------|---------|
| 입력 검증 오류 | AlertDialog (4-18 스펙 참조) |
| API 통신 오류 | Toast (4-16 스펙, 오류 아이콘 + 오류 메시지) |
| 빈 데이터 | EmptyView (4-19 스펙 참조) |

### 8-3. Toast 메시지 트리거 조건

| 상황 | 메시지 |
|------|--------|
| 거래 등록 완료 | "등록 완료!!!" |
| 거래 수정 완료 | "수정 완료!!!" |
| 거래 삭제 완료 | "삭제 완료!!!" |
| 자산 등록 완료 | "등록 완료!!!" |
| 자산 수정 완료 | "수정 완료!!!" |

Toast는 이전 화면으로 복귀 시 해당 화면에서 표시한다.

### 8-4. 스크롤 패턴

| 패턴 | 적용 방식 |
|------|---------|
| 거래 목록, 자산 목록 | `ListView.builder` (성능 최적화, 대량 데이터 대응) |
| 차트 화면 | `SingleChildScrollView` (요약 카드 + 차트 포함) |
| 폼 화면 | `SingleChildScrollView` + `Column` |
| 맨 위로 이동 | `ScrollController.animateTo(0, ...)` |

### 8-5. 키보드 입력 유형

| 입력 필드 | keyboardType | inputFormatter |
|---------|-------------|----------------|
| 가격 | `TextInputType.numberWithOptions(decimal: false)` | 천단위 콤마 자동 포맷 |
| 포인트 처리 금액 | `TextInputType.numberWithOptions(decimal: false)` | 천단위 콤마 자동 포맷 |
| 개수 (자산) | `TextInputType.numberWithOptions(decimal: true)` | 없음 |
| 자산 이름, 티커 | `TextInputType.text` | 없음 |
| 비고 | `TextInputType.multiline` | 없음 |

### 8-6. 금액 표기 규칙

```dart
// 천단위 콤마
NumberFormat("#,##0", "ko_KR").format(amount)

// 예시
1234567 → "1,234,567"

// 비율
"${value.toStringAsFixed(1)}%"

// 날짜 (거래 카드 그룹 헤더)
DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(date)

// 날짜 (DateFilterBar 연도)
"${date.year}년"

// 날짜 (DateFilterBar 월)
"${date.month.toString().padLeft(2, '0')}월"
또는 "전체"
```

### 8-7. 반응형 고려사항 (Flutter Web)

이 앱은 Flutter Web 전용으로 개발된다. CORS 주의 사항과 함께 아래를 준수한다.

| 항목 | 기준 |
|------|------|
| 최소 화면 너비 | 360px (모바일 기준) |
| 최대 컨텐츠 너비 | 600px (모바일 앱 폼팩터 유지) |
| 너비 초과 시 | `Center` + `ConstrainedBox(maxWidth: 600)` |
| 폰트 스케일 | `textScaleFactor` 무시 (고정 크기 유지) |

### 8-8. 접근성 최소 요구사항

| 항목 | 적용 기준 |
|------|---------|
| 탭 영역 최소 크기 | 44px x 44px (iOS HIG 기준) |
| 텍스트 대비 비율 | 배경 `#0D1117` 대비 텍스트 `#E6EDF3` → 11.1:1 (AA 기준 4.5:1 초과) |
| 보조 텍스트 대비 | 배경 `#161B22` 대비 `#8B949E` → 약 4.6:1 (AA 기준 충족) |
| 아이콘 전용 버튼 | `Semantics` 위젯으로 레이블 제공 |
| 진행률 바 | `Semantics` + `value` 속성으로 비율 값 제공 |

---

*본 문서는 Stage 3 Flutter 구현 가이드(`docs/FLUTTER_DESIGN_GUIDE.md`) 작성의 직접 입력 자료로 사용됩니다.*  
*Stage 4~6 flutter-expert 에이전트는 이 문서를 코드 레벨 결정의 최종 기준으로 삼습니다.*
