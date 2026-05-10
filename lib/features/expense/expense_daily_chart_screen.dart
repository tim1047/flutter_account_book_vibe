import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/expense/expense_chart_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpenseDailyChartScreen extends StatefulWidget {
  const ExpenseDailyChartScreen({super.key});

  @override
  State<ExpenseDailyChartScreen> createState() =>
      _ExpenseDailyChartScreenState();
}

class _ExpenseDailyChartScreenState extends State<ExpenseDailyChartScreen> {
  late final ExpenseChartViewModel _vm;
  late final DateFilterViewModel _dateFilter;

  @override
  void initState() {
    super.initState();
    _vm = ExpenseChartViewModel();
    _dateFilter = DateFilterViewModel();
    _load();
  }

  int get _effectiveMonth {
    final m = _dateFilter.selectedMonth;
    return m == 0 ? DateTime.now().month : m;
  }

  void _load() => _vm.loadDailyData(_dateFilter.selectedYear, _effectiveMonth);

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
                    final data = _vm.monthlyDailyData;
                    if (data.isEmpty || data.every((m) => m.entries.isEmpty)) {
                      return const EmptyView();
                    }
                    return _DailyChartBody(monthlyData: data);
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

class _DailyChartBody extends StatelessWidget {
  const _DailyChartBody({required this.monthlyData});

  final List<MonthDailyData> monthlyData;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Legend(monthlyData: monthlyData),
          const SizedBox(height: 12),
          _MultiMonthLineChart(monthlyData: monthlyData),
        ],
      ),
    );
  }
}

// ── 범례 ──────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend({required this.monthlyData});

  final List<MonthDailyData> monthlyData;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < monthlyData.length; i++) ...[
          if (i > 0) const SizedBox(width: 20),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.chartLineColors[i % AppColors.chartLineColors.length],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${monthlyData[i].month}월',
            style: const TextStyle(
              color: AppColors.colorTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ── 3개월 꺾은선 차트 ──────────────────────────────────────────────────────────

class _MultiMonthLineChart extends StatelessWidget {
  const _MultiMonthLineChart({required this.monthlyData});

  final List<MonthDailyData> monthlyData;

  static const double _yInterval = 500000;

  List<FlSpot> _buildSpots(List<DailyChartEntry> entries) => entries
      .map((e) => FlSpot(e.day.toDouble(), e.price.toDouble()))
      .toList();

  double _maxY() {
    double max = 0;
    for (final m in monthlyData) {
      for (final e in m.entries) {
        if (e.price > max) max = e.price.toDouble();
      }
    }
    if (max == 0) return _yInterval;
    final steps = (max / _yInterval).ceil();
    return (steps + 1) * _yInterval;
  }

  @override
  Widget build(BuildContext context) {
    final maxY = _maxY();

    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(4, 24, 16, 8),
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: 31,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            for (int i = 0; i < monthlyData.length; i++)
              LineChartBarData(
                spots: _buildSpots(monthlyData[i].entries),
                color: AppColors.chartLineColors[
                    i % AppColors.chartLineColors.length],
                isCurved: true,
                curveSmoothness: 0.25,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Color.fromRGBO(
                    AppColors.chartLineColors[
                            i % AppColors.chartLineColors.length]
                        .red,
                    AppColors.chartLineColors[
                            i % AppColors.chartLineColors.length]
                        .green,
                    AppColors.chartLineColors[
                            i % AppColors.chartLineColors.length]
                        .blue,
                    0.06,
                  ),
                ),
              ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _yInterval,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.colorDivider,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: _yInterval,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${(value / 10000).round()}만',
                      style: const TextStyle(
                        color: AppColors.colorTextSecondary,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  if (day == 1 || day % 5 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$day',
                        style: const TextStyle(
                          color: AppColors.colorTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.colorBgCard,
              getTooltipItems: (spots) => spots.map((spot) {
                final idx = spot.barIndex;
                final month = monthlyData[idx].month;
                return LineTooltipItem(
                  '$month월 ${spot.x.toInt()}일\n'
                  '${FormatUtil.formatPrice(spot.y.round())}원',
                  TextStyle(
                    color: AppColors.chartLineColors[
                        idx % AppColors.chartLineColors.length],
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
