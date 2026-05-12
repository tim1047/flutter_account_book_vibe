// lib/features/dashboard/tabs/asset_tab.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/widgets/donut_legend_row.dart';
import 'package:account_book_vibe/features/dashboard/widgets/net_worth_line_chart.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AssetTab extends StatelessWidget {
  const AssetTab({super.key, required this.vm});

  final DashboardAssetViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.colorAccentIndigo),
          );
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return _AssetContent(vm: vm, data: data);
      },
    );
  }
}

class _AssetContent extends StatelessWidget {
  const _AssetContent({required this.vm, required this.data});

  final DashboardAssetViewModel vm;
  final DashboardAssetData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ① 순자산 헤더 (항상 오늘 스냅샷)
        _AssetHeroCard(data: data),
        const SizedBox(height: 12),

        // ② 자산 구성 도넛 (항상 오늘 스냅샷)
        _SectionCard(
          title: '자산 구성',
          child: _AssetDonutSection(data: data),
        ),
        const SizedBox(height: 12),

        // ③ 순자산 추이 (히스토리 기간 선택 가능)
        _SectionCard(
          title: '순자산 추이',
          trailing: _HistoryPeriodPicker(vm: vm),
          child: NetWorthLineChart(
            history: data.netWorthHistory,
            height: 140,
          ),
        ),
        const SizedBox(height: 12),

        // ④ 자산 항목별 리스트 (항상 오늘 스냅샷)
        _SectionCard(
          title: '자산 항목',
          child: Column(
            children: data.assetGroups
                .map((g) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.assetNm,
                              style: AppTextStyles.textBodySm.copyWith(
                                color: AppColors.colorTextPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '₩ ${FormatUtil.formatPrice(g.assetTotSumPrice)}',
                            style: AppTextStyles.textBodySm.copyWith(
                              color: AppColors.colorTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),

        // ⑤ 부채 현황 (부채 > 0 일 때만, 항상 오늘 스냅샷)
        if (data.debt > 0) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: '부채 현황',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 부채',
                  style: AppTextStyles.textBodySm.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                Text(
                  '-₩ ${FormatUtil.formatPrice(data.debt)}',
                  style: AppTextStyles.textBodyMd.copyWith(
                    color: AppColors.colorExpense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryPeriodPicker extends StatelessWidget {
  const _HistoryPeriodPicker({required this.vm});

  final DashboardAssetViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: AssetHistoryPeriod.values.map((p) {
          final isSelected = vm.historyPeriod == p;
          return GestureDetector(
            onTap: () => vm.selectHistoryPeriod(p),
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.colorAccentTeal
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.colorAccentTeal
                      : AppColors.colorDivider,
                ),
              ),
              child: Text(
                _label(p),
                style: AppTextStyles.textBodyXs.copyWith(
                  color: isSelected
                      ? AppColors.colorBgMain
                      : AppColors.colorTextSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(AssetHistoryPeriod p) => switch (p) {
        AssetHistoryPeriod.threeMonths => '3개월',
        AssetHistoryPeriod.sixMonths => '6개월',
        AssetHistoryPeriod.oneYear => '1년',
      };
}

class _AssetHeroCard extends StatelessWidget {
  const _AssetHeroCard({required this.data});
  final DashboardAssetData data;

  @override
  Widget build(BuildContext context) {
    final growth = data.yearlyGrowth;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '순자산 (Net Worth)',
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₩ ${FormatUtil.formatPrice(data.netWorth)}',
            style: AppTextStyles.textHeadingLg.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: '총자산',
                  value: '₩${FormatUtil.formatPrice(data.totalAsset)}',
                  color: AppColors.colorProfit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: '전년 대비',
                  value: growth >= 0
                      ? '+₩${FormatUtil.formatPrice(growth)}'
                      : '-₩${FormatUtil.formatPrice(growth.abs())}',
                  color: growth >= 0
                      ? AppColors.colorProfit
                      : AppColors.colorExpense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.textBodyXs.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.textBodySm.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetDonutSection extends StatelessWidget {
  const _AssetDonutSection({required this.data});
  final DashboardAssetData data;

  static const _colors = AppColors.assetChartColors;

  @override
  Widget build(BuildContext context) {
    if (data.assetComposition.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text('데이터 없음')),
      );
    }
    final sections = data.assetComposition.asMap().entries.map((e) {
      final color = _colors[e.key % _colors.length];
      return PieChartSectionData(
        value: e.value.ratio,
        color: color,
        radius: 40,
        title: '',
      );
    }).toList();

    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 28,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: data.assetComposition.asMap().entries.map((e) {
              final color = _colors[e.key % _colors.length];
              return DonutLegendRow(
                color: color,
                label: e.value.assetNm,
                amount: e.value.amount,
                ratio: e.value.ratio,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.textBodySm.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
