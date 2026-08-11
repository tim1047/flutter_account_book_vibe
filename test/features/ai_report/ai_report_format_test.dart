import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPeriod', () {
    test('YYYYMM을 점 표기로 바꾼다', () {
      expect(formatPeriod('202607'), '2026.07');
      expect(formatPeriod('202512'), '2025.12');
    });

    test('형식이 아닌 값은 그대로 돌려준다', () {
      expect(formatPeriod('2026'), '2026');
    });
  });

  group('formatMetricValue', () {
    test('currency는 콤마 붙은 정수다', () {
      expect(formatMetricValue(1540000, 'currency'), '1,540,000');
      expect(formatMetricValue(187400000, 'currency'), '187,400,000');
    });

    test('currency에 실수가 들어와도 소수점이 새지 않는다', () {
      // 서버가 int로 주지만 Dart 쪽 타입은 num이라 방어한다.
      expect(formatMetricValue(1540000.0, 'currency'), '1,540,000');
    });

    test('percent는 소수점 1자리다', () {
      expect(formatMetricValue(51.2, 'percent'), '51.2%');
      expect(formatMetricValue(40, 'percent'), '40.0%');
    });

    test('months는 소수점 1자리에 단위를 붙인다', () {
      expect(formatMetricValue(4.1, 'months'), '4.1개월');
    });

    test('음수 금액에 부호가 남는다', () {
      expect(formatMetricValue(-320000, 'currency'), '-320,000');
    });
  });

  group('formatMetricDelta', () {
    test('증가는 ▲, 감소는 ▼를 붙이고 절댓값을 쓴다', () {
      expect(formatMetricDelta(2100000, 'currency'), '▲ 2,100,000');
      expect(formatMetricDelta(-320000, 'currency'), '▼ 320,000');
      expect(formatMetricDelta(3.4, 'percent'), '▲ 3.4%');
      expect(formatMetricDelta(-0.3, 'months'), '▼ 0.3개월');
    });

    test('변동 없음은 대시로 표시한다', () {
      expect(formatMetricDelta(0, 'currency'), '–');
      expect(formatMetricDelta(0.0, 'percent'), '–');
    });
  });

  group('metricVerdictColor', () {
    test('판정별 색', () {
      expect(metricVerdictColor('good'), AppColors.colorSuccess);
      expect(metricVerdictColor('bad'), AppColors.colorError);
      expect(metricVerdictColor('caution'), AppColors.colorWarning);
    });

    test('모르는 값은 주의색으로 떨어진다', () {
      expect(metricVerdictColor('unknown'), AppColors.colorWarning);
    });
  });
}
