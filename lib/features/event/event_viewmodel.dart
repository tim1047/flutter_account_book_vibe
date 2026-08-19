import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/event_model.dart';
import 'package:account_book_vibe/data/services/event_service.dart';
import 'package:flutter/foundation.dart';

/// 타임라인 한 덩어리 — 날짜 헤더 + 그 날 시작하는 일정들.
class EventDayGroup {
  const EventDayGroup(this.day, this.events);

  final DateTime day;
  final List<EventListResponse> events;
}

/// 여러 날 일정이 날짜가 바뀌어도 같은 줄에 놓이도록 레인(줄 번호)을 배정한다.
///
/// 시작일 → 긴 기간 → `eventId` 순으로 훑으며 그 일정이 걸치는 모든 날에서
/// 비어 있는 가장 낮은 레인을 잡는다. 월 단위로 한 번만 계산하므로 주가
/// 바뀌어도 막대가 위아래로 튀지 않는다.
///
/// ponytail: 일정 수 × 기간 길이의 단순 스캔. 한 달치(수십 건) 기준이라
/// 충분하다. 몇 백 건 단위로 커지면 구간 트리로 바꿀 것.
Map<int, int> assignEventLanes(List<EventListResponse> events) {
  final sorted = <EventListResponse>[...events]..sort((a, b) {
      final byStart = a.strtDt.compareTo(b.strtDt);
      if (byStart != 0) return byStart;
      // 긴 일정이 위쪽 레인을 차지해야 짧은 일정이 빈틈을 메운다.
      final byEnd = b.endDt.compareTo(a.endDt);
      if (byEnd != 0) return byEnd;
      return a.eventId.compareTo(b.eventId);
    });

  final occupied = <DateTime, Set<int>>{};
  final lanes = <int, int>{};
  for (final event in sorted) {
    final days = event.dayList;
    var lane = 0;
    while (days.any((d) => occupied[d]?.contains(lane) ?? false)) {
      lane++;
    }
    for (final d in days) {
      (occupied[d] ??= <int>{}).add(lane);
    }
    lanes[event.eventId] = lane;
  }
  return lanes;
}

class EventViewModel extends ChangeNotifier {
  EventViewModel({DateTime? initialMonth})
      : year = (initialMonth ?? DateTime.now()).year,
        month = (initialMonth ?? DateTime.now()).month;

  int year;
  int month;

  bool isLoading = false;
  String? errorMessage;

  List<EventListResponse> events = <EventListResponse>[];

  /// 날짜(자정 기준) → 그 날 걸치는 일정들. 여러 날 일정은 모든 날에 들어간다.
  Map<DateTime, List<EventListResponse>> byDay = <DateTime, List<EventListResponse>>{};

  Map<int, int> lanes = <int, int>{};

  List<EventDayGroup> timelineGroups = <EventDayGroup>[];

  DateTime get monthStart => DateTime(year, month, 1);
  DateTime get monthEnd => DateTime(year, month + 1, 0);

  void setMonth(int y, int m) {
    year = y;
    month = m;
  }

  List<EventListResponse> eventsOn(DateTime day) =>
      byDay[DateTime(day.year, day.month, day.day)] ?? const [];

  int laneOf(EventListResponse event) => lanes[event.eventId] ?? 0;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      applyEvents(await EventService.instance.getEvents(
        strtDt: formatApiDate(monthStart),
        endDt: formatApiDate(monthEnd),
      ));
    } on AppException catch (e) {
      errorMessage = e.message;
      applyEvents(<EventListResponse>[]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 목록을 갈아 끼우고 날짜별 색인·레인·타임라인 묶음을 다시 만든다.
  void applyEvents(List<EventListResponse> loaded) {
    events = loaded;
    byDay = <DateTime, List<EventListResponse>>{};
    for (final event in events) {
      for (final day in event.dayList) {
        (byDay[day] ??= <EventListResponse>[]).add(event);
      }
    }
    lanes = assignEventLanes(events);

    // 타임라인은 시작일에 한 번만 노출한다. 지난달에 시작해 이번 달로
    // 이어지는 일정은 조회 기간 첫 날로 당겨 붙인다.
    final groups = <DateTime, List<EventListResponse>>{};
    for (final event in events) {
      final key =
          event.startDate.isBefore(monthStart) ? monthStart : event.startDate;
      (groups[key] ??= <EventListResponse>[]).add(event);
    }
    final keys = groups.keys.toList()..sort();
    timelineGroups = <EventDayGroup>[
      for (final key in keys) EventDayGroup(key, groups[key]!),
    ];
  }
}
