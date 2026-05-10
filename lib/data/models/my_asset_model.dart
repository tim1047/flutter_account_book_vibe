part 'my_asset_model.g.dart';

int _parseToInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return double.parse(value).toInt();
  return 0;
}

class MyAssetItemResponse {
  const MyAssetItemResponse({
    required this.assetId,
    required this.myAssetId,
    required this.myAssetNm,
    required this.ticker,
    required this.price,
    required this.qty,
    required this.assetNm,
    required this.priceDivCd,
    required this.exchangeRateYn,
    required this.sumPrice,
    this.myAssetGroupId,
    required this.cashableYn,
    required this.myAssetAccumDts,
    this.myAssetGroupNm,
  });

  final String assetId;
  final String myAssetId;
  final String myAssetNm;
  final String ticker;
  final int price;
  final double qty;
  final String assetNm;
  final String priceDivCd;
  final String exchangeRateYn;
  final int sumPrice;
  final String? myAssetGroupId;
  final String cashableYn;
  final String myAssetAccumDts;
  final String? myAssetGroupNm;

  factory MyAssetItemResponse.fromJson(Map<String, dynamic> json) =>
      MyAssetItemResponse(
        assetId: json['assetId'] as String,
        myAssetId: json['myAssetId'] as String,
        myAssetNm: json['myAssetNm'] as String,
        ticker: json['ticker'] as String,
        price: _parseToInt(json['price']),
        qty: (json['qty'] as num).toDouble(),
        assetNm: json['assetNm'] as String,
        priceDivCd: json['priceDivCd'] as String,
        exchangeRateYn: json['exchangeRateYn'] as String,
        sumPrice: json['sumPrice'] as int,
        myAssetGroupId: json['myAssetGroupId'] as String?,
        cashableYn: json['cashableYn'] as String,
        myAssetAccumDts: json['myAssetAccumDts'] as String,
        myAssetGroupNm: json['myAssetGroupNm'] as String?,
      );
}

class MyAssetSubGroupResponse {
  const MyAssetSubGroupResponse({
    required this.myAssetGroupId,
    required this.myAssetGroupNm,
    required this.sumPrice,
    required this.items,
  });

  final String myAssetGroupId;
  final String myAssetGroupNm;
  final int sumPrice;
  final List<MyAssetItemResponse> items;
}

class MyAssetGroupResponse {
  const MyAssetGroupResponse({
    required this.assetNm,
    required this.assetTotSumPrice,
    required this.items,
    required this.subGroups,
  });

  final String assetNm;
  final int assetTotSumPrice;
  final List<MyAssetItemResponse> items;
  final List<MyAssetSubGroupResponse> subGroups;

  List<MyAssetItemResponse> get allItems => [
        ...items,
        for (final g in subGroups) ...g.items,
      ];

  factory MyAssetGroupResponse.fromJson(Map<String, dynamic> json) {
    final directItems = <MyAssetItemResponse>[];
    final subGroupsList = <MyAssetSubGroupResponse>[];

    for (final e in json['data'] as List<dynamic>) {
      final map = e as Map<String, dynamic>;
      if (map.containsKey('myAssetId')) {
        directItems.add(MyAssetItemResponse.fromJson(map));
      } else if (map.containsKey('data')) {
        final subItems = (map['data'] as List<dynamic>)
            .map((s) => MyAssetItemResponse.fromJson(s as Map<String, dynamic>))
            .toList();
        subGroupsList.add(MyAssetSubGroupResponse(
          myAssetGroupId: map['myAssetGroupId'] as String? ?? '',
          myAssetGroupNm: map['myAssetGroupNm'] as String? ?? '',
          sumPrice: subItems.fold(0, (sum, item) => sum + item.sumPrice),
          items: subItems,
        ));
      }
    }

    return MyAssetGroupResponse(
      assetNm: json['assetNm'] as String,
      assetTotSumPrice: json['assetTotSumPrice'] as int,
      items: directItems,
      subGroups: subGroupsList,
    );
  }
}

class MyAssetListResponse {
  const MyAssetListResponse({
    required this.totSumPrice,
    required this.totNetWorthSumPrice,
    required this.totCashableSumPrice,
    required this.usdKrwRate,
    required this.jpyKrwRate,
    required this.myAssetAccumDts,
    required this.data,
  });

  final int totSumPrice;
  final int totNetWorthSumPrice;
  final int totCashableSumPrice;
  final int usdKrwRate;
  final double jpyKrwRate;
  final String myAssetAccumDts;
  final Map<String, MyAssetGroupResponse> data;

  factory MyAssetListResponse.fromJson(Map<String, dynamic> json) =>
      MyAssetListResponse(
        totSumPrice: json['totSumPrice'] as int,
        totNetWorthSumPrice: json['totNetWorthSumPrice'] as int,
        totCashableSumPrice: json['totCashableSumPrice'] as int,
        usdKrwRate: json['usdKrwRate'] as int,
        jpyKrwRate: (json['jpyKrwRate'] as num).toDouble(),
        myAssetAccumDts: json['myAssetAccumDts'] as String,
        data: (json['data'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            MyAssetGroupResponse.fromJson(v as Map<String, dynamic>),
          ),
        ),
      );
}

class MyAssetSumResponse {
  const MyAssetSumResponse({
    required this.accumDt,
    required this.assetId,
    required this.assetNm,
    required this.sumPrice,
  });

  final String accumDt;
  final String assetId;
  final String assetNm;
  final int sumPrice;

  factory MyAssetSumResponse.fromJson(Map<String, dynamic> json) =>
      MyAssetSumResponse(
        accumDt: json['accumDt'] as String,
        assetId: json['assetId'] as String,
        assetNm: json['assetNm'] as String,
        sumPrice: _parseToInt(json['sumPrice']),
      );
}

class MyAssetRequest {
  const MyAssetRequest({
    required this.myAssetNm,
    required this.assetId,
    required this.ticker,
    required this.priceDivCd,
    required this.price,
    required this.qty,
    required this.exchangeRateYn,
    required this.cashableYn,
  });

  final String myAssetNm;
  final String assetId;
  final String ticker;
  final String priceDivCd;
  final int price;
  final double qty;
  final String exchangeRateYn;
  final String cashableYn;

  Map<String, dynamic> toJson() => {
        'myAssetNm': myAssetNm,
        'assetId': assetId,
        'ticker': ticker,
        'priceDivCd': priceDivCd,
        'price': price,
        'qty': qty,
        'exchangeRateYn': exchangeRateYn,
        'cashableYn': cashableYn,
      };
}
