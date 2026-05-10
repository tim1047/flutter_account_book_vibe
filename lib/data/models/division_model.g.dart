// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'division_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DivisionListResponse _$DivisionListResponseFromJson(
        Map<String, dynamic> json) =>
    DivisionListResponse(
      divisionId: json['divisionId'] as String,
      divisionNm: json['divisionNm'] as String,
    );

DivisionSumResponse _$DivisionSumResponseFromJson(Map<String, dynamic> json) =>
    DivisionSumResponse(
      income: (json['income'] as num).toInt(),
      interest: (json['interest'] as num).toInt(),
      expense: (json['expense'] as num).toInt(),
      invest: (json['invest'] as num).toInt(),
      investRate: json['investRate'] as String,
    );

SumGroupByMonthItem _$SumGroupByMonthItemFromJson(Map<String, dynamic> json) =>
    SumGroupByMonthItem(
      divisionId: json['divisionId'] as String,
      divisionNm: json['divisionNm'] as String,
      sumPrice: (json['sumPrice'] as num).toInt(),
      month: (json['month'] as num).toInt(),
    );

SumGroupByMonthResponse _$SumGroupByMonthResponseFromJson(
        Map<String, dynamic> json) =>
    SumGroupByMonthResponse(
      avgSumPrice: (json['avgSumPrice'] as num).toInt(),
      data: (json['data'] as List<dynamic>)
          .map((e) => SumGroupByMonthItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
