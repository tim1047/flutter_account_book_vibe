import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key, required this.vm});

  final DashboardPeriodViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: DashboardPeriod.values.map((p) {
            final isSelected = vm.period == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onTap(context, p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
      ),
    );
  }

  Future<void> _onTap(BuildContext context, DashboardPeriod p) async {
    if (p != DashboardPeriod.custom) {
      vm.select(p);
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
  }

  String _label(DashboardPeriod p) => switch (p) {
        DashboardPeriod.thisMonth => '이번 달',
        DashboardPeriod.thisQuarter => '이번 분기',
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
