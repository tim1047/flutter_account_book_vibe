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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.colorAccentTeal,
            onPrimary: AppColors.colorBgMain,
            surface: AppColors.colorBgCard,
            onSurface: AppColors.colorTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      vm.setCustomRange(picked.start, picked.end);
    }
  }

  String _label(DashboardPeriod p) => switch (p) {
        DashboardPeriod.thisMonth => '이번 달',
        DashboardPeriod.thisQuarter => '이번 분기',
        DashboardPeriod.thisYear => '올해',
        DashboardPeriod.custom => vm.customLabel,
      };
}
