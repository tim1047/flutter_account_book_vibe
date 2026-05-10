import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/asset/asset_accum_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AssetAccumScreen extends StatefulWidget {
  const AssetAccumScreen({super.key});

  @override
  State<AssetAccumScreen> createState() => _AssetAccumScreenState();
}

class _AssetAccumScreenState extends State<AssetAccumScreen> {
  late final AssetAccumViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AssetAccumViewModel();
    _load();
  }

  void _load() => _vm.loadData();

  @override
  void dispose() {
    _vm.dispose();
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
                return ErrorView(message: _vm.errorMessage!, onRetry: _load);
              }
              if (_vm.sortedDates.isEmpty) {
                return const EmptyView();
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendSection(assetNames: _vm.assetNames),
                    const SizedBox(height: 16),
                    _StackedBarChart(vm: _vm),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TotalAssetDetailCard(
                        sortedDates: _vm.sortedDates,
                        dateAssetMap: _vm.dateAssetMap,
                        assetNames: _vm.assetNames,
                      ),
                    ),
                    ..._vm.assetNames.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AssetDetailCard(
                          assetNm: e.value,
                          colorIndex: e.key,
                          sortedDates: _vm.sortedDates,
                          dateAssetMap: _vm.dateAssetMap,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _LegendSection extends StatelessWidget {
  const _LegendSection({required this.assetNames});

  final List<String> assetNames;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: assetNames.asMap().entries.map((e) {
        final color =
            AppColors.assetChartColors[e.key % AppColors.assetChartColors.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              e.value,
              style: const TextStyle(
                color: AppColors.colorTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Stacked Bar Chart ─────────────────────────────────────────────────────────

class _StackedBarChart extends StatelessWidget {
  const _StackedBarChart({required this.vm});

  final AssetAccumViewModel vm;

  double get _barWidth {
    final count = vm.sortedDates.length;
    if (count <= 4) return 36;
    if (count <= 8) return 24;
    if (count <= 12) return 18;
    return 14;
  }

  double get _maxY {
    double max = 0;
    for (final date in vm.sortedDates) {
      double total = 0;
      for (final nm in vm.assetNames) {
        total += vm.dateAssetMap[date]?[nm] ?? 0;
      }
      if (total > max) max = total;
    }
    return max == 0 ? 1000000 : max * 1.25;
  }

  List<BarChartGroupData> get _barGroups {
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < vm.sortedDates.length; i++) {
      final date = vm.sortedDates[i];
      final assetMap = vm.dateAssetMap[date] ?? {};
      double fromY = 0;
      final stacks = <BarChartRodStackItem>[];
      for (int j = 0; j < vm.assetNames.length; j++) {
        final price = (assetMap[vm.assetNames[j]] ?? 0).toDouble();
        if (price > 0) {
          final color = AppColors
              .assetChartColors[j % AppColors.assetChartColors.length];
          stacks.add(BarChartRodStackItem(fromY, fromY + price, color));
          fromY += price;
        }
      }
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: fromY,
            rodStackItems: stacks.isEmpty
                ? [BarChartRodStackItem(0, 0, Colors.transparent)]
                : stacks,
            width: _barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }
    return groups;
  }

  String _xLabel(String dt) {
    if (dt.length < 6) return dt;
    return '${dt.substring(0, 4)}.${dt.substring(4, 6)}';
  }

  String _yLabel(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(1)}억';
    }
    return '${(value / 10000).round()}만';
  }

  @override
  Widget build(BuildContext context) {
    final maxY = _maxY;
    final labelStep = (vm.sortedDates.length / 6).ceil().clamp(1, 30);

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(4, 24, 16, 8),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: _barGroups,
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
                reservedSize: 54,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _yLabel(value),
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
                  if (idx < 0 || idx >= vm.sortedDates.length) {
                    return const SizedBox.shrink();
                  }
                  if (idx % labelStep != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _xLabel(vm.sortedDates[idx]),
                      style: const TextStyle(
                        color: AppColors.colorTextSecondary,
                        fontSize: 9,
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
                if (idx < 0 || idx >= vm.sortedDates.length) return null;
                final date = vm.sortedDates[idx];
                final assetMap = vm.dateAssetMap[date] ?? {};
                final lines = <String>[_xLabel(date)];
                for (final nm in vm.assetNames) {
                  final p = assetMap[nm] ?? 0;
                  if (p > 0) lines.add('$nm: ${FormatUtil.formatPrice(p)}원');
                }
                return BarTooltipItem(
                  lines.join('\n'),
                  const TextStyle(
                    color: AppColors.colorTextPrimary,
                    fontSize: 11,
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

// ── Total Asset Detail Card ───────────────────────────────────────────────────

class _TotalAssetDetailCard extends StatelessWidget {
  const _TotalAssetDetailCard({
    required this.sortedDates,
    required this.dateAssetMap,
    required this.assetNames,
  });

  final List<String> sortedDates;
  final Map<String, Map<String, int>> dateAssetMap;
  final List<String> assetNames;

  String _fmtDt(String dt) {
    if (dt.length < 8) return dt;
    return '${dt.substring(0, 4)}.${dt.substring(4, 6)}.${dt.substring(6)}';
  }

  int _totalForDate(String date) {
    final assetMap = dateAssetMap[date] ?? {};
    int total = 0;
    for (final nm in assetNames) {
      total += assetMap[nm] ?? 0;
    }
    return total;
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final price = _totalForDate(date);

      int? change;
      double? pct;
      if (i > 0) {
        final prev = _totalForDate(sortedDates[i - 1]);
        if (prev > 0) {
          change = price - prev;
          pct = change / prev * 100;
        } else if (price == 0) {
          change = 0;
          pct = 0.0;
        }
      }

      final isPositive = (change ?? 0) >= 0;
      final changeColor =
          isPositive ? AppColors.colorIncome : AppColors.colorExpense;

      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                _fmtDt(date),
                style: const TextStyle(
                  color: AppColors.colorTextSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${FormatUtil.formatPrice(price)}원',
                style: const TextStyle(
                  color: AppColors.colorTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (change != null && pct != null) ...[
              Text(
                '${isPositive ? '+' : ''}${FormatUtil.formatPrice(change)}원',
                style: TextStyle(color: changeColor, fontSize: 11),
              ),
              const SizedBox(width: 4),
              Text(
                '(${isPositive ? '+' : ''}${pct.toStringAsFixed(1)}%)',
                style: TextStyle(color: changeColor, fontSize: 11),
              ),
            ],
          ],
        ),
      ));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      color: AppColors.colorBgSub,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.colorTextPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '총 자산',
                  style: TextStyle(
                    color: AppColors.colorTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.colorDivider),
            ...rows,
          ],
        ),
      ),
    );
  }
}

// ── Asset Detail Card ─────────────────────────────────────────────────────────

class _AssetDetailCard extends StatelessWidget {
  const _AssetDetailCard({
    required this.assetNm,
    required this.colorIndex,
    required this.sortedDates,
    required this.dateAssetMap,
  });

  final String assetNm;
  final int colorIndex;
  final List<String> sortedDates;
  final Map<String, Map<String, int>> dateAssetMap;

  Color get _color =>
      AppColors.assetChartColors[colorIndex % AppColors.assetChartColors.length];

  String _fmtDt(String dt) {
    if (dt.length < 8) return dt;
    return '${dt.substring(0, 4)}.${dt.substring(4, 6)}.${dt.substring(6)}';
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final price = dateAssetMap[date]?[assetNm] ?? 0;

      int? change;
      double? pct;
      if (i > 0) {
        final prev = dateAssetMap[sortedDates[i - 1]]?[assetNm] ?? 0;
        if (prev > 0) {
          change = price - prev;
          pct = change / prev * 100;
        } else if (price == 0) {
          change = 0;
          pct = 0.0;
        }
      }

      final isPositive = (change ?? 0) >= 0;
      final changeColor = isPositive ? AppColors.colorIncome : AppColors.colorExpense;

      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                _fmtDt(date),
                style: const TextStyle(
                  color: AppColors.colorTextSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${FormatUtil.formatPrice(price)}원',
                style: const TextStyle(
                  color: AppColors.colorTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (change != null && pct != null) ...[
              Text(
                '${isPositive ? '+' : ''}${FormatUtil.formatPrice(change)}원',
                style: TextStyle(color: changeColor, fontSize: 11),
              ),
              const SizedBox(width: 4),
              Text(
                '(${isPositive ? '+' : ''}${pct.toStringAsFixed(1)}%)',
                style: TextStyle(color: changeColor, fontSize: 11),
              ),
            ],
          ],
        ),
      ));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      color: AppColors.colorBgSub,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  assetNm,
                  style: const TextStyle(
                    color: AppColors.colorTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.colorDivider),
            ...rows,
          ],
        ),
      ),
    );
  }
}
