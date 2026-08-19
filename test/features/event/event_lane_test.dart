import 'package:account_book_vibe/data/models/event_model.dart';
import 'package:account_book_vibe/data/models/member_model.dart';
import 'package:account_book_vibe/features/event/event_form_screen.dart';
import 'package:account_book_vibe/features/event/event_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

EventListResponse _event(
  int id,
  String strtDt,
  String endDt, {
  String strtTm = '',
  String endTm = '',
}) =>
    EventListResponse(
      eventId: id,
      eventTypeCd: 'SCHEDULE',
      eventTypeNm: '일정',
      eventNm: '일정 $id',
      contents: '',
      strtDt: strtDt,
      endDt: endDt,
      strtTm: strtTm,
      endTm: endTm,
      memberId: '',
      memberNm: '',
    );

void main() {
  group('dayList — 기간 양끝 포함', () {
    test('하루짜리는 그 날 하나', () {
      expect(_event(1, '20260810', '20260810').dayList,
          [DateTime(2026, 8, 10)]);
    });

    test('8/10~8/12 는 종료일 포함 3일', () {
      expect(_event(1, '20260810', '20260812').dayList, [
        DateTime(2026, 8, 10),
        DateTime(2026, 8, 11),
        DateTime(2026, 8, 12),
      ]);
    });

    test('월을 넘겨도 이어진다', () {
      expect(_event(1, '20260830', '20260902').dayList.length, 4);
    });
  });

  group('assignEventLanes', () {
    test('겹치지 않는 일정은 모두 0번 레인을 쓴다', () {
      final lanes = assignEventLanes([
        _event(1, '20260810', '20260811'),
        _event(2, '20260812', '20260813'),
      ]);

      expect(lanes[1], 0);
      expect(lanes[2], 0);
    });

    test('하루라도 겹치면 다른 레인으로 밀린다', () {
      final lanes = assignEventLanes([
        _event(1, '20260810', '20260812'),
        _event(2, '20260812', '20260814'),
      ]);

      expect(lanes[1], 0);
      expect(lanes[2], 1);
    });

    test('긴 일정이 위 레인을 잡고 짧은 일정이 빈틈을 메운다', () {
      final lanes = assignEventLanes([
        _event(2, '20260810', '20260810'),
        _event(1, '20260810', '20260815'),
        _event(3, '20260812', '20260812'),
      ]);

      expect(lanes[1], 0, reason: '가장 긴 일정이 0번');
      expect(lanes[2], 1);
      // 2번과 3번은 서로 겹치지 않으므로 같은 레인을 재사용한다.
      expect(lanes[3], 1);
    });

    test('여러 날 일정은 걸치는 모든 날에서 같은 레인을 유지한다', () {
      final lanes = assignEventLanes([
        _event(1, '20260810', '20260820'),
        _event(2, '20260811', '20260811'),
        _event(3, '20260818', '20260818'),
      ]);

      expect(lanes[1], 0);
      expect(lanes[2], 1);
      expect(lanes[3], 1);
    });

    test('세 건이 한 날에 겹치면 0·1·2 로 쌓인다', () {
      final lanes = assignEventLanes([
        _event(1, '20260810', '20260810'),
        _event(2, '20260810', '20260810'),
        _event(3, '20260810', '20260810'),
      ]);

      expect(<int>{lanes[1]!, lanes[2]!, lanes[3]!}, <int>{0, 1, 2});
    });
  });

  _memberOptionsTests();

  group('formatApiDate / parseApiDate', () {
    test('왕복 변환', () {
      expect(formatApiDate(DateTime(2026, 8, 5)), '20260805');
      expect(parseApiDate('20260805'), DateTime(2026, 8, 5));
    });
  });
}

// ── memberOptions ────────────────────────────────────────────────────────────

MemberListResponse _member(String id, String name) =>
    MemberListResponse(memberId: id, memberNm: name);

void _memberOptionsTests() {
  group('memberOptions', () {
    test('목록이 오기 전에도 수정 대상 멤버가 항목에 있다', () {
      // 항목에 없는 값을 DropdownButton에 주면 assert로 죽는다.
      final options = memberOptions(const [], '1', '강원');

      expect(options.map((o) => o.id), contains('1'));
      expect(options.where((o) => o.id == '1').single.name, '강원');
    });

    test('목록에 이미 있으면 중복으로 넣지 않는다', () {
      final options = memberOptions([_member('1', '강원')], '1', '강원');

      expect(options.where((o) => o.id == '1'), hasLength(1));
    });

    test('멤버 미지정이면 목록 그대로', () {
      final options = memberOptions([_member('1', '강원')], '', '');

      expect(options.map((o) => o.id), <String>['', '1']);
    });

    test('이름을 모르면 id로 표기한다', () {
      expect(memberOptions(const [], '9', '').last.name, '9');
    });
  });
}
