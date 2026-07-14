import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/material.dart';

class PeriodSelector extends StatefulWidget {
  const PeriodSelector({super.key, required this.vm, this.onExpandedChanged});

  final DashboardPeriodViewModel vm;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  bool _expanded = false;

  void _setExpanded(bool value) {
    setState(() => _expanded = value);
    widget.onExpandedChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _YearMonthBar(
            vm: widget.vm,
            expanded: _expanded,
            onToggleExpanded: () => _setExpanded(!_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _PeriodPillRow(
                vm: widget.vm,
                onSelected: () => _setExpanded(false),
              ),
            ),
        ],
      ),
    );
  }
}

class _YearMonthBar extends StatelessWidget {
  const _YearMonthBar({
    required this.vm,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final DashboardPeriodViewModel vm;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  List<int> get _years {
    final currentYear = DateTime.now().year;
    final minYear =
        currentYear - 5 < vm.selectedYear ? currentYear - 5 : vm.selectedYear;
    final maxYear =
        currentYear + 1 > vm.selectedYear ? currentYear + 1 : vm.selectedYear;
    return [for (var y = minYear; y <= maxYear; y++) y];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconButton(
            icon: Icons.chevron_left,
            onPressed: vm.goPrevMonth,
          ),
          const SizedBox(width: 8),
          _DropdownContainer(
            child: DropdownButton<int>(
              value: vm.selectedYear,
              underline: const SizedBox.shrink(),
              isDense: true,
              style: AppTextStyles.textLabelMd
                  .copyWith(color: AppColors.colorTextPrimary),
              dropdownColor: AppColors.colorBgCard,
              items: _years
                  .map((y) => DropdownMenuItem(value: y, child: Text('$y년')))
                  .toList(),
              onChanged: (y) {
                if (y != null) vm.selectYearMonth(y, vm.selectedMonth);
              },
            ),
          ),
          const SizedBox(width: 8),
          _DropdownContainer(
            child: DropdownButton<int>(
              value: vm.selectedMonth,
              underline: const SizedBox.shrink(),
              isDense: true,
              style: AppTextStyles.textLabelMd
                  .copyWith(color: AppColors.colorTextPrimary),
              dropdownColor: AppColors.colorBgCard,
              items: List.generate(12, (i) => i + 1)
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('${m.toString().padLeft(2, '0')}월'),
                      ))
                  .toList(),
              onChanged: (m) {
                if (m != null) vm.selectYearMonth(vm.selectedYear, m);
              },
            ),
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.chevron_right,
            onPressed: vm.goNextMonth,
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.refresh,
            color: AppColors.colorTextSecondary,
            onPressed: vm.resetToToday,
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: expanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.colorTextSecondary,
            onPressed: onToggleExpanded,
          ),
        ],
      ),
    );
  }
}

class _DropdownContainer extends StatelessWidget {
  const _DropdownContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.color = AppColors.colorAccentTeal,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.colorBgCard,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _PeriodPillRow extends StatelessWidget {
  const _PeriodPillRow({required this.vm, required this.onSelected});

  final DashboardPeriodViewModel vm;
  final VoidCallback onSelected;

  static const _presets = [
    DashboardPeriod.thisMonth,
    DashboardPeriod.thisQuarter,
    DashboardPeriod.thisHalfYear,
    DashboardPeriod.thisYear,
    DashboardPeriod.custom,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _presets.map((p) {
          final isSelected = vm.period == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onTap(context, p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.colorAccentTeal
                      : AppColors.colorBgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.colorAccentTeal
                        : AppColors.colorDivider,
                  ),
                ),
                child: Text(
                  _label(p),
                  style: AppTextStyles.textBodySm.copyWith(
                    color: isSelected
                        ? AppColors.colorBgMain
                        : AppColors.colorTextSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, DashboardPeriod p) async {
    if (p != DashboardPeriod.custom) {
      vm.select(p);
      onSelected();
      return;
    }
    final now = DateTime.now();
    final initStart = vm.customStart ?? DateTime(now.year, now.month, 1);
    final initEnd = vm.customEnd ?? now;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.colorBgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MonthRangePickerSheet(
        initialStart: initStart,
        initialEnd: initEnd,
        onConfirm: vm.setCustomRange,
      ),
    );
    onSelected();
  }

  String _label(DashboardPeriod p) => switch (p) {
        DashboardPeriod.singleMonth => vm.label,
        DashboardPeriod.thisMonth => '이번 달',
        DashboardPeriod.thisQuarter => '직전 3개월',
        DashboardPeriod.thisHalfYear => '직전 6개월',
        DashboardPeriod.thisYear => '올해',
        DashboardPeriod.custom => vm.customLabel,
      };
}

class _MonthRangePickerSheet extends StatefulWidget {
  const _MonthRangePickerSheet({
    required this.initialStart,
    required this.initialEnd,
    required this.onConfirm,
  });

  final DateTime initialStart;
  final DateTime initialEnd;
  final void Function(DateTime start, DateTime end) onConfirm;

  @override
  State<_MonthRangePickerSheet> createState() => _MonthRangePickerSheetState();
}

class _MonthRangePickerSheetState extends State<_MonthRangePickerSheet> {
  late int _startYear;
  late int _startMonth;
  late int _endYear;
  late int _endMonth;

  @override
  void initState() {
    super.initState();
    _startYear = widget.initialStart.year;
    _startMonth = widget.initialStart.month;
    _endYear = widget.initialEnd.year;
    _endMonth = widget.initialEnd.month;
  }

  List<int> get _years {
    final now = DateTime.now();
    return List.generate(6, (i) => now.year - 5 + i);
  }

  bool get _isValid =>
      !DateTime(_startYear, _startMonth).isAfter(DateTime(_endYear, _endMonth));

  void _confirm() {
    widget.onConfirm(
      DateTime(_startYear, _startMonth, 1),
      DateTime(_endYear, _endMonth, 1),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.colorDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '커스텀 기간 선택',
            style: AppTextStyles.textBodySm
                .copyWith(color: AppColors.colorTextSecondary),
          ),
          const SizedBox(height: 16),
          _buildRow(
            '시작',
            _startYear,
            _startMonth,
            (y, m) => setState(() {
              _startYear = y;
              _startMonth = m;
            }),
          ),
          const SizedBox(height: 12),
          _buildRow(
            '종료',
            _endYear,
            _endMonth,
            (y, m) => setState(() {
              _endYear = y;
              _endMonth = m;
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isValid ? _confirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.colorAccentTeal,
                foregroundColor: AppColors.colorBgMain,
              ),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    int year,
    int month,
    void Function(int y, int m) onChange,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: AppTextStyles.textBodySm
                .copyWith(color: AppColors.colorTextPrimary),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: year,
          dropdownColor: AppColors.colorBgCard,
          style: AppTextStyles.textBodySm
              .copyWith(color: AppColors.colorTextPrimary),
          underline: const SizedBox.shrink(),
          items: _years
              .map((y) =>
                  DropdownMenuItem(value: y, child: Text('$y년')))
              .toList(),
          onChanged: (y) {
            if (y != null) onChange(y, month);
          },
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: month,
          dropdownColor: AppColors.colorBgCard,
          style: AppTextStyles.textBodySm
              .copyWith(color: AppColors.colorTextPrimary),
          underline: const SizedBox.shrink(),
          items: List.generate(12, (i) => i + 1)
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text('${m.toString().padLeft(2, '0')}월'),
                  ))
              .toList(),
          onChanged: (m) {
            if (m != null) onChange(year, m);
          },
        ),
      ],
    );
  }
}
