import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.data,
    required this.barColor,
    this.height = 120,
  });

  /// data: (month: 'YYYYMM', amount: int) 리스트, 월 오름차순
  final List<({String month, int amount})> data;
  final Color barColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('데이터 없음', style: AppTextStyles.textBodySm.copyWith(
            color: AppColors.colorTextSecondary,
          )),
        ),
      );
    }

    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final barGroups = data.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: maxAmount == 0 ? 0 : e.amount / maxAmount,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [barColor.withValues(alpha: 0.6), barColor],
            ),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  final month = data[idx].month;
                  final m = month.length >= 6 ? month.substring(4, 6) : month;
                  return Text(
                    '${int.tryParse(m) ?? 0}월',
                    style: AppTextStyles.textBodyXs.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: false),
        ),
      ),
    );
  }
}
