import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

/// 일정 1건. `GET /account-book/event`
///
/// 서버가 `null` 대신 빈 문자열을 주므로 nullable 필드가 없다.
/// 기간은 `[strtDt, endDt]` 양끝 포함(inclusive)이다.
@JsonSerializable(createToJson: false)
class EventListResponse {
  const EventListResponse({
    required this.eventId,
    required this.eventTypeCd,
    required this.eventTypeNm,
    required this.eventNm,
    required this.contents,
    required this.strtDt,
    required this.endDt,
    required this.strtTm,
    required this.endTm,
    required this.memberId,
    required this.memberNm,
  });

  final int eventId;
  final String eventTypeCd;
  final String eventTypeNm;
  final String eventNm;
  final String contents;

  /// `YYYYMMDD`
  final String strtDt;

  /// `YYYYMMDD`. 이 날짜까지 포함한다.
  final String endDt;

  /// `HH:MM` 또는 종일 일정이면 `""`
  final String strtTm;
  final String endTm;

  /// `""` 면 멤버 미지정
  final String memberId;
  final String memberNm;

  factory EventListResponse.fromJson(Map<String, dynamic> json) =>
      _$EventListResponseFromJson(json);

  DateTime get startDate => parseApiDate(strtDt);
  DateTime get endDate => parseApiDate(endDt);

  bool get isAllDay => strtTm.isEmpty;
  bool get isMultiDay => strtDt != endDt;

  /// `strtDt`부터 `endDt`까지(포함) 걸치는 날짜 목록.
  List<DateTime> get dayList {
    final days = <DateTime>[];
    for (var d = startDate;
        !d.isAfter(endDate);
        d = DateTime(d.year, d.month, d.day + 1)) {
      days.add(d);
    }
    return days;
  }
}

/// 등록·수정 공용 요청. `PUT`은 전량 치환이라 수정 시에도 전 필드를 보낸다.
class EventRequest {
  const EventRequest({
    required this.eventTypeCd,
    required this.eventNm,
    this.contents = '',
    required this.strtDt,
    required this.endDt,
    this.strtTm = '',
    this.endTm = '',
    this.memberId = '',
  });

  final String eventTypeCd;
  final String eventNm;
  final String contents;
  final String strtDt;
  final String endDt;
  final String strtTm;
  final String endTm;
  final String memberId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'eventTypeCd': eventTypeCd,
        'eventNm': eventNm,
        'contents': contents,
        'strtDt': strtDt,
        'endDt': endDt,
        'strtTm': strtTm,
        'endTm': endTm,
        'memberId': memberId,
      };
}

/// `"YYYYMMDD"` → 자정 기준 [DateTime].
DateTime parseApiDate(String yyyymmdd) => DateTime(
      int.parse(yyyymmdd.substring(0, 4)),
      int.parse(yyyymmdd.substring(4, 6)),
      int.parse(yyyymmdd.substring(6, 8)),
    );

/// [DateTime] → `"YYYYMMDD"`.
String formatApiDate(DateTime dt) =>
    '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
