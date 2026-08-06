import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.data,
    required this.barColor,
    this.height = 140,
    this.highlightMonth,
  });

  /// data: (month: 'YYYYMM', amount: int) 리스트, 월 오름차순
  final List<({String month, int amount})> data;
  final Color barColor;
  final double height;

  /// 강조 표시할 'YYYYMM'. null이면 모든 막대 동일하게 표시.
  final String? highlightMonth;

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
    final maxY = maxAmount == 0 ? 1000000.0 : maxAmount * 1.25;
    final minBarY = maxY * 0.02;
    final highlightIdx = highlightMonth == null
        ? -1
        : data.indexWhere((e) => e.month == highlightMonth);
    final barGroups = data.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final isDimmed = highlightMonth != null && e.month != highlightMonth;
      final rodColors = isDimmed
          ? [barColor.withValues(alpha: 0.18), barColor.withValues(alpha: 0.3)]
          : [barColor.withValues(alpha: 0.6), barColor];
      return BarChartGroupData(
        x: i,
        showingTooltipIndicators: i == highlightIdx ? const [0] : const [],
        barRods: [
          BarChartRodData(
            toY: e.amount == 0 ? minBarY : e.amount.toDouble(),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: rodColors,
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
          maxY: maxY,
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.colorTextDisabled,
              strokeWidth: 0.5,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${(value / 10000).round()}',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.textBodyXs.copyWith(
                      color: AppColors.colorTextSecondary,
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
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
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.colorBgSub,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              tooltipMargin: 4,
              getTooltipItem: (group, _, __, ___) {
                final e = data[group.x];
                return BarTooltipItem(
                  '${FormatUtil.formatPrice(e.amount)}원',
                  const TextStyle(
                    color: AppColors.colorTextPrimary,
                    fontSize: 10,
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
