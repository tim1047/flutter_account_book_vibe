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

    // 이름은 구간이 걸치는 칸마다 그려지고, 칸별로 왼쪽으로 밀려 한 줄로
    // 이어 붙는다. 8/10~8/12는 월~수라 한 주 안에 있으니 칸 3개.
    expect(find.text('제주도 여행'), findsNWidgets(3));
    expect(vm.eventsOn(DateTime(2026, 8, 11)), hasLength(1));
    expect(vm.eventsOn(DateTime(2026, 8, 13)), isEmpty);

    // 세 조각이 같은 글자를 같은 자리에서 시작하도록 밀려 있어야 한 줄로
    // 읽힌다. 어긋나면 칸마다 이름이 처음부터 다시 보인다.
    final origins = tester
        .widgetList<Text>(find.text('제주도 여행'))
        .map((text) => tester.getTopLeft(find.byWidget(text)).dx)
        .toList();
    expect(origins[1], moreOrLessEquals(origins[0], epsilon: 0.5));
    expect(origins[2], moreOrLessEquals(origins[0], epsilon: 0.5));
  });

  group('segmentIndexOf', () {
    // 2026-08-09는 일요일, 08-10은 월요일.
    test('구간 첫 칸이 0, 이어지는 칸마다 1씩 는다', () {
      final event = _event(1, '제주도 여행', '20260810', '20260812');

      expect(segmentIndexOf(event, DateTime.utc(2026, 8, 10)), 0);
      expect(segmentIndexOf(event, DateTime.utc(2026, 8, 11)), 1);
      expect(segmentIndexOf(event, DateTime.utc(2026, 8, 12)), 2);
    });

    test('주가 바뀌면 일요일 칸에서 0부터 다시 센다', () {
      final event = _event(1, '여름 휴가', '20260807', '20260811');

      expect(segmentIndexOf(event, DateTime.utc(2026, 8, 7)), 0);
      expect(segmentIndexOf(event, DateTime.utc(2026, 8, 8)), 1);
      expect(segmentIndexOf(event, DateTime.utc(2026, 8, 9)), 0);
      expect(segmentIndexOf(event, DateTime.utc(2026, 8, 10)), 1);
    });

    // table_calendar는 UTC 자정을, 모델은 로컬 자정을 준다. 둘을 섞어 빼면
    // 시차만큼 어긋나므로 어느 쪽이 들어와도 같은 값이 나와야 한다.
    test('UTC 날짜와 로컬 날짜가 같은 값을 낸다', () {
      final event = _event(1, '제주도 여행', '20260810', '20260812');

      expect(
        segmentIndexOf(event, DateTime.utc(2026, 8, 12)),
        segmentIndexOf(event, DateTime(2026, 8, 12)),
      );
    });
  });
}
