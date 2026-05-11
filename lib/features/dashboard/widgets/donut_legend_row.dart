import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/material.dart';

class DonutLegendRow extends StatelessWidget {
  const DonutLegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.amount,
    required this.ratio,
    this.trailing,
  });

  final Color color;
  final String label;
  final int amount;
  final double ratio;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
          ),
          Text(
            '${(ratio * 100).toStringAsFixed(1)}%',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₩ ${FormatUtil.formatPrice(amount)}',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
