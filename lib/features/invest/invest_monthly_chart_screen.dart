import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/features/invest/invest_chart_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class InvestMonthlyChartScreen extends StatefulWidget {
  const InvestMonthlyChartScreen({super.key});

  @override
  State<InvestMonthlyChartScreen> createState() =>
      _InvestMonthlyChartScreenState();
}

class _InvestMonthlyChartScreenState extends State<InvestMonthlyChartScreen> {
  late final InvestChartViewModel _vm;
  late final DateFilterViewModel _dateFilter;

  @override
  void initState() {
    super.initState();
    _vm = InvestChartViewModel();
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

  Map<int, int> get _monthMap =>
      {for (final item in data.data) item.month: item.sumPrice};

  @override
  Widget build(BuildContext context) {
    final monthMap = _monthMap;
    final currentPrice = monthMap[currentMonth] ?? 0;
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevPrice = monthMap[prevMonth] ?? 0;
    final diff = currentPrice - prevPrice;

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
          _SummaryCard(
            icon: Icons.compare_arrows,
            text: diff == 0
                ? '저번달과 동일해요'
                : diff > 0
                    ? '저번달보다 ${FormatUtil.formatPrice(diff)}원 더 투자했어요'
                    : '저번달보다 ${FormatUtil.formatPrice(-diff)}원 덜 투자했어요',
            color: diff > 0 ? AppColors.colorInvest : AppColors.colorIncome,
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.bar_chart,
            text: '한달에 평균 ${FormatUtil.formatPrice(data.avgSumPrice)}원 투자중이에요',
            color: AppColors.colorRate,
          ),
          const SizedBox(height: 24),
          _BarChartCard(
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

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.colorBgSub,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.colorTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
    required this.monthMap,
    required this.orderedMonths,
    required this.avgPrice,
    required this.currentMonth,
  });

  final Map<int, int> monthMap;
  final List<int> orderedMonths;
  final int avgPrice;
  final int currentMonth;

  @override
  Widget build(BuildContext context) {
    final rawValues = [
      ...orderedMonths.map((m) => (monthMap[m] ?? 0).toDouble()),
      avgPrice.toDouble(),
    ];
    final rawMax = rawValues.isEmpty
        ? 0.0
        : rawValues.reduce((a, b) => a > b ? a : b);
    final maxY = rawMax == 0 ? 1000000.0 : rawMax * 1.25;
    final minBarY = maxY * 0.02;

    final barGroups = <BarChartGroupData>[
      for (int i = 0; i < orderedMonths.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (monthMap[orderedMonths[i]] ?? 0) == 0
                  ? minBarY
                  : (monthMap[orderedMonths[i]] ?? 0).toDouble(),
              gradient: orderedMonths[i] == currentMonth
                  ? null
                  : AppColors.barChartGradient,
              color: orderedMonths[i] == currentMonth
                  ? AppColors.colorChartCurrent
                  : null,
              width: 14,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      BarChartGroupData(
        x: orderedMonths.length,
        barRods: [
          BarChartRodData(
            toY: avgPrice == 0 ? minBarY : avgPrice.toDouble(),
            color: AppColors.colorChartAverage,
            width: 14,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ),
    ];

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(4, 24, 16, 8),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
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
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  final label = idx < orderedMonths.length
                      ? '${orderedMonths[idx]}'
                      : '평균';
                  final isCurrent = idx < orderedMonths.length &&
                      orderedMonths[idx] == currentMonth;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isCurrent
                            ? AppColors.colorChartCurrent
                            : AppColors.colorTextSecondary,
                        fontSize: 10,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.colorBgSub,
              getTooltipItem: (group, _, rod, __) {
                final idx = group.x;
                final label = idx < orderedMonths.length
                    ? '${orderedMonths[idx]}월'
                    : '평균';
                final actualPrice = idx < orderedMonths.length
                    ? (monthMap[orderedMonths[idx]] ?? 0)
                    : avgPrice;
                return BarTooltipItem(
                  '$label\n${FormatUtil.formatPrice(actualPrice)}원',
                  const TextStyle(
                    color: AppColors.colorTextPrimary,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
