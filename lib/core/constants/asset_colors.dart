import 'package:flutter/material.dart';

/// assetId(1~8) 별 고정 차트 컬러.
///
/// 인덱스 기반 색상 배정 대신 assetId로 직접 조회해 정렬 순서가 바뀌어도
/// 같은 자산은 항상 같은 색을 유지한다. 새 assetId가 서버에 추가되면
/// 이 맵에도 항목을 추가해야 한다.
class AssetColors {
  AssetColors._();

  static const Color _fallback = Color(0xFF8B949E);

  static const Map<String, Color> _colors = <String, Color>{
    '1': Color(0xFF818CF8),
    '2': Color(0xFFF472B6),
    '3': Color(0xFF2DD4BF),
    '4': Color(0xFF4ADE80),
    '5': Color(0xFFF87171),
    '6': Color(0xFFE6EDF3),
    '7': Color(0xFFFB923C),
    '8': Color(0xFFFACC15),
  };

  static Color of(String assetId) => _colors[assetId] ?? _fallback;
}
