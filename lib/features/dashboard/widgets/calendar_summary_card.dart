import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/calendar_summary_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarSummaryCard extends StatefulWidget {
  const CalendarSummaryCard({super.key, required this.vm});

  final CalendarSummaryViewModel vm;

  @override
  State<CalendarSummaryCard> createState() => _CalendarSummaryCardState();
}

class _CalendarSummaryCardState extends State<CalendarSummaryCard> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(widget.vm.year, widget.vm.month);
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() => _focusedDay = focusedDay);
    widget.vm.setMonth(focusedDay.year, focusedDay.month);
    widget.vm.load();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final date = '${selectedDay.year}${_pad(selectedDay.month)}${_pad(selectedDay.day)}';
    context.push('/accountList', extra: AccountListExtra(date: date));
  }

  Future<void> _onHeaderTapped(DateTime focusedDay) async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => _YearMonthPickerDialog(
        initialYear: widget.vm.year,
        initialMonth: widget.vm.month,
      ),
    );
    if (selected == null) return;
    setState(() => _focusedDay = selected);
    widget.vm.setMonth(selected.year, selected.month);
    widget.vm.load();
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _formatHeaderTitle(DateTime date, dynamic locale) =>
      '${date.year}년 ${date.month}월';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorBgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ColorLegend(),
              const SizedBox(height: 8),
              TableCalendar<void>(
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime(2035, 12, 31),
                focusedDay: _focusedDay,
                rowHeight: 76,
                daysOfWeekHeight: 20,
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: AppTextStyles.textHeadlineSm,
                  titleTextFormatter: _formatHeaderTitle,
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppColors.colorAccentTeal,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppColors.colorAccentTeal,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: AppTextStyles.textCaption,
                  weekendStyle: AppTextStyles.textCaption,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) =>
                      _DayCell(day: day, summary: widget.vm.summaryFor(day)),
                  todayBuilder: (context, day, focusedDay) => _DayCell(
                    day: day,
                    summary: widget.vm.summaryFor(day),
                    isToday: true,
                  ),
                  outsideBuilder: (context, day, focusedDay) =>
                      const SizedBox.shrink(),
                ),
                onPageChanged: _onPageChanged,
                onDaySelected: _onDaySelected,
                onHeaderTapped: _onHeaderTapped,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.summary,
    this.isToday = false,
  });

  final DateTime day;
  final CalendarDaySummary summary;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: isToday
          ? BoxDecoration(
              border: Border.all(color: AppColors.colorAccentTeal),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: AppTextStyles.textCaption.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          if (summary.income != 0)
            _AmountLine(amount: summary.income, color: AppColors.colorIncome, sign: '+'),
          if (summary.expense != 0)
            _AmountLine(amount: summary.expense, color: AppColors.colorExpense, sign: '-'),
          if (summary.invest != 0)
            _AmountLine(amount: summary.invest, color: AppColors.colorInvest, sign: '+'),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.amount,
    required this.color,
    required this.sign,
  });

  final int amount;
  final Color color;
  final String sign;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$sign${FormatUtil.formatPrice(amount)}',
      style: AppTextStyles.textCaption.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ColorLegend extends StatelessWidget {
  const _ColorLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(label: '수입', color: AppColors.colorIncome),
        SizedBox(width: 16),
        _LegendItem(label: '지출', color: AppColors.colorExpense),
        SizedBox(width: 16),
        _LegendItem(label: '투자', color: AppColors.colorInvest),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.textCaption.copyWith(
            color: AppColors.colorTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _YearMonthPickerDialog extends StatefulWidget {
  const _YearMonthPickerDialog({
    required this.initialYear,
    required this.initialMonth,
  });

  final int initialYear;
  final int initialMonth;

  @override
  State<_YearMonthPickerDialog> createState() =>
      _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
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
            icon: const Icon(Icons.chevron_left, color: AppColors.colorAccentTeal),
            onPressed: () => setState(() => _year--),
          ),
          Text('$_year년', style: AppTextStyles.textHeadlineSm),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.colorAccentTeal),
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
