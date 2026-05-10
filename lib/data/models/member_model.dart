import 'package:json_annotation/json_annotation.dart';

part 'member_model.g.dart';

@JsonSerializable(createToJson: false)
class MemberListResponse {
  const MemberListResponse({
    required this.memberId,
    required this.memberNm,
  });

  final String memberId;
  final String memberNm;

  factory MemberListResponse.fromJson(Map<String, dynamic> json) =>
      _$MemberListResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class MemberSumResponse {
  const MemberSumResponse({
    required this.memberId,
    required this.memberNm,
    required this.sumPrice,
  });

  final String memberId;
  final String memberNm;
  final int sumPrice;

  factory MemberSumResponse.fromJson(Map<String, dynamic> json) =>
      _$MemberSumResponseFromJson(json);
}
