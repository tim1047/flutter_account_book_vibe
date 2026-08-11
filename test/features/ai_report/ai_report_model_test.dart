import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportDetailResponse.fromJson', () {
    // API 스펙 §5.6 예시 응답의 resultData를 그대로 옮긴 것.
    final doneJson = <String, dynamic>{
      'period': '202607',
      'status': 'done',
      'publishedAt': '2026-08-02T21:04:11+0900',
      'headline': '고정비가 처음으로 수입의 절반을 넘었다.',
      'metrics': [
        {
          'key': 'net_saving', 'label': '순저축', 'value': 1540000,
          'delta': -320000, 'verdict': 'caution', 'format': 'currency',
        },
        {
          'key': 'fixed_ratio', 'label': '고정비율', 'value': 51.2,
          'delta': 3.4, 'verdict': 'bad', 'format': 'percent',
        },
      ],
      'bodyMd': '## 고정비\n7월 고정비는 ...',
      'action': '구독 서비스 1건을 이번 주에 해지한다.',
      'errorMessage': null,
    };

    test('완료 회차의 전 필드를 파싱한다', () {
      final result = ReportDetailResponse.fromJson(doneJson);

      expect(result.period, '202607');
      expect(result.status, 'done');
      expect(result.headline, '고정비가 처음으로 수입의 절반을 넘었다.');
      expect(result.bodyMd, '## 고정비\n7월 고정비는 ...');
      expect(result.errorMessage, isNull);
      expect(result.metrics, hasLength(2));
    });

    test('콜론 없는 +0900 오프셋을 DateTime으로 파싱한다', () {
      final result = ReportDetailResponse.fromJson(doneJson);

      // 서버 세션 타임존이 Asia/Seoul 고정이라 오프셋은 항상 +0900이다.
      expect(result.publishedAt, isNotNull);
      expect(result.publishedAt!.toUtc(), DateTime.utc(2026, 8, 2, 12, 4, 11));
    });

    test('금액 지표는 정수, 비율 지표는 실수로 들어온다', () {
      final result = ReportDetailResponse.fromJson(doneJson);

      expect(result.metrics[0].value, 1540000);
      expect(result.metrics[0].delta, -320000);
      expect(result.metrics[1].value, 51.2);
      expect(result.metrics[1].delta, 3.4);
    });

    test('미완료 회차는 metrics가 빈 배열이고 본문이 null이다', () {
      final result = ReportDetailResponse.fromJson(<String, dynamic>{
        'period': '202607',
        'status': 'running',
        'publishedAt': null,
        'headline': null,
        'metrics': <dynamic>[],
        'bodyMd': null,
        'action': null,
        'errorMessage': null,
      });

      expect(result.status, 'running');
      expect(result.metrics, isEmpty);
      expect(result.bodyMd, isNull);
      expect(result.publishedAt, isNull);
    });

    test('실패 회차는 errorMessage에 예외 타입명이 담긴다', () {
      final result = ReportDetailResponse.fromJson(<String, dynamic>{
        'period': '202607',
        'status': 'failed',
        'publishedAt': null,
        'headline': null,
        'metrics': <dynamic>[],
        'bodyMd': null,
        'action': null,
        'errorMessage': 'ValidationError',
      });

      expect(result.status, 'failed');
      expect(result.errorMessage, 'ValidationError');
    });
  });

  group('ReportStatusResponse.fromJson', () {
    test('미발행 상태를 파싱한다', () {
      final result = ReportStatusResponse.fromJson(<String, dynamic>{
        'publishablePeriod': '202607',
        'published': false,
        'publishedAt': null,
        'pendingQuestions': '- Q1. 87만, 여행이었어?',
        'running': false,
      });

      expect(result.publishablePeriod, '202607');
      expect(result.published, isFalse);
      expect(result.running, isFalse);
      expect(result.pendingQuestions, '- Q1. 87만, 여행이었어?');
      expect(result.publishedAt, isNull);
    });
  });

  group('ReportListItem.fromJson', () {
    test('목록 항목을 파싱한다', () {
      final result = ReportListItem.fromJson(<String, dynamic>{
        'period': '202606',
        'headline': '여행 87만이 빠졌는데도 순저축이 늘었다.',
        'publishedAt': '2026-07-03T10:22:47+0900',
      });

      expect(result.period, '202606');
      expect(result.headline, '여행 87만이 빠졌는데도 순저축이 늘었다.');
      expect(result.publishedAt, isNotNull);
    });
  });

  group('ProfileResponse.fromJson', () {
    test('초기 상태는 세 구역이 모두 빈 문자열이다', () {
      final result = ProfileResponse.fromJson(<String, dynamic>{
        'userConfirmed': '',
        'pendingQuestions': '',
        'observations': '',
        'updatedAt': '2026-08-11T09:12:33+0900',
      });

      expect(result.userConfirmed, isEmpty);
      expect(result.pendingQuestions, isEmpty);
      expect(result.observations, isEmpty);
    });
  });
}
