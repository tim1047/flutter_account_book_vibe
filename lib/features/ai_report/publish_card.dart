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
