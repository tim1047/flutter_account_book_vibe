import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/material.dart';

const _tabularFigures = [FontFeature.tabularFigures()];

class CategoryLegendRow extends StatelessWidget {
  const CategoryLegendRow({
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
          SizedBox(
            width: 92,
            child: Text(
              '₩ ${FormatUtil.formatPrice(amount)}',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorTextPrimary,
                fontWeight: FontWeight.w500,
                fontFeatures: _tabularFigures,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            child: Text(
              '${(ratio * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorTextSecondary,
                fontFeatures: _tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
