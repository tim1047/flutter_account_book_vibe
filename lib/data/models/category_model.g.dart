// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryListResponse _$CategoryListResponseFromJson(
        Map<String, dynamic> json) =>
    CategoryListResponse(
      divisionId: json['divisionId'] as String,
      categoryId: json['categoryId'] as String,
      categoryNm: json['categoryNm'] as String,
    );

CategorySeqListResponse _$CategorySeqListResponseFromJson(
        Map<String, dynamic> json) =>
    CategorySeqListResponse(
      categoryId: json['categoryId'] as String,
      categorySeq: json['categorySeq'] as String,
      categorySeqNm: json['categorySeqNm'] as String,
    );

CategorySeqSumResponse _$CategorySeqSumResponseFromJson(
        Map<String, dynamic> json) =>
    CategorySeqSumResponse(
      categoryId: json['categoryId'] as String,
      categoryNm: json['categoryNm'] as String,
      divisionId: json['divisionId'] as String,
      divisionNm: json['divisionNm'] as String,
      categorySeq: json['categorySeq'] as String,
      categorySeqNm: json['categorySeqNm'] as String,
      fixedPriceYn: json['fixedPriceYn'] as String,
      sumPrice: (json['sumPrice'] as num).toInt(),
      totalSumPrice: (json['totalSumPrice'] as num).toInt(),
    );

CategorySeqItem _$CategorySeqItemFromJson(Map<String, dynamic> json) =>
    CategorySeqItem(
      categorySeq: json['categorySeq'] as String,
      categorySeqNm: json['categorySeqNm'] as String,
      sumPrice: (json['sumPrice'] as num).toInt(),
    );

CategorySumResponse _$CategorySumResponseFromJson(Map<String, dynamic> json) =>
    CategorySumResponse(
      categoryId: json['categoryId'] as String,
      categoryNm: json['categoryNm'] as String,
      divisionId: json['divisionId'] as String,
      sumPrice: (json['sumPrice'] as num).toInt(),
      totalSumPrice: (json['totalSumPrice'] as num).toInt(),
      data: (json['data'] as List<dynamic>)
          .map((e) => CategorySeqItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
