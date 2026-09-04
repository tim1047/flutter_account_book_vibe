import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/event_type.dart';
import 'package:account_book_vibe/data/models/event_model.dart';
import 'package:account_book_vibe/features/event/event_card.dart';
import 'package:account_book_vibe/features/event/event_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/year_month_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// 한 칸에 보여줄 최대 막대 수. 넘치면 마지막 줄이 `+N`으로 바뀐다.
const int _maxLanes = 3;
const double _barHeight = 14;
const double _barGap = 2;

Color? _weekdayColor(int weekday) {
  if (weekday == DateTime.saturday) return AppColors.colorInfo;
  if (weekday == DateTime.sunday) return AppColors.colorError;
  return null;
}

/// 월간 캘린더. 여러 날 일정은 날짜 칸마다 조각을 그려 하나의 기간 막대처럼
/// 이어 붙인다. `table_calendar`의 `rangeStartDay`/`rangeEndDay`는 사용자가
/// 고르는 단일 구간 전용이라 쓸 수 없다.
class EventCalendarTab extends StatelessWidget {
  const EventCalendarTab({
    super.key,
    required this.vm,
    required this.onEditEvent,
  });

  final EventViewModel vm;
  final ValueChanged<EventListResponse> onEditEvent;

  /// 보고 있는 달은 ViewModel이 단일 소유한다. 타임라인 탭에서 달을 바꿔도
  /// 여기 캘린더가 같은 달을 따라가게 하려고 로컬 상태를 두지 않는다.
  DateTime get _focusedDay => DateTime(vm.year, vm.month);

  static String _formatHeaderTitle(DateTime date, dynamic locale) =>
      '${date.year}년 ${date.month}월';

  static const List<String> _weekdayLabels = <String>[
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
    '일',
  ];

  void _goToMonth(DateTime month) {
    if (month.year == vm.year && month.month == vm.month) return;
    vm.setMonth(month.year, month.month);
    vm.load();
  }

  Future<void> _onHeaderTapped(BuildContext context) async {
    final selected = await YearMonthPickerDialog.show(
      context,
      year: vm.year,
      month: vm.month,
    );
    if (selected == null) return;
    _goToMonth(selected);
  }

  void _onDaySelected(BuildContext context, DateTime selectedDay) {
    final events = vm.eventsOn(selectedDay);
    if (events.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.colorBgMain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _DaySheet(
        day: selectedDay,
        events: events,
        onEditEvent: (event) {
          Navigator.of(sheetContext).pop();
          onEditEvent(event);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final error = vm.errorMessage;
        return Column(
          children: [
            TableCalendar<EventListResponse>(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: _focusedDay,
              rowHeight: 72,
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
              calendarBuilders: CalendarBuilders<EventListResponse>(
                dowBuilder: (context, day) => Center(
                  child: Text(
                    _weekdayLabels[day.weekday - 1],
                    style: AppTextStyles.textCaption.copyWith(
                      color: _weekdayColor(day.weekday),
                    ),
                  ),
                ),
                defaultBuilder: (context, day, focusedDay) =>
                    _DayCell(vm: vm, day: day),
                todayBuilder: (context, day, focusedDay) =>
                    _DayCell(vm: vm, day: day, isToday: true),
                selectedBuilder: (context, day, focusedDay) =>
                    _DayCell(vm: vm, day: day),
                // 지난달·다음달 칸은 비워 둔다. 걸쳐 있는 일정은 이번 달
                // 구간만 막대로 보인다.
                outsideBuilder: (context, day, focusedDay) =>
                    const SizedBox.shrink(),
              ),
              onPageChanged: _goToMonth,
              onDaySelected: (selectedDay, _) =>
                  _onDaySelected(context, selectedDay),
              onHeaderTapped: (_) => _onHeaderTapped(context),
            ),
            const Divider(height: 1, color: AppColors.colorDivider),
            const _TypeLegend(),
            if (error != null)
              Expanded(
                child: ErrorView(message: error, onRetry: vm.load),
              )
            else
              const Spacer(),
          ],
        );
      },
    );
  }
}

/// 날짜 숫자 + 기간 막대들. 커스텀 빌더를 쓰면 `cellMargin`이 붙지 않으므로
/// 칸 전체 폭을 채우는 막대끼리 좌우로 맞닿아 연속된 띠로 보인다.
class _DayCell extends StatelessWidget {
  const _DayCell({required this.vm, required this.day, this.isToday = false});

  final EventViewModel vm;
  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final events = vm.eventsOn(day);
    final isHoliday =
        events.any((event) => event.eventTypeCd == EventType.holiday);
    final byLane = <int, EventListResponse>{
      for (final event in events) vm.laneOf(event): event,
    };
    // 넘치는 게 있으면 마지막 줄을 `+N` 표기에 내주므로 그만큼 덜 보인다.
    final overflows = events.any((event) => vm.laneOf(event) >= _maxLanes);
    final visibleLanes = overflows ? _maxLanes - 1 : _maxLanes;
    final hiddenCount =
        events.where((event) => vm.laneOf(event) >= visibleLanes).length;

    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              textAlign: TextAlign.center,
              style: AppTextStyles.textCaption.copyWith(
                color: isToday
                    ? AppColors.colorAccentTeal
                    : isHoliday
                        ? AppColors.colorError
                        : _weekdayColor(day.weekday) ??
                            AppColors.colorTextPrimary,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            for (var lane = 0; lane < visibleLanes; lane++)
              if (byLane[lane] != null)
                _EventBar(
                  event: byLane[lane]!,
                  day: day,
                  cellWidth: constraints.maxWidth,
                )
              else
                const SizedBox(height: _barHeight + _barGap),
            if (hiddenCount > 0) _MoreLabel(count: hiddenCount),
          ],
        ),
      ),
    );
  }
}

/// 하루치 막대 조각. 일정의 시작·끝이거나 주가 바뀌는 자리에서만 모서리를
/// 둥글리고 안쪽 여백을 준다. 중간 날짜는 각져 있어 옆 칸과 붙는다.
///
/// 일정명은 구간(이번 주에서 이 일정이 차지하는 연속된 칸들) 전체를 가로지르는
/// 한 줄로 보인다. 칸마다 독립 셀이라 텍스트가 칸 경계를 넘어갈 수 없으므로,
/// 모든 칸이 같은 이름을 그리되 자기 순번만큼 왼쪽으로 밀고 막대 밖은 잘라낸다.
/// 잘린 조각들이 이어 붙어 한 줄처럼 읽힌다.
class _EventBar extends StatelessWidget {
  const _EventBar({
    required this.event,
    required this.day,
    required this.cellWidth,
  });

  final EventListResponse event;
  final DateTime day;
  final double cellWidth;

  @override
  Widget build(BuildContext context) {
    final isSegmentStart =
        isSameDay(day, event.startDate) || day.weekday == DateTime.sunday;
    final isSegmentEnd =
        isSameDay(day, event.endDate) || day.weekday == DateTime.saturday;
    final color = EventType.colorOf(event.eventTypeCd);
    final marginLeft = isSegmentStart ? 2.0 : 0.0;

    return Container(
      height: _barHeight,
      margin: EdgeInsets.only(
        bottom: _barGap,
        left: marginLeft,
        right: isSegmentEnd ? 2 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(isSegmentStart ? 4 : 0),
          right: Radius.circular(isSegmentEnd ? 4 : 0),
        ),
      ),
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        // 한 구간은 길어야 7칸이라 이만큼이면 이름이 미리 잘리지 않는다.
        maxWidth: cellWidth * 7,
        child: Transform.translate(
          // 구간 첫 칸의 글자 시작점(칸 왼쪽 + margin 2 + padding 3)에 맞춰
          // 이 칸 몫만큼 왼쪽으로 민다.
          offset: Offset(
            2 - marginLeft - segmentIndexOf(event, day) * cellWidth,
            0,
          ),
          child: Text(
            event.eventNm,
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            style: AppTextStyles.textCaption.copyWith(
              color: AppColors.colorBgMain,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// `day`가 이번 주 구간의 몇 번째 칸인지(구간 시작 칸이 0). 구간은 일요일이나
/// 일정 시작일 중 늦은 쪽에서 시작한다.
///
/// `table_calendar`가 넘겨주는 `day`는 UTC 자정이고 `event.startDate`는 로컬
/// 자정이라 그대로 빼면 시차만큼 어긋난다. 로컬 자정으로 맞춘 뒤 센다.
@visibleForTesting
int segmentIndexOf(EventListResponse event, DateTime day) {
  final localDay = DateTime(day.year, day.month, day.day);
  final weekStart = DateTime(day.year, day.month, day.day - day.weekday % 7);
  final segmentStart =
      event.startDate.isAfter(weekStart) ? event.startDate : weekStart;
  return (localDay.difference(segmentStart).inHours / 24).round();
}

class _MoreLabel extends StatelessWidget {
  const _MoreLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _barHeight + _barGap,
      child: Text(
        '+$count',
        textAlign: TextAlign.center,
        style: AppTextStyles.textCaption.copyWith(
          color: AppColors.colorTextSecondary,
        ),
      ),
    );
  }
}

class _TypeLegend extends StatelessWidget {
  const _TypeLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: <Widget>[
          for (final code in EventType.all)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: EventType.colorOf(code),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  EventType.nameOf(code),
                  style: AppTextStyles.textCaption.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({
    required this.day,
    required this.events,
    required this.onEditEvent,
  });

  final DateTime day;
  final List<EventListResponse> events;
  final ValueChanged<EventListResponse> onEditEvent;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.month}월 ${day.day}일',
              style: AppTextStyles.textHeadlineMd,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => EventCard(
                  event: events[index],
                  onTap: () => onEditEvent(events[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
