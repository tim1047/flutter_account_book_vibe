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

  static String _pad(int n) => n.toString().padLeft(2, '0');

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
          return TableCalendar<void>(
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
          _AmountLine(amount: summary.income, color: AppColors.colorIncome),
          _AmountLine(amount: summary.expense, color: AppColors.colorExpense),
          _AmountLine(amount: summary.invest, color: AppColors.colorInvest),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.amount, required this.color});

  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      FormatUtil.formatPrice(amount),
      style: AppTextStyles.textCaption.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
