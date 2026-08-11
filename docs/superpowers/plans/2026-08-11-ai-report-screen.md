# AI 리포트 화면 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 하단 내비게이션에 `AI` 탭을 추가하고, `ai-report` API로 월간 리포트를 발행·열람하고 AI 질문에 답하는 화면 3개를 만든다.

**Architecture:** 기존 계층을 그대로 따른다 — 화면 → `ChangeNotifier` 뷰모델 → 싱글톤 서비스 → `DioClient`. 발행 완료는 폴링 없이 사용자가 당겨서 새로고침한다. 리포트 상세는 불변 데이터라 뷰모델 없이 `FutureBuilder`로 읽는다.

**Tech Stack:** Flutter 3.38.9 / Dart 3.10.8, go_router 13, dio 5, json_serializable 6, flutter_markdown_plus 1.0.12

**설계 문서:** [docs/superpowers/specs/2026-08-11-ai-report-screen-design.md](../specs/2026-08-11-ai-report-screen-design.md)
**API 계약:** [docs/AI_REPORT_API_SPEC.md](../../AI_REPORT_API_SPEC.md)

## Global Constraints

- 브랜치는 `feature/ai-report-screen`. 이미 만들어져 있고 설계 문서 커밋 1개가 올라가 있다.
- `AppConfig.baseUrl`이 `http://34.19.118.233:8000/account-book`이다. **서비스의 경로는 `/ai-report...`로 시작한다.** `/account-book`을 다시 붙이지 않는다.
- 응답 JSON은 전부 camelCase다. 모델에 `fieldRename`을 쓰지 않는다 (기존 모델들과 동일).
- 모든 응답 모델은 `@JsonSerializable(createToJson: false)`.
- 상태 관리는 `ChangeNotifier` + `ListenableBuilder`만 쓴다. Riverpod/Bloc/Provider 금지 (`lib/CLAUDE.md`).
- import는 항상 `package:account_book_vibe/...` 절대 경로 (`always_use_package_imports`). 문자열은 홑따옴표.
- 테스트는 목(mock) 라이브러리 없이 순수 함수·데이터 변환만 검증한다. 네트워크를 태우는 테스트는 만들지 않는다.
- `flutter test` 전체를 돌리면 **날짜 의존 기존 실패 2건**이 나온다. master에서도 실패하는 기존 문제이니 고치려 들지 말고, 본인이 추가한 테스트 파일만 지정해서 돌린다.
- 커밋 메시지는 한국어 본문 + Conventional Commits 접두어. 각 태스크 끝에서 커밋한다.

**설계 문서에서 조정한 것:** 설계의 파일 구조는 포맷 함수를 `metric_grid.dart`에 두었는데, 회차 포맷(`202607` → `2026.07`)을 홈·상세·카드 세 군데서 쓴다. 포맷 함수를 전부 `ai_report_format.dart`로 모으고 `metric_grid.dart`는 위젯만 갖는다. 라우트 경로도 셸 브랜치(`/aiReport`)와의 모호함을 피해 `/aiReportDetail/:period`, `/aiProfile`로 평평하게 둔다 (기존 `/account`, `/myAsset`와 같은 스타일). 목록 항목에는 회차와 headline만 싣는다 — 발행 시각은 회차와 거의 같은 정보라 줄만 늘린다.

## File Structure

| 파일 | 책임 |
|---|---|
| `lib/data/models/ai_report_model.dart` | 응답 모델 5개. 로직 없음 |
| `lib/data/services/ai_report_service.dart` | 엔드포인트 6개. HTTP와 봉투 언랩만 |
| `lib/core/network/dio_client.dart` (수정) | `mapDioException` 공개 함수로 추출 + 봉투 메시지 보존 |
| `lib/features/ai_report/ai_report_format.dart` | 회차·지표 값·증감 포맷, verdict 색. 전부 순수 함수 |
| `lib/features/ai_report/publish_card.dart` | `PublishCardState` enum + `resolvePublishCard` + 카드 위젯 |
| `lib/features/ai_report/ai_home_viewmodel.dart` | status + 목록 + 전월 상세 로드, 발행 요청, 목록 dedup |
| `lib/features/ai_report/ai_report_home_screen.dart` | 탭 루트 화면 |
| `lib/features/ai_report/metric_grid.dart` | 지표 2×2 그리드 위젯 |
| `lib/features/ai_report/ai_report_detail_screen.dart` | 상세 화면 (`FutureBuilder`) |
| `lib/features/ai_report/ai_profile_viewmodel.dart` | 프로필 로드/저장 |
| `lib/features/ai_report/ai_profile_screen.dart` | 프로필 편집 화면 |
| `lib/features/shell/main_shell_screen.dart` (수정) | 5번째 탭 아이템 |
| `lib/core/router/app_router.dart` (수정) | 5번째 브랜치 + 상세/프로필 라우트 |

---

### Task 1: 응답 모델과 파싱

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/data/models/ai_report_model.dart`
- Test: `test/features/ai_report/ai_report_model_test.dart`

**Interfaces:**
- Consumes: 없음 (첫 태스크)
- Produces:
  - `ReportListItem(period: String, headline: String?, publishedAt: DateTime?)`
  - `ReportStatusResponse(publishablePeriod: String, published: bool, publishedAt: DateTime?, pendingQuestions: String, running: bool)`
  - `ReportDetailResponse(period: String, status: String, publishedAt: DateTime?, headline: String?, metrics: List<MetricItem>, bodyMd: String?, action: String?, errorMessage: String?)`
  - `MetricItem(key: String, label: String, value: num, delta: num, verdict: String, format: String)`
  - `ProfileResponse(userConfirmed: String, pendingQuestions: String, observations: String, updatedAt: DateTime)`
  - 각 클래스에 `factory X.fromJson(Map<String, dynamic>)`

- [ ] **Step 1: 마크다운 패키지 추가**

```bash
flutter pub add flutter_markdown_plus
```

`pubspec.yaml`의 `dependencies`에 `flutter_markdown_plus: ^1.0.12`가 추가되고 `markdown 7.3.1`이 함께 잠긴다. 추가된 줄 위에 `# 마크다운 렌더링 (AI 리포트 본문)` 주석을 달아 다른 의존성들과 형식을 맞춘다.

- [ ] **Step 2: 실패하는 파싱 테스트 작성**

`test/features/ai_report/ai_report_model_test.dart`:

```dart
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
```

- [ ] **Step 3: 테스트가 실패하는지 확인**

Run: `flutter test test/features/ai_report/ai_report_model_test.dart`
Expected: 컴파일 실패 — `Target of URI doesn't exist: 'package:account_book_vibe/data/models/ai_report_model.dart'`

- [ ] **Step 4: 모델 작성**

`lib/data/models/ai_report_model.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'ai_report_model.g.dart';

/// 발행 완료 리포트 목록의 한 항목. `GET /ai-report`
@JsonSerializable(createToJson: false)
class ReportListItem {
  const ReportListItem({
    required this.period,
    this.headline,
    this.publishedAt,
  });

  /// `YYYYMM` 형식의 회차.
  final String period;
  final String? headline;
  final DateTime? publishedAt;

  factory ReportListItem.fromJson(Map<String, dynamic> json) =>
      _$ReportListItemFromJson(json);
}

/// 발행 가능 회차(전월)의 현재 상태. `GET /ai-report/status`,
/// `POST /ai-report/{period}` 두 곳이 같은 스키마를 쓴다.
@JsonSerializable(createToJson: false)
class ReportStatusResponse {
  const ReportStatusResponse({
    required this.publishablePeriod,
    required this.published,
    this.publishedAt,
    required this.pendingQuestions,
    required this.running,
  });

  /// 발행 대상 회차. `POST` 응답에서는 방금 요청한 회차가 담긴다.
  final String publishablePeriod;
  final bool published;
  final DateTime? publishedAt;

  /// 미답변 질문 원문(마크다운 목록 관례를 따르는 자유 텍스트).
  final String pendingQuestions;
  final bool running;

  factory ReportStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$ReportStatusResponseFromJson(json);
}

/// 리포트 상세. `GET /ai-report/{period}`
@JsonSerializable(createToJson: false)
class ReportDetailResponse {
  const ReportDetailResponse({
    required this.period,
    required this.status,
    this.publishedAt,
    this.headline,
    this.metrics = const [],
    this.bodyMd,
    this.action,
    this.errorMessage,
  });

  final String period;

  /// `running` | `done` | `failed`. 서버가 좀비 판정까지 적용한 유효 상태다.
  final String status;
  final DateTime? publishedAt;
  final String? headline;

  /// 발행 완료 회차만 4건이 채워지고, 미완료 회차는 빈 배열이다.
  final List<MetricItem> metrics;
  final String? bodyMd;

  /// 이번 달에 할 일 정확히 1개.
  final String? action;

  /// 발행 실패 시 예외 타입명. 성공이면 null.
  final String? errorMessage;

  factory ReportDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$ReportDetailResponseFromJson(json);
}

/// 핵심 지표 1건. 값은 서버가 계산해 발행 시점에 스냅샷으로 굳힌 것이다.
@JsonSerializable(createToJson: false)
class MetricItem {
  const MetricItem({
    required this.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.verdict,
    required this.format,
  });

  final String key;
  final String label;

  /// 금액 지표는 정수, 비율·개월 지표는 실수로 내려온다. 타입으로 포맷을
  /// 추론하지 말고 항상 [format]을 볼 것.
  final num value;

  /// 전월 동일 지표와의 차이.
  final num delta;

  /// `good` | `caution` | `bad`
  final String verdict;

  /// `currency` | `percent` | `months`
  final String format;

  factory MetricItem.fromJson(Map<String, dynamic> json) =>
      _$MetricItemFromJson(json);
}

/// 프로필 3구역. `GET`/`PUT /ai-report/profile`
@JsonSerializable(createToJson: false)
class ProfileResponse {
  const ProfileResponse({
    required this.userConfirmed,
    required this.pendingQuestions,
    required this.observations,
    required this.updatedAt,
  });

  /// 사용자가 쓰는 구역. 앱이 갱신할 수 있는 유일한 구역이다.
  final String userConfirmed;

  /// LLM이 쓰는 구역 — 읽기 전용.
  final String pendingQuestions;

  /// LLM이 쓰는 구역 — 읽기 전용.
  final String observations;
  final DateTime updatedAt;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
}
```

- [ ] **Step 5: 코드 생성**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/data/models/ai_report_model.g.dart` 생성, `Succeeded after ...` 출력

- [ ] **Step 6: 테스트 통과 확인**

Run: `flutter test test/features/ai_report/ai_report_model_test.dart`
Expected: PASS (8개)

- [ ] **Step 7: 커밋**

```bash
git add pubspec.yaml pubspec.lock lib/data/models/ai_report_model.dart lib/data/models/ai_report_model.g.dart test/features/ai_report/ai_report_model_test.dart
git commit -m "feat(ai-report): 응답 모델 5개와 마크다운 패키지 추가

콜론 없는 +0900 오프셋과 int|float 유니온(num) 파싱을 테스트로 고정했다."
```

---

### Task 2: 에러 인터셉터가 서버 메시지를 살리게 수정

이 API는 입력 오류도 500 + 메시지 문자열로 내려주므로(API 스펙 §7.1), 지금처럼 응답 바디를 버리면 `"아직 종료되지 않은 월은 발행할 수 없습니다"`가 `"[500] Internal Server Error"`로 뭉개져 화면에 쓸 수가 없다.

**Files:**
- Modify: `lib/core/network/dio_client.dart:47-78`
- Test: `test/core/dio_error_mapping_test.dart`

**Interfaces:**
- Consumes: `AppException`, `NetworkException`, `ServerException` (기존 `lib/core/network/app_exception.dart`)
- Produces: `AppException mapDioException(DioException err)` — `dio_client.dart`의 공개 top-level 함수. private `_ErrorInterceptor`는 테스트에서 못 건드리므로 판정 로직만 밖으로 뺀 것이다.

- [ ] **Step 1: 실패하는 테스트 작성**

`test/core/dio_error_mapping_test.dart`:

```dart
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(int statusCode, Object? data, {String? statusMessage}) {
  final options = RequestOptions(path: '/ai-report/202608');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: statusCode,
      statusMessage: statusMessage,
      data: data,
    ),
  );
}

void main() {
  group('mapDioException — 공통 봉투 응답', () {
    test('봉투의 resultMessage를 그대로 예외 메시지로 쓴다', () {
      final result = mapDioException(_badResponse(500, {
        'resultCode': 500,
        'resultMessage': '아직 종료되지 않은 월은 발행할 수 없습니다',
        'resultData': null,
        'errorMessage': '아직 종료되지 않은 월은 발행할 수 없습니다',
      }, statusMessage: 'Internal Server Error'));

      expect(result, isA<ServerException>());
      expect(result.message, '아직 종료되지 않은 월은 발행할 수 없습니다');
    });

    test('404 봉투도 서버 메시지를 쓴다', () {
      final result = mapDioException(_badResponse(404, {
        'resultCode': 404,
        'resultMessage': '202607 회차 리포트가 없습니다',
        'resultData': null,
        'errorMessage': '202607 회차 리포트가 없습니다',
      }));

      expect(result.message, '202607 회차 리포트가 없습니다');
    });
  });

  group('mapDioException — 봉투가 아닌 응답 (기존 동작 유지)', () {
    test('FastAPI 422 detail 배열은 상태코드 표기로 떨어진다', () {
      final result = mapDioException(_badResponse(422, {
        'detail': [
          {'type': 'missing', 'loc': ['body', 'userConfirmed'], 'msg': 'Field required'},
        ],
      }, statusMessage: 'Unprocessable Entity'));

      expect(result, isA<ServerException>());
      expect(result.message, '[422] Unprocessable Entity');
    });

    test('바디가 문자열이면 상태코드 표기로 떨어진다', () {
      final result = mapDioException(
        _badResponse(502, 'Bad Gateway', statusMessage: 'Bad Gateway'),
      );

      expect(result.message, '[502] Bad Gateway');
    });

    test('resultMessage가 빈 문자열이면 상태코드 표기로 떨어진다', () {
      final result = mapDioException(_badResponse(500, {
        'resultCode': 500,
        'resultMessage': '',
      }, statusMessage: 'Internal Server Error'));

      expect(result.message, '[500] Internal Server Error');
    });
  });

  group('mapDioException — 네트워크 계열', () {
    test('연결 타임아웃', () {
      final result = mapDioException(DioException(
        requestOptions: RequestOptions(path: '/ai-report'),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(result, isA<NetworkException>());
      expect(result.message, '네트워크 연결이 지연되고 있습니다.');
    });

    test('연결 실패', () {
      final result = mapDioException(DioException(
        requestOptions: RequestOptions(path: '/ai-report'),
        type: DioExceptionType.connectionError,
      ));

      expect(result.message, '서버에 연결할 수 없습니다.');
    });
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `flutter test test/core/dio_error_mapping_test.dart`
Expected: 컴파일 실패 — `The function 'mapDioException' isn't defined`

- [ ] **Step 3: `dio_client.dart` 수정**

`_ErrorInterceptor` 클래스 전체(파일 끝 `class _ErrorInterceptor ... }`)를 아래로 교체한다. `switch` 판정 로직을 top-level 함수로 옮기고 `badResponse` 분기만 바꾼 것이다.

```dart
/// [DioException]을 앱 내부 [AppException]으로 변환한다.
///
/// 서버가 공통 봉투(`CommResponse`)로 내려준 `resultMessage`를 최우선으로 쓴다.
/// 일부 도메인(ai-report)은 입력값 오류도 500 + 메시지 문자열로 구분하게 되어
/// 있어서, 상태코드만 남기면 화면에서 사유를 보여줄 방법이 없다.
/// 봉투가 아닌 응답(FastAPI 검증 에러의 `detail` 배열 등)은 기존대로
/// `[코드] 상태문구` 형태로 떨어진다.
AppException mapDioException(DioException err) {
  switch (err.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException('네트워크 연결이 지연되고 있습니다.');
    case DioExceptionType.connectionError:
      return const NetworkException('서버에 연결할 수 없습니다.');
    case DioExceptionType.badResponse:
      final envelopeMessage = _envelopeMessage(err.response?.data);
      if (envelopeMessage != null) return ServerException(envelopeMessage);
      final statusCode = err.response?.statusCode ?? 0;
      final message = err.response?.statusMessage ?? '알 수 없는 오류';
      return ServerException.fromCode(statusCode, message);
    case DioExceptionType.cancel:
      return const NetworkException('요청이 취소되었습니다.');
    default:
      return NetworkException(err.message ?? '알 수 없는 네트워크 오류');
  }
}

String? _envelopeMessage(Object? data) {
  if (data is! Map) return null;
  for (final key in const ['resultMessage', 'errorMessage']) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = mapDioException(err);

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
        message: exception.message,
      ),
    );
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/core/dio_error_mapping_test.dart`
Expected: PASS (7개)

- [ ] **Step 5: 커밋**

```bash
git add lib/core/network/dio_client.dart test/core/dio_error_mapping_test.dart
git commit -m "fix(network): 에러 응답 봉투의 서버 메시지를 살린다

ai-report는 입력값 오류도 500 + 메시지 문자열로 구분하게 되어 있어
상태코드만 남기면 화면에서 사유를 보여줄 수 없다. 판정 로직을
mapDioException으로 추출해 목 없이 테스트한다."
```

---

### Task 3: `AiReportService`

**Files:**
- Create: `lib/data/services/ai_report_service.dart`

**Interfaces:**
- Consumes: Task 1의 모델 5개, `DioClient.instance.dio`, `ApiResponse`, `AppException` 계열
- Produces: `AiReportService.instance`의 메서드 6개
  - `Future<ReportStatusResponse> getStatus()`
  - `Future<List<ReportListItem>> getReports({int limit = 20, int offset = 0})`
  - `Future<ReportDetailResponse?> getReport(String period)` — **404면 null**
  - `Future<ReportStatusResponse> publish(String period)`
  - `Future<ProfileResponse> getProfile()`
  - `Future<ProfileResponse> updateProfile(String userConfirmed)`

이 태스크에는 테스트가 없다. 순수 로직이 없고 전부 HTTP 왕복이며, 이 저장소에는 목 인프라가 없다. 검증은 `flutter analyze`와 Task 5~9의 화면 동작으로 한다.

- [ ] **Step 1: 서비스 작성**

`lib/data/services/ai_report_service.dart`. 구조는 `lib/data/services/division_service.dart`와 동일하다.

```dart
import 'package:account_book_vibe/core/network/api_response.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:dio/dio.dart';

/// AI 자산관리 리포트 API. 경로는 `AppConfig.baseUrl`의 `/account-book`
/// 뒤에 붙으므로 `/ai-report`로 시작한다.
///
/// `POST /ai-report/questions`는 외부 cron 전용이라 여기 없다.
class AiReportService {
  AiReportService._();
  static final AiReportService instance = AiReportService._();

  final _dio = DioClient.instance.dio;

  Future<T> _request<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw NetworkException(e.message ?? '알 수 없는 오류');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException(e.toString());
    }
  }

  Future<ReportStatusResponse> getStatus() => _request(() async {
        final response = await _dio.get('/ai-report/status');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => ReportStatusResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });

  Future<List<ReportListItem>> getReports({
    int limit = 20,
    int offset = 0,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/ai-report',
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .map((e) => ReportListItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });

  /// 한 번도 발행을 시도하지 않은 회차는 서버가 404를 준다. 그건 오류가 아니라
  /// 정상 상태이므로 예외 대신 null을 돌려준다. 발행 카드가 이 값으로
  /// "미발행"과 "직전 발행 실패"를 가른다.
  Future<ReportDetailResponse?> getReport(String period) =>
      _request<ReportDetailResponse?>(() async {
        try {
          final response = await _dio.get('/ai-report/$period');
          final api = ApiResponse.fromJson(
            response.data as Map<String, dynamic>,
            (json) =>
                ReportDetailResponse.fromJson(json as Map<String, dynamic>),
          );
          if (!api.isSuccess) throw ServerException(api.errorMessage);
          return api.resultData;
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return null;
          rethrow;
        }
      });

  /// 발행 요청. 응답은 즉시 돌아오고 실제 발행은 서버 백그라운드에서 돈다.
  /// 이미 running인 회차에 다시 요청하면 오류가 아니라 현재 상태만 돌아온다.
  Future<ReportStatusResponse> publish(String period) => _request(() async {
        final response = await _dio.post('/ai-report/$period');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => ReportStatusResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });

  Future<ProfileResponse> getProfile() => _request(() async {
        final response = await _dio.get('/ai-report/profile');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => ProfileResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });

  /// 사용자 확정 구역 전면 교체. 부분 갱신이 아니다.
  Future<ProfileResponse> updateProfile(String userConfirmed) =>
      _request(() async {
        final response = await _dio.put(
          '/ai-report/profile',
          data: {'userConfirmed': userConfirmed},
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => ProfileResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });
}
```

- [ ] **Step 2: 정적 분석 통과 확인**

Run: `flutter analyze lib/data/services/ai_report_service.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/data/services/ai_report_service.dart
git commit -m "feat(ai-report): API 서비스 6개 메서드

getReport만 404를 null로 돌려준다. 미시도 회차는 오류가 아니라
발행 카드가 '미발행'과 '실패'를 가르는 신호다."
```

---

### Task 4: 포맷 함수와 발행 카드 상태 판정

**Files:**
- Create: `lib/features/ai_report/ai_report_format.dart`
- Create: `lib/features/ai_report/publish_card.dart` (이 태스크에서는 enum + 판정 함수만)
- Test: `test/features/ai_report/ai_report_format_test.dart`
- Test: `test/features/ai_report/publish_card_test.dart`

**Interfaces:**
- Consumes: `MetricItem`, `ReportStatusResponse`, `ReportDetailResponse` (Task 1)
- Produces:
  - `String formatPeriod(String period)` — `'202607'` → `'2026.07'`
  - `String formatMetricValue(num value, String format)`
  - `String formatMetricDelta(num delta, String format)`
  - `Color metricVerdictColor(String verdict)`
  - `enum PublishCardState { notPublished, running, done, failed }`
  - `PublishCardState resolvePublishCard(ReportStatusResponse status, ReportDetailResponse? detail)`

- [ ] **Step 1: 포맷 테스트 작성**

`test/features/ai_report/ai_report_format_test.dart`:

```dart
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
```

- [ ] **Step 2: 발행 카드 판정 테스트 작성**

`test/features/ai_report/publish_card_test.dart`:

```dart
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
```

- [ ] **Step 3: 두 테스트가 실패하는지 확인**

Run: `flutter test test/features/ai_report/ai_report_format_test.dart test/features/ai_report/publish_card_test.dart`
Expected: 컴파일 실패 — 두 URI 모두 `doesn't exist`

- [ ] **Step 4: 포맷 함수 작성**

`lib/features/ai_report/ai_report_format.dart`:

```dart
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
```

- [ ] **Step 5: 판정 함수 작성**

`lib/features/ai_report/publish_card.dart` (위젯은 Task 6에서 이 파일에 덧붙인다):

```dart
import 'package:account_book_vibe/data/models/ai_report_model.dart';

/// 발행 카드가 그릴 수 있는 네 가지 상태.
enum PublishCardState { notPublished, running, done, failed }

/// 상태 응답과 전월 상세를 카드 상태 하나로 접는다.
///
/// `published:false, running:false` 조합만으로는 "한 번도 시도 안 함"과
/// "시도했다가 실패함"이 구분되지 않아서(API 스펙 §5.2) 상세 응답이 필요하다.
/// 상세가 null이면 서버에 행 자체가 없다는 뜻, 즉 미시도다.
///
/// 좁비(10분 초과 running) 판정은 서버가 조회 시점에 적용해 이미 `failed`로
/// 내려주므로 여기서 경과 시간을 계산하지 않는다.
PublishCardState resolvePublishCard(
  ReportStatusResponse status,
  ReportDetailResponse? detail,
) {
  if (status.published) return PublishCardState.done;
  if (status.running) return PublishCardState.running;
  if (detail?.status == 'failed') return PublishCardState.failed;
  return PublishCardState.notPublished;
}
```

- [ ] **Step 6: 테스트 통과 확인**

Run: `flutter test test/features/ai_report/ai_report_format_test.dart test/features/ai_report/publish_card_test.dart`
Expected: PASS (17개)

- [ ] **Step 7: 커밋**

```bash
git add lib/features/ai_report/ai_report_format.dart lib/features/ai_report/publish_card.dart test/features/ai_report/ai_report_format_test.dart test/features/ai_report/publish_card_test.dart
git commit -m "feat(ai-report): 포맷 함수와 발행 카드 상태 판정

발행 카드는 status 응답만으로 미발행과 실패를 못 가르므로
전월 상세를 함께 본다."
```

---

### Task 5: `AiHomeViewModel`

**Files:**
- Create: `lib/features/ai_report/ai_home_viewmodel.dart`
- Test: `test/features/ai_report/ai_home_viewmodel_test.dart`

**Interfaces:**
- Consumes: `AiReportService.instance` (Task 3), Task 1 모델, `resolvePublishCard`는 화면에서 쓰므로 여기선 안 씀
- Produces: `AiHomeViewModel`
  - 필드: `bool isLoading`, `String? errorMessage`, `ReportStatusResponse? status`, `List<ReportListItem> reports`, `ReportDetailResponse? publishableDetail`, `bool isPublishing`
  - `Future<void> load()`
  - `Future<String?> publish()` — 성공이면 null, 실패면 사용자에게 보여줄 메시지
  - `static List<ReportListItem> excludePublishable(List<ReportListItem> reports, String publishablePeriod)`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/ai_report/ai_home_viewmodel_test.dart`. 네트워크를 타는 `load()`는 테스트하지 않고, 순수 정적 함수만 검증한다 (`DivisionSummaryViewModel` 테스트와 같은 방식).

```dart
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
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `flutter test test/features/ai_report/ai_home_viewmodel_test.dart`
Expected: 컴파일 실패 — `ai_home_viewmodel.dart` 없음

- [ ] **Step 3: 뷰모델 작성**

`lib/features/ai_report/ai_home_viewmodel.dart`:

```dart
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/data/services/ai_report_service.dart';
import 'package:flutter/foundation.dart';

/// AI 탭 루트의 상태. 발행 가능 회차의 상태 + 지난 리포트 목록을 함께 들고 있다.
///
/// 발행 완료를 폴링하지 않는다. 서버에 푸시 채널이 없고, 사용자가 당겨서
/// 새로고침하면 [load]가 다시 돈다.
class AiHomeViewModel extends ChangeNotifier {
  bool isLoading = false;
  bool isPublishing = false;
  String? errorMessage;

  ReportStatusResponse? status;
  List<ReportListItem> reports = [];

  /// 발행 가능 회차의 상세. null이면 그 회차를 한 번도 발행 시도하지 않은 것이다.
  ReportDetailResponse? publishableDetail;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // publishablePeriod가 status 응답에서 나오므로 셋을 한 번에 묶을 수 없다.
      final currentStatus = await AiReportService.instance.getStatus();
      final rest = await Future.wait([
        AiReportService.instance.getReports(),
        AiReportService.instance.getReport(currentStatus.publishablePeriod),
      ]);

      status = currentStatus;
      reports = excludePublishable(
        rest[0] as List<ReportListItem>,
        currentStatus.publishablePeriod,
      );
      publishableDetail = rest[1] as ReportDetailResponse?;
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 발행 요청. 성공하면 null, 실패하면 화면이 토스트로 띄울 메시지를 돌려준다.
  ///
  /// `POST`가 상태 조회와 같은 스키마를 돌려주므로(API 스펙 §5.7) 재조회 없이
  /// 그 값으로 교체한다. 실제 발행은 서버 백그라운드에서 계속 돈다.
  Future<String?> publish() async {
    final period = status?.publishablePeriod;
    if (period == null) return null;

    isPublishing = true;
    notifyListeners();

    try {
      status = await AiReportService.instance.publish(period);
      publishableDetail = null;
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      isPublishing = false;
      notifyListeners();
    }
  }

  /// 발행 카드와 목록이 같은 회차를 두 번 보여주지 않게 한다.
  static List<ReportListItem> excludePublishable(
    List<ReportListItem> reports,
    String publishablePeriod,
  ) =>
      reports.where((e) => e.period != publishablePeriod).toList();
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/features/ai_report/ai_home_viewmodel_test.dart`
Expected: PASS (4개)

- [ ] **Step 5: 커밋**

```bash
git add lib/features/ai_report/ai_home_viewmodel.dart test/features/ai_report/ai_home_viewmodel_test.dart
git commit -m "feat(ai-report): 홈 뷰모델

publishablePeriod가 status 응답에서 나와서 3개를 병렬로 못 묶는다.
status 먼저, 목록과 전월 상세를 그다음 병렬로 부른다."
```

---

### Task 6: AI 탭 배선 + 홈 화면

이 태스크가 끝나면 앱을 켜서 AI 탭에 들어갈 수 있다.

**Files:**
- Modify: `lib/features/shell/main_shell_screen.dart:11-16`
- Modify: `lib/core/router/app_router.dart:36-62`
- Modify: `lib/features/ai_report/publish_card.dart` (위젯 추가)
- Create: `lib/features/ai_report/ai_report_home_screen.dart`

**Interfaces:**
- Consumes: `AiHomeViewModel` (Task 5), `PublishCardState` / `resolvePublishCard` (Task 4), `formatPeriod` (Task 4)
- Produces:
  - `PublishCard` 위젯 — `PublishCard({required PublishCardState state, required ReportStatusResponse status, required String? failureReason, required bool isPublishing, required VoidCallback onPublish, required VoidCallback onOpenReport, required VoidCallback onOpenProfile})` (`failureReason`은 nullable이지만 명시 전달을 강제한다)
  - `AiReportHomeScreen` — 라우트 `/aiReport`
  - 라우트 이름 `'/aiReportDetail/:period'`, `'/aiProfile'` (화면은 Task 8·9에서 채운다)

- [ ] **Step 1: 하단 내비게이션에 탭 추가**

`lib/features/shell/main_shell_screen.dart`의 `_items` 리스트 마지막에 한 줄 추가한다:

```dart
  static const _items = <({String emoji, String label})>[
    (emoji: '📋', label: '목록'),
    (emoji: '📊', label: '분석'),
    (emoji: '🏠', label: '홈'),
    (emoji: '🏢', label: '자산'),
    (emoji: '🤖', label: 'AI'),
  ];
```

레이아웃은 손대지 않는다. `Expanded`가 5등분으로 알아서 처리한다.

- [ ] **Step 2: 라우트 추가**

`lib/core/router/app_router.dart`:

먼저 import 3줄을 추가한다 (기존 import는 알파벳 순이므로 `analysis` 다음, `asset` 앞).

```dart
import 'package:account_book_vibe/features/ai_report/ai_profile_screen.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_detail_screen.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_home_screen.dart';
```

`branches` 리스트의 `/asset` 브랜치 다음에 5번째 브랜치를 추가한다:

```dart
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/aiReport',
            pageBuilder: (c, s) => _slidePage(const AiReportHomeScreen(), s),
          ),
        ]),
```

셸 밖 라우트는 `/myAsset` 다음에 추가한다. 셸 브랜치 경로(`/aiReport`)와 겹치지 않게 평평한 경로를 쓴다:

```dart
    GoRoute(
      path: '/aiReportDetail/:period',
      pageBuilder: (c, s) => _slidePage(
        AiReportDetailScreen(period: s.pathParameters['period']!),
        s,
      ),
    ),
    GoRoute(
      path: '/aiProfile',
      pageBuilder: (c, s) => _slidePage(const AiProfileScreen(), s),
    ),
```

이 시점에는 두 화면 파일이 없어 컴파일이 깨진다. Step 3에서 카드를, Step 4에서 홈을 만들고, Task 8·9에서 나머지 둘을 만든다. **Step 5의 임시 스텁으로 이 태스크 안에서 컴파일을 복구한다.**

- [ ] **Step 3: 발행 카드 위젯 작성**

`lib/features/ai_report/publish_card.dart` 끝에 덧붙인다. import를 파일 맨 위에 추가한다:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_shadows.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_format.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
```

위젯 본문:

```dart
/// 발행 가능 회차 하나를 다루는 카드. 상태에 따라 몸통과 버튼이 바뀐다.
class PublishCard extends StatelessWidget {
  const PublishCard({
    super.key,
    required this.state,
    required this.status,
    required this.failureReason,
    required this.isPublishing,
    required this.onPublish,
    required this.onOpenReport,
    required this.onOpenProfile,
  });

  final PublishCardState state;
  final ReportStatusResponse status;

  /// 실패 회차의 예외 타입명. 서버가 원본 데이터 유출을 막으려고 타입명만 준다.
  final String? failureReason;
  final bool isPublishing;
  final VoidCallback onPublish;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorBgSub,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatPeriod(status.publishablePeriod)} 회차',
            style: AppTextStyles.textHeadlineSm.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _statusLine(),
          if (status.pendingQuestions.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _PendingQuestionsRow(
              questions: status.pendingQuestions,
              onTap: onOpenProfile,
            ),
          ],
          const SizedBox(height: 16),
          _actionButton(),
        ],
      ),
    );
  }

  Widget _statusLine() {
    final (String text, Color color) = switch (state) {
      PublishCardState.notPublished => ('아직 발행하지 않았어', AppColors.colorTextSecondary),
      PublishCardState.running => ('리포트를 만들고 있어', AppColors.colorAccentTeal),
      PublishCardState.done => ('발행 완료', AppColors.colorSuccess),
      PublishCardState.failed => (
          '지난번 생성이 실패했어${failureReason == null ? '' : ' ($failureReason)'}',
          AppColors.colorError,
        ),
    };

    return Row(
      children: [
        if (state == PublishCardState.running) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.colorAccentTeal,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.textBodyMd.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _actionButton() {
    if (state == PublishCardState.done) {
      return GradientButton(
        label: '리포트 보기',
        icon: Icons.article_outlined,
        onPressed: onOpenReport,
      );
    }

    if (state == PublishCardState.running) {
      // 서버가 백그라운드에서 만드는 중이고 완료 알림 채널이 없다.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientButton(
            label: '생성 중…',
            onPressed: null,
            enabled: false,
          ),
          const SizedBox(height: 8),
          Text(
            '몇 분 걸려. 다 되면 화면을 아래로 당겨서 새로고침해줘.',
            style: AppTextStyles.textBodyXs.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
        ],
      );
    }

    return GradientButton(
      label: state == PublishCardState.failed ? '다시 시도' : '리포트 발행하기',
      icon: Icons.auto_awesome,
      onPressed: isPublishing ? null : onPublish,
      enabled: !isPublishing,
    );
  }
}

class _PendingQuestionsRow extends StatelessWidget {
  const _PendingQuestionsRow({required this.questions, required this.onTap});

  final String questions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 질문은 서버가 주는 자유 텍스트(마크다운 목록 관례)라 줄 수만 센다.
    final count = questions
        .split('\n')
        .where((line) => line.trimLeft().startsWith('-'))
        .length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.colorHoverTeal,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.help_outline,
              size: 18,
              color: AppColors.colorAccentTeal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count > 0 ? 'AI가 물어본 게 $count개 있어' : 'AI가 물어본 게 있어',
                style: AppTextStyles.textBodySm.copyWith(
                  color: AppColors.colorAccentTeal,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.colorAccentTeal,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 홈 화면 작성**

`lib/features/ai_report/ai_report_home_screen.dart`:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/features/ai_report/ai_home_viewmodel.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_format.dart';
import 'package:account_book_vibe/features/ai_report/publish_card.dart';
import 'package:account_book_vibe/shared/widgets/app_list_card.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// AI 탭 루트. 발행 카드 하나 + 지난 리포트 목록.
class AiReportHomeScreen extends StatefulWidget {
  const AiReportHomeScreen({super.key});

  @override
  State<AiReportHomeScreen> createState() => _AiReportHomeScreenState();
}

class _AiReportHomeScreenState extends State<AiReportHomeScreen> {
  final _vm = AiHomeViewModel();

  @override
  void initState() {
    super.initState();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final failure = await _vm.publish();
    if (!mounted || failure == null) return;
    AppToast.show(context, failure, type: ToastType.error);
  }

  Future<void> _openProfile() async {
    await context.push('/aiProfile');
    // 프로필을 고치면 미답변 질문 표시가 달라질 수 있다.
    await _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: MainAppBar(
        showMenuButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '내 프로필',
            onPressed: _openProfile,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.colorAccentTeal),
            );
          }

          final status = _vm.status;
          if (_vm.errorMessage != null || status == null) {
            return ErrorView(
              message: _vm.errorMessage ?? '리포트 상태를 불러오지 못했습니다.',
              onRetry: _vm.load,
            );
          }

          return RefreshIndicator(
            color: AppColors.colorAccentTeal,
            backgroundColor: AppColors.colorBgSub,
            onRefresh: _vm.load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                PublishCard(
                  state: resolvePublishCard(status, _vm.publishableDetail),
                  status: status,
                  failureReason: _vm.publishableDetail?.errorMessage,
                  isPublishing: _vm.isPublishing,
                  onPublish: _publish,
                  onOpenReport: () =>
                      context.push('/aiReportDetail/${status.publishablePeriod}'),
                  onOpenProfile: _openProfile,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    '지난 리포트',
                    style: AppTextStyles.textTitleMd.copyWith(
                      color: AppColors.colorTextPrimary,
                    ),
                  ),
                ),
                if (_vm.reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyView(message: '아직 발행된 리포트가 없어.'),
                  )
                else
                  for (final report in _vm.reports)
                    _ReportRow(
                      report: report,
                      onTap: () =>
                          context.push('/aiReportDetail/${report.period}'),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onTap});

  final ReportListItem report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      onTap: onTap,
      title: Text(
        formatPeriod(report.period),
        style: AppTextStyles.textTitleSm.copyWith(
          color: AppColors.colorTextPrimary,
        ),
      ),
      subtitle: Text(
        report.headline ?? '요약 없음',
        style: AppTextStyles.textBodySm.copyWith(
          color: AppColors.colorTextSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.colorTextDisabled,
        size: 20,
      ),
    );
  }
}
```

- [ ] **Step 5: `MainAppBar`에 actions 슬롯 추가 + 나머지 두 화면 스텁**

`MainAppBar`에는 아직 `actions`가 없다. `lib/shared/widgets/main_app_bar.dart`의 생성자와 필드, `AppBar` 호출에 각각 한 줄씩 추가한다:

```dart
  const MainAppBar({
    super.key,
    this.bottom,
    this.showMenuButton = true,
    this.actions,
  });

  final PreferredSizeWidget? bottom;

  /// 우측 액션 버튼들. 지정하지 않으면 기존처럼 비어 있다.
  final List<Widget>? actions;
```

`AppBar(...)` 인자에 `actions: actions,`를 `bottom: bottom,` 앞에 넣는다.

그리고 라우터가 참조하는 두 화면의 스텁을 만들어 컴파일을 복구한다. Task 8·9에서 내용을 채운다.

`lib/features/ai_report/ai_report_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';

class AiReportDetailScreen extends StatelessWidget {
  const AiReportDetailScreen({super.key, required this.period});

  final String period;

  @override
  Widget build(BuildContext context) => const Scaffold();
}
```

`lib/features/ai_report/ai_profile_screen.dart`:

```dart
import 'package:flutter/material.dart';

class AiProfileScreen extends StatelessWidget {
  const AiProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold();
}
```

- [ ] **Step 6: 정적 분석과 기존 테스트 확인**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test test/shared/widgets/main_app_bar_test.dart test/features/shell/hero_tag_regression_test.dart`
Expected: PASS — `MainAppBar` 수정과 탭 추가가 기존 위젯 테스트를 깨지 않았는지 본다

- [ ] **Step 7: 실기기/시뮬레이터에서 확인**

Run: `flutter run`
확인할 것:
1. 하단 탭이 5개로 늘고 맨 오른쪽이 `🤖 AI`인지
2. AI 탭 진입 시 발행 카드와 목록이 뜨는지
3. 아래로 당기면 새로고침이 도는지
4. 다른 탭 4개가 그대로 동작하는지

- [ ] **Step 8: 커밋**

```bash
git add lib/features/shell/main_shell_screen.dart lib/core/router/app_router.dart lib/shared/widgets/main_app_bar.dart lib/features/ai_report/
git commit -m "feat(ai-report): AI 탭과 홈 화면

하단 내비 5번째 탭, 발행 카드, 지난 리포트 목록.
상세/프로필 화면은 라우팅만 뚫어두고 스텁이다.
MainAppBar에 actions 슬롯을 열었다 (기본값 null이라 기존 화면 영향 없음)."
```

---

### Task 7: 지표 그리드 위젯

**Files:**
- Create: `lib/features/ai_report/metric_grid.dart`

**Interfaces:**
- Consumes: `MetricItem` (Task 1), `formatMetricValue` / `formatMetricDelta` / `metricVerdictColor` (Task 4)
- Produces: `MetricGrid({required List<MetricItem> metrics})`

포맷 로직은 Task 4에서 이미 테스트했다. 이 태스크는 위젯 조립만이라 테스트를 추가하지 않는다.

- [ ] **Step 1: 위젯 작성**

`lib/features/ai_report/metric_grid.dart`:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_shadows.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_format.dart';
import 'package:flutter/material.dart';

/// 핵심 지표 4개를 2×2로 깐다. 서버가 순서를 고정해 주므로 정렬하지 않는다.
class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.metrics});

  final List<MetricItem> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        for (final metric in metrics) _MetricTile(metric: metric),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final MetricItem metric;

  @override
  Widget build(BuildContext context) {
    final verdictColor = metricVerdictColor(metric.verdict);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.colorBgSub,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
        border: Border(left: BorderSide(color: verdictColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metric.label,
            style: AppTextStyles.textBodyXs.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMetricValue(metric.value, metric.format),
              style: AppTextStyles.moneyMedium.copyWith(color: verdictColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMetricDelta(metric.delta, metric.format),
            style: AppTextStyles.textBodyXs.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 정적 분석 확인**

Run: `flutter analyze lib/features/ai_report/metric_grid.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/ai_report/metric_grid.dart
git commit -m "feat(ai-report): 지표 2x2 그리드

verdict를 좌측 보더 색으로, delta를 방향 기호로 보여준다."
```

---

### Task 8: 리포트 상세 화면

**Files:**
- Modify: `lib/features/ai_report/ai_report_detail_screen.dart` (Task 6의 스텁을 대체)

**Interfaces:**
- Consumes: `AiReportService.instance.getReport` (Task 3), `MetricGrid` (Task 7), `formatPeriod` (Task 4), `flutter_markdown_plus` (Task 1)
- Produces: `AiReportDetailScreen({required String period})` — 라우트 `/aiReportDetail/:period`

- [ ] **Step 1: 화면 작성**

`lib/features/ai_report/ai_report_detail_screen.dart` 전체를 교체한다:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/data/services/ai_report_service.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_format.dart';
import 'package:account_book_vibe/features/ai_report/metric_grid.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// 발행 완료된 회차 하나를 읽는 화면.
///
/// 발행이 끝난 리포트는 서버에서 스냅샷으로 굳어 변하지 않으므로 뷰모델 없이
/// [FutureBuilder]로 한 번만 읽는다.
class AiReportDetailScreen extends StatefulWidget {
  const AiReportDetailScreen({super.key, required this.period});

  final String period;

  @override
  State<AiReportDetailScreen> createState() => _AiReportDetailScreenState();
}

class _AiReportDetailScreenState extends State<AiReportDetailScreen> {
  late Future<ReportDetailResponse?> _future = _load();

  Future<ReportDetailResponse?> _load() =>
      AiReportService.instance.getReport(widget.period);

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: AppBar(
        backgroundColor: AppColors.colorBgMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.colorTextPrimary),
        title: Text(
          '${formatPeriod(widget.period)} 리포트',
          style: AppTextStyles.textHeadlineSm.copyWith(
            color: AppColors.colorTextPrimary,
          ),
        ),
      ),
      body: FutureBuilder<ReportDetailResponse?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.colorAccentTeal),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorView(
              message: error is AppException
                  ? error.message
                  : '리포트를 불러오지 못했습니다.',
              onRetry: _retry,
            );
          }

          final report = snapshot.data;
          // 목록과 서버 상태가 어긋난 경우의 방어. 정상 경로에서는 안 온다.
          if (report == null) {
            return const EmptyView(message: '이 회차 리포트가 없어.');
          }
          if (report.status != 'done') {
            return const EmptyView(message: '아직 발행이 끝나지 않았어.');
          }

          return _ReportBody(report: report);
        },
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final ReportDetailResponse report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (report.headline != null)
          Text(
            report.headline!,
            style: AppTextStyles.textHeadlineLg.copyWith(
              color: AppColors.colorTextPrimary,
              height: 1.4,
            ),
          ),
        const SizedBox(height: 20),
        MetricGrid(metrics: report.metrics),
        const SizedBox(height: 24),
        if (report.bodyMd != null)
          MarkdownBody(
            data: report.bodyMd!,
            styleSheet: _markdownStyle(),
          ),
        if (report.action != null) ...[
          const SizedBox(height: 24),
          _ActionBox(action: report.action!),
        ],
      ],
    );
  }

  /// 마크다운 본문을 앱 타이포/색에 맞춘다. 섹션 구성이 회차마다 달라지므로
  /// 특정 제목을 가정하지 않고 레벨별 스타일만 정의한다.
  MarkdownStyleSheet _markdownStyle() => MarkdownStyleSheet(
        p: AppTextStyles.textBodyLg.copyWith(
          color: AppColors.colorTextPrimary,
          height: 1.7,
        ),
        h1: AppTextStyles.textHeadlineMd.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        h2: AppTextStyles.textHeadlineSm.copyWith(
          color: AppColors.colorAccentTeal,
        ),
        h3: AppTextStyles.textTitleMd.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        listBullet: AppTextStyles.textBodyLg.copyWith(
          color: AppColors.colorTextSecondary,
        ),
        strong: AppTextStyles.textBodyLg.copyWith(
          color: AppColors.colorTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        blockquote: AppTextStyles.textBodyMd.copyWith(
          color: AppColors.colorTextSecondary,
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.colorBgSub,
          borderRadius: BorderRadius.circular(8),
        ),
        code: AppTextStyles.textBodySm.copyWith(
          color: AppColors.colorAccentTeal,
          backgroundColor: AppColors.colorBgCard,
        ),
        tableBody: AppTextStyles.textBodySm.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        tableBorder: TableBorder.all(color: AppColors.colorDivider),
        h2Padding: const EdgeInsets.only(top: 20, bottom: 4),
        h3Padding: const EdgeInsets.only(top: 12, bottom: 4),
      );
}

class _ActionBox extends StatelessWidget {
  const _ActionBox({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorHoverTeal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.colorAccentTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppColors.colorAccentTeal,
              ),
              const SizedBox(width: 6),
              Text(
                '이번 달에 할 일',
                style: AppTextStyles.textLabelMd.copyWith(
                  color: AppColors.colorAccentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action,
            style: AppTextStyles.textBodyLg.copyWith(
              color: AppColors.colorTextPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 정적 분석 확인**

Run: `flutter analyze`
Expected: `No issues found!`

`MarkdownStyleSheet`의 필드명이 안 맞으면 설치된 버전의 API를 확인한다:
`cat ~/.pub-cache/hosted/pub.dev/flutter_markdown_plus-1.0.12/lib/src/style_sheet.dart | grep 'final '`

- [ ] **Step 3: 실기기 확인**

Run: `flutter run`
확인할 것: 목록에서 리포트를 열면 헤드라인 → 지표 4개 → 마크다운 본문 → 액션 박스 순으로 뜨는지, 본문의 제목·목록·볼드가 앱 색으로 렌더되는지

- [ ] **Step 4: 커밋**

```bash
git add lib/features/ai_report/ai_report_detail_screen.dart
git commit -m "feat(ai-report): 리포트 상세 화면

발행 완료 리포트는 서버 스냅샷이라 불변이므로 뷰모델 없이 FutureBuilder로 읽는다."
```

---

### Task 9: 프로필 화면

**Files:**
- Create: `lib/features/ai_report/ai_profile_viewmodel.dart`
- Modify: `lib/features/ai_report/ai_profile_screen.dart` (Task 6의 스텁을 대체)

**Interfaces:**
- Consumes: `AiReportService.instance.getProfile` / `updateProfile` (Task 3), `AppAlertDialog.confirm`, `AppToast.show`
- Produces:
  - `AiProfileViewModel` — 필드 `ProfileResponse? profile`, `bool isLoading`, `bool isSaving`, `String? errorMessage`; `Future<void> load()`; `Future<String?> save(String userConfirmed)` (성공 null, 실패 메시지)
  - `AiProfileScreen` — 라우트 `/aiProfile`

- [ ] **Step 1: 뷰모델 작성**

`lib/features/ai_report/ai_profile_viewmodel.dart`:

```dart
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/data/services/ai_report_service.dart';
import 'package:flutter/foundation.dart';

/// 프로필 3구역의 로드와 저장.
///
/// 앱이 쓸 수 있는 건 `userConfirmed` 하나뿐이다. 나머지 두 구역은 LLM이
/// 쓰고 요청 스키마에 아예 없어서 덮어쓸 경로가 없다.
class AiProfileViewModel extends ChangeNotifier {
  ProfileResponse? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await AiReportService.instance.getProfile();
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자 확정 구역 전면 교체. 성공하면 null, 실패하면 화면이 토스트로
  /// 띄울 메시지를 돌려준다. 실패해도 화면의 입력 내용은 건드리지 않는다.
  Future<String?> save(String userConfirmed) async {
    isSaving = true;
    notifyListeners();

    try {
      profile = await AiReportService.instance.updateProfile(userConfirmed);
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
```

- [ ] **Step 2: 화면 작성**

`lib/features/ai_report/ai_profile_screen.dart` 전체를 교체한다:

```dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/features/ai_report/ai_profile_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_dialogs.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';

/// 미답변 질문을 읽고, 사용자 확정 구역을 통째로 고치는 화면.
///
/// 질문에 답하는 별도 엔드포인트는 없다. 답은 확정 구역에 직접 적는 것이고,
/// 질문 텍스트가 자동으로 옮겨오지 않는다.
class AiProfileScreen extends StatefulWidget {
  const AiProfileScreen({super.key});

  @override
  State<AiProfileScreen> createState() => _AiProfileScreenState();
}

class _AiProfileScreenState extends State<AiProfileScreen> {
  final _vm = AiProfileViewModel();
  final _controller = TextEditingController();

  /// 서버에서 마지막으로 받은 원문. 이것과 다르면 미저장 변경이 있는 것이다.
  String _saved = '';

  @override
  void initState() {
    super.initState();
    _vm.addListener(_syncController);
    _vm.load();
  }

  @override
  void dispose() {
    _vm.removeListener(_syncController);
    _vm.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncController() {
    final loaded = _vm.profile?.userConfirmed;
    if (loaded == null || loaded == _saved) return;
    _saved = loaded;
    _controller.text = loaded;
  }

  bool get _isDirty => _controller.text != _saved;

  Future<void> _save() async {
    final failure = await _vm.save(_controller.text);
    if (!mounted) return;
    if (failure != null) {
      // 입력 내용은 그대로 둔다. 다시 누르면 재시도된다.
      AppToast.show(context, failure, type: ToastType.error);
      return;
    }
    AppToast.show(context, '저장했어', type: ToastType.success);
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return AppAlertDialog.confirm(
      context,
      message: '저장하지 않은 변경이 있어. 그냥 나갈까?',
      confirmText: '나가기',
      cancelText: '계속 쓰기',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.colorBgMain,
        appBar: AppBar(
          backgroundColor: AppColors.colorBgMain,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppColors.colorTextPrimary),
          title: Text(
            '내 프로필',
            style: AppTextStyles.textHeadlineSm.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          actions: [
            ListenableBuilder(
              listenable: Listenable.merge([_vm, _controller]),
              builder: (context, _) {
                final canSave = _isDirty && !_vm.isSaving;
                return TextButton(
                  onPressed: canSave ? _save : null,
                  child: Text(
                    _vm.isSaving ? '저장 중…' : '저장',
                    style: AppTextStyles.textLabelMd.copyWith(
                      color: canSave
                          ? AppColors.colorAccentTeal
                          : AppColors.colorTextDisabled,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            if (_vm.isLoading) {
              return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.colorAccentTeal),
              );
            }

            final profile = _vm.profile;
            if (_vm.errorMessage != null || profile == null) {
              return ErrorView(
                message: _vm.errorMessage ?? '프로필을 불러오지 못했습니다.',
                onRetry: _vm.load,
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (profile.pendingQuestions.trim().isNotEmpty) ...[
                  _SectionLabel(
                    label: 'AI가 물어본 것',
                    color: AppColors.colorAccentTeal,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.colorHoverTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      profile.pendingQuestions,
                      style: AppTextStyles.textBodyMd.copyWith(
                        color: AppColors.colorTextPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const _SectionLabel(label: '내가 확정한 내용'),
                const SizedBox(height: 4),
                Text(
                  '여기에 적은 내용이 다음 리포트에 반영돼. 질문에 대한 답도 여기 적으면 돼.',
                  style: AppTextStyles.textBodyXs.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  maxLines: null,
                  minLines: 10,
                  style: AppTextStyles.textBodyMd.copyWith(
                    color: AppColors.colorTextPrimary,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: '- 목표: 전세보증금 1.5억 · 2028년\n- 월 지출 상한 300만',
                    hintStyle: AppTextStyles.textBodyMd.copyWith(
                      color: AppColors.colorTextDisabled,
                    ),
                    filled: true,
                    fillColor: AppColors.colorBgSub,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.colorDivider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.colorDivider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.colorAccentTeal),
                    ),
                  ),
                ),
                if (profile.observations.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      iconColor: AppColors.colorTextSecondary,
                      collapsedIconColor: AppColors.colorTextSecondary,
                      title: Text(
                        'AI가 관찰한 내용',
                        style: AppTextStyles.textLabelMd.copyWith(
                          color: AppColors.colorTextSecondary,
                        ),
                      ),
                      children: [
                        SelectableText(
                          profile.observations,
                          style: AppTextStyles.textBodySm.copyWith(
                            color: AppColors.colorTextSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.textTitleSm.copyWith(
        color: color ?? AppColors.colorTextPrimary,
      ),
    );
  }
}
```

- [ ] **Step 3: 정적 분석 확인**

Run: `flutter analyze`
Expected: `No issues found!`

`PopScope.onPopInvokedWithResult`가 없다는 오류가 나오면 설치된 Flutter가 구버전이다. `onPopInvoked: (didPop) async { ... }`로 바꾼다 (동작 동일).

- [ ] **Step 4: 실기기 확인**

Run: `flutter run`
확인할 것:
1. 홈의 프로필 아이콘 또는 "AI가 물어본 게 N개 있어" 줄로 진입되는지
2. 확정 구역을 고치면 저장 버튼이 활성화되는지
3. 저장 후 토스트가 뜨고 버튼이 다시 비활성이 되는지
4. 고친 채로 뒤로가기를 하면 확인 다이얼로그가 뜨는지
5. 저장하고 돌아오면 홈의 질문 표시가 갱신되는지

- [ ] **Step 5: 커밋**

```bash
git add lib/features/ai_report/ai_profile_viewmodel.dart lib/features/ai_report/ai_profile_screen.dart
git commit -m "feat(ai-report): 프로필 편집 화면

PUT이 확정 구역 전면 교체라 화면도 전문 편집으로 맞췄다.
저장 실패 시 입력 내용을 유지한다."
```

---

### Task 10: 전체 검증

**Files:** 없음 (검증만)

- [ ] **Step 1: 정적 분석**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: 이번 작업이 추가한 테스트 전부**

Run: `flutter test test/features/ai_report/ test/core/dio_error_mapping_test.dart`
Expected: PASS (36개 — 모델 8 + 인터셉터 7 + 포맷 11 + 발행 카드 6 + 뷰모델 4)

- [ ] **Step 3: 전체 테스트**

Run: `flutter test`
Expected: **날짜 의존 기존 실패 2건만** 남는다. 실패 목록을 확인해서 그 2건이 `test/features/ai_report/`와 `test/core/dio_error_mapping_test.dart` 밖에 있는지 본다. 그 밖의 실패가 있으면 이번 변경이 회귀를 낸 것이므로 고친다.

`git stash` 후 master에서 `flutter test`를 돌려 실패 목록이 같은지 비교하면 확실하다.

- [ ] **Step 4: 전체 흐름 손으로 확인**

Run: `flutter run`

1. 탭 5개, 맨 오른쪽 `🤖 AI`
2. AI 탭 → 발행 카드 상태가 서버 상태와 맞는지
3. 발행 버튼 → 카드가 "생성 중"으로 바뀌는지
4. 잠시 후 당겨서 새로고침 → 완료로 바뀌는지
5. "리포트 보기" → 상세가 뜨는지
6. 지난 리포트 목록에 방금 회차가 **중복으로 안 나오는지**
7. 프로필 편집 → 저장 → 홈 질문 표시 갱신
8. 기존 탭 4개 정상 동작

- [ ] **Step 5: 최종 커밋 (변경이 있었을 때만)**

```bash
git add -A
git commit -m "chore(ai-report): 전체 검증 후 정리"
```

## 참고

- 발행 실패 원인은 서버 응답에 예외 타입명만 담긴다. 무인증 API라 원본 데이터가 섞인 예외 메시지를 노출하지 않으려는 의도적 설계다. 상세 사유는 서버 로그를 봐야 한다.
- `POST /ai-report/questions`는 외부 cron이 매월 1일에 호출한다. 앱에 호출 경로를 만들지 않는다. 이 배치가 돌아야 `pendingQuestions`가 채워지고 미발행 회차가 자동 발행된다.
