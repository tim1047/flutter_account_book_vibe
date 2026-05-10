import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/category_emojis.dart';
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/expense/expense_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/progress_row.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExpenseCategoryScreen extends StatefulWidget {
  const ExpenseCategoryScreen({super.key});

  @override
  State<ExpenseCategoryScreen> createState() => _ExpenseCategoryScreenState();
}

class _ExpenseCategoryScreenState extends State<ExpenseCategoryScreen> {
  late final ExpenseViewModel _vm;
  late final DateFilterViewModel _dateFilter;

  @override
  void initState() {
    super.initState();
    _vm = ExpenseViewModel();
    _dateFilter = DateFilterViewModel();
    _load();
  }

  void _load() => _vm.loadCategorySum(_dateFilter.strtDt, _dateFilter.endDt);

  @override
  void dispose() {
    _vm.dispose();
    _dateFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              DateFilterBar(viewModel: _dateFilter, onRefresh: _load),
              Expanded(
                child: ListenableBuilder(
                  listenable: _vm,
                  builder: (context, _) {
                    if (_vm.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.colorAccentTeal,
                        ),
                      );
                    }
                    if (_vm.errorMessage != null) {
                      return ErrorView(
                        message: _vm.errorMessage!,
                        onRetry: _load,
                      );
                    }
                    if (_vm.categorySumList.isEmpty) {
                      return const EmptyView();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _vm.categorySumList.length,
                      itemBuilder: (context, index) {
                        final item = _vm.categorySumList[index];
                        return _CategoryTile(
                          item: item,
                          onSeqTap: (categorySeq) => context.push(
                            '/accountList',
                            extra: AccountListExtra(
                              divisionId: Division.expense,
                              categoryId: item.categoryId,
                              categorySeq: categorySeq,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.onSeqTap});

  final CategorySumResponse item;
  final void Function(String categorySeq) onSeqTap;

  double get _catPct =>
      FormatUtil.percentageOf(item.sumPrice, item.totalSumPrice) / 100;

  String get _catPctStr => FormatUtil.formatPercentage(
        FormatUtil.percentageOf(item.sumPrice, item.totalSumPrice),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: AppColors.colorBgSub,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Text(
            CategoryEmojis.getEmoji(item.categoryNm),
            style: const TextStyle(fontSize: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.categoryNm,
                  style: AppTextStyles.textBodyMd,
                ),
              ),
              Text(
                '${FormatUtil.formatPrice(item.sumPrice)}원  $_catPctStr',
                style: AppTextStyles.textBodySm.copyWith(
                  color: AppColors.colorExpense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: _catPct,
                color: AppColors.colorExpense,
                backgroundColor: AppColors.colorProgressTrack,
                minHeight: 4,
              ),
            ),
          ),
          children: item.data.map((seq) {
            final seqPct =
                FormatUtil.percentageOf(seq.sumPrice, item.sumPrice) / 100;
            final seqPctStr = FormatUtil.formatPercentage(
              FormatUtil.percentageOf(seq.sumPrice, item.sumPrice),
            );
            return ProgressRow(
              emoji: CategoryEmojis.getEmoji(seq.categorySeqNm),
              label: seq.categorySeqNm,
              value: '${FormatUtil.formatPrice(seq.sumPrice)}원 ($seqPctStr)',
              percentage: seqPct,
              color: AppColors.colorAccentTeal,
              onTap: () => onSeqTap(seq.categorySeq),
            );
          }).toList(),
        ),
      ),
    );
  }
}
