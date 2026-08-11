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
