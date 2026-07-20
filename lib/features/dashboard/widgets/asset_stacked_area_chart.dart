import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/asset_colors.dart';
import 'package:account_book_vibe/features/dashboard/utils/chart_x_axis.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 기간별 자산 구성 변화를 자산별 누적 영역으로 쌓아 보여준다.
/// 순자산(부채 반영 합계)은 포함하지 않는다 — 자산 항목들의 누적 합이 곧
/// 총자산이라 순자산까지 밴드로 넣으면 이중 집계된다.
class AssetStackedAreaChart extends StatelessWidget {
  const AssetStackedAreaChart({
    super.key,
    required this.history,
    required this.assets,
    this.height = 170,
  });

  /// history: (date: 'YYYYMMDD', byAsset) 오름차순.
  final List<({String date, Map<String, int> byAsset})> history;

  /// assetId별 고정 색상 조회에 쓰인다 — 기간별 자산 현황 리스트와 순서 일치 불필요.
  final List<({String id, String name})> assets;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (history.length < 2 || assets.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '데이터 없음',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
        ),
      );
    }

    final cumulative = _buildCumulative();
    final maxY = cumulative.last.reduce((a, b) => a > b ? a : b);
    final yInterval = maxY > 0 ? maxY / 3.0 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY > 0 ? maxY * 1.1 : 1.0,
              lineBarsData: _buildBarsData(cumulative),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.colorDivider,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 54,
                    interval: yInterval,
                    getTitlesWidget: (value, _) {
                      if (value < -1.0 || value > maxY + 1.0) {
                        return const SizedBox.shrink();
                      }
                      final amountInEok = value / 100000000;
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
                  sideTitles: buildDateAxisTitles(
                    history.map((record) => record.date).toList(),
                  ),
                ),
              ),
              lineTouchData: const LineTouchData(enabled: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: assets.map((asset) {
            return _LegendChip(
              color: AssetColors.of(asset.id),
              label: asset.name,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// cumulative[i][j] = 0~i번째 자산까지 j번째 시점의 누적 금액.
  List<List<double>> _buildCumulative() {
    final cumulative = <List<double>>[];
    for (var i = 0; i < assets.length; i++) {
      final prevRow = i == 0 ? null : cumulative[i - 1];
      final row = List<double>.generate(history.length, (j) {
        final amount = (history[j].byAsset[assets[i].name] ?? 0).toDouble();
        return (prevRow?[j] ?? 0) + amount;
      });
      cumulative.add(row);
    }
    return cumulative;
  }

  /// 맨 위(총합) 밴드부터 그려 그 아래를 순서대로 덮어써야 스택된 영역처럼 보인다.
  List<LineChartBarData> _buildBarsData(List<List<double>> cumulative) {
    final barsData = <LineChartBarData>[];
    for (var i = assets.length - 1; i >= 0; i--) {
      final color = AssetColors.of(assets[i].id);
      barsData.add(LineChartBarData(
        spots: List.generate(
          history.length,
          (j) => FlSpot(j.toDouble(), cumulative[i][j]),
        ),
        isCurved: true,
        color: AppColors.colorBgCard,
        barWidth: 1.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: color),
      ));
    }
    return barsData;
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.textBodyXs.copyWith(
            color: AppColors.colorTextSecondary,
          ),
        ),
      ],
    );
  }
}
