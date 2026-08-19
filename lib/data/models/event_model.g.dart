// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventListResponse _$EventListResponseFromJson(Map<String, dynamic> json) =>
    EventListResponse(
      eventId: (json['eventId'] as num).toInt(),
      eventTypeCd: json['eventTypeCd'] as String,
      eventTypeNm: json['eventTypeNm'] as String,
      eventNm: json['eventNm'] as String,
      contents: json['contents'] as String,
      strtDt: json['strtDt'] as String,
      endDt: json['endDt'] as String,
      strtTm: json['strtTm'] as String,
      endTm: json['endTm'] as String,
      memberId: json['memberId'] as String,
      memberNm: json['memberNm'] as String,
    );
