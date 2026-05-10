import 'package:json_annotation/json_annotation.dart';

part 'asset_model.g.dart';

@JsonSerializable(createToJson: false)
class AssetListResponse {
  const AssetListResponse({
    required this.assetId,
    required this.assetNm,
  });

  final String assetId;
  final String assetNm;

  factory AssetListResponse.fromJson(Map<String, dynamic> json) =>
      _$AssetListResponseFromJson(json);
}
