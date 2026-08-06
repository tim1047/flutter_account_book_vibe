import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/category_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/dashboard/widgets/category_legend_row.dart';
import 'package:account_book_vibe/features/dashboard/widgets/category_share_bar.dart';
import 'package:account_book_vibe/features/dashboard/widgets/monthly_bar_chart.dart';
import 'package:flutter/material.dart';

/// 지출/수입/투자 공통 3섹션(총액/카테고리 비중/월별 추이). 스크롤을 갖지 않으므로
/// 호출부가 ListView 등으로 감싸야 한다.
class DivisionSummaryContent extends StatelessWidget {
  const DivisionSummaryContent({
    super.key,
    required this.data,
    required this.title,
    required this.accentColor,
    required this.heroGradient,
    this.onCategoryTap,
  });

  final DivisionSummaryData data;
  final String title;
  final Color accentColor;
  final Gradient heroGradient;
  final void Function(DivisionCategoryItem item)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroCard(data: data, title: title, gradient: heroGradient, accentColor: accentColor),
        const SizedBox(height: 12),
        _SectionCard(
          title: '카테고리별 비중',
          child: _CategoryShareSection(data: data, onTap: onCategoryTap),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '월별 추이',
          child: MonthlyBarChart(
            data: data.monthlyAmounts,
            barColor: accentColor,
            highlightMonth: data.chartHighlightMonth,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.data,
    required this.title,
    required this.gradient,
    required this.accentColor,
  });

  final DivisionSummaryData data;
  final String title;
  final Gradient gradient;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final change = data.changeRate;
    final isIncrease = change >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
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
            style: AppTextStyles.textBodySm.copyWith(color: AppColors.colorTextSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            '₩ ${FormatUtil.formatPrice(data.totalAmount)}',
            style: AppTextStyles.textHeadingLg.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 14,
                color: isIncrease ? accentColor : AppColors.colorProfit,
              ),
              Text(
                '${(change.abs() * 100).toStringAsFixed(1)}% ${data.changeLabel}',
                style: AppTextStyles.textBodySm.copyWith(
                  color: isIncrease ? accentColor : AppColors.colorProfit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryShareSection extends StatelessWidget {
  const _CategoryShareSection({required this.data, this.onTap});

  final DivisionSummaryData data;
  final void Function(DivisionCategoryItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    if (data.categoryBreakdown.isEmpty) {
      return const SizedBox(height: 60, child: Center(child: Text('데이터 없음')));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryShareBar(
          segments: data.categoryBreakdown
              .map((e) => (color: CategoryColors.of(e.categoryId), ratio: e.ratio))
              .toList(),
        ),
        const SizedBox(height: 12),
        Column(
          children: data.categoryBreakdown.map((e) {
            final row = CategoryLegendRow(
              color: CategoryColors.of(e.categoryId),
              label: e.categoryNm,
              amount: e.amount,
              ratio: e.ratio,
            );
            if (onTap == null) return row;
            return InkWell(onTap: () => onTap!(e), child: row);
          }).toList(),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.textBodySm.copyWith(color: AppColors.colorTextSecondary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
