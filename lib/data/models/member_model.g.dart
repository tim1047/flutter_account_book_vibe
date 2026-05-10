// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberListResponse _$MemberListResponseFromJson(Map<String, dynamic> json) =>
    MemberListResponse(
      memberId: json['memberId'] as String,
      memberNm: json['memberNm'] as String,
    );

MemberSumResponse _$MemberSumResponseFromJson(Map<String, dynamic> json) =>
    MemberSumResponse(
      memberId: json['memberId'] as String,
      memberNm: json['memberNm'] as String,
      sumPrice: (json['sumPrice'] as num).toInt(),
    );
