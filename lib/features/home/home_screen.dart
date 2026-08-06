import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_shared_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/tabs/overview_tab.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/overview_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/period_selector.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DashboardPeriodViewModel _period;
  late final DashboardSharedViewModel _shared;
  late final DashboardOverviewViewModel _overviewVm;
  late final CalendarSummaryViewModel _calendarVm;
  bool _periodExpanded = false;

  @override
  void initState() {
    super.initState();
    _period = DashboardPeriodViewModel();
    _shared = DashboardSharedViewModel(_period)..load();
    _overviewVm = DashboardOverviewViewModel(_shared)..load();
    _calendarVm = CalendarSummaryViewModel()..load();
  }

  @override
  void dispose() {
    _period.dispose();
    _shared.dispose();
    _overviewVm.dispose();
    _calendarVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: MainAppBar(
        showMenuButton: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40 + (_periodExpanded ? 48 : 0)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PeriodSelector(
              vm: _period,
              onExpandedChanged: (expanded) => setState(() => _periodExpanded = expanded),
            ),
          ),
        ),
      ),
      body: OverviewTab(vm: _overviewVm, calendarVm: _calendarVm, periodVm: _period),
      floatingActionButton: GradientFAB(
        heroTag: 'addAccountHome',
        icon: Icons.add,
        onPressed: () async {
          final result = await context.push<String>('/account');
          if (!context.mounted) return;
          _shared.load();
          _overviewVm.load();
          _calendarVm.load();
          if (result != null) {
            AppToast.show(context, '$result 완료!!!', type: ToastType.success);
          }
        },
      ),
    );
  }
}
