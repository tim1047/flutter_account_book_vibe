import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message = '데이터가 없습니다.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: AppColors.colorDivider,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.textBodyLg.copyWith(
              color: AppColors.colorTextDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
