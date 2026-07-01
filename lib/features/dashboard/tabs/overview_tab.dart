import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/category_emojis.dart';
import 'package:account_book_vibe/core/constants/member_images.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/hero_metric_card.dart';
import 'package:account_book_vibe/features/dashboard/widgets/mini_bar_row.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/user_avatar.dart';
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
        // ① 수입/지출/저축/투자
        HeroMetricCard(
          title: '수입',
          amount: data.totalIncome,
          changeAmount: data.incomeChange,
          changeLabel: data.changeLabel,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF042F2E), Color(0xFF115E59)],
          ),
        ),
        const SizedBox(height: 12),
        HeroMetricCard(
          title: '지출',
          amount: data.totalExpense,
          changeAmount: data.expenseChange,
          changeLabel: data.changeLabel,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4C0519), Color(0xFF7F1D1D)],
          ),
        ),
        const SizedBox(height: 12),
        HeroMetricCard(
          title: '저축',
          amount: data.savings,
          changeAmount: data.savingsChange,
          changeLabel: data.changeLabel,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF052E16), Color(0xFF166534)],
          ),
        ),
        const SizedBox(height: 12),
        HeroMetricCard(
          title: '투자',
          amount: data.totalInvest,
          changeAmount: data.investChange,
          changeLabel: data.changeLabel,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF431407), Color(0xFF9A3412)],
          ),
        ),
        const SizedBox(height: 16),

        // ② 지출 TOP 5
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

        // ③ 최근 거래
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
