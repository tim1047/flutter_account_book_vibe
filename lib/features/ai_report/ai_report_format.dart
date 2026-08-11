import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:flutter/material.dart';

/// `'202607'` → `'2026.07'`. 형식이 아니면 원문을 그대로 돌려준다.
String formatPeriod(String period) {
  if (period.length != 6) return period;
  return '${period.substring(0, 4)}.${period.substring(4, 6)}';
}

/// 지표 값 포맷. 값의 Dart 타입이 아니라 서버가 준 [format]으로 판단한다
/// (금액은 정수, 비율·개월은 실수로 오지만 유니온이라 보장되지 않는다).
String formatMetricValue(num value, String format) {
  switch (format) {
    case 'currency':
      return FormatUtil.formatPrice(value.round());
    case 'percent':
      return '${value.toDouble().toStringAsFixed(1)}%';
    case 'months':
      return '${value.toDouble().toStringAsFixed(1)}개월';
    default:
      return value.toString();
  }
}

/// 전월 대비 증감. 방향 기호 + 절댓값.
String formatMetricDelta(num delta, String format) {
  if (delta == 0) return '–';
  final arrow = delta > 0 ? '▲' : '▼';
  return '$arrow ${formatMetricValue(delta.abs(), format)}';
}

Color metricVerdictColor(String verdict) => switch (verdict) {
      'good' => AppColors.colorSuccess,
      'bad' => AppColors.colorError,
      _ => AppColors.colorWarning,
    };
