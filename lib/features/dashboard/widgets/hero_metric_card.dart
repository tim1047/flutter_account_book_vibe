import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/material.dart';

class HeroMetricCard extends StatelessWidget {
  const HeroMetricCard({
    super.key,
    required this.title,
    required this.amount,
    this.changeAmount,
    this.changeLabel,
    this.gradient,
    this.subtitle,
  });

  final String title;
  final int amount;
  final int? changeAmount;
  final String? changeLabel;
  final LinearGradient? gradient;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final change = changeAmount;
    final isPositive = change != null && change >= 0;
    final changeColor =
        isPositive ? AppColors.colorSuccess : AppColors.colorExpense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D2D50), Color(0xFF133B5C)],
            ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₩ ${FormatUtil.formatPrice(amount)}',
            style: AppTextStyles.textHeadingLg.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
          ],
          if (change != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${changeLabel ?? ''} ',
                  style: AppTextStyles.textBodySm.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                Icon(
                  isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: changeColor,
                  size: 14,
                ),
                Text(
                  '₩ ${FormatUtil.formatPrice(change.abs())}',
                  style: AppTextStyles.textBodySm.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
