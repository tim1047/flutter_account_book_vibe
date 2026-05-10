import 'dart:ui';

import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Teal Fusion 타이포그래피 스케일.
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Pretendard';

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  // Display
  static const TextStyle textDisplayLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textDisplayMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.colorTextPrimary,
  );

  // Headline
  static const TextStyle textHeadlineLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textHeadlineMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.1,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textHeadlineSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
  );

  // Title
  static const TextStyle textTitleLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textTitleMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textTitleSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.colorTextPrimary,
  );

  // Body
  static const TextStyle textBodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textBodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textBodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.colorTextPrimary,
  );

  // Label / Caption
  static const TextStyle textLabelMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textLabelSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle textCaption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 9,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.colorTextSecondary,
  );

  // Money (tabular figures 필수)
  static const TextStyle moneyDisplay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.colorTextPrimary,
    fontFeatures: _tabular,
  );

  static const TextStyle moneyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.colorTextPrimary,
    fontFeatures: _tabular,
  );

  static const TextStyle moneyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
    fontFeatures: _tabular,
  );

  static const TextStyle moneySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.colorTextPrimary,
    fontFeatures: _tabular,
  );

  static const TextStyle moneyStrikethrough = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.colorTextDisabled,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.colorTextDisabled,
    fontFeatures: _tabular,
  );

  static const TextStyle moneyUnit = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.colorTextSecondary,
  );
}
