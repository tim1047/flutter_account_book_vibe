import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/constants/member.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/member_model.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/expense/expense_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/progress_row.dart';
import 'package:account_book_vibe/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExpenseMemberScreen extends StatefulWidget {
  const ExpenseMemberScreen({super.key});

  @override
  State<ExpenseMemberScreen> createState() => _ExpenseMemberScreenState();
}

class _ExpenseMemberScreenState extends State<ExpenseMemberScreen> {
  late final ExpenseViewModel _vm;
  late final DateFilterViewModel _dateFilter;

  @override
  void initState() {
    super.initState();
    _vm = ExpenseViewModel();
    _dateFilter = DateFilterViewModel();
    _load();
  }

  void _load() => _vm.loadMemberSum(_dateFilter.strtDt, _dateFilter.endDt);

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
                    if (_vm.memberSumList.isEmpty) {
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
    final total = _vm.memberSumList.fold(0, (sum, m) => sum + m.sumPrice);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: _vm.memberSumList.length,
      itemBuilder: (context, index) {
        final item = _vm.memberSumList[index];
        final color =
            AppColors.memberColors[index % AppColors.memberColors.length];
        final pct = FormatUtil.percentageOf(item.sumPrice, total) / 100;
        final pctStr =
            FormatUtil.formatPercentage(FormatUtil.percentageOf(item.sumPrice, total));
        final memberIndex =
            item.memberId.codeUnits.fold(0, (a, b) => a + b) %
                AppColors.memberColors.length;
        return Card(
          elevation: 0,
          color: AppColors.colorBgSub,
          margin: const EdgeInsets.only(bottom: 6),
          child: _MemberRow(
            item: item,
            color: color,
            memberIndex: memberIndex,
            pct: pct,
            pctStr: pctStr,
            onTap: () => context.push(
              '/accountList',
              extra: AccountListExtra(
                divisionId: Division.expense,
                memberId: item.memberId,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Member Row ────────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.item,
    required this.color,
    required this.memberIndex,
    required this.pct,
    required this.pctStr,
    required this.onTap,
  });

  final MemberSumResponse item;
  final Color color;
  final int memberIndex;
  final double pct;
  final String pctStr;
  final VoidCallback onTap;

  String? get _imagePath => Member.images[item.memberId];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            UserAvatar(
              memberIndex: memberIndex,
              imagePath: _imagePath,
              name: item.memberNm,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProgressRow(
                label: item.memberNm,
                value: '${FormatUtil.formatPrice(item.sumPrice)}원 ($pctStr)',
                percentage: pct,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
