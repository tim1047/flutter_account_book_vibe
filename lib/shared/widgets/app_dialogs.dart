import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppAlertDialog {
  static Future<void> show(
    BuildContext context, {
    required String message,
    String title = '알림',
    String confirmText = '확인',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.colorBgSub,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Text(title, style: AppTextStyles.textHeadlineSm),
        content: Text(
          message,
          style: AppTextStyles.textBodyLg.copyWith(
            color: AppColors.colorTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              confirmText,
              style: AppTextStyles.textTitleSm.copyWith(
                color: AppColors.colorAccentTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String message,
    String title = '확인',
    String confirmText = '확인',
    String cancelText = '취소',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.colorBgSub,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Text(title, style: AppTextStyles.textHeadlineSm),
        content: Text(
          message,
          style: AppTextStyles.textBodyLg.copyWith(
            color: AppColors.colorTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: AppTextStyles.textTitleSm.copyWith(
                color: AppColors.colorTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: AppTextStyles.textTitleSm.copyWith(
                color: AppColors.colorError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class AppLoadingDialog {
  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.colorLoadingOverlay,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: _LoadingContent(),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppColors.colorBgSub,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          color: AppColors.colorAccentTeal,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
