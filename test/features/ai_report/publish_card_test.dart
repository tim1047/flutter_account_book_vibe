import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/features/ai_report/publish_card.dart';
import 'package:flutter_test/flutter_test.dart';

ReportStatusResponse _status({
  bool published = false,
  bool running = false,
  DateTime? publishedAt,
}) =>
    ReportStatusResponse(
      publishablePeriod: '202607',
      published: published,
      publishedAt: publishedAt,
      pendingQuestions: '',
      running: running,
    );

ReportDetailResponse _detail(String status, {String? errorMessage}) =>
    ReportDetailResponse(
      period: '202607',
      status: status,
      errorMessage: errorMessage,
    );

void main() {
  group('resolvePublishCard', () {
    test('행이 없으면 미발행', () {
      expect(
        resolvePublishCard(_status(), null),
        PublishCardState.notPublished,
      );
    });

    test('직전 발행이 실패했으면 실패', () {
      // published:false + running:false만으로는 미시도와 실패를 못 가른다.
      // 상세의 status를 봐야 구분된다 (API 스펙 §5.2).
      expect(
        resolvePublishCard(
          _status(),
          _detail('failed', errorMessage: 'ValidationError'),
        ),
        PublishCardState.failed,
      );
    });

    test('진행 중이면 생성 중', () {
      expect(
        resolvePublishCard(_status(running: true), _detail('running')),
        PublishCardState.running,
      );
    });

    test('발행 완료면 완료', () {
      expect(
        resolvePublishCard(
          _status(published: true, publishedAt: DateTime(2026, 8, 2)),
          _detail('done'),
        ),
        PublishCardState.done,
      );
    });

    test('완료 판정이 진행 중 판정보다 우선한다', () {
      // 서버상 발생하지 않는 조합이지만, 응답이 어긋나도 사용자가 결과를
      // 못 보는 상태로 갇히지 않게 published를 먼저 본다.
      expect(
        resolvePublishCard(
          _status(published: true, running: true),
          _detail('done'),
        ),
        PublishCardState.done,
      );
    });

    test('좀비 running은 서버가 이미 failed로 내려주므로 앱은 시간 계산을 안 한다', () {
      expect(
        resolvePublishCard(_status(), _detail('failed', errorMessage: 'TimeoutError')),
        PublishCardState.failed,
      );
    });
  });
}
