import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({
    super.key,
    required this.history,
    this.height = 120,
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

    final amounts = history.map((e) => e.amount.toDouble()).toList();
    final minY = amounts.reduce((a, b) => a < b ? a : b);
    final maxY = amounts.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    final spots = history.asMap().entries.map((e) => FlSpot(
          e.key.toDouble(),
          e.value.amount.toDouble(),
        )).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
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
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
