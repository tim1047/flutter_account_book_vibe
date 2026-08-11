import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/features/ai_report/ai_home_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

ReportListItem _item(String period) =>
    ReportListItem(period: period, headline: '$period 요약');

void main() {
  group('AiHomeViewModel.excludePublishable', () {
    test('발행 카드가 다루는 회차를 목록에서 뺀다', () {
      final result = AiHomeViewModel.excludePublishable(
        [_item('202607'), _item('202606'), _item('202605')],
        '202607',
      );

      expect(result.map((e) => e.period), ['202606', '202605']);
    });

    test('해당 회차가 목록에 없으면 그대로 둔다', () {
      // 미발행 회차는 애초에 목록 API에 나오지 않는다.
      final result = AiHomeViewModel.excludePublishable(
        [_item('202606'), _item('202605')],
        '202607',
      );

      expect(result.map((e) => e.period), ['202606', '202605']);
    });

    test('빈 목록은 빈 목록', () {
      expect(AiHomeViewModel.excludePublishable([], '202607'), isEmpty);
    });

    test('원본 목록을 변형하지 않는다', () {
      final original = [_item('202607'), _item('202606')];

      AiHomeViewModel.excludePublishable(original, '202607');

      expect(original, hasLength(2));
    });
  });
}
