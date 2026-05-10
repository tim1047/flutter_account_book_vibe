import 'package:flutter/material.dart';

class FormatUtil {
  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  static String formatPrice(int price) {
    final isNegative = price < 0;
    final abs = price.abs().toString();
    final buffer = StringBuffer();
    final remainder = abs.length % 3;

    for (int i = 0; i < abs.length; i++) {
      if (i != 0 && (i - remainder) % 3 == 0) buffer.write(',');
      buffer.write(abs[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()}';
  }

  static String formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      final weekday = _weekdays[dt.weekday - 1];
      return '${dt.year}.${_pad(dt.month)}.${_pad(dt.day)} ($weekday)';
    } catch (_) {
      return date;
    }
  }

  static String formatDateShort(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.year}.${_pad(dt.month)}.${_pad(dt.day)}';
    } catch (_) {
      return date;
    }
  }

  static String formatMonthYear(int year, int month) {
    if (month == 0) return '$year년 전체';
    return '$year년 ${_pad(month)}월';
  }

  static String toProcDt(int year, int month) {
    final m = month == 0 ? DateTime.now().month : month;
    return '$year${_pad(m)}';
  }

  static String toStrtDt(int year, int month) {
    if (month == 0) return '${year}0101';
    return '$year${_pad(month)}01';
  }

  static String toEndDt(int year, int month) {
    if (month == 0) return '${year}1231';
    final lastDay = DateTime(year, month + 1, 0).day;
    return '$year${_pad(month)}${_pad(lastDay)}';
  }

  static double percentageOf(int value, int total) {
    if (total == 0) return 0.0;
    return (value / total * 100).clamp(0.0, 100.0);
  }

  static String formatPercentage(double value) => '${value.toStringAsFixed(1)}%';

  static Color weekdayColor(String date) {
    try {
      final dt = DateTime.parse(date);
      if (dt.weekday == DateTime.saturday) return Colors.blue;
      if (dt.weekday == DateTime.sunday) return Colors.red;
    } catch (_) {}
    return Colors.white;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
