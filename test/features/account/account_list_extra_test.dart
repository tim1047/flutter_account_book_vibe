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

  group('AccountListExtra.year/month', () {
    test('divisionId와 함께 year/month 전달 가능', () {
      const extra = AccountListExtra(
        divisionId: '3',
        year: 2026,
        month: 7,
      );
      expect(extra.divisionId, '3');
      expect(extra.year, 2026);
      expect(extra.month, 7);
      expect(extra.date, isNull);
    });
  });
}
