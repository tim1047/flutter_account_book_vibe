import 'package:account_book_vibe/data/models/event_model.dart';
import 'package:account_book_vibe/features/event/event_calendar_tab.dart';
import 'package:account_book_vibe/features/event/event_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EventListResponse _event(int id, String name, String strtDt, String endDt) =>
    EventListResponse(
      eventId: id,
      eventTypeCd: 'VACATION',
      eventTypeNm: '휴가',
      eventNm: name,
      contents: '',
      strtDt: strtDt,
      endDt: endDt,
      strtTm: '',
      endTm: '',
      memberId: '',
      memberNm: '',
    );

Future<void> _pump(WidgetTester tester, EventViewModel vm) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: EventCalendarTab(vm: vm, onEditEvent: (_) {}),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('한 칸에 막대가 꽉 차도 오버플로가 나지 않는다', (tester) async {
    final vm = EventViewModel(initialMonth: DateTime(2026, 8))
      ..applyEvents([
        _event(1, '제주도 여행', '20260810', '20260812'),
        _event(2, '워크샵', '20260810', '20260810'),
        _event(3, '건강검진', '20260810', '20260810'),
        _event(4, '넘치는 일정', '20260810', '20260810'),
      ]);

    await _pump(tester, vm);

    expect(tester.takeException(), isNull);
    // 4건 중 2건만 막대로 보이고 나머지는 +2로 접힌다.
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('여러 날 일정은 걸치는 날마다 막대 조각이 그려진다', (tester) async {
    final vm = EventViewModel(initialMonth: DateTime(2026, 8))
      ..applyEvents([_event(1, '제주도 여행', '20260810', '20260812')]);

    await _pump(tester, vm);

    // 이름은 구간이 시작하는 칸에서만 그린다. 8/10은 월요일이라 주 시작(일요일)
    // 칸이 따로 없어 라벨은 한 번만 나온다.
    expect(find.text('제주도 여행'), findsOneWidget);
    expect(vm.eventsOn(DateTime(2026, 8, 11)), hasLength(1));
    expect(vm.eventsOn(DateTime(2026, 8, 13)), isEmpty);
  });
}
