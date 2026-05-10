// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountListResponse _$AccountListResponseFromJson(Map<String, dynamic> json) =>
    AccountListResponse(
      seq: (json['seq'] as num).toInt(),
      accountId: (json['accountId'] as num).toInt(),
      accountDt: json['accountDt'] as String,
      divisionId: json['divisionId'] as String,
      divisionNm: json['divisionNm'] as String,
      memberId: json['memberId'] as String,
      memberNm: json['memberNm'] as String,
      paymentId: json['paymentId'] as String,
      paymentNm: json['paymentNm'] as String,
      paymentType: json['paymentType'] as String,
      categoryId: json['categoryId'] as String,
      categoryNm: json['categoryNm'] as String,
      categorySeq: json['categorySeq'] as String,
      categorySeqNm: json['categorySeqNm'] as String,
      price: (json['price'] as num).toInt(),
      remark: json['remark'] as String?,
      impulseYn: json['impulseYn'] as String,
      pointPrice: (json['pointPrice'] as num).toInt(),
    );
