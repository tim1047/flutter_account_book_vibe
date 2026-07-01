import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_shared_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/tabs/asset_tab.dart';
import 'package:account_book_vibe/features/dashboard/tabs/expense_tab.dart';
import 'package:account_book_vibe/features/dashboard/tabs/overview_tab.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/expense_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/period_selector.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final DashboardPeriodViewModel _period;
  late final DashboardSharedViewModel _shared;
  late final DashboardOverviewViewModel _overviewVm;
  late final DashboardExpenseViewModel _expenseVm;
  late final DashboardAssetViewModel _assetVm;
  late final CalendarSummaryViewModel _calendarVm;
  late final TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _period = DashboardPeriodViewModel();
    _shared = DashboardSharedViewModel(_period)..load();
    _overviewVm = DashboardOverviewViewModel(_shared)..load();
    _expenseVm = DashboardExpenseViewModel(_shared)..load();
    _assetVm = DashboardAssetViewModel()..load();
    _calendarVm = CalendarSummaryViewModel()..load();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index != _currentIndex) {
      _currentIndex = _tabController.index;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _period.dispose();
    _shared.dispose();
    _overviewVm.dispose();
    _expenseVm.dispose();
    _assetVm.dispose();
    _calendarVm.dispose();
    _tabController.dispose();
    super.dispose();
  }

  static const int _assetTabIndex = 2;
  bool get _isAssetTab => _tabController.index == _assetTabIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      drawer: const AppDrawer(),
      appBar: MainAppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isAssetTab ? 44 : 88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isAssetTab)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PeriodSelector(vm: _period),
                ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.colorAccentTeal,
                labelColor: AppColors.colorAccentTeal,
                unselectedLabelColor: AppColors.colorTextSecondary,
                labelStyle: AppTextStyles.textBodySm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTextStyles.textBodySm,
                tabs: const [
                  Tab(text: '개요'),
                  Tab(text: '지출'),
                  Tab(text: '자산'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(vm: _overviewVm, calendarVm: _calendarVm),
          ExpenseTab(vm: _expenseVm),
          AssetTab(vm: _assetVm),
        ],
      ),
      floatingActionButton: GradientFAB(
        heroTag: 'addAccount',
        icon: Icons.add,
        onPressed: () async {
          final result = await context.push<String>('/account');
          if (!context.mounted) return;
          _shared.load();
          _overviewVm.load();
          _expenseVm.load();
          _calendarVm.load();
          if (result != null) {
            AppToast.show(context, '$result 완료!!!', type: ToastType.success);
          }
        },
      ),
    );
  }
}
