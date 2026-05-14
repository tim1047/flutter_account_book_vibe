import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/category_emojis.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/hero_metric_card.dart';
import 'package:account_book_vibe/features/dashboard/widgets/mini_bar_row.dart';
import 'package:account_book_vibe/features/dashboard/widgets/net_worth_line_chart.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.vm});

  final DashboardOverviewViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.colorAccentTeal),
          );
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return _OverviewContent(data: data);
      },
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.data});

  final DashboardOverviewData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ① 순자산 히어로
        HeroMetricCard(
          title: '순자산 (Net Worth)',
          amount: data.netWorth,
          changeAmount: data.netWorthChange,
          changeLabel: '전월 대비',
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF312E81), Color(0xFF1E3A5F)],
          ),
        ),
        const SizedBox(height: 12),

        // ② 수지 + 투자 요약 2컬럼
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: '이번 달 수지',
                rows: [
                  ('수입', data.totalIncome, AppColors.colorIncome),
                  ('지출', data.totalExpense, AppColors.colorExpense),
                  ('저축', data.savings, AppColors.colorProfit),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: '투자 현황',
                rows: [
                  ('이번 기간', data.totalInvest, AppColors.colorInvest),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ③ 순자산 변화 차트
        _SectionCard(
          title: '순자산 변화',
          child: NetWorthLineChart(history: data.netWorthHistory),
        ),
        const SizedBox(height: 12),

        // ④ 지출 TOP 5
        _SectionCard(
          title: '지출 TOP 5 카테고리',
          child: Column(
            children: data.topExpenseCategories.map((e) {
              final emoji = CategoryEmojis.forCategory(e.categoryNm);
              return MiniBarRow(
                label: '$emoji ${e.categoryNm}',
                amount: e.amount,
                ratio: e.ratio,
                color: AppColors.colorExpense,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ⑤ 최근 거래
        _SectionCard(
          title: '최근 거래',
          trailing: TextButton(
            onPressed: () => context.go('/accountList'),
            child: Text(
              '더보기',
              style: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorAccentTeal,
              ),
            ),
          ),
          child: Column(
            children: data.recentTransactions.map((tx) {
              final isExpense = tx.divisionId == '3';
              final color =
                  isExpense ? AppColors.colorExpense : AppColors.colorIncome;
              final sign = isExpense ? '-' : '+';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        FormatUtil.formatCategoryDesc(
                            tx.categoryNm, tx.categorySeqNm, tx.remark),
                        style: AppTextStyles.textBodySm.copyWith(
                          color: AppColors.colorTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$sign₩${FormatUtil.formatPrice(tx.price)}',
                      style: AppTextStyles.textBodySm.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.textBodySm.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.rows});

  final String title;
  final List<(String, int, Color)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.textBodyXs.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.$1,
                      style: AppTextStyles.textBodySm.copyWith(
                        color: AppColors.colorTextSecondary,
                      ),
                    ),
                    Text(
                      '₩${FormatUtil.formatPrice(r.$2)}',
                      style: AppTextStyles.textBodySm.copyWith(
                        color: r.$3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
