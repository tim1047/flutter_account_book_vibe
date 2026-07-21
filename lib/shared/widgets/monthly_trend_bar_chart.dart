import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 월별 합계를 막대로, 평균을 기준선으로 보여주는 차트.
/// 이번달 막대는 강조색 + 상시 노출 값 라벨로 표시된다.
class MonthlyTrendBarChart extends StatelessWidget {
  const MonthlyTrendBarChart({
    super.key,
    required this.monthMap,
    required this.orderedMonths,
    required this.avgPrice,
    required this.currentMonth,
  });

  final Map<int, int> monthMap;
  final List<int> orderedMonths;
  final int avgPrice;
  final int currentMonth;

  static double computeMaxY(List<int> values, int avgPrice) {
    final rawValues = [
      ...values.map((v) => v.toDouble()),
      avgPrice.toDouble(),
    ];
    final rawMax =
        rawValues.isEmpty ? 0.0 : rawValues.reduce((a, b) => a > b ? a : b);
    return rawMax == 0 ? 1000000.0 : rawMax * 1.25;
  }

  @override
  Widget build(BuildContext context) {
    final values = orderedMonths.map((m) => monthMap[m] ?? 0).toList();
    final maxY = computeMaxY(values, avgPrice);
    final minBarY = maxY * 0.02;

    final barGroups = <BarChartGroupData>[
      for (int i = 0; i < orderedMonths.length; i++)
        BarChartGroupData(
          x: i,
          showingTooltipIndicators:
              orderedMonths[i] == currentMonth ? const [0] : const [],
          barRods: [
            BarChartRodData(
              toY: values[i] == 0 ? minBarY : values[i].toDouble(),
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
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: avgPrice.toDouble(),
                color: AppColors.colorTextSecondary,
                strokeWidth: 1,
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(
                    color: AppColors.colorTextSecondary,
                    fontSize: 10,
                  ),
                  labelResolver: (_) =>
                      '평균 ${FormatUtil.formatPrice(avgPrice)}원',
                ),
              ),
            ],
          ),
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
                  if (idx < 0 || idx >= orderedMonths.length) {
                    return const SizedBox.shrink();
                  }
                  final isCurrent = orderedMonths[idx] == currentMonth;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${orderedMonths[idx]}',
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
                return BarTooltipItem(
                  '${orderedMonths[idx]}월\n${FormatUtil.formatPrice(values[idx])}원',
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
