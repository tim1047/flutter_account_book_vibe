import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountListExtra.parseDateYearMonth', () {
    test('YYYYMMDD 문자열에서 연/월 추출', () {
      final result = AccountListExtra.parseDateYearMonth('20260715');
      expect(result.year, 2026);
      expect(result.month, 7);
    });

    test('12월도 올바르게 파싱', () {
      final result = AccountListExtra.parseDateYearMonth('20251231');
      expect(result.year, 2025);
      expect(result.month, 12);
    });
  });
}
