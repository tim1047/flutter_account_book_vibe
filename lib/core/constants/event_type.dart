import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 일정 유형. 서버 `GET /event/type`은 아래 4종 고정이고 색상도 내려주지 않아서
/// 호출하지 않고 상수로 들고 있는다. 순서는 서버 `sortOrd`와 동일.
class EventType {
  EventType._();

  static const String vacation = 'VACATION';
  static const String holiday = 'HOLIDAY';
  static const String anniversary = 'ANNIVERSARY';
  static const String schedule = 'SCHEDULE';

  static const List<String> all = <String>[
    vacation,
    holiday,
    anniversary,
    schedule,
  ];

  static const Map<String, String> names = <String, String>{
    vacation: '휴가',
    holiday: '공휴일',
    anniversary: '기념일',
    schedule: '일정',
  };

  static const Map<String, Color> colors = <String, Color>{
    vacation: AppColors.colorAccentTeal,
    holiday: AppColors.colorError,
    anniversary: AppColors.colorUser2,
    schedule: AppColors.colorAccentIndigo,
  };

  static String nameOf(String code) => names[code] ?? code;

  static Color colorOf(String code) =>
      colors[code] ?? AppColors.colorTextSecondary;
}
