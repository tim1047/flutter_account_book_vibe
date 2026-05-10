import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

@JsonSerializable(createToJson: false)
class CategoryListResponse {
  const CategoryListResponse({
    required this.divisionId,
    required this.categoryId,
    required this.categoryNm,
  });

  final String divisionId;
  final String categoryId;
  final String categoryNm;

  factory CategoryListResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryListResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class CategorySeqListResponse {
  const CategorySeqListResponse({
    required this.categoryId,
    required this.categorySeq,
    required this.categorySeqNm,
  });

  final String categoryId;
  final String categorySeq;
  final String categorySeqNm;

  factory CategorySeqListResponse.fromJson(Map<String, dynamic> json) =>
      _$CategorySeqListResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class CategorySeqSumResponse {
  const CategorySeqSumResponse({
    required this.categoryId,
    required this.categoryNm,
    required this.divisionId,
    required this.divisionNm,
    required this.categorySeq,
    required this.categorySeqNm,
    required this.fixedPriceYn,
    required this.sumPrice,
    required this.totalSumPrice,
  });

  final String categoryId;
  final String categoryNm;
  final String divisionId;
  final String divisionNm;
  final String categorySeq;
  final String categorySeqNm;
  final String fixedPriceYn;
  final int sumPrice;
  final int totalSumPrice;

  factory CategorySeqSumResponse.fromJson(Map<String, dynamic> json) =>
      _$CategorySeqSumResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class CategorySeqItem {
  const CategorySeqItem({
    required this.categorySeq,
    required this.categorySeqNm,
    required this.sumPrice,
  });

  final String categorySeq;
  final String categorySeqNm;
  final int sumPrice;

  factory CategorySeqItem.fromJson(Map<String, dynamic> json) =>
      _$CategorySeqItemFromJson(json);
}

@JsonSerializable(createToJson: false)
class CategorySumResponse {
  const CategorySumResponse({
    required this.categoryId,
    required this.categoryNm,
    required this.divisionId,
    required this.sumPrice,
    required this.totalSumPrice,
    required this.data,
  });

  final String categoryId;
  final String categoryNm;
  final String divisionId;
  final int sumPrice;
  final int totalSumPrice;
  final List<CategorySeqItem> data;

  factory CategorySumResponse.fromJson(Map<String, dynamic> json) =>
      _$CategorySumResponseFromJson(json);
}
