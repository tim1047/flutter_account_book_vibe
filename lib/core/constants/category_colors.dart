import 'package:flutter/material.dart';

/// categoryId(1~26) 별 고정 차트 컬러.
///
/// 도넛/범례 등에서 인덱스 기반 색상 배정 대신 categoryId로 직접 조회해
/// 정렬 순서가 바뀌어도 같은 카테고리는 항상 같은 색을 유지한다.
/// 새 categoryId가 서버에 추가되면 이 맵에도 항목을 추가해야 한다.
class CategoryColors {
  CategoryColors._();

  static const Color _fallback = Color(0xFF8B949E);

  static const Map<String, Color> _colors = <String, Color>{
    '1': Color(0xFFE06655),
    '2': Color(0xFF556DE0),
    '3': Color(0xFF96E055),
    '4': Color(0xFFE055BE),
    '5': Color(0xFF55E0DA),
    '6': Color(0xFFE0B155),
    '7': Color(0xFF8955E0),
    '8': Color(0xFF55E060),
    '9': Color(0xFFE05573),
    '10': Color(0xFF559CE0),
    '11': Color(0xFFC4E055),
    '12': Color(0xFFD455E0),
    '13': Color(0xFF55E0AB),
    '14': Color(0xFFE08355),
    '15': Color(0xFF5A55E0),
    '16': Color(0xFF79E055),
    '17': Color(0xFFE055A2),
    '18': Color(0xFF55CAE0),
    '19': Color(0xFFE0CE55),
    '20': Color(0xFFA555E0),
    '21': Color(0xFF55E07D),
    '22': Color(0xFFE05556),
    '23': Color(0xFF557FE0),
    '24': Color(0xFFA8E055),
    '25': Color(0xFFE055D0),
    '26': Color(0xFF55E0C8),
  };

  static Color of(String categoryId) => _colors[categoryId] ?? _fallback;
}
