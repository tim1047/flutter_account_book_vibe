import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/category_emojis.dart';
import 'package:account_book_vibe/core/constants/member_images.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/expense_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/donut_legend_row.dart';
import 'package:account_book_vibe/features/dashboard/widgets/monthly_bar_chart.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/user_avatar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpenseTab extends StatelessWidget {
  const ExpenseTab({super.key, required this.vm});

  final DashboardExpenseViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.colorExpense),
          );
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return _ExpenseContent(data: data);
      },
    );
  }
}

class _ExpenseContent extends StatelessWidget {
  const _ExpenseContent({required this.data});

  final DashboardExpenseData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ① 총 지출 헤더
        _ExpenseHeroCard(data: data),
        const SizedBox(height: 12),

        // ② 카테고리 도넛 차트
        _SectionCard(
          title: '카테고리별 비중',
          child: _DonutSection(data: data),
        ),
        const SizedBox(height: 12),

        // ③ 월별 지출 바 차트
        _SectionCard(
          title: '월별 지출 추이',
          child: MonthlyBarChart(
            data: data.monthlyExpenses,
            barColor: AppColors.colorExpense,
          ),
        ),
        const SizedBox(height: 12),

        // ④ 카테고리 상세 리스트
        _SectionCard(
          title: '카테고리 상세',
          child: Column(
            children: data.categoryBreakdown.map((e) {
              final changeRate = e.changeRate;
              final hasChange = e.prevPeriodAmount > 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          CategoryEmojis.getEmoji(e.categoryNm),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.categoryNm,
                            style: AppTextStyles.textBodySm.copyWith(
                              color: AppColors.colorTextPrimary,
                            ),
                          ),
                        ),
                        if (hasChange)
                          Text(
                            changeRate >= 0
                                ? '▲${(changeRate * 100).toStringAsFixed(1)}%'
                                : '▼${(changeRate.abs() * 100).toStringAsFixed(1)}%',
                            style: AppTextStyles.textBodySm.copyWith(
                              color: changeRate >= 0
                                  ? AppColors.colorExpense
                                  : AppColors.colorProfit,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          '₩${FormatUtil.formatPrice(e.amount)}',
                          style: AppTextStyles.textBodySm.copyWith(
                            color: AppColors.colorTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: e.ratio.clamp(0.0, 1.0),
                        backgroundColor: AppColors.colorBgElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.colorExpense,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ⑤ 최대 단건 지출 TOP 10
        _SectionCard(
          title: '최대 단건 지출 TOP 10',
          child: Column(
            children: data.topTransactions
                .map((tx) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          UserAvatar(
                            memberIndex:
                                tx.memberId.codeUnits.fold(0, (a, b) => a + b) %
                                    AppColors.memberColors.length,
                            imagePath: MemberImages.paths[tx.memberNm],
                            name: tx.memberNm,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FormatUtil.formatCategoryDesc(
                                      tx.categoryNm, tx.categorySeqNm,
                                      remark: tx.remark),
                                  style: AppTextStyles.textBodySm.copyWith(
                                    color: AppColors.colorTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  FormatUtil.formatDateShort(tx.accountDt),
                                  style: AppTextStyles.textCaption.copyWith(
                                    color: AppColors.colorTextDisabled,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '-₩${FormatUtil.formatPrice(tx.price)}',
                            style: AppTextStyles.textBodySm.copyWith(
                              color: AppColors.colorExpense,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ExpenseHeroCard extends StatelessWidget {
  const _ExpenseHeroCard({required this.data});
  final DashboardExpenseData data;

  @override
  Widget build(BuildContext context) {
    final change = data.changeRate;
    final isIncrease = change >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C0519), Color(0xFF7F1D1D)],
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
            '총 지출',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₩ ${FormatUtil.formatPrice(data.totalExpense)}',
            style: AppTextStyles.textHeadingLg.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color:
                    isIncrease ? AppColors.colorExpense : AppColors.colorProfit,
              ),
              Text(
                '${(change.abs() * 100).toStringAsFixed(1)}% ${data.changeLabel}',
                style: AppTextStyles.textBodySm.copyWith(
                  color: isIncrease
                      ? AppColors.colorExpense
                      : AppColors.colorProfit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutSection extends StatelessWidget {
  const _DonutSection({required this.data});
  final DashboardExpenseData data;

  static const _colors = AppColors.assetChartColors;

  @override
  Widget build(BuildContext context) {
    if (data.categoryBreakdown.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text('데이터 없음')),
      );
    }
    final sections = data.categoryBreakdown.asMap().entries.map((e) {
      final color = _colors[e.key % _colors.length];
      return PieChartSectionData(
        value: e.value.ratio,
        color: color,
        radius: 40,
        title: '',
      );
    }).toList();

    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 22,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: data.categoryBreakdown.asMap().entries.map((e) {
              final color = _colors[e.key % _colors.length];
              return DonutLegendRow(
                color: color,
                label: e.value.categoryNm,
                amount: e.value.amount,
                ratio: e.value.ratio,
              );
            }).toList(),
          ),
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
          Text(
            title,
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
