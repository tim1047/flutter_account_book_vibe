import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:flutter/material.dart';

class DateFilterBar extends StatelessWidget {
  const DateFilterBar({
    super.key,
    required this.viewModel,
    required this.onRefresh,
  });

  final DateFilterViewModel viewModel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.colorBgSub,
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FilterIconButton(
              icon: Icons.chevron_left,
              color: AppColors.colorAccentTeal,
              onPressed: () {
                viewModel.goPrev();
                onRefresh();
              },
            ),
            const SizedBox(width: 8),
            _YearDropdown(viewModel: viewModel, onChanged: onRefresh),
            const SizedBox(width: 8),
            _MonthDropdown(viewModel: viewModel, onChanged: onRefresh),
            const SizedBox(width: 8),
            _FilterIconButton(
              icon: Icons.chevron_right,
              color: AppColors.colorAccentTeal,
              onPressed: () {
                viewModel.goNext();
                onRefresh();
              },
            ),
            const SizedBox(width: 8),
            _FilterIconButton(
              icon: Icons.refresh,
              color: AppColors.colorTextSecondary,
              onPressed: () {
                viewModel.setToday();
                onRefresh();
              },
            ),
          ],
        ),
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

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
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

class _YearDropdown extends StatelessWidget {
  const _YearDropdown({required this.viewModel, required this.onChanged});

  final DateFilterViewModel viewModel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(currentYear - 2019, (i) => currentYear - i);

    return _DropdownContainer(
      child: DropdownButton<int>(
        value: viewModel.selectedYear,
        underline: const SizedBox.shrink(),
        isDense: true,
        style: AppTextStyles.textLabelMd.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        dropdownColor: AppColors.colorBgCard,
        items: years
            .map(
              (y) => DropdownMenuItem(
                value: y,
                child: Text('$y년'),
              ),
            )
            .toList(),
        onChanged: (y) {
          if (y != null) {
            viewModel.setYear(y);
            onChanged();
          }
        },
      ),
    );
  }
}

class _MonthDropdown extends StatelessWidget {
  const _MonthDropdown({required this.viewModel, required this.onChanged});

  final DateFilterViewModel viewModel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final months = [
      const DropdownMenuItem(value: 0, child: Text('전체')),
      ...List.generate(
        12,
        (i) => DropdownMenuItem(
          value: i + 1,
          child: Text('${(i + 1).toString().padLeft(2, '0')}월'),
        ),
      ),
    ];

    return _DropdownContainer(
      child: DropdownButton<int>(
        value: viewModel.selectedMonth,
        underline: const SizedBox.shrink(),
        isDense: true,
        style: AppTextStyles.textLabelMd.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        dropdownColor: AppColors.colorBgCard,
        items: months,
        onChanged: (m) {
          if (m != null) {
            viewModel.setMonth(m);
            onChanged();
          }
        },
      ),
    );
  }
}
