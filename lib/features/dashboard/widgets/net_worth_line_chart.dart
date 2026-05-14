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

    // Normalize: shift all spot values so dataMin → 0.
    // fl_chart generates ticks at multiples of interval from 0 (global grid).
    // With minY shifted to 0, the 4 target ticks (0, interval, 2*interval, yRange)
    // are exact multiples of yInterval, so they align perfectly.
    final yInterval = yRange > 0 ? yRange / 3.0 : 1.0;
    // padding < yInterval ensures chartMin < 0, so first fl_chart tick = 0 = normalized minY
    final padding = yRange > 0 ? yRange * 0.1 : 0.3;

    final spots = history.asMap().entries.map((entry) => FlSpot(
          entry.key.toDouble(),
          entry.value.amount.toDouble() - minY,
        )).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: -padding,
          maxY: yRange + padding,
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
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) {
              // Show grid lines only at the two middle (1/3, 2/3) positions
              final isMidTick = (value - yInterval).abs() <= 1.0 ||
                  (value - yInterval * 2).abs() <= 1.0;
              if (!isMidTick) {
                return const FlLine(color: Colors.transparent, strokeWidth: 0);
              }
              return const FlLine(
                color: AppColors.colorDivider,
                strokeWidth: 0.5,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 62,
                interval: yInterval,
                getTitlesWidget: (value, _) {
                  // Guard: only show labels within the data range [0, yRange]
                  if (value < -1.0 || value > yRange + 1.0) {
                    return const SizedBox.shrink();
                  }
                  final actualValue = value + minY;
                  final amountInEok = actualValue / 100000000;
                  return Text(
                    '${amountInEok.toStringAsFixed(2)}억',
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
