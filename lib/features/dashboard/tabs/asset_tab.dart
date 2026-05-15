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

        // ④ 부채 현황 (부채 > 0 일 때만, 항상 오늘 스냅샷)
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...[AssetHistoryPeriod.threeMonths, AssetHistoryPeriod.sixMonths]
            .map((p) {
          final isSelected = vm.historyPeriod == p;
          return GestureDetector(
            onTap: () => vm.selectHistoryPeriod(p),
            child: _PeriodChip(
              label: _label(p),
              isSelected: isSelected,
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showYearsDialog(context, vm),
          child: _PeriodChip(
            label: '${vm.customYears}년',
            isSelected: vm.historyPeriod == AssetHistoryPeriod.oneYear,
          ),
        ),
      ],
    );
  }

  static String _label(AssetHistoryPeriod p) => switch (p) {
        AssetHistoryPeriod.threeMonths => '3개월',
        AssetHistoryPeriod.sixMonths => '6개월',
        AssetHistoryPeriod.oneYear => throw StateError('unreachable'),
      };
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.colorAccentTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppColors.colorAccentTeal : AppColors.colorDivider,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.textBodyXs.copyWith(
            color: isSelected
                ? AppColors.colorBgMain
                : AppColors.colorTextSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

Future<void> _showYearsDialog(
  BuildContext context,
  DashboardAssetViewModel vm,
) async {
  final years = await showDialog<int>(
    context: context,
    builder: (context) => _YearsInputDialog(currentYears: vm.customYears),
  );
  if (!context.mounted) return;
  if (years != null) {
    vm.selectCustomYears(years);
  }
}

class _YearsInputDialog extends StatefulWidget {
  const _YearsInputDialog({required this.currentYears});

  final int currentYears;

  @override
  State<_YearsInputDialog> createState() => _YearsInputDialogState();
}

class _YearsInputDialogState extends State<_YearsInputDialog> {
  late final TextEditingController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentYears.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1 || value > 50) {
      setState(() => _hasError = true);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.colorBgSub,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      title: Text(
        '기간 입력',
        style: AppTextStyles.textHeadlineMd.copyWith(
          color: AppColors.colorTextPrimary,
        ),
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        style: AppTextStyles.textBodyLg.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        decoration: InputDecoration(
          filled: false,
          labelText: '기간 (년)',
          labelStyle: AppTextStyles.textBodySm.copyWith(
            color: AppColors.colorTextSecondary,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.colorDivider),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.colorAccentTeal),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.colorError),
          ),
          disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.colorDivider),
          ),
          errorText: _hasError ? '1~50 사이 숫자를 입력해주세요' : null,
        ),
        onSubmitted: (_) => _confirm(),
        onChanged: (_) {
          if (_hasError) setState(() => _hasError = false);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '취소',
            style: AppTextStyles.textBodyMd.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text(
            '확인',
            style: AppTextStyles.textBodyMd.copyWith(
              color: AppColors.colorAccentTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
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
          width: 80,
          height: 80,
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 22,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(width: 24),
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
