import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/income/income_chart_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/monthly_trend_bar_chart.dart';
import 'package:account_book_vibe/shared/widgets/trend_summary_card.dart';
import 'package:flutter/material.dart';

class IncomeMonthlyChartScreen extends StatefulWidget {
  const IncomeMonthlyChartScreen({super.key});

  @override
  State<IncomeMonthlyChartScreen> createState() =>
      _IncomeMonthlyChartScreenState();
}

class _IncomeMonthlyChartScreenState extends State<IncomeMonthlyChartScreen> {
  late final IncomeChartViewModel _vm;
  late final DateFilterViewModel _dateFilter;

  @override
  void initState() {
    super.initState();
    _vm = IncomeChartViewModel();
    _dateFilter = DateFilterViewModel();
    _load();
  }

  void _load() => _vm.loadMonthlyData(
        FormatUtil.toProcDt(_dateFilter.selectedYear, _dateFilter.selectedMonth),
      );

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
                    final data = _vm.monthlyData;
                    if (data == null || data.data.isEmpty) {
                      return const EmptyView();
                    }
                    final currentMonth = _dateFilter.selectedMonth == 0
                        ? DateTime.now().month
                        : _dateFilter.selectedMonth;
                    return _MonthlyChartBody(
                      data: data,
                      currentMonth: currentMonth,
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

// ── Body ──────────────────────────────────────────────────────────────────────

class _MonthlyChartBody extends StatelessWidget {
  const _MonthlyChartBody({required this.data, required this.currentMonth});

  final SumGroupByMonthResponse data;
  final int currentMonth;

  @override
  Widget build(BuildContext context) {
    final monthMap = {for (final item in data.data) item.month: item.sumPrice};
    final sortedItems = [...data.data]
      ..sort((a, b) {
        final keyA = (a.month - currentMonth - 1 + 12) % 12;
        final keyB = (b.month - currentMonth - 1 + 12) % 12;
        return keyA.compareTo(keyB);
      });
    final orderedMonths = sortedItems.map((e) => e.month).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TrendSummaryCard(
            icon: Icons.bar_chart,
            text: '한달에 평균 ${FormatUtil.formatPrice(data.avgSumPrice)}원 수입이 있어요',
            color: AppColors.colorIncome,
          ),
          const SizedBox(height: 24),
          MonthlyTrendBarChart(
            monthMap: monthMap,
            orderedMonths: orderedMonths,
            avgPrice: data.avgSumPrice,
            currentMonth: currentMonth,
          ),
        ],
      ),
    );
  }
}
