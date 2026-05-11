// lib/shared/widgets/transaction_anomaly_card.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/insight/insight_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TransactionAnomalyCard extends StatelessWidget {
  const TransactionAnomalyCard({super.key, required this.item});

  final TransactionAnomalyItem item;

  Color get _accentColor =>
      item.multiple >= 4.0 ? AppColors.colorExpense : AppColors.colorInvest;

  @override
  Widget build(BuildContext context) {
    final tx = item.account;
    final dateStr = FormatUtil.formatDateKorean(tx.accountDt);
    final desc =
        tx.remark?.isNotEmpty == true ? tx.remark! : tx.categorySeqNm;

    return GestureDetector(
      onTap: () => context.go('/account', extra: tx),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.colorBgAnomalyTransaction,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: _accentColor, width: 3),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tx.categorySeqNm}  ·  $dateStr',
                    style: AppTextStyles.textBodyMd.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$desc  ·  ${FormatUtil.formatPrice(tx.price)}원',
                    style: AppTextStyles.textBodySm.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '카테고리 상세 평균 단가 ${FormatUtil.formatPrice(item.categoryAvgPrice)}원',
                    style: AppTextStyles.textLabelSm.copyWith(
                      color: AppColors.colorTextDisabled,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item.multiple.toStringAsFixed(1)}배',
                style: AppTextStyles.textLabelMd.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
