import 'package:json_annotation/json_annotation.dart';

part 'account_model.g.dart';

@JsonSerializable(createToJson: false)
class AccountListResponse {
  const AccountListResponse({
    required this.seq,
    required this.accountId,
    required this.accountDt,
    required this.divisionId,
    required this.divisionNm,
    required this.memberId,
    required this.memberNm,
    required this.paymentId,
    required this.paymentNm,
    required this.paymentType,
    required this.categoryId,
    required this.categoryNm,
    required this.categorySeq,
    required this.categorySeqNm,
    required this.price,
    this.remark,
    required this.impulseYn,
    required this.pointPrice,
  });

  final int seq;
  final int accountId;
  final String accountDt;
  final String divisionId;
  final String divisionNm;
  final String memberId;
  final String memberNm;
  final String paymentId;
  final String paymentNm;
  final String paymentType;
  final String categoryId;
  final String categoryNm;
  final String categorySeq;
  final String categorySeqNm;
  final int price;
  final String? remark;
  final String impulseYn;
  final int pointPrice;

  factory AccountListResponse.fromJson(Map<String, dynamic> json) =>
      _$AccountListResponseFromJson(json);
}

class AccountRequest {
  const AccountRequest({
    required this.accountDt,
    required this.divisionId,
    required this.memberId,
    required this.paymentId,
    required this.categoryId,
    required this.categorySeq,
    required this.price,
    this.remark,
    this.impulseYn = 'N',
    this.pointPrice = 0,
  });

  final String accountDt;
  final String divisionId;
  final String memberId;
  final String paymentId;
  final String categoryId;
  final String categorySeq;
  final int price;
  final String? remark;
  final String impulseYn;
  final int pointPrice;

  Map<String, dynamic> toJson() => {
        'accountDt': accountDt,
        'divisionId': divisionId,
        'memberId': memberId,
        'paymentId': paymentId,
        'categoryId': categoryId,
        'categorySeq': categorySeq,
        'price': price,
        'remark': remark ?? '',
        'impulseYn': impulseYn,
        'pointPrice': pointPrice,
      };
}
