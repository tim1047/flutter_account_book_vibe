# Flutter Design Guide — 가계부 앱 ("Teal Fusion")

> 이 문서는 `docs/DESIGN_SYSTEM.md`의 디자인 스펙을 Flutter 코드로 직접 옮길 수 있도록 정리한 구현 지침서입니다.
> Stage 4~6의 flutter-expert 에이전트들은 이 파일의 코드 스니펫을 그대로 복사·붙여넣어 사용해도 됩니다.
>
> 대상 플랫폼: Flutter Web (Chrome). 검증 명령: `flutter run -d chrome`
> 절대 수정 금지 영역: `*_viewmodel.dart`, `*_service.dart`, `*_model.dart` (UI 레이어만 수정)

---

## 목차

1. [app_colors.dart 전체 구현](#섹션-1-app_colorsdart-전체-구현)
2. [app_text_styles.dart 신규 파일](#섹션-2-app_text_stylesdart-신규-파일)
3. [app_theme.dart 전체 구현](#섹션-3-app_themedart-전체-구현)
4. [커스텀 위젯 구현 가이드](#섹션-4-커스텀-위젯-구현-가이드)
5. [기존 위젯별 교체 가이드](#섹션-5-기존-위젯별-교체-가이드)
6. [pubspec.yaml 변경 사항](#섹션-6-pubspecyaml-변경-사항)
7. [구현 순서 및 주의사항](#섹션-7-구현-순서-및-주의사항)

---

## 섹션 1. app_colors.dart 전체 구현

`lib/core/constants/app_colors.dart` 파일을 아래 코드로 **완전히 교체**합니다.

핵심 원칙:
- `withOpacity()` 대신 `Color.fromRGBO(r, g, b, opacity)`를 사용하여 const 호환성을 유지합니다.
- 기존 `divisionColor` Map의 키(`Division.income/expense/invest`)는 그대로 유지합니다 (ViewModel 호환).
- 기존 `primary` 상수는 **유지하되 값만** `#FF6B35` → `#2DD4BF`로 교체합니다 (다른 코드 참조 호환).
- 기존 `expense`, `income`, `invest`, `netIncome`, `investRate`, `success`, `error`, `warning` 상수는 새 Teal Fusion 팔레트 값으로 교체하여 alias 역할을 유지합니다.

```dart
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:flutter/material.dart';

/// Teal Fusion 디자인 시스템 색상 팔레트.
///
/// 모든 색상은 `Color(0xFF......)` 형식 또는 `Color.fromRGBO(...)` 형식으로
/// const 컨텍스트에서 사용 가능하도록 정의합니다.
class AppColors {
  AppColors._();

  // ===========================================================================
  // 1. 배경 계층 (그림자 없이 배경색 차이로 깊이 표현)
  // ===========================================================================

  /// Scaffold 배경, AppBar 배경 (가장 어두운 배경).
  static const Color colorBgMain = Color(0xFF0D1117);

  /// 카드, Drawer, DateFilterBar, SummaryCard 배경.
  static const Color colorBgSub = Color(0xFF161B22);

  /// 인터랙티브 요소, InputField, Accordion 펼침 영역 배경.
  static const Color colorBgCard = Color(0xFF21262D);

  /// 팝업, Tooltip, 선택된 메뉴 등 가장 위 계층.
  static const Color colorBgElevated = Color(0xFF30363D);

  // ===========================================================================
  // 2. 강조색
  // ===========================================================================

  /// CTA 버튼, 수입/소득, 활성 상태, FAB의 메인 컬러.
  static const Color colorAccentTeal = Color(0xFF2DD4BF);

  /// 그래디언트 끝점, 보조 강조.
  static const Color colorAccentIndigo = Color(0xFF818CF8);

  // ===========================================================================
  // 3. 텍스트 계층
  // ===========================================================================

  static const Color colorTextPrimary = Color(0xFFE6EDF3);
  static const Color colorTextSecondary = Color(0xFF8B949E);
  static const Color colorTextDisabled = Color(0xFF484F58);
  static const Color colorDivider = Color(0xFF30363D);

  // ===========================================================================
  // 4. 의미색 (수입/지출/투자/순수익/투자율)
  // ===========================================================================

  static const Color colorIncome = Color(0xFF2DD4BF);
  static const Color colorExpense = Color(0xFFF87171);
  static const Color colorInvest = Color(0xFFFB923C);
  static const Color colorProfit = Color(0xFF4ADE80);
  static const Color colorRate = Color(0xFFFACC15);

  static const Color colorSuccess = Color(0xFF4ADE80);
  static const Color colorError = Color(0xFFF87171);
  static const Color colorWarning = Color(0xFFFACC15);
  static const Color colorInfo = Color(0xFF818CF8);

  // ===========================================================================
  // 5. 오버레이 / Hover / Pressed (Color.fromRGBO 사용 — const 안전)
  // ===========================================================================

  /// InkWell splashColor (Teal 10% 불투명).
  static const Color colorHoverTeal = Color.fromRGBO(45, 212, 191, 0.10);

  /// InkWell highlightColor (Teal 5% 불투명).
  static const Color colorPressedTeal = Color.fromRGBO(45, 212, 191, 0.05);

  /// Loading Dialog 오버레이 (Bg 85% 불투명).
  static const Color colorLoadingOverlay = Color.fromRGBO(13, 17, 23, 0.85);

  /// ProgressIndicator 트랙 (흰색 8% 불투명).
  static const Color colorProgressTrack = Color.fromRGBO(255, 255, 255, 0.08);

  /// SummaryCard 아이콘 컨테이너 배경 (각 의미색 15% 불투명).
  static const Color colorIconBgIncome = Color.fromRGBO(45, 212, 191, 0.15);
  static const Color colorIconBgExpense = Color.fromRGBO(248, 113, 113, 0.15);
  static const Color colorIconBgInvest = Color.fromRGBO(251, 146, 60, 0.15);
  static const Color colorIconBgProfit = Color.fromRGBO(74, 222, 128, 0.15);
  static const Color colorIconBgRate = Color.fromRGBO(250, 204, 21, 0.15);

  // ===========================================================================
  // 6. 배지 색상 (배경 / 텍스트 쌍)
  // ===========================================================================

  static const Color badgeIncomeBg = Color.fromRGBO(45, 212, 191, 0.20);
  static const Color badgeIncomeText = Color(0xFF2DD4BF);

  static const Color badgeExpenseBg = Color.fromRGBO(248, 113, 113, 0.20);
  static const Color badgeExpenseText = Color(0xFFF87171);

  static const Color badgeInvestBg = Color.fromRGBO(251, 146, 60, 0.20);
  static const Color badgeInvestText = Color(0xFFFB923C);

  static const Color badgeSeoulLoveBg = Color(0xFF1F2937);
  static const Color badgeSeoulLoveText = Color(0xFFE6EDF3);

  static const Color badgeFirstMeetingBg = Color(0xFF312E81);
  static const Color badgeFirstMeetingText = Color(0xFFA5B4FC);

  static const Color badgePointBg = Color(0xFF92400E);
  static const Color badgePointText = Color(0xFFFCD34D);

  static const Color badgeImpulseBg = Color(0xFF4C1D95);
  static const Color badgeImpulseText = Color(0xFFC4B5FD);

  static const Color badgeFixedBg = Color(0xFF713F12);
  static const Color badgeFixedText = Color(0xFFFDE68A);

  // ===========================================================================
  // 7. 사용자 구분색
  // ===========================================================================

  /// 강원 (member 0).
  static const Color colorUser1 = Color(0xFF2DD4BF);

  /// 정윤 (member 1).
  static const Color colorUser2 = Color(0xFFF472B6);

  /// 추가 멤버 (member 2).
  static const Color colorUser3 = Color(0xFFFB923C);

  // ===========================================================================
  // 8. 차트 색상 리스트
  // ===========================================================================

  /// 사용자별 진행률 바·아바타 등에 인덱스 순환 사용.
  static const List<Color> memberColors = <Color>[
    colorUser1,
    colorUser2,
    colorUser3,
    Color(0xFF818CF8), // 4번째 이상이 필요할 경우 fallback
  ];

  /// 자산 누적 차트 8색 팔레트 (순환 사용).
  static const List<Color> assetChartColors = <Color>[
    Color(0xFF818CF8),
    Color(0xFFF472B6),
    Color(0xFF2DD4BF),
    Color(0xFF4ADE80),
    Color(0xFFF87171),
    Color(0xFFE6EDF3),
    Color(0xFFFB923C),
    Color(0xFFFACC15),
  ];

  /// 일별 지출 LineChart 사용자별 라인 컬러.
  static const List<Color> chartLineColors = <Color>[
    Color(0xFF2DD4BF),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
  ];

  /// BarChart 평균 막대 색상.
  static const Color colorChartAverage = Color(0xFF30363D);

  /// BarChart 현재 달 강조 색상.
  static const Color colorChartCurrent = Color(0xFFF87171);

  // ===========================================================================
  // 9. 그래디언트 상수
  // ===========================================================================

  /// CTA 버튼 등 메인 그래디언트 (좌→우).
  static const LinearGradient appGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[colorAccentTeal, colorAccentIndigo],
  );

  /// BarChart 일반 막대 그래디언트 (하→상).
  static const LinearGradient barChartGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: <Color>[colorAccentTeal, colorAccentIndigo],
  );

  /// LineChart 배경 그래디언트 (상→하).
  static const LinearGradient lineChartBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[colorBgMain, colorBgSub],
  );

  /// Drawer 헤더 사진 위 오버레이 (상→하).
  static const LinearGradient drawerHeaderOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color.fromRGBO(13, 17, 23, 0.0),
      Color.fromRGBO(13, 17, 23, 0.7),
    ],
  );

  // ===========================================================================
  // 10. Legacy alias (기존 코드 호환)
  // ===========================================================================
  // 기존 코드에서 참조 중인 상수명을 그대로 유지하되, 값만 새 팔레트로 교체.

  /// 기존 코드 호환용 — 새 메인 컬러는 Teal.
  static const Color primary = colorAccentTeal;
  static const Color primaryDark = Color(0xFF14B8A6);

  static const Color background = colorBgMain;
  static const Color surface = colorBgSub;
  static const Color surfaceVariant = colorBgCard;

  static const Color income = colorIncome;
  static const Color expense = colorExpense;
  static const Color invest = colorInvest;
  static const Color netIncome = colorProfit;
  static const Color investRate = colorRate;

  static const Color textPrimary = colorTextPrimary;
  static const Color textSecondary = colorTextSecondary;
  static const Color textHint = colorTextDisabled;
  static const Color divider = colorDivider;
  static const Color border = colorDivider;

  static const Color badgeSeoulLove = badgeSeoulLoveBg;
  static const Color badgeFirstMeeting = badgeFirstMeetingBg;
  static const Color badgePoint = badgePointBg;
  static const Color badgeImpulse = badgeImpulseBg;
  static const Color badgeFixed = badgeFixedBg;

  static const Color success = colorSuccess;
  static const Color error = colorError;
  static const Color warning = colorWarning;

  // ===========================================================================
  // 11. Division 매핑 (기존 ViewModel 호환 — 절대 키 변경 금지)
  // ===========================================================================

  static const Map<String, Color> divisionColor = <String, Color>{
    Division.income: colorIncome,
    Division.expense: colorExpense,
    Division.invest: colorInvest,
  };

  /// 배지용 division 매핑 (배경 / 텍스트).
  static const Map<String, Color> divisionBadgeBg = <String, Color>{
    Division.income: badgeIncomeBg,
    Division.expense: badgeExpenseBg,
    Division.invest: badgeInvestBg,
  };

  static const Map<String, Color> divisionBadgeText = <String, Color>{
    Division.income: badgeIncomeText,
    Division.expense: badgeExpenseText,
    Division.invest: badgeInvestText,
  };
}
```

---

## 섹션 2. app_text_styles.dart 신규 파일

`lib/core/constants/app_text_styles.dart` 파일을 **신규 생성**합니다.

### 폰트 fallback 처리 전략

1. `pubspec.yaml`에 Pretendard를 등록하고 `assets/fonts/`에 ttf 파일을 배치하면 자동으로 사용됩니다.
2. ttf 파일이 아직 없을 경우 `_kFontFamily` 상수를 `'NotoSans'`(google_fonts에서 자동 로딩)로 일시 변경 가능. 단, google_fonts는 네트워크 의존이므로 Pretendard 로컬 등록을 권장합니다.
3. 모든 금액(`money*`) 스타일은 `fontFeatures: [FontFeature.tabularFigures()]`를 적용하여 자릿수 정렬이 어긋나지 않도록 합니다.

```dart
import 'dart:ui';

import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Teal Fusion 타이포그래피 스케일.
///
/// 폰트 패밀리 우선순위: Pretendard → Noto Sans KR (fallback).
/// pubspec.yaml의 `fonts:` 섹션에 Pretendard ttf가 등록되어 있어야 합니다.
class AppTextStyles {
  AppTextStyles._();

  /// 메인 폰트 패밀리. Pretendard 미등록 시 'NotoSans'로 변경.
  static const String _fontFamily = 'Pretendard';

  /// 금액 표시 전용 fontFeatures — 자릿수 폭 고정 (tabular).
  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  // ===========================================================================
  // Display
  // ===========================================================================

  static const TextStyle textDisplayLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textDisplayMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.colorTextPrimary,
  );

  // ===========================================================================
  // Headline
  // ===========================================================================

  static const TextStyle textHeadlineLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textHeadlineMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.1,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textHeadlineSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
  );

  // ===========================================================================
  // Title
  // ===========================================================================

  static const TextStyle textTitleLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textTitleMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.colorTextPrimary,
  );

  /// 버튼 텍스트 기본.
  static const TextStyle textTitleSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.colorTextPrimary,
  );

  // ===========================================================================
  // Body
  // ===========================================================================

  static const TextStyle textBodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textBodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textBodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.colorTextPrimary,
  );

  // ===========================================================================
  // Label / Caption
  // ===========================================================================

  static const TextStyle textLabelMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textLabelSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textCaption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.colorTextSecondary,
  );

  // ===========================================================================
  // Money (tabular figures 필수)
  // ===========================================================================

  static const TextStyle moneyDisplay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.colorTextPrimary,
    fontFeatures: _tabular,
  );

  /// SummaryCard 메인 금액.
  static const TextStyle moneyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.colorTextPrimary,
    fontFeatures: _tabular,
  );

  /// 자산 목록.
  static const TextStyle moneyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
    fontFeatures: _tabular,
  );

  /// TransactionCard 금액.
  static const TextStyle moneySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
    fontFeatures: _tabular,
  );

  /// 포인트 사용 시 원래 금액(취소선).
  static const TextStyle moneyStrikethrough = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.colorTextDisabled,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.colorTextDisabled,
    fontFeatures: _tabular,
  );

  /// "원", "%" 단위 표기.
  static const TextStyle moneyUnit = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.colorTextSecondary,
  );
}
```

---

## 섹션 3. app_theme.dart 전체 구현

`lib/core/theme/app_theme.dart` 파일을 **완전 교체**합니다.

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Teal Fusion 다크 테마.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final ThemeData base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.colorBgMain,

      // -----------------------------------------------------------------------
      // ColorScheme
      // -----------------------------------------------------------------------
      colorScheme: const ColorScheme.dark(
        primary: AppColors.colorAccentTeal,
        onPrimary: AppColors.colorBgMain,
        secondary: AppColors.colorAccentIndigo,
        onSecondary: AppColors.colorBgMain,
        surface: AppColors.colorBgSub,
        onSurface: AppColors.colorTextPrimary,
        background: AppColors.colorBgMain,
        onBackground: AppColors.colorTextPrimary,
        error: AppColors.colorError,
        onError: AppColors.colorBgMain,
        surfaceVariant: AppColors.colorBgCard,
        outline: AppColors.colorDivider,
      ),

      // -----------------------------------------------------------------------
      // Text
      // -----------------------------------------------------------------------
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.textDisplayLg,
        displayMedium: AppTextStyles.textDisplayMd,
        headlineLarge: AppTextStyles.textHeadlineLg,
        headlineMedium: AppTextStyles.textHeadlineMd,
        headlineSmall: AppTextStyles.textHeadlineSm,
        titleLarge: AppTextStyles.textTitleLg,
        titleMedium: AppTextStyles.textTitleMd,
        titleSmall: AppTextStyles.textTitleSm,
        bodyLarge: AppTextStyles.textBodyLg,
        bodyMedium: AppTextStyles.textBodyMd,
        bodySmall: AppTextStyles.textBodySm,
        labelLarge: AppTextStyles.textLabelMd,
        labelMedium: AppTextStyles.textLabelMd,
        labelSmall: AppTextStyles.textLabelSm,
      ).apply(
        bodyColor: AppColors.colorTextPrimary,
        displayColor: AppColors.colorTextPrimary,
      ),

      // -----------------------------------------------------------------------
      // AppBar
      // -----------------------------------------------------------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.colorBgMain,
        foregroundColor: AppColors.colorTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        iconTheme: IconThemeData(
          color: AppColors.colorTextSecondary,
          size: 24,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.colorTextPrimary,
        ),
      ),

      // -----------------------------------------------------------------------
      // Card
      // -----------------------------------------------------------------------
      cardTheme: const CardTheme(
        color: AppColors.colorBgSub,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // -----------------------------------------------------------------------
      // Input
      // -----------------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.colorBgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.colorTextSecondary,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.colorAccentTeal,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.colorTextDisabled,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.colorDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.colorDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.colorAccentTeal,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.colorBgCard),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.colorError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.colorError, width: 2),
        ),
      ),

      // -----------------------------------------------------------------------
      // Buttons (대부분 GradientButton 커스텀 위젯 사용 권장)
      // -----------------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorAccentTeal,
          foregroundColor: AppColors.colorBgMain,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.colorAccentTeal,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.colorError,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.colorError),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // FAB
      // -----------------------------------------------------------------------
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.colorAccentTeal,
        foregroundColor: AppColors.colorBgMain,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      ),

      // -----------------------------------------------------------------------
      // Drawer / Dialog / BottomSheet
      // -----------------------------------------------------------------------
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.colorBgSub,
        elevation: 0,
        shape: RoundedRectangleBorder(),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.colorBgSub,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: AppTextStyles.textHeadlineSm,
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.colorTextSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.colorBgSub,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // -----------------------------------------------------------------------
      // Lists / Expansion / Divider
      // -----------------------------------------------------------------------
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.colorBgSub,
        iconColor: AppColors.colorTextSecondary,
        textColor: AppColors.colorTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: AppColors.colorBgCard,
        collapsedBackgroundColor: AppColors.colorBgSub,
        iconColor: AppColors.colorAccentTeal,
        collapsedIconColor: AppColors.colorTextSecondary,
        textColor: AppColors.colorTextPrimary,
        collapsedTextColor: AppColors.colorTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.colorDivider,
        thickness: 1,
        space: 1,
      ),

      // -----------------------------------------------------------------------
      // Progress / Switch / Checkbox
      // -----------------------------------------------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.colorAccentTeal,
        linearMinHeight: 4,
        linearTrackColor: AppColors.colorProgressTrack,
        circularTrackColor: AppColors.colorProgressTrack,
      ),

      // -----------------------------------------------------------------------
      // SnackBar (앱 자체 Toast 위젯 사용 — 비활성화 스타일만 정의)
      // -----------------------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.colorBgCard,
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.colorTextPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // -----------------------------------------------------------------------
      // Misc
      // -----------------------------------------------------------------------
      iconTheme: const IconThemeData(
        color: AppColors.colorTextSecondary,
        size: 24,
      ),
      splashColor: AppColors.colorHoverTeal,
      highlightColor: AppColors.colorPressedTeal,
      hoverColor: AppColors.colorHoverTeal,
      focusColor: AppColors.colorHoverTeal,
    );
  }
}
```

---

## 섹션 4. 커스텀 위젯 구현 가이드

### 4-1. GradientButton

`lib/shared/widgets/gradient_button.dart` (**신규 생성**).

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Teal→Indigo 그래디언트 CTA 버튼.
///
/// - 높이 52px, 너비 double.infinity, BorderRadius 16px.
/// - Pressed: AnimatedScale 0.97 / 200ms / Curves.easeInOut.
/// - 비활성: opacity 0.5, 탭 무효.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled && widget.onPressed != null;

    return Opacity(
      opacity: active ? 1.0 : 0.5,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: active ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            height: 52,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.appGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon, size: 18, color: AppColors.colorBgMain),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.textTitleSm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorBgMain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 삭제 등 위험 동작 전용 버튼.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.badgeExpenseBg,
          foregroundColor: AppColors.colorError,
          side: const BorderSide(color: AppColors.colorError),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.textTitleSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: AppColors.colorError),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
```

### 4-2. AppBadge

`lib/shared/widgets/app_badge.dart` (**신규 생성**).

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 거래/자산에 표시되는 배지 종류.
enum BadgeType {
  income,
  expense,
  invest,
  seoulLove,
  firstMeeting,
  point,
  impulse,
  fixed,
}

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.type,
    required this.label,
  });

  final BadgeType type;
  final String label;

  Color get _bg {
    switch (type) {
      case BadgeType.income:
        return AppColors.badgeIncomeBg;
      case BadgeType.expense:
        return AppColors.badgeExpenseBg;
      case BadgeType.invest:
        return AppColors.badgeInvestBg;
      case BadgeType.seoulLove:
        return AppColors.badgeSeoulLoveBg;
      case BadgeType.firstMeeting:
        return AppColors.badgeFirstMeetingBg;
      case BadgeType.point:
        return AppColors.badgePointBg;
      case BadgeType.impulse:
        return AppColors.badgeImpulseBg;
      case BadgeType.fixed:
        return AppColors.badgeFixedBg;
    }
  }

  Color get _fg {
    switch (type) {
      case BadgeType.income:
        return AppColors.badgeIncomeText;
      case BadgeType.expense:
        return AppColors.badgeExpenseText;
      case BadgeType.invest:
        return AppColors.badgeInvestText;
      case BadgeType.seoulLove:
        return AppColors.badgeSeoulLoveText;
      case BadgeType.firstMeeting:
        return AppColors.badgeFirstMeetingText;
      case BadgeType.point:
        return AppColors.badgePointText;
      case BadgeType.impulse:
        return AppColors.badgeImpulseText;
      case BadgeType.fixed:
        return AppColors.badgeFixedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.2,
          color: _fg,
        ),
      ),
    );
  }
}
```

### 4-3. UserAvatar

`lib/shared/widgets/user_avatar.dart` (**신규 생성**).

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 사용자 프로필 아바타.
///
/// - [memberIndex]에 따라 colorUser1~3을 자동 매핑하여 테두리 색으로 사용.
/// - [imagePath]가 있으면 AssetImage, 없으면 이름의 첫 글자 fallback.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.memberIndex,
    this.imagePath,
    this.name,
    this.size = 40,
  });

  final int memberIndex;
  final String? imagePath;
  final String? name;
  final double size;

  Color get _borderColor {
    final List<Color> palette = AppColors.memberColors;
    return palette[memberIndex % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final double inner = size - 4; // 2px 테두리 양쪽

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _borderColor, width: 2),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: imagePath != null
            ? Image.asset(
                imagePath!,
                width: inner,
                height: inner,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Fallback(
                  size: inner,
                  name: name,
                  color: _borderColor,
                ),
              )
            : _Fallback(size: inner, name: name, color: _borderColor),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.size,
    required this.color,
    this.name,
  });

  final double size;
  final Color color;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final String initial =
        (name != null && name!.isNotEmpty) ? name!.characters.first : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: color.withOpacity(0.20),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
```

### 4-4. ThousandsSeparatorInputFormatter

`lib/core/utils/thousands_formatter.dart` (**신규 생성**).

```dart
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 천단위 콤마를 자동으로 삽입하는 TextInputFormatter.
///
/// - 한국 로케일 기반 (#,##0).
/// - 사용자가 입력 중간에 커서를 옮겨도 콤마 위치를 보정합니다.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter();

  static final NumberFormat _formatter = NumberFormat('#,##0', 'ko_KR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 콤마 제거 후 숫자만 추출.
    final String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final int parsed = int.tryParse(digitsOnly) ?? 0;
    final String formatted = _formatter.format(parsed);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
```

> 메모: `intl` 패키지는 이미 Flutter SDK 의존성으로 들어와 있습니다. 만약 import에 실패하면 `flutter pub add intl`로 명시 등록합니다.

---

## 섹션 5. 기존 위젯별 교체 가이드

각 파일에 대한 **핵심 변경점**만 정리합니다 (전체 코드 재작성 불필요, 색·스타일만 교체).

### 5-1. `main_app_bar.dart`

- `backgroundColor`: `AppColors.colorBgMain` (Scaffold 배경과 동일하여 seamless).
- `elevation: 0`, `scrolledUnderElevation: 0`, 하단 구분선 제거.
- `toolbarHeight: 56`.
- 타이틀: `AppTextStyles.textHeadlineMd.copyWith(color: AppColors.colorTextPrimary)`.
- 햄버거/뒤로 아이콘: `IconThemeData(color: AppColors.colorTextSecondary, size: 24)`.

### 5-2. `app_drawer.dart`

- `Drawer.backgroundColor`: `AppColors.colorBgSub`, `elevation: 0`.
- `DrawerHeader`:
  - 높이 180px, `family.png`을 `BoxFit.cover`로 채움.
  - 그래디언트 오버레이는 `AppColors.drawerHeaderOverlay`를 `Stack`으로 위에 얹음.
- 메뉴 ListTile (비활성):
  - 아이콘/텍스트 색: `AppColors.colorTextSecondary`.
  - 폰트: `AppTextStyles.textBodyMd` (14px / w400).
  - 높이 48px (`minVerticalPadding`).
- 메뉴 ListTile (현재 라우트 활성):
  - 아이콘/텍스트 색: `AppColors.colorAccentTeal`.
  - 배경: `Color.fromRGBO(45, 212, 191, 0.08)`.
  - 좌측 3px 인디케이터: `Container(width: 3, color: AppColors.colorAccentTeal)`를 Row 맨 앞에 배치.
- 아코디언 헤더(`ExpansionTile`):
  - `iconColor: AppColors.colorAccentIndigo`.
  - 펼침 시 배경: `AppColors.colorBgCard`.

### 5-3. `date_filter_bar.dart`

- 컨테이너 배경: `AppColors.colorBgSub`, 높이 48px.
- 좌우 화살표: `Icon(Icons.chevron_left/right, color: AppColors.colorAccentTeal, size: 24)`.
- 드롭다운 컨테이너: 배경 `AppColors.colorBgCard`, `BorderRadius.circular(8)`, 텍스트 `AppTextStyles.textLabelMd` (14/w600).
- 새로고침 버튼: `Icon(Icons.refresh, color: AppColors.colorTextSecondary)`.
- 전체 가운데 정렬 (`MainAxisAlignment.center`), 항목 간 8px gap.

### 5-4. `summary_card.dart`

- 기존 GlassCard / BoxDecoration 그림자 효과 **모두 제거**.
- 배경: `AppColors.colorBgSub`, `BorderRadius.circular(16)`, `elevation: 0`.
- 카드 패딩: `EdgeInsets.symmetric(horizontal: 20, vertical: 16)`.
- 카드 간 간격: 8px (`SizedBox(height: 8)`).
- 좌측 아이콘 컨테이너:
  - 50×50 원형, 배경은 의미색별 `colorIconBg*` (15% 불투명).
  - 내부 아이콘: 28px, 의미색.
- 금액: `AppTextStyles.moneyLarge` (32/w700/tabular).
- 항목명 라벨: `AppTextStyles.textCaption` (11/w400, color `colorTextSecondary`).
- 탭 효과: `InkWell(splashColor: AppColors.colorHoverTeal, highlightColor: AppColors.colorPressedTeal)`로 감싸기.

### 5-5. `progress_row.dart`

- `LinearProgressIndicator`:
  - `minHeight: 4`.
  - `borderRadius: BorderRadius.circular(100)` (Flutter 3.10+ 미지원 시 `ClipRRect`로 감싸기).
  - 배경 트랙: `AppColors.colorProgressTrack`.
  - 채움색 분기:
    - 지출 대분류: `AppColors.colorExpense`.
    - 지출 소분류: `AppColors.colorInvest` (주황).
    - 수입: `AppColors.colorIncome`.
    - 투자: `AppColors.colorInvest`.
    - 사용자별: `AppColors.memberColors[memberIndex % length]`.

### 5-6. `app_toast.dart`

- 기존 `ScaffoldMessenger.showSnackBar` 호출은 유지하되, 공통 위젯을 `OverlayEntry` 기반으로 교체.
- 구조: `Stack` → `Positioned(bottom: 32)` → `AnimatedSlide + AnimatedOpacity` → `Container`.
- 컨테이너:
  - 배경 `AppColors.colorBgCard`, `border: Border.all(color: AppColors.colorDivider)`, `BorderRadius.circular(12)`.
  - 패딩 `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`.
- 텍스트: `AppTextStyles.textBodyMd.copyWith(fontWeight: FontWeight.w500)`.
- 출현 애니메이션: 250ms, 사라짐 페이드 300ms, 노출 시간 2000ms.
- 좌측 아이콘 (등록=Icons.check_circle, 수정=Icons.edit, 삭제=Icons.delete) 18px, 색은 의미색.

### 5-7. `app_dialogs.dart`

- `LoadingDialog`:
  - `Stack` 최상위에 `ModalBarrier(color: AppColors.colorLoadingOverlay, dismissible: false)`.
  - 가운데 컨테이너: 배경 `AppColors.colorBgSub`, `BorderRadius.circular(16)`, 패딩 `EdgeInsets.all(32)`.
  - 스피너: `CircularProgressIndicator(color: AppColors.colorAccentTeal, strokeWidth: 3)` 40×40.
- `AlertDialog`:
  - `backgroundColor: AppColors.colorBgSub`, `shape: RoundedRectangleBorder(borderRadius: 16)`.
  - 제목 `AppTextStyles.textHeadlineSm`, 내용 `AppTextStyles.textBodyLg.copyWith(color: AppColors.colorTextSecondary, fontSize: 15)`.
  - 확인 버튼: `TextButton`, 텍스트 `AppTextStyles.textTitleSm.copyWith(color: AppColors.colorAccentTeal, fontWeight: FontWeight.w600)`.

### 5-8. `empty_view.dart`

- `Center` → `Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min)`.
- 아이콘: 64px, color `AppColors.colorDivider`.
- 텍스트: `AppTextStyles.textBodyLg.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.colorTextDisabled)`.

### 5-9. (참고) `transaction_card.dart`

- 카드 배경 `AppColors.colorBgSub`, `BorderRadius.circular(12)`, `elevation: 0`.
- 좌측 `UserAvatar(memberIndex: ...)` 사용.
- 금액: `AppTextStyles.moneySmall`. 포인트 사용 시 원 금액은 `AppTextStyles.moneyStrikethrough`로 옆에 표기.
- 카테고리 텍스트: `AppTextStyles.textBodySm.copyWith(color: AppColors.colorTextSecondary)`.
- 배지 영역: `Wrap(spacing: 4, runSpacing: 4)` + `AppBadge`.

### 5-10. (참고) `floating_action_buttons.dart`

- 추가 FAB: 56px 원형, 배경 `colorAccentTeal`, 아이콘 색 `colorBgMain`, `elevation: 0`.
- 맨 위로 FAB: 44px 원형, 배경 `colorBgCard`, 테두리 1px `colorDivider`, 아이콘 `colorTextSecondary`.
- 표시 조건: `ScrollController.offset > 200`. `AnimatedOpacity(duration: 300ms)`로 토글.
- 두 FAB는 `Column(mainAxisSize: MainAxisSize.min, children: [topFab, SizedBox(8), addFab])` 형태.

---

## 섹션 6. pubspec.yaml 변경 사항

### 6-1. Pretendard 폰트 등록

`assets/fonts/` 디렉토리를 만들고 다음 4개 ttf 파일을 배치합니다 (Pretendard 공식 GitHub `.ttf` 다운로드):

```
assets/fonts/Pretendard-Regular.ttf
assets/fonts/Pretendard-Medium.ttf
assets/fonts/Pretendard-SemiBold.ttf
assets/fonts/Pretendard-Bold.ttf
```

`pubspec.yaml`의 `flutter:` 블록에 다음을 추가합니다.

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/fonts/

  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/Pretendard-Regular.ttf
          weight: 400
        - asset: assets/fonts/Pretendard-Medium.ttf
          weight: 500
        - asset: assets/fonts/Pretendard-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Pretendard-Bold.ttf
          weight: 700
```

### 6-2. 패키지 의존성

추가 또는 유지 결정:

| 패키지 | 결정 | 비고 |
|--------|------|------|
| `google_fonts: ^5.1.0` | **제거 권장** | Pretendard 로컬 등록 후 불필요. 단, 즉시 제거 시 다른 코드 import 영향이 있을 수 있어 Stage 4 첫 마이그레이션 후 제거 |
| `intl` | **추가 필요** | `ThousandsSeparatorInputFormatter`, `NumberFormat`, `DateFormat('yyyy.MM.dd (E)', 'ko_KR')` 사용 |
| `flutter_localizations` | **추가 필요** | `DateFormat`의 `ko_KR` 로케일과 `MaterialApp` localizationsDelegates에 필요 |
| `fl_chart: ^0.66.2` | 유지 | 차트 그래디언트/스택 막대 모두 지원 |

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  cupertino_icons: ^1.0.2
  go_router: ^13.2.0
  dio: ^5.4.0
  fl_chart: ^0.66.2
  json_annotation: ^4.9.0
  intl: ^0.19.0
  # google_fonts는 Pretendard 등록 완료 후 제거
```

`MaterialApp.router`에 한국어 로케일을 등록해야 `DateFormat`의 `'E'` 한국어 요일이 정상 출력됩니다.

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp.router(
  // ...
  localizationsDelegates: const <LocalizationsDelegate<Object>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const <Locale>[Locale('ko', 'KR')],
);
```

추가로 앱 진입점(`main()`)에서 한 번만 다음을 호출:

```dart
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}
```

---

## 섹션 7. 구현 순서 및 주의사항

### 7-1. Stage 4 에이전트 작업 순서 (반드시 이 순서를 따를 것)

1. **`pubspec.yaml`** 수정 → `flutter pub get` 실행.
   - Pretendard ttf 파일 4개 `assets/fonts/`에 배치.
   - `intl`, `flutter_localizations` 추가.
2. **`lib/core/constants/app_colors.dart`** 전체 교체 (섹션 1).
3. **`lib/core/constants/app_text_styles.dart`** 신규 생성 (섹션 2).
4. **`lib/core/theme/app_theme.dart`** 전체 교체 (섹션 3).
5. **`lib/core/utils/thousands_formatter.dart`** 신규 생성 (섹션 4-4).
6. **공통 커스텀 위젯** 신규 생성 (섹션 4):
   - `lib/shared/widgets/gradient_button.dart`
   - `lib/shared/widgets/app_badge.dart`
   - `lib/shared/widgets/user_avatar.dart`
7. **`main.dart`** 수정 — `initializeDateFormatting`, `localizationsDelegates`, `supportedLocales` 적용.
8. **기존 공통 위젯** 교체 (섹션 5의 5-1 ~ 5-10).
9. **페이지 단위** 적용 (홈 → 가계부 목록 → 추가/수정 → 지출 → 수입 → 투자 → 자산 순).
10. 페이지마다 `flutter run -d chrome`으로 시각 검증.

### 7-2. 호환성 유지 핵심 규칙

- `AppColors.divisionColor[Division.income/expense/invest]` Map 키와 시그니처를 **절대 변경하지 않음**.
- `AppColors.primary`, `AppColors.income`, `AppColors.expense`, `AppColors.invest`, `AppColors.netIncome`, `AppColors.investRate`, `AppColors.success`, `AppColors.error`, `AppColors.warning`, `AppColors.background`, `AppColors.surface`, `AppColors.surfaceVariant`, `AppColors.textPrimary`, `AppColors.textSecondary`, `AppColors.textHint`, `AppColors.divider`, `AppColors.border`, `AppColors.memberColors`, `AppColors.assetChartColors`, `AppColors.chartLineColors` 등 **기존 상수명은 유지**하고 값만 새 팔레트로 교체 (섹션 1의 Legacy alias).
- 배지 alias `AppColors.badgeSeoulLove`, `badgeFirstMeeting`, `badgePoint`, `badgeImpulse`, `badgeFixed`도 유지 — `Bg`/`Text` suffix 신규 상수와 병존.

### 7-3. 절대 수정 금지 영역

다음 파일/디렉토리는 UI 마이그레이션 중 **절대 수정하지 않습니다**.

- `**/*_viewmodel.dart`
- `**/*_service.dart`
- `**/*_model.dart`
- `lib/data/**` 하위 데이터 계층 전체
- `lib/core/constants/division.dart` (`Division.income/expense/invest` 값은 ViewModel과 백엔드 통신에 직결)

UI 표시용 색·텍스트만 교체하며, 데이터 흐름·상태 관리·라우팅 키는 그대로 둡니다.

### 7-4. 주요 함정 / 체크리스트

- `withOpacity()`는 **non-const**이므로 const 컨텍스트(예: `static const Color`)에서 사용 불가. 대신 `Color.fromRGBO(r,g,b,a)`를 사용.
- `LinearProgressIndicator`의 `borderRadius` 파라미터는 Flutter 버전에 따라 다름. 안전하게 `ClipRRect(borderRadius: BorderRadius.circular(100), child: LinearProgressIndicator(...))` 패턴 사용 권장.
- `ExpansionTile`의 `backgroundColor`/`collapsedBackgroundColor` 차이를 활용해 펼침 시 배경 톤 변화를 반드시 적용.
- `fl_chart`의 `BarChartRodData.gradient`는 `LinearGradient`를 직접 받습니다. `AppColors.barChartGradient` 상수 그대로 사용 가능.
- Flutter Web 너비 제한: 페이지 루트에서 `Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: ...))` 패턴 적용.
- 탭 영역 최소 44×44px (접근성). FAB·아이콘 버튼은 `IconButton`(기본 48×48) 또는 `SizedBox(width:44,height:44)`로 보장.
- `DateFormat('yyyy.MM.dd (E)', 'ko_KR')` 사용 전에 반드시 `initializeDateFormatting('ko_KR', null)` 호출 필요.

### 7-5. 검증 방법

1. `flutter pub get` 정상 종료.
2. `flutter analyze` 경고 0건 (특히 `prefer_single_quotes`, `avoid_print` 등 `flutter_lints` 규칙 통과).
3. `flutter run -d chrome`으로 웹 실행 → 다음 시각 확인:
   - 모든 페이지 배경이 `#0D1117`로 통일.
   - 카드 배경이 `#161B22`로 elevation 0 평면.
   - SummaryCard의 5개 카드 아이콘이 의미색 15% 불투명 원형 배경.
   - DateFilterBar의 화살표가 Teal `#2DD4BF`로 표시.
   - 거래 카드의 사용자 아바타가 강원=Teal, 정윤=Pink 테두리.
   - 가계부 추가 페이지 등록 버튼이 Teal→Indigo 그래디언트.
   - Drawer를 열었을 때 헤더에 그래디언트 오버레이 + 활성 메뉴에 Teal 좌측 인디케이터.
   - BarChart 막대가 일반=Teal→Indigo 그래디언트, 현재 달=Coral, 평균=회색.
4. Toast/Dialog/Loading 모두 새 색·radius 적용.

---

이 가이드를 그대로 적용하면 기존 ViewModel·Service·Model 코드를 전혀 수정하지 않고 UI 레이어만 Teal Fusion 디자인 시스템으로 교체할 수 있습니다.
