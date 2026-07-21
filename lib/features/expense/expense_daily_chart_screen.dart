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
    final current = monthlyData.last;
    final previous =
        monthlyData.length >= 2 ? monthlyData[monthlyData.length - 2] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Legend(),
          const SizedBox(height: 12),
          _MultiMonthLineChart(monthlyData: monthlyData),
          const SizedBox(height: 16),
          _CumulativeMonthCard(current: current, previous: previous),
        ],
      ),
    );
  }
}

// ── 범례 (이번달 강조 / 지난달들 눌림, 2항목 고정) ─────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: AppColors.colorChartCurrent, label: '이번달'),
        SizedBox(width: 20),
        _LegendItem(color: AppColors.colorTextSecondary, label: '지난달들'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.colorTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── 패널 A: 3개월 겹침 라인 (이번달 강조, 지난달들 눌림) ────────────────────────

class _MultiMonthLineChart extends StatelessWidget {
  const _MultiMonthLineChart({required this.monthlyData});

  final List<MonthDailyData> monthlyData;

  static const double _yInterval = 500000;

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
    final currentIndex = monthlyData.length - 1;

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
              _buildLine(i, i == currentIndex),
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
                    color: idx == currentIndex
                        ? AppColors.colorChartCurrent
                        : AppColors.colorTextSecondary,
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

  LineChartBarData _buildLine(int index, bool isCurrent) {
    final entries = monthlyData[index].entries;
    final spots =
        entries.map((e) => FlSpot(e.day.toDouble(), e.price.toDouble())).toList();
    final lastSpot = spots.isEmpty ? null : spots.last;

    return LineChartBarData(
      spots: spots,
      color: isCurrent ? AppColors.colorChartCurrent : AppColors.colorTextSecondary,
      isCurved: true,
      curveSmoothness: 0.25,
      barWidth: isCurrent ? 2 : 1,
      dotData: FlDotData(
        show: isCurrent,
        checkToShowDot: (spot, _) => lastSpot != null && spot == lastSpot,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4,
          color: AppColors.colorChartCurrent,
          strokeWidth: 2,
          strokeColor: AppColors.colorBgCard,
        ),
      ),
      belowBarData: BarAreaData(
        show: isCurrent,
        color: Color.fromRGBO(
          AppColors.colorChartCurrent.red,
          AppColors.colorChartCurrent.green,
          AppColors.colorChartCurrent.blue,
          0.1,
        ),
      ),
    );
  }
}

// ── 누적 계산 (순수 함수, 테스트 대상) ──────────────────────────────────────────

/// 일별 데이터에서 누적 합계를 계산하는 순수 함수 모음.
class DailyCumulativeCalc {
  DailyCumulativeCalc._();

  static int cumulativeUpTo(List<DailyChartEntry> entries, int day) =>
      entries
          .where((e) => e.day <= day)
          .fold(0, (sum, e) => sum + e.price);

  static List<FlSpot> buildCumulativeSpots(List<DailyChartEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.day.compareTo(b.day));
    int running = 0;
    final spots = <FlSpot>[];
    for (final e in sorted) {
      running += e.price;
      spots.add(FlSpot(e.day.toDouble(), running.toDouble()));
    }
    return spots;
  }

  /// [year]/[month]가 실제 달력상 이번달이면 오늘까지, 아니면 그 달의 마지막 날까지를
  /// "누적 기준일"로 본다. 이번달인 경우 `today.day`는 정의상 그 달의 마지막 날을
  /// 넘을 수 없으므로 별도 clamp가 필요 없다.
  static int referenceDay(int year, int month, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final isCurrentCalendarMonth = year == today.year && month == today.month;
    if (isCurrentCalendarMonth) return today.day;
    return DateTime(year, month + 1, 0).day;
  }
}
