import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({
    super.key,
    required this.history,
    this.height = 170,
  });

  /// history: (date: 'YYYYMMDD', amount: int) 오름차순
  final List<({String date, int amount})> history;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('데이터 없음', style: AppTextStyles.textBodySm.copyWith(
            color: AppColors.colorTextSecondary,
          )),
        ),
      );
    }

    final amounts = history.map((record) => record.amount.toDouble()).toList();
    final minY = amounts.reduce((a, b) => a < b ? a : b);
    final maxY = amounts.reduce((a, b) => a > b ? a : b);
    final yRange = maxY - minY;

    // interval = yRange/3 so chart bounds [minY-interval, maxY+interval]
    // aligns fl_chart's tick grid exactly with our 4 target positions
    final yInterval = yRange > 0 ? yRange / 3.0 : 1.0;

    // 4 target Y-axis positions: data min, 1/3, 2/3, data max
    final yAxisTicks = [
      minY,
      minY + yInterval,
      minY + yInterval * 2,
      maxY,
    ];

    final spots = history.asMap().entries.map((entry) => FlSpot(
          entry.key.toDouble(),
          entry.value.amount.toDouble(),
        )).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - yInterval,
          maxY: maxY + yInterval,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.colorAccentTeal,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.colorAccentTeal.withValues(alpha: 0.2),
                    AppColors.colorAccentTeal.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
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
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                interval: yInterval,
                getTitlesWidget: (value, _) {
                  // Only show labels at our 4 target tick positions.
                  // epsilon = 1.0 won: fl_chart ticks are exact due to aligned bounds.
                  if (!yAxisTicks.any((tick) => (value - tick).abs() <= 1.0)) {
                    return const SizedBox.shrink();
                  }
                  final amountInEok = value / 100000000;
                  final formatted = amountInEok.toStringAsFixed(1);
                  final label = formatted.endsWith('.0')
                      ? '${amountInEok.round()}억'
                      : '$formatted억';
                  return Text(
                    label,
                    style: AppTextStyles.textBodyXs.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= history.length) {
                    return const SizedBox.shrink();
                  }
                  final currentMonth = history[idx].date.substring(4, 6);
                  if (idx > 0 &&
                      currentMonth == history[idx - 1].date.substring(4, 6)) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${int.parse(currentMonth)}월',
                    style: AppTextStyles.textBodyXs.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
