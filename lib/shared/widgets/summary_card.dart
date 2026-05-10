import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/shared/widgets/emoji_icon.dart';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final String emoji;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  Color _iconBg() {
    if (color == AppColors.colorIncome) return AppColors.colorIconBgIncome;
    if (color == AppColors.colorExpense) return AppColors.colorIconBgExpense;
    if (color == AppColors.colorInvest) return AppColors.colorIconBgInvest;
    if (color == AppColors.colorProfit) return AppColors.colorIconBgProfit;
    if (color == AppColors.colorRate) return AppColors.colorIconBgRate;
    return Color.fromRGBO(color.red, color.green, color.blue, 0.15);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.colorBgSub,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.colorHoverTeal,
        highlightColor: AppColors.colorPressedTeal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              EmojiIcon(
                emoji: emoji,
                backgroundColor: _iconBg(),
                size: 50,
                fontSize: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: AppTextStyles.moneyMedium),
                    const SizedBox(height: 2),
                    Text(label, style: AppTextStyles.textCaption),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.colorTextDisabled,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
