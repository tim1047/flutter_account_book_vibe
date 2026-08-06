import 'package:flutter/material.dart';

/// 카드형 UI 전체에서 공용으로 쓰는 그림자 프리셋.
class AppShadows {
  AppShadows._();

  /// 일반 카드(리스트 카드, 섹션 카드, 요약 카드 등)에 쓰는 기본 그림자.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.3),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
