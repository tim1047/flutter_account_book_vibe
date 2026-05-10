import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 천단위 콤마를 자동으로 삽입하는 TextInputFormatter.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter();

  static final NumberFormat _formatter = NumberFormat('#,##0', 'ko_KR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final int parsed = int.tryParse(digitsOnly) ?? 0;
    final String formatted = _formatter.format(parsed);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
