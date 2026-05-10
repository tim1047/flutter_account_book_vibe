import 'package:account_book_vibe/core/constants/division.dart';
import 'package:flutter/material.dart';

/// Teal Fusion 디자인 시스템 색상 팔레트.
class AppColors {
  AppColors._();

  // 1. 배경 계층
  static const Color colorBgMain = Color(0xFF0D1117);
  static const Color colorBgSub = Color(0xFF161B22);
  static const Color colorBgCard = Color(0xFF21262D);
  static const Color colorBgElevated = Color(0xFF30363D);

  // 2. 강조색
  static const Color colorAccentTeal = Color(0xFF2DD4BF);
  static const Color colorAccentIndigo = Color(0xFF818CF8);

  // 3. 텍스트 계층
  static const Color colorTextPrimary = Color(0xFFE6EDF3);
  static const Color colorTextSecondary = Color(0xFF8B949E);
  static const Color colorTextDisabled = Color(0xFF484F58);
  static const Color colorDivider = Color(0xFF30363D);

  // 4. 의미색
  static const Color colorIncome = Color(0xFF2DD4BF);
  static const Color colorExpense = Color(0xFFF87171);
  static const Color colorInvest = Color(0xFFFB923C);
  static const Color colorProfit = Color(0xFF4ADE80);
  static const Color colorRate = Color(0xFFFACC15);

  static const Color colorSuccess = Color(0xFF4ADE80);
  static const Color colorError = Color(0xFFF87171);
  static const Color colorWarning = Color(0xFFFACC15);
  static const Color colorInfo = Color(0xFF818CF8);

  // 5. 오버레이 (Color.fromRGBO — const 안전)
  static const Color colorHoverTeal = Color.fromRGBO(45, 212, 191, 0.10);
  static const Color colorPressedTeal = Color.fromRGBO(45, 212, 191, 0.05);
  static const Color colorLoadingOverlay = Color.fromRGBO(13, 17, 23, 0.85);
  static const Color colorProgressTrack = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color colorIconBgIncome = Color.fromRGBO(45, 212, 191, 0.15);
  static const Color colorIconBgExpense = Color.fromRGBO(248, 113, 113, 0.15);
  static const Color colorIconBgInvest = Color.fromRGBO(251, 146, 60, 0.15);
  static const Color colorIconBgProfit = Color.fromRGBO(74, 222, 128, 0.15);
  static const Color colorIconBgRate = Color.fromRGBO(250, 204, 21, 0.15);

  // 6. 배지 색상
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

  // 7. 사용자 구분색
  static const Color colorUser1 = Color(0xFF2DD4BF);
  static const Color colorUser2 = Color(0xFFF472B6);
  static const Color colorUser3 = Color(0xFFFB923C);

  // 8. 차트 색상
  static const List<Color> memberColors = <Color>[
    colorUser1,
    colorUser2,
    colorUser3,
    Color(0xFF818CF8),
  ];

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

  static const List<Color> chartLineColors = <Color>[
    Color(0xFF2DD4BF),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
  ];

  static const Color colorChartAverage = Color(0xFF30363D);
  static const Color colorChartCurrent = Color(0xFFF87171);

  // 9. 그래디언트
  static const LinearGradient appGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[colorAccentTeal, colorAccentIndigo],
  );

  static const LinearGradient barChartGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: <Color>[colorAccentTeal, colorAccentIndigo],
  );

  static const LinearGradient lineChartBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[colorBgMain, colorBgSub],
  );

  static const LinearGradient drawerHeaderOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color.fromRGBO(13, 17, 23, 0.0),
      Color.fromRGBO(13, 17, 23, 0.7),
    ],
  );

  // 10. Legacy alias (기존 코드 호환)
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

  // 10-1. 이상 지출 카드 배경색
  static const Color colorBgAnomalyIncrease = Color(0xFF1A0808);
  static const Color colorBgAnomalyDecrease = Color(0xFF081508);
  static const Color colorBgAnomalyTransaction = Color(0xFF1A1008);

  // 11. Division 매핑 (ViewModel 호환 — 키 변경 금지)
  static const Map<String, Color> divisionColor = <String, Color>{
    Division.income: colorIncome,
    Division.expense: colorExpense,
    Division.invest: colorInvest,
  };

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
