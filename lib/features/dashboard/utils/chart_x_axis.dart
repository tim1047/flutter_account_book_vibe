import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 날짜별(YYYYMMDD, 오름차순) x축 라벨 설정을 만든다.
///
/// 데이터 포인트가 촘촘해도 라벨은 월 단위로 한 번만 찍고, 범위가 길어지면
/// 분기(1/4/7/10월) → 반기(1/7월) → 연 단위로 단계적으로 줄여 겹침을 막는다.
SideTitles buildDateAxisTitles(List<String> dates) {
  final monthKeys = <String>[];
  for (final date in dates) {
    final key = date.substring(0, 6);
    if (monthKeys.isEmpty || monthKeys.last != key) monthKeys.add(key);
  }
  const quarterMonths = {'01', '04', '07', '10'};
  const halfMonths = {'01', '07'};
  var anchorMonths = const {
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12'
  };
  var yearlyLabels = false;
  if (monthKeys.length > 12) {
    final quarterCount =
        monthKeys.where((k) => quarterMonths.contains(k.substring(4))).length;
    if (quarterCount <= 12) {
      anchorMonths = quarterMonths;
    } else {
      final halfCount =
          monthKeys.where((k) => halfMonths.contains(k.substring(4))).length;
      if (halfCount <= 12) {
        anchorMonths = halfMonths;
      } else {
        anchorMonths = const {'01'};
        yearlyLabels = true;
      }
    }
  }

  return SideTitles(
    showTitles: true,
    reservedSize: 20,
    interval: 1,
    getTitlesWidget: (value, _) {
      final idx = value.toInt();
      if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
      final date = dates[idx];
      final currentMonth = date.substring(4, 6);
      if (idx > 0 && date.substring(0, 6) == dates[idx - 1].substring(0, 6)) {
        return const SizedBox.shrink();
      }
      if (!anchorMonths.contains(currentMonth)) {
        return const SizedBox.shrink();
      }
      final label =
          yearlyLabels ? date.substring(0, 4) : '${int.parse(currentMonth)}월';
      return Text(
        label,
        style: AppTextStyles.textBodyXs.copyWith(
          color: AppColors.colorTextSecondary,
        ),
      );
    },
  );
}
