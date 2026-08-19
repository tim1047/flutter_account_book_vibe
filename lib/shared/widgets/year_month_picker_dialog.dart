import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// 캘린더 헤더를 눌렀을 때 뜨는 연/월 선택 다이얼로그.
/// 선택하면 해당 월 1일의 [DateTime]을, 취소하면 null을 돌려준다.
class YearMonthPickerDialog extends StatefulWidget {
  const YearMonthPickerDialog({
    super.key,
    required this.initialYear,
    required this.initialMonth,
  });

  final int initialYear;
  final int initialMonth;

  static Future<DateTime?> show(
    BuildContext context, {
    required int year,
    required int month,
  }) =>
      showDialog<DateTime>(
        context: context,
        builder: (_) =>
            YearMonthPickerDialog(initialYear: year, initialMonth: month),
      );

  @override
  State<YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<YearMonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.colorBgCard,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left,
                color: AppColors.colorAccentTeal),
            onPressed: () => setState(() => _year--),
          ),
          Text('$_year년', style: AppTextStyles.textHeadlineSm),
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: AppColors.colorAccentTeal),
            onPressed: () => setState(() => _year++),
          ),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(12, (i) {
            final month = i + 1;
            final isSelected =
                _year == widget.initialYear && month == widget.initialMonth;
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(DateTime(_year, month)),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.colorAccentTeal
                      : AppColors.colorBgMain,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$month월',
                  style: AppTextStyles.textBodySm.copyWith(
                    color: isSelected
                        ? AppColors.colorBgMain
                        : AppColors.colorTextPrimary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
