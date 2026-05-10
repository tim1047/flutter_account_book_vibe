import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Teal Fusion 다크 테마.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final ThemeData base = ThemeData.dark(useMaterial3: true);

    const ColorScheme colorScheme = ColorScheme.dark(
      primary: AppColors.colorAccentTeal,
      onPrimary: AppColors.colorBgMain,
      secondary: AppColors.colorAccentIndigo,
      onSecondary: AppColors.colorBgMain,
      surface: AppColors.colorBgSub,
      onSurface: AppColors.colorTextPrimary,
      error: AppColors.colorError,
      onError: AppColors.colorBgMain,
      surfaceContainerHighest: AppColors.colorBgCard,
      outline: AppColors.colorDivider,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.colorBgMain,
      colorScheme: colorScheme,

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

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.colorBgMain,
        foregroundColor: AppColors.colorTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
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

      cardTheme: const CardThemeData(
        color: AppColors.colorBgSub,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

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

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.colorAccentTeal,
        foregroundColor: AppColors.colorBgMain,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.colorBgSub,
        elevation: 0,
        shape: RoundedRectangleBorder(),
      ),
      dialogTheme: DialogThemeData(
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

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.colorAccentTeal,
        linearMinHeight: 4,
        linearTrackColor: AppColors.colorProgressTrack,
        circularTrackColor: AppColors.colorProgressTrack,
      ),

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
