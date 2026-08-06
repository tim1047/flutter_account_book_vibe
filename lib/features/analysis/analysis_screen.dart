import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/data_refresh_bus.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/analysis/division_summary_tab.dart';
import 'package:account_book_vibe/features/analysis/division_summary_viewmodel.dart';
import 'package:account_book_vibe/features/analysis/expense_analysis_tab.dart';
import 'package:account_book_vibe/features/analysis/expense_summary_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/period_selector.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _incomeHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF042F2E), Color(0xFF115E59)],
);

const _investHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF431407), Color(0xFF9A3412)],
);

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late final DashboardPeriodViewModel _period;
  late final ExpenseSummaryViewModel _expenseVm;
  late final DivisionSummaryViewModel _incomeVm;
  late final DivisionSummaryViewModel _investVm;
  late final TabController _tabController;
  bool _periodExpanded = false;

  @override
  void initState() {
    super.initState();
    _period = DashboardPeriodViewModel();
    _period.addListener(_onPeriodChanged);
    _expenseVm = ExpenseSummaryViewModel(_period)..load();
    _incomeVm = DivisionSummaryViewModel(Division.income, _period)..load();
    _investVm = DivisionSummaryViewModel(Division.invest, _period)..load();
    _tabController = TabController(length: 3, vsync: this);
    DataRefreshBus.instance.addListener(_onDataChanged);
  }

  // Reloads this screen's own data in response to a mutation made in any
  // branch (including this one, via DataRefreshBus.instance.notifyDataChanged()).
  void _onDataChanged() {
    if (!mounted) return;
    _reloadAll();
  }

  void _reloadAll() {
    _expenseVm.load();
    _incomeVm.load();
    _investVm.load();
  }

  @override
  void dispose() {
    DataRefreshBus.instance.removeListener(_onDataChanged);
    _period.removeListener(_onPeriodChanged);
    _period.dispose();
    _expenseVm.dispose();
    _incomeVm.dispose();
    _investVm.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 카드 클릭으로 가계부 목록 이동이 가능한 기간(단일 월)인지 여부.
  bool get _canNavigateToList =>
      _period.period == DashboardPeriod.singleMonth ||
      _period.period == DashboardPeriod.thisMonth;

  int get _navYear =>
      _period.period == DashboardPeriod.singleMonth ? _period.selectedYear : DateTime.now().year;
  int get _navMonth =>
      _period.period == DashboardPeriod.singleMonth ? _period.selectedMonth : DateTime.now().month;

  void _onPeriodChanged() {
    setState(() {});
  }

  void _goToAccountList(AccountListExtra extra) {
    context.push('/accountList', extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: MainAppBar(
        showMenuButton: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(88 + (_periodExpanded ? 48 : 0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PeriodSelector(
                  vm: _period,
                  onExpandedChanged: (expanded) => setState(() => _periodExpanded = expanded),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.colorAccentTeal,
                labelColor: AppColors.colorAccentTeal,
                unselectedLabelColor: AppColors.colorTextSecondary,
                labelStyle: AppTextStyles.textBodySm.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.textBodySm,
                tabs: const [Tab(text: '지출'), Tab(text: '수입'), Tab(text: '투자')],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExpenseAnalysisTab(
            vm: _expenseVm,
            onCategoryTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.expense,
                      categoryId: item.categoryId,
                      year: _navYear,
                      month: _navMonth,
                    )),
            onCategorySeqTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.expense,
                      categoryId: item.categoryId,
                      categorySeq: item.categorySeq,
                      year: _navYear,
                      month: _navMonth,
                    )),
            onMemberTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.expense,
                      memberId: item.memberId,
                      year: _navYear,
                      month: _navMonth,
                    )),
          ),
          DivisionSummaryTab(
            vm: _incomeVm,
            title: '총 수입',
            accentColor: AppColors.colorIncome,
            heroGradient: _incomeHeroGradient,
            onCategoryTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.income,
                      categoryId: item.categoryId,
                      year: _navYear,
                      month: _navMonth,
                    )),
          ),
          DivisionSummaryTab(
            vm: _investVm,
            title: '총 투자',
            accentColor: AppColors.colorInvest,
            heroGradient: _investHeroGradient,
            onCategoryTap: !_canNavigateToList
                ? null
                : (item) => _goToAccountList(AccountListExtra(
                      divisionId: Division.invest,
                      categoryId: item.categoryId,
                      year: _navYear,
                      month: _navMonth,
                    )),
          ),
        ],
      ),
      floatingActionButton: GradientFAB(
        heroTag: 'addAccountAnalysis',
        icon: Icons.add,
        onPressed: () async {
          final result = await context.push<String>('/account');
          if (!context.mounted) return;
          DataRefreshBus.instance.notifyDataChanged();
          if (result != null) {
            AppToast.show(context, '$result 완료!!!', type: ToastType.success);
          }
        },
      ),
    );
  }
}
