import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/category_emojis.dart';
import 'package:account_book_vibe/core/constants/member.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/analysis/division_summary_content.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/analysis/expense_summary_data.dart';
import 'package:account_book_vibe/features/analysis/expense_summary_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/progress_row.dart';
import 'package:account_book_vibe/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

const _expenseHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4C0519), Color(0xFF7F1D1D)],
);

class ExpenseAnalysisTab extends StatelessWidget {
  const ExpenseAnalysisTab({
    super.key,
    required this.vm,
    this.onCategoryTap,
    this.onCategorySeqTap,
    this.onMemberTap,
  });

  final ExpenseSummaryViewModel vm;
  final void Function(DivisionCategoryItem item)? onCategoryTap;
  final void Function(ExpenseCategorySeqItem item)? onCategorySeqTap;
  final void Function(ExpenseMemberItem item)? onMemberTap;

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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DivisionSummaryContent(
              data: data.summary,
              title: '총 지출',
              accentColor: AppColors.colorExpense,
              heroGradient: _expenseHeroGradient,
              onCategoryTap: onCategoryTap,
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '카테고리 상세',
              child: Column(
                children: data.categorySeqBreakdown
                    .map((e) => _CategorySeqRow(item: e, onTap: onCategorySeqTap))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '주체별 지출',
              child: Column(
                children: data.memberBreakdown
                    .asMap()
                    .entries
                    .map((entry) => _MemberRow(
                          item: entry.value,
                          colorIndex: entry.key,
                          onTap: onMemberTap,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '최대 단건 지출 TOP 10',
              child: Column(
                children: data.topTransactions
                    .map((tx) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              UserAvatar(
                                memberIndex: tx.memberId.codeUnits.fold(0, (a, b) => a + b) %
                                    AppColors.memberColors.length,
                                imagePath: Member.images[tx.memberId],
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
                                          tx.categoryNm, tx.categorySeqNm, remark: tx.remark),
                                      style: AppTextStyles.textBodySm
                                          .copyWith(color: AppColors.colorTextPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      FormatUtil.formatDateShort(tx.accountDt),
                                      style: AppTextStyles.textCaption
                                          .copyWith(color: AppColors.colorTextDisabled),
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
      },
    );
  }
}

class _CategorySeqRow extends StatelessWidget {
  const _CategorySeqRow({required this.item, this.onTap});

  final ExpenseCategorySeqItem item;
  final void Function(ExpenseCategorySeqItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    final changeRate = item.changeRate;
    final hasChange = item.prevPeriodAmount > 0;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Row(
              children: [
                Text(CategoryEmojis.getEmoji(item.categoryNm), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.categorySeqNm,
                          style: AppTextStyles.textBodySm.copyWith(color: AppColors.colorTextPrimary)),
                      Text(item.categoryNm,
                          style: AppTextStyles.textCaption.copyWith(color: AppColors.colorTextDisabled)),
                    ],
                  ),
                ),
                if (hasChange)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        changeRate >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 16,
                        color: changeRate >= 0 ? AppColors.colorExpense : AppColors.colorProfit,
                      ),
                      Text(
                        '${(changeRate.abs() * 100).toStringAsFixed(1)}%',
                        style: AppTextStyles.textBodySm.copyWith(
                          color: changeRate >= 0 ? AppColors.colorExpense : AppColors.colorProfit,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                Text(
                  '₩${FormatUtil.formatPrice(item.amount)}',
                  style: AppTextStyles.textBodySm
                      .copyWith(color: AppColors.colorTextPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: item.ratio.clamp(0.0, 1.0),
                backgroundColor: AppColors.colorBgElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.colorExpense),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.item, required this.colorIndex, this.onTap});

  final ExpenseMemberItem item;
  final int colorIndex;
  final void Function(ExpenseMemberItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.memberColors[colorIndex % AppColors.memberColors.length];
    final memberIndex =
        item.memberId.codeUnits.fold(0, (a, b) => a + b) % AppColors.memberColors.length;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(item),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            UserAvatar(
              memberIndex: memberIndex,
              imagePath: Member.images[item.memberId],
              name: item.memberNm,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProgressRow(
                label: item.memberNm,
                value: '₩${FormatUtil.formatPrice(item.amount)} (${(item.ratio * 100).toStringAsFixed(1)}%)',
                percentage: item.ratio,
                color: color,
              ),
            ),
          ],
        ),
      ),
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
      decoration: BoxDecoration(color: AppColors.colorBgCard, borderRadius: BorderRadius.circular(12)),
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
