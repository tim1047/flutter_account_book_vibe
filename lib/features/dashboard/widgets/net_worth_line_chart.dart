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

    final amounts = history.map((e) => e.amount.toDouble()).toList();
    final minY = amounts.reduce((a, b) => a < b ? a : b);
    final maxY = amounts.reduce((a, b) => a > b ? a : b);
    final yRange = maxY - minY;
    final padding = yRange < 1 ? 1.0 : yRange * 0.1;

    // 4 tick positions: data min, 1/3, 2/3, data max
    final tick0 = minY;
    final tick1 = minY + yRange / 3.0;
    final tick2 = minY + yRange * 2.0 / 3.0;
    final tick3 = maxY;
    // epsilon must be > padding so fl_chart ticks (offset by padding) still match
    final tickEpsilon = yRange < 1 ? 0.5 : yRange * 0.12;
    final yInterval = yRange < 1 ? 1.0 : yRange / 3.0;

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
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                interval: yInterval,
                getTitlesWidget: (value, _) {
                  final ticks = [tick0, tick1, tick2, tick3];
                  if (!ticks.any((t) => (value - t).abs() <= tickEpsilon)) {
                    return const SizedBox.shrink();
                  }
                  final awkDouble = value / 100000000;
                  final label = awkDouble.toStringAsFixed(1).endsWith('.0')
                      ? '${awkDouble.round()}억'
                      : '${awkDouble.toStringAsFixed(1)}억';
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
