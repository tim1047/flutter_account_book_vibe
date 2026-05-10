// lib/shared/widgets/category_anomaly_card.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/insight/insight_viewmodel.dart';
import 'package:flutter/material.dart';

class CategoryAnomalyCard extends StatelessWidget {
  const CategoryAnomalyCard({super.key, required this.item});

  final CategoryAnomalyItem item;

  bool get _isIncrease => item.diffRate > 0;

  Color get _accentColor =>
      _isIncrease ? AppColors.colorExpense : AppColors.colorProfit;

  @override
  Widget build(BuildContext context) {
    final pct = (item.diffRate * 100).abs();
    final diffLabel = _isIncrease
        ? '+${pct.toStringAsFixed(0)}%'
        : '−${pct.toStringAsFixed(0)}%';
    final diffAmount = item.currentPrice - item.avgPrice;
    final diffAmountLabel = _isIncrease
        ? '+${FormatUtil.formatPrice(diffAmount)}원'
        : '−${FormatUtil.formatPrice(diffAmount.abs())}원';

    // 진행률 바: 현재 금액 / (평균 × 2), 최대 1.0
    final barValue =
        (item.currentPrice / (item.avgPrice * 2)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _isIncrease
            ? const Color(0xFF1A0808)
            : const Color(0xFF081508),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: _accentColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_isIncrease ? '⚠' : '✓'} ${item.categoryNm} $diffLabel',
                style: AppTextStyles.textBodyMd.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isIncrease ? '증가' : '감소',
                  style: AppTextStyles.textLabelSm
                      .copyWith(color: _accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '이번달 ${FormatUtil.formatPrice(item.currentPrice)}원  ·  평균 ${FormatUtil.formatPrice(item.avgPrice)}원',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: barValue,
            backgroundColor: AppColors.colorProgressTrack,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            borderRadius: BorderRadius.circular(2),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            diffAmountLabel,
            style: AppTextStyles.textLabelSm.copyWith(
              color: AppColors.colorTextDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
