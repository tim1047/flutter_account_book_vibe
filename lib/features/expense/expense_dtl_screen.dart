import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/category_emojis.dart';
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
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

class ExpenseDtlScreen extends StatefulWidget {
  const ExpenseDtlScreen({super.key});

  @override
  State<ExpenseDtlScreen> createState() => _ExpenseDtlScreenState();
}

class _ExpenseDtlScreenState extends State<ExpenseDtlScreen> {
  late final ExpenseViewModel _vm;
  late final DateFilterViewModel _dateFilter;

  @override
  void initState() {
    super.initState();
    _vm = ExpenseViewModel();
    _dateFilter = DateFilterViewModel();
    _load();
  }

  void _load() =>
      _vm.loadCategorySeqSum(_dateFilter.strtDt, _dateFilter.endDt);

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
                    if (_vm.categorySeqSumList.isEmpty) {
                      return const EmptyView();
                    }
                    return _buildList();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: _vm.categorySeqSumList.length,
      itemBuilder: (context, index) {
        final item = _vm.categorySeqSumList[index];
        final pct =
            FormatUtil.percentageOf(item.sumPrice, item.totalSumPrice) / 100;
        final pctStr = FormatUtil.formatPercentage(
          FormatUtil.percentageOf(item.sumPrice, item.totalSumPrice),
        );
        return Card(
          elevation: 0,
          color: AppColors.colorBgSub,
          margin: const EdgeInsets.only(bottom: 6),
          child: ProgressRow(
            emoji: CategoryEmojis.getEmoji(item.categoryNm),
            label: FormatUtil.formatCategoryDesc(
                item.categoryNm, item.categorySeqNm, null),
            value: '${FormatUtil.formatPrice(item.sumPrice)}원 ($pctStr)',
            percentage: pct,
            color: AppColors.colorIncome,
            badge: item.fixedPriceYn == 'Y' ? '고정지출' : null,
            badgeColor: AppColors.badgeFixed,
            onTap: () => context.push(
              '/accountList',
              extra: AccountListExtra(
                divisionId: Division.expense,
                categoryId: item.categoryId,
                categorySeq: item.categorySeq,
              ),
            ),
          ),
        );
      },
    );
  }
}
