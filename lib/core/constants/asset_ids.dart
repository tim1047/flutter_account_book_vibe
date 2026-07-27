/// 서버가 내려주는 assetId 상수.
///
/// `/my-asset`, `/my-asset/sum` 응답의 assetId는 문자열 코드로 내려온다.
/// 이 상수 없이 리터럴('6' 등)로 비교하면 의미가 드러나지 않아 실수하기 쉽다.
class AssetIds {
  AssetIds._();

  static const String total = '0';
  static const String domesticStock = '1';
  static const String usStock = '2';
  static const String coin = '3';
  static const String cash = '4';
  static const String realEstate = '5';
  static const String loan = '6';
  static const String jpStock = '7';
  static const String pension = '8';
}
